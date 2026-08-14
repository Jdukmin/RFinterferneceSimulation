classdef AntennaStructureFOVResult
    %ANTENNASTRUCTUREFOVRESULT Antenna-to-structure FOV evidence (ICD spacecraft_geometry.md 7).
    %   Geometry evidence only; carries no EM gain/loss value.
    properties
        antennaId = ''
        structureId = ''
        structureType = ''
        closestDistance_m = NaN
        centerAz_deg = NaN
        centerEl_deg = NaN
        centerOffBoresight_deg = NaN
        minAz_deg = NaN
        maxAz_deg = NaN
        minEl_deg = NaN
        maxEl_deg = NaN
        maxAngularRadius_deg = NaN
        occupiedLobes = {}
        centerLobe = ''
        centerRayHits = false
        geometryFidelity = ''
        validity = ''
        warnings = {}
    end
    methods
        function obj = AntennaStructureFOVResult(s)
            if nargin >= 1 && ~isempty(s) && isstruct(s)
                f = fieldnames(s);
                for i = 1:numel(f); if isprop(obj, f{i}); obj.(f{i}) = s.(f{i}); end; end
            end
        end
        function tf = occupies(obj, lobeClass)
            tf = any(strcmp(obj.occupiedLobes, lobeClass));
        end
    end
end
