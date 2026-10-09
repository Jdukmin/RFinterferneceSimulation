classdef CstNativeSupport
    %CSTNATIVESUPPORT Shared evaluation logic of the native-3D CST pattern classes.
    %   The raw CST (theta, phi) grid is always queried in its own SOURCE frame (CstSphericalPatternData);
    %   the pattern class decides how a query direction reaches that frame:
    %     FREE_SPACE (source frame CST_LOCAL):
    %       antenna-frame u_A -> v_L = M_AL.' u_A (rfscreen.kaa.CstLocalFrameAdapter) -> raw (theta, phi)
    %     INSTALLED (source frame SPACECRAFT_BODY_FIXED):
    %       body d_B -> raw (theta, phi) directly (no R_BL / R_BA / M_AL rotation);
    %       antenna-frame u_A (RFI engine contract) -> d_B = R_BA u_A -> raw;
    %       antenna-local d_L (local cuts only)     -> d_B = R_BL d_L -> raw.
    %   The PatternGrid passed to the AntennaPattern base is an antenna-frame az/el resampling at the
    %   native angular step, kept only for consumers that read obj.grid directly; evaluate() never uses it.
    properties (Constant)
        FREQ_TOL_HZ = 1e3    % a CST plane answers only at its own canonical frequency
        FRAME_CST_LOCAL = 'CST_LOCAL'
        FRAME_BODY = 'SPACECRAFT_BODY_FIXED'
    end
    methods (Static)
        function grid = antennaGrid(native, f_Hz, gainA)
            %ANTENNAGRID az/el resampling; gainA(u_A) = frame-specific antenna-frame query (default free-space).
            if nargin < 3; gainA = @(u) rfscreen.cal.CstNativeSupport.gainAntenna(native, u); end
            step = min(native.thetaStep_deg, native.phiStep_deg);
            az = -180:step:180; el = -90:step:90;
            if az(end) < 180; az(end+1) = 180; end
            if el(end) < 90; el(end+1) = 90; end
            [A, E] = meshgrid(az, el);
            G = reshape(gainA(rfscreen.cal.CstNativeSupport.azElToU(A(:).', E(:).')), numel(el), numel(az));
            grid = rfscreen.antenna.PatternGrid(az, el, f_Hz, G);
        end

        function u_A = azElToU(az_deg, el_deg)
            u_A = [cosd(el_deg(:).') .* cosd(az_deg(:).'); cosd(el_deg(:).') .* sind(az_deg(:).'); sind(el_deg(:).')];
        end

        function g = gainAzEl(native, az_deg, el_deg)
            %GAINAZEL Free-space (CST_LOCAL) query from antenna-frame az/el.
            g = rfscreen.cal.CstNativeSupport.gainAntenna(native, rfscreen.cal.CstNativeSupport.azElToU(az_deg, el_deg));
            g = reshape(g, size(az_deg));
        end

        function g = gainAntenna(native, u_A)
            %GAINANTENNA Free-space (CST_LOCAL) Realized Gain toward antenna-frame direction(s) u_A (3xN).
            v_L = rfscreen.kaa.CstLocalFrameAdapter.localToAntenna().' * u_A;
            g = native.gainAtLocal(v_L);
        end

        function checkFrequency(name, fPlane_Hz, f_Hz)
            if ~(isscalar(f_Hz) && isfinite(f_Hz)) || abs(f_Hz - fPlane_Hz) > rfscreen.cal.CstNativeSupport.FREQ_TOL_HZ
                error('rfscreen:cal:wrongFrequencyPlane', ['%s is the %.6g GHz CST plane; requested %.6g GHz. ' ...
                    'A pattern of another frequency is never re-used (victim-band rule).'], name, fPlane_Hz / 1e9, f_Hz / 1e9);
            end
        end

        function info = evalInfo()
            info = struct('inDomain', true, 'clampedEl', false, 'wrappedAz', false, ...
                'freqHandling', 'cst-native-plane', 'warnings', {{}});
        end

        function v = metaField(meta, name, default)
            if isfield(meta, name) && ~isempty(meta.(name)); v = meta.(name); else; v = default; end
        end
    end
end
