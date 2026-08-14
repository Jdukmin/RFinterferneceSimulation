classdef IntermodulationCriterion
    %INTERMODULATIONCRITERION IM3 acceptance (ICD receiver_nonlinear.md 6, Task 28).
    %   MAX_IM3_INPUT_POWER: allowable effective IM3 product power (input-referred dBm).
    %   Margin_dB = maxDbm - effectiveProductPower ; >=0 PASS (sign per Phase 3).
    properties (SetAccess = private)
        type            % 'MAX_IM3_INPUT_POWER'
        thresholdValue  % dBm
        provenance
    end
    methods
        function obj = IntermodulationCriterion(type, thresholdValue, opts)
            if nargin < 3 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            obj.type = V.member(type, {'MAX_IM3_INPUT_POWER'}, 'type');
            obj.thresholdValue = V.finiteScalar(thresholdValue, 'thresholdValue');
            if isfield(opts, 'provenance') && ~isempty(opts.provenance)
                obj.provenance = opts.provenance;
            else
                obj.provenance = 'SYNTHETIC_TEST';
            end
        end

        function r = evaluate(obj, effectiveProductPower_dBm)
            r = struct('type', obj.type, 'thresholdValue', obj.thresholdValue, ...
                       'margin_dB', NaN, 'pass', 'UNKNOWN');
            if isfinite(effectiveProductPower_dBm)
                r.margin_dB = obj.thresholdValue - effectiveProductPower_dBm;
                if r.margin_dB >= 0; r.pass = 'PASS'; else; r.pass = 'FAIL'; end
            end
        end
    end
end
