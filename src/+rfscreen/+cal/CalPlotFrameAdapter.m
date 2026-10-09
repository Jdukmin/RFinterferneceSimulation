classdef CalPlotFrameAdapter
    %CALPLOTFRAMEADAPTER Owner steering of the installed CST figures: three rotation ANGLES per installed dataset.
    %   The only display input is data/cal_config/installed_pattern_rotation.csv (rot_x_deg, rot_y_deg, rot_z_deg),
    %   one independent row per installed dataset, keyed by installation_id + CST SOURCE frequency:
    %     GPSA_1 @ 1.2, GPSA_2 @ 1.2, SBA_NADIR @ 2.06, SBA_NADIR @ 2.25, SBA_ZENITH @ 2.06, SBA_ZENITH @ 2.25.
    %   No matrix is configured anywhere; 0 / 0 / 0 deg shows the raw CST result axes as Body axes.
    %   Convention (fixed): active rotation in the spacecraft Body frame, R = Rz(rot_z) * Ry(rot_y) * Rx(rot_x)
    %   (a vector is rotated about X_B first, then Y_B, then Z_B). d_B = R d_raw (3D view); d_raw = R.' d_B
    %   (BODY_XY / XZ / YZ and LOCAL_XZ / YZ cuts). One rotation per dataset, shared by all its installed views.
    %   Gain values never change; R_BA / R_BL / positions / panel normals are never changed; raw pattern_plots/ are
    %   never rotated; RFI never uses installed patterns.
    %
    %   Boresight check (report only - never changes the owner angles): high-gain content (samples within
    %   HIGH_GAIN_WINDOW_DB of the peak, solid-angle x linear-gain weighted) in the +n_B / -n_B hemispheres of the
    %   SSOT panel outward normal -> main_lobe_hemisphere EXPECTED_BORESIGHT | OPPOSITE_BORESIGHT | AMBIGUOUS.
    properties (Constant)
        HIGH_GAIN_WINDOW_DB = 10
        OFF_NORMAL_WARN_DEG = 45
        FREQ_TOL_GHZ = 1e-3
        AMBIGUOUS_BAND = 0.02
        CONVENTION = 'R = Rz(rot_z)*Ry(rot_y)*Rx(rot_x), active Body-frame rotation (X first, then Y, then Z)'
        INSTALLED_DATASETS = {'GPSA_1', 1.2; 'GPSA_2', 1.2; 'SBA_NADIR', 2.06; 'SBA_NADIR', 2.25; ...
            'SBA_ZENITH', 2.06; 'SBA_ZENITH', 2.25}
    end
    methods (Static)
        function [C, key] = rawToDisplayedBody(pattern, f_Hz) %#ok<INUSD>
            %RAWTODISPLAYEDBODY Owner rotation of a CAL pattern (identity for free-space / CST_LOCAL patterns).
            if isprop(pattern, 'C_raw_to_body') && ~isempty(pattern.C_raw_to_body)
                C = pattern.C_raw_to_body; fc = pattern.frameCorrection;
                key = sprintf('%s@%gGHz Rx=%g Ry=%g Rz=%g', fc.installation_id, fc.source_frequency_ghz, fc.rot_x_deg, fc.rot_y_deg, fc.rot_z_deg);
            else
                C = eye(3); key = 'IDENTITY_FREE_SPACE';
            end
        end

        function dRaw = toRaw(pattern, dB)
            %TORAW Desired Body direction(s) -> raw CST query direction(s) (rotation inverse = transpose).
            dRaw = rfscreen.cal.CalPlotFrameAdapter.rawToDisplayedBody(pattern).' * dB;
        end

        function [R, info] = effectiveTransform(pattern, rotationConfig)
            %EFFECTIVETRANSFORM Rotation of an installed pattern for a steering config (default: its own record).
            A = rfscreen.cal.CalPlotFrameAdapter;
            fc = pattern.frameCorrection;
            if nargin < 2 || isempty(rotationConfig)
                st = struct('rot_x_deg', fc.rot_x_deg, 'rot_y_deg', fc.rot_y_deg, 'rot_z_deg', fc.rot_z_deg, ...
                    'configured', strcmp(fc.user_rotation_status, 'CONFIGURED'));
            else
                st = A.lookupRotation(rotationConfig, fc.installation_id, fc.source_frequency_ghz);
            end
            R = A.userRotation(st.rot_x_deg, st.rot_y_deg, st.rot_z_deg);
            info = struct('installation_id', fc.installation_id, 'source_frequency_ghz', fc.source_frequency_ghz, ...
                'rot_x_deg', st.rot_x_deg, 'rot_y_deg', st.rot_y_deg, 'rot_z_deg', st.rot_z_deg, ...
                'rotation_configured', st.configured, 'effective_transform', R);
        end

        function R = userRotation(rx, ry, rz)
            %USERROTATION Owner rule R = Rz * Ry * Rx (active, Body frame, degrees).
            Rx = [1 0 0; 0 cosd(rx) -sind(rx); 0 sind(rx) cosd(rx)];
            Ry = [cosd(ry) 0 sind(ry); 0 1 0; -sind(ry) 0 cosd(ry)];
            Rz = [cosd(rz) -sind(rz) 0; sind(rz) cosd(rz) 0; 0 0 1];
            R = Rz * Ry * Rx;
            R(abs(R) < 1e-12) = 0;                      % exact zeros for 90 / 180 deg steps
        end

        function f = defaultRotationFile()
            here = fileparts(mfilename('fullpath'));
            f = fullfile(fileparts(fileparts(fileparts(here))), 'data', 'cal_config', 'installed_pattern_rotation.csv');
        end

        function S = loadRotationConfig(file)
            %LOADROTATIONCONFIG Owner angle rows; each (installation, source frequency) must be one of INSTALLED_DATASETS
            %   and appear at most once; angles numeric (rfscreen:cal:badRotationConfig otherwise).
            A = rfscreen.cal.CalPlotFrameAdapter;
            if nargin < 1 || isempty(file); file = A.defaultRotationFile(); end
            S = struct('installation_id', {}, 'source_frequency_ghz', {}, 'rot_x_deg', {}, 'rot_y_deg', {}, 'rot_z_deg', {}, 'note', {});
            if exist(file, 'file') ~= 2; return; end
            R = rfscreen.spacecraft.SpacecraftDataReader.readTable(file);
            need = {'installation_id', 'source_frequency_ghz', 'rot_x_deg', 'rot_y_deg', 'rot_z_deg'};
            for k = 1:numel(need)
                if ~isfield(R, need{k})
                    error('rfscreen:cal:badRotationConfig', '%s: column %s missing.', file, need{k});
                end
            end
            D = A.INSTALLED_DATASETS;
            for r = 1:R.nRows
                id = strtrim(R.installation_id{r});
                v = cellfun(@(n) str2double(R.(n){r}), need(2:end));
                if any(~isfinite(v))
                    error('rfscreen:cal:badRotationConfig', '%s row %d (%s): non-numeric frequency / angle.', file, r, id);
                end
                okId = strcmp(D(:, 1), id);
                if ~any(okId)
                    error('rfscreen:cal:badRotationConfig', '%s row %d: unknown installed installation_id "%s" (known: %s).', ...
                        file, r, id, strjoin(unique(D(:, 1)).', ' '));
                end
                if ~any(okId & abs(cell2mat(D(:, 2)) - v(1)) <= A.FREQ_TOL_GHZ)
                    error('rfscreen:cal:badRotationConfig', '%s row %d: %s has no installed dataset at source %.6g GHz.', file, r, id, v(1));
                end
                if any(strcmp({S.installation_id}, id) & abs([S.source_frequency_ghz] - v(1)) <= A.FREQ_TOL_GHZ)
                    error('rfscreen:cal:badRotationConfig', '%s: duplicate steering row %s @ %.6g GHz.', file, id, v(1));
                end
                note = ''; if isfield(R, 'note'); note = R.note{r}; end
                S(end+1) = struct('installation_id', id, 'source_frequency_ghz', v(1), 'rot_x_deg', v(2), 'rot_y_deg', v(3), ...
                    'rot_z_deg', v(4), 'note', note); %#ok<AGROW>
            end
        end

        function st = lookupRotation(S, installationId, sourceFrequency_GHz)
            %LOOKUPROTATION Angles of one dataset; no row -> 0 / 0 / 0 (configured = false).
            st = struct('rot_x_deg', 0, 'rot_y_deg', 0, 'rot_z_deg', 0, 'configured', false);
            for k = 1:numel(S)
                if strcmp(S(k).installation_id, installationId) && ...
                        abs(S(k).source_frequency_ghz - sourceFrequency_GHz) <= rfscreen.cal.CalPlotFrameAdapter.FREQ_TOL_GHZ
                    st = struct('rot_x_deg', S(k).rot_x_deg, 'rot_y_deg', S(k).rot_y_deg, 'rot_z_deg', S(k).rot_z_deg, 'configured', true);
                    return;
                end
            end
        end

        function d = sphericalDirection(theta_deg, phi_deg)
            d = [sind(theta_deg(:).') .* cosd(phi_deg(:).'); sind(theta_deg(:).') .* sind(phi_deg(:).'); cosd(theta_deg(:).')];
        end

        function m = hemisphereMetrics(native, C, n_B)
            %HEMISPHEREMETRICS Main-lobe hemisphere of the displayed pattern relative to n_B (raw gains, no change).
            A = rfscreen.cal.CalPlotFrameAdapter;
            n = n_B(:) / norm(n_B);
            [TH, PH] = ndgrid(native.theta_deg, native.phi_deg);
            G = native.gain_dBi;
            dB = C * A.sphericalDirection(TH, PH);
            s = (n.' * dB).';
            w = sind(TH(:)) * deg2rad(native.thetaStep_deg) * deg2rad(native.phiStep_deg);
            w(w <= 0) = 1e-6;                                    % pole rows keep a token weight
            gl = 10 .^ (G(:) / 10);
            hi = G(:) >= max(G(:)) - A.HIGH_GAIN_WINDOW_DB;
            pPos = sum(w(hi & s > 0) .* gl(hi & s > 0)); pNeg = sum(w(hi & s < 0) .* gl(hi & s < 0));
            m = struct();
            m.peakPos_dBi = A.maxOr(G(s > 0)); m.peakNeg_dBi = A.maxOr(G(s < 0));
            m.highGainFractionPos = pPos / max(pPos + pNeg, realmin);
            v = dB(:, hi) * (w(hi) .* gl(hi)); v = v / max(norm(v), realmin);
            m.mainLobeCentroid_B = v;
            m.centroidAngle_deg = acosd(max(-1, min(1, v.' * n)));
            [~, k] = max(G(:));
            m.rawPeak = A.sphericalDirection(TH(k), PH(k)); m.bodyPeak = C * m.rawPeak;
            m.peakAngle_deg = acosd(max(-1, min(1, m.bodyPeak.' * n)));
            if m.highGainFractionPos > 0.5 + A.AMBIGUOUS_BAND
                m.hemisphere = 'EXPECTED_BORESIGHT';
            elseif m.highGainFractionPos < 0.5 - A.AMBIGUOUS_BAND
                m.hemisphere = 'OPPOSITE_BORESIGHT';
            else
                m.hemisphere = 'AMBIGUOUS';
            end
        end

        function r = resolve(native, n_B, ident, rotationConfig)
            %RESOLVE Owner rotation of one installed dataset + boresight check (report only).
            %   ident: struct(installationId, sourceFile, sourceFrequency_GHz); rotationConfig: loadRotationConfig().
            A = rfscreen.cal.CalPlotFrameAdapter;
            if nargin < 4; rotationConfig = []; end
            st = A.lookupRotation(rotationConfig, ident.installationId, ident.sourceFrequency_GHz);
            R = A.userRotation(st.rot_x_deg, st.rot_y_deg, st.rot_z_deg);
            m = A.hemisphereMetrics(native, R, n_B);
            switch m.hemisphere
                case 'EXPECTED_BORESIGHT'
                    status = 'PASS';
                    if m.centroidAngle_deg > A.OFF_NORMAL_WARN_DEG; status = 'WARN_MAIN_LOBE_OFF_NORMAL'; end
                    if m.peakNeg_dBi > m.peakPos_dBi; status = 'WARN_GLOBAL_PEAK_IN_OPPOSITE_HEMISPHERE'; end
                case 'OPPOSITE_BORESIGHT'
                    status = 'FAIL_MAIN_LOBE_OPPOSITE_BORESIGHT';
                otherwise
                    status = 'FAIL_MAIN_LOBE_AMBIGUOUS';
            end
            n = n_B(:) / norm(n_B);
            rot = 'CONFIGURED'; if ~st.configured; rot = 'USER_ROTATION_NOT_CONFIGURED'; end
            r = struct('installation_id', ident.installationId, 'source_file', ident.sourceFile, ...
                'source_frequency_ghz', ident.sourceFrequency_GHz, 'rot_x_deg', st.rot_x_deg, 'rot_y_deg', st.rot_y_deg, ...
                'rot_z_deg', st.rot_z_deg, 'user_rotation_status', rot, 'convention', A.CONVENTION, ...
                'expected_boresight_x', n(1), 'expected_boresight_y', n(2), 'expected_boresight_z', n(3), ...
                'raw_peak_direction', A.vec(m.rawPeak), 'displayed_peak_direction', A.vec(m.bodyPeak), ...
                'peak_angle_to_expected_boresight_deg', m.peakAngle_deg, 'main_lobe_centroid_direction', A.vec(m.mainLobeCentroid_B), ...
                'angle_to_expected_boresight_deg', m.centroidAngle_deg, ...
                'positive_boresight_hemisphere_peak_dbi', m.peakPos_dBi, 'negative_boresight_hemisphere_peak_dbi', m.peakNeg_dBi, ...
                'positive_hemisphere_high_gain_fraction', m.highGainFractionPos, 'main_lobe_hemisphere', m.hemisphere, ...
                'status', status, 'C', R);
        end

        function L = steeringLines(r)
            %STEERINGLINES Console / run-summary block of one installed dataset (angles + boresight check).
            L = {'[CAL] INSTALLED STEERING'};
            L{end+1} = sprintf('  pattern      : %s (%s)', r.installation_id, r.source_file);
            L{end+1} = sprintf('  source freq  : %.6g GHz', r.source_frequency_ghz);
            if strcmp(r.user_rotation_status, 'CONFIGURED')
                L{end+1} = sprintf('  user rotation: Rx=%g deg, Ry=%g deg, Rz=%g deg  (%s)', r.rot_x_deg, r.rot_y_deg, r.rot_z_deg, r.convention);
            else
                L{end+1} = '  user rotation: USER_ROTATION_NOT_CONFIGURED -> using 0/0/0 deg';
            end
            L{end+1} = sprintf('  expected n_B : [%+.3f %+.3f %+.3f]', r.expected_boresight_x, r.expected_boresight_y, r.expected_boresight_z);
            L{end+1} = sprintf('  peak         : raw %s -> displayed %s (%.1f deg from n_B)', r.raw_peak_direction, ...
                r.displayed_peak_direction, r.peak_angle_to_expected_boresight_deg);
            L{end+1} = sprintf('  main lobe    : %s, centroid %.1f deg from n_B; peaks +n_B %.2f / -n_B %.2f dBi; high-gain share +n_B %.0f%%', ...
                r.main_lobe_hemisphere, r.angle_to_expected_boresight_deg, r.positive_boresight_hemisphere_peak_dbi, ...
                r.negative_boresight_hemisphere_peak_dbi, 100 * r.positive_hemisphere_high_gain_fraction);
            L{end+1} = sprintf('  check        : %s', r.status);
            if ~strncmp(r.status, 'PASS', 4)
                bar = repmat('!', 1, 100);
                L = [{bar} L {sprintf(['  %s: displayed main lobe is not on the panel outward normal - adjust rot_x_deg / rot_y_deg / ' ...
                    'rot_z_deg of %s @ %.6g GHz in installed_pattern_rotation.csv (the angles are used as entered)'], ...
                    r.status, r.installation_id, r.source_frequency_ghz), bar}];
            end
        end

        function s = vec(v)
            s = sprintf('[%+.3f %+.3f %+.3f]', v(1), v(2), v(3));
        end

        function x = maxOr(v)
            if isempty(v); x = -Inf; else; x = max(v); end
        end
    end
end
