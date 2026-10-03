classdef GimbalSteeringDomain
    %GIMBALSTEERINGDOMAIN Allowed commanded-boresight set of a gimbal-steered antenna
    %   (ICD mission_spacecraft.md 7). Mission-level steering METADATA kept separate
    %   from the fixed AntennaInstallation (whose R_BA is the gimbal zero/reference).
    %
    %   Allowed u_B:  |u_B| = 1  and  angle(u_B, referenceAxis_B) <= maxOffAxis_deg.
    %   HEMISPHERE (maxOffAxis_deg = 90) is the simplified RFC/RFI screening
    %   assumption u_B . n_ref >= 0 -- NOT a hardware hard-stop/keep-out/slew
    %   envelope. CONE narrows it when real gimbal data is available.
    properties (Constant)
        HEMISPHERE = 'HEMISPHERE'
        CONE       = 'CONE'
        UNIT_TOL   = 1e-9    % |norm(u)-1| tolerance for a commanded boresight
        ANGLE_TOL_DEG = 1e-9 % boundary tolerance on the off-axis limit
    end
    properties (SetAccess = private)
        antennaId
        referenceAxis_B   % 3x1 unit vector (gimbal reference / base outward normal)
        steeringModel     % HEMISPHERE | CONE
        maxOffAxis_deg
        provenance        % e.g. SIMPLIFIED_ASSUMPTION
    end
    methods
        function obj = GimbalSteeringDomain(antennaId, referenceAxis_B, steeringModel, maxOffAxis_deg, provenance)
            V = rfscreen.util.Validate;
            obj.antennaId = V.id(antennaId, 'GimbalSteeringDomain.antennaId');
            n = V.vector3(referenceAxis_B, 'referenceAxis_B');
            if abs(norm(n) - 1) > 1e-6
                error('rfscreen:spacecraft:notUnitVector', 'referenceAxis_B must be a unit vector.');
            end
            obj.referenceAxis_B = n / norm(n);
            obj.steeringModel = V.member(steeringModel, {'HEMISPHERE', 'CONE'}, 'steeringModel');
            a = V.positiveScalar(maxOffAxis_deg, 'maxOffAxis_deg');
            if strcmp(obj.steeringModel, 'HEMISPHERE') && a ~= 90
                error('rfscreen:spacecraft:badSteering', 'HEMISPHERE requires maxOffAxis_deg = 90 (got %g).', a);
            end
            if a > 180
                error('rfscreen:spacecraft:badSteering', 'maxOffAxis_deg must be <= 180 (got %g).', a);
            end
            obj.maxOffAxis_deg = a;
            obj.provenance = V.id(provenance, 'provenance');
        end

        function ang = offAxisAngle_deg(obj, u_B)
            %OFFAXISANGLE_DEG Angle between a commanded unit boresight and the reference axis.
            u = rfscreen.spacecraft.GimbalSteeringDomain.requireUnit(u_B);
            ang = atan2d(norm(cross(obj.referenceAxis_B, u)), dot(obj.referenceAxis_B, u));
        end

        function tf = isAllowed(obj, u_B)
            %ISALLOWED True if the commanded boresight u_B lies in the steering domain.
            tf = obj.offAxisAngle_deg(u_B) <= ...
                obj.maxOffAxis_deg + rfscreen.spacecraft.GimbalSteeringDomain.ANGLE_TOL_DEG;
        end

        function U = sampleDirections(obj, step_deg)
            %SAMPLEDIRECTIONS Deterministic 3xN unit boresights covering the domain
            %   (polar 0:step:max about the reference axis incl. the boundary; azimuth
            %   0:step:<360 measured from the +X_B projection). Sweep extension point
            %   for worst-case RFC/RFI scans.
            step_deg = rfscreen.util.Validate.positiveScalar(step_deg, 'step_deg');
            [t1, t2] = obj.tangentBasis();
            pol = 0:step_deg:obj.maxOffAxis_deg;
            if pol(end) < obj.maxOffAxis_deg; pol(end+1) = obj.maxOffAxis_deg; end
            azs = 0:step_deg:(360 - step_deg/2);
            U = obj.referenceAxis_B;
            for p = pol(2:end)
                for a = azs
                    u = cosd(p) * obj.referenceAxis_B + sind(p) * (cosd(a) * t1 + sind(a) * t2);
                    U(:, end+1) = u / norm(u); %#ok<AGROW>
                end
            end
        end

        function R = steeredR_BA(obj, u_B)
            %STEEREDR_BA Proper DCM with +X_A = u_B (must be allowed). Deterministic roll:
            %   z_A = component of +X_B orthogonal to u_B (fallback: reference axis),
            %   y_A = z_A x x_A. At u_B = reference axis this equals the side-mount
            %   reference orientation of the installation.
            if ~obj.isAllowed(u_B)
                error('rfscreen:spacecraft:outsideSteeringDomain', ...
                    '%s: commanded boresight is %.6g deg off-axis (limit %.6g deg).', ...
                    obj.antennaId, obj.offAxisAngle_deg(u_B), obj.maxOffAxis_deg);
            end
            x = u_B(:) / norm(u_B);
            z = [1; 0; 0] - x(1) * x;
            if norm(z) < 1e-9
                z = obj.referenceAxis_B - dot(obj.referenceAxis_B, x) * x;
            end
            z = z / norm(z);
            R = [x, cross(z, x), z];
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R, 'steeredR_BA');
        end

        function inst = steeredInstallation(obj, baseInstallation, u_B)
            %STEEREDINSTALLATION Copy of the reference installation pointed along u_B
            %   (same antenna id, same position, same configId) for sweep analyses.
            if ~isa(baseInstallation, 'rfscreen.antenna.AntennaInstallation') ...
                    || ~strcmp(baseInstallation.antennaId, obj.antennaId)
                error('rfscreen:spacecraft:badInstallation', ...
                    'baseInstallation must be the AntennaInstallation of %s.', obj.antennaId);
            end
            inst = rfscreen.antenna.AntennaInstallation(obj.antennaId, baseInstallation.position_m, ...
                obj.steeredR_BA(u_B), baseInstallation.configId);
        end
    end
    methods (Access = private)
        function [t1, t2] = tangentBasis(obj)
            n = obj.referenceAxis_B;
            t1 = [1; 0; 0] - n(1) * n;
            if norm(t1) < 1e-9; t1 = [0; 1; 0] - n(2) * n; end
            t1 = t1 / norm(t1);
            t2 = cross(n, t1);
        end
    end
    methods (Static)
        function u = requireUnit(u_B)
            u = rfscreen.util.Validate.vector3(u_B, 'u_B');
            if abs(norm(u) - 1) > rfscreen.spacecraft.GimbalSteeringDomain.UNIT_TOL
                error('rfscreen:spacecraft:notUnitVector', ...
                    'commanded boresight must be a unit vector (|u| = %.12g).', norm(u));
            end
        end
    end
end
