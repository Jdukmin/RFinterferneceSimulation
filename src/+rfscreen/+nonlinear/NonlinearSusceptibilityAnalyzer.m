classdef NonlinearSusceptibilityAnalyzer
    %NONLINEARSUSCEPTIBILITYANALYZER Scenario-level receiver nonlinear analysis (ICD 10).
    %   Gathers all active interfering TX to one RX, REUSING the Phase-1 pairwise
    %   engine for spatial coupling (no geometry recompute), builds per-interferer
    %   LNA-input powers, and runs compression / blocking / IM3.
    methods (Static)
        function res = analyze(scenario, rxId, config, opts)
            if nargin < 3 || isempty(config); config = rfscreen.config.AnalysisConfig.default(); end
            if nargin < 4 || isempty(opts); opts = struct(); end
            NV = rfscreen.receiver.NonlinearValidity;
            scenario.validate();

            rx = scenario.receivers(rxId);
            fe = rx.receiverFrontEnd;
            rxCenter = rx.fc_Hz;
            rxBand = rx.band_Hz();
            channelFilter = rfscreen.nonlinear.NonlinearSusceptibilityAnalyzer.pickChannelFilter(rx, fe, rxBand);

            couplingModel = rfscreen.interference.InterferenceAnalyzer.makeCouplingModel(config.couplingModel);

            wantedTxId = '';
            if isfield(opts, 'wantedTxId') && ~isempty(opts.wantedTxId); wantedTxId = opts.wantedTxId; end

            % ---- collect interferers (active TX excluding self antenna and wanted) ----
            activeTx = scenario.resolveActiveTxIds();
            interfererIds = {};
            inputs = struct('txId', {}, 'freq_Hz', {}, 'lnaInputPower_dBm', {}, ...
                            'isAbsolute', {}, 'couplingValidity', {});
            for i = 1:numel(activeTx)
                txId = activeTx{i};
                tx = scenario.transmitters(txId);
                if strcmp(tx.antennaId, rx.antennaId); continue; end   % self
                if ~isempty(wantedTxId) && strcmp(txId, wantedTxId); continue; end
                interfererIds{end+1} = txId; %#ok<AGROW>

                in = scenario.buildPairInput(txId, rxId);
                pr = rfscreen.interference.PairwiseAnalyzer.analyze(in, couplingModel, config);

                isAbs = strcmp(pr.couplingModelType, 'FAR_FIELD') && pr.isPhysicalCoupling ...
                        && isfinite(pr.couplingMetric_dB) && isfinite(pr.txGain_dBi) && isfinite(pr.rxGain_dBi);
                entry = struct();
                entry.txId = txId;
                entry.freq_Hz = tx.fc_Hz;
                if isAbs
                    absT = pr.txGain_dBi + pr.rxGain_dBi - pr.couplingMetric_dB;
                    presel = 0;
                    if ~isempty(fe); presel = fe.preselectorResponse_dB(tx.fc_Hz); end
                    entry.lnaInputPower_dBm = tx.power_dBm + absT + presel;
                    entry.isAbsolute = true;
                    entry.couplingValidity = 'FAR_FIELD_VALID';
                else
                    entry.lnaInputPower_dBm = NaN;
                    entry.isAbsolute = false;
                    if strcmp(pr.couplingModelType, 'PATTERN_ONLY')
                        entry.couplingValidity = 'PATTERN_ONLY';
                    else
                        entry.couplingValidity = 'FAR_FIELD_INVALID_OR_UNKNOWN';
                    end
                end
                inputs(end+1) = entry; %#ok<AGROW>
            end

            % ---- run the three nonlinear mechanisms ----
            compression = rfscreen.nonlinear.CompressionAnalyzer.analyze(inputs, fe, rx.compressionCriterion);
            blocking = rfscreen.nonlinear.BlockingAnalyzer.analyze(inputs, rxCenter, rx.blockingCriterion);
            im3out = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(inputs, fe, channelFilter, rxBand, rx.intermodulationCriterion);

            % ---- assemble ----
            s = struct();
            s.rxId = rxId;
            s.referencePlane = rfscreen.receiver.ReferencePlane.LNA_INPUT;
            s.interfererIds = interfererIds;
            s.compression = compression;
            s.blocking = blocking;
            s.im3 = im3out.products;
            s.im2 = 'NOT_IMPLEMENTED';
            s.warnings = im3out.warnings;

            nValid = 0;
            for k = 1:numel(inputs); if inputs(k).isAbsolute; nValid = nValid + 1; end; end
            if isempty(inputs)
                s.validity = NV.VALID;
                s.warnings{end+1} = 'no active interferers for this receiver';
            elseif nValid == 0
                s.validity = NV.ABSOLUTE_COUPLING_UNAVAILABLE;
                s.warnings{end+1} = 'no interferer has valid absolute coupling: nonlinear physics withheld';
            elseif nValid < numel(inputs)
                s.validity = NV.INCOMPLETE_INTERFERER_SET;
            else
                s.validity = NV.VALID;
            end
            res = rfscreen.results.NonlinearSusceptibilityResult(s);
        end
    end

    methods (Static, Access = private)
        function cf = pickChannelFilter(rx, fe, rxBand)
            if ~isempty(rx.filter)
                cf = rx.filter;
            elseif ~isempty(fe) && ~isempty(fe.channelFilter)
                cf = fe.channelFilter;
            else
                cf = rfscreen.receiver.IdealBandpassFilter(rxBand, 0, -Inf, ...
                    struct('provenance', 'SYNTHETIC_TEST'));
            end
        end
    end
end
