classdef PatternGrid
    %PATTERNGRID Tabulated gain grid + interpolation (AR-020..AR-025, ICD antenna.md 3.4).
    %   Storage: az_deg (1xnA, monotonic in [-180,180]),
    %            el_deg (1xnE, monotonic in [-90,90]),
    %            frequency_Hz (1xnF, monotonic > 0),
    %            gain_dBi (nE x nA x nF).
    %   Interpolation: bilinear in (az,el); az periodic (wrap); el clamped.
    %   Frequency: 'nearest' | 'linear'; out-of-range per policy.outOfBandFreq.
    %   A single-frequency grid (nF==1) is treated as frequency-independent
    %   (the plane is reused at any frequency, with a warning if the query
    %   differs). Missing gain nodes (NaN) are never interpolated over.
    properties (SetAccess = private)
        az_deg
        el_deg
        frequency_Hz
        gain_dBi
    end

    methods
        function obj = PatternGrid(az_deg, el_deg, frequency_Hz, gain_dBi)
            V = rfscreen.util.Validate;
            obj.az_deg = V.monotonicVector(az_deg, 'az_deg');
            obj.el_deg = V.monotonicVector(el_deg, 'el_deg');
            obj.frequency_Hz = V.monotonicVector(frequency_Hz, 'frequency_Hz');
            if any(obj.frequency_Hz <= 0)
                error('rfscreen:pattern:badFrequency', 'frequency_Hz must be > 0.');
            end
            if obj.az_deg(1) < -180 - 1e-9 || obj.az_deg(end) > 180 + 1e-9
                error('rfscreen:pattern:azRange', 'az_deg must lie within [-180,180].');
            end
            if obj.el_deg(1) < -90 - 1e-9 || obj.el_deg(end) > 90 + 1e-9
                error('rfscreen:pattern:elRange', 'el_deg must lie within [-90,90].');
            end
            nE = numel(obj.el_deg); nA = numel(obj.az_deg); nF = numel(obj.frequency_Hz);
            % NB: size() drops trailing singleton dims, so check per-dimension
            % (size(X,3)==1 for a 2-D array) rather than isequal(size(X),[..]).
            if ~(isnumeric(gain_dBi) && ndims(gain_dBi) <= 3 && ...
                    size(gain_dBi, 1) == nE && size(gain_dBi, 2) == nA && size(gain_dBi, 3) == nF)
                error('rfscreen:pattern:gainShape', ...
                    'gain_dBi must be [nEl(%d) x nAz(%d) x nFreq(%d)].', nE, nA, nF);
            end
            obj.gain_dBi = double(gain_dBi);
        end

        function [gain_dBi, info] = evaluate(obj, frequency_Hz, az_deg, el_deg, policy)
            %EVALUATE Directional gain [dBi] with interpolation + boundary policy.
            if nargin < 5 || isempty(policy)
                policy = rfscreen.config.PatternInterpolationPolicy();
            end
            info = struct('inDomain', true, 'clampedEl', false, 'wrappedAz', false, ...
                          'freqHandling', '', 'warnings', {{}});

            % ---- Azimuth locate (periodic wrap) ----
            [a0, a1, ta, ~, wrappedAz] = rfscreen.antenna.PatternGrid.locateCircular( ...
                obj.az_deg, az_deg, 360, policy.azWrap);
            info.wrappedAz = wrappedAz;

            % ---- Elevation locate (clamp) ----
            [e0, e1, te, clampedEl] = rfscreen.antenna.PatternGrid.locateClamp( ...
                obj.el_deg, el_deg, policy.elClamp);
            info.clampedEl = clampedEl;
            if clampedEl
                info.warnings{end+1} = 'elevation clamped to pattern boundary';
            end

            % ---- Frequency handling ----
            [fIdx, fw, freqInfo] = obj.locateFrequency(frequency_Hz, policy);
            info.freqHandling = freqInfo.mode;
            if ~isempty(freqInfo.warning)
                info.warnings{end+1} = freqInfo.warning;
            end
            if ~freqInfo.inDomain
                info.inDomain = false;
                gain_dBi = NaN;
                info.warnings{end+1} = 'frequency outside pattern domain';
                return;
            end

            % ---- Bilinear over az/el for each contributing frequency plane ----
            planeVals = zeros(1, numel(fIdx));
            for k = 1:numel(fIdx)
                [planeVals(k), ok] = rfscreen.antenna.PatternGrid.bilinear( ...
                    obj.gain_dBi(:, :, fIdx(k)), e0, e1, te, a0, a1, ta);
                if ~ok
                    info.inDomain = false;
                    gain_dBi = NaN;
                    info.warnings{end+1} = 'missing gain data (NaN) in interpolation stencil';
                    return;
                end
            end
            gain_dBi = sum(planeVals(:) .* fw(:));
        end
    end

    methods (Access = private)
        function [fIdx, fw, freqInfo] = locateFrequency(obj, q, policy)
            f = obj.frequency_Hz;
            nF = numel(f);
            freqInfo = struct('mode', '', 'warning', '', 'inDomain', true);
            V = rfscreen.util.Validate;
            q = V.finiteScalar(q, 'frequency_Hz');

            if nF == 1
                fIdx = 1; fw = 1;
                freqInfo.mode = 'single-plane';
                if abs(q - f(1)) > 1e-6 * max(1, f(1))
                    freqInfo.warning = 'single-frequency pattern evaluated at a different frequency (reused)';
                end
                return;
            end

            below = q < f(1) - 1e-6;
            above = q > f(end) + 1e-6;
            if below || above
                switch policy.outOfBandFreq
                    case 'error'
                        error('rfscreen:pattern:freqOutOfRange', ...
                            'frequency %.6g Hz outside pattern range [%.6g, %.6g].', q, f(1), f(end));
                    case 'nearest'
                        if below; fIdx = 1; else; fIdx = nF; end
                        fw = 1; freqInfo.mode = 'nearest-clamped';
                        freqInfo.warning = 'frequency clamped to nearest supported plane';
                        return;
                    otherwise % 'nan'
                        fIdx = 1; fw = 1; freqInfo.inDomain = false; freqInfo.mode = 'nan';
                        return;
                end
            end

            switch policy.freqMethod
                case 'linear'
                    freqInfo.mode = 'linear';
                    k = find(f <= q, 1, 'last');
                    if k >= nF
                        fIdx = nF; fw = 1;
                    elseif abs(f(k) - q) <= eps
                        fIdx = k; fw = 1;
                    else
                        t = (q - f(k)) / (f(k+1) - f(k));
                        fIdx = [k, k+1];
                        fw = [1 - t, t];
                    end
                otherwise % 'nearest'
                    freqInfo.mode = 'nearest';
                    [~, idx] = min(abs(f - q));
                    fIdx = idx; fw = 1;
            end
        end
    end

    methods (Static, Access = private)
        function [i0, i1, t, clamped, wrapped] = locateCircular(grid, q, span, doWrap)
            n = numel(grid);
            clamped = false; wrapped = false;
            if n == 1
                i0 = 1; i1 = 1; t = 0; return;
            end
            if doWrap
                q = grid(1) + mod(q - grid(1), span);
                if q >= grid(n)
                    % seam segment between last node and first node + span
                    i0 = n; i1 = 1;
                    denom = (grid(1) + span) - grid(n);
                    t = (q - grid(n)) / denom;
                    wrapped = true;
                    return;
                end
            else
                [i0, i1, t, clamped] = rfscreen.antenna.PatternGrid.locateClamp(grid, q, true);
                return;
            end
            k = find(grid <= q, 1, 'last');
            if isempty(k); k = 1; end
            if k >= n; k = n - 1; end
            i0 = k; i1 = k + 1;
            t = (q - grid(k)) / (grid(k+1) - grid(k));
        end

        function [i0, i1, t, clamped] = locateClamp(grid, q, doClamp) %#ok<INUSD>
            n = numel(grid);
            clamped = false;
            if n == 1
                i0 = 1; i1 = 1; t = 0; return;
            end
            if q <= grid(1)
                i0 = 1; i1 = 1; t = 0; clamped = (q < grid(1) - 1e-12);
                return;
            end
            if q >= grid(n)
                i0 = n; i1 = n; t = 0; clamped = (q > grid(n) + 1e-12);
                return;
            end
            k = find(grid <= q, 1, 'last');
            i0 = k; i1 = k + 1;
            t = (q - grid(k)) / (grid(k+1) - grid(k));
        end

        function [val, ok] = bilinear(G, e0, e1, te, a0, a1, ta)
            % Corners with weights; a corner contributes only if weight>0.
            w = [ (1-te)*(1-ta), (1-te)*ta, te*(1-ta), te*ta ];
            v = [ G(e0, a0), G(e0, a1), G(e1, a0), G(e1, a1) ];
            used = w > 0;
            if any(used & ~isfinite(v))
                val = NaN; ok = false; return;
            end
            val = sum(w(used) .* v(used));
            ok = true;
        end
    end
end
