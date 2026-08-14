classdef SamplingType
    %SAMPLINGTYPE Angular sampling classification (DR-104, §7).
    properties (Constant)
        UNIFORM     = 'UNIFORM'
        NON_UNIFORM = 'NON_UNIFORM'
        INVALID     = 'INVALID'
    end
    methods (Static)
        function v = values()
            v = {'UNIFORM', 'NON_UNIFORM', 'INVALID'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.patterndata.SamplingType.values()));
        end
    end
end
