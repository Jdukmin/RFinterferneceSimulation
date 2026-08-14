classdef LineOfSightStatus
    %LINEOFSIGHTSTATUS Geometric line-of-sight status (DR-401, Task 16).
    %   Geometry evidence only; BLOCKED never implies an RF attenuation value.
    properties (Constant)
        CLEAR               = 'CLEAR'
        BLOCKED             = 'BLOCKED'
        PARTIALLY_OCCLUDED  = 'PARTIALLY_OCCLUDED'
        UNKNOWN             = 'UNKNOWN'
    end
    methods (Static)
        function v = values()
            v = {'CLEAR','BLOCKED','PARTIALLY_OCCLUDED','UNKNOWN'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.geometry.LineOfSightStatus.values()));
        end
    end
end
