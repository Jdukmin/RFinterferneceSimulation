1;  % Octave script with local functions -- RFI: PRIMARY victim-band PSD / SECONDARY OOB blocker / receiver
% =============================================================================================
% PRIMARY  VICTIM_BAND_EMISSION_PSD : TX compliant source emission -> optional filter (scenario)
%          -> victim-band coupling (CST responses AT THE VICTIM FREQUENCY) -> victim-port PSD
%          -> allowable victim PSD -> margin / required additional suppression   [dBm/Hz, dB]
%          -> victim_band_psd_results.csv, psd_pair_summary.csv, rfi_analysis_readiness.csv
% SECONDARY SECONDARY_OOB_BLOCKER_ANALYSIS : blocker port power [dBm] at the TX carrier
%          (values from pair_results.csv, unchanged) -> oob_blocking_results.csv
% RECEIVER I_rx = int PSD |H|^2 df over the actual channel -> receiver_integrated_results.csv
% Inputs: data/rfi_psd/{receiver_baseline,tx_emission_masks,reference_scenarios,filter_scenarios,
%         tx_chain_losses}.csv, data/antenna_port_response_cst, results/pair_results.csv.
% No source emission value is created here: tx_emission_masks.csv is read as given (currently empty).
%   octave-cli --no-gui --norc --eval "run('output/claude/run_psd_analysis.m')"   (after run_rfi_analysis.m)
% =============================================================================================

function logm(fid, varargin)
    s = sprintf(varargin{:}); fprintf(fid, '%s\n', s); fprintf('%s\n', s);
end

function v = ifelse(c, a, b)
    if c; v = a; else; v = b; end
end

function s = csvnum(x)
    if ischar(x); s = x; return; end
    if islogical(x); x = double(x); end
    if isempty(x) || isnan(x); s = 'NaN'; elseif isinf(x); if x < 0; s = '-Inf'; else; s = 'Inf'; end
    else; s = sprintf('%.4f', x); end
end

function writeTable(path, header, rows)
    fid = fopen(path, 'w');
    fprintf(fid, '%s\n', strjoin(header, ','));
    for i = 1:numel(rows)
        r = rows{i}; c = cell(1, numel(r));
        for j = 1:numel(r); c{j} = csvnum(r{j}); end
        fprintf(fid, '%s\n', strjoin(strrep(c, ',', ';'), ','));
    end
    fclose(fid);
end

function T = readCsvSimple(path)
    L = strsplit(strrep(fileread(path), char(13), ''), char(10)); L = L(~cellfun(@isempty, strtrim(L)));
    h = regexp(L{1}, ',', 'split'); T = struct('nRows', numel(L) - 1);
    V = cellfun(@(x) regexp(x, ',', 'split'), L(2:end), 'UniformOutput', false);
    for j = 1:numel(h); T.(h{j}) = cellfun(@(v) v{j}, V, 'UniformOutput', false); end
end

function t = tmpl(sysId)
    t = regexprep(sysId, '@.*$', '');
end

function v = nmax(x)
    x = x(~isnan(x)); if isempty(x); v = NaN; else; v = max(x); end
end

function v = nmin(x)
    x = x(~isnan(x)); if isempty(x); v = NaN; else; v = min(x); end
end

function st = worstStatus(s)
    if any(strcmp(s, 'FAIL')); st = 'FAIL';
    elseif all(strcmp(s, 'PASS')); st = 'PASS';
    else; o = s(~strcmp(s, 'PASS') & ~strcmp(s, 'FAIL')); st = o{1}; end
end

% ------------------------------------------------------------------------------------------------
here = fileparts(mfilename('fullpath'));
if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'src')); addpath(fullfile(here, 'code'));
outDir = fullfile(here, 'results');
logf = fopen(fullfile(outDir, 'psd_run_log.txt'), 'w');
pv = rfi_provenance(repo, outDir, 'run_psd_analysis.m', 'primary victim-band PSD / secondary blocker / receiver');
logm(logf, 'RFI PSD-primary run %s (GNU Octave %s); analysis base commit %s, working tree %s', pv.run_time, OCTAVE_VERSION, ...
    pv.analysis_base_commit, pv.working_tree);

