classdef Polarization
    %POLARIZATION Antenna polarization enumeration (portable enum).
    properties (Constant)
        LINEAR_H = 'LINEAR_H'
        LINEAR_V = 'LINEAR_V'
        RHCP     = 'RHCP'
        LHCP     = 'LHCP'
        DUAL     = 'DUAL'
        UNKNOWN  = 'UNKNOWN'
    end
    methods (Static)
        function v = values()
            v = {'LINEAR_H', 'LINEAR_V', 'RHCP', 'LHCP', 'DUAL', 'UNKNOWN'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.antenna.Polarization.values()));
        end
    end
end
