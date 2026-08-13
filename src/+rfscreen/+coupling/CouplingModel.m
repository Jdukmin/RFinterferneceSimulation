classdef CouplingModel
    %COUPLINGMODEL Abstract coupling-model boundary (SR-012, reference.md rule 1).
    %   Concrete: PatternOnlyCouplingModel (Phase 1), FarFieldCouplingModel
    %   (guarded), MeasuredS21CouplingModel/HFSSCouplingModel (reserved).
    %
    %   Contract: result = computeCoupling(ctx), where ctx is a plain struct of
    %   pre-computed pair quantities (see ICD coupling.md 1). The model is kept
    %   independent of geometry/pattern internals so it is freely replaceable.
    methods
        function result = computeCoupling(obj, ctx) %#ok<STOUT,INUSD>
            error('rfscreen:coupling:abstract', ...
                'computeCoupling must be implemented by a concrete CouplingModel subclass.');
        end
    end
    methods (Static)
        function ctx = newContext()
            %NEWCONTEXT Template context struct with the canonical fields.
            ctx = struct('distance_m', NaN, 'txGain_dBi', NaN, 'rxGain_dBi', NaN, ...
                         'frequency_Hz', NaN, 'txPower_dBm', NaN, ...
                         'txMaxDim_m', NaN, 'rxMaxDim_m', NaN);
        end
    end
end
