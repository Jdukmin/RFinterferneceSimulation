classdef KaGimbalScreening
    %KAGIMBALSCREENING Worst-case KAA steering screening for one victim point.
    %   The validated aperture is axisymmetric and the aperture centre is taken at the installation
    %   reference point (pivot/aperture offset not defined -> ASSUMPTION), so the direct field at a
    %   victim depends only on the distance d and on theta = angle(boresight u, victim direction v).
    %   Reachable theta for a domain with reference axis n and limit L: alpha = angle(n, v),
    %   theta in [max(0, alpha - L), min(180, alpha + L)], realised by u in the (v, n) plane.
    %   The 1-D theta sweep is therefore exact for this model; a brute-force sweep over
    %   GimbalSteeringDomain.sampleDirections() is used as a regression check (tests).
    %   Mechanical shadowing / hard stops / keep-outs are NOT defined in the inputs: the steering
    %   domain is the simplified HEMISPHERE assumption (steering_constraints.csv).
    properties (Constant)
        NOMINAL = 'NOMINAL_GIMBAL_REFERENCE'
        DIRECTED = 'VICTIM_DIRECTED_OR_NEAREST_ALLOWED'
        WORST = 'MAX_COUPLING_ALLOWED'
        COARSE_DEG = 0.25
        FINE_DEG = 0.01
    end
    methods (Static)
        function u = pointingForTheta(n, v, theta_deg)
            %POINTINGFORTHETA Unit boresight at angle theta from v, rotated from v toward n.
            v = v(:) / norm(v); n = n(:) / norm(n);
            w = n - dot(n, v) * v;
            if norm(w) < 1e-12
                w = cross(v, [1; 0; 0]); if norm(w) < 1e-9; w = cross(v, [0; 1; 0]); end
            end
            w = w / norm(w);
            u = cosd(theta_deg) * v + sind(theta_deg) * w; u = u / norm(u);
        end

        function [u, theta] = nearestAllowed(domain, v)
            %NEARESTALLOWED v itself when allowed, else the closest boundary direction.
            v = v(:) / norm(v); n = domain.referenceAxis_B;
            alpha = atan2d(norm(cross(n, v)), dot(n, v));
            if alpha <= domain.maxOffAxis_deg
                u = v; theta = 0;
            else
                theta = alpha - domain.maxOffAxis_deg;
                u = rfscreen.kaa.KaGimbalScreening.pointingForTheta(n, v, theta);
            end
        end

        function out = screen(model, freqs_Hz, P_dBm, origin_B, domain, victim_B, weight_dB, refineModel)
            %SCREEN Nominal / victim-directed / max-coupling steering states.
            %   weight_dB(k): per-frequency additive weight (victim gain [dBi] + 10log10(lambda^2/4pi));
            %   pass zeros to maximise the band-average incident power density instead.
            %   refineModel (optional): finer-sampled aperture used for the fine sweep and the states
            %   (the coarse sweep then uses the cheaper 'model').
            if nargin < 8 || isempty(refineModel); refineModel = model; end
            G = rfscreen.kaa.KaGimbalScreening; S = rfscreen.kaa.ApertureNearFieldSolver;
            d_B = victim_B(:) - origin_B(:); d = norm(d_B); v = d_B / d; n = domain.referenceAxis_B;
            alpha = atan2d(norm(cross(n, v)), dot(n, v));
            L = domain.maxOffAxis_deg;
            tlo = max(0, alpha - L); thi = min(180, alpha + L);
            nf = numel(freqs_Hz);
            dens = @(th) G.densityAt(model, freqs_Hz, P_dBm, d, th);             % nf x numel(th) W/m^2
            metric = @(Sd) 10 * log10(mean(Sd .* 10 .^ (weight_dB(:) / 10), 1));
            tc = unique([tlo:G.COARSE_DEG:thi, thi]);
            mc = metric(dens(tc)); [~, i] = max(mc);
            tf = unique(max(tlo, min(thi, tc(i) + (-G.COARSE_DEG:G.FINE_DEG:G.COARSE_DEG))));
            mf = metric(G.densityAt(refineModel, freqs_Hz, P_dBm, d, tf)); [~, j] = max(mf); tw = tf(j);
            [uDir, tDir] = G.nearestAllowed(domain, v);
            th = [acosd(max(-1, min(1, dot(n, v)))), tDir, tw];
            us = {n, uDir, G.pointingForTheta(n, v, tw)};
            names = {G.NOMINAL, G.DIRECTED, G.WORST};
            out = struct('state', names, 'u_B', us, 'theta_ap_deg', num2cell(th), 'allowed', [], ...
                'offAxisFromRef_deg', [], 'S_Wpm2', [], 'metric_dB', [], 'R_BL', []);
            for s = 1:3
                out(s).allowed = domain.isAllowed(out(s).u_B);
                out(s).offAxisFromRef_deg = domain.offAxisAngle_deg(out(s).u_B);
                out(s).R_BL = rfscreen.kaa.CstLocalFrameAdapter.gimbalPointing(domain, out(s).u_B);
                r_L = rfscreen.kaa.CstLocalFrameAdapter.pointToLocal(out(s).R_BL, origin_B, victim_B);
                Sd = zeros(nf, 1);
                for k = 1:nf; e = S.evaluate(refineModel, freqs_Hz(k), P_dBm, r_L); Sd(k) = e.S_Wpm2; end
                out(s).S_Wpm2 = Sd; out(s).metric_dB = metric(Sd);
                out(s).r_L = r_L;
            end
            out(1).sweep = struct('theta_deg', [tc tf], 'metric_dB', [mc mf], 'alpha_deg', alpha, ...
                'reachable_deg', [tlo thi], 'distance_m', d);
        end

        function Sd = densityAt(model, freqs_Hz, P_dBm, d, theta_deg)
            %DENSITYAT Power density at distance d, angle theta from boresight (phi = 0; axisymmetric).
            r = d * [sind(theta_deg); zeros(size(theta_deg)); cosd(theta_deg)];
            Sd = zeros(numel(freqs_Hz), numel(theta_deg));
            for k = 1:numel(freqs_Hz)
                e = rfscreen.kaa.ApertureNearFieldSolver.evaluate(model, freqs_Hz(k), P_dBm, r);
                Sd(k, :) = e.S_Wpm2;
            end
        end
    end
end
