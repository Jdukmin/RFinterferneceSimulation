classdef GeometryProvenance
    %GEOMETRYPROVENANCE Provenance of spacecraft structure geometry (DR-401, Task 31).
    properties (Constant)
        USER_DEFINED   = 'USER_DEFINED'
        CAD_DERIVED    = 'CAD_DERIVED'
        MEASURED       = 'MEASURED'
        MISSION_CONFIG = 'MISSION_CONFIG'
        SYNTHETIC_TEST = 'SYNTHETIC_TEST'
        % --- reference-case provenance (Phase 6) -------------------------------
        % Kept consistent with data/reference_cases/README.md so a geometry taken
        % from (or assumed for) a published case can declare that fact in code.
        PUBLIC_REPORTED        = 'PUBLIC_REPORTED'         % stated in a public paper
        PUBLIC_DIGITIZED       = 'PUBLIC_DIGITIZED'        % read off a published figure
        ASSUMED_FOR_REPLICATION = 'ASSUMED_FOR_REPLICATION' % representative, NOT the paper's value
    end
    methods (Static)
        function v = values()
            v = {'USER_DEFINED','CAD_DERIVED','MEASURED','MISSION_CONFIG','SYNTHETIC_TEST', ...
                 'PUBLIC_REPORTED','PUBLIC_DIGITIZED','ASSUMED_FOR_REPLICATION'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.geometry.GeometryProvenance.values()));
        end
    end
end
