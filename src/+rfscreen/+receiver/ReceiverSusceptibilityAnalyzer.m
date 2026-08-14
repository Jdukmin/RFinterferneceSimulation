classdef ReceiverSusceptibilityAnalyzer
    %RECEIVERSUSCEPTIBILITYANALYZER Linear RF coexistence: spectral coupling +
    %   noise + criterion -> ReceiverSusceptibilityResult (ICD 8).
    %   Central rule: an absolute RF metric is produced ONLY with sufficient valid
    %   evidence; pattern-only DirectionalCouplingIndex is NEVER an absolute loss.
    methods (Static)
        function res = analyze(request)
            R  = rfscreen.receiver.ReferencePlane;
            AM = rfscreen.receiver.AnalysisMode;
            SV = rfscreen.receiver.SusceptibilityValidity;

            spatial = request.spatial;
            txSpectrum = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.field(request, 'txSpectrum', []);
            rxFilter   = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.field(request, 'rxFilter', []);
            noiseModel = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.field(request, 'noiseModel', []);
            criterion  = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.field(request, 'criterion', []);

            s = struct();
            s.referencePlane = R.RECEIVER_RF_INPUT;
            s.couplingValidity = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.field(spatial, 'couplingValidity', '');
            s.warnings = {};

            % ---- spectral coupling (no geometry, no absolute power) ----
            haveSpectrum = ~isempty(txSpectrum);
            haveFilter = ~isempty(rxFilter);
            if haveSpectrum && haveFilter
                spec = rfscreen.interference.SpectralCouplingAnalyzer.analyze(txSpectrum, rxFilter);
                s.spectralOverlapFraction = spec.overlapFraction;
                s.spectralFactor_dB = spec.spectralFactor_dB;
                s.warnings = [s.warnings, spec.warnings];
                s.noiseBandwidth_Hz = rxFilter.equivalentNoiseBandwidth_Hz();
            else
                s.spectralOverlapFraction = NaN;
                s.spectralFactor_dB = NaN;
                s.noiseBandwidth_Hz = NaN;
            end

            isAbs = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.field(spatial, 'isAbsolute', false);
            absT  = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.field(spatial, 'absoluteTransfer_dB', NaN);
            modeB = isAbs && isfinite(absT) && haveSpectrum && haveFilter;

            if modeB
                s.mode = AM.ABSOLUTE_LINEAR;
                txPow = spatial.txPower_dBm;
                s.interferencePower_dBm = txPow + absT + s.spectralFactor_dB;   % at RECEIVER_RF_INPUT

                if ~isempty(noiseModel) && isfinite(s.noiseBandwidth_Hz)
                    s.noisePower_dBm = noiseModel.noisePower_dBm(s.noiseBandwidth_Hz);
                else
                    s.noisePower_dBm = NaN;
                end
                if isfinite(s.interferencePower_dBm) && isfinite(s.noisePower_dBm)
                    s.iOverN_dB = s.interferencePower_dBm - s.noisePower_dBm;
                else
                    s.iOverN_dB = NaN;
                end

                if ~isempty(criterion)
                    ev = criterion.evaluate(s.interferencePower_dBm, s.noisePower_dBm);
                    s.thresholdType = ev.type; s.thresholdValue = ev.thresholdValue;
                    s.margin_dB = ev.margin_dB; s.passFail = ev.pass;
                end

                % validity precedence
                if isempty(noiseModel)
                    s.validity = SV.NOISE_MODEL_INCOMPLETE;
                    s.warnings{end+1} = 'no noise model: I/N unavailable';
                elseif isempty(criterion)
                    s.validity = SV.MISSING_CRITERION;
                    s.warnings{end+1} = 'no interference criterion: PASS/FAIL unavailable';
                else
                    s.validity = SV.VALID_ABSOLUTE;
                end
            else
                s.mode = AM.RELATIVE_SCREENING;
                s.interferencePower_dBm = NaN;
                s.noisePower_dBm = NaN;
                s.iOverN_dB = NaN;
                s.margin_dB = NaN;
                s.passFail = 'UNKNOWN';
                if ~isempty(criterion)
                    s.thresholdType = criterion.type; s.thresholdValue = criterion.thresholdValue;
                end
                if ~haveSpectrum
                    s.validity = SV.MISSING_SPECTRUM;
                    s.warnings{end+1} = 'no TX spectrum: spectral coupling unavailable';
                elseif ~haveFilter
                    s.validity = SV.MISSING_FILTER;
                    s.warnings{end+1} = 'no RX filter: spectral coupling unavailable';
                else
                    s.validity = SV.ABSOLUTE_COUPLING_UNAVAILABLE;
                    s.warnings{end+1} = ['relative screening only: coupling is not an absolute ' ...
                        'loss model; absolute RX interference power not produced'];
                end
            end

            s.confidence = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.confidence( ...
                s.couplingValidity, modeB, ~isempty(noiseModel), ~isempty(criterion));
            res = rfscreen.receiver.ReceiverSusceptibilityResult(s);
        end

        function res = analyzeFromPair(pairResult, txPower_dBm, txSpectrum, rxFilter, noiseModel, criterion)
            %ANALYZEFROMPAIR Build spatial evidence from a Phase-1 PairResult and analyze.
            %   Reuses Phase-1 coupling; does NOT recompute geometry (AR-213).
            pr = pairResult;
            spatial = struct();
            spatial.txGain_dBi = pr.txGain_dBi;
            spatial.rxGain_dBi = pr.rxGain_dBi;
            spatial.txPower_dBm = txPower_dBm;
            isFarField = strcmp(pr.couplingModelType, 'FAR_FIELD');
            if isFarField && pr.isPhysicalCoupling && isfinite(pr.couplingMetric_dB)
                spatial.isAbsolute = true;
                spatial.absoluteTransfer_dB = pr.txGain_dBi + pr.rxGain_dBi - pr.couplingMetric_dB;
                spatial.couplingValidity = 'FAR_FIELD_VALID';
            else
                spatial.isAbsolute = false;
                spatial.absoluteTransfer_dB = NaN;
                if strcmp(pr.couplingModelType, 'PATTERN_ONLY')
                    spatial.couplingValidity = 'PATTERN_ONLY';
                elseif isFarField
                    spatial.couplingValidity = 'FAR_FIELD_INVALID_OR_UNKNOWN';
                else
                    spatial.couplingValidity = '';
                end
            end
            if nargin < 5; noiseModel = []; end
            if nargin < 6; criterion = []; end
            request = struct('spatial', spatial, 'txSpectrum', txSpectrum, 'rxFilter', rxFilter, ...
                             'noiseModel', noiseModel, 'criterion', criterion);
            res = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.analyze(request);
        end
    end

    methods (Static, Access = private)
        function v = field(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
        function c = confidence(couplingValidity, modeB, haveNoise, haveCrit)
            switch couplingValidity
                case 'FULL_WAVE_COUPLING'; c = 0.95;
                case 'MEASURED_COUPLING';  c = 0.90;
                case 'FAR_FIELD_VALID';    c = 0.70;
                case 'PATTERN_ONLY';       c = 0.30;
                case 'FAR_FIELD_INVALID_OR_UNKNOWN'; c = 0.20;
                otherwise;                 c = 0.50;
            end
            if ~modeB; c = min(c, 0.40); end
            if modeB && ~haveNoise; c = c - 0.10; end
            if modeB && ~haveCrit;  c = c - 0.05; end
            c = max(min(c, 1.0), 0.0);
        end
    end
end
