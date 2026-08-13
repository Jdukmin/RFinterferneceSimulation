classdef InstalledPatternSource
    %INSTALLEDPATTERNSOURCE Source of an installed antenna pattern (SR-051, DR-032).
    properties (Constant)
        MEASURED     = 'MEASURED'
        HFSS         = 'HFSS'
        CST          = 'CST'
        OTHER_SOLVER = 'OTHER_SOLVER'
        APPROXIMATE  = 'APPROXIMATE'
    end
    methods (Static)
        function v = values()
            v = {'MEASURED', 'HFSS', 'CST', 'OTHER_SOLVER', 'APPROXIMATE'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.antenna.InstalledPatternSource.values()));
        end
    end
end
