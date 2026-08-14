classdef InstalledPatternPolicy
    %INSTALLEDPATTERNPOLICY Pattern-selection policy (ICD installed_environment.md 4, Task 40).
    properties (Constant)
        PREFER_INSTALLED  = 'PREFER_INSTALLED'
        REQUIRE_INSTALLED = 'REQUIRE_INSTALLED'
    end
    methods (Static)
        function v = values()
            v = {'PREFER_INSTALLED', 'REQUIRE_INSTALLED'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.installed.InstalledPatternPolicy.values()));
        end
    end
end
