classdef Constants
    %CONSTANTS Physical constants used by the RF screening engine.
    %   Values are SI. See docs/icd/README.md for canonical units.
    methods (Static)
        function c = speedOfLight_mps()
            %SPEEDOFLIGHT_MPS Speed of light in vacuum [m/s].
            c = 299792458.0;
        end

        function k = boltzmann_JperK()
            %BOLTZMANN_JPERK Boltzmann constant [J/K] (DR-210).
            k = 1.380649e-23;
        end

        function t = standardNoiseTemp_K()
            %STANDARDNOISETEMP_K Reference noise temperature T0 = 290 K.
            t = 290.0;
        end
    end
end
