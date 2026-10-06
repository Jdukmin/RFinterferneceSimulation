classdef KaaVictimBandBound
    %KAAVICTIMBANDBOUND Tier-3 ENGINEERING_BOUND on the KAA radiation gain in the victim bands.
    %   No victim-band KAA pattern exists (feed-only CST at 25.5/26.25/27 GHz + non-CST equivalent
    %   paraboloid; no feed pattern, reflector solve or excitation below Ka), so the antenna-only
    %   radiation term is closed with an explicit ceiling, never with a measured / CST-validated gain:
    %     aperture bound   G_ap  = 4 pi A / lambda^2 = (pi D / lambda)^2,  A = pi D^2 / 4 (eta = 1)
    %                      physical optics / large-aperture limit; not rigorous for D/lambda ~ 1
    %     sphere bound     G_sph = (k a)^2 + 2 k a,  k = 2 pi / lambda,  a = D / 2
    %                      Harrington / Chu limit of any antenna inside the sphere of radius a
    %                      (superdirective, unachievable in practice; valid for electrically small D)
    %     TIER-3 BOUND     G_max = max(G_ap, G_sph)  [dBi]  (G_sph > G_ap always: the two differ by
    %                      2 k a, which dominates at L/S and is < 0.5 dB at X band)
    %   Directivity bounds the realised gain (mismatch / ohmic loss only lower it), so G_max is a
    %   ceiling on RealizedGain in every direction. The enclosing sphere is taken as a = D/2 (aperture
    %   disc only; feed volume behind the dish and the hull are NOT included -> if the real structure
    %   extends beyond that sphere the rigorous sphere bound is larger: sensitivity SPHERE_RADIUS_FACTOR).
    %   Direction independent by construction: a ceiling carries no pattern shape, so the gimbal
    %   maximum over the allowed range equals the ceiling whenever the victim lies in the outward
    %   hemisphere (boresight can reach it) and is NOT tightened otherwise.
    %   Tags carried by every value: ENGINEERING_BOUND; NOT_MEASURED; NOT_CST_VALIDATED.
    properties (Constant)
        C0 = 299792458
        FIXED_SENSITIVITY_DBI = [0 10 20]
        TIER = 3
        TAGS = 'ENGINEERING_BOUND;NOT_MEASURED;NOT_CST_VALIDATED'
        MODEL_TYPE = 'BOUNDED'
        REFLECTOR_INCLUDED = 'NO'
        CLASSIFICATION = 'GAIN_BOUND_ONLY'
        SPHERE_RADIUS_FACTOR = 1.5      % sensitivity: enclosing sphere a = factor * D/2
    end
    methods (Static)
        function D = reflectorDiameter_m(repoRoot)
            %REFLECTORDIAMETER_M D of the validated KAA equivalent paraboloid (owner estimate 220 mm).
            J = jsondecode(fileread(fullfile(repoRoot, 'data', 'Kaband_KAA_CST', 'ka_final_validation.json')));
            D = J.reflector.D_mm / 1000;
        end

        function g = apertureBound_dBi(f_Hz, D_m)
            lam = rfscreen.kaa.KaaVictimBandBound.C0 ./ f_Hz;
            g = 20 * log10(pi * D_m ./ lam);
        end

        function g = sphereBound_dBi(f_Hz, a_m)
            ka = 2 * pi * f_Hz * a_m / rfscreen.kaa.KaaVictimBandBound.C0;
            g = 10 * log10(ka .^ 2 + 2 * ka);
        end

        function g = bound_dBi(f_Hz, D_m, radiusFactor)
            %BOUND_DBI Tier-3 ceiling max(aperture, sphere(a = radiusFactor*D/2)) [dBi].
            if nargin < 3; radiusFactor = 1; end
            K = rfscreen.kaa.KaaVictimBandBound;
            g = max(K.apertureBound_dBi(f_Hz, D_m), K.sphereBound_dBi(f_Hz, radiusFactor * D_m / 2));
        end

        function s = applicability(f_Hz, D_m)
            %APPLICABILITY Electrical size and the regime in which each bound is meaningful.
            K = rfscreen.kaa.KaaVictimBandBound;
            ka = 2 * pi * f_Hz * (D_m / 2) / K.C0;
            if ka >= 10; s = 'LARGE_APERTURE (aperture bound tight to < 0.5 dB of the sphere bound)';
            elseif ka >= 3; s = 'INTERMEDIATE (aperture formula is not a rigorous ceiling; sphere bound governs)';
            else; s = 'ELECTRICALLY_SMALL (ka < 3: only the sphere bound is a rigorous ceiling; superdirective)'; end
        end

        function [theta_deg, ok] = reachableOffset(domain, v_B)
            %REACHABLEOFFSET Smallest boresight-to-victim angle over the allowed gimbal range [deg].
            %   OUTWARD_HEMISPHERE_SCREENING: ok = victim inside the commanded-boresight cone.
            [~, theta_deg] = rfscreen.kaa.KaGimbalScreening.nearestAllowed(domain, v_B);
            ok = theta_deg < 1e-9;
        end

        function r = farFieldRatio(f_Hz, D_m, d_m)
            %FARFIELDRATIO d / (2 D^2 / lambda): < 1 means the Friis far-field coupling is not strictly valid.
            r = d_m ./ (2 * D_m ^ 2 * f_Hz / rfscreen.kaa.KaaVictimBandBound.C0);
        end
    end
end
