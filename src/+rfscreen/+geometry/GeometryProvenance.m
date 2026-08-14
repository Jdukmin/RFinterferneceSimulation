classdef GeometryProvenance
    %GEOMETRYPROVENANCE Provenance of spacecraft structure geometry (DR-401, Task 31).
    properties (Constant)
        USER_DEFINED   = 'USER_DEFINED'
        CAD_DERIVED    = 'CAD_DERIVED'
        MEASURED       = 'MEASURED'
        MISSION_CONFIG = 'MISSION_CONFIG'
        SYNTHETIC_TEST = 'SYNTHETIC_TEST'
    end
    methods (Static)
        function v = values()
            v = {'USER_DEFINED','CAD_DERIVED','MEASURED','MISSION_CONFIG','SYNTHETIC_TEST'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.geometry.GeometryProvenance.values()));
        end
    end
end
