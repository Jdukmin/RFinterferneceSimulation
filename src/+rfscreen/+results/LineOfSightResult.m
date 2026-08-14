classdef LineOfSightResult
    %LINEOFSIGHTRESULT Antenna-to-antenna LOS blockage evidence (ICD spacecraft_geometry.md 8).
    %   BLOCKED is geometry evidence only; it never implies an RF attenuation value.
    properties
        antennaAId = ''
        antennaBId = ''
        status = ''
        blockingStructureIds = {}
        intersectionCount = 0
        segmentLength_m = NaN
        geometryFidelity = ''
        validity = ''
        warnings = {}
    end
    methods
        function obj = LineOfSightResult(s)
            if nargin >= 1 && ~isempty(s) && isstruct(s)
                f = fieldnames(s);
                for i = 1:numel(f); if isprop(obj, f{i}); obj.(f{i}) = s.(f{i}); end; end
            end
        end
        function tf = isBlocked(obj)
            tf = strcmp(obj.status, rfscreen.geometry.LineOfSightStatus.BLOCKED);
        end
    end
end
