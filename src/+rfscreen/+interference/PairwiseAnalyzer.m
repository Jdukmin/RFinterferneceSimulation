classdef PairwiseAnalyzer
    %PAIRWISEANALYZER Analyze one TX->RX pair (AR-001, AR-010..AR-081).
    %   Pure, deterministic. Consumes a fully-resolved pair-input struct so it can
    %   be unit-tested without a Scenario. Implements the canonical flow:
    %   geometry -> local az/el -> pattern lookup -> lobe class -> frequency
    %   relation -> coupling model -> receiver susceptibility -> PairResult.
    methods (Static)
        function pr = analyze(in, couplingModel, config)
            %ANALYZE Analyze one pair.
            %   in fields (all required unless noted):
            %     tx (RFTransmitter), rx (RFReceiver),
            %     txAntenna, rxAntenna (Antenna),
            %     txInstall, rxInstall (AntennaInstallation),
            %     txPattern, rxPattern (AntennaPattern)
            if nargin < 3 || isempty(config); config = rfscreen.config.AnalysisConfig.default(); end
            if nargin < 2 || isempty(couplingModel)
                couplingModel = rfscreen.coupling.PatternOnlyCouplingModel();
            end
            RL = rfscreen.results.RiskLevel;
            RV = rfscreen.results.ResultValidity;

            pr = rfscreen.results.PairResult();
            pr.txId = in.tx.id;             pr.rxId = in.rx.id;
            pr.txAntennaId = in.txAntenna.id; pr.rxAntennaId = in.rxAntenna.id;
            pr.analysisFrequency_Hz = in.tx.fc_Hz;
            pr.couplingModelType = ''; pr.warnings = {};
            pr.provenance = struct('txPatternProvenance', in.txPattern.provenance, ...
                                   'rxPatternProvenance', in.rxPattern.provenance);
            pr.confidence = rfscreen.interference.PairwiseAnalyzer.screeningConfidence( ...
                in.txPattern, in.rxPattern);

            % ---- Self-pair guard (same antenna) ----
            if strcmp(in.txAntenna.id, in.rxAntenna.id)
                pr.riskLevel = RL.NA;
                pr.validity = RV.VALID_PATTERN_SCREENING;
                pr.interferenceType = rfscreen.results.InterferenceType.NONE;
                pr.warnings{end+1} = 'self-pair (TX and RX share the same antenna): not analyzed';
                return;
            end

            fAnalysis = in.tx.fc_Hz;

            % ---- Frequency relation (independent of geometry) ----
            frel = rfscreen.rf.FrequencyRelation.classify( ...
                in.tx.occupiedBand_Hz(), in.rx.band_Hz(), config.frequency);
            pr.frequencyRelation = frel.type;
            pr.overlap_Hz = frel.overlap_Hz;
            pr.interferenceType = rfscreen.interference.InterferenceClassifier.fromFrequencyRelation(frel.type);
            inBand = strcmp(frel.type, rfscreen.rf.FrequencyRelationType.IN_BAND);

            % ---- Geometry ----
            geom = rfscreen.geometry.AntennaToAntennaFOV.relativeGeometry( ...
                in.txInstall.position_m, in.txInstall.R_BA, ...
                in.rxInstall.position_m, in.rxInstall.R_BA);
            pr.distance_m = geom.distance_m;

            if ~geom.isDefined
                % Co-located antennas: directional screening undefined; do not invent numbers.
                pr.warnings = [pr.warnings, geom.warnings];
                pr.warnings{end+1} = 'zero separation (co-located): full-wave verification required';
                pr.validity = RV.REQUIRES_FULL_WAVE_VERIFICATION;
                pr.couplingModelType = config.couplingModel;
                if inBand; pr.riskLevel = RL.HIGH; else; pr.riskLevel = RL.WARN; end
                return;
            end

            pr.txAz_deg = geom.txAz_deg; pr.txEl_deg = geom.txEl_deg;
            pr.rxAz_deg = geom.rxAz_deg; pr.rxEl_deg = geom.rxEl_deg;

            % ---- Pattern lookup (gain toward the other antenna, at TX frequency) ----
            [txGain, txInfo] = in.txPattern.evaluateWithInfo( ...
                fAnalysis, geom.txAz_deg, geom.txEl_deg, config.interpolation);
            [rxGain, rxInfo] = in.rxPattern.evaluateWithInfo( ...
                fAnalysis, geom.rxAz_deg, geom.rxEl_deg, config.interpolation);
            pr.txGain_dBi = txGain; pr.rxGain_dBi = rxGain;
            pr.warnings = [pr.warnings, txInfo.warnings, rxInfo.warnings];
            outOfDomain = ~txInfo.inDomain || ~rxInfo.inDomain;

            % ---- Lobe classification (metadata only) ----
            pr.txLobeClass = rfscreen.interference.LobeClassifier.classify( ...
                in.txPattern, fAnalysis, geom.txAz_deg, geom.txEl_deg, config.lobe, txGain);
            pr.rxLobeClass = rfscreen.interference.LobeClassifier.classify( ...
                in.rxPattern, fAnalysis, geom.rxAz_deg, geom.rxEl_deg, config.lobe, rxGain);

            % ---- Directional coupling index (for risk), independent of model ----
            if isfinite(txGain) && isfinite(rxGain)
                dci = txGain + rxGain;
            else
                dci = NaN;
            end

            % ---- Coupling model ----
            ctx = rfscreen.coupling.CouplingModel.newContext();
            ctx.distance_m = geom.distance_m;
            ctx.txGain_dBi = txGain; ctx.rxGain_dBi = rxGain;
            ctx.frequency_Hz = fAnalysis; ctx.txPower_dBm = in.tx.power_dBm;
            ctx.txMaxDim_m = in.txAntenna.maxDimension_m;
            ctx.rxMaxDim_m = in.rxAntenna.maxDimension_m;
            cres = couplingModel.computeCoupling(ctx);
            pr.couplingModelType = cres.modelType;
            pr.couplingMetric_dB = cres.metric_dB;
            pr.couplingMetricName = cres.metricName;
            pr.isPhysicalCoupling = cres.isPhysicalCoupling;
            pr.warnings = [pr.warnings, cres.warnings];

            % ---- Interference screening metric (referenced to RX antenna port) ----
            farFieldRequestedNotVerified = false;
            if cres.isPhysicalCoupling && isfinite(cres.metric_dB)
                % Far-field valid: received power at RX input = P + Gtx + Grx - FSPL.
                if isfinite(dci)
                    pr.interferenceMetric_dB = in.tx.power_dBm + dci - cres.metric_dB;
                    pr.receiverInputPower_dBm = pr.interferenceMetric_dB;
                else
                    pr.interferenceMetric_dB = NaN;
                end
            else
                % Pattern-only (or far-field-not-verified): upper-bound screening
                % index at RX port WITHOUT path loss. Not received power.
                if isfinite(dci)
                    pr.interferenceMetric_dB = in.tx.power_dBm + dci;
                    pr.warnings{end+1} = 'screening index without verified path loss (not received power)';
                else
                    pr.interferenceMetric_dB = NaN;
                end
                if strcmp(cres.validity, rfscreen.coupling.CouplingValidity.FAR_FIELD_INVALID_OR_UNKNOWN)
                    farFieldRequestedNotVerified = true;
                end
            end

            % ---- Receiver susceptibility (margin) ----
            if in.rx.hasThreshold() && isfinite(pr.interferenceMetric_dB)
                pr.margin_dB = in.rx.interferenceThreshold_dBm - pr.interferenceMetric_dB;
            else
                pr.margin_dB = NaN;
            end

            % ---- Risk level (screening) ----
            pr.riskLevel = rfscreen.interference.PairwiseAnalyzer.riskLevel( ...
                frel.type, dci, config.risk);

            % ---- Validity (canonical precedence, ICD pair_result.md 4) ----
            patternOnly = strcmp(cres.modelType, rfscreen.coupling.CouplingModelType.PATTERN_ONLY);
            if outOfDomain
                pr.validity = RV.OUTSIDE_PATTERN_DOMAIN;
            elseif inBand && ~in.rx.hasThreshold()
                pr.validity = RV.MISSING_RECEIVER_DATA;
                pr.warnings{end+1} = 'no receiver interference threshold: margin undefined';
            elseif inBand && patternOnly && isfinite(dci) && dci >= config.risk.indexHigh_dB
                pr.validity = RV.REQUIRES_FULL_WAVE_VERIFICATION;
            elseif farFieldRequestedNotVerified
                pr.validity = RV.FAR_FIELD_NOT_VERIFIED;
            else
                pr.validity = RV.VALID_PATTERN_SCREENING;
            end
        end

        function rl = riskLevel(freqRelType, dci, riskPolicy)
            %RISKLEVEL Screening risk from frequency relation + directional index.
            RL = rfscreen.results.RiskLevel;
            T  = rfscreen.rf.FrequencyRelationType;
            if isnan(dci)
                rl = RL.OK; return;
            end
            isIn  = strcmp(freqRelType, T.IN_BAND);
            isAdj = strcmp(freqRelType, T.ADJACENT_BAND);
            isOut = strcmp(freqRelType, T.OUT_OF_BAND);
            if isOut && dci < riskPolicy.indexWarn_dB
                rl = RL.OK;
            elseif isIn && dci >= riskPolicy.indexHigh_dB
                rl = RL.HIGH;
            elseif isIn && dci >= riskPolicy.indexWarn_dB
                rl = RL.WARN;
            elseif isAdj && dci >= riskPolicy.indexHigh_dB
                rl = RL.WARN;
            elseif dci >= riskPolicy.indexLow_dB
                rl = RL.LOW;
            else
                rl = RL.OK;
            end
        end

        function c = screeningConfidence(txPattern, rxPattern)
            %SCREENINGCONFIDENCE Derived from pattern-data confidence (not physics).
            a = txPattern.confidence; b = rxPattern.confidence;
            if isnan(a) || isnan(b)
                c = NaN;
            else
                c = min(a, b);
            end
        end
    end
end
