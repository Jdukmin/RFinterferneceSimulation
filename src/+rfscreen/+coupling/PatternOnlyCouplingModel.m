classdef PatternOnlyCouplingModel < rfscreen.coupling.CouplingModel
    %PATTERNONLYCOUPLINGMODEL Phase-1 coupling (SR-080, AR-050, ICD coupling.md 2).
    %   metric = txGain_dBi + rxGain_dBi = DirectionalCouplingIndex_dB.
    %   This is a SCREENING index, NOT isolation/S21 and NOT a physical coupling:
    %     - modelType         = PATTERN_ONLY
    %     - validity          = PATTERN_ONLY
    %     - isPhysicalCoupling = false
    %     - metricName        = 'DirectionalCouplingIndex_dB'
    %   No path-loss term is applied (AR-051). It must NEVER masquerade as
    %   MEASURED_S21 (VR-082).
    methods
        function result = computeCoupling(obj, ctx) %#ok<INUSL>
            warnings = {};
            if ~isfinite(ctx.txGain_dBi) || ~isfinite(ctx.rxGain_dBi)
                dci = NaN;
                warnings{end+1} = 'gain out of pattern domain; DirectionalCouplingIndex undefined';
            else
                dci = ctx.txGain_dBi + ctx.rxGain_dBi;
            end
            T = rfscreen.coupling.CouplingModelType;
            Vv = rfscreen.coupling.CouplingValidity;
            result = rfscreen.coupling.CouplingResult( ...
                T.PATTERN_ONLY, Vv.PATTERN_ONLY, dci, ...
                'DirectionalCouplingIndex_dB', false, warnings);
        end
    end
end
