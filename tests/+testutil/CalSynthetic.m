classdef CalSynthetic
    %CALSYNTHETIC SYNTHETIC_TEST CST-ASCII-like fixtures for the CAL path (never real antenna data).
    %   Files are written only to temporary directories (or tests/fixtures); never to data/cal.
    methods (Static)
        function G = gain(theta, phi, s)
            %GAIN Smooth asymmetric synthetic Realized Gain [dBi]: peak s.peak on boresight, back level
            %   s.back, +X-half tilt s.tiltX (dB) and an optional Gaussian bump (s.bump = [theta0 phi0 dB width]).
            %   Boresight = +Z of the file frame, or s.axis (3-vector in the file frame) when given: an INSTALLED
            %   export is in the spacecraft body frame, so its main lobe points along the panel normal n_B
            %   (tilt then along +X_B orthogonalised to the axis).
            if isfield(s, 'axis') && ~isempty(s.axis)
                a = s.axis(:) / norm(s.axis);
                xp = [1; 0; 0] - a(1) * a;
                if norm(xp) < 1e-9; xp = [0; 0; 1] - a(3) * a; end
                xp = xp / norm(xp);
                v = [sind(theta(:)) .* cosd(phi(:)), sind(theta(:)) .* sind(phi(:)), cosd(theta(:))];
                ca = reshape(max(-1, min(1, v * a)), size(theta));
                G = s.back + (s.peak - s.back) * ((1 + ca) / 2) .^ 2 + s.tiltX * reshape(v * xp, size(theta));
            else
                G = s.back + (s.peak - s.back) * ((1 + cosd(theta)) / 2) .^ 2 + s.tiltX * sind(theta) .* cosd(phi);
            end
            if isfield(s, 'bump') && ~isempty(s.bump)
                b = s.bump;
                v = [sind(theta(:)) .* cosd(phi(:)), sind(theta(:)) .* sind(phi(:)), cosd(theta(:))];
                v0 = [sind(b(1)) * cosd(b(2)), sind(b(1)) * sind(b(2)), cosd(b(1))];
                ang = reshape(acosd(max(-1, min(1, v * v0.'))), size(theta));
                G = G + b(3) * exp(-(ang / b(4)) .^ 2);
            end
        end

        function [T, P, G] = grid(step, s)
            [T, P] = ndgrid(0:step:180, 0:step:(360 - step));
            G = testutil.CalSynthetic.gain(T, P, s);
        end

        function write(path, T, P, G, style)
            %WRITE CST-like ASCII; style: 'cst' (header + separator, spaces), 'tabs', 'noheader', 'broken', 'shuffled'.
            if nargin < 5; style = 'cst'; end
            d = fileparts(path); if exist(d, 'dir') ~= 7; mkdir(d); end
            M = [T(:) P(:) G(:) abs(G(:)) mod(T(:) + P(:), 360) abs(G(:)) / 2 mod(P(:), 360) 3 + 0 * T(:)];
            if strcmp(style, 'shuffled')
                [~, idx] = sort(mod((1:size(M, 1)) * 0.6180339887, 1));   % deterministic, RNG-free shuffle
                M = M(idx, :);
            end
            fid = fopen(path, 'w');
            switch style
                case 'noheader'
                case 'broken'
                    fprintf(fid, 'Thet\n');                     % truncated header, no separator
                otherwise
                    fprintf(fid, 'SYNTHETIC_TEST Theta [deg.]  Phi   [deg.]  Abs(Realized Gain)[dBi   ]  Abs(Theta)  Phase(Theta)  Abs(Phi)  Phase(Phi)  Ax.Ratio[dB]\n');
                    fprintf(fid, '------------------------------------------------------------------------------------------------------\n');
            end
            if strcmp(style, 'tabs')
                fmt = '%g\t%g\t\t%.6f\t%.4e\t%.3f\t%.4e\t%.3f\t%.3f\r\n';
            else
                fmt = '  %8.3f   %8.3f    %12.6f    %.4e   %8.3f  %.4e   %8.3f   %8.3f\n';
            end
            fprintf(fid, fmt, M.');
            fclose(fid);
        end

        function files = buildTree(root, step, skip)
            %BUILDTREE Full owner-named data/cal-like tree of SYNTHETIC_TEST files. skip: cellstr of stems to omit.
            if nargin < 3; skip = {}; end
            C = testutil.CalSynthetic;
            spec = C.spec();
            files = {};
            for i = 1:size(spec, 1)
                stem = spec{i, 2};
                if any(strcmp(skip, stem)); continue; end
                [T, P, G] = C.grid(step, spec{i, 3});
                f = fullfile(root, spec{i, 1}, [stem '.txt']);
                C.write(f, T, P, G, 'cst');
                files{end+1} = f; %#ok<AGROW>
            end
        end

        function S = spec()
            %SPEC folder, stem, synthetic parameters (each file distinct so bindings are testable).
            fx = {'1.1764', '1.2276', '1.5754', '2.25', '8.9', '9.65', '10.4', '10.6'};
            % Installed files are raw CST exports whose main lobe, after the per-dataset raw -> displayed-Body table
            % matrix (cal_installed_frame_corrections.csv, d_B = C d_raw), lies along the SSOT panel normal: raw axis = C.' n_B.
            A = rfscreen.cal.CalPlotFrameAdapter; T = A.loadTable();
            n3 = [0 -0.866025404 -0.5]; n6 = [0 0.866025404 0.5]; n4 = [0 0 -1];
            ax = @(id, stem, f, n) (A.lookup(T, id, stem, f).C.' * n.').';
            r3a = ax('GPSA_1', 'GPSA_GPSA1_f1.2', 1.2, n3); r3b = ax('GPSA_2', 'GPSA_GPSA2_f1.2', 1.2, n3);
            r6a = ax('SBA_NADIR', 'RFC_SBA_NADIR_f2.06', 2.06, n6); r6b = ax('SBA_NADIR', 'RFC_SBA_NADIR_f2.25', 2.25, n6);
            r4a = ax('SBA_ZENITH', 'RFC_SBA_ZENITH_f2.06', 2.06, n4); r4b = ax('SBA_ZENITH', 'RFC_SBA_ZENITH_f2.25', 2.25, n4);
            S = {'gps', 'GPSA_ORIGINAL_f1.2', struct('peak', 4, 'back', -20, 'tiltX', 0); ...
                 'gps', 'GPSA_GPSA1_f1.2', struct('peak', 5, 'back', -25, 'tiltX', 2, 'axis', r3a); ...
                 'gps', 'GPSA_GPSA2_f1.2', struct('peak', 6, 'back', -22, 'tiltX', -2, 'axis', r3b)};
            for k = 1:numel(fx)
                v = str2double(fx{k});
                S(end+1, :) = {'isl', ['RFC_ISL_f' fx{k}], struct('peak', 8 + v / 2, 'back', -30, 'tiltX', 1)}; %#ok<AGROW>
                S(end+1, :) = {'kaa', ['RFC_KAA_f' fx{k}], struct('peak', 10 + v, 'back', -35, 'tiltX', 3)}; %#ok<AGROW>
            end
            fs = {'1.1764', '1.2276', '1.5754', '2.06', '2.25', '8.9', '9.65', '10.4', '10.6'};
            for k = 1:numel(fs)
                S(end+1, :) = {'sba', ['RFC_SBA_f' fs{k}], struct('peak', 3 + str2double(fs{k}) / 10, 'back', -18, 'tiltX', 0.5)}; %#ok<AGROW>
            end
            S(end+1, :) = {'sba', 'RFC_SBA_NADIR_f2.06', struct('peak', 4.1, 'back', -15, 'tiltX', 1.5, 'axis', r6a)};
            S(end+1, :) = {'sba', 'RFC_SBA_NADIR_f2.25', struct('peak', 4.2, 'back', -16, 'tiltX', 1.5, 'axis', r6b)};
            S(end+1, :) = {'sba', 'RFC_SBA_ZENITH_f2.06', struct('peak', 4.3, 'back', -17, 'tiltX', -1.5, 'axis', r4a)};
            S(end+1, :) = {'sba', 'RFC_SBA_ZENITH_f2.25', struct('peak', 4.4, 'back', -19, 'tiltX', -1.5, 'axis', r4b)};
        end
    end
end
