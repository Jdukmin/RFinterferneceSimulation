classdef ConvexPolygonGeometry < rfscreen.geometry.StructureGeometry
    %CONVEXPOLYGONGEOMETRY Exact flat convex polygon in the local XY plane (z=0), normal +Z_S.
    %   Models an arbitrary planar convex face (e.g. an irregular hexagonal end cap)
    %   from its exact vertex list -- no regular-polygon, rectangle, disk or triangle
    %   approximation. Vertices are kept exactly as given (order and count), so the
    %   VERTEX_SAMPLED footprint samples the true corners. Ray-plane + in-polygon test
    %   (edge half-planes). Geometry evidence only: no EM quantity is produced.
    properties (SetAccess = private)
        vertices2D_m    % 2xN local (x,y) vertices, consecutive = edges (wrapping)
        isCCW           % true if the vertex order is counter-clockwise in local XY
    end
    methods
        function obj = ConvexPolygonGeometry(vertices2D_m)
            if ~(isnumeric(vertices2D_m) && isreal(vertices2D_m) && size(vertices2D_m, 1) == 2 ...
                    && size(vertices2D_m, 2) >= 3 && all(isfinite(vertices2D_m(:))))
                error('rfscreen:geometry:badPolygon', ...
                    'vertices2D_m must be a finite real 2xN array with N >= 3.');
            end
            v = double(vertices2D_m);
            n = size(v, 2);
            scale = max(1, max(abs(v(:))));
            tol = 1e-12 * scale;
            % unique vertices (no repeated/closing vertex)
            for i = 1:n
                for j = i+1:n
                    if norm(v(:, i) - v(:, j)) <= tol
                        error('rfscreen:geometry:badPolygon', ...
                            'polygon vertices %d and %d coincide.', i, j);
                    end
                end
            end
            % strict convexity: all consecutive edge cross products share one sign
            cr = zeros(1, n);
            for i = 1:n
                e1 = v(:, mod(i, n) + 1) - v(:, i);
                e2 = v(:, mod(i + 1, n) + 1) - v(:, mod(i, n) + 1);
                cr(i) = e1(1) * e2(2) - e1(2) * e2(1);
            end
            if ~(all(cr > tol * scale) || all(cr < -tol * scale))
                error('rfscreen:geometry:badPolygon', ...
                    'polygon is not strictly convex (collinear or reflex vertex).');
            end
            % simple polygon: exterior angles of a convex polygon sum to exactly 360 deg
            turn = 0;
            for i = 1:n
                e1 = v(:, mod(i, n) + 1) - v(:, i);
                e2 = v(:, mod(i + 1, n) + 1) - v(:, mod(i, n) + 1);
                turn = turn + atan2(e1(1) * e2(2) - e1(2) * e2(1), dot(e1, e2));
            end
            if abs(abs(turn) - 2*pi) > 1e-9
                error('rfscreen:geometry:badPolygon', ...
                    'polygon is self-intersecting (total turning %.6g rad).', turn);
            end
            obj.vertices2D_m = v;
            obj.isCCW = cr(1) > 0;
        end

        function v = verticesLocal(obj)
            v = [obj.vertices2D_m; zeros(1, size(obj.vertices2D_m, 2))];
        end

        function [hit, tHit] = rayIntersectLocal(obj, o_S, d_S)
            o = o_S(:); d = d_S(:); tol = 1e-12;
            if abs(d(3)) < tol
                hit = false; tHit = NaN; return;      % ray parallel to polygon plane
            end
            t = -o(3) / d(3);
            if t < -tol
                hit = false; tHit = NaN; return;      % intersection behind origin
            end
            p = o + t * d;
            if obj.containsPoint(p(1:2))
                hit = true; tHit = max(t, 0);
            else
                hit = false; tHit = NaN;
            end
        end

        function tf = containsPoint(obj, p2)
            %CONTAINSPOINT True if local (x,y) point lies inside or on the polygon boundary.
            v = obj.vertices2D_m; n = size(v, 2);
            tol = 1e-12 * max(1, max(abs(v(:))));
            sgn = 1; if ~obj.isCCW; sgn = -1; end
            tf = true;
            for i = 1:n
                a = v(:, i); b = v(:, mod(i, n) + 1);
                e = b - a; w = p2(:) - a;
                c = sgn * (e(1) * w(2) - e(2) * w(1)) / norm(e);   % signed distance (inside > 0)
                if c < -tol
                    tf = false; return;
                end
            end
        end

        function L = edgeLengths(obj)
            v = obj.vertices2D_m; n = size(v, 2);
            L = zeros(1, n);
            for i = 1:n
                L(i) = norm(v(:, mod(i, n) + 1) - v(:, i));
            end
        end
        function p = perimeter(obj)
            p = sum(obj.edgeLengths());
        end
        function A = area(obj)
            A = abs(obj.signedArea());
        end
        function c = centroid(obj)
            %CENTROID Area centroid (local x,y).
            v = obj.vertices2D_m; n = size(v, 2);
            cx = 0; cy = 0;
            for i = 1:n
                j = mod(i, n) + 1;
                k = v(1, i) * v(2, j) - v(1, j) * v(2, i);
                cx = cx + (v(1, i) + v(1, j)) * k;
                cy = cy + (v(2, i) + v(2, j)) * k;
            end
            A = obj.signedArea();
            c = [cx; cy] / (6 * A);
        end

        function r = boundingRadius(obj)
            r = max(sqrt(sum(obj.vertices2D_m.^2, 1)));
        end
        function s = describe(obj)
            s = sprintf('ConvexPolygon[%d vertices, A=%.6g m^2]', size(obj.vertices2D_m, 2), obj.area());
        end
    end
    methods (Access = private)
        function A = signedArea(obj)
            v = obj.vertices2D_m; n = size(v, 2); A = 0;
            for i = 1:n
                j = mod(i, n) + 1;
                A = A + v(1, i) * v(2, j) - v(1, j) * v(2, i);
            end
            A = A / 2;
        end
    end
end
