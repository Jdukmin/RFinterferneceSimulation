classdef FilterProvenance
    %FILTERPROVENANCE Provenance of a receiver filter (DR-202, Task 28).
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
            tf = ischar(x) && any(strcmp(x, rfscreen.receiver.FilterProvenance.values()));
        end
    end
end
