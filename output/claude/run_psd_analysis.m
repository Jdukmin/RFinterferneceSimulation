1;  % Octave script with local functions -- RFI split into blocker / victim-band PSD / receiver stages
% =============================================================================================
% A. FUNDAMENTAL_OOB_BLOCKER      : blocker port power [dBm] at the TX carrier (from pair_results.csv,
%                                   unchanged numbers) -> oob_blocking_results.csv
% B. VICTIM_BAND_EMISSION_PSD     : PSD_port(f) = PSD_TX(f) - L_chain(f) + C_EM(f) over the WHOLE victim
%                                   tuning band, C_EM from CST responses AT THE VICTIM FREQUENCY
%                                   -> victim_band_psd_results.csv, psd_pair_summary.csv
% C. RECEIVER_INTEGRATED          : I_rx = int PSD |H|^2 df over the actual RX channel (2nd stage)
%                                   -> receiver_integrated_results.csv
% Inputs: data/rfi_psd/{receiver_baseline,tx_emission_masks,tx_chain_losses}.csv,
%         data/antenna_port_response_cst (CST victim-band responses), results/pair_results.csv.
% Run after run_rfi_analysis.m:
%   octave-cli --no-gui --norc --eval "run('output/claude/run_psd_analysis.m')"
% =============================================================================================

function logm(fid, varargin)
    s = sprintf(varargin{:}); fprintf(fid, '%s\n', s); fprintf('%s\n', s);
end

function s = csvnum(x)
    if ischar(x); s = x; return; end
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

% ------------------------------------------------------------------------------------------------
here = fileparts(mfilename('fullpath'));
if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'src')); addpath(fullfile(here, 'code'));
outDir = fullfile(here, 'results');
logf = fopen(fullfile(outDir, 'psd_run_log.txt'), 'w');
logm(logf, 'RFI blocker / victim-band PSD / receiver run %s (GNU Octave %s)', datestr(now, 'yyyy-mm-dd HH:MM:SS'), OCTAVE_VERSION);
[~, gitHead] = system(sprintf('git -C "%s" rev-parse HEAD', repo));
logm(logf, 'Repository HEAD: %s', strtrim(gitHead));

P = rfscreen.psd.PsdMath; V = rfscreen.psd.VictimBandPsdPath; C = rfscreen.psd.VictimBandCoupling;
O = rfscreen.psd.OobBlockerPath; RB = rfscreen.psd.ReceiverBaseline; A = rfscreen.kaa.CstLocalFrameAdapter;
psdDir = fullfile(repo, 'data', 'rfi_psd');
B = RB.read(fullfile(psdDir, 'receiver_baseline.csv'));
masks = rfscreen.psd.EmissionMaskTable.read(fullfile(psdDir, 'tx_emission_masks.csv'));
chainT = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(psdDir, 'tx_chain_losses.csv'));
logm(logf, 'Inputs: %d receiver baselines, %d TX emission-mask rows, %d TX chain-loss rows', numel(B), numel(masks), chainT.nRows);
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
getResp = @(fam, band) rfscreen.psd.BandResponse.fromRepository(repo, fam, band, prov);
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

% =========================== A. fundamental OOB blocker ===========================
obRows = {};
for i = 1:PR.nRows
    port = str2double(PR.oob_blocker_port_A_dbm{i});
    st = O.evaluate(port, NaN, NaN);
    status = st.status;
    if strcmp(PR.status{i}, 'NOT_EVALUATED'); status = 'NOT_EVALUATED (same antenna port: diplexer/T-R isolation missing)'; end
    fc = (str2double(PR.tx_band_lo_ghz{i}) + str2double(PR.tx_band_hi_ghz{i})) / 2 * 1e9;
    obRows{end+1} = {PR.case_id{i}, PR.tx_system{i}, PR.rx_system{i}, fc, str2double(PR.tx_power_dbm_at_antenna_input{i}), ...
        str2double(PR.s21_A_db{i}), port, str2double(PR.oob_blocker_port_B_dbm{i}), NaN, NaN, NaN, NaN, status, ...
        str2double(PR.screening_suppression_to_inband_limit_A_db{i}), PR.coupling_method{i}, PR.missing_reason{i}}; %#ok<AGROW>
