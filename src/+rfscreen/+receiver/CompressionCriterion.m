classdef CompressionCriterion
    %COMPRESSIONCRITERION Compression acceptance (ICD receiver_nonlinear.md 4, Task 28).
    %   requiredBackoff_dB: minimum backoff below P1dB required to PASS.
    %   pass = (p1dB_in - requiredBackoff) - P_agg >= 0. Sign per Phase 3.
    properties (SetAccess = private)
        requiredBackoff_dB
        provenance
    end
    methods
        function obj = CompressionCriterion(requiredBackoff_dB, opts)
            if nargin < 1 || isempty(requiredBackoff_dB); requiredBackoff_dB = 0; end
            if nargin < 2 || isempty(opts); opts = struct(); end
            obj.requiredBackoff_dB = rfscreen.util.Validate.finiteScalar( ...
                requiredBackoff_dB, 'requiredBackoff_dB');
            if isfield(opts, 'provenance') && ~isempty(opts.provenance)
                obj.provenance = opts.provenance;
            else
                obj.provenance = 'SYNTHETIC_TEST';
            end
        end

        function r = evaluate(obj, p1dB_in_dBm, aggregateInputPower_dBm)
            %EVALUATE Margin = (P1dB_in - requiredBackoff) - P_agg ; >=0 PASS.
            r = struct('allowable_dBm', NaN, 'margin_dB', NaN, 'pass', 'UNKNOWN');
            if isfinite(p1dB_in_dBm) && isfinite(aggregateInputPower_dBm)
                r.allowable_dBm = p1dB_in_dBm - obj.requiredBackoff_dB;
                r.margin_dB = r.allowable_dBm - aggregateInputPower_dBm;
                if r.margin_dB >= 0; r.pass = 'PASS'; else; r.pass = 'FAIL'; end
            end
        end
    end
end