P = rfscreen.psd.PsdMath; V = rfscreen.psd.VictimBandPsdPath; C = rfscreen.psd.VictimBandCoupling;
O = rfscreen.psd.OobBlockerPath; RB = rfscreen.psd.ReceiverBaseline; A = rfscreen.kaa.CstLocalFrameAdapter;
psdDir = fullfile(repo, 'data', 'rfi_psd');
B = RB.read(fullfile(psdDir, 'receiver_baseline.csv'));
masks = rfscreen.psd.EmissionMaskTable.read(fullfile(psdDir, 'tx_emission_masks.csv'));
[refs, refX] = rfscreen.psd.EmissionMaskTable.read(fullfile(psdDir, 'reference_scenarios.csv'));
FS = rfscreen.psd.FilterScenario.read(fullfile(psdDir, 'filter_scenarios.csv'));
postT = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(psdDir, 'tx_chain_losses.csv'));
logm(logf, 'Inputs: %d receivers, %d mission source-emission rows, %d reference rows, %d filter scenarios (%s), %d post-filter loss rows', ...
    numel(B), numel(masks), numel(refs), numel(FS), strjoin(cellfun(@(f) f.id, FS, 'UniformOutput', false), ' '), postT.nRows);
prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));
PR = readCsvSimple(fullfile(outDir, 'pair_results.csv'));

model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
pos = containers.Map(); Rbl = containers.Map();
for i = 1:numel(model.installationRecords)
    rc = model.installationRecords(i); pn = model.panels(strcmp({model.panels.id}, rc.panelId));
    pos(rc.antennaId) = rc.position_m(:); Rbl(rc.antennaId) = A.fixedMount(pn.normal_B);
end
bandOfRx = struct('S_TC_RX', 'S_TC', 'GPS_L1_RX', 'L1', 'GPS_L2_RX', 'L2', 'GPS_L5_RX', 'L5', 'ISL_X_RX', 'ISL');
famOfMount = struct('SBA_NADIR', 'S', 'SBA_ZENITH', 'S', 'GPSA_1', 'L', 'GPSA_2', 'L', 'ISL', 'ISL', 'KAA_1', 'KA', 'KAA_2', 'KA');
resp = containers.Map();
nF = 21;

% =========================== receiver baseline (output echo) ===========================
rbRows = {};
for b = B
    rbRows{end+1} = {b.receiver, b.victim_band, sprintf('%.4f-%.4f MHz', b.tuning_lo_Hz / 1e6, b.tuning_hi_Hz / 1e6), b.tuning_prov, ...
        b.channel_fc_Hz / 1e6, b.integration_bw_Hz, b.integration_bw_prov, b.rx_filter_model, b.nf_dB, b.noise_psd_dBmHz, ...
        b.i_n_max_dB, b.allowable_psd_dBmHz, b.allowable_integrated_dBm, b.desired_signal_reference_dbm, b.desired_prov, ...
        'kT0 = -174 dBm/Hz (290 K convention)', b.nf_prov, b.note}; %#ok<AGROW>
end
writeTable(fullfile(outDir, 'receiver_baseline.csv'), {'receiver', 'victim_band', 'tuning_range', 'tuning_prov', 'channel_fc_mhz', ...
    'integration_bw_hz', 'integration_bw_prov', 'rx_filter_model', 'nf_db', 'noise_psd_dbm_hz', 'i_n_max_db', ...
    'allowable_interference_psd_dbm_hz', 'allowable_integrated_in_integration_bw_dbm', 'desired_signal_reference_dbm', ...
    'desired_prov', 'thermal_reference', 'nf_prov', 'note'}, rbRows);

