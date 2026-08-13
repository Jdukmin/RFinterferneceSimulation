classdef HFSSCouplingModel < rfscreen.coupling.CouplingModel
    %HFSSCOUPLINGMODEL Reserved interface for HFSS full-wave coupling (SR-083).
    %   Phase 1 does NOT call any EM solver; computeCoupling raises
    %   NotImplementedPhase1 rather than fabricating a coupling number (SR-120).
    %   The same pattern applies to CST / other solvers.
    methods
        function result = computeCoupling(obj, ctx) %#ok<STOUT,INUSD>
            error('rfscreen:coupling:NotImplementedPhase1', ...
                ['HFSSCouplingModel is a reserved interface. Full-wave coupling import ' ...
                 'is out of Phase-1 scope; this tool feeds HFSS, it does not run it.']);
        end
    end
end
