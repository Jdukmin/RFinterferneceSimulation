1;  % Octave script with local functions -- Task 1: S-TC TX (legacy id S_TM_TX) victim-band PSD incl. GPS L2/L5 rescaling
% =============================================================================================
% Source  : ITU RR AP3 / SM.329 spurious, 5 W -> -49.0206 dBm/Hz at the antenna port (data/rfi_psd/stc_itu_spurious_source.csv)
% L1/S/ISL: CST RealizedGain of the S antenna at the victim frequency (validated route, unchanged)
% L2/L5   : PORT_MISMATCH_RESCALED_LBAND -- unreliable RealizedGain NOT used; accepted-power Gain envelope (S L1+L2 Gain cuts)
%           + OWNER_ENGINEERING_BOUND rescaling -10 dB (data/rfi_psd/tx_port_mismatch_rescaling.csv)
%   PSD_victim = PSD_ITU + R_mismatch + G_tx(f_v) - FSPL + G_rx(f_v) - L_filter           [dBm/Hz]
%   required_additional_suppression = max(0, PSD_victim(0 dB filter) - PSD_allowable)       [dB]
% Filter scenarios FILTER_0/40/60/70/80DB (screening, not design values). Design target = minimum required + 10 dB reserve,
% rounded up to a 10 dB step (planning convention, not a filter guarantee).
%   octave-cli --no-gui --norc --eval "run('output/claude/run_stc_lband_rescaling.m')"
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

function v = nmax(x)
    x = x(~isnan(x)); if isempty(x); v = NaN; else; v = max(x); end
end

function v = nmin(x)
    x = x(~isnan(x)); if isempty(x); v = NaN; else; v = min(x); end
end

function t = designTarget(req)
    if isnan(req); t = NaN; else; t = ceil((req + 10) / 10 - 1e-9) * 10; end
end

function s = firstPass(atten, minMargin)
    k = find(minMargin >= 0, 1);
    if isempty(k); s = sprintf('NONE (> %g dB)', max(atten)); else; s = sprintf('%g dB', atten(k)); end
    if all(isnan(minMargin)); s = 'NOT_EVALUATED'; end
end

% ------------------------------------------------------------------------------------------------
here = fileparts(mfilename('fullpath'));
if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'src')); addpath(fullfile(here, 'code'));
outDir = fullfile(here, 'results');
logf = fopen(fullfile(outDir, 'stc_run_log.txt'), 'w');
pv = rfi_provenance(repo, outDir, 'run_stc_lband_rescaling.m', 'Task 1 S-TC TX (legacy S_TM_TX) incl. L2/L5 port-mismatch rescaling');
logm(logf, 'S-TC TX run %s (GNU Octave %s); analysis base commit %s, working tree %s', pv.run_time, OCTAVE_VERSION, ...
    pv.analysis_base_commit, pv.working_tree);

P = rfscreen.psd.PsdMath; V = rfscreen.psd.VictimBandPsdPath; RB = rfscreen.psd.ReceiverBaseline;
A = rfscreen.kaa.CstLocalFrameAdapter; PM = rfscreen.psd.PortMismatchRescaledResponse;
SD = rfscreen.spacecraft.SpacecraftDataReader;
psdDir = fullfile(repo, 'data', 'rfi_psd');
B = RB.read(fullfile(psdDir, 'receiver_baseline.csv'));
masks = rfscreen.psd.EmissionMaskTable.read(fullfile(psdDir, 'stc_itu_spurious_source.csv'));
FS = rfscreen.psd.FilterScenario.read(fullfile(psdDir, 'filter_scenarios.csv'));
att = cellfun(@(f) f.atten_dB, FS);
RS = SD.readTable(fullfile(psdDir, 'tx_port_mismatch_rescaling.csv'));
prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));
T = SD.readTable(fullfile(rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir(), 'rf_systems.csv'));
carrier = str2double(T.tx_power_dbm{find(strcmp(T.system_id, 'S_TM_TX@SBA_NADIR'), 1)});
logm(logf, 'S-TC TX (legacy id S_TM_TX) carrier %.4f dBm; ITU source rows %d; filter scenarios %s', carrier, numel(masks), ...
    strjoin(cellfun(@(f) f.id, FS, 'UniformOutput', false), ' '));