% =========================== SECONDARY: fundamental OOB blocker ===========================
obRows = {}; blkAvail = containers.Map();
for i = 1:PR.nRows
    port = str2double(PR.oob_blocker_port_A_dbm{i});
    st = O.evaluate(port, NaN, NaN); status = st.status;
    if strcmp(PR.status{i}, 'NOT_EVALUATED'); status = 'NOT_EVALUATED (same antenna port: diplexer/T-R isolation missing)'; end
    blkAvail([PR.tx_system{i} '>' PR.rx_system{i}]) = isfinite(port);
    fc = (str2double(PR.tx_band_lo_ghz{i}) + str2double(PR.tx_band_hi_ghz{i})) / 2 * 1e9;
    obRows{end+1} = {PR.case_id{i}, O.CLASS, PR.tx_system{i}, PR.rx_system{i}, fc, str2double(PR.tx_power_dbm_at_antenna_input{i}), ...
        str2double(PR.s21_A_db{i}), port, str2double(PR.oob_blocker_port_B_dbm{i}), NaN, NaN, NaN, NaN, status, ...
        str2double(PR.screening_suppression_to_inband_limit_A_db{i}), PR.coupling_method{i}, PR.missing_reason{i}}; %#ok<AGROW>
end
writeTable(fullfile(outDir, 'oob_blocking_results.csv'), {'case_id', 'analysis_class', 'tx_system', 'rx_system', 'blocker_frequency_hz', ...
    'tx_power_dbm', 'coupling_db', 'blocker_port_dbm', 'blocker_port_ref_pattern_dbm', 'receiver_filter_rejection_db', ...
    'post_filter_blocker_dbm', 'blocking_limit_dbm', 'margin_db', 'status', 'screening_suppression_to_inband_limit_db_DIAGNOSTIC_ONLY', ...
    'coupling_method', 'note'}, obRows);
logm(logf, 'SECONDARY blocker rows: %d (values copied unchanged from pair_results.csv; no PASS/FAIL)', numel(obRows));

