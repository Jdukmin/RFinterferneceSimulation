classdef Role
    %ROLE Antenna RF role enumeration (portable enum via Constant char values).
    properties (Constant)
        TX   = 'TX'
        RX   = 'RX'
        TXRX = 'TXRX'
    end
    methods (Static)
        function v = values()
            v = {'TX', 'RX', 'TXRX'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.antenna.Role.values()));
        end
        function tf = canTransmit(x)
            tf = any(strcmp(x, {'TX', 'TXRX'}));
        end
        function tf = canReceive(x)
            tf = any(strcmp(x, {'RX', 'TXRX'}));
        end
    end
end
