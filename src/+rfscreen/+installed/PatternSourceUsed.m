classdef PatternSourceUsed
    %PATTERNSOURCEUSED Which pattern the selection used (ICD installed_environment.md 4).
    properties (Constant)
        INSTALLED           = 'INSTALLED'
        FREE_SPACE_FALLBACK = 'FREE_SPACE_FALLBACK'
        NONE                = 'NONE'
    end
    methods (Static)
        function v = values()
            v = {'INSTALLED', 'FREE_SPACE_FALLBACK', 'NONE'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.installed.PatternSourceUsed.values()));
        end
    end
end
