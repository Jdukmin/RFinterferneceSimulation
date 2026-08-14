classdef InterferenceCriterion
    %INTERFERENCECRITERION Physical receiver acceptance criterion (Task 19, 21).
    %   DISTINCT from screening policies (config.RiskPolicy / FrequencyRelationPolicy).
    %   Sign convention (fixed): Margin_dB = Allowable - Actual ; >0 PASS.
    %   Types: I_N_MAX (thresholdValue in dB), MAX_INTERFERENCE_POWER (dBm).
    properties (SetAccess = private)
        type            % 'I_N_MAX' | 'MAX_INTERFERENCE_POWER'
        thresholdValue  % dB (I/N) or dBm (power)
        provenance
    end
    methods
        function obj = InterferenceCriterion(type, thresholdValue, opts)
            if nargin < 3 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            obj.type = V.member(type, {'I_N_MAX', 'MAX_INTERFERENCE_POWER'}, 'type');
            obj.thresholdValue = V.finiteScalar(thresholdValue, 'thresholdValue');
            if isfield(opts, 'provenance') && ~isempty(opts.provenance)
                obj.provenance = opts.provenance;
            else
                obj.provenance = 'SYNTHETIC_TEST';
            end
        end

        function r = evaluate(obj, interferencePower_dBm, noisePower_dBm)
            %EVALUATE Margin per fixed sign convention (Allowable - Actual).
            if nargin < 3; noisePower_dBm = NaN; end
            r = struct('type', obj.type, 'thresholdValue', obj.thresholdValue, ...
                       'actual', NaN, 'margin_dB', NaN, 'pass', '');
            switch obj.type
                case 'I_N_MAX'
                    if isfinite(interferencePower_dBm) && isfinite(noisePower_dBm)
                        r.actual = interferencePower_dBm - noisePower_dBm;   % I/N [dB]
                    end
                case 'MAX_INTERFERENCE_POWER'
                    if isfinite(interferencePower_dBm)
                        r.actual = interferencePower_dBm;                    % [dBm]
                    end
            end
            if isfinite(r.actual)
                r.margin_dB = obj.thresholdValue - r.actual;    % Allowable - Actual
                if r.margin_dB >= 0; r.pass = 'PASS'; else; r.pass = 'FAIL'; end
            else
                r.pass = 'UNKNOWN';
            end
        end
    end
end
