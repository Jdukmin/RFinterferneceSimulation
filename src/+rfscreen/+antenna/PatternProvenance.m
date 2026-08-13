classdef PatternProvenance
    %PATTERNPROVENANCE Pattern data provenance (SR-052, DR-031, DR-040).
    %   SYNTHETIC_TEST marks non-mission test fixtures unmistakably (Task 9, 32).
    properties (Constant)
        MEASURED_3D      = 'MEASURED_3D'
        SIMULATED_3D     = 'SIMULATED_3D'
        APPROX_FROM_CUTS = 'APPROX_FROM_CUTS'
        SYNTHETIC_TEST   = 'SYNTHETIC_TEST'
    end
    methods (Static)
        function v = values()
            v = {'MEASURED_3D', 'SIMULATED_3D', 'APPROX_FROM_CUTS', 'SYNTHETIC_TEST'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.antenna.PatternProvenance.values()));
        end
        function tf = isSyntheticTest(x)
            tf = strcmp(x, rfscreen.antenna.PatternProvenance.SYNTHETIC_TEST);
        end
    end
end
