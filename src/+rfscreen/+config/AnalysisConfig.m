classdef AnalysisConfig
    %ANALYSISCONFIG Aggregate analysis configuration (DR-070, DR-071).
    %   Bundles all policy objects with documented defaults.
    properties
        lobe            % LobeClassificationPolicy
        frequency       % FrequencyRelationPolicy
        interpolation   % PatternInterpolationPolicy
        risk            % RiskPolicy
        couplingModel   % char CouplingModelType selector (default PATTERN_ONLY)
    end
    methods
        function obj = AnalysisConfig(opts)
            if nargin < 1; opts = struct(); end
            obj.lobe          = rfscreen.config.AnalysisConfig.pick(opts, 'lobe', ...
                                    rfscreen.config.LobeClassificationPolicy());
            obj.frequency     = rfscreen.config.AnalysisConfig.pick(opts, 'frequency', ...
                                    rfscreen.config.FrequencyRelationPolicy());
            obj.interpolation = rfscreen.config.AnalysisConfig.pick(opts, 'interpolation', ...
                                    rfscreen.config.PatternInterpolationPolicy());
            obj.risk          = rfscreen.config.AnalysisConfig.pick(opts, 'risk', ...
                                    rfscreen.config.RiskPolicy());
            if isfield(opts, 'couplingModel') && ~isempty(opts.couplingModel)
                obj.couplingModel = opts.couplingModel;
            else
                obj.couplingModel = rfscreen.coupling.CouplingModelType.PATTERN_ONLY;
            end
        end
    end
    methods (Static)
        function obj = default()
            obj = rfscreen.config.AnalysisConfig();
        end
        function v = pick(opts, name, default)
            if isfield(opts, name) && ~isempty(opts.(name))
                v = opts.(name);
            else
                v = default;
            end
        end
    end
end
