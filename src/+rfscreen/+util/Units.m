classdef Units
    %UNITS Centralized unit conversions (DR-002).
    %   All ad-hoc inline conversions are disallowed elsewhere; use these.
    %   Canonical units: position m, frequency Hz, power dBm, gain dBi,
    %   loss dB, public angles deg. See docs/icd/README.md.
    methods (Static)
        function w = dbm2w(dBm)
            %DBM2W Convert dBm to watts.
            w = 10.0 .^ ((dBm - 30.0) / 10.0);
        end

        function dBm = w2dbm(w)
            %W2DBM Convert watts to dBm.
            dBm = 10.0 * log10(w) + 30.0;
        end

        function lin = db2lin(dB)
            %DB2LIN Convert a dB power ratio to linear.
            lin = 10.0 .^ (dB / 10.0);
        end

        function dB = lin2db(lin)
            %LIN2DB Convert a linear power ratio to dB.
            dB = 10.0 * log10(lin);
        end

        function lambda_m = wavelength_m(frequency_Hz)
            %WAVELENGTH_M Wavelength [m] for a frequency [Hz].
            lambda_m = rfscreen.util.Constants.speedOfLight_mps() ./ frequency_Hz;
        end
    end
end
