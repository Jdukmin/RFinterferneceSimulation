classdef DirectionCalculator
    %DIRECTIONCALCULATOR Direction <-> azimuth/elevation, frame transforms.
    %   Canonical az/el convention (docs/icd/coordinate_system.md):
    %     boresight = +X_A (az=0,el=0); az about +Z_A from +X toward +Y,
    %     range [-180,180] periodic; el toward +Z_A, range [-90,90] clamped.
    methods (Static)
        function u_A = azElToDirection(az_deg, el_deg)
            %AZELTODIRECTION Unit vector in antenna frame from az/el (deg).
            u_A = [ cosd(el_deg) .* cosd(az_deg);
                    cosd(el_deg) .* sind(az_deg);
                    sind(el_deg) ];
        end

        function [az_deg, el_deg, isDefined] = directionToAzEl(v_A)
            %DIRECTIONTOAZEL Azimuth/elevation (deg) from a vector in antenna frame.
            %   Returns isDefined=false for the (near-)zero vector (AR-015).
            v_A = rfscreen.util.Validate.vector3(v_A, 'v_A');
            r = norm(v_A);
            if r <= eps
                az_deg = NaN; el_deg = NaN; isDefined = false;
                return;
            end
            z = max(min(v_A(3) / r, 1.0), -1.0);
            el_deg = asind(z);
            az_deg = atan2d(v_A(2), v_A(1));
            isDefined = true;
        end

        function v_A = bodyToLocal(R_BA, v_B)
            %BODYTOLOCAL Transform a body-frame vector to antenna-local frame.
            %   v_A = R_AB * v_B = R_BA' * v_B.
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA, 'R_BA');
            v_B = rfscreen.util.Validate.vector3(v_B, 'v_B');
            v_A = R_BA.' * v_B;
        end

        function v_B = localToBody(R_BA, v_A)
            %LOCALTOBODY Transform an antenna-local vector to body frame.
            %   v_B = R_BA * v_A.
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA, 'R_BA');
            v_A = rfscreen.util.Validate.vector3(v_A, 'v_A');
            v_B = R_BA * v_A;
        end

        function b_B = boresightInBody(R_BA)
            %BORESIGHTINBODY Boresight (+X_A) expressed in body frame.
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA, 'R_BA');
            b_B = R_BA(:, 1);
        end

        function ang_deg = offBoresightAngle(az_deg, el_deg)
            %OFFBORESIGHTANGLE Angle (deg) between a direction and boresight (+X_A).
            u = rfscreen.geometry.DirectionCalculator.azElToDirection(az_deg, el_deg);
            c = max(min(u(1), 1.0), -1.0);   % dot(u, [1;0;0])
            ang_deg = acosd(c);
        end
    end
end