end
writeTable(fullfile(outDir, 'oob_blocking_results.csv'), {'case_id', 'tx_system', 'rx_system', 'blocker_frequency_hz', 'tx_power_dbm', ...
    'coupling_db', 'blocker_port_dbm', 'blocker_port_ref_pattern_dbm', 'receiver_filter_rejection_db', 'post_filter_blocker_dbm', ...
    'blocking_limit_dbm', 'margin_db', 'status', 'screening_suppression_to_inband_limit_db (diagnostic only)', 'coupling_method', 'note'}, obRows);
logm(logf, 'A. OOB blocker rows: %d (blocker port powers copied unchanged from pair_results.csv)', numel(obRows));

% =========================== B. victim-band emission PSD ===========================
psdRows = {}; sumRows = {}; intRows = {};
for i = 1:PR.nRows
    cid = PR.case_id{i}; tx = PR.tx_system{i}; rx = PR.rx_system{i}; tm = PR.tx_mount{i}; rm = PR.rx_mount{i};
    rt = tmpl(rx); vband = bandOfRx.(rt); b = RB.lookup(B, rt); tt = tmpl(tx);
    tfam = famOfMount.(tm); rfam = famOfMount.(rm);
    carrier = str2double(PR.tx_power_dbm_at_antenna_input{i});
    f = RB.tuningSweep(b, nF);
    base = {cid, tx, rx, vband};
    if strcmp(tm, rm)
        psdRows{end+1} = [base, {NaN, 'BROADBAND_PSD', NaN, NaN, '', '', NaN, NaN, b.allowable_psd_dBmHz, NaN, NaN, NaN, ...
            'NOT_EVALUATED', 'same antenna port: TX noise in the RX band through the diplexer (diplexer isolation + TX noise PSD missing)'}]; %#ok<AGROW>
        sumRows{end+1} = [base, {tfam, rfam, NaN, NaN, NaN, NaN, NaN, NaN, b.allowable_psd_dBmHz, 'NOT_EVALUATED', 'same antenna port'}]; %#ok<AGROW>
        continue;
    end
    d = pos(rm) - pos(tm); dist = norm(d); u = d / dist;
    dT = A.bodyToLocal(Rbl(tm), u); dR = A.bodyToLocal(Rbl(rm), -u);
    rk = [rfam '/' vband]; if ~resp.isKey(rk); resp(rk) = getResp(rfam, vband); end
    rr = resp(rk);
    specs = rfscreen.psd.EmissionMaskTable.select(masks, tt, vband);
    chain = struct('filter_dB', NaN, 'post_dB', NaN);
    if strcmp(tfam, 'KA')
        % Ka victim-band emission: conducted post-filter PSD + KAA low-band response, or radiated EIRP PSD.
        % The KAA Ka-band reflector pattern is NOT re-used at S/L/X (no extrapolation).
        txSrc = 'NOT_AVAILABLE: KAA response at the victim band not computed (Ka reflector pattern not re-used)';
        if rr.isAvailable()
            cr = arrayfun(@(x) C.patternRoute([], rr, vband, x, dT, dR, dist, false).coupling_dB, f);
            rxSrc = sprintf('CST %s %s/%s RealizedGain', rr.cstCase, rfam, vband);
            stt = 'KA_EMISSION_REQUIRES_RADIATED_EIRP_PSD_OR_CONDUCTED_PSD_PLUS_KAA_LOWBAND_RESPONSE';
            why = 'G_rx - FSPL at the victim frequency is evaluated (coupling_rx_only_db) for use with a radiated EIRP PSD; no Ka TX emission data';
        else
            cr = NaN(1, nF); rxSrc = [rr.status ': ' rr.reason]; stt = 'INPUT_MISSING'; why = rr.reason;
        end
        for k = 1:nF
            psdRows{end+1} = [base, {f(k), 'BROADBAND_PSD', NaN, NaN, txSrc, rxSrc, NaN, cr(k), b.allowable_psd_dBmHz, NaN, NaN, ...
                b.allowable_psd_dBmHz - cr(k), stt, [why ' | max_tx_eirp_psd column = allowable - (G_rx - FSPL)']}]; %#ok<AGROW>
        end
        sumRows{end+1} = [base, {'KA', rfam, NaN, NaN, NaN, NaN, NaN, min(b.allowable_psd_dBmHz - cr), b.allowable_psd_dBmHz, stt, why}]; %#ok<AGROW>
        continue;
    end
    tk = [tfam '/' vband]; if ~resp.isKey(tk); resp(tk) = getResp(tfam, vband); end
    tr = resp(tk);
    txSrc = sprintf('CST %s %s/%s RealizedGain', tr.cstCase, tfam, vband); if ~tr.isAvailable(); txSrc = [tr.status ': ' tr.reason]; end
    rxSrc = sprintf('CST %s %s/%s RealizedGain', rr.cstCase, rfam, vband); if ~rr.isAvailable(); rxSrc = [rr.status ': ' rr.reason]; end
    if ~(tr.isAvailable() && rr.isAvailable())
        why = strjoin({tr.reason, rr.reason}, ' | ');
        psdRows{end+1} = [base, {NaN, 'BROADBAND_PSD', NaN, NaN, txSrc, rxSrc, NaN, NaN, b.allowable_psd_dBmHz, NaN, NaN, NaN, ...
            'COUPLING_INPUT_MISSING', why}]; %#ok<AGROW>
        sumRows{end+1} = [base, {tfam, rfam, NaN, NaN, NaN, NaN, NaN, NaN, b.allowable_psd_dBmHz, 'COUPLING_INPUT_MISSING', why}]; %#ok<AGROW>
        continue;
    end
    cs = arrayfun(@(x) C.patternRoute(tr, rr, vband, x, dT, dR, dist, true), f);
    cE = [cs.coupling_dB];
    R = V.evaluate(f, cE, b.allowable_psd_dBmHz, specs, carrier, chain);
    for k = 1:nF
        psdRows{end+1} = [base, {f(k), R.emission_type, R.tx_psd_dBmHz(k), R.chain_dB(k), sprintf('%s: %.2f dBi', txSrc, cs(k).gtx_dBi), ...
            sprintf('%s: %.2f dBi', rxSrc, cs(k).grx_dBi), cE(k), NaN, R.allowable_dBmHz(k), R.port_psd_dBmHz(k), R.margin_dB(k), ...
            R.max_tx_psd_at_antenna_port_dBmHz(k), R.status{k}, ...
            'C_EM = Gtx(f) + Grx(f) - FSPL(f) at the victim frequency (RealizedGain: mismatch included once); TX emission mask: none in tx_emission_masks.csv'}]; %#ok<AGROW>
    end
    [cmax, km] = max(cE);
    sumRows{end+1} = [base, {tfam, rfam, min(cE), cmax, f(km), min(R.max_tx_psd_at_antenna_port_dBmHz), ...
        min(R.max_tx_psd_at_antenna_port_dBmHz) - carrier, NaN, b.allowable_psd_dBmHz, R.status{km}, ...
        'coupling evaluated over the whole tuning band; TX emission mask missing -> victim-port PSD not evaluated'}]; %#ok<AGROW>
    % C. receiver-integrated (2nd stage): needs the victim-port PSD inside the channel
    intRows{end+1} = {cid, tx, rx, b.channel_fc_Hz, b.integration_bw_Hz, b.integration_bw_prov, b.rx_filter_model, NaN, ...
        b.noise_psd_dBmHz + 10 * log10(b.integration_bw_Hz), b.allowable_integrated_dBm, NaN, NaN, NaN, ...
        'NOT_EVALUATED_NO_VICTIM_PORT_PSD (TX emission mask missing)'}; %#ok<AGROW>
