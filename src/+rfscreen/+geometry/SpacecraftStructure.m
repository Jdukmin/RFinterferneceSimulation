classdef SpacecraftStructure
    %SPACECRAFTSTRUCTURE Spacecraft structure with body-frame placement (ICD 3).
    %   Geometry defined in the structure local frame S; v_B = R_BS*v_S + origin_m.
    %   Provides body-frame vertices, centroid, and ray intersection. Type is
    %   metadata; algorithms do not depend strongly on it (Task 7).
    properties (SetAccess = private)
        id
        name
        structureType
        geometry            % geometry.StructureGeometry
        R_BS                % 3x3 structure->body
        origin_m            % 3x1 body-frame origin
        configId            % '' = configuration-independent
        deploymentState
        active
        provenance
    end
    methods
        function obj = SpacecraftStructure(id, name, structureType, geometry, R_BS, origin_m, opts)
            if nargin < 7 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            obj.id = V.id(id, 'SpacecraftStructure.id');
            obj.name = V.id(name, 'SpacecraftStructure.name');
            obj.structureType = V.member(structureType, ...
                rfscreen.geometry.StructureType.values(), 'structureType');
            if ~isa(geometry, 'rfscreen.geometry.StructureGeometry')
                error('rfscreen:geometry:badGeometry', 'geometry must be a StructureGeometry.');
            end
            obj.geometry = geometry;
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BS, 'R_BS');
            obj.R_BS = double(R_BS);
            obj.origin_m = V.vector3(origin_m, 'origin_m');

            g = @(nm, dflt) rfscreen.geometry.SpacecraftStructure.opt(opts, nm, dflt);
            obj.configId = g('configId', '');
            obj.deploymentState = V.member(g('deploymentState', ...
                rfscreen.geometry.DeploymentState.DEPLOYED), ...
                rfscreen.geometry.DeploymentState.values(), 'deploymentState');
            av = g('active', true); obj.active = logical(av);
            obj.provenance = V.member(g('provenance', ...
                rfscreen.geometry.GeometryProvenance.SYNTHETIC_TEST), ...
                rfscreen.geometry.GeometryProvenance.values(), 'provenance');
        end

        function v = verticesBody(obj)
            vl = obj.geometry.verticesLocal();
            v = obj.R_BS * vl + repmat(obj.origin_m, 1, size(vl, 2));
        end

        function c = centroidBody(obj)
            v = obj.verticesBody();
            c = mean(v, 2);
        end

        function [hit, tHit] = rayIntersectBody(obj, o_B, d_B)
            %RAYINTERSECTBODY Intersect a body-frame ray (unit d_B) with this structure.
            o_B = rfscreen.util.Validate.vector3(o_B, 'o_B');
            d_B = rfscreen.util.Validate.vector3(d_B, 'd_B');
            nd = norm(d_B);
            if nd <= 0
                error('rfscreen:geometry:zeroDir', 'd_B must be non-zero.');
            end
            d_B = d_B / nd;
            o_S = obj.R_BS.' * (o_B - obj.origin_m);
            d_S = obj.R_BS.' * d_B;                 % rotation preserves norm -> unit
            [hit, tHit] = obj.geometry.rayIntersectLocal(o_S, d_S);
        end
    end
    methods (Static, Access = private)
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
    end
end
