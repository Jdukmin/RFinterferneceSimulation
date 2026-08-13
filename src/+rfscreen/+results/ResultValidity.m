classdef ResultValidity
    %RESULTVALIDITY Validity/qualification of a PairResult (SR-093, Task 40).
    properties (Constant)
        VALID_PATTERN_SCREENING      = 'VALID_PATTERN_SCREENING'
        APPROXIMATE                  = 'APPROXIMATE'
        OUTSIDE_PATTERN_DOMAIN       = 'OUTSIDE_PATTERN_DOMAIN'
        FAR_FIELD_NOT_VERIFIED       = 'FAR_FIELD_NOT_VERIFIED'
        MISSING_RECEIVER_DATA        = 'MISSING_RECEIVER_DATA'
        REQUIRES_FULL_WAVE_VERIFICATION = 'REQUIRES_FULL_WAVE_VERIFICATION'
    end
    methods (Static)
        function v = values()
            v = {'VALID_PATTERN_SCREENING', 'APPROXIMATE', 'OUTSIDE_PATTERN_DOMAIN', ...
                 'FAR_FIELD_NOT_VERIFIED', 'MISSING_RECEIVER_DATA', ...
                 'REQUIRES_FULL_WAVE_VERIFICATION'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.results.ResultValidity.values()));
        end
    end
end
