classdef CalPlotFrameAdapter
    %CALPLOTFRAMEADAPTER Raw installed-CST axes -> displayed spacecraft Body axes, PER installed dataset (figures only).
    %   Priority: physical installation geometry -> raw CST result -> C_base (base coordinate adapter) ->
    %   OWNER USER ROTATION R_user -> final installed plot.
    %     C_base     data/cal_config/cal_installed_frame_corrections.csv, keyed by (installation_id, source_file_stem,
    %                source_frequency_ghz); full 3x3 orthogonal.
    %     R_user     data/cal_config/installed_pattern_rotation.csv, keyed by installation_id + SOURCE frequency; active
    %                Body-frame rotation R_user = Rz(rot_z) * Ry(rot_y) * Rx(rot_x) (vector: X first, then Y, then Z).
    %     C_effective = R_user * C_base;   d_B = C_effective d_raw (3D);   d_raw = C_effective.' d_B (body / local cuts).
    %   One C_effective per dataset, shared by its 3D, XY, XZ, YZ and local views; datasets are independent (no
    %   family-wide or frequency-wide matrix). No per-plane flip; gain values never changed. Not the physical mount
    %   (R_BA / R_BL / positions / panel normals untouched); raw pattern_plots/ are not steered; RFI never uses it.
    %
    %   Boresight validation (diagnostic only - it NEVER replaces the owner steering): high-gain content (samples
    %   within HIGH_GAIN_WINDOW_DB of the peak, solid-angle x linear-gain weighted) in the +n_B / -n_B hemispheres of
    %   the panel outward normal decides main_lobe_hemisphere (EXPECTED_BORESIGHT | OPPOSITE_BORESIGHT | AMBIGUOUS);
    %   hemisphere peaks and main-lobe angle are reported. A failing dataset is printed loudly with a suggested
    %   signed permutation; the figures keep C_effective as configured.
    properties (Constant)
        HIGH_GAIN_WINDOW_DB = 10
        OFF_NORMAL_WARN_DEG = 45     % EXPECTED hemisphere but main-lobe centroid this far from n_B -> WARN
        FREQ_TOL_GHZ = 1e-3
        AMBIGUOUS_BAND = 0.02        % high-gain share within 50 +/- 2 % -> AMBIGUOUS
        CONVENTION = 'R_user = Rz(rot_z)*Ry(rot_y)*Rx(rot_x), active Body-frame rotation (X first, then Y, then Z); C_effective = R_user*C_base'
    end
    methods (Static)
        function T = loadTable(file)
            %LOADTABLE struct array: key, installationId, stem, sourceFrequency_GHz, C, provenance, note.
            if nargin < 1 || isempty(file); file = rfscreen.cal.CalPlotFrameAdapter.defaultTableFile(); end
            R = rfscreen.spacecraft.SpacecraftDataReader.readTable(file);
            T = struct('key', {}, 'installationId', {}, 'stem', {}, 'sourceFrequency_GHz', {}, 'C', {}, 'provenance', {}, 'note', {});
            names = {'c11', 'c12', 'c13', 'c21', 'c22', 'c23', 'c31', 'c32', 'c33'};
            for r = 1:R.nRows
                v = cellfun(@(n) str2double(R.(n){r}), names);
                C = reshape(v, 3, 3).';
                if any(~isfinite(v)) || norm(C.' * C - eye(3)) > 1e-9
                    error('rfscreen:cal:badFrameCorrection', '%s row %s: C must be a finite orthogonal 3x3 matrix.', file, R.correction_key{r});
                end
                e = struct('key', R.correction_key{r}, 'installationId', R.installation_id{r}, 'stem', R.source_file_stem{r}, ...
                    'sourceFrequency_GHz', str2double(R.source_frequency_ghz{r}), 'C', C, 'provenance', R.provenance{r}, 'note', R.note{r});
                if any(strcmp({T.key}, e.key)) || any(strcmp({T.stem}, e.stem))
                    error('rfscreen:cal:badFrameCorrection', '%s: duplicate correction key / source file %s.', file, e.stem);
                end
                T(end+1) = e; %#ok<AGROW>
            end
        end

        function f = defaultTableFile()
            here = fileparts(mfilename('fullpath'));
            f = fullfile(fileparts(fileparts(fileparts(here))), 'data', 'cal_config', 'cal_installed_frame_corrections.csv');
        end

        function e = lookup(T, installationId, stem, sourceFrequency_GHz)
            %LOOKUP Table row of ONE installed dataset ([] if none). Installation, file and source frequency must all match.
            e = [];
            for k = 1:numel(T)
                if strcmp(T(k).installationId, installationId) && strcmpi(T(k).stem, stem) && ...
                        abs(T(k).sourceFrequency_GHz - sourceFrequency_GHz) <= rfscreen.cal.CalPlotFrameAdapter.FREQ_TOL_GHZ
                    e = T(k); return;
                end
            end
        end

        function [C, key] = rawToDisplayedBody(pattern, f_Hz) %#ok<INUSD>
            %RAWTODISPLAYEDBODY C_effective of a CAL pattern (identity for free-space / CST_LOCAL patterns).
            if isprop(pattern, 'C_raw_to_body') && ~isempty(pattern.C_raw_to_body)
                C = pattern.C_raw_to_body; key = pattern.frameCorrection.correction_key;
            else
                C = eye(3); key = 'IDENTITY_FREE_SPACE';
            end
        end

        function [C, info] = effectiveTransform(pattern, rotationConfig)
            %EFFECTIVETRANSFORM C_effective = R_user * C_base of an installed pattern for a steering config
            %   (rotationConfig: loadRotationConfig() result; default = the pattern's own resolved record).
            A = rfscreen.cal.CalPlotFrameAdapter;
            fc = pattern.frameCorrection;
            if nargin < 2 || isempty(rotationConfig)
                C = pattern.C_raw_to_body; info = A.steeringInfo(fc); return;
            end
            st = A.lookupRotation(rotationConfig, fc.installation_id, fc.source_frequency_ghz);
            Ru = A.userRotation(st.rot_x_deg, st.rot_y_deg, st.rot_z_deg);
            C = Ru * fc.C_base_matrix;
            info = struct('installation_id', fc.installation_id, 'source_frequency_ghz', fc.source_frequency_ghz, ...
                'base_transform', fc.C_base_matrix, 'rot_x_deg', st.rot_x_deg, 'rot_y_deg', st.rot_y_deg, 'rot_z_deg', st.rot_z_deg, ...
                'user_rotation_matrix', Ru, 'effective_transform', C, 'rotation_configured', st.configured);
        end

        function info = steeringInfo(fc)
            info = struct('installation_id', fc.installation_id, 'source_frequency_ghz', fc.source_frequency_ghz, ...
                'base_transform', fc.C_base_matrix, 'rot_x_deg', fc.rot_x_deg, 'rot_y_deg', fc.rot_y_deg, 'rot_z_deg', fc.rot_z_deg, ...
                'user_rotation_matrix', fc.R_user_matrix, 'effective_transform', fc.C, 'rotation_configured', strcmp(fc.user_rotation_status, 'CONFIGURED'));
        end

        function R = userRotation(rx, ry, rz)
            %USERROTATION Owner rule R_user = Rz * Ry * Rx (active, Body frame, degrees).
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

        function S = loadRotationConfig(file, table)
            %LOADROTATIONCONFIG Owner steering rows; each (installation, source frequency) must be an installed dataset
            %   of the base table and appear at most once (rfscreen:cal:badRotationConfig otherwise).
            A = rfscreen.cal.CalPlotFrameAdapter;
            if nargin < 1 || isempty(file); file = A.defaultRotationFile(); end
            if nargin < 2 || isempty(table); table = A.loadTable(); end
            S = struct('installation_id', {}, 'source_frequency_ghz', {}, 'rot_x_deg', {}, 'rot_y_deg', {}, 'rot_z_deg', {}, 'note', {});
            if exist(file, 'file') ~= 2; return; end
            R = rfscreen.spacecraft.SpacecraftDataReader.readTable(file);
            need = {'installation_id', 'source_frequency_ghz', 'rot_x_deg', 'rot_y_deg', 'rot_z_deg'};
            for k = 1:numel(need)
                if ~isfield(R, need{k})
                    error('rfscreen:cal:badRotationConfig', '%s: column %s missing.', file, need{k});
                end
            end
            for r = 1:R.nRows
                id = strtrim(R.installation_id{r});
                v = cellfun(@(n) str2double(R.(n){r}), need(2:end));
                if any(~isfinite(v))
                    error('rfscreen:cal:badRotationConfig', '%s row %d (%s): non-numeric frequency / angle.', file, r, id);
                end
                okId = strcmp({table.installationId}, id);
                if ~any(okId)
                    error('rfscreen:cal:badRotationConfig', '%s row %d: unknown installed installation_id "%s" (known: %s).', ...
                        file, r, id, strjoin(unique({table.installationId}), ' '));
                end
                if ~any(okId & abs([table.sourceFrequency_GHz] - v(1)) <= A.FREQ_TOL_GHZ)
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
            %LOOKUPROTATION Steering of one dataset; no row -> 0 / 0 / 0 (configured = false).
            st = struct('rot_x_deg', 0, 'rot_y_deg', 0, 'rot_z_deg', 0, 'configured', false);
            for k = 1:numel(S)
                if strcmp(S(k).installation_id, installationId) && ...
                        abs(S(k).source_frequency_ghz - sourceFrequency_GHz) <= rfscreen.cal.CalPlotFrameAdapter.FREQ_TOL_GHZ
                    st = struct('rot_x_deg', S(k).rot_x_deg, 'rot_y_deg', S(k).rot_y_deg, 'rot_z_deg', S(k).rot_z_deg, 'configured', true);
                    return;
                end
            end
        end

        function dRaw = toRaw(pattern, dB)
            %TORAW Desired displayed-Body direction(s) -> raw CST query direction(s): C^-1 = C.' (orthogonal).
            dRaw = rfscreen.cal.CalPlotFrameAdapter.rawToDisplayedBody(pattern).' * dB;
        end

        function d = sphericalDirection(theta_deg, phi_deg)
            d = [sind(theta_deg(:).') .* cosd(phi_deg(:).'); sind(theta_deg(:).') .* sind(phi_deg(:).'); cosd(theta_deg(:).')];
        end

        function P = signedPermutations()
            %SIGNEDPERMUTATIONS All 48 axis permutation / sign matrices (cell array).
            pm = perms(1:3); P = {};
            for i = 1:size(pm, 1)
                for s = 0:7
                    sg = 1 - 2 * [bitand(s, 1) > 0, bitand(s, 2) > 0, bitand(s, 4) > 0];
                    C = zeros(3); C(sub2ind([3 3], 1:3, pm(i, :))) = sg;
                    P{end+1} = C; %#ok<AGROW>
                end
            end
        end

        function m = hemisphereMetrics(native, C, n_B)
            %HEMISPHEREMETRICS Main-lobe hemisphere of the corrected pattern relative to n_B (raw gains, no change).
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
            % Decided by the high-gain CONTENT (not by the single global peak); the hemisphere peaks are reported.
            if m.highGainFractionPos > 0.5 + A.AMBIGUOUS_BAND
                m.hemisphere = 'EXPECTED_BORESIGHT';
            elseif m.highGainFractionPos < 0.5 - A.AMBIGUOUS_BAND
                m.hemisphere = 'OPPOSITE_BORESIGHT';
            else
                m.hemisphere = 'AMBIGUOUS';
            end
        end

        function r = resolve(native, entry, n_B, ident, rotationConfig)
            %RESOLVE C_effective = R_user * C_base of one installed dataset + boresight validation (diagnostic only).
            %   ident: struct(installationId, sourceFile, sourceFrequency_GHz); rotationConfig: loadRotationConfig().
            A = rfscreen.cal.CalPlotFrameAdapter;
            if nargin < 5; rotationConfig = []; end
            if isempty(entry)
                Cb = eye(3); key = sprintf('NO_BASE_ROW_%s', ident.installationId); prov = 'NONE';
            else
                Cb = entry.C; key = entry.key; prov = entry.provenance;
            end
            st = A.lookupRotation(rotationConfig, ident.installationId, ident.sourceFrequency_GHz);
            Ru = A.userRotation(st.rot_x_deg, st.rot_y_deg, st.rot_z_deg);
            C = Ru * Cb;
            m = A.hemisphereMetrics(native, C, n_B);
            suggested = '';
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
            if ~strncmp(status, 'PASS', 4)
                suggested = A.suggestion(native, C, n_B);
            end
            n = n_B(:) / norm(n_B);
            fmtC = @(M) strjoin(arrayfun(@(x) sprintf('%.6g', x), reshape(M.', 1, []), 'UniformOutput', false), ' ');
            rot = 'CONFIGURED'; if ~st.configured; rot = 'USER_ROTATION_NOT_CONFIGURED'; end
            r = struct('installation_id', ident.installationId, 'source_file', ident.sourceFile, ...
                'source_frequency_ghz', ident.sourceFrequency_GHz, 'correction_key', key, 'base_provenance', prov, ...
                'base_transform', fmtC(Cb), 'rot_x_deg', st.rot_x_deg, 'rot_y_deg', st.rot_y_deg, 'rot_z_deg', st.rot_z_deg, ...
                'user_rotation_status', rot, 'user_rotation_matrix', fmtC(Ru), 'effective_transform', fmtC(C), ...
                'C_raw_to_body', fmtC(C), 'expected_boresight_x', n(1), 'expected_boresight_y', n(2), 'expected_boresight_z', n(3), ...
                'raw_peak_direction', A.vec(m.rawPeak), 'corrected_peak_direction', A.vec(m.bodyPeak), ...
                'peak_angle_to_expected_boresight_deg', m.peakAngle_deg, 'main_lobe_centroid_direction', A.vec(m.mainLobeCentroid_B), ...
                'angle_to_expected_boresight_deg', m.centroidAngle_deg, ...
                'positive_boresight_hemisphere_peak_dbi', m.peakPos_dBi, 'negative_boresight_hemisphere_peak_dbi', m.peakNeg_dBi, ...
                'positive_hemisphere_high_gain_fraction', m.highGainFractionPos, 'main_lobe_hemisphere', m.hemisphere, ...
                'status', status, 'suggested_effective_transform', suggested, ...
                'C', C, 'C_base_matrix', Cb, 'R_user_matrix', Ru);
        end

        function s = suggestion(native, C, n_B)
            %SUGGESTION Diagnostic hint only: signed permutation with the main lobe closest to n_B (ties: nearest to C).
            A = rfscreen.cal.CalPlotFrameAdapter;
            P = A.signedPermutations(); best = []; bestScore = [Inf Inf];
            for i = 1:numel(P)
                mi = A.hemisphereMetrics(native, P{i}, n_B);
                if ~strcmp(mi.hemisphere, 'EXPECTED_BORESIGHT'); continue; end
                sc = [round(mi.centroidAngle_deg), round(norm(P{i} - C, 'fro') * 1e9) / 1e9];
                if sc(1) < bestScore(1) || (sc(1) == bestScore(1) && sc(2) < bestScore(2)); bestScore = sc; best = i; end
            end
            if isempty(best); s = 'none'; else
                s = strjoin(arrayfun(@(x) sprintf('%g', x), reshape(P{best}.', 1, []), 'UniformOutput', false), ' ');
            end
        end

        function L = steeringLines(r)
            %STEERINGLINES Console / run-summary block of one installed dataset (steering + boresight validation).
            L = {'[CAL] INSTALLED STEERING'};
            L{end+1} = sprintf('  pattern      : %s (%s, base %s)', r.installation_id, r.source_file, r.correction_key);
            L{end+1} = sprintf('  source freq  : %.6g GHz', r.source_frequency_ghz);
            L{end+1} = sprintf('  base C       : [%s]', r.base_transform);
            if strcmp(r.user_rotation_status, 'CONFIGURED')
                L{end+1} = sprintf('  user rotation: Rx=%g deg, Ry=%g deg, Rz=%g deg  (%s)', r.rot_x_deg, r.rot_y_deg, r.rot_z_deg, ...
                    rfscreen.cal.CalPlotFrameAdapter.CONVENTION);
            else
                L{end+1} = '  user rotation: USER_ROTATION_NOT_CONFIGURED -> using 0/0/0 deg';
            end
            L{end+1} = sprintf('  effective C  : [%s]', r.effective_transform);
            L{end+1} = sprintf('  expected n_B : [%+.3f %+.3f %+.3f]', r.expected_boresight_x, r.expected_boresight_y, r.expected_boresight_z);
            L{end+1} = sprintf('  peak         : raw %s -> displayed %s (%.1f deg from n_B)', r.raw_peak_direction, ...
                r.corrected_peak_direction, r.peak_angle_to_expected_boresight_deg);
            L{end+1} = sprintf('  main lobe    : %s, centroid %.1f deg from n_B; peaks +n_B %.2f / -n_B %.2f dBi; high-gain share +n_B %.0f%%', ...
                r.main_lobe_hemisphere, r.angle_to_expected_boresight_deg, r.positive_boresight_hemisphere_peak_dbi, ...
                r.negative_boresight_hemisphere_peak_dbi, 100 * r.positive_hemisphere_high_gain_fraction);
            L{end+1} = sprintf('  validation   : %s', r.status);
            if ~strncmp(r.status, 'PASS', 4)
                bar = repmat('!', 1, 100);
                L = [{bar} L {sprintf(['  %s: displayed main lobe is not on the panel outward normal (steering kept as configured; ' ...
                    'diagnostic suggestion C_effective = [%s]) - adjust installed_pattern_rotation.csv'], r.status, ...
                    r.suggested_effective_transform), bar}];
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
