classdef LobeClass
    %LOBECLASS Main/side/back lobe classification (metadata only, SR-060).
    properties (Constant)
        MAIN = 'MAIN'
        SIDE = 'SIDE'
        BACK = 'BACK'
    end
    methods (Static)
        function v = values()
            v = {'MAIN', 'SIDE', 'BACK'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.results.LobeClass.values()));
        end
    end
end
