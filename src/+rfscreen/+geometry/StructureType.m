classdef StructureType
    %STRUCTURETYPE Spacecraft structure classification (DR-401, Task 7).
    %   Metadata only; algorithms do not depend strongly on these values.
    properties (Constant)
        BUS          = 'BUS'
        PANEL        = 'PANEL'
        SOLAR_ARRAY  = 'SOLAR_ARRAY'
        PAYLOAD      = 'PAYLOAD'
        BOOM         = 'BOOM'
        REFLECTOR    = 'REFLECTOR'
        ANTENNA_BODY = 'ANTENNA_BODY'
        OTHER        = 'OTHER'
    end
    methods (Static)
        function v = values()
            v = {'BUS','PANEL','SOLAR_ARRAY','PAYLOAD','BOOM','REFLECTOR','ANTENNA_BODY','OTHER'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.geometry.StructureType.values()));
        end
    end
end
