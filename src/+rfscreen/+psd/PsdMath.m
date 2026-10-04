classdef PsdMath
    %PSDMATH Units and arithmetic of the victim-band unwanted-emission (PSD) path.
    %   Level types are kept apart (no implicit conversion between them):
    %     PSD            dBm/Hz   (broadband noise / spectral mask; carrier-relative form dBc/Hz)
    %     POWER          dBm      (discrete spur / harmonic in a stated RBW, blocker, integrated I)
    %     ATTENUATION    dB       (TX filter / diplexer / cable loss, receiver rejection)
    %     COUPLING       dB       (C_EM = G_tx + G_rx - FSPL, or S21)
    %   Thermal reference: kT0 = -174 dBm/Hz (290 K engineering convention; exact value -173.98).
    properties (Constant)
        KT0_DBM_HZ = -174
        C0 = 299792458
    end
    methods (Static)
        function n = noisePsd(nf_dB)
            n = rfscreen.psd.PsdMath.KT0_DBM_HZ + nf_dB;
        end

        function a = allowablePsd(nf_dB, iN_dB)
            %ALLOWABLEPSD Allowable interference PSD = kT0 + NF + (I/N)max [dBm/Hz].
            a = rfscreen.psd.PsdMath.noisePsd(nf_dB) + iN_dB;
        end

        function p = dbcHzToDbmHz(level_dBcHz, carrier_dBm)
            %DBCHZTODBMHZ Carrier-relative mask [dBc/Hz] + carrier [dBm] -> PSD [dBm/Hz].
            p = carrier_dBm + level_dBcHz;
        end

        function p = applyAttenuation(level, atten_dB)
            %APPLYATTENUATION Filter/cable attenuation [dB] lowers a PSD or a power by atten_dB.
            if any(atten_dB(:) < 0)
                error('rfscreen:psd:negativeAttenuation', 'attenuation must be >= 0 dB (got %g).', min(atten_dB(:)));
            end
            p = level - atten_dB;
        end

        function p = victimPortPsd(txPsd_dBmHz, chainLoss_dB, coupling_dB)
            %VICTIMPORTPSD PSD_victim_port = PSD_TX - L_TXchain + C_EM   [dBm/Hz].
            p = rfscreen.psd.PsdMath.applyAttenuation(txPsd_dBmHz, chainLoss_dB) + coupling_dB;
        end

        function m = margin(allowable_dBmHz, portPsd_dBmHz)
            %MARGIN PSD margin = allowable - victim-port PSD [dB] (>= 0 compliant).
            m = allowable_dBmHz - portPsd_dBmHz;
        end

        function s = requiredSuppression(portPsd_dBmHz, allowable_dBmHz)
            %REQUIREDSUPPRESSION In-band PSD suppression needed = PSD_victim_port - PSD_allowable [dB].
            s = portPsd_dBmHz - allowable_dBmHz;
        end

        function st = maskStatus(m)
            st = repmat({'PASS'}, size(m)); st(m < 0) = {'FAIL'}; st(isnan(m)) = {'NOT_EVALUATED'};
        end

        function I = integrate(f_Hz, psd_dBmHz, H2_dB)
            %INTEGRATE Second-stage receiver interference I = int PSD(f) |H(f)|^2 df  [dBm]
            %   (trapezoid in linear mW/Hz over the given receiver-channel samples).
            if nargin < 3 || isempty(H2_dB); H2_dB = zeros(size(f_Hz)); end
            if numel(f_Hz) < 2; error('rfscreen:psd:integration', 'need >= 2 frequency samples.'); end
            I = 10 * log10(trapz(f_Hz, 10 .^ ((psd_dBmHz + H2_dB) / 10)));
        end

        function L = fspl(f_Hz, d_m)
            L = 20 * log10(4 * pi * d_m .* f_Hz / rfscreen.psd.PsdMath.C0);
        end
    end
end
