classdef BlockingCriterion
    %BLOCKINGCRITERION Allowable blocker power vs frequency offset (Task 11-13).
    %   Independent of spectral overlap (Task 14). Two forms:
    %     constant  : one maxBlockerPower_dBm for all offsets
    %     tabulated : (offset_Hz -> maxBlockerPower_dBm), interpolated in dB, clamped
    %   BlockingMargin_dB = allowable(offset) - actualBlocker (sign per Phase 3).
    properties (SetAccess = private)
        mode                 % 'CONSTANT' | 'TABULATED'
        maxBlockerPower_dBm  % constant value (NaN if tabulated)
        offset_Hz            % tabulated grid (or [])
        allowable_dBm        % tabulated values (or [])
        provenance
    end
    methods
        function obj = BlockingCriterion(spec, opts)
            if nargin < 2 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            obj.maxBlockerPower_dBm = NaN; obj.offset_Hz = []; obj.allowable_dBm = [];
            if isnumeric(spec) && isscalar(spec)
                obj.mode = 'CONSTANT';
                obj.maxBlockerPower_dBm = V.finiteScalar(spec, 'maxBlockerPower_dBm');
            elseif isstruct(spec) && isfield(spec, 'offset_Hz') && isfield(spec, 'allowable_dBm')
                obj.mode = 'TABULATED';
                off = V.monotonicVector(spec.offset_Hz, 'offset_Hz');
                al = spec.allowable_dBm(:).';
                if numel(al) ~= numel(off) || any(~isfinite(al))
                    error('rfscreen:receiver:badBlockingTable', ...
                        'allowable_dBm must be finite and match offset_Hz length.');
                end
                obj.offset_Hz = off; obj.allowable_dBm = al;
            else
                error('rfscreen:receiver:badBlockingSpec', ...
                    'spec must be a scalar dBm or a struct(offset_Hz, allowable_dBm).');
            end
            if isfield(opts, 'provenance') && ~isempty(opts.provenance)
                obj.provenance = opts.provenance;
            else
                obj.provenance = 'SYNTHETIC_TEST';
            end
        end

        function a = allowableFor(obj, offset_Hz)
            %ALLOWABLEFOR Allowable blocker power [dBm] at a signed frequency offset.
            if strcmp(obj.mode, 'CONSTANT')
                a = obj.maxBlockerPower_dBm;
            else
                q = abs(offset_Hz);   % symmetric in |offset| unless table is signed
                og = obj.offset_Hz;
                a = interp1(og, obj.allowable_dBm, q, 'linear');
                if q < og(1);  a = obj.allowable_dBm(1);   end
                if q > og(end); a = obj.allowable_dBm(end); end
            end
        end

        function r = evaluate(obj, actualBlockerPower_dBm, offset_Hz)
            %EVALUATE Margin = allowable(offset) - actual ; >=0 PASS.
            r = struct('allowable_dBm', obj.allowableFor(offset_Hz), 'margin_dB', NaN, 'pass', 'UNKNOWN');
            if isfinite(actualBlockerPower_dBm) && isfinite(r.allowable_dBm)
                r.margin_dB = r.allowable_dBm - actualBlockerPower_dBm;
                if r.margin_dB >= 0; r.pass = 'PASS'; else; r.pass = 'FAIL'; end
            end
        end
    end
end
