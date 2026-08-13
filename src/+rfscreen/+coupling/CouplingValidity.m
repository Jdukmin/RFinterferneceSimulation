classdef CouplingValidity
    %COUPLINGVALIDITY Near/far-field & source validity of a coupling result (SR-082).
    properties (Constant)
        PATTERN_ONLY                 = 'PATTERN_ONLY'
        FAR_FIELD_VALID              = 'FAR_FIELD_VALID'
        FAR_FIELD_INVALID_OR_UNKNOWN = 'FAR_FIELD_INVALID_OR_UNKNOWN'
        MEASURED_COUPLING            = 'MEASURED_COUPLING'
        FULL_WAVE_COUPLING           = 'FULL_WAVE_COUPLING'
    end
    methods (Static)
        function v = values()
            v = {'PATTERN_ONLY', 'FAR_FIELD_VALID', 'FAR_FIELD_INVALID_OR_UNKNOWN', ...
                 'MEASURED_COUPLING', 'FULL_WAVE_COUPLING'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.coupling.CouplingValidity.values()));
        end
    end
end
