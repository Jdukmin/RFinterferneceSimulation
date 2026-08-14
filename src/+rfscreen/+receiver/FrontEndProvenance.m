classdef FrontEndProvenance
    %FRONTENDPROVENANCE Provenance of receiver nonlinear hardware data (DR-301, Task 29).
    properties (Constant)
        DATASHEET      = 'DATASHEET'
        MEASURED       = 'MEASURED'
        SIMULATED      = 'SIMULATED'
        USER_INPUT     = 'USER_INPUT'
        SYNTHETIC_TEST = 'SYNTHETIC_TEST'
    end
    methods (Static)
        function v = values()
            v = {'DATASHEET', 'MEASURED', 'SIMULATED', 'USER_INPUT', 'SYNTHETIC_TEST'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.receiver.FrontEndProvenance.values()));
        end
    end
end
