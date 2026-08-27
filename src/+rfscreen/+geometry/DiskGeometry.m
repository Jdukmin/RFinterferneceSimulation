classdef DiskGeometry < rfscreen.geometry.StructureGeometry
    %DISKGEOMETRY Circular flat disk in the local XY plane (z=0), normal +Z_S.
    %   Models a reflector / dish antenna aperture -- the dominant blocking
    %   structure in spacecraft antenna-FOV studies (e.g. a payload-antenna
    %   reflector in front of a TC&R antenna).
    %
    %   Rim sampling: verticesLocal() returns nRim points on the rim, so the
    %   VERTEX_SAMPLED angular footprint reproduces the disk's true angular
    %   width 2*atan(D/2/R). A square PanelGeometry of side D would instead
    %   sample its CORNERS and overestimate the width by a factor sqrt(2).
    properties (SetAccess = private)
        diameter_m
        nRim            % number of rim sample points (VERTEX_SAMPLED fidelity)
    end
    methods
        function obj = DiskGeometry(diameter_m, nRim)
            V = rfscreen.util.Validate;
            obj.diameter_m = V.positiveScalar(diameter_m, 'diameter_m');
            if nargin < 2 || isempty(nRim); nRim = 16; end
            nRim = V.positiveScalar(nRim, 'nRim');
            if nRim < 3
                error('rfscreen:geometry:badDisk', 'nRim must be >= 3 (got %g).', nRim);
            end
            obj.nRim = round(nRim);
        end

        function v = verticesLocal(obj)
            r = obj.diameter_m / 2;
            th = (0:obj.nRim-1) * (360 / obj.nRim);
            v = [ r * cosd(th); r * sind(th); zeros(1, obj.nRim) ];
        end

        function [hit, tHit] = rayIntersectLocal(obj, o_S, d_S)
            o = o_S(:); d = d_S(:); tol = 1e-12;
            if abs(d(3)) < tol
                hit = false; tHit = NaN; return;      % ray parallel to disk plane
            end
            t = -o(3) / d(3);
            if t < -tol
                hit = false; tHit = NaN; return;      % intersection behind origin
            end
            p = o + t * d;
            if hypot(p(1), p(2)) <= obj.diameter_m/2 + tol
                hit = true; tHit = max(t, 0);
            else
                hit = false; tHit = NaN;
            end
        end

        function r = boundingRadius(obj)
            r = obj.diameter_m / 2;
        end
        function s = describe(obj)
            s = sprintf('Disk[D=%.3g m, %d rim pts]', obj.diameter_m, obj.nRim);
        end
    end
end