% =========================== PRIMARY: victim-band PSD ===========================
psdRows = {}; sumRows = {}; intRows = {}; rdy = containers.Map(); rdyOrder = {};
for i = 1:PR.nRows
    cid = PR.case_id{i}; tx = PR.tx_system{i}; rx = PR.rx_system{i}; tm = PR.tx_mount{i}; rm = PR.rx_mount{i};
    rt = tmpl(rx); vband = bandOfRx.(rt); b = RB.lookup(B, rt); tt = tmpl(tx);
    tfam = famOfMount.(tm); rfam = famOfMount.(rm); isKa = strcmp(tfam, 'KA');
    carrier = str2double(PR.tx_power_dbm_at_antenna_input{i});
    f = RB.tuningSweep(b, nF); frange = sprintf('%.4f-%.4f MHz', f(1) / 1e6, f(end) / 1e6);
    specs = rfscreen.psd.EmissionMaskTable.select(masks, tt, vband);
    key = [tx '>' rx];
    if ~rdy.isKey(key); rdyOrder{end+1} = key; end %#ok<AGROW>
    if strcmp(tm, rm)
        rdy(key) = {tx, rx, vband, 'NO', ifelse(isempty(specs), 'NO', 'YES'), 'NO', 'NO', 'NO', 'NOT_APPLICABLE_SAME_PORT', ...
            'diplexer / T-R isolation and TX noise PSD in the RX band (same antenna port)'};
        continue;
    end
    d = pos(rm) - pos(tm); dist = norm(d); u = d / dist;
    dT = A.bodyToLocal(Rbl(tm), u); dR = A.bodyToLocal(Rbl(rm), -u);
    rk = [rfam '/' vband]; if ~resp.isKey(rk); resp(rk) = rfscreen.psd.BandResponse.fromRepository(repo, rfam, vband, prov); end
    rr = resp(rk);
    if isKa
        tr = rfscreen.psd.BandResponse.missing('KA', vband, ...
            'KAA radiation response at the victim band not computed (26 GHz reflector pattern is not extrapolated)');
    else
        tk = [tfam '/' vband]; if ~resp.isKey(tk); resp(tk) = rfscreen.psd.BandResponse.fromRepository(repo, tfam, vband, prov); end
        tr = resp(tk);
    end
    cRad = NaN(1, nF); cCond = NaN(1, nF); gtx = NaN(1, nF); grx = NaN(1, nF);
    if rr.isAvailable()
        for k = 1:nF
            c = C.patternRoute([], rr, vband, f(k), dT, dR, dist, false); cRad(k) = c.coupling_dB; grx(k) = c.grx_dBi;
            if tr.isAvailable()
                c = C.patternRoute(tr, rr, vband, f(k), dT, dR, dist, true); cCond(k) = c.coupling_dB; gtx(k) = c.gtx_dBi;
            end
        end
    end
    txSrc = ifelse(tr.isAvailable(), sprintf('CST %s %s/%s RealizedGain', tr.cstCase, tfam, vband), [tr.status ': ' tr.reason]);
    rxSrc = ifelse(rr.isAvailable(), sprintf('CST %s %s/%s RealizedGain', rr.cstCase, rfam, vband), [rr.status ': ' rr.reason]);
    % readiness (main path needs victim-band responses only; blocker-band mesh limits do not matter)
    vca = 'NO'; if rr.isAvailable() && tr.isAvailable(); vca = 'YES'; elseif rr.isAvailable(); vca = 'RX_ONLY (radiated EIRP route)'; end
    miss = {};
    if ~rr.isAvailable(); miss{end+1} = rr.reason; end %#ok<AGROW>
    if ~isKa && ~tr.isAvailable(); miss{end+1} = tr.reason; end %#ok<AGROW>
    if isempty(specs)
        if isKa; miss{end+1} = 'Ka source emission: RADIATED_EIRP_PSD in the victim band (or conducted PSD + KAA victim-band response)'; %#ok<AGROW>
        else; miss{end+1} = sprintf('%s source emission in %s (tx_emission_masks.csv)', tt, vband); end %#ok<AGROW>
    end
    if ~rr.isAvailable() || (~isKa && ~tr.isAvailable()); rst = 'COUPLING_INPUT_MISSING';
    elseif isKa && (isempty(specs) || ~specs{1}.isRadiated()); rst = 'KAA_RADIATED_PSD_OR_LOWBAND_RESPONSE_REQUIRED';
    elseif isempty(specs); rst = 'EMISSION_SPEC_MISSING';
    else; rst = 'READY_FOR_PSD_ANALYSIS'; end
    blk = 'NO'; if blkAvail.isKey(key) && blkAvail(key); blk = 'YES'; end
    rdy(key) = {tx, rx, vband, vca, ifelse(isempty(specs), 'NO', 'YES'), ifelse(postT.nRows > 0, 'PARTIAL', 'NO (filter scenarios only)'), ...
        ifelse(rr.isAvailable(), 'YES', 'NO'), blk, rst, strjoin(miss, ' | ')};
    srcStatus = ifelse(isempty(specs), 'SOURCE_EMISSION_MISSING', 'SOURCE_EMISSION_PROVIDED');
    srcPlane = ''; srcProv = '';
    if ~isempty(specs)
        srcPlane = specs{1}.referencePlane;
        srcProv = strjoin(unique(cellfun(@(s) [s.assumptionClass ':' s.standardOrSource], specs, 'UniformOutput', false)), ' | ');
    end
    for q = 1:numel(FS)
        R = V.evaluate(f, cCond, cRad, b.allowable_psd_dBmHz, specs, carrier, FS{q}, NaN, isKa);
        for k = 1:nF
            psdRows{end+1} = {cid, V.PATH, tx, rx, vband, f(k), 'BROADBAND_PSD', srcStatus, R.source_psd_dBmHz(k), R.plane, ...
                FS{q}.id, R.filter_dB(k), FS{q}.provenance, sprintf('%s: %.2f dBi', txSrc, gtx(k)), sprintf('%s: %.2f dBi', rxSrc, grx(k)), ...
                cCond(k), cRad(k), R.coupling_dB(k), R.port_psd_dBmHz(k), R.allowable_dBmHz(k), R.margin_dB(k), ...
                R.required_add_supp_dB(k), R.max_tx_psd_conducted_dBmHz(k), R.max_tx_eirp_psd_dBmHz(k), R.status{k}, ...
                strtrim([srcProv ' ' R.post_flag])}; %#ok<AGROW>
        end
        rs = ifelse(isempty(specs), rst, worstStatus(R.status));
        sumRows{end+1} = {cid, tx, rx, vband, frange, tfam, rfam, nmin(cCond), nmax(cCond), nmin(cRad), nmax(cRad), ...
            nmin(R.max_tx_psd_conducted_dBmHz), nmin(R.max_tx_psd_conducted_dBmHz) - carrier, nmin(R.max_tx_eirp_psd_dBmHz), ...
            srcStatus, nmax(R.source_psd_dBmHz), srcPlane, srcProv, FS{q}.id, FS{q}.label(), FS{q}.provenance, ...
            nmax(R.port_psd_dBmHz), b.allowable_psd_dBmHz, nmin(R.margin_dB), nmax(R.required_add_supp_dB), rs, rst}; %#ok<AGROW>
    end
    nI = b.noise_psd_dBmHz + 10 * log10(b.integration_bw_Hz);
    intRows{end+1} = {cid, tx, rx, b.channel_fc_Hz, b.integration_bw_Hz, b.integration_bw_prov, b.rx_filter_model, NaN, nI, ...
        b.allowable_integrated_dBm, NaN, NaN, NaN, 'NOT_EVALUATED_NO_VICTIM_PORT_PSD (source emission missing)'}; %#ok<AGROW>
