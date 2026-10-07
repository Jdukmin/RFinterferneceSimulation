classdef CstSphericalPatternData
    %CSTSPHERICALPATTERNDATA Validated full-sphere CST Realized Gain on its native (theta, phi) grid.
    %   Frame: CST pattern-local frame L (+Z_L = boresight for a free-space pattern, = mounting-face
    %   outward normal for an installed pattern). theta = polar angle from +Z_L, phi = azimuth
    %   atan2(y_L, x_L) in [0, 360) - the rfscreen.kaa.CstLocalFrameAdapter.thetaPhi convention.
    %
    %   Validation (fromColumns; every failure is an error with a rfscreen:cal:* identifier):
    %     theta within [0, 180], phi within [0, 360]   numeric + finite theta / phi / gain
    %     duplicate (theta, phi) rows                  theta / phi step identified from the UNIQUE
    %     values (never hard-coded)                    uniform steps (a gap = missing angular plane)
    %     full theta 0..180 coverage (both poles)      phi 0 .. 360 - step (phi = 360 accepted only
    %     as a consistent alias of phi = 0)            every theta x phi node present (completeness)
    %
    %   Poles: theta = 0 / 180 rows are one spatial direction each. Their phi spread is CST numerical
    %   noise; for interpolation the pole row is replaced by its linear-power mean (gain_dBi keeps the
    %   raw values; poleSpread_dB reports the spread). This keeps az/el and body-frame queries stable
    %   near the poles. Interpolation: bilinear in (theta, phi) in dB, phi periodic - no extrapolation
    %   (the grid is a closed sphere).
    properties (Constant)
        ANGLE_TOL = 1e-6           % deg, node identification tolerance
        POLE_WARN_DB = 0.5         % pole phi-spread above which a warning is recorded
    end
    properties (SetAccess = private)
        theta_deg                  % 1 x nT, 0 .. 180 ascending
        phi_deg                    % 1 x nP, 0 .. 360-step ascending
        gain_dBi                   % nT x nP raw Realized Gain (column 3)
        thetaStep_deg
        phiStep_deg
        nRows                      % data rows read
        poleSpread_dB              % [north south] max-min over phi at theta = 0 / 180
        poleGain_dBi               % [north south] linear-power mean used by interpolation
        peakGain_dBi
        peakTheta_deg
        peakPhi_deg
        sourceFile = ''
        info                       % parser info struct
        warnings = {}
    end
    properties (Access = private)
        G                          % interpolation table (pole rows consolidated)
    end

    methods (Static)
        function p = fromColumns(theta, phi, gain, info, opts) %#ok<INUSD>
            if nargin < 4 || isempty(info); info = struct(); end
            C = rfscreen.cal.CstSphericalPatternData;
            tol = C.ANGLE_TOL;
            theta = double(theta(:)); phi = double(phi(:)); gain = double(gain(:));
            label = '<data>';
            if isfield(info, 'sourceFile'); label = info.sourceFile; end
            if isempty(theta)
                error('rfscreen:cal:noData', '%s: no data rows.', label);
            end
            bad = find(~isfinite(theta) | ~isfinite(phi) | ~isfinite(gain), 1);
            if ~isempty(bad)
                error('rfscreen:cal:nonFinite', '%s: data row %d has a non-finite theta/phi/gain.', label, bad);
            end
            if any(theta < -tol | theta > 180 + tol)
                error('rfscreen:cal:thetaRange', '%s: theta outside [0, 180] deg (min %g, max %g).', label, min(theta), max(theta));
            end
            if any(phi < -tol | phi > 360 + tol)
                error('rfscreen:cal:phiRange', '%s: phi outside [0, 360] deg (min %g, max %g).', label, min(phi), max(phi));
            end
            % Snap to the tolerance lattice so equal angles compare equal.
            q = @(x) round(x / tol) * tol;
            theta = q(theta); phi = q(phi);

            % phi = 360 is the same half-plane as phi = 0: accepted only as a consistent alias.
            w = abs(phi - 360) <= tol;
            warns = {};
            if any(w)
                [tf, loc] = ismember([theta(w) zeros(nnz(w), 1)], [theta(~w) phi(~w)], 'rows');
                if ~all(tf)
                    error('rfscreen:cal:phiRange', '%s: phi = 360 rows without a phi = 0 counterpart.', label);
                end
                g0 = gain(~w); d = max(abs(g0(loc) - gain(w)));
                if d > 1e-3
                    warns{end+1} = sprintf('phi = 360 alias differs from phi = 0 by up to %.3g dB (phi = 0 kept)', d);
                end
                theta = theta(~w); phi = phi(~w); gain = gain(~w);
            end

            % Duplicate (theta, phi).
            [u, ~, j] = unique([theta phi], 'rows');
            if size(u, 1) < numel(theta)
                cnt = accumarray(j, 1); k = find(cnt > 1, 1);
                error('rfscreen:cal:duplicateSample', '%s: %d duplicate (theta, phi) rows, e.g. (%g, %g).', ...
                    label, numel(theta) - size(u, 1), u(k, 1), u(k, 2));
            end

            T = unique(theta).'; P = unique(phi).';
            tStep = C.identifyStep(T, 'theta', label);
            pStep = C.identifyStep(P, 'phi', label);
            if abs(T(1)) > tol || abs(T(end) - 180) > tol
                error('rfscreen:cal:incompleteGrid', '%s: theta covers %g..%g deg, full sphere needs 0..180.', label, T(1), T(end));
            end
            if abs(P(1)) > tol || abs(P(end) + pStep - 360) > tol
                error('rfscreen:cal:incompleteGrid', '%s: phi covers %g..%g deg with step %g, full sphere needs 0..%g.', ...
                    label, P(1), P(end), pStep, 360 - pStep);
            end
            nT = numel(T); nP = numel(P);
            if numel(theta) ~= nT * nP
                [~, it] = ismember(theta, T); [~, ip] = ismember(phi, P);
                have = false(nT, nP); have(sub2ind([nT nP], it, ip)) = true;
                [mi, mj] = find(~have, 1);
                error('rfscreen:cal:missingSample', '%s: %d of %d (theta, phi) samples missing, e.g. (%g, %g).', ...
                    label, nT * nP - numel(theta), nT * nP, T(mi), P(mj));
            end
            [~, it] = ismember(theta, T); [~, ip] = ismember(phi, P);
            Graw = NaN(nT, nP); Graw(sub2ind([nT nP], it, ip)) = gain;

            p = rfscreen.cal.CstSphericalPatternData();
            p.theta_deg = T; p.phi_deg = P; p.gain_dBi = Graw;
            p.thetaStep_deg = tStep; p.phiStep_deg = pStep;
            p.nRows = numel(gain) + nnz(w);
            p.info = info;
            if isfield(info, 'sourceFile'); p.sourceFile = info.sourceFile; end
            p.poleSpread_dB = [max(Graw(1, :)) - min(Graw(1, :)), max(Graw(end, :)) - min(Graw(end, :))];
            lin = @(r) 10 * log10(mean(10 .^ (r / 10)));
            p.poleGain_dBi = [lin(Graw(1, :)), lin(Graw(end, :))];
            for k = 1:2
                if p.poleSpread_dB(k) > C.POLE_WARN_DB
                    nm = {'theta = 0', 'theta = 180'};
                    warns{end+1} = sprintf('%s pole phi-spread %.3g dB (CST numerical noise?); linear-power mean used', ...
                        nm{k}, p.poleSpread_dB(k)); %#ok<AGROW>
                end
            end
            p.G = Graw; p.G(1, :) = p.poleGain_dBi(1); p.G(end, :) = p.poleGain_dBi(2);
            [p.peakGain_dBi, k] = max(Graw(:));
            [kt, kp] = ind2sub([nT nP], k);
            p.peakTheta_deg = T(kt); p.peakPhi_deg = P(kp);
            p.warnings = warns;
        end
    end

    methods
        function g = gainAt(obj, theta_deg, phi_deg)
            %GAINAT Realized Gain [dBi] at CST (theta, phi) [deg] (vectorised, same-size inputs).
            sz = size(theta_deg);
            th = min(max(double(theta_deg(:)), 0), 180);
            ph = mod(double(phi_deg(:)), 360);
            nT = numel(obj.theta_deg); nP = numel(obj.phi_deg);
            x = th / obj.thetaStep_deg;
            i0 = min(floor(x), nT - 2); t = x - i0; i0 = i0 + 1;
            y = ph / obj.phiStep_deg;
            j0 = floor(y); s = y - j0; j0 = mod(j0, nP) + 1; j1 = mod(j0, nP) + 1;
            G = obj.G;
            g = (1 - t) .* (1 - s) .* G(sub2ind([nT nP], i0, j0)) + (1 - t) .* s .* G(sub2ind([nT nP], i0, j1)) ...
              + t .* (1 - s) .* G(sub2ind([nT nP], i0 + 1, j0)) + t .* s .* G(sub2ind([nT nP], i0 + 1, j1));
            g = reshape(g, sz);
        end

        function g = gainAtLocal(obj, v_L)
            %GAINATLOCAL Realized Gain [dBi] toward CST-local direction(s) v_L (3xN).
            [th, ph] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi(v_L);
            g = obj.gainAt(th, ph);
        end

        function [ang, g, thetaUsed, phiUsed] = planeCut(obj, plane)
            %PLANECUT Full pattern-coordinate cut through the boresight (+Z_L).
            %   'XZ': phi = 0 half (+X, ang = +theta) joined with phi = 180 half (-X, ang = -theta).
            %   'YZ': phi = 90 half (+Y, ang = +theta) joined with phi = 270 half (-Y, ang = -theta).
            %   ang in [-180, 180] deg, 0 = boresight. Values come from the native grid (exact at
            %   nodes; pole rows use the consolidated pole value).
            switch upper(plane)
                case 'XZ'; pPos = 0;  pNeg = 180;
                case 'YZ'; pPos = 90; pNeg = 270;
                otherwise; error('rfscreen:cal:badPlane', 'plane must be XZ or YZ.');
            end
            T = obj.theta_deg;
            ang = [-fliplr(T(2:end)), T];
            thetaUsed = [fliplr(T(2:end)), T];
            phiUsed = [repmat(pNeg, 1, numel(T) - 1), repmat(pPos, 1, numel(T))];
            g = obj.gainAt(thetaUsed, phiUsed);
        end

        function s = summary(obj)
            s = struct('nTheta', numel(obj.theta_deg), 'nPhi', numel(obj.phi_deg), 'nRows', obj.nRows, ...
                'thetaStep_deg', obj.thetaStep_deg, 'phiStep_deg', obj.phiStep_deg, ...
                'peakGain_dBi', obj.peakGain_dBi, 'peakTheta_deg', obj.peakTheta_deg, 'peakPhi_deg', obj.peakPhi_deg, ...
                'minGain_dBi', min(obj.gain_dBi(:)), 'boresightGain_dBi', obj.poleGain_dBi(1), ...
                'poleSpreadNorth_dB', obj.poleSpread_dB(1), 'poleSpreadSouth_dB', obj.poleSpread_dB(2));
        end
    end

    methods (Static, Access = private)
        function step = identifyStep(U, name, label)
            % Step from the unique node values; uniformity required (a gap = missing plane).
            tol = 1e-4;
            if numel(U) < 2
                error('rfscreen:cal:incompleteGrid', '%s: only one unique %s value.', label, name);
            end
            d = diff(U);
            step = min(d);
            m = d / step;
            if any(abs(m - round(m)) > tol)
                [~, k] = max(abs(m - round(m)));
                error('rfscreen:cal:nonUniformStep', '%s: %s nodes are not uniformly spaced (step %g deg, spacing %g deg after %g).', ...
                    label, name, step, d(k), U(k));
            end
            if any(round(m) > 1)
                k = find(round(m) > 1, 1);
                error('rfscreen:cal:missingSample', '%s: missing %s plane(s): gap of %g deg after %g (step %g).', ...
                    label, name, d(k), U(k), step);
            end
            n = round((U(end) - U(1)) / step);
            if abs(n * step - (U(end) - U(1))) > tol
                error('rfscreen:cal:nonUniformStep', '%s: %s step %g does not tile the range.', label, name, step);
            end
        end
    end
end
