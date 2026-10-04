classdef WaveguideCutoff
    %WAVEGUIDECUTOFF Rectangular-waveguide TE10 below-cutoff (evanescent) attenuation bound.
    %   fc = c / (2 a)                                                    TE10 cutoff [Hz]
    %   alpha = (2 pi fc / c) * sqrt(1 - (f / fc)^2)   [Np/m],  f < fc     evanescent decay
    %   A(f, L) = 20 log10(e) * alpha * L = 8.686 alpha L                [dB]
    %   Provenance WAVEGUIDE_BELOW_CUTOFF_BOUND; ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED: an ideal
    %   uniform guide only (no flange/transition/discontinuity leakage, no higher-order or coaxial-like
    %   modes, no radiation launched downstream of the guide). Never labelled a filter attenuation.
    properties (Constant)
        C0 = 299792458
        NP_TO_DB = 20 / log(10)
        PROVENANCE = 'WAVEGUIDE_BELOW_CUTOFF_BOUND'
        TAGS = 'ENGINEERING_BOUND;NOT_FULL_WAVE_VALIDATED'
    end
    methods (Static)
        function fc = cutoffTE10(a_m)
            fc = rfscreen.psd.WaveguideCutoff.C0 ./ (2 * a_m);
        end

        function a = alphaDbPerM(f_Hz, a_m)
            %ALPHADBPERM Below-cutoff attenuation constant [dB/m]; 0 at or above cutoff (propagating).
            W = rfscreen.psd.WaveguideCutoff; fc = W.cutoffTE10(a_m);
            r = f_Hz ./ fc;
            a = W.NP_TO_DB * (2 * pi * fc / W.C0) .* sqrt(max(0, 1 - r .^ 2));
        end

        function A = totalDb(f_Hz, a_m, L_m)
            if any(L_m(:) < 0); error('rfscreen:psd:negativeLength', 'waveguide length must be >= 0.'); end
            A = rfscreen.psd.WaveguideCutoff.alphaDbPerM(f_Hz, a_m) .* L_m;
        end

        function L = lengthForDb(f_Hz, a_m, A_dB)
            %LENGTHFORDB Effective below-cutoff length [m] that provides A_dB (Inf at/above cutoff).
            al = rfscreen.psd.WaveguideCutoff.alphaDbPerM(f_Hz, a_m);
            L = max(0, A_dB) ./ al; L(al <= 0 & A_dB > 0) = Inf;
        end
    end
end
