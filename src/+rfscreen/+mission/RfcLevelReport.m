classdef RfcLevelReport
    %RFCLEVELREPORT Per (interferer -> victim) received-level / S21 table of a mission case (P8).
    %   Runs the EXISTING engine (InterferenceAnalyzer -> PairwiseAnalyzer, coupling models,
    %   Phase-3 susceptibility) over the active TX x RX of a case and tabulates, for every pair:
    %     geometry (distance, LOS, blocking panels), gains toward each other, the transfer
    %     S21 in dB (Gtx + Grx - FSPL, or the tabulated installed S21), the received level at the
    %     victim antenna port (P_tx + S21), the in-band interference power at the receiver RF input
    %     (adds the spectral factor), noise, allowable level, I/N and margin.
    %   Coupling policy (owner decision 2026-10-04): X-band (ISL), Ka and SAR use FREE-SPACE
    %   propagation/patterns; L- and S-band use an installed S21 table where one exists, else the
    %   free-space result with an explicit flag. No number is invented: where Friis is applied
    %   although far-field is not verified the row says so.
    %   Column labels come from rfc_terms.csv (configurable terminology).
    methods (Static)
        function terms = readTerms(datasetDir)
            if nargin < 1 || isempty(datasetDir)
                datasetDir = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
            end
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(datasetDir, 'rfc_terms.csv'));
            terms = struct();
            for r = 1:T.nRows
                terms.(T.term_key{r}) = struct('ko', T.ko{r}, 'en', T.en{r}, 'status', T.status{r});
            end
        end

        function model = couplingModel(s21Tables)
            %COUPLINGMODEL Free-space (assumed where far-field is unverified) + optional installed S21.
            ff = rfscreen.coupling.FarFieldCouplingModel(5, struct('assumeFreeSpace', true));
            if nargin < 1 || isempty(s21Tables)
                model = ff;
            else
                model = rfscreen.coupling.PreferredCouplingModel(rfscreen.coupling.CstCouplingModel(s21Tables), ff);
            end
        end

        function rows = build(c, couplingModel, config)
            %BUILD Rows for every active TX x RX pair of case struct c (MissionCaseBuilder.buildCase).
            if nargin < 3 || isempty(config); config = rfscreen.config.AnalysisConfig.default(); end
            sc = c.scenario;
            out = rfscreen.interference.RfCoexistenceAnalyzer.analyze(sc, config, couplingModel);
            sysById = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for q = 1:numel(c.rfSystems); sysById(c.rfSystems(q).systemId) = c.rfSystems(q); end
            rows = struct('caseId', {}, 'modeId', {}, 'interfererId', {}, 'victimId', {}, ...
                'interfererAntenna', {}, 'victimAntenna', {}, 'txFreq_Hz', {}, 'txBw_Hz', {}, 'rxFreq_Hz', {}, ...
                'rxBw_Hz', {}, 'frequencyRelation', {}, 'distance_m', {}, 'los', {}, 'blockingPanels', {}, ...
                'txGain_dBi', {}, 'rxGain_dBi', {}, 'txLobe', {}, 'rxLobe', {}, 'coupling', {}, 'couplingValidity', {}, ...
                'farFieldVerified', {}, 'fspl_dB', {}, 's21_dB', {}, 'txPower_dBm', {}, 'receivedLevel_dBm', {}, ...
                'spectralFactor_dB', {}, 'inBandInterference_dBm', {}, 'noise_dBm', {}, 'allowable_dBm', {}, ...
                'iOverN_dB', {}, 'margin_dB', {}, 'requiredRejection_dB', {}, 'passFail', {}, 'band', {}, 'installedEffect', {}, 'warnings', {});
            structs = sc.activeStructures();
            for i = 1:numel(out.txIds)
                tx = sc.transmitters(out.txIds{i});
                for j = 1:numel(out.rxIds)
                    rx = sc.receivers(out.rxIds{j});
                    pr = out.matrix.pairs{i, j};
                    s = out.susceptibility{i, j};
                    txAnt = sc.antennas(tx.antennaId); rxAnt = sc.antennas(rx.antennaId);
                    if strcmp(txAnt.installationId, rxAnt.installationId); continue; end   % same mount: no inter-antenna path
                    ia = sc.installations(txAnt.installationId); ib = sc.installations(rxAnt.installationId);
                    los = rfscreen.geometry.LineOfSight.segment(txAnt.installationId, rxAnt.installationId, ...
                        ia.position_m, ib.position_m, structs);
                    at = rfscreen.coupling.AbsoluteTransfer.fromPair(pr);
                    s21 = NaN; fspl = NaN;
                    if at.isAbsolute
                        s21 = at.absoluteTransfer_dB;
                        if strcmp(pr.couplingModelType, 'FAR_FIELD'); fspl = pr.couplingMetric_dB; end
                    end
                    recv = NaN; if isfinite(s21); recv = tx.power_dBm + s21; end
                    spec = NaN; inb = NaN; noise = NaN; allow = NaN; ion = NaN; mar = NaN; pf = '';
                    if ~isempty(s)
                        spec = s.spectralFactor_dB; inb = s.interferencePower_dBm; noise = s.noisePower_dBm;
                        ion = s.iOverN_dB; pf = s.passFail;
                        if ~isempty(rx.interferenceCriterion) && isfinite(noise)
                            allow = noise + rx.interferenceCriterion.thresholdValue;
                            if isfinite(inb); mar = allow - inb; end
                        end
                    end
                    reqRej = NaN;     % rejection the victim front end must provide to meet its criterion
                    if isfinite(recv) && ~isempty(rx.interferenceCriterion) && isfinite(rx.noiseModel.noisePower_dBm(rx.bw_Hz))
                        reqRej = recv - (rx.noiseModel.noisePower_dBm(rx.bw_Hz) + rx.interferenceCriterion.thresholdValue);
                    end
                    ffv = strcmp(at.couplingValidity, 'FAR_FIELD_VALID') || strcmp(at.couplingValidity, 'FULL_WAVE_COUPLING');
                    rows(end+1) = struct('caseId', c.caseId, 'modeId', c.mode.modeId, 'interfererId', tx.id, 'victimId', rx.id, ...
                        'interfererAntenna', txAnt.id, 'victimAntenna', rxAnt.id, 'txFreq_Hz', tx.fc_Hz, 'txBw_Hz', tx.bw_Hz, ...
                        'rxFreq_Hz', rx.fc_Hz, 'rxBw_Hz', rx.bw_Hz, 'frequencyRelation', pr.frequencyRelation, ...
                        'distance_m', pr.distance_m, 'los', los.status, 'blockingPanels', {los.blockingStructureIds}, ...
                        'txGain_dBi', pr.txGain_dBi, 'rxGain_dBi', pr.rxGain_dBi, 'txLobe', pr.txLobeClass, ...
                        'rxLobe', pr.rxLobeClass, 'coupling', pr.couplingModelType, 'couplingValidity', at.couplingValidity, ...
                        'farFieldVerified', ffv, 'fspl_dB', fspl, 's21_dB', s21, 'txPower_dBm', tx.power_dBm, ...
                        'receivedLevel_dBm', recv, 'spectralFactor_dB', spec, 'inBandInterference_dBm', inb, ...
                        'noise_dBm', noise, 'allowable_dBm', allow, 'iOverN_dB', ion, 'margin_dB', mar, 'requiredRejection_dB', reqRej, 'passFail', pf, ...
                        'band', rfscreen.mission.RfcLevelReport.bandClass(tx.fc_Hz, rx.fc_Hz), ...
                        'installedEffect', rfscreen.mission.RfcLevelReport.installedFlag(tx.fc_Hz, rx.fc_Hz, pr, at, ...
                            rfscreen.mission.RfcLevelReport.isInstalled(c, txAnt.id) || rfscreen.mission.RfcLevelReport.isInstalled(c, rxAnt.id)), ...
                        'warnings', {pr.warnings}); %#ok<AGROW>
                end
            end
        end

        function b = bandClass(fTx, fRx) %#ok<INUSD>
            %BANDCLASS Coupling-policy band, decided by the INTERFERER (coupling) frequency:
            %   below 3 GHz (L/S) an installed S21 can exist; at X-band / Ka / SAR free space is used.
            if fTx < 3e9; b = 'L_S'; else; b = 'X_KA_FREE_SPACE'; end
        end

        function tf = isInstalled(c, antennaId)
            k = find(strcmp({c.functions.functionId}, antennaId), 1);
            tf = ~isempty(k) && strcmp(c.functions(k).patternSource, 'INSTALLED');
        end

        function f = installedFlag(fTx, fRx, pr, at, anyInstalledPattern) %#ok<INUSL>
            %INSTALLEDFLAG Whether an installation effect is included in the transfer.
            if strcmp(at.couplingValidity, 'FULL_WAVE_COUPLING')
                f = 'INSTALLED_S21';
            elseif anyInstalledPattern
                f = 'INSTALLED_PATTERN';
            elseif fTx >= 3e9
                f = 'FREE_SPACE_BY_DECISION';
            else
                f = 'FREE_SPACE_INSTALLATION_EFFECT_UNKNOWN';
            end
        end

        function writeCsv(rows, filePath, terms)
            %WRITECSV Deterministic CSV with terminology-driven headers noted in a comment line.
            if nargin < 3 || isempty(terms); terms = rfscreen.mission.RfcLevelReport.readTerms(); end
            fid = fopen(filePath, 'w');
            fprintf(fid, '# interferer = %s / %s ; victim = %s / %s ; status %s (terminology not yet confirmed against the KARI papers)\n', ...
                terms.interferer.ko, terms.interferer.en, terms.victim.ko, terms.victim.en, terms.interferer.status);
            fprintf(fid, ['case_id,mode_id,interferer_id,victim_id,interferer_antenna,victim_antenna,tx_freq_ghz,tx_bw_mhz,rx_freq_ghz,rx_bw_mhz,' ...
                'freq_relation,distance_m,los,blocking_panels,tx_gain_dbi,rx_gain_dbi,tx_lobe,rx_lobe,coupling,coupling_validity,' ...
                'far_field_verified,fspl_db,s21_db,tx_power_dbm,received_level_dbm,spectral_factor_db,in_band_interference_dbm,' ...
                'noise_dbm,allowable_dbm,i_over_n_db,margin_db,required_rejection_db,pass_fail,policy_band,installed_effect\n']);
            for k = 1:numel(rows)
                r = rows(k);
                fprintf(fid, '%s,%s,%s,%s,%s,%s,%.6f,%.6f,%.6f,%.6f,%s,%.4f,%s,%s,%.3f,%.3f,%s,%s,%s,%s,%d,%s,%s,%.4f,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n', ...
                    r.caseId, r.modeId, r.interfererId, r.victimId, r.interfererAntenna, r.victimAntenna, ...
                    r.txFreq_Hz/1e9, r.txBw_Hz/1e6, r.rxFreq_Hz/1e9, r.rxBw_Hz/1e6, r.frequencyRelation, r.distance_m, ...
                    r.los, strjoin(r.blockingPanels, ';'), r.txGain_dBi, r.rxGain_dBi, r.txLobe, r.rxLobe, r.coupling, ...
                    r.couplingValidity, r.farFieldVerified, num(r.fspl_dB), num(r.s21_dB), r.txPower_dBm, ...
                    num(r.receivedLevel_dBm), num(r.spectralFactor_dB), num(r.inBandInterference_dBm), num(r.noise_dBm), ...
                    num(r.allowable_dBm), num(r.iOverN_dB), num(r.margin_dB), num(r.requiredRejection_dB), r.passFail, r.band, r.installedEffect);
            end
            fclose(fid);
        end
    end
end

function s = num(x)
    if isnan(x); s = 'NaN'; elseif isinf(x); if x < 0; s = '-Inf'; else; s = 'Inf'; end
    else; s = sprintf('%.3f', x); end
end
