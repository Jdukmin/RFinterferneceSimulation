classdef BlockingAnalyzer
    %BLOCKINGANALYZER Per-interferer blocking (ICD 5, Task 11-14, 33).
    %   Independent of spectral overlap: every interferer is evaluated by frequency
    %   offset, including out-of-band blockers with NO spectral overlap.
    methods (Static)
        function res = analyze(inputs, rxCenterFreq_Hz, criterion)
            NV = rfscreen.receiver.NonlinearValidity;
            s = struct();
            s.referencePlane = rfscreen.receiver.ReferencePlane.LNA_INPUT;
            s.warnings = {};
            entries = struct('txId', {}, 'blockerPower_dBm', {}, 'offset_Hz', {}, ...
                             'allowable_dBm', {}, 'margin_dB', {}, 'passFail', {}, 'validity', {});

            if isempty(criterion)
                s.entries = entries;
                s.worstMargin_dB = NaN; s.worstTxId = '';
                s.validity = NV.MISSING_BLOCKING_CRITERION;
                s.warnings{end+1} = 'no blocking criterion: blocking withheld';
                res = rfscreen.results.BlockingResult(s);
                return;
            end

            worst = Inf; worstTx = ''; nValid = 0;
            for k = 1:numel(inputs)
                e = struct();
                e.txId = inputs(k).txId;
                e.offset_Hz = inputs(k).freq_Hz - rxCenterFreq_Hz;
                e.allowable_dBm = criterion.allowableFor(e.offset_Hz);
                if inputs(k).isAbsolute && isfinite(inputs(k).lnaInputPower_dBm)
                    e.blockerPower_dBm = inputs(k).lnaInputPower_dBm;
                    ev = criterion.evaluate(e.blockerPower_dBm, e.offset_Hz);
                    e.margin_dB = ev.margin_dB; e.passFail = ev.pass; e.validity = NV.VALID;
                    nValid = nValid + 1;
                    if e.margin_dB < worst; worst = e.margin_dB; worstTx = e.txId; end
                else
                    e.blockerPower_dBm = NaN; e.margin_dB = NaN; e.passFail = 'UNKNOWN';
                    e.validity = NV.ABSOLUTE_COUPLING_UNAVAILABLE;
                end
                entries(end+1) = e; %#ok<AGROW>
            end
            s.entries = entries;
            if nValid == 0
                s.worstMargin_dB = NaN; s.worstTxId = '';
                s.validity = NV.ABSOLUTE_COUPLING_UNAVAILABLE;
                s.warnings{end+1} = 'no interferer has valid absolute coupling: blocking withheld';
            else
                s.worstMargin_dB = worst; s.worstTxId = worstTx;
                if nValid == numel(inputs)
                    s.validity = NV.VALID;
                else
                    s.validity = NV.INCOMPLETE_INTERFERER_SET;
                    s.warnings{end+1} = 'some interferers lack absolute evidence: blocking incomplete';
                end
            end
            res = rfscreen.results.BlockingResult(s);
        end
    end
end