% L2/L5 rescaled responses and the kept-but-unused CST values
resc = containers.Map(); unRows = {};
for r = 1:RS.nRows
    if ~strcmp(RS.tx_system{r}, 'S_TM_TX'); continue; end
    vb = RS.victim_band{r}; rdb = str2double(RS.rescaling_db{r});
    m = PM.fromRepository(repo, RS.envelope_family{r}, strsplit(RS.envelope_bands{r}, ';'), rdb, prov);
    resc(vb) = m;
    u = PM.unreliableStatus(repo, 'S', vb, prov);
    unRows{end+1} = {'S-TC TX (legacy id S_TM_TX)', vb, u.status, u.peak_dBi, sprintf('%.4f;', u.acceptedFractions), 'NO (excluded from primary)', ...
        PM.ROUTE, m.peakEnvelope_dBi(), rdb, m.peakEnvelope_dBi() + rdb, strjoin(m.envelopeSources, ';'), RS.provenance{r}}; %#ok<AGROW>
    logm(logf, '%s: unreliable CST RealizedGain peak %.2f dBi kept unused; envelope peak %.2f dBi (%s) + %g dB -> %.2f dBi', vb, u.peak_dBi, ...
        m.peakEnvelope_dBi(), strjoin(m.envelopeSources, ' '), rdb, m.peakEnvelope_dBi() + rdb);
end
writeTable(fullfile(outDir, 'stc_unreliable_cst_kept.csv'), {'attacker', 'victim_band', 'cst_realized_gain_status', ...
    'cst_realized_gain_peak_dbi', 'accepted_power_fractions', 'used_in_primary', 'replacement_route', 'accepted_gain_envelope_peak_dbi', ...
    'port_mismatch_rescaling_db', 'effective_tx_gain_peak_dbi', 'envelope_sources', 'rescaling_provenance'}, unRows);

model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
pos = containers.Map(); Rbl = containers.Map();
for i = 1:numel(model.installationRecords)
    rc = model.installationRecords(i); pn = model.panels(strcmp({model.panels.id}, rc.panelId));
    pos(rc.antennaId) = rc.position_m(:); Rbl(rc.antennaId) = A.fixedMount(pn.normal_B);
end
victims = { ...   % receiver template, mount, family, band, role name
    'GPS_L1_RX', 'GPSA_1', 'L', 'L1', 'GPS RX'; 'GPS_L1_RX', 'GPSA_2', 'L', 'L1', 'GPS RX'; ...
    'GPS_L2_RX', 'GPSA_1', 'L', 'L2', 'GPS RX'; 'GPS_L2_RX', 'GPSA_2', 'L', 'L2', 'GPS RX'; ...
    'GPS_L5_RX', 'GPSA_1', 'L', 'L5', 'GPS RX'; 'GPS_L5_RX', 'GPSA_2', 'L', 'L5', 'GPS RX'; ...
    'S_TC_RX', 'SBA_NADIR', 'S', 'S_TC', 'S-TM RX (legacy id S_TC_RX)'; 'S_TC_RX', 'SBA_ZENITH', 'S', 'S_TC', 'S-TM RX (legacy id S_TC_RX)'; ...
    'ISL_X_RX', 'ISL', 'ISL', 'ISL', 'ISL RX'; 'SAR_X_RX', 'SAR_ANT', 'SAR', 'SAR', 'SAR RX'};
