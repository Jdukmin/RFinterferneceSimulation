classdef FrequencyRelationType
    %FREQUENCYRELATIONTYPE Spectral relation between a TX and RX band.
    properties (Constant)
        IN_BAND       = 'IN_BAND'
        ADJACENT_BAND = 'ADJACENT_BAND'
        OUT_OF_BAND   = 'OUT_OF_BAND'
    end
    methods (Static)
        function v = values()
            v = {'IN_BAND', 'ADJACENT_BAND', 'OUT_OF_BAND'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.rf.FrequencyRelationType.values()));
        end
    end
end
