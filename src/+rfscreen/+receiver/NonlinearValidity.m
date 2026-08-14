classdef NonlinearValidity
    %NONLINEARVALIDITY Validity of a nonlinear susceptibility result (DR-305, Task 31).
    properties (Constant)
        VALID                         = 'VALID'
        VALID_WITH_WARNINGS           = 'VALID_WITH_WARNINGS'
        ABSOLUTE_COUPLING_UNAVAILABLE = 'ABSOLUTE_COUPLING_UNAVAILABLE'
        MISSING_FRONT_END             = 'MISSING_FRONT_END'
        MISSING_P1DB                  = 'MISSING_P1DB'
        MISSING_IIP3                  = 'MISSING_IIP3'
        MISSING_BLOCKING_CRITERION    = 'MISSING_BLOCKING_CRITERION'
        INCOMPLETE_INTERFERER_SET     = 'INCOMPLETE_INTERFERER_SET'
        NONLINEAR_MODEL_NOT_SUPPORTED = 'NONLINEAR_MODEL_NOT_SUPPORTED'
        OUTSIDE_MODEL_DOMAIN          = 'OUTSIDE_MODEL_DOMAIN'
    end
    methods (Static)
        function v = values()
            v = {'VALID', 'VALID_WITH_WARNINGS', 'ABSOLUTE_COUPLING_UNAVAILABLE', ...
                 'MISSING_FRONT_END', 'MISSING_P1DB', 'MISSING_IIP3', ...
                 'MISSING_BLOCKING_CRITERION', 'INCOMPLETE_INTERFERER_SET', ...
                 'NONLINEAR_MODEL_NOT_SUPPORTED', 'OUTSIDE_MODEL_DOMAIN'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.receiver.NonlinearValidity.values()));
        end
    end
end
