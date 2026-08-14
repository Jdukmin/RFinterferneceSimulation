classdef ReferencePlane
    %REFERENCEPLANE RF power reference plane (SR-202, ICD receiver_susceptibility.md 1).
    properties (Constant)
        TX_OUTPUT          = 'TX_OUTPUT'
        TX_ANTENNA_INPUT   = 'TX_ANTENNA_INPUT'
        EIRP_REFERENCE     = 'EIRP_REFERENCE'
        RX_ANTENNA_TERMINAL= 'RX_ANTENNA_TERMINAL'
        RECEIVER_RF_INPUT  = 'RECEIVER_RF_INPUT'   % after preselector filter, before LNA
        POST_FILTER        = 'POST_FILTER'
    end
    methods (Static)
        function v = values()
            v = {'TX_OUTPUT', 'TX_ANTENNA_INPUT', 'EIRP_REFERENCE', ...
                 'RX_ANTENNA_TERMINAL', 'RECEIVER_RF_INPUT', 'POST_FILTER'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.receiver.ReferencePlane.values()));
        end
    end
end
