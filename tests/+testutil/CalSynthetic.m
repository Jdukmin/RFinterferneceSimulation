classdef CalSynthetic
    %CALSYNTHETIC SYNTHETIC_TEST CST-ASCII-like fixtures for the CAL path (never real antenna data).
    %   Files are written only to temporary directories (or tests/fixtures); never to data/cal.
    methods (Static)
        function G = gain(theta, phi, s)
            %GAIN Smooth asymmetric synthetic Realized Gain [dBi]: peak s.peak on boresight, back level
            %   s.back, +X-half tilt s.tiltX (dB) and an optional Gaussian bump (s.bump = [theta0 phi0 dB width]).
            G = s.back + (s.peak - s.back) * ((1 + cosd(theta)) / 2) .^ 2 + s.tiltX * sind(theta) .* cosd(phi);
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
            S = {'gps', 'GPS_ORIGINAL_f1.2', struct('peak', 4, 'back', -20, 'tiltX', 0); ...
                 'gps', 'GPS_GPSA1_f1.2', struct('peak', 5, 'back', -25, 'tiltX', 2); ...
                 'gps', 'GPS_GPSA2_f1.2', struct('peak', 6, 'back', -22, 'tiltX', -2)};
            for k = 1:numel(fx)
                v = str2double(fx{k});
                S(end+1, :) = {'isl', ['RFC_ISL_f' fx{k}], struct('peak', 8 + v / 2, 'back', -30, 'tiltX', 1)}; %#ok<AGROW>
                S(end+1, :) = {'kaa', ['RFC_KAA_f' fx{k}], struct('peak', 10 + v, 'back', -35, 'tiltX', 3)}; %#ok<AGROW>
            end
            fs = {'1.1764', '1.2276', '1.5754', '2.06', '2.25', '8.9', '9.65', '10.4', '10.6'};
            for k = 1:numel(fs)
                S(end+1, :) = {'sba', ['RFC_SBA_f' fs{k}], struct('peak', 3 + str2double(fs{k}) / 10, 'back', -18, 'tiltX', 0.5)}; %#ok<AGROW>
            end
            S(end+1, :) = {'sba', 'RFC_SBA_NADIR_f2.06', struct('peak', 4.1, 'back', -15, 'tiltX', 1.5)};
            S(end+1, :) = {'sba', 'RFC_SBA_NADIR_f2.25', struct('peak', 4.2, 'back', -16, 'tiltX', 1.5)};
            S(end+1, :) = {'sba', 'RFC_SBA_ZENITH_f2.06', struct('peak', 4.3, 'back', -17, 'tiltX', -1.5)};
            S(end+1, :) = {'sba', 'RFC_SBA_ZENITH_f2.25', struct('peak', 4.4, 'back', -19, 'tiltX', -1.5)};
        end
    end
end
