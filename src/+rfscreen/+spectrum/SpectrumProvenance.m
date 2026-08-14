classdef SpectrumProvenance
    %SPECTRUMPROVENANCE Provenance of a TX spectrum (DR-201, Task 27).
    %   Stored explicitly; test fixtures use SYNTHETIC_TEST. No mission mask is
    %   fabricated (Task 29).
    properties (Constant)
        IDEAL_MODEL    = 'IDEAL_MODEL'
        DATASHEET      = 'DATASHEET'
        MEASURED       = 'MEASURED'
        SIMULATED      = 'SIMULATED'
        SYNTHETIC_TEST = 'SYNTHETIC_TEST'
    end
    methods (Static)
        function v = values()
            v = {'IDEAL_MODEL', 'DATASHEET', 'MEASURED', 'SIMULATED', 'SYNTHETIC_TEST'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.spectrum.SpectrumProvenance.values()));
        end
    end
end
