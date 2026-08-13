classdef RiskLevel
    %RISKLEVEL Screening risk level for a matrix cell (AR-072).
    properties (Constant)
        NA   = 'NA'      % self-pair / not analyzed
        OK   = 'OK'
        LOW  = 'LOW'
        WARN = 'WARN'
        HIGH = 'HIGH'
    end
    methods (Static)
        function v = values()
            v = {'NA', 'OK', 'LOW', 'WARN', 'HIGH'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.results.RiskLevel.values()));
        end
    end
end
