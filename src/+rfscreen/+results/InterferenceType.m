classdef InterferenceType
    %INTERFERENCETYPE Interference taxonomy (SR-090, R9). Phase 1 computes
    %   NONE/IN_BAND/ADJACENT_BAND; BLOCKING_COMPRESSION and
    %   INTERMODULATION_SPURIOUS are reserved (need RFFrontEnd data, AR-041).
    properties (Constant)
        NONE                     = 'NONE'
        IN_BAND                  = 'IN_BAND'
        ADJACENT_BAND            = 'ADJACENT_BAND'
        BLOCKING_COMPRESSION     = 'BLOCKING_COMPRESSION'
        INTERMODULATION_SPURIOUS = 'INTERMODULATION_SPURIOUS'
    end
    methods (Static)
        function v = values()
            v = {'NONE', 'IN_BAND', 'ADJACENT_BAND', ...
                 'BLOCKING_COMPRESSION', 'INTERMODULATION_SPURIOUS'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.results.InterferenceType.values()));
        end
    end
end
