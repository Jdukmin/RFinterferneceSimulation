classdef InstallationValidity
    %INSTALLATIONVALIDITY Installed-environment validity codes (ICD installed_environment.md 7).
    properties (Constant)
        INSTALLED_PATTERN_AVAILABLE   = 'INSTALLED_PATTERN_AVAILABLE'
        FREE_SPACE_FALLBACK           = 'FREE_SPACE_FALLBACK'
        INSTALLATION_EFFECT_UNKNOWN   = 'INSTALLATION_EFFECT_UNKNOWN'
        REQUIRE_INSTALLED_UNAVAILABLE = 'REQUIRE_INSTALLED_UNAVAILABLE'
        GEOMETRY_ONLY                 = 'GEOMETRY_ONLY'
        UNSUPPORTED_EM_PHYSICS        = 'UNSUPPORTED_EM_PHYSICS'
    end
    methods (Static)
        function v = values()
            v = {'INSTALLED_PATTERN_AVAILABLE','FREE_SPACE_FALLBACK','INSTALLATION_EFFECT_UNKNOWN', ...
                 'REQUIRE_INSTALLED_UNAVAILABLE','GEOMETRY_ONLY','UNSUPPORTED_EM_PHYSICS'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.installed.InstallationValidity.values()));
        end
    end
end
