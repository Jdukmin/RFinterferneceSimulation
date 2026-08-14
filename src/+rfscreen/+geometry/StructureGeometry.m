classdef StructureGeometry
    %STRUCTUREGEOMETRY Abstract primitive geometry in the structure local frame
    %   (ICD spacecraft_geometry.md 2). Concrete: BoxGeometry, PanelGeometry.
    %   Deterministic, math-based; no CAD kernel. MESH/EXTERNAL is reserved.
    methods
        function v = verticesLocal(obj) %#ok<STOUT,MANU>
            error('rfscreen:geometry:abstract', 'verticesLocal must be implemented by a subclass.');
        end
        function [hit, tHit] = rayIntersectLocal(obj, o_S, d_S) %#ok<STOUT,INUSD>
            error('rfscreen:geometry:abstract', 'rayIntersectLocal must be implemented by a subclass.');
        end
        function r = boundingRadius(obj) %#ok<STOUT,MANU>
            error('rfscreen:geometry:abstract', 'boundingRadius must be implemented by a subclass.');
        end
        function s = describe(obj) %#ok<MANU>
            s = 'StructureGeometry';
        end
    end
end