end

% reference scenarios (same engine; coupling override; never mixed with mission rows)
for r = 1:numel(refs)
    e = refX{r}; b = RB.lookup(B, e.rx_receiver); f = RB.tuningSweep(b, nF); c0 = str2double(e.coupling_override_db);
    for q = 1:numel(FS)
        R = V.evaluate(f, c0 * ones(1, nF), NaN(1, nF), b.allowable_psd_dBmHz, refs(r), NaN, FS{q}, 0, false);
        for k = 1:nF
            psdRows{end+1} = {e.scenario_id, 'REFERENCE_SCENARIO', refs{r}.txSystem, e.rx_receiver, refs{r}.victimBand, f(k), 'BROADBAND_PSD', ...
                'REFERENCE_SOURCE', R.source_psd_dBmHz(k), R.plane, FS{q}.id, R.filter_dB(k), FS{q}.provenance, 'REFERENCE', 'REFERENCE', ...
                c0, NaN, R.coupling_dB(k), R.port_psd_dBmHz(k), R.allowable_dBmHz(k), R.margin_dB(k), R.required_add_supp_dB(k), ...
                R.max_tx_psd_conducted_dBmHz(k), NaN, R.status{k}, [refs{r}.assumptionClass ':' refs{r}.provenance]}; %#ok<AGROW>
        end
        sumRows{end+1} = {e.scenario_id, refs{r}.txSystem, e.rx_receiver, refs{r}.victimBand, sprintf('%.4f-%.4f MHz', f(1) / 1e6, f(end) / 1e6), ...
            'REFERENCE', 'REFERENCE', c0, c0, NaN, NaN, nmin(R.max_tx_psd_conducted_dBmHz), NaN, NaN, 'REFERENCE_SOURCE', ...
            nmax(R.source_psd_dBmHz), R.plane, [refs{r}.assumptionClass ':' refs{r}.standardOrSource], FS{q}.id, FS{q}.label(), ...
            FS{q}.provenance, nmax(R.port_psd_dBmHz), b.allowable_psd_dBmHz, nmin(R.margin_dB), nmax(R.required_add_supp_dB), ...
            worstStatus(R.status), 'REFERENCE_SCENARIO'}; %#ok<AGROW>
        [fc, H2] = RB.channelSamples(b, 201);
        I = P.integrate(fc, R.port_psd_dBmHz(1) * ones(size(fc)), H2); nI = b.noise_psd_dBmHz + 10 * log10(b.integration_bw_Hz);
        intRows{end+1} = {e.scenario_id, refs{r}.txSystem, e.rx_receiver, b.channel_fc_Hz, b.integration_bw_Hz, b.integration_bw_prov, ...
            b.rx_filter_model, I, nI, b.allowable_integrated_dBm, I - nI, NaN, NaN, sprintf('REFERENCE %s: I/N %.1f dB', FS{q}.id, I - nI)}; %#ok<AGROW>
        logm(logf, 'Reference %s %s: PSD %.1f dBm/Hz vs %.0f -> margin %+.1f dB (%s), required additional suppression %.1f dB, I/N %.1f dB', ...
            e.scenario_id, FS{q}.id, nmax(R.port_psd_dBmHz), b.allowable_psd_dBmHz, nmin(R.margin_dB), worstStatus(R.status), ...
            nmax(R.required_add_supp_dB), I - nI);
    end
