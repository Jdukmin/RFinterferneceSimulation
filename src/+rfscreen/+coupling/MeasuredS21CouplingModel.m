classdef MeasuredS21CouplingModel < rfscreen.coupling.CouplingModel
    %MEASUREDS21COUPLINGMODEL Reserved interface for measured S21 coupling (SR-083).
    %   Phase 1 does NOT implement measured-coupling import; computeCoupling
    %   raises NotImplementedPhase1 rather than fabricating a coupling number
    %   ("no fake physics", SR-120). Exists to prove the extension boundary.
    methods
        function result = computeCoupling(obj, ctx) %#ok<STOUT,INUSD>
            error('rfscreen:coupling:NotImplementedPhase1', ...
                ['MeasuredS21CouplingModel is a reserved interface. Import of measured ' ...
                 'S21 coupling is out of Phase-1 scope.']);
        end
    end
end
