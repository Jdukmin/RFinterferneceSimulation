classdef FreeSpacePattern < rfscreen.antenna.AntennaPattern
    %FREESPACEPATTERN Isolated (free-space) antenna pattern (SR-051, VR-084).
    %   Distinct type from InstalledPattern: it carries NO installed source,
    %   so a free-space pattern can never be mistaken for an installed one.
    methods
        function obj = FreeSpacePattern(name, provenance, grid, opts)
            if nargin < 4; opts = struct(); end
            obj@rfscreen.antenna.AntennaPattern(name, provenance, grid, opts);
        end

        function tf = isInstalled(obj) %#ok<MANU>
            tf = false;
        end

        function s = patternClass(obj) %#ok<MANU>
            s = 'FreeSpace';
        end
    end
end