end

writeTable(fullfile(outDir, 'victim_band_psd_results.csv'), {'case_id', 'analysis_class', 'tx_system', 'rx_system', 'victim_band', ...
    'frequency_hz', 'emission_type', 'source_emission_status', 'source_emission_psd_dbm_hz', 'source_emission_reference_plane', ...
    'filter_scenario_id', 'filter_attenuation_db', 'filter_provenance', 'tx_gain_or_source', 'rx_gain_or_source', ...
    'coupling_conducted_db', 'coupling_radiated_db', 'coupling_applied_db', 'victim_port_psd_dbm_hz', 'allowable_psd_dbm_hz', ...
    'psd_margin_db', 'required_additional_suppression_db', 'max_allowable_tx_psd_conducted_dbm_hz', ...
    'max_allowable_tx_eirp_psd_dbm_hz', 'status', 'provenance'}, psdRows);
writeTable(fullfile(outDir, 'psd_pair_summary.csv'), {'case_id', 'tx_system', 'rx_system', 'victim_band', 'victim_frequency_range', ...
    'tx_family', 'rx_family', 'coupling_conducted_min_db', 'coupling_conducted_max_db', 'coupling_radiated_min_db', ...
    'coupling_radiated_max_db', 'max_allowable_tx_psd_conducted_dbm_hz', 'max_allowable_tx_psd_conducted_dbc_hz', ...
    'max_allowable_tx_eirp_psd_dbm_hz', 'source_emission_status', 'source_emission_psd_dbm_hz', 'source_emission_reference_plane', ...
    'source_spec_provenance', 'filter_scenario_id', 'filter_attenuation_db', 'filter_provenance', 'victim_port_psd_dbm_hz', ...
    'allowable_psd_dbm_hz', 'psd_margin_db', 'required_additional_suppression_db', 'result_status', 'readiness_status'}, sumRows);
writeTable(fullfile(outDir, 'receiver_integrated_results.csv'), {'case_id', 'tx_system', 'rx_system', 'channel_fc_hz', ...
    'integration_bw_hz', 'integration_bw_prov', 'rx_filter_model', 'I_rx_dbm', 'noise_in_bw_dbm', 'allowable_integrated_dbm', ...
    'I_over_N_db', 'C_over_N0_dbhz', 'J_over_S_db', 'status'}, intRows);
rRows = cellfun(@(k) rdy(k), rdyOrder, 'UniformOutput', false);
writeTable(fullfile(outDir, 'rfi_analysis_readiness.csv'), {'tx_system', 'rx_system', 'victim_band', 'victim_coupling_available', ...
    'tx_emission_spec_available', 'tx_filter_data_available', 'radiated_eirp_psd_supported', 'blocker_path_available', ...
    'readiness_status', 'missing_inputs'}, rRows);
st = cellfun(@(r) r{9}, rRows, 'UniformOutput', false);
[u, ~, j] = unique(st);
for k = 1:numel(u); logm(logf, 'readiness %-48s %d pairs', u{k}, sum(j == k)); end
logm(logf, 'Rows: PSD %d, pair summary %d, readiness %d, integrated %d, blocker %d', numel(psdRows), numel(sumRows), ...
    numel(rRows), numel(intRows), numel(obRows));
fclose(logf);
