classdef NonlinearSusceptibilityResult
    %NONLINEARSUSCEPTIBILITYRESULT Aggregate receiver nonlinear result (ICD 9).
    %   Separate from Phase-3 linear results (Task 38).
    properties
        rxId = ''
        referencePlane = ''
        interfererIds = {}
        compression = []        % results.CompressionResult
        blocking = []           % results.BlockingResult
        im3 = {}                % cell of results.IntermodulationProduct
        im2 = 'NOT_IMPLEMENTED' % IM2 taxonomy documented, not implemented (Task 23)
        validity = ''
        warnings = {}
    end
    methods
        function obj = NonlinearSusceptibilityResult(s)
            if nargin >= 1 && ~isempty(s) && isstruct(s)
                f = fieldnames(s);
                for i = 1:numel(f)
                    if isprop(obj, f{i}); obj.(f{i}) = s.(f{i}); end
                end
            end
        end
        function list = im3ByType(obj, productType)
            list = {};
            for i = 1:numel(obj.im3)
                if strcmp(obj.im3{i}.productType, productType)
                    list{end+1} = obj.im3{i}; %#ok<AGROW>
                end
            end
        end
    end
end
