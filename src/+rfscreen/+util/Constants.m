classdef Constants
    %CONSTANTS Physical constants used by the RF screening engine.
    %   Values are SI. See docs/icd/README.md for canonical units.
    methods (Static)
        function c = speedOfLight_mps()
            %SPEEDOFLIGHT_MPS Speed of light in vacuum [m/s].
            c = 299792458.0;
        end
    end
end
