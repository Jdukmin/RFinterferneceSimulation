classdef PairResult
    %PAIRRESULT Result of one TX->RX pair analysis (SR-091, ICD pair_result.md 2).
    %   Plain serializable value object (DR-062). Reserved fields are NaN in
    %   Phase 1 (never invented, SR-120).
    properties
        % --- identity ---
        txId = ''
        rxId = ''
        txAntennaId = ''
        rxAntennaId = ''
        % --- geometry ---
        distance_m = NaN
        txAz_deg = NaN
        txEl_deg = NaN
        txGain_dBi = NaN
        rxAz_deg = NaN
        rxEl_deg = NaN
        rxGain_dBi = NaN
        % --- lobe metadata ---
        txLobeClass = ''
        rxLobeClass = ''
        % --- spectral ---
        frequencyRelation = ''
        overlap_Hz = NaN
        analysisFrequency_Hz = NaN
        % --- coupling ---
        couplingModelType = ''
        couplingMetric_dB = NaN
        couplingMetricName = ''
        isPhysicalCoupling = false
        % --- interference decision (screening) ---
        interferenceType = ''
        interferenceMetric_dB = NaN
        margin_dB = NaN
        % --- qualification ---
        validity = ''
        confidence = NaN
        riskLevel = ''
        provenance = struct('txPatternProvenance', '', 'rxPatternProvenance', '')
        warnings = {}
        % --- reserved extension fields (Phase 1: NaN/empty; Task 24) ---
        ItoN_dB = NaN
        CtoNplusI_dB = NaN
        receiverInputPower_dBm = NaN
        blockingMargin_dB = NaN
        p1dBMargin_dB = NaN
        im3Margin_dB = NaN
        measuredS21_dB = NaN
    end

    methods
        function obj = PairResult(s)
            %PAIRRESULT Optionally initialize from a struct of field values.
            if nargin >= 1 && ~isempty(s) && isstruct(s)
                f = fieldnames(s);
                for i = 1:numel(f)
                    if isprop(obj, f{i})
                        obj.(f{i}) = s.(f{i});
                    end
                end
            end
        end

        function s = toStruct(obj)
            %TOSTRUCT Convert to a plain struct (for export/serialization).
            p = properties(obj);
            s = struct();
            for i = 1:numel(p)
                s.(p{i}) = obj.(p{i});
            end
        end

        function tf = isSelfPair(obj)
            tf = ~isempty(obj.riskLevel) && strcmp(obj.riskLevel, rfscreen.results.RiskLevel.NA);
        end
    end
end
