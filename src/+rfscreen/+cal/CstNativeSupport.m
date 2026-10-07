classdef CstNativeSupport
    %CSTNATIVESUPPORT Shared evaluation logic of the native-3D CST pattern classes.
    %   Query chain (single path for RFI gains and every plot):
    %     antenna-frame (az, el) -> u_A (ICD 2.1) -> v_L = M_AL.' u_A (rfscreen.kaa.CstLocalFrameAdapter)
    %     -> CST (theta, phi) -> bilinear interpolation on the native CST grid.
    %   The PatternGrid passed to the AntennaPattern base is an az/el resampling at the native angular
    %   step, kept only for consumers that read obj.grid directly; evaluate() never uses it.
    properties (Constant)
        FREQ_TOL_HZ = 1e3    % a CST plane answers only at its own canonical frequency
    end
    methods (Static)
        function grid = antennaGrid(native, f_Hz)
            step = min(native.thetaStep_deg, native.phiStep_deg);
            az = -180:step:180; el = -90:step:90;
            if az(end) < 180; az(end+1) = 180; end
            if el(end) < 90; el(end+1) = 90; end
            [A, E] = meshgrid(az, el);
            G = reshape(rfscreen.cal.CstNativeSupport.gainAzEl(native, A(:).', E(:).'), numel(el), numel(az));
            grid = rfscreen.antenna.PatternGrid(az, el, f_Hz, G);
        end

        function g = gainAzEl(native, az_deg, el_deg)
            u_A = [cosd(el_deg(:).') .* cosd(az_deg(:).'); cosd(el_deg(:).') .* sind(az_deg(:).'); sind(el_deg(:).')];
            g = rfscreen.cal.CstNativeSupport.gainAntenna(native, u_A);
            g = reshape(g, size(az_deg));
        end

        function g = gainAntenna(native, u_A)
            %GAINANTENNA Realized Gain toward antenna-frame direction(s) u_A (3xN).
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
    end
end
