classdef CalRfiAnalyzer
    %CALRFIANALYZER CAL pair plan -> existing victim-band PSD engine (no new physics).
    %   For each cal_rfi_plan.csv row (victim band x CST frequency plane) and attacker/victim pair:
    %     geometry   : SimplifiedSpacecraftBuilder installations (position, R_BA); u = unit(p_rx - p_tx)
    %     directions : u_tx,A = R_BA,tx' u ; u_rx,A = R_BA,rx' (-u)
    %     coupling   : rfscreen.psd.VictimBandCoupling.patternRoute  C = G_tx(f_v) + G_rx(f_v) - FSPL(f_v)
    %                  (Realized Gain: no separate S11 loss; CST plane = victim frequency only)
    %     source     : ITU source rows (EmissionSpec) of the attacker tx_system in source_band, carrier from rf_systems.csv
    %     criterion  : rfscreen.psd.ReceiverBaseline allowable PSD = kT0 + NF + (I/N)max
    %     result     : PsdMath.victimPortPsd / margin / requiredSuppression (TX chain loss 0 dB: ANTENNA_PORT sources)
    %   Missing pattern -> INPUT_MISSING (no coupling); missing source -> coupling evaluated, verdict UNKNOWN.
    properties (Constant)
        SOURCE_FILES = {fullfile('data', 'rfi_psd', 'kaa_itu_spurious_source.csv'), ...
                        fullfile('data', 'rfi_psd', 'stc_itu_spurious_source.csv'), ...
                        fullfile('data', 'cal_config', 'cal_emission_sources.csv')}
    end
    methods (Static)
        function rows = run(repoRoot, catalog, binder, model, freqMap, configDir)
            R = rfscreen.spacecraft.SpacecraftDataReader;
            P = rfscreen.psd.PsdMath;
            plan = R.readTable(fullfile(configDir, 'cal_rfi_plan.csv'));
            B = rfscreen.psd.ReceiverBaseline.read(fullfile(repoRoot, 'data', 'rfi_psd', 'receiver_baseline.csv'));
            sources = rfscreen.cal.CalRfiAnalyzer.loadSources(repoRoot);
            sysT = R.readTable(fullfile(model.datasetDir, 'rf_systems.csv'));
            sar = rfscreen.cal.CalRfiAnalyzer.loadSar(repoRoot);
            rows = struct([]);
            for r = 1:plan.nRows
                band = plan.victim_band{r};
                [ok, f, flab] = freqMap.resolve(plan.freq_token{r});
                if ~ok
                    error('rfscreen:cal:badPlan', 'cal_rfi_plan.csv row %d: token %s not in the alias table.', r, plan.freq_token{r});
                end
                b = rfscreen.psd.ReceiverBaseline.lookup(B, plan.criterion_receiver{r});
                crit = sprintf('%s: kT0 %g + NF %g + I/N %g = %.4g dBm/Hz', b.receiver, P.KT0_DBM_HZ, b.nf_dB, b.i_n_max_dB, ...
                    b.allowable_psd_dBmHz);
                victims = strsplit(plan.victims{r}, ';');
                attackers = strsplit(plan.attackers{r}, ';');
                for iv = 1:numel(victims)
                    for ia = 1:numel(attackers)
                        tx = attackers{ia}; rx = victims{iv};
                        if strcmp(tx, rx); continue; end
                        row = rfscreen.cal.CalRfiAnalyzer.evaluatePair(tx, rx, band, plan.source_band{r}, f, flab, ...
                            binder, model, sources, sysT, sar, b, crit);
                        row.band_lo_mhz = str2double(plan.band_lo_mhz{r}); row.band_hi_mhz = str2double(plan.band_hi_mhz{r});
                        row.band_prov = plan.band_prov{r};
                        if isempty(rows); rows = row; else; rows(end+1) = row; end %#ok<AGROW>
                    end
                end
            end
        end

        function row = evaluatePair(tx, rx, band, sourceBand, f, flab, binder, model, sources, sysT, sar, b, crit)
            P = rfscreen.psd.PsdMath;
            DC = rfscreen.geometry.DirectionCalculator;
            row = rfscreen.cal.CalRfiAnalyzer.blankRow();
            tag = band; if ~strcmp(band, flab); tag = [band '_' flab]; end
            row.pair_id = sprintf('CAL_%s_%s_TO_%s', tag, tx, rx);
            row.tx_installation = tx; row.rx_installation = rx; row.victim_band = band;
            row.analysis_frequency_hz = f; row.frequency_label = flab;
            row.allowable_psd_dbm_hz = b.allowable_psd_dBmHz; row.receiver_criterion = crit;
            W = {};
            iT = model.installations(tx); iR = model.installations(rx);
            d = iR.position_m - iT.position_m; dist = norm(d); u = d / dist;
            row.distance_m = dist;
            uT = iT.R_BA.' * u; uR = iR.R_BA.' * (-u);
            [row.tx_az_deg, row.tx_el_deg] = DC.directionToAzEl(uT);
            [row.rx_az_deg, row.rx_el_deg] = DC.directionToAzEl(uR);
            [row.tx_cst_theta_deg, row.tx_cst_phi_deg] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi( ...
                rfscreen.kaa.CstLocalFrameAdapter.localToAntenna().' * uT);
            [row.rx_cst_theta_deg, row.rx_cst_phi_deg] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi( ...
                rfscreen.kaa.CstLocalFrameAdapter.localToAntenna().' * uR);
            los = rfscreen.geometry.LineOfSight.segment(tx, rx, iT.position_m, iR.position_m, model.structures);
            row.los_status = los.status;
            if strcmp(los.status, 'BLOCKED')
                W{end+1} = sprintf('LOS_BLOCKED by %s (geometry evidence only; no attenuation applied)', ...
                    strjoin(los.blockingStructureIds, '+'));
            end
            if any(strcmp({'KAA_1', 'KAA_2'}, tx))
                W{end+1} = 'KAA_GIMBAL_REFERENCE_ORIENTATION (panel normal; not a commanded tracking case)';
            end
            if any(strcmp('ISL', {tx, rx}))
                W{end+1} = ['ISL_ORIENTATION_SSOT antenna_installations.csv PANEL_3 normal (closed-network geometry uses ' ...
                    'an owner +X end-face override)'];
            end

            % ---- TX pattern ----
            sT = binder.bind(tx, 'TX', f);
            W = [W sT.warnings];
            row.tx_pattern_type = sT.patternType; row.tx_pattern_file = sT.file;
            if strcmp(sT.status, 'BOUND'); row.tx_pattern_class = class(sT.pattern); end
            % ---- RX pattern ----
            rinfo = binder.roleInfo(rx);
            if strcmp(rinfo.family, 'SAR')
                if isempty(sar.pattern)
                    sR = struct('status', 'INPUT_MISSING', 'reason', sar.reason, 'warnings', {{}});
                else
                    sR = struct('status', 'BOUND', 'reason', '', 'warnings', {{}});
                    row.rx_pattern_type = 'OWNER_ENGINEERING_BASELINE';
                    row.rx_pattern_file = sar.file; row.rx_pattern_class = 'rfscreen.psd.SarOwnerPattern';
                    rResp = rfscreen.cal.CalBandResponse.fromSar(band, sar.pattern, sar.peak_dBi);
                    W{end+1} = 'RX_SAR_OWNER_ENGINEERING_BASELINE (not CST; not installed)';
                end
            else
                sR = binder.bind(rx, 'RX', f);
                row.rx_pattern_type = sR.patternType; row.rx_pattern_file = sR.file;
                if strcmp(sR.status, 'BOUND')
                    row.rx_pattern_class = class(sR.pattern);
                    rResp = rfscreen.cal.CalBandResponse.fromPattern(band, sR.pattern);
                end
            end
            W = [W sR.warnings];
            missing = {};
            if ~strcmp(sT.status, 'BOUND'); missing{end+1} = ['TX: ' sT.reason]; end
            if ~strcmp(sR.status, 'BOUND'); missing{end+1} = ['RX: ' sR.reason]; end
            row.tx_pattern_provenance = rfscreen.cal.CalRfiAnalyzer.provOf(sT);
            row.rx_pattern_provenance = rfscreen.cal.CalRfiAnalyzer.provOf(sR);
            if ~isempty(missing)
                row.status = 'INPUT_MISSING_PATTERN';
                row.verdict = 'UNKNOWN';
                row.validity = 'INPUT_MISSING';
                W = [W missing];
                row.warnings = strjoin(W, ' | ');
                return;
            end
            if strcmp(sT.patternType, 'FREE_SPACE') || strcmp(row.rx_pattern_type, 'FREE_SPACE')
                W{end+1} = 'FREE_SPACE_PATTERN_IN_PATH (installation effect of that antenna not included)';
            end
            tResp = rfscreen.cal.CalBandResponse.fromPattern(band, sT.pattern);

            % ---- source ----
            tinfo = binder.roleInfo(tx);
            spec = rfscreen.cal.CalRfiAnalyzer.findSource(sources, tinfo.txSystem, sourceBand, f);
            includeTxGain = true;
            if ~isempty(spec); includeTxGain = ~spec.isRadiated(); end
            c = rfscreen.psd.VictimBandCoupling.patternRoute(tResp, rResp, band, f, uT, uR, dist, includeTxGain);
            row.tx_gain_dbi = c.gtx_dBi; row.rx_gain_dbi = c.grx_dBi; row.fspl_db = c.fspl_dB;
            row.coupling_db = c.coupling_dB; row.coupling_route = c.route;
            if ~includeTxGain
                % EIRP-referenced source: G_tx is inside the source; keep the directional value for provenance.
                row.tx_gain_dbi = tResp.gainAt(band, f, uT);
            end
            row.coupling_fidelity = 'NATIVE_3D_CST_REALIZED_GAIN; FAR_FIELD_FSPL_MODEL (near-field not verified)';
            if isempty(spec)
                row.status = 'COUPLING_EVALUATED_SOURCE_MISSING';
                row.verdict = 'UNKNOWN';
                row.validity = 'INPUT_MISSING';
                W{end+1} = sprintf('EMISSION_SOURCE_MISSING: no %s source row for band %s at %.6g GHz', tinfo.txSystem, sourceBand, f / 1e9);
                row.warnings = strjoin(W, ' | ');
                return;
            end
            k = find(strcmp(sysT.template_id, tinfo.txSystem) & strcmp(sysT.kind, 'TX'), 1);
            carrier = str2double(sysT.tx_power_dbm{k});
            row.source_psd_dbm_hz = spec.psdDbmHz(carrier);
            row.source_plane = spec.referencePlane;
            row.source_provenance = sprintf('%s; %s; %s', spec.standardOrSource, spec.assumptionClass, spec.provenance);
            row.tx_chain_loss_db = 0;
            row.victim_psd_dbm_hz = P.victimPortPsd(row.source_psd_dbm_hz, row.tx_chain_loss_db, row.coupling_db);
            row.margin_db = P.margin(row.allowable_psd_dbm_hz, row.victim_psd_dbm_hz);
            row.required_suppression_db = max(0, P.requiredSuppression(row.victim_psd_dbm_hz, row.allowable_psd_dbm_hz));
            st = P.maskStatus(row.margin_db); row.verdict = st{1};
            row.status = 'EVALUATED';
            row.validity = 'SCREENING_SINGLE_CST_PLANE';
            W{end+1} = 'SINGLE_FREQUENCY_PLANE (victim band not swept; TX chain/filter loss 0 dB)';
            row.warnings = strjoin(W, ' | ');
        end

        function row = blankRow()
            row = struct('pair_id', '', 'tx_installation', '', 'rx_installation', '', 'victim_band', '', ...
                'analysis_frequency_hz', NaN, 'frequency_label', '', 'band_lo_mhz', NaN, 'band_hi_mhz', NaN, 'band_prov', '', ...
                'tx_pattern_file', '', 'rx_pattern_file', '', 'tx_pattern_type', '', 'rx_pattern_type', '', ...
                'tx_pattern_class', '', 'rx_pattern_class', '', 'tx_pattern_provenance', '', 'rx_pattern_provenance', '', ...
                'tx_az_deg', NaN, 'tx_el_deg', NaN, 'rx_az_deg', NaN, 'rx_el_deg', NaN, ...
                'tx_cst_theta_deg', NaN, 'tx_cst_phi_deg', NaN, 'rx_cst_theta_deg', NaN, 'rx_cst_phi_deg', NaN, ...
                'tx_gain_dbi', NaN, 'rx_gain_dbi', NaN, 'distance_m', NaN, 'fspl_db', NaN, 'coupling_db', NaN, ...
                'coupling_route', '', 'coupling_fidelity', '', 'los_status', '', ...
                'source_psd_dbm_hz', NaN, 'source_plane', '', 'source_provenance', '', 'tx_chain_loss_db', NaN, ...
                'victim_psd_dbm_hz', NaN, 'allowable_psd_dbm_hz', NaN, 'receiver_criterion', '', ...
                'margin_db', NaN, 'required_suppression_db', NaN, 'status', '', 'verdict', '', 'validity', '', 'warnings', '');
        end

        function S = loadSources(repoRoot)
            files = rfscreen.cal.CalRfiAnalyzer.SOURCE_FILES;
            S = {};
            for i = 1:numel(files)
                p = fullfile(repoRoot, files{i});
                if exist(p, 'file') ~= 2; continue; end
                T = rfscreen.spacecraft.SpacecraftDataReader.readTable(p);
                cols = rfscreen.psd.EmissionSpec.COLUMNS;
                for r = 1:T.nRows
                    s = struct();
                    for c = 1:numel(cols); s.(cols{c}) = T.(cols{c}){r}; end
                    e = rfscreen.psd.EmissionSpec(s);
                    for j = 1:numel(S)
                        if strcmp(S{j}.txSystem, e.txSystem) && strcmp(S{j}.victimBand, e.victimBand)
                            error('rfscreen:cal:duplicateSource', '%s: source %s / %s already defined.', files{i}, e.txSystem, e.victimBand);
                        end
                    end
                    S{end+1} = e; %#ok<AGROW>
                end
            end
        end

        function spec = findSource(S, txSystem, band, f)
            spec = [];
            for j = 1:numel(S)
                if strcmp(S{j}.txSystem, txSystem) && strcmp(S{j}.victimBand, band) && ...
                        strcmp(S{j}.emissionType, 'BROADBAND_PSD') && S{j}.covers(f)
                    spec = S{j}; return;
                end
            end
        end

        function sar = loadSar(repoRoot)
            sar = struct('pattern', [], 'peak_dBi', NaN, 'file', '', 'reason', '');
            d = fullfile(repoRoot, 'data', 'Xband_SAR_K8_owner');
            try
                SP = rfscreen.psd.SarOwnerPattern.fromFile(fullfile(d, 'owner_cut_values.csv'));
                OA = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(d, 'owner_absolute_inputs.csv'));
                oa = @(k) str2double(OA.value{strcmp(OA.item, k)});
                sar.pattern = SP.withOutsideCeiling(oa('OUTSIDE_80_CEILING'));
                sar.peak_dBi = oa('SAR_PEAK_GAIN');
                sar.file = 'data/Xband_SAR_K8_owner/owner_cut_values.csv + owner_absolute_inputs.csv';
            catch err
                sar.reason = sprintf('SAR owner engineering baseline unavailable: %s', err.message);
            end
        end

        function s = provOf(b)
            if ~isfield(b, 'pattern') || isempty(b.pattern)
                s = '';
                if isfield(b, 'status') && strcmp(b.status, 'BOUND'); s = rfscreen.psd.SarOwnerPattern.PROVENANCE; end
                return;
            end
            s = sprintf('%s; %s', b.pattern.provenance, b.pattern.patternClass());
            if b.pattern.isInstalled(); s = [s '; installedSource=' b.pattern.installedSource]; end
        end

    end
end
