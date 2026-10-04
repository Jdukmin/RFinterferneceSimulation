classdef CstLocalFrameAdapter
    %CSTLOCALFRAMEADAPTER Explicit map between the repository antenna frame A and the CST
    %   local / KAA reflector-aperture frame L (ICD coordinate_system.md + this note).
    %
    %   Repository antenna frame A (ICD 1.2, SimplifiedSpacecraftBuilder.sideMountR_BA,
    %   GimbalSteeringDomain.steeredR_BA):
    %       +X_A = boresight,  +Z_A = +X_B component orthogonal to the boresight,
    %       +Y_A = Z_A x X_A.                      R_BA = [X_A Y_A Z_A]  (v_B = R_BA v_A)
    %   CST local frame L (status.json local_to_body_rotation; CST cuts; KAA aperture):
    %       +Z_L = boresight,  +X_L = +X_B component orthogonal to the boresight,
    %       +Y_L = Z_L x X_L.                      R_BL = [X_L Y_L Z_L]  (v_B = R_BL v_L)
    %   Hence X_L = Z_A, Y_L = -Y_A, Z_L = X_A, i.e. v_A = M_AL v_L with
    %       M_AL = [0 0 1; 0 -1 0; 1 0 0]   (proper rotation, det = +1).
    %
    %   This is deliberately NOT rfscreen.patterndata.CutPatternAssembler.canonicalToAntenna()
    %   ([0 0 1; 1 0 0; 0 1 0], source +X -> antenna +Y_A): that generic map sends the CST XZ cut
    %   plane to the antenna X_A-Y_A plane, whereas the CST XZ plane contains +X_B (= +Z_A).
    %   For an axisymmetric pattern the two coincide; for any asymmetric source they differ
    %   (regression: tests/test_ka_nearfield.m).
    properties (Constant)
        FRAME_NOTE = 'L: +Z_L boresight, +X_L = +X_B (orthogonalised), +Y_L = Z_L x X_L; v_A = M_AL v_L'
    end
    methods (Static)
        function M = localToAntenna()
            %LOCALTOANTENNA v_A = M * v_L.
            M = [0 0 1; 0 -1 0; 1 0 0];
        end

        function R_BL = fromR_BA(R_BA)
            %FROMR_BA CST-local DCM (columns = L axes in B) from a repository R_BA.
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA, 'R_BA');
            R_BL = R_BA * rfscreen.kaa.CstLocalFrameAdapter.localToAntenna();
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BL, 'R_BL');
        end

        function R_BL = fixedMount(n_B)
            %FIXEDMOUNT CST-local DCM of a fixed panel mount (boresight = outward normal n_B).
            R_BL = rfscreen.kaa.CstLocalFrameAdapter.fromR_BA( ...
                rfscreen.spacecraft.SimplifiedSpacecraftBuilder.sideMountR_BA(n_B));
        end

        function R_BL = gimbalPointing(domain, u_B)
            %GIMBALPOINTING CST-local / aperture DCM of a gimbal antenna commanded to u_B.
            %   Uses the repository steering convention (deterministic roll); u_B must be allowed.
            R_BL = rfscreen.kaa.CstLocalFrameAdapter.fromR_BA(domain.steeredR_BA(u_B(:) / norm(u_B)));
        end

        function v_L = bodyToLocal(R_BL, v_B)
            %BODYTOLOCAL Free vectors (3xN) from B to L.
            v_L = R_BL.' * v_B;
        end

        function v_B = localToBody(R_BL, v_L)
            v_B = R_BL * v_L;
        end

        function r_L = pointToLocal(R_BL, origin_B, p_B)
            %POINTTOLOCAL Points (3xN, body m) to L coordinates about origin_B (3x1, body m).
            r_L = R_BL.' * (p_B - origin_B(:));
        end

        function [theta, phi] = thetaPhi(v_L)
            %THETAPHI Polar angle from +Z_L and azimuth atan2(y,x) in [0,360) (deg), CST cut convention.
            n = sqrt(sum(v_L .^ 2, 1));
            theta = acosd(max(-1, min(1, v_L(3, :) ./ n)));
            phi = mod(atan2d(v_L(2, :), v_L(1, :)), 360);
        end
    end
end
