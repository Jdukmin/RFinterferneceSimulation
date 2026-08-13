classdef Rotation
    %ROTATION Rotation-matrix (DCM) utilities. Canonical orientation = DCM.
    %   Convention (docs/icd/coordinate_system.md):
    %     R_BA : antenna-frame -> body-frame,  v_B = R_BA * v_A
    %     R_AB = R_BA'         : body -> antenna
    %   Quaternion is a convenience only, scalar-first q = [w x y z].
    methods (Static)
        function tf = isRotationMatrix(R, tolOrth, tolDet)
            %ISROTATIONMATRIX True if R is a proper 3x3 rotation (SR-034).
            if nargin < 2 || isempty(tolOrth); tolOrth = 1e-9; end
            if nargin < 3 || isempty(tolDet);  tolDet  = 1e-6; end
            tf = false;
            if ~(isnumeric(R) && isequal(size(R), [3 3]) && isreal(R) && all(isfinite(R(:))))
                return;
            end
            orthErr = norm(R.' * R - eye(3), 'fro');
            if orthErr > tolOrth
                return;
            end
            if det(R) < (1 - tolDet)
                return;
            end
            tf = true;
        end

        function R = mustBeRotationMatrix(R, fieldName)
            %MUSTBEROTATIONMATRIX Validate and return R, else error.
            if nargin < 2; fieldName = 'R'; end
            if ~rfscreen.geometry.Rotation.isRotationMatrix(R)
                error('rfscreen:geometry:invalidRotation', ...
                    '%s is not a proper 3x3 rotation matrix (orthonormal, det=+1).', fieldName);
            end
        end

        function R_AB = inverse(R_BA)
            %INVERSE Inverse rotation (transpose for a proper rotation).
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA, 'R_BA');
            R_AB = R_BA.';
        end

        function R = fromQuaternion(q)
            %FROMQUATERNION DCM from unit quaternion q=[w x y z] (scalar-first).
            if ~(isnumeric(q) && numel(q) == 4 && all(isfinite(q(:))))
                error('rfscreen:geometry:invalidQuaternion', ...
                    'q must be a finite 4-element vector [w x y z].');
            end
            q = double(q(:));
            n = norm(q);
            if n <= 0
                error('rfscreen:geometry:invalidQuaternion', 'q must be non-zero.');
            end
            q = q / n;
            w = q(1); x = q(2); y = q(3); z = q(4);
            R = [ 1-2*(y^2+z^2),   2*(x*y - w*z),   2*(x*z + w*y);
                  2*(x*y + w*z),   1-2*(x^2+z^2),   2*(y*z - w*x);
                  2*(x*z - w*y),   2*(y*z + w*x),   1-2*(x^2+y^2) ];
        end

        function q = toQuaternion(R)
            %TOQUATERNION Unit quaternion [w x y z] from a proper DCM.
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R, 'R');
            tr = trace(R);
            if tr > 0
                S = sqrt(tr + 1.0) * 2;      % S = 4w
                w = 0.25 * S;
                x = (R(3,2) - R(2,3)) / S;
                y = (R(1,3) - R(3,1)) / S;
                z = (R(2,1) - R(1,2)) / S;
            elseif (R(1,1) > R(2,2)) && (R(1,1) > R(3,3))
                S = sqrt(1.0 + R(1,1) - R(2,2) - R(3,3)) * 2;  % S = 4x
                w = (R(3,2) - R(2,3)) / S;
                x = 0.25 * S;
                y = (R(1,2) + R(2,1)) / S;
                z = (R(1,3) + R(3,1)) / S;
            elseif R(2,2) > R(3,3)
                S = sqrt(1.0 + R(2,2) - R(1,1) - R(3,3)) * 2;  % S = 4y
                w = (R(1,3) - R(3,1)) / S;
                x = (R(1,2) + R(2,1)) / S;
                y = 0.25 * S;
                z = (R(2,3) + R(3,2)) / S;
            else
                S = sqrt(1.0 + R(3,3) - R(1,1) - R(2,2)) * 2;  % S = 4z
                w = (R(2,1) - R(1,2)) / S;
                x = (R(1,3) + R(3,1)) / S;
                y = (R(2,3) + R(3,2)) / S;
                z = 0.25 * S;
            end
            q = [w x y z];
            q = q / norm(q);
        end

        function R = aboutZ(angle_deg)
            %ABOUTZ Rotation about +Z by angle_deg (right-handed, active).
            c = cosd(angle_deg); s = sind(angle_deg);
            R = [ c -s 0; s c 0; 0 0 1 ];
        end

        function R = aboutY(angle_deg)
            %ABOUTY Rotation about +Y by angle_deg.
            c = cosd(angle_deg); s = sind(angle_deg);
            R = [ c 0 s; 0 1 0; -s 0 c ];
        end

        function R = aboutX(angle_deg)
            %ABOUTX Rotation about +X by angle_deg.
            c = cosd(angle_deg); s = sind(angle_deg);
            R = [ 1 0 0; 0 c -s; 0 s c ];
        end
    end
end
