classdef PreferredCouplingModel < rfscreen.coupling.CouplingModel
    %PREFERREDCOUPLINGMODEL Per-pair choice: a primary (installed / tabulated S21) model where it has
    %   data, otherwise a fallback (e.g. free-space) model -- with the fallback made explicit.
    %   Used for "installed where we have it (L/S), free-space otherwise (X/Ka)". The fallback is
    %   used only when the primary reports S21_UNAVAILABLE; its result keeps its own modelType /
    %   validity (never relabelled) and gains a warning naming the fallback.
    properties (SetAccess = private)
        primary
        fallback
    end
    methods
        function obj = PreferredCouplingModel(primary, fallback)
            if ~isa(primary, 'rfscreen.coupling.CouplingModel') || ~isa(fallback, 'rfscreen.coupling.CouplingModel')
                error('rfscreen:coupling:badModel', 'primary and fallback must be CouplingModel objects.');
            end
            obj.primary = primary; obj.fallback = fallback;
        end
        function result = computeCoupling(obj, ctx)
            r = obj.primary.computeCoupling(ctx);
            if ~strcmp(r.validity, rfscreen.coupling.CouplingValidity.S21_UNAVAILABLE)
                result = r; return;
            end
            f = obj.fallback.computeCoupling(ctx);
            w = [{'no installed S21 for this pair/frequency: fallback coupling model used'}, f.warnings];
            result = rfscreen.coupling.CouplingResult(f.modelType, f.validity, f.metric_dB, f.metricName, ...
                f.isPhysicalCoupling, w);
        end
    end
end
