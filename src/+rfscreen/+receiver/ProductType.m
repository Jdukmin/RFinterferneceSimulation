classdef ProductType
    %PRODUCTTYPE Third-order intermodulation product type (DR-305, Task 15).
    properties (Constant)
        TWO_F1_MINUS_F2 = '2F1_MINUS_F2'   % 2*f1 - f2
        TWO_F2_MINUS_F1 = '2F2_MINUS_F1'   % 2*f2 - f1
    end
    methods (Static)
        function v = values()
            v = {'2F1_MINUS_F2', '2F2_MINUS_F1'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.receiver.ProductType.values()));
        end
    end
end
