classdef PrismHull
    %PRISMHULL Convex polygonal cross-section (body Y-Z) extruded along +X_B (ICD mission_spacecraft.md 4).
    %   Pure deterministic math on the exact SSOT vertices: edge lengths, outward
    %   normals, supporting-plane distances, area/perimeter/centroid, circumradius,
    %   volume, side-panel frames, and signed plane offsets of external points.
    %   Edge k runs from vertex k to vertex k+1 (wrapping). Vertices must be CCW in
    %   (Y,Z) so that the outward normal of edge (dY,dZ) is (dZ,-dY)/|.|.
    %   Geometry evidence only: no EM quantity is produced.
    properties (SetAccess = private)
        vertexIds       % 1xN cellstr
        yz_m            % 2xN (Y;Z) vertices [m]
        xMin_m
        xMax_m
        section         % geometry.ConvexPolygonGeometry of the (Y,Z) cross-section
    end
    methods
        function obj = PrismHull(vertexIds, yz_m, xMin_m, xMax_m)
            V = rfscreen.util.Validate;
            if ~(iscellstr(vertexIds) && numel(vertexIds) == size(yz_m, 2))
                error('rfscreen:spacecraft:badHull', 'vertexIds must be a cellstr matching yz_m columns.');
            end
            if numel(unique(vertexIds)) ~= numel(vertexIds)
                error('rfscreen:spacecraft:badHull', 'vertex ids must be unique.');
            end
            obj.section = rfscreen.geometry.ConvexPolygonGeometry(yz_m);   % validates convexity/uniqueness
            if ~obj.section.isCCW
                error('rfscreen:spacecraft:badHull', 'cross-section vertices must be counter-clockwise in (Y,Z).');
            end
            obj.vertexIds = vertexIds(:).';
            obj.yz_m = double(yz_m);
            obj.xMin_m = V.finiteScalar(xMin_m, 'xMin_m');
            obj.xMax_m = V.finiteScalar(xMax_m, 'xMax_m');
            if obj.xMax_m <= obj.xMin_m
                error('rfscreen:spacecraft:badHull', 'xMax_m must exceed xMin_m.');
            end
        end

        function n = nVertices(obj);    n = size(obj.yz_m, 2); end
        function L = length_m(obj);     L = obj.xMax_m - obj.xMin_m; end
        function L = edgeLengths(obj);  L = obj.section.edgeLengths(); end
        function A = area(obj);         A = obj.section.area(); end
        function p = perimeter(obj);    p = obj.section.perimeter(); end
        function c = centroid(obj);     c = obj.section.centroid(); end
        function v = volume(obj);       v = obj.area() * obj.length_m(); end
        function a = sideAreas(obj);    a = obj.edgeLengths() * obj.length_m(); end

        function r = vertexRadii(obj)
            %VERTEXRADII Distance of each vertex from the centre axis (Y=Z=0).
            r = sqrt(sum(obj.yz_m.^2, 1));
        end
        function r = circumradius(obj); r = max(obj.vertexRadii()); end

        function k = edgeIndex(obj, fromId, toId)
            %EDGEINDEX Index k of the edge fromId -> toId (must be consecutive, CCW).
            i = find(strcmp(obj.vertexIds, fromId));
            j = find(strcmp(obj.vertexIds, toId));
            n = obj.nVertices();
            if isempty(i) || isempty(j) || j ~= mod(i, n) + 1
                error('rfscreen:spacecraft:badEdge', ...
                    'edge %s -> %s is not a consecutive CCW hull edge.', fromId, toId);
            end
            k = i;
        end

        function nB = sideNormal_B(obj, k)
            %SIDENORMAL_B Outward unit normal of side edge k in the body frame.
            [a, b] = obj.edgeEnds(k);
            e = b - a;
            nB = [0; e(2); -e(1)] / norm(e);
        end
        function d = supportDistance(obj, k)
            %SUPPORTDISTANCE Centre-axis normal distance of side edge k's supporting plane.
            [a, ~] = obj.edgeEnds(k);
            nB = obj.sideNormal_B(k);
            d = nB(2:3).' * a;
        end
        function c = sideCenter_B(obj, k)
            %SIDECENTER_B Geometric centre of side panel k in the body frame.
            [a, b] = obj.edgeEnds(k);
            m = (a + b) / 2;
            c = [(obj.xMin_m + obj.xMax_m) / 2; m];
        end
        function R = sideR_BS(obj, k)
            %SIDER_BS Structure->body DCM for side panel k as a PanelGeometry:
            %   x_S = +X_B (extrusion), z_S = outward normal, y_S = z_S x x_S.
            xS = [1; 0; 0];
            zS = obj.sideNormal_B(k);
            yS = cross(zS, xS);
            R = [xS, yS, zS];
        end

        function off = sideOffset(obj, p_B, k)
            %SIDEOFFSET Signed distance of p_B from side plane k (>0 outside).
            p_B = rfscreen.util.Validate.vector3(p_B, 'p_B');
            nB = obj.sideNormal_B(k);
            off = nB.' * p_B - obj.supportDistance(k);
        end
        function off = endOffset(obj, p_B, which)
            %ENDOFFSET Signed distance of p_B from the 'MAX' (+X) or 'MIN' (-X) end plane.
            p_B = rfscreen.util.Validate.vector3(p_B, 'p_B');
            if strcmp(which, 'MAX'); off = p_B(1) - obj.xMax_m; else; off = obj.xMin_m - p_B(1); end
        end
        function d = hullSignedDistance(obj, p_B)
            %HULLSIGNEDDISTANCE max over all bounding planes of the signed plane offset.
            %   <0 strictly inside the convex prism, 0 on its boundary, >0 outside.
            d = max(obj.endOffset(p_B, 'MAX'), obj.endOffset(p_B, 'MIN'));
            for k = 1:obj.nVertices()
                d = max(d, obj.sideOffset(p_B, k));
            end
        end
    end
    methods (Access = private)
        function [a, b] = edgeEnds(obj, k)
            n = obj.nVertices();
            if ~(isscalar(k) && k >= 1 && k <= n && k == round(k))
                error('rfscreen:spacecraft:badEdge', 'edge index must be an integer in 1..%d.', n);
            end
            a = obj.yz_m(:, k); b = obj.yz_m(:, mod(k, n) + 1);
        end
    end
end
