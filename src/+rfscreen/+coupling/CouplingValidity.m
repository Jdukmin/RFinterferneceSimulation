classdef CouplingValidity
    %COUPLINGVALIDITY Near/far-field & source validity of a coupling result (SR-082).
    properties (Constant)
        PATTERN_ONLY                 = 'PATTERN_ONLY'
        FAR_FIELD_VALID              = 'FAR_FIELD_VALID'
        FAR_FIELD_INVALID_OR_UNKNOWN = 'FAR_FIELD_INVALID_OR_UNKNOWN'
        MEASURED_COUPLING            = 'MEASURED_COUPLING'
        FULL_WAVE_COUPLING           = 'FULL_WAVE_COUPLING'
        S21_UNAVAILABLE              = 'S21_UNAVAILABLE'   % no tabulated S21 for the pair/frequency (Phase 7)
    end
    methods (Static)
        function v = values()
            v = {'PATTERN_ONLY', 'FAR_FIELD_VALID', 'FAR_FIELD_INVALID_OR_UNKNOWN', ...
                 'MEASURED_COUPLING', 'FULL_WAVE_COUPLING', 'S21_UNAVAILABLE'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.coupling.CouplingValidity.values()));
        end
    end
end
