classdef CalPlotFrameAdapter
    %CALPLOTFRAMEADAPTER Raw installed-CST axes -> displayed spacecraft Body axes, PER installed dataset (figures only).
    %   d_B = C * d_raw (3D view),  d_raw = C.' * d_B (body / antenna-local cuts; C orthogonal). One C per dataset,
    %   shared by the 3D, XY, XZ, YZ and local views of that dataset; no per-plane flip; gain values never changed.
    %   C is a plotting-frame adapter, NOT the physical mount (R_BA / R_BL are untouched). RFI never uses it.
    %
    %   Table: data/cal_config/cal_installed_frame_corrections.csv, keyed by (installation_id, source_file_stem,
    %   source_frequency_ghz); full 3x3 matrices. No family-wide or frequency-wide shared matrix exists.
    %
    %   Boresight validation (authoritative physical reference = SSOT panel outward normal n_B):
    %     high-gain content = raw samples within HIGH_GAIN_WINDOW_DB of the peak, weighted by solid angle and
    %     linear gain; its share in the +n_B / -n_B hemispheres decides main_lobe_hemisphere
    %     (EXPECTED_BORESIGHT | OPPOSITE_BORESIGHT | AMBIGUOUS); the peak of each hemisphere is reported. Not a
    %     single global-peak test.
    %   resolve(): table C validated; if its main lobe is not EXPECTED_BORESIGHT the table row FAILS and the figures
    %   use the signed permutation whose main lobe lies in +n_B closest to n_B (main-lobe angle, 1 deg bins), ties
    %   broken by the smallest change from the table (min ||C - C_table||_F) (resolution AUTO_RESOLVED);
    %   none -> table C kept, status FAIL.
    properties (Constant)
        HIGH_GAIN_WINDOW_DB = 10
        OFF_NORMAL_WARN_DEG = 45     % EXPECTED hemisphere but main-lobe centroid this far from n_B -> WARN
        FREQ_TOL_GHZ = 1e-3
        AMBIGUOUS_BAND = 0.02        % high-gain share within 50 +/- 2 % -> AMBIGUOUS
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
            %RAWTODISPLAYEDBODY Resolved C of a CAL pattern (identity for free-space / CST_LOCAL patterns).
            if isprop(pattern, 'C_raw_to_body') && ~isempty(pattern.C_raw_to_body)
                C = pattern.C_raw_to_body; key = pattern.frameCorrection.correction_key;
            else
                C = eye(3); key = 'IDENTITY_FREE_SPACE';
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

        function r = resolve(native, entry, n_B, ident)
            %RESOLVE Validate the table C of one installed dataset and pick the C used by its figures.
            %   ident: struct(installationId, sourceFile, sourceFrequency_GHz). r: frame-correction record.
            A = rfscreen.cal.CalPlotFrameAdapter;
            if isempty(entry)
                Ct = eye(3); key = sprintf('NO_TABLE_ROW_%s', ident.installationId); prov = 'NONE';
            else
                Ct = entry.C; key = entry.key; prov = entry.provenance;
            end
            mt = A.hemisphereMetrics(native, Ct, n_B);
            C = Ct; m = mt; resolution = 'TABLE';
            if ~strcmp(mt.hemisphere, 'EXPECTED_BORESIGHT')
                P = A.signedPermutations(); best = []; bestScore = [Inf Inf];
                for i = 1:numel(P)
                    mi = A.hemisphereMetrics(native, P{i}, n_B);
                    if ~strcmp(mi.hemisphere, 'EXPECTED_BORESIGHT'); continue; end
                    sc = [round(mi.centroidAngle_deg), round(norm(P{i} - Ct, 'fro') * 1e9) / 1e9];
                    if sc(1) < bestScore(1) || (sc(1) == bestScore(1) && sc(2) < bestScore(2))
                        bestScore = sc; best = i; m = mi;
                    end
                end
                if isempty(best)
                    resolution = 'UNRESOLVED';
                else
                    C = P{best}; resolution = 'AUTO_RESOLVED';
                end
            end
            if strcmp(m.hemisphere, 'EXPECTED_BORESIGHT') && strcmp(resolution, 'TABLE')
                status = 'PASS';
                if m.centroidAngle_deg > A.OFF_NORMAL_WARN_DEG; status = 'WARN_MAIN_LOBE_OFF_NORMAL'; end
                if m.peakNeg_dBi > m.peakPos_dBi; status = 'WARN_GLOBAL_PEAK_IN_OPPOSITE_HEMISPHERE'; end
            elseif strcmp(resolution, 'AUTO_RESOLVED')
                status = 'FAIL_TABLE_MATRIX_AUTO_RESOLVED';
            else
                status = 'FAIL';
            end
            n = n_B(:) / norm(n_B);
            fmtC = @(M) strjoin(arrayfun(@(x) sprintf('%g', x), reshape(M.', 1, []), 'UniformOutput', false), ' ');
            r = struct('installation_id', ident.installationId, 'source_file', ident.sourceFile, ...
                'source_frequency_ghz', ident.sourceFrequency_GHz, 'correction_key', key, 'table_provenance', prov, ...
                'C_table', fmtC(Ct), 'table_main_lobe_hemisphere', mt.hemisphere, 'resolution', resolution, ...
                'C_raw_to_body', fmtC(C), 'expected_boresight_x', n(1), 'expected_boresight_y', n(2), 'expected_boresight_z', n(3), ...
                'raw_peak_direction', A.vec(m.rawPeak), 'corrected_peak_direction', A.vec(m.bodyPeak), ...
                'peak_angle_to_expected_boresight_deg', m.peakAngle_deg, 'main_lobe_centroid_direction', A.vec(m.mainLobeCentroid_B), ...
                'angle_to_expected_boresight_deg', m.centroidAngle_deg, ...
                'positive_boresight_hemisphere_peak_dbi', m.peakPos_dBi, 'negative_boresight_hemisphere_peak_dbi', m.peakNeg_dBi, ...
                'positive_hemisphere_high_gain_fraction', m.highGainFractionPos, 'main_lobe_hemisphere', m.hemisphere, ...
                'status', status, 'C', C, 'C_table_matrix', Ct);
        end

        function L = validationLines(r)
            %VALIDATIONLINES Console / run-summary block of one installed dataset.
            L = {sprintf('[CAL] installed boresight validation: %s  %s @ %.6g GHz  -> %s', r.installation_id, r.source_file, ...
                r.source_frequency_ghz, r.status)};
            L{end+1} = sprintf('      correction %s (%s): table C = [%s], used C = [%s] (%s)', r.correction_key, r.table_provenance, ...
                r.C_table, r.C_raw_to_body, r.resolution);
            L{end+1} = sprintf('      expected boresight n_B = [%+.3f %+.3f %+.3f]', r.expected_boresight_x, r.expected_boresight_y, r.expected_boresight_z);
            L{end+1} = sprintf('      raw peak %s -> corrected peak %s (%.1f deg from n_B)', r.raw_peak_direction, ...
                r.corrected_peak_direction, r.peak_angle_to_expected_boresight_deg);
            L{end+1} = sprintf('      main-lobe centroid %s: %.1f deg from n_B; hemisphere peaks +n_B %.2f / -n_B %.2f dBi; high-gain share in +n_B %.0f%%', ...
                r.main_lobe_centroid_direction, r.angle_to_expected_boresight_deg, r.positive_boresight_hemisphere_peak_dbi, ...
                r.negative_boresight_hemisphere_peak_dbi, 100 * r.positive_hemisphere_high_gain_fraction);
            L{end+1} = sprintf('      main-lobe hemisphere (used C): %s; with the table C: %s', r.main_lobe_hemisphere, r.table_main_lobe_hemisphere);
            if ~strcmp(r.status, 'PASS')
                bar = repmat('!', 1, 100);
                L = [{bar} L {sprintf('      %s: %s', r.status, rfscreen.cal.CalPlotFrameAdapter.statusText(r)), bar}];
            end
        end

        function s = statusText(r)
            switch r.status
                case 'FAIL_TABLE_MATRIX_AUTO_RESOLVED'
                    s = sprintf(['the table matrix puts the main lobe in the %s hemisphere (sidelobe/backlobe shown as boresight); ' ...
                        'figures use the best-aligned nearest signed permutation [%s] - update cal_installed_frame_corrections.csv'], ...
                        r.table_main_lobe_hemisphere, r.C_raw_to_body);
                case 'FAIL'
                    s = 'no axis permutation / sign puts the main lobe in the +n_B hemisphere - installed figures are NOT valid';
                case 'WARN_GLOBAL_PEAK_IN_OPPOSITE_HEMISPHERE'
                    s = sprintf(['main-lobe content is in +n_B but the single highest sample (%.2f dBi) is in -n_B ' ...
                        '(+n_B peak %.2f dBi) - review'], r.negative_boresight_hemisphere_peak_dbi, r.positive_boresight_hemisphere_peak_dbi);
                case 'WARN_MAIN_LOBE_OFF_NORMAL'
                    s = sprintf('main lobe in the +n_B hemisphere but %.1f deg from n_B (scattering?) - review', r.angle_to_expected_boresight_deg);
                otherwise
                    s = '';
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