nF = 21; resp = containers.Map(); psdRows = {}; sumRows = {}; desRows = {};
getResp = @(fam, vb) rfscreen.psd.BandResponse.fromRepository(repo, fam, vb, prov);
for tm = {'SBA_NADIR', 'SBA_ZENITH'}
    tx = ['S_TM_TX@' tm{1}];
    for q = 1:size(victims, 1)
        rt = victims{q, 1}; rm = victims{q, 2}; rfam = victims{q, 3}; vb = victims{q, 4};
        if strcmp(rm, tm{1}); continue; end                     % same antenna port: diplexer data missing
        b = RB.lookup(B, rt); f = RB.tuningSweep(b, nF);
        d = pos(rm) - pos(tm{1}); dist = norm(d); u = d / dist;
        dT = A.bodyToLocal(Rbl(tm{1}), u); dR = A.bodyToLocal(Rbl(rm), -u);
        rk = [rfam '/' vb];
        if ~resp.isKey(rk)
            try; resp(rk) = getResp(rfam, vb); catch err; resp(rk) = rfscreen.psd.BandResponse.missing(rfam, vb, err.message); end
        end
        rr = resp(rk);
        isResc = resc.isKey(vb);
        if isResc
            m = resc(vb); route = PM.ROUTE; conf = PM.CONFIDENCE; rdb = m.rescale_dB;
            gtx = m.envelopeGainAt(dT) * ones(1, nF);
            txSrc = sprintf('accepted-power Gain envelope (%s) + %g dB %s', strjoin(m.envelopeSources, ' '), rdb, PM.PROVENANCE);
        else
            tk = ['S/' vb]; if ~resp.isKey(tk); resp(tk) = getResp('S', vb); end
            tr = resp(tk); route = 'CST_REALIZED_GAIN'; conf = 'SIMULATION (CST RealizedGain)'; rdb = 0;
            gtx = NaN(1, nF);
            if tr.isAvailable(); for k = 1:nF; gtx(k) = tr.gainAt(vb, f(k), dT); end; end
            txSrc = ifelse(tr.isAvailable(), sprintf('CST %s S/%s RealizedGain', tr.cstCase, vb), [tr.status ': ' tr.reason]);
        end
        grx = NaN(1, nF);
        if rr.isAvailable(); for k = 1:nF; grx(k) = rr.gainAt(vb, f(k), dR); end; end
        fspl = P.fspl(f, dist);
        cpl = gtx + grx - fspl;                                 % coupling without the rescaling
        specs = rfscreen.psd.EmissionMaskTable.select(masks, 'S_TM_TX', vb);
        src = max(cellfun(@(s) s.psdDbmHz(carrier), specs));
        key = [tx '>' rt '@' rm];
        mm = NaN(1, numel(FS)); req0 = NaN; psd0 = NaN;
        for s = 1:numel(FS)
            R = V.evaluate(f, cpl + rdb, NaN(1, nF), b.allowable_psd_dBmHz, specs, carrier, FS{s}, NaN, false);
            st = R.status;
            if ~rr.isAvailable(); st(:) = {'VICTIM_RX_RESPONSE_MISSING'}; end
            for k = 1:nF
                psdRows{end+1} = {key, 'S-TC TX (legacy id S_TM_TX)', tx, victims{q, 5}, rt, rm, vb, f(k), route, src, rdb, src + rdb, ...
                    gtx(k), grx(k), fspl(k), cpl(k), FS{s}.id, R.filter_dB(k), R.port_psd_dBmHz(k), R.allowable_dBmHz(k), R.margin_dB(k), ...
                    R.required_add_supp_dB(k), st{k}}; %#ok<AGROW>
            end
            mm(s) = nmin(R.margin_dB);
            if s == 1; req0 = nmax(R.required_add_supp_dB); psd0 = nmax(R.port_psd_dBmHz); end
            sumRows{end+1} = {key, tx, rt, rm, vb, route, FS{s}.id, att(s), src, rdb, src + rdb, nmax(gtx), nmax(cpl), nmax(R.port_psd_dBmHz), ...
                b.allowable_psd_dBmHz, nmin(R.margin_dB), nmax(R.required_add_supp_dB), ifelse(rr.isAvailable(), ...
                ifelse(nmin(R.margin_dB) >= 0, 'PASS', 'FAIL'), 'VICTIM_RX_RESPONSE_MISSING')}; %#ok<AGROW>
        end
        desRows{end+1} = {key, 'S-TC TX (legacy id S_TM_TX)', tx, victims{q, 5}, rt, rm, vb, sprintf('%.4f-%.4f MHz', f(1) / 1e6, f(end) / 1e6), ...
            route, src, rdb, src + rdb, nmax(gtx), nmax(grx), nmin(fspl), nmax(cpl), psd0, b.allowable_psd_dBmHz, mm(1), req0, ...
            firstPass(att, mm), designTarget(req0), ifelse(rr.isAvailable(), conf, 'NOT_EVALUATED (victim response missing)'), txSrc, ...
            ifelse(rr.isAvailable(), sprintf('CST %s %s/%s RealizedGain', rr.cstCase, rfam, vb), [rr.status ': ' rr.reason])}; %#ok<AGROW>
        logm(logf, '%-38s %-4s %-30s src %.2f %+g -> %.2f dBm/Hz, C %7.2f dB, PSD %8.2f vs %.0f -> req %6.2f dB, first pass %s', key, vb, route, ...
            src, rdb, src + rdb, nmax(cpl), psd0, b.allowable_psd_dBmHz, req0, firstPass(att, mm));
    end
