classdef CouplingResult
    %COUPLINGRESULT Output of a CouplingModel (ICD coupling.md 1).
    %   metric_dB semantics depend on modelType; metricName + isPhysicalCoupling
    %   prevent a screening index from being misread as a physical isolation/S21.
    properties (SetAccess = private)
        modelType           % CouplingModelType char
        validity            % CouplingValidity char
        metric_dB
        metricName
        isPhysicalCoupling  % logical
        warnings            % cellstr
    end
    methods
        function obj = CouplingResult(modelType, validity, metric_dB, metricName, ...
                                      isPhysicalCoupling, warnings)
            if nargin < 6 || isempty(warnings); warnings = {}; end
            V = rfscreen.util.Validate;
            obj.modelType = V.member(modelType, ...
                rfscreen.coupling.CouplingModelType.values(), 'modelType');
            obj.validity = V.member(validity, ...
                rfscreen.coupling.CouplingValidity.values(), 'validity');
            obj.metric_dB = double(metric_dB);
            obj.metricName = V.id(metricName, 'metricName');
            obj.isPhysicalCoupling = logical(isPhysicalCoupling);
            obj.warnings = warnings;
        end
    end
end
