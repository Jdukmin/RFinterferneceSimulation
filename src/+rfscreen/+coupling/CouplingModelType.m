classdef CouplingModelType
    %COUPLINGMODELTYPE Which coupling model produced a result.
    properties (Constant)
        PATTERN_ONLY = 'PATTERN_ONLY'
        FAR_FIELD    = 'FAR_FIELD'
        MEASURED_S21 = 'MEASURED_S21'
        HFSS         = 'HFSS'
        CST          = 'CST'
        OTHER_SOLVER = 'OTHER_SOLVER'
    end
    methods (Static)
        function v = values()
            v = {'PATTERN_ONLY', 'FAR_FIELD', 'MEASURED_S21', 'HFSS', 'CST', 'OTHER_SOLVER'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.coupling.CouplingModelType.values()));
        end
    end
end