end
desHdr = {'pair', 'attacker', 'tx_system_legacy', 'victim_role', 'rx_receiver_legacy', 'rx_mount', 'victim_band', 'victim_frequency_range', ...
    'tx_route', 'itu_source_psd_dbm_hz', 'port_mismatch_rescaling_db', 'effective_tx_source_psd_dbm_hz', 'tx_gain_max_dbi', 'rx_gain_max_dbi', ...
    'fspl_min_db', 'coupling_max_db', 'victim_psd_0db_max_dbm_hz', 'allowable_psd_dbm_hz', 'margin_0db_db', 'required_additional_suppression_db', ...
    'first_passing_scenario', 'design_target_db', 'confidence', 'tx_response_source', 'rx_response_source'};
writeTable(fullfile(outDir, 'stc_filter_design.csv'), desHdr, desRows);
writeTable(fullfile(outDir, 'stc_pair_summary.csv'), {'pair', 'tx_system_legacy', 'rx_receiver_legacy', 'rx_mount', 'victim_band', 'tx_route', ...
    'filter_scenario_id', 'filter_attenuation_db', 'itu_source_psd_dbm_hz', 'port_mismatch_rescaling_db', 'effective_tx_source_psd_dbm_hz', ...
    'tx_gain_max_dbi', 'coupling_max_db', 'victim_psd_max_dbm_hz', 'allowable_psd_dbm_hz', 'psd_margin_min_db', ...
    'required_additional_suppression_max_db', 'status'}, sumRows);
writeTable(fullfile(outDir, 'stc_psd_results.csv'), {'pair', 'attacker', 'tx_system_legacy', 'victim_role', 'rx_receiver_legacy', 'rx_mount', ...
    'victim_band', 'frequency_hz', 'tx_route', 'itu_source_psd_dbm_hz', 'port_mismatch_rescaling_db', 'effective_tx_source_psd_dbm_hz', ...
    'tx_gain_dbi', 'rx_gain_dbi', 'fspl_db', 'coupling_db', 'filter_scenario_id', 'filter_attenuation_db', 'victim_psd_dbm_hz', ...
    'allowable_psd_dbm_hz', 'psd_margin_db', 'required_additional_suppression_db', 'status'}, psdRows);
logm(logf, 'Rows: design %d, pair summary %d, PSD %d, unreliable-kept %d', numel(desRows), numel(sumRows), numel(psdRows), numel(unRows));
fclose(logf);
