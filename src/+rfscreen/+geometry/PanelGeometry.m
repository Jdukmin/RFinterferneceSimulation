classdef PanelGeometry < rfscreen.geometry.StructureGeometry
    %PANELGEOMETRY Flat rectangle in the local XY plane (z=0), normal +Z_S (ICD 2).
    %   Spans [-w/2,w/2] x [-h/2,h/2]. Ray-plane + in-bounds intersection.
    properties (SetAccess = private)
        width_m
        height_m
    end
    methods
        function obj = PanelGeometry(width_m, height_m)
            V = rfscreen.util.Validate;
            obj.width_m = V.positiveScalar(width_m, 'width_m');
            obj.height_m = V.positiveScalar(height_m, 'height_m');
        end

        function v = verticesLocal(obj)
            w = obj.width_m/2; h = obj.height_m/2;
            v = [ -w  w  w -w;
                  -h -h  h  h;
                   0  0  0  0 ];
        end

        function [hit, tHit] = rayIntersectLocal(obj, o_S, d_S)
            o = o_S(:); d = d_S(:); tol = 1e-12;
            if abs(d(3)) < tol
                hit = false; tHit = NaN; return;      % ray parallel to panel plane
            end
            t = -o(3) / d(3);
            if t < -tol
                hit = false; tHit = NaN; return;       % intersection behind origin
            end
            p = o + t * d;
            if abs(p(1)) <= obj.width_m/2 + tol && abs(p(2)) <= obj.height_m/2 + tol
                hit = true; tHit = max(t, 0);
            else
                hit = false; tHit = NaN;
            end
        end

        function r = boundingRadius(obj)
            r = 0.5 * sqrt(obj.width_m^2 + obj.height_m^2);
        end
        function s = describe(obj)
            s = sprintf('Panel[%.3g x %.3g m]', obj.width_m, obj.height_m);
        end
    end
end
