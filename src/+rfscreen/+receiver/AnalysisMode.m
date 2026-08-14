classdef AnalysisMode
    %ANALYSISMODE Relative screening vs absolute linear RF (Task 16).
    properties (Constant)
        RELATIVE_SCREENING = 'RELATIVE_SCREENING'
        ABSOLUTE_LINEAR    = 'ABSOLUTE_LINEAR'
    end
    methods (Static)
        function v = values()
            v = {'RELATIVE_SCREENING', 'ABSOLUTE_LINEAR'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.receiver.AnalysisMode.values()));
        end
    end
end
