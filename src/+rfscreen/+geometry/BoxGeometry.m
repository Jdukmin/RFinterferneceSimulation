classdef BoxGeometry < rfscreen.geometry.StructureGeometry
    %BOXGEOMETRY Axis-aligned box in the structure local frame (ICD 2).
    %   Extent [-hx,hx] x [-hy,hy] x [-hz,hz]. Slab-method ray intersection.
    properties (SetAccess = private)
        halfSizes_m   % 3x1 [hx; hy; hz]
    end
    methods
        function obj = BoxGeometry(halfSizes_m)
            h = rfscreen.util.Validate.vector3(halfSizes_m, 'halfSizes_m');
            if any(h <= 0)
                error('rfscreen:geometry:badBox', 'halfSizes_m must be > 0.');
            end
            obj.halfSizes_m = h;
        end

        function v = verticesLocal(obj)
            h = obj.halfSizes_m;
            s = [-1 1];
            v = zeros(3, 8); k = 0;
            for a = s; for b = s; for c = s
                k = k + 1; v(:, k) = [a*h(1); b*h(2); c*h(3)];
            end; end; end
        end

        function [hit, tHit] = rayIntersectLocal(obj, o_S, d_S)
            %RAYINTERSECTLOCAL Slab method. Unit d_S -> tHit in meters.
            o = o_S(:); d = d_S(:); h = obj.halfSizes_m;
            lo = -h; hi = h;
            tmin = -Inf; tmax = Inf; tol = 1e-12;
            for i = 1:3
                if abs(d(i)) < tol
                    if o(i) < lo(i) - tol || o(i) > hi(i) + tol
                        hit = false; tHit = NaN; return;   % parallel & outside slab
                    end
                else
                    t1 = (lo(i) - o(i)) / d(i);
                    t2 = (hi(i) - o(i)) / d(i);
                    if t1 > t2; tmp = t1; t1 = t2; t2 = tmp; end
                    tmin = max(tmin, t1);
                    tmax = min(tmax, t2);
                    if tmin > tmax + tol
                        hit = false; tHit = NaN; return;
                    end
                end
            end
            if tmax < -tol
                hit = false; tHit = NaN; return;           % box entirely behind origin
            end
            if tmin >= -tol
                tHit = tmin;                                % entry point ahead
            else
                tHit = tmax;                                % origin inside box
            end
            if tHit < 0; tHit = 0; end
            hit = true;
        end

        function r = boundingRadius(obj)
            r = norm(obj.halfSizes_m);
        end
        function s = describe(obj)
            s = sprintf('Box[%.3g x %.3g x %.3g m]', 2*obj.halfSizes_m(1), ...
                2*obj.halfSizes_m(2), 2*obj.halfSizes_m(3));
        end
    end
end
