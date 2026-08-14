classdef DeploymentState
    %DEPLOYMENTSTATE Deterministic deployment state selector (DR-401, Task 30).
    %   Selects a geometry state; no motion profile is modeled.
    properties (Constant)
        STOWED   = 'STOWED'
        DEPLOYED = 'DEPLOYED'
        CUSTOM   = 'CUSTOM'
    end
    methods (Static)
        function v = values()
            v = {'STOWED','DEPLOYED','CUSTOM'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.geometry.DeploymentState.values()));
        end
    end
end
