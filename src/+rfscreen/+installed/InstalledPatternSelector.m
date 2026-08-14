classdef InstalledPatternSelector
    %INSTALLEDPATTERNSELECTOR Deterministic pattern selection (ICD installed_environment.md 4).
    %   NEVER silently falls back; NEVER derives an installed pattern from geometry.
    %   Fidelity/provenance propagate unchanged.
    methods (Static)
        function sel = select(freeSpacePattern, installedPattern, policy)
            if nargin < 3 || isempty(policy)
                policy = rfscreen.installed.InstalledPatternPolicy.PREFER_INSTALLED;
            end
            rfscreen.util.Validate.member(policy, ...
                rfscreen.installed.InstalledPatternPolicy.values(), 'policy');
            PSU = rfscreen.installed.PatternSourceUsed;
            IV = rfscreen.installed.InstallationValidity;

            haveInstalled = ~isempty(installedPattern) && ...
                isa(installedPattern, 'rfscreen.antenna.InstalledPattern');

            sel = struct('pattern', [], 'sourceUsed', '', 'installationValidity', '', ...
                'provenance', '', 'installedSource', '', 'warnings', {{}});

            if haveInstalled
                sel.pattern = installedPattern;
                sel.sourceUsed = PSU.INSTALLED;
                sel.installationValidity = IV.INSTALLED_PATTERN_AVAILABLE;
                sel.provenance = installedPattern.provenance;       % propagated, not upgraded
                sel.installedSource = installedPattern.installedSource;
            elseif strcmp(policy, rfscreen.installed.InstalledPatternPolicy.REQUIRE_INSTALLED)
                sel.pattern = [];
                sel.sourceUsed = PSU.NONE;
                sel.installationValidity = IV.REQUIRE_INSTALLED_UNAVAILABLE;
                sel.warnings{end+1} = 'REQUIRE_INSTALLED: no installed pattern available; result withheld';
            else
                % PREFER_INSTALLED with no installed pattern -> explicit free-space fallback
                sel.pattern = freeSpacePattern;
                sel.sourceUsed = PSU.FREE_SPACE_FALLBACK;
                sel.installationValidity = IV.INSTALLATION_EFFECT_UNKNOWN;
                if ~isempty(freeSpacePattern)
                    sel.provenance = freeSpacePattern.provenance;
                end
                sel.warnings{end+1} = 'no installed pattern: free-space fallback (installation effect UNKNOWN)';
            end
        end
    end
end
