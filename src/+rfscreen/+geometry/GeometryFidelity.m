classdef GeometryFidelity
    %GEOMETRYFIDELITY Explicit geometry-analysis fidelity (DR-401, Task 14).
    properties (Constant)
        CENTER_POINT      = 'CENTER_POINT'
        BOUNDING_VOLUME   = 'BOUNDING_VOLUME'
        VERTEX_SAMPLED    = 'VERTEX_SAMPLED'
        SURFACE_SAMPLED   = 'SURFACE_SAMPLED'
        MESH_INTERSECTION = 'MESH_INTERSECTION'
    end
    methods (Static)
        function v = values()
            v = {'CENTER_POINT','BOUNDING_VOLUME','VERTEX_SAMPLED','SURFACE_SAMPLED','MESH_INTERSECTION'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.geometry.GeometryFidelity.values()));
        end
    end
end
