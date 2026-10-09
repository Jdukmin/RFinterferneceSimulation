classdef CalPlotFrameAdapter
    %CALPLOTFRAMEADAPTER Raw installed-CST axes -> displayed spacecraft Body axes (CAL figures only).
    %   The installed CST far-field exports are labelled SPACECRAFT_BODY_FIXED, but owner comparison of the CAL
    %   figures with the CST results showed axis-sign mismatches between the raw CST result axes and the CAL
    %   Body display. They are corrected by ONE 3x3 matrix applied to direction vectors:
    %       d_B   = C_raw_to_body * d_raw       (3D view: raw sample direction -> displayed Body direction)
    %       d_raw = C_raw_to_body.' * d_B       (Body / local cuts: desired Body direction -> raw query direction)
    %   Every 3D and 2D figure is derived from the same C; there is no per-plane flip. Gain values are never
    %   changed (raw G(theta, phi) is only re-addressed).
    %
    %   Owner-derived table (from the XY / XZ / YZ comparison against CST):
    %       GPSA installed (GPSA_GPSA1 / GPSA_GPSA2, every bound frequency)   C = diag([+1 -1 +1])
    %       SBA installed @ 2.06 GHz (SBA_NADIR and SBA_ZENITH)                C = diag([+1 +1 -1])
    %       SBA installed @ 2.25 GHz (SBA_NADIR and SBA_ZENITH)                C = diag([+1 -1 -1])
    %   Free-space (CST_LOCAL) patterns and any installed dataset not in the table: identity (not verified by
    %   the owner; no correction is invented).
    %
    %   C_raw_to_body is a plotting-frame adapter between CST result axes and the CAL display. It is NOT the
    %   physical installation: R_BA / R_BL (SimplifiedSpacecraftBuilder, CstLocalFrameAdapter) are unchanged.
    properties (Constant)
        FREQ_TOL_HZ = 1e6
        C_GPSA = diag([1 -1 1])
        C_SBA_206 = diag([1 1 -1])
        C_SBA_225 = diag([1 -1 -1])
        WARN_ANGLE_DEG = 90     % corrected peak in the hemisphere opposite to the panel normal
    end
    methods (Static)
        function [C, key] = rawToDisplayedBody(pattern, f_Hz)
            %RAWTODISPLAYEDBODY Correction matrix of a CAL pattern object (f_Hz default: its own CST plane).
            if nargin < 2 || isempty(f_Hz); f_Hz = pattern.cstFrequency_Hz; end
            [C, key] = rfscreen.cal.CalPlotFrameAdapter.lookup(pattern.patternType, pattern.family, f_Hz);
        end

        function [C, key] = lookup(patternType, family, f_Hz)
            %LOOKUP Correction table (patternType, family, frequency) -> C, key.
            A = rfscreen.cal.CalPlotFrameAdapter;
            C = eye(3); key = 'IDENTITY_FREE_SPACE';
            if ~strcmp(patternType, 'INSTALLED'); return; end
            key = 'IDENTITY_UNVERIFIED_INSTALLED';
            switch family
                case 'GPS'
                    C = A.C_GPSA; key = 'GPSA_INSTALLED';
                case 'SBA'
                    if abs(f_Hz - 2.06e9) <= A.FREQ_TOL_HZ
                        C = A.C_SBA_206; key = 'SBA_INSTALLED_2P06';
                    elseif abs(f_Hz - 2.25e9) <= A.FREQ_TOL_HZ
                        C = A.C_SBA_225; key = 'SBA_INSTALLED_2P25';
                    end
            end
        end

        function d = sphericalDirection(theta_deg, phi_deg)
            %SPHERICALDIRECTION Raw CST unit direction(s) (3xN) of (theta, phi) [deg].
            d = [sind(theta_deg(:).') .* cosd(phi_deg(:).'); sind(theta_deg(:).') .* sind(phi_deg(:).'); cosd(theta_deg(:).')];
        end

        function dB = toDisplayedBody(pattern, dRaw)
            dB = rfscreen.cal.CalPlotFrameAdapter.rawToDisplayedBody(pattern) * dRaw;
        end

        function dRaw = toRaw(pattern, dB)
            %TORAW Desired displayed-Body direction(s) -> raw CST query direction(s) (C orthogonal: inverse = C.').
            dRaw = rfscreen.cal.CalPlotFrameAdapter.rawToDisplayedBody(pattern).' * dB;
        end

        function s = peakAlignment(pattern, n_B)
            %PEAKALIGNMENT Corrected raw-peak direction vs the installation panel normal (diagnostic, no hard fail).
            A = rfscreen.cal.CalPlotFrameAdapter;
            nat = pattern.native;
            [C, key] = A.rawToDisplayedBody(pattern);
            dRaw = A.sphericalDirection(nat.peakTheta_deg, nat.peakPhi_deg);
            dB = C * dRaw;
            n = n_B(:) / norm(n_B);
            a = dot(dB, n);
            s = struct('installation', pattern.installationId, 'frequency_ghz', pattern.cstFrequency_Hz / 1e9, ...
                'source_file', pattern.sourceFile, 'correction', key, 'C_diag', sprintf('%+d %+d %+d', round(diag(C))), ...
                'peak_gain_dbi', nat.peakGain_dBi, 'raw_peak_theta_deg', nat.peakTheta_deg, 'raw_peak_phi_deg', nat.peakPhi_deg, ...
                'raw_peak_x', dRaw(1), 'raw_peak_y', dRaw(2), 'raw_peak_z', dRaw(3), ...
                'body_peak_x', dB(1), 'body_peak_y', dB(2), 'body_peak_z', dB(3), ...
                'normal_x', n(1), 'normal_y', n(2), 'normal_z', n(3), ...
                'alignment_dot', a, 'angle_error_deg', acosd(max(-1, min(1, a))), 'warning', '');
            if s.angle_error_deg >= A.WARN_ANGLE_DEG
                s.warning = sprintf(['STRONG WARNING: corrected peak is %.1f deg from the panel normal (opposite ' ...
                    'hemisphere) - check the raw-to-body correction'], s.angle_error_deg);
            end
        end

        function L = alignmentLines(s)
            v = @(x, y, z) sprintf('[%+.3f %+.3f %+.3f]', x, y, z);
            L = {sprintf('[CAL] installed peak alignment: %s @ %.6g GHz (%s, C = diag(%s))', s.installation, ...
                s.frequency_ghz, s.correction, s.C_diag)};
            L{end+1} = sprintf('      raw peak       : %s (theta %.4g, phi %.4g deg, %.2f dBi)', v(s.raw_peak_x, s.raw_peak_y, ...
                s.raw_peak_z), s.raw_peak_theta_deg, s.raw_peak_phi_deg, s.peak_gain_dbi);
            L{end+1} = sprintf('      corrected peak : %s', v(s.body_peak_x, s.body_peak_y, s.body_peak_z));
            L{end+1} = sprintf('      expected normal: %s', v(s.normal_x, s.normal_y, s.normal_z));
            L{end+1} = sprintf('      alignment %.4f, angle error %.2f deg', s.alignment_dot, s.angle_error_deg);
            if ~isempty(s.warning); L{end+1} = ['      ' s.warning]; end
        end
    end
end
