classdef GeometryRisk
    %GEOMETRYRISK Geometry-based screening risk (ICD installed_environment.md 6, Task 25).
    %   SCREENING ONLY. Distinct from physical RF interference margins; it never
    %   overwrites Phase-3/4 physical results.
    properties (Constant)
        NA       = 'NA'
        LOW      = 'LOW'
        MODERATE = 'MODERATE'
        HIGH     = 'HIGH'
    end
    methods (Static)
        function v = values()
            v = {'NA', 'LOW', 'MODERATE', 'HIGH'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.installed.GeometryRisk.values()));
        end
    end
end
