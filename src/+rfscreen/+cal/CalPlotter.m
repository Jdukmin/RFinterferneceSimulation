classdef CalPlotter
    %CALPLOTTER CAL figures. Physics values are never altered for display:
    %   - gain values / colours = Realized Gain [dBi] queried from the native 3D CST grid;
    %   - 3D / polar RADIUS is a separate visualization-only mapping
    %       r_vis = R_VIS_M * max(0, G - (G_max - VIS_RANGE_DB)) / VIS_RANGE_DB
    %     (positive dB offset normalised to the pattern peak), because negative dBi cannot be a radius.
    %   A  planeCuts      : pattern-coordinate XZ (phi 0/180) and YZ (phi 90/270) full cuts, +Z = boresight
    %   B  installed3D    : spacecraft hull (SSOT panels) + body axes + mount point + boresight + 3D pattern
    %   C  bodyCuts       : body XZ / YZ / XY cross-sections; every sample is a body direction mapped
    %                       body -> antenna (R_BA') -> CST local (M_AL') -> (theta, phi) -> native interpolation
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

        function files = planeCuts(native, titleText, outPrefix)
            %PLANECUTS *_XZ.png and *_YZ.png (Cartesian signed angle from boresight vs gain).
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
                text(2, yl(1) + 2, 'boresight +Z (theta = 0)');
                xlabel(sprintf('signed angle from +Z in the CST %s plane [deg] (+: %s, -: %s)', planes{i}, ...
                    strtok(pos{i}, '('), strtok(neg{i}, '(')));
                ylabel('Realized Gain [dBi]');
                title(sprintf('%s - pattern-coordinate %s cut (peak %.2f dBi)', titleText, planes{i}, max(g)), 'interpreter', 'none');
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
            R_BL = rfscreen.kaa.CstLocalFrameAdapter.fromR_BA(inst.R_BA);
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
            vL = [sind(TH(:).') .* cosd(PH(:).'); sind(TH(:).') .* sind(PH(:).'); cosd(TH(:).')];
            vB = R_BL * vL;
            X = reshape(p0(1) + r(:).' .* vB(1, :), size(TH));
            Y = reshape(p0(2) + r(:).' .* vB(2, :), size(TH));
            Z = reshape(p0(3) + r(:).' .* vB(3, :), size(TH));
            surf(X, Y, Z, G, 'edgecolor', 'none');
            cb = colorbar(); ylabel(cb, sprintf('colour: Realized Gain [dBi] (peak %.2f)  |  radius: visualization only, %g dB offset scale', ...
                nat.peakGain_dBi, C.VIS_RANGE_DB));
            plot3(p0(1), p0(2), p0(3), 'ko', 'markerfacecolor', 'y', 'markersize', 8);
            n = inst.R_BA(:, 1) * 1.3 * C.R_VIS_M;
            quiver3(p0(1), p0(2), p0(3), n(1), n(2), n(3), 0, 'm', 'linewidth', 2.5);
            text(p0(1) + n(1), p0(2) + n(2), p0(3) + n(3), sprintf('%s boresight = mount normal', installationId), 'interpreter', 'none');
            axis equal; view(-50, 25);
            ylabel('Y_B [m]'); zlabel('Z_B [m]');
            % Single-line strings only (the gnuplot toolkit cannot render multi-line titles).
            title(sprintf('%s - installed pattern on spacecraft (body frame B)', titleText), 'interpreter', 'none');
            xlabel('X_B [m]');
            f = outPath;
            C.savePng(fig, f);
        end

        function [files, cuts] = bodyCuts(model, installationId, pattern, f_Hz, titleText, outPrefix)
            %BODYCUTS Body XZ / YZ / XY cross-sections of the transformed full-3D pattern.
            C = rfscreen.cal.CalPlotter;
            inst = model.installations(installationId);
            nat = pattern.native;
            cuts = C.bodyCutData(inst.R_BA, pattern, f_Hz);
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
                title(sprintf('Body %s plane: hull projection + pattern (radius visualization only)', planes{1}), 'interpreter', 'none');
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
                title(sprintf('%s - body %s cut (queried from the full 3D pattern)', titleText, planes{1}), 'interpreter', 'none');
                f = sprintf('%s_BODY_%s.png', outPrefix, planes{1});
                C.savePng(fig, f);
                files{end+1} = f; %#ok<AGROW>
            end
        end

        function cuts = bodyCutData(R_BA, pattern, f_Hz)
            %BODYCUTDATA Body XZ / YZ / XY cuts: d_B(alpha) in the plane -> u_A = R_BA' d_B ->
            %   pattern.gainAntenna (-> CST local -> theta/phi -> native 3D interpolation). No 2D-cut rotation.
            nat = pattern.native;
            step = min(nat.thetaStep_deg, nat.phiStep_deg);
            alpha = -180:step:180;
            planes = {'XZ', [1 3]; 'YZ', [2 3]; 'XY', [1 2]};
            cuts = struct('plane', {}, 'axes', {}, 'alpha_deg', {}, 'gain_dBi', {}, 'dir_B', {});
            for i = 1:size(planes, 1)
                ij = planes{i, 2};
                dB = zeros(3, numel(alpha));
                dB(ij(1), :) = cosd(alpha); dB(ij(2), :) = sind(alpha);
                g = pattern.gainAntenna(f_Hz, R_BA.' * dB);
                cuts(end+1) = struct('plane', planes{i, 1}, 'axes', ij, 'alpha_deg', alpha, 'gain_dBi', g, 'dir_B', dB); %#ok<AGROW>
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
