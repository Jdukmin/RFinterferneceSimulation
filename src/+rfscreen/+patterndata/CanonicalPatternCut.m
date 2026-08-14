classdef CanonicalPatternCut
    %CANONICALPATTERNCUT Single internal representation of one canonicalized cut
    %   (DR-107, ICD pattern_data.md 3). theta_deg is canonical (sorted, [0,360)),
    %   native resolution preserved. Periodic interpolation via evaluate().
    properties (SetAccess = private)
        patternId
        antennaId
        plane
        theta_deg
        gain_dBi
        samplingType
        nominalStep_deg
        frequency_Hz
        fidelity
        sourceConvention
        canonicalConvention
        provenance
        validationStatus
        warnings
    end

    methods
        function obj = CanonicalPatternCut(s)
            %CANONICALPATTERNCUT Build from a struct of already-canonicalized fields.
            V = rfscreen.util.Validate;
            obj.patternId = V.id(s.patternId, 'patternId');
            obj.plane = V.member(s.plane, {'XZ', 'YZ'}, 'plane');
            th = s.theta_deg(:).';
            g  = s.gain_dBi(:).';
            if numel(th) ~= numel(g)
                error('rfscreen:patterndata:cutShape', 'theta_deg and gain_dBi length mismatch.');
            end
            if numel(th) >= 1 && (any(th < 0) || any(th >= 360 + 1e-9))
                error('rfscreen:patterndata:cutRange', 'canonical theta_deg must be in [0,360).');
            end
            if numel(th) >= 2 && any(diff(th) <= 0)
                error('rfscreen:patterndata:cutOrder', 'canonical theta_deg must be strictly increasing.');
            end
            obj.theta_deg = th;
            obj.gain_dBi = g;

            obj.antennaId = rfscreen.patterndata.CanonicalPatternCut.optChar(s, 'antennaId', '');
            obj.samplingType = V.member( ...
                rfscreen.patterndata.CanonicalPatternCut.optChar(s, 'samplingType', 'INVALID'), ...
                rfscreen.patterndata.SamplingType.values(), 'samplingType');
            obj.nominalStep_deg = rfscreen.patterndata.CanonicalPatternCut.optNum(s, 'nominalStep_deg', NaN);
            obj.frequency_Hz = rfscreen.patterndata.CanonicalPatternCut.optNum(s, 'frequency_Hz', NaN);
            obj.fidelity = V.member( ...
                rfscreen.patterndata.CanonicalPatternCut.optChar(s, 'fidelity', 'SYNTHETIC_TEST'), ...
                rfscreen.patterndata.PatternFidelity.values(), 'fidelity');
            obj.sourceConvention = rfscreen.patterndata.CanonicalPatternCut.optAny(s, 'sourceConvention', []);
            obj.canonicalConvention = rfscreen.patterndata.CanonicalPatternCut.optAny(s, 'canonicalConvention', []);
            obj.provenance = rfscreen.patterndata.CanonicalPatternCut.optAny(s, 'provenance', struct());
            obj.validationStatus = V.member( ...
                rfscreen.patterndata.CanonicalPatternCut.optChar(s, 'validationStatus', 'VALID'), ...
                rfscreen.patterndata.ValidationStatus.values(), 'validationStatus');
            obj.warnings = rfscreen.patterndata.CanonicalPatternCut.optAny(s, 'warnings', {});
        end

        function n = numSamples(obj)
            n = numel(obj.theta_deg);
        end

        function g = evaluate(obj, theta_query_deg)
            %EVALUATE Periodic linear interpolation on the native theta grid (§13, §20).
            th = obj.theta_deg; gv = obj.gain_dBi;
            n = numel(th);
            if n == 0
                g = NaN; return;
            elseif n == 1
                g = gv(1); return;
            end
            q = mod(theta_query_deg, 360);
            if q >= th(1) && q <= th(end)
                k = find(th <= q, 1, 'last');
                if k >= n; k = n - 1; end
                t = (q - th(k)) / (th(k+1) - th(k));
                g = (1 - t) * gv(k) + t * gv(k+1);
            else
                % wrap seam between last node and first node + 360
                denom = (th(1) + 360) - th(end);
                if q < th(1); qq = q + 360; else; qq = q; end
                t = (qq - th(end)) / denom;
                g = (1 - t) * gv(end) + t * gv(1);
            end
        end

        function tf = is2DCut(obj)
            tf = rfscreen.patterndata.PatternFidelity.is2DCut(obj.fidelity);
        end

        function s = toStruct(obj)
            %TOSTRUCT Plain struct of all fields (for resampling / export).
            p = properties(obj); s = struct();
            for i = 1:numel(p); s.(p{i}) = obj.(p{i}); end
        end
    end

    methods (Static, Access = private)
        function v = optChar(s, name, default)
            if isfield(s, name) && ~isempty(s.(name)) && ischar(s.(name)); v = s.(name); else; v = default; end
        end
        function v = optNum(s, name, default)
            if isfield(s, name) && ~isempty(s.(name)); v = double(s.(name)); else; v = default; end
        end
        function v = optAny(s, name, default)
            if isfield(s, name); v = s.(name); else; v = default; end
        end
    end
end
