classdef RfCoexistenceAnalyzer
    %RFCOEXISTENCEANALYZER Phase-3 linear RF coexistence over a scenario (ICD 9).
    %   REUSES the existing Phase-1 InterferenceAnalyzer for the geometric/pattern
    %   matrix, then layers receiver susceptibility for pairs whose TX carries a
    %   spectrum and RX carries a filter. Geometry/directional gain are NOT
    %   recomputed (AR-213). Pairwise-first (Task 26).
    methods (Static)
        function out = analyze(scenario, config, couplingModel)
            if nargin < 2 || isempty(config); config = rfscreen.config.AnalysisConfig.default(); end
            if nargin < 3; couplingModel = []; end
            if isempty(couplingModel)
                matrix = rfscreen.interference.InterferenceAnalyzer.analyze(scenario, config);
            else
                matrix = rfscreen.interference.InterferenceAnalyzer.analyze(scenario, config, couplingModel);
            end

            txIds = matrix.txIds; rxIds = matrix.rxIds;
            nTx = numel(txIds); nRx = numel(rxIds);
            susc = cell(nTx, nRx);
            for i = 1:nTx
                tx = scenario.transmitters(txIds{i});
                for j = 1:nRx
                    rx = scenario.receivers(rxIds{j});
                    pr = matrix.pairs{i, j};
                    if isempty(pr) || ~tx.hasSpectrum() || ~rx.hasFilterModel()
                        susc{i, j} = [];
                        continue;
                    end
                    susc{i, j} = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.analyzeFromPair( ...
                        pr, tx.power_dBm, tx.spectrum, rx.filter, rx.noiseModel, rx.interferenceCriterion);
                end
            end

            out = struct();
            out.matrix = matrix;
            out.susceptibility = susc;
            out.txIds = txIds;
            out.rxIds = rxIds;
            out.scenarioName = scenario.name;
        end

        function s = susceptibilityOf(out, txId, rxId)
            i = find(strcmp(out.txIds, txId), 1);
            j = find(strcmp(out.rxIds, rxId), 1);
            if isempty(i) || isempty(j)
                error('rfscreen:interference:noPair', 'unknown pair %s -> %s.', txId, rxId);
            end
            s = out.susceptibility{i, j};
        end
    end
end
