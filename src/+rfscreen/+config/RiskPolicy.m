classdef RiskPolicy
    %RISKPOLICY Configurable screening-risk thresholds (AR-072, ICD scenario.md 3.4).
    %   Risk is a SCREENING indicator over the DirectionalCouplingIndex + frequency
    %   relation; always paired with a ResultValidity (never a verified isolation).
    properties
        indexHigh_dB = 0     % DCI >= indexHigh_dB : strong directional overlap
        indexWarn_dB = -10   % DCI >= indexWarn_dB : moderate
        indexLow_dB  = -20   % below this : OK
    end
    methods
        function obj = RiskPolicy(opts)
            if nargin >= 1 && ~isempty(opts) && isstruct(opts)
                f = fieldnames(opts);
                for i = 1:numel(f)
                    if isprop(obj, f{i})
                        obj.(f{i}) = opts.(f{i});
                    end
                end
            end
            V = rfscreen.util.Validate;
            obj.indexHigh_dB = V.finiteScalar(obj.indexHigh_dB, 'indexHigh_dB');
            obj.indexWarn_dB = V.finiteScalar(obj.indexWarn_dB, 'indexWarn_dB');
            obj.indexLow_dB  = V.finiteScalar(obj.indexLow_dB, 'indexLow_dB');
        end
    end
end