end

% reference cross-check (other-satellite S -> L example): -120 dBm/Hz, 60 dB filter, GPS -178 dBm/Hz
bG = RB.lookup(B, 'GPS_L1_RX');
ref = {rfscreen.psd.EmissionSpec('REF_S_TX', 'FILTER_INPUT', 2.25e9, 'L1', bG.channel_fc_Hz, 'BROADBAND_PSD', -120, 'dBm/Hz', NaN, ...
    'PRE_FILTER', 'REFERENCE_CROSSCHECK (other satellite; coupling folded into the PSD)')};
for flt = [0 60]
    Rr = V.evaluate(bG.channel_fc_Hz, 0, bG.allowable_psd_dBmHz, ref, NaN, struct('filter_dB', flt, 'post_dB', 0));
    psdRows{end+1} = {'REFERENCE_CROSSCHECK_S_TO_L', 'REF_S_TX', 'GPS_L1_RX', 'L1', bG.channel_fc_Hz, 'BROADBAND_PSD', -120, flt, ...
        'REFERENCE (coupling folded into the -120 dBm/Hz victim-band PSD)', 'REFERENCE', 0, NaN, bG.allowable_psd_dBmHz, ...
        Rr.port_psd_dBmHz, Rr.margin_dB, NaN, Rr.status{1}, sprintf('filter %d dB: required PSD suppression %.1f dB', flt, Rr.required_psd_suppression_dB)}; %#ok<AGROW>
    [fc, H2] = RB.channelSamples(bG, 201);
    I = P.integrate(fc, Rr.port_psd_dBmHz * ones(size(fc)), H2);
    nI = bG.noise_psd_dBmHz + 10 * log10(bG.integration_bw_Hz);
    intRows{end+1} = {'REFERENCE_CROSSCHECK_S_TO_L', 'REF_S_TX', 'GPS_L1_RX', bG.channel_fc_Hz, bG.integration_bw_Hz, bG.integration_bw_prov, ...
        bG.rx_filter_model, I, nI, bG.allowable_integrated_dBm, I - nI, NaN, NaN, ...
        sprintf('REFERENCE filter %d dB: I/N %.1f dB (C/N0, J/S need the receiver model)', flt, I - nI)}; %#ok<AGROW>
    logm(logf, 'Reference S->L: filter %2d dB -> %.1f dBm/Hz, margin %+.1f dB (%s); I = %.1f dBm in %.2f MHz, I/N = %.1f dB', ...
        flt, Rr.port_psd_dBmHz, Rr.margin_dB, Rr.status{1}, I, bG.integration_bw_Hz / 1e6, I - nI);
