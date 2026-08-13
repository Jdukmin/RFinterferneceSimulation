classdef InstalledPattern < rfscreen.antenna.AntennaPattern
    %INSTALLEDPATTERN Installed (on-platform) antenna pattern (SR-051, DR-032).
    %   Distinct type from FreeSpacePattern; additionally records installedSource
    %   (MEASURED/HFSS/CST/OTHER_SOLVER/APPROXIMATE). Phase 1 does NOT generate
    %   installed patterns (Task 10); this class fixes the import contract only.
    properties (SetAccess = private)
        installedSource     % InstalledPatternSource char
    end
    methods
        function obj = InstalledPattern(name, provenance, grid, installedSource, opts)
            if nargin < 5; opts = struct(); end
            obj@rfscreen.antenna.AntennaPattern(name, provenance, grid, opts);
            obj.installedSource = rfscreen.util.Validate.member(installedSource, ...
                rfscreen.antenna.InstalledPatternSource.values(), 'installedSource');
        end

        function tf = isInstalled(obj) %#ok<MANU>
            tf = true;
        end

        function s = patternClass(obj) %#ok<MANU>
            s = 'Installed';
        end
    end
end
