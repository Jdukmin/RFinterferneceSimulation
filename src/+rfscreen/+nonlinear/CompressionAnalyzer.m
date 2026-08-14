classdef CompressionAnalyzer
    %COMPRESSIONANALYZER Aggregate P1dB compression screening (ICD 4, Task 7, 32).
    %   CompressionMargin = p1dB_in - P_agg. Requires valid absolute evidence and
    %   a P1dB value; otherwise the result is withheld with explicit validity.
    methods (Static)
        function res = analyze(inputs, frontEnd, criterion)
            if nargin < 3; criterion = []; end
            NV = rfscreen.receiver.NonlinearValidity;
            s = struct();
            s.referencePlane = rfscreen.receiver.ReferencePlane.LNA_INPUT;
            s.warnings = {};

            agg = rfscreen.nonlinear.InterfererAggregator.aggregate(inputs);
            s.aggregateInputPower_dBm = agg.aggregate_dBm;
            s.nInterferers = agg.nTotal;
            s.nValidInterferers = agg.nValid;

            hasFE = ~isempty(frontEnd);
            hasP1 = hasFE && frontEnd.hasP1dB();
            if hasP1
                s.p1dB_in_dBm = frontEnd.p1dB_in_dBm;
            else
                s.p1dB_in_dBm = NaN;
            end

            if agg.nValid == 0
                s.validity = NV.ABSOLUTE_COUPLING_UNAVAILABLE;
                s.warnings{end+1} = 'no interferer has valid absolute coupling: compression withheld';
            elseif ~hasFE
                s.validity = NV.MISSING_FRONT_END;
                s.warnings{end+1} = 'no receiver front-end model: compression withheld';
            elseif ~hasP1
                s.validity = NV.MISSING_P1DB;
                s.warnings{end+1} = 'no P1dB_in: compression margin withheld';
            else
                s.compressionMargin_dB = s.p1dB_in_dBm - s.aggregateInputPower_dBm;
                if ~isempty(criterion)
                    ev = criterion.evaluate(s.p1dB_in_dBm, s.aggregateInputPower_dBm);
                    s.compressionMargin_dB = ev.margin_dB;
                    s.passFail = ev.pass;
                else
                    if s.compressionMargin_dB >= 0; s.passFail = 'PASS'; else; s.passFail = 'FAIL'; end
                end
                if ~agg.complete
                    s.validity = NV.INCOMPLETE_INTERFERER_SET;
                    s.warnings{end+1} = 'some active interferers lack absolute evidence: aggregate incomplete';
                else
                    s.validity = NV.VALID;
                end
            end
            res = rfscreen.results.CompressionResult(s);
        end
    end
end
