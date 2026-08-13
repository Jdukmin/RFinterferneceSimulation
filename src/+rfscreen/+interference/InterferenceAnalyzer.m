classdef InterferenceAnalyzer
    %INTERFERENCEANALYZER Orchestrates pairwise analysis into a matrix (SR-092, AR-070).
    %   Iterates all active TX x RX pairs and assembles a MatrixResult.
    methods (Static)
        function mr = analyze(scenario, config, couplingModel)
            if nargin < 2 || isempty(config); config = rfscreen.config.AnalysisConfig.default(); end
            if nargin < 3 || isempty(couplingModel)
                couplingModel = rfscreen.interference.InterferenceAnalyzer.makeCouplingModel(config.couplingModel);
            end
            scenario.validate();

            txIds = scenario.resolveActiveTxIds();
            rxIds = scenario.resolveActiveRxIds();
            nTx = numel(txIds); nRx = numel(rxIds);

            pairs = cell(nTx, nRx);
            risk = cell(nTx, nRx);
            for i = 1:nTx
                for j = 1:nRx
                    in = scenario.buildPairInput(txIds{i}, rxIds{j});
                    pr = rfscreen.interference.PairwiseAnalyzer.analyze(in, couplingModel, config);
                    pairs{i, j} = pr;
                    risk{i, j} = pr.riskLevel;
                end
            end

            gen = struct();
            gen.couplingModel = config.couplingModel;
            gen.freqGuard_Hz = config.frequency.guard_Hz;
            gen.lobeMainDropDb = config.lobe.mainDropDb;
            gen.riskIndexHigh_dB = config.risk.indexHigh_dB;
            gen.freqMethod = config.interpolation.freqMethod;

            mr = rfscreen.results.MatrixResult(txIds, rxIds, pairs, risk, ...
                scenario.name, config.couplingModel, gen);
        end

        function model = makeCouplingModel(modelType)
            %MAKECOUPLINGMODEL Instantiate a coupling model by type (Phase 1: PATTERN_ONLY).
            T = rfscreen.coupling.CouplingModelType;
            switch modelType
                case T.PATTERN_ONLY
                    model = rfscreen.coupling.PatternOnlyCouplingModel();
                case T.FAR_FIELD
                    model = rfscreen.coupling.FarFieldCouplingModel();
                otherwise
                    error('rfscreen:interference:unsupportedCoupling', ...
                        ['coupling model ''%s'' is a reserved interface not available in ' ...
                         'Phase 1; use PATTERN_ONLY (or FAR_FIELD, guarded).'], modelType);
            end
        end
    end
end
