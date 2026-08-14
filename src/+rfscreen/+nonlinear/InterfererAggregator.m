classdef InterfererAggregator
    %INTERFERERAGGREGATOR Linear aggregate of interferer LNA-input powers (Task 8-10).
    %   Aggregates ONLY interferers with valid absolute power at the same plane;
    %   never sums dBm directly; never treats a missing interferer as zero power.
    methods (Static)
        function agg = aggregate(inputs)
            %AGGREGATE inputs: struct array with fields isAbsolute, lnaInputPower_dBm.
            %   Returns struct(aggregate_dBm, nTotal, nValid, complete).
            nTotal = numel(inputs);
            valid = [];
            for k = 1:nTotal
                if inputs(k).isAbsolute && isfinite(inputs(k).lnaInputPower_dBm)
                    valid(end+1) = inputs(k).lnaInputPower_dBm; %#ok<AGROW>
                end
            end
            nValid = numel(valid);
            if nValid == 0
                aggregate_dBm = NaN;
            else
                aggregate_dBm = rfscreen.util.Units.sumPowers_dBm(valid);
            end
            agg = struct('aggregate_dBm', aggregate_dBm, 'nTotal', nTotal, ...
                         'nValid', nValid, 'complete', nValid == nTotal);
        end
    end
end
