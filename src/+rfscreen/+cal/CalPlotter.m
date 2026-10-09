classdef CalPlotter
    %CALPLOTTER CAL figures. Physics values are never altered for display:
    %   - gain values / colours = Realized Gain [dBi] queried from the native 3D CST grid;
    %   - 3D / polar RADIUS is a separate visualization-only mapping
    %       r_vis = R_VIS_M * max(0, G - (G_max - VIS_RANGE_DB)) / VIS_RANGE_DB
    %     (positive dB offset normalised to the pattern peak), because negative dBi cannot be a radius.
    %   A  planeCuts      : raw source-frame XZ (phi 0/180) and YZ (phi 90/270) full cuts through +Z_S
    %                       (free-space: S = CST local L, +Z = boresight; installed: S = body B, +Z = +Z_B)
    %   Installed figures use ONE raw -> displayed-Body matrix per dataset, C = C_effective = R_user * C_base
    %   (CalPlotFrameAdapter.rawToDisplayedBody; owner steering file installed_pattern_rotation.csv)
    %   (owner axis-sign correction; not the physical mount R_BL). No per-plane flip; gains never altered.
    %   B  installed3D    : spacecraft hull (SSOT panels) + body axes + mount point + panel normal + 3D pattern;
    %                       raw (theta, phi) -> d_raw -> d_B = C d_raw (colour = raw G(theta, phi))
    %   C  bodyCuts       : body XZ (Y_B = 0) / YZ (X_B = 0) / XY (Z_B = 0) cross-sections; desired d_B ->
    %                       d_raw = C.' d_B -> raw grid query (gainRaw)
    %   D  localCuts      : antenna-local XZ / YZ cuts (+Z_L = panel normal, +X_L = +X_B orthogonalised);
    %                       d_L -> d_B = R_BL d_L -> d_raw = C.' d_B -> raw grid query
    properties (Constant)
        VIS_RANGE_DB = 30
        R_VIS_M = 1.5
        PLOT_STEP_DEG = 3      % 3D surface sampling (display only)
    end
    methods (Static)
        function ok = setupGraphics()
            %SETUPGRAPHICS Pick a toolkit able to render off-screen. false = plotting unavailable.
            ok = true;
            if exist('OCTAVE_VERSION', 'builtin') == 0; return; end
            tk = available_graphics_toolkits();
            if isempty(tk); ok = false; return; end
            if isempty(getenv('DISPLAY')) && any(strcmp(tk, 'gnuplot'))
                graphics_toolkit('gnuplot');
            elseif ~any(strcmp(graphics_toolkit(), tk))
                graphics_toolkit(tk{1});
            end
        end

        function savePng(fig, path)
            d = fileparts(path);
            if exist(d, 'dir') ~= 7; mkdir(d); end
            if exist('OCTAVE_VERSION', 'builtin') ~= 0 && strcmp(graphics_toolkit(), 'gnuplot')
                print(fig, '-dpngcairo', path);
            else
                print(fig, '-dpng', '-r110', path);
            end
            close(fig);
        end

        function files = planeCuts(native, titleText, outPrefix, sourceFrame)
            %PLANECUTS *_XZ.png and *_YZ.png (Cartesian signed angle from +Z_S vs gain), raw source frame S.
            if nargin < 4; sourceFrame = 'CST_LOCAL'; end
            if strcmp(sourceFrame, 'SPACECRAFT_BODY_FIXED')
                zLabel = '+Z raw (theta = 0)'; frameName = 'raw installed CST axes, no display correction';
            else
                zLabel = 'boresight +Z_L (theta = 0)'; frameName = 'CST local frame';
            end
            planes = {'XZ', 'YZ'};
            neg = {'-X half (phi = 180)', '-Y half (phi = 270)'};
            pos = {'+X half (phi = 0)', '+Y half (phi = 90)'};
            files = {};
            for i = 1:2
                [ang, g] = native.planeCut(planes{i});
                fig = figure('visible', 'off', 'position', [0 0 900 520]);
                plot(ang, g, 'b-', 'linewidth', 1.5); hold on; grid on;
                yl = [floor(min(g) / 5) * 5 - 5, ceil(max(g) / 5) * 5 + 5];
                plot([0 0], yl, 'k--'); ylim(yl); xlim([-180 180]);
                set(gca, 'xtick', -180:30:180);
                text(-170, yl(2) - 2, neg{i}); text(20, yl(2) - 2, pos{i});
                text(2, yl(1) + 2, sprintf('%s; %s', zLabel, frameName), 'interpreter', 'none');
                xlabel(sprintf('signed angle from +Z in the CST %s plane [deg] (+: %s, -: %s)', planes{i}, ...
                    strtok(pos{i}, '('), strtok(neg{i}, '(')));
                ylabel('Realized Gain [dBi]');
                title(sprintf('RAW CST — UNCORRECTED: %s %s (peak %.2f dBi)', titleText, planes{i}, max(g)), 'interpreter', 'none');
                f = sprintf('%s_%s.png', outPrefix, planes{i});
                rfscreen.cal.CalPlotter.savePng(fig, f);
                files{end+1} = f; %#ok<AGROW>
            end
        end

        function r = visRadius(g, gMax)
            C = rfscreen.cal.CalPlotter;
            r = C.R_VIS_M * max(0, g - (gMax - C.VIS_RANGE_DB)) / C.VIS_RANGE_DB;
        end

        function f = installed3D(model, installationId, pattern, titleText, outPath)
            C = rfscreen.cal.CalPlotter;
            inst = model.installations(installationId);
            p0 = inst.position_m;
            fig = figure('visible', 'off', 'position', [0 0 1000 800]);
            hold on; grid on;
            C.drawHull3D(model, installationId);
            L = 1.0;
            quiver3(0, 0, 0, L, 0, 0, 0, 'r', 'linewidth', 2); text(L * 1.05, 0, 0, '+X_B');
            quiver3(0, 0, 0, 0, L, 0, 0, 'g', 'linewidth', 2); text(0, L * 1.05, 0, '+Y_B');
            quiver3(0, 0, 0, 0, 0, L, 0, 'b', 'linewidth', 2); text(0, 0, L * 1.05, '+Z_B');
            nat = pattern.native;
            st = max(C.PLOT_STEP_DEG, max(nat.thetaStep_deg, nat.phiStep_deg));
            [TH, PH] = ndgrid(0:st:180, 0:st:360);
            G = nat.gainAt(TH, PH);
            r = C.visRadius(G, nat.peakGain_dBi);
            vB = C.displayedBodyDirections(pattern, TH, PH);
            X = reshape(p0(1) + r(:).' .* vB(1, :), size(TH));
            Y = reshape(p0(2) + r(:).' .* vB(2, :), size(TH));
            Z = reshape(p0(3) + r(:).' .* vB(3, :), size(TH));
            surf(X, Y, Z, G, 'edgecolor', 'none');
            cb = colorbar(); ylabel(cb, sprintf('colour: Realized Gain [dBi] (peak %.2f)  |  radius: visualization only, %g dB offset scale', ...
                nat.peakGain_dBi, C.VIS_RANGE_DB));
            plot3(p0(1), p0(2), p0(3), 'ko', 'markerfacecolor', 'y', 'markersize', 8);
            n = inst.R_BA(:, 1) * 1.3 * C.R_VIS_M;
            quiver3(p0(1), p0(2), p0(3), n(1), n(2), n(3), 0, 'm', 'linewidth', 2.5);
            text(p0(1) + n(1), p0(2) + n(2), p0(3) + n(3), sprintf('%s panel outward normal n_B', installationId), 'interpreter', 'none');
            dPk = C.displayedBodyDirections(pattern, nat.peakTheta_deg, nat.peakPhi_deg) * 1.15 * C.R_VIS_M;
            quiver3(p0(1), p0(2), p0(3), dPk(1), dPk(2), dPk(3), 0, 'c', 'linewidth', 2);
            text(p0(1) + dPk(1), p0(2) + dPk(2), p0(3) + dPk(3), 'corrected peak direction', 'interpreter', 'none');
            axis equal; view(-50, 25);
            ylabel('Y_B [m]'); zlabel('Z_B [m]');
            % Single-line strings only (the gnuplot toolkit cannot render multi-line titles).
            title(sprintf('%s | 3D body frame | %s', C.frameTag(pattern), pattern.frameCorrection.status), 'interpreter', 'none', 'fontsize', 9);
            xlabel('X_B [m]');
            f = outPath;
            C.savePng(fig, f);
        end

        function [files, cuts] = bodyCuts(model, installationId, pattern, f_Hz, titleText, outPrefix)
            %BODYCUTS Body XZ / YZ / XY cross-sections of the transformed full-3D pattern.
            C = rfscreen.cal.CalPlotter;
            inst = model.installations(installationId);
            nat = pattern.native;
            cuts = C.bodyCutData(pattern, f_Hz);
            ax = {'X_B', 'Y_B', 'Z_B'};
            files = {};
            for i = 1:numel(cuts)
                ij = cuts(i).axes; alpha = cuts(i).alpha_deg; g = cuts(i).gain_dBi;
                planes = {cuts(i).plane};
                fig = figure('visible', 'off', 'position', [0 0 1300 560]);
                subplot(1, 2, 1); hold on; grid on;
                C.drawHullProjection(model, ij);
                p = inst.position_m(ij);
                r = C.visRadius(g, nat.peakGain_dBi);
                px = p(1) + r .* cosd(alpha); py = p(2) + r .* sind(alpha);
                plot(px, py, 'b-', 'linewidth', 1.5);
                scatter(px, py, 12, g, 'filled');
                cb = colorbar(); ylabel(cb, 'Realized Gain [dBi]');
                plot(p(1), p(2), 'ko', 'markerfacecolor', 'y', 'markersize', 8);
                bo = inst.R_BA(ij, 1);
                if norm(bo) > 1e-6
                    quiver(p(1), p(2), bo(1) * 1.2, bo(2) * 1.2, 0, 'm', 'linewidth', 2);
                end
                axis equal;
                xlabel([ax{ij(1)} ' [m]']); ylabel([ax{ij(2)} ' [m]']);
                title(sprintf('%s | Body %s', C.frameTag(pattern), planes{1}), 'interpreter', 'none', 'fontsize', 8);
                subplot(1, 2, 2); hold on; grid on;
                plot(alpha, g, 'b-', 'linewidth', 1.5);
                yl = [floor(min(g) / 5) * 5 - 5, ceil(max(g) / 5) * 5 + 5]; ylim(yl); xlim([-180 180]);
                set(gca, 'xtick', -180:30:180);
                if norm(bo) > 1e-6
                    ab = atan2d(bo(2), bo(1));
                    plot([ab ab], yl, 'm--');
                    text(ab + 2, yl(2) - 2, sprintf('boresight projection (%.0f%% in-plane)', 100 * norm(bo)));
                end
                xlabel(sprintf('body angle from +%s toward +%s [deg]', ax{ij(1)}, ax{ij(2)}), 'interpreter', 'none');
                ylabel('Realized Gain [dBi]');
                title(sprintf('Body %s cut (d_raw = C_eff^T d_B) | boresight check %s', planes{1}, pattern.frameCorrection.status), ...
                    'interpreter', 'none', 'fontsize', 8);
                f = sprintf('%s_BODY_%s.png', outPrefix, planes{1});
                C.savePng(fig, f);
                files{end+1} = f; %#ok<AGROW>
            end
        end

        function cuts = bodyCutData(pattern, f_Hz)
            %BODYCUTDATA Body XZ (Y_B = 0) / YZ (X_B = 0) / XY (Z_B = 0) cuts of an INSTALLED pattern:
            %   desired d_B(alpha) in the plane -> d_raw = C.' d_B -> pattern.gainRaw (no R_BL / R_BA / M_AL).
            rfscreen.cal.CalPlotter.mustBeBodyFrame(pattern);
            C = rfscreen.cal.CalPlotFrameAdapter.rawToDisplayedBody(pattern, f_Hz);
            nat = pattern.native;
            step = min(nat.thetaStep_deg, nat.phiStep_deg);
            alpha = -180:step:180;
            planes = {'XZ', [1 3]; 'YZ', [2 3]; 'XY', [1 2]};
            cuts = struct('plane', {}, 'axes', {}, 'alpha_deg', {}, 'gain_dBi', {}, 'dir_B', {}, 'dir_raw', {});
            for i = 1:size(planes, 1)
                ij = planes{i, 2};
                dB = zeros(3, numel(alpha));
                dB(ij(1), :) = cosd(alpha); dB(ij(2), :) = sind(alpha);
                dRaw = C.' * dB;
                g = pattern.gainRaw(f_Hz, dRaw);
                cuts(end+1) = struct('plane', planes{i, 1}, 'axes', ij, 'alpha_deg', alpha, 'gain_dBi', g, 'dir_B', dB, ...
                    'dir_raw', dRaw); %#ok<AGROW>
            end
        end

        function cuts = localCutData(pattern, f_Hz)
            %LOCALCUTDATA Antenna-local XZ / YZ cuts of an INSTALLED pattern (antenna-geometry view):
            %   d_L(ang) in the local plane (ang = signed angle from +Z_L toward +X_L / +Y_L)
            %   -> d_B = R_BL d_L (physical mount) -> d_raw = C.' d_B (plot-frame adapter) -> pattern.gainRaw.
            rfscreen.cal.CalPlotter.mustBeBodyFrame(pattern);
            C = rfscreen.cal.CalPlotFrameAdapter.rawToDisplayedBody(pattern, f_Hz);
            nat = pattern.native;
            step = min(nat.thetaStep_deg, nat.phiStep_deg);
            ang = -180:step:180;
            planes = {'XZ', 1; 'YZ', 2};
            cuts = struct('plane', {}, 'ang_deg', {}, 'gain_dBi', {}, 'dir_L', {}, 'dir_B', {}, 'dir_raw', {});
            for i = 1:size(planes, 1)
                dL = zeros(3, numel(ang));
                dL(planes{i, 2}, :) = sind(ang); dL(3, :) = cosd(ang);
                dB = pattern.R_BL * dL;
                dRaw = C.' * dB;
                g = pattern.gainRaw(f_Hz, dRaw);
                cuts(end+1) = struct('plane', planes{i, 1}, 'ang_deg', ang, 'gain_dBi', g, 'dir_L', dL, 'dir_B', dB, ...
                    'dir_raw', dRaw); %#ok<AGROW>
            end
        end

        function files = localCuts(pattern, f_Hz, titleText, outPrefix)
            %LOCALCUTS *_LOCAL_XZ.png / *_LOCAL_YZ.png of an installed pattern (antenna-local view).
            cuts = rfscreen.cal.CalPlotter.localCutData(pattern, f_Hz);
            ax = {'X_L', 'Y_L'};
            files = {};
            for i = 1:numel(cuts)
                ang = cuts(i).ang_deg; g = cuts(i).gain_dBi;
                fig = figure('visible', 'off', 'position', [0 0 900 520]);
                plot(ang, g, 'b-', 'linewidth', 1.5); hold on; grid on;
                yl = [floor(min(g) / 5) * 5 - 5, ceil(max(g) / 5) * 5 + 5];
                plot([0 0], yl, 'k--'); ylim(yl); xlim([-180 180]);
                set(gca, 'xtick', -180:30:180);
                text(2, yl(1) + 2, '+Z_L = panel outward normal n_B');
                xlabel(sprintf('signed angle from +Z_L toward +%s in the antenna-local %s plane [deg]', ax{i}, cuts(i).plane), 'interpreter', 'none');
                ylabel('Realized Gain [dBi]');
                title(sprintf('%s | Local %s | %s', rfscreen.cal.CalPlotter.frameTag(pattern), cuts(i).plane, ...
                    pattern.frameCorrection.status), 'interpreter', 'none', 'fontsize', 9);
                f = sprintf('%s_LOCAL_%s.png', outPrefix, cuts(i).plane);
                rfscreen.cal.CalPlotter.savePng(fig, f);
                files{end+1} = f; %#ok<AGROW>
            end
        end

        function d = displayedBodyDirections(pattern, TH, PH)
            %DISPLAYEDBODYDIRECTIONS Displayed Body directions (3xN) of raw installed (theta, phi) samples:
            %   d_B = C * d_raw (CalPlotFrameAdapter); the sample gain stays G(theta, phi).
            rfscreen.cal.CalPlotter.mustBeBodyFrame(pattern);
            A = rfscreen.cal.CalPlotFrameAdapter;
            d = A.rawToDisplayedBody(pattern) * A.sphericalDirection(TH, PH);
        end

        function t = frameTag(pattern)
            %FRAMETAG Dataset, owner steering and validation status shown in every installed figure title.
            fc = pattern.frameCorrection;
            t = sprintf('%s @ %.6g GHz | User steering: Rx=%g deg, Ry=%g deg, Rz=%g deg%s', fc.installation_id, ...
                fc.source_frequency_ghz, fc.rot_x_deg, fc.rot_y_deg, fc.rot_z_deg, ...
                rfscreen.cal.CalPlotter.ternary(strcmp(fc.user_rotation_status, 'CONFIGURED'), '', ' (not configured)'));
        end

        function v = ternary(c, a, b)
            if c; v = a; else; v = b; end
        end

        function mustBeBodyFrame(pattern)
            if ~isprop(pattern, 'sourceFrame') || ~strcmp(pattern.sourceFrame, 'SPACECRAFT_BODY_FIXED')
                error('rfscreen:cal:notBodyFramePattern', ['installed spacecraft figures need an INSTALLED pattern whose ' ...
                    'raw CST frame is SPACECRAFT_BODY_FIXED.']);
            end
        end

        function drawHull3D(model, installationId)
            h = model.hull;
            n = h.nVertices(); yz = h.yz_m;
            for k = 1:n
                k2 = mod(k, n) + 1;
                xs = [h.xMin_m h.xMax_m h.xMax_m h.xMin_m h.xMin_m];
                ys = [yz(1, k) yz(1, k) yz(1, k2) yz(1, k2) yz(1, k)];
                zs = [yz(2, k) yz(2, k) yz(2, k2) yz(2, k2) yz(2, k)];
                plot3(xs, ys, zs, '-', 'color', [0.35 0.35 0.35]);
            end
            for xe = [h.xMin_m h.xMax_m]
                plot3(repmat(xe, 1, n + 1), yz(1, [1:n 1]), yz(2, [1:n 1]), '-', 'color', [0.35 0.35 0.35]);
            end
            % Mounting panel highlighted (SSOT panel of the installation).
            rec = model.installationRecords(strcmp({model.installationRecords.antennaId}, installationId));
            pn = model.panels(strcmp({model.panels.id}, rec.panelId));
            if strcmp(pn.kind, 'SIDE')
                k = pn.edgeIndex; k2 = mod(k, n) + 1;
                V = [h.xMin_m yz(1, k) yz(2, k); h.xMax_m yz(1, k) yz(2, k); h.xMax_m yz(1, k2) yz(2, k2); h.xMin_m yz(1, k2) yz(2, k2)];
                patch('Vertices', V, 'Faces', [1 2 3; 1 3 4], 'FaceColor', [0.85 0.85 0.6], 'EdgeColor', 'none');   % triangles: gnuplot-safe
            end
        end

        function drawHullProjection(model, ij)
            h = model.hull;
            yz = h.yz_m;
            if isequal(ij, [2 3])
                plot(yz(1, [1:end 1]), yz(2, [1:end 1]), 'k-', 'linewidth', 1.2);
            else
                other = yz(ij(2) - 1, :);           % ij = [1 3] -> z, [1 2] -> y
                lo = min(other); hi = max(other);
                plot([h.xMin_m h.xMax_m h.xMax_m h.xMin_m h.xMin_m], [lo lo hi hi lo], 'k-', 'linewidth', 1.2);
            end
        end
    end
end
