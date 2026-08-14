classdef SusceptibilityValidity
    %SUSCEPTIBILITYVALIDITY Validity of a receiver-susceptibility result (AR-212).
    properties (Constant)
        VALID_ABSOLUTE                = 'VALID_ABSOLUTE'
        RELATIVE_SCREENING_ONLY       = 'RELATIVE_SCREENING_ONLY'
        ABSOLUTE_COUPLING_UNAVAILABLE = 'ABSOLUTE_COUPLING_UNAVAILABLE'
        NOISE_MODEL_INCOMPLETE        = 'NOISE_MODEL_INCOMPLETE'
        MISSING_CRITERION             = 'MISSING_CRITERION'
        MISSING_FILTER                = 'MISSING_FILTER'
        MISSING_SPECTRUM              = 'MISSING_SPECTRUM'
        OUTSIDE_ANALYSIS_BAND         = 'OUTSIDE_ANALYSIS_BAND'
        FAR_FIELD_NOT_VERIFIED        = 'FAR_FIELD_NOT_VERIFIED'
    end
    methods (Static)
        function v = values()
            v = {'VALID_ABSOLUTE', 'RELATIVE_SCREENING_ONLY', 'ABSOLUTE_COUPLING_UNAVAILABLE', ...
                 'NOISE_MODEL_INCOMPLETE', 'MISSING_CRITERION', 'MISSING_FILTER', ...
                 'MISSING_SPECTRUM', 'OUTSIDE_ANALYSIS_BAND', 'FAR_FIELD_NOT_VERIFIED'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.receiver.SusceptibilityValidity.values()));
        end
    end
end
