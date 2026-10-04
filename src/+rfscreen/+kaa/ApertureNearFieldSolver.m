classdef ApertureNearFieldSolver
    %APERTURENEARFIELDSOLVER Direct reflector-aperture field at arbitrary 3D points (source model
    %   REFLECTOR_APERTURE_NEAR_FIELD).
    %
    %   Scalar Kirchhoff integration of the tangential aperture field over the unblocked annulus
    %   (aperture plane z_L = 0, boresight +Z_L, CST-local / aperture frame L):
    %     E(r) = sqrt(2 eta P/(4 pi)) * (j k/(2 pi)) * sum_i w_i * Q_i * exp(-j k R_i) / R_i
    %     Q_i  = [1 + cos(chi_i) (1 + 1/(j k R_i))] / 2,   cos(chi_i) = z / R_i,  R_i = |r - r'_i|
    %   i.e. actual aperture amplitude taper and phase, subreflector blockage, per-element spherical
    %   phase and 1/R. Far-field limit: G(theta) = (k/2pi)^2 |sum w e^{jk r.r'}|^2 ((1+cos th)/2)^2,
    %   which is exactly cst/ka_reflector_po.py aperture_gain() (validated datasheet anchor model).
    %
    %   Outputs are the DIRECT reflector field only: the spacecraft structure (scattering,
    %   shadowing, diffraction), feed spillover/strut scattering and the subreflector itself are
    %   NOT modelled, so the result is NOT a strict upper bound for an installed configuration.
    properties (Constant)
        SOURCE_MODEL = 'REFLECTOR_APERTURE_NEAR_FIELD'
        FAR_FIELD_MODEL = 'FAR_FIELD_PATTERN_FRIIS'
        FIELD_SCOPE = 'DIRECT_REFLECTOR_FIELD_ONLY'
        STRUCTURE_FLAG = 'STRUCTURE_SCATTERING_NOT_MODELED'
        ETA0 = 376.730313668
    end
    methods (Static)
        function E = fieldPerSqrtWatt(model, f_Hz, r_L)
            %FIELDPERSQRTWATT Complex E [V/m peak] per sqrt(W) of TX accepted power at points r_L (3xN, m).
            S = rfscreen.kaa.ApertureNearFieldSolver;
            s = model.samples(f_Hz); k = s.k;
            C = sqrt(2 * S.ETA0 / (4 * pi)) * (1j * k / (2 * pi));
            N = size(r_L, 2); E = complex(zeros(1, N));
            for q = 1:N
                dx = r_L(1, q) - s.x; dy = r_L(2, q) - s.y; z = r_L(3, q);
                R = sqrt(dx .^ 2 + dy .^ 2 + z ^ 2);
                Q = 0.5 * (1 + (z ./ R) .* (1 + 1 ./ (1j * k * R)));
                E(q) = C * sum(s.w .* Q .* exp(-1j * k * R) ./ R);
            end
        end

        function res = evaluate(model, f_Hz, P_dBm, r_L)
            %EVALUATE Field, power density and equivalent gain at points r_L (3xN, aperture frame).
            S = rfscreen.kaa.ApertureNearFieldSolver;
            P_W = 10 .^ ((P_dBm - 30) / 10);
            E = S.fieldPerSqrtWatt(model, f_Hz, r_L) * sqrt(P_W);
            Sd = abs(E) .^ 2 / (2 * S.ETA0);                         % W/m^2
            d = sqrt(sum(r_L .^ 2, 1));
            [th, ph] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi(r_L);
            res = struct('f_Hz', f_Hz, 'E', E, ...
                'E_Vpm_rms', abs(E) / sqrt(2), 'E_dBuVpm', 20 * log10(abs(E) / sqrt(2) * 1e6), ...
                'S_Wpm2', Sd, 'S_dBmpm2', 10 * log10(Sd) + 30, ...
                'Geq_dBi', 10 * log10(4 * pi * d .^ 2 .* Sd / P_W), ...
                'distance_m', d, 'theta_deg', th, 'phi_deg', ph, ...
                'R_ff_m', model.farFieldDistance(f_Hz), ...
                'sourceModel', S.SOURCE_MODEL, 'scope', [S.FIELD_SCOPE ';' S.STRUCTURE_FLAG]);
        end

        function G = farFieldGain(model, f_Hz, theta_deg, phi_deg)
            %FARFIELDGAIN Far-field gain [dBi] of the same aperture (validation reference).
            s = model.samples(f_Hz); k = s.k; G = zeros(size(theta_deg));
            for i = 1:numel(theta_deg)
                st = sind(theta_deg(i)); ct = cosd(theta_deg(i));
                ph = exp(1j * k * st * (cosd(phi_deg(i)) * s.x + sind(phi_deg(i)) * s.y));
                G(i) = 10 * log10((k / (2 * pi)) ^ 2 * abs(sum(s.w .* ph)) ^ 2 * ((1 + ct) / 2) ^ 2);
            end
        end

        function u = arrivalDirection(model, f_Hz, r_L)
            %ARRIVALDIRECTION Local propagation direction (unit, aperture frame) at r_L from the phase
            %   gradient of E (diagnostic: compares the near-field wave direction with the geometric
            %   aperture-centre direction used for the victim antenna gain).
            lam = model.C0 / f_Hz; h = lam / 40; k = 2 * pi / lam;
            u = zeros(3, size(r_L, 2));
            for q = 1:size(r_L, 2)
                P = repmat(r_L(:, q), 1, 6) + h * [eye(3), -eye(3)];
                E = rfscreen.kaa.ApertureNearFieldSolver.fieldPerSqrtWatt(model, f_Hz, P);
                g = -angle(E(1:3) ./ E(4:6)) / (2 * h);           % -dphase/dx  (e^{-jkR} convention)
                u(:, q) = g(:) / k; u(:, q) = u(:, q) / norm(u(:, q));
            end
        end

        function P = portPower_dBm(S_Wpm2, Grx_dBi, f_Hz)
            %PORTPOWER_DBM Victim port power = S * lambda^2/(4 pi) * G_rx (local plane-wave incidence).
            lam = rfscreen.kaa.ReflectorApertureModel.C0 ./ f_Hz;
            P = 10 * log10(S_Wpm2 .* lam .^ 2 / (4 * pi)) + Grx_dBi + 30;
        end
    end
end