end

writeTable(fullfile(outDir, 'victim_band_psd_results.csv'), {'case_id', 'tx_system', 'rx_system', 'victim_band', 'frequency_hz', ...
    'emission_type', 'tx_emission_psd_dbm_hz', 'tx_chain_loss_db', 'tx_gain_or_source', 'rx_gain_or_source', 'coupling_db', ...
    'coupling_rx_only_db', 'allowable_psd_dbm_hz', 'victim_port_psd_dbm_hz', 'psd_margin_db', 'max_tx_psd_at_antenna_port_dbm_hz', ...
    'status', 'provenance'}, psdRows);
writeTable(fullfile(outDir, 'psd_pair_summary.csv'), {'case_id', 'tx_system', 'rx_system', 'victim_band', 'tx_family', 'rx_family', ...
    'coupling_min_db', 'coupling_max_db', 'frequency_of_max_coupling_hz', 'min_max_tx_psd_at_antenna_port_dbm_hz', ...
    'min_max_tx_psd_rel_carrier_dbc_hz', 'min_max_tx_eirp_psd_dbm_hz', 'allowable_psd_dbm_hz', 'status', 'note'}, sumRows);
writeTable(fullfile(outDir, 'receiver_integrated_results.csv'), {'case_id', 'tx_system', 'rx_system', 'channel_fc_hz', ...
    'integration_bw_hz', 'integration_bw_prov', 'rx_filter_model', 'I_rx_dbm', 'noise_in_bw_dbm', 'allowable_integrated_dbm', ...
    'I_over_N_db', 'C_over_N0_dbhz', 'J_over_S_db', 'status'}, intRows);
st = cellfun(@(r) r{end-1}, sumRows, 'UniformOutput', false);
[u, ~, j] = unique(st);
for k = 1:numel(u); logm(logf, 'B. victim-band pairs %-80s %d', u{k}, sum(j == k)); end
logm(logf, 'Rows: PSD %d, pair summary %d, integrated %d, receiver baseline %d', numel(psdRows), numel(sumRows), numel(intRows), numel(rbRows));
fclose(logf);
