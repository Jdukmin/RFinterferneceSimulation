classdef MatrixResult
    %MATRIXRESULT Interference matrix over all TX x RX pairs (SR-092, ICD pair_result.md 5).
    %   Plain serializable structure; no live handles (DR-062).
    properties (SetAccess = private)
        txIds               % cellstr row keys
        rxIds               % cellstr column keys
        pairs               % nTx x nRx cell of PairResult ([] for self-pair)
        risk                % nTx x nRx cell of RiskLevel char
        scenarioName
        couplingModelType
        generatedFields     % struct of run metadata
    end
    methods
        function obj = MatrixResult(txIds, rxIds, pairs, risk, scenarioName, ...
                                    couplingModelType, generatedFields)
            if nargin < 7 || isempty(generatedFields); generatedFields = struct(); end
            obj.txIds = txIds(:).';
            obj.rxIds = rxIds(:).';
            obj.pairs = pairs;
            obj.risk = risk;
            obj.scenarioName = scenarioName;
            obj.couplingModelType = couplingModelType;
            obj.generatedFields = generatedFields;
        end

        function p = getPair(obj, txId, rxId)
            i = obj.rowIndex(txId);
            j = obj.colIndex(rxId);
            p = obj.pairs{i, j};
        end

        function r = riskOf(obj, txId, rxId)
            i = obj.rowIndex(txId);
            j = obj.colIndex(rxId);
            r = obj.risk{i, j};
        end

        function list = highRiskPairs(obj)
            %HIGHRISKPAIRS Cell array of [txId rxId] with HIGH risk.
            list = {};
            H = rfscreen.results.RiskLevel.HIGH;
            for i = 1:numel(obj.txIds)
                for j = 1:numel(obj.rxIds)
                    if strcmp(obj.risk{i, j}, H)
                        list{end+1} = {obj.txIds{i}, obj.rxIds{j}}; %#ok<AGROW>
                    end
                end
            end
        end

        function M = riskMatrixChar(obj)
            %RISKMATRIXCHAR Return the risk cell matrix (for display/export).
            M = obj.risk;
        end
    end

    methods (Access = private)
        function i = rowIndex(obj, txId)
            i = find(strcmp(obj.txIds, txId), 1);
            if isempty(i)
                error('rfscreen:results:noTx', 'unknown txId ''%s''.', txId);
            end
        end
        function j = colIndex(obj, rxId)
            j = find(strcmp(obj.rxIds, rxId), 1);
            if isempty(j)
                error('rfscreen:results:noRx', 'unknown rxId ''%s''.', rxId);
            end
        end
    end
end
