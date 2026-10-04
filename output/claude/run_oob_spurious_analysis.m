1;  % Octave script -- Claude worker: OOB/spurious-standard-based victim-band PSD RFI analysis
% =============================================================================================
% Freeze point 8469e8903da83b6ebed014aae311f90855c31715 (shared engine src/+rfscreen/+psd unchanged).
% Source limits: output/claude/inputs/tx_emission_sources_claude.csv (RR AP3 primary, ECSS sensitivity).
% Couplings at the VICTIM frequency:
%   CST       : G_tx(f_v) + G_rx(f_v) - FSPL(f_v) from data/antenna_port_response_cst (simulation data)
%   BOUND     : where the TX antenna victim-band response is not available (KAA at S/L/X; S antenna at
%               L2/L5 with unreliable normalization) the TX gain is replaced by the Harrington maximum
%               directivity of the antenna's enclosing sphere, D = (ka)^2 + 2ka (physics bound, worst pointing,
%               perfect match) -- the 26 GHz KAA pattern is NOT used.
%   WR42 (Ka sensitivity, conditional): additional evanescent attenuation of a WR-42 section of length 2 lambda_c,
%               109.15 sqrt(1 - (f/fc)^2) dB (SM.329-13 recommends 2.5 condition); not verified for the KAA.
% Filter scenarios: data/rfi_psd/filter_scenarios.csv (FILTER_0/40/60/70/80DB, SCREENING_FILTER_SCENARIO).
% Outputs: output/claude/results/oob_spurious/*.csv
%   octave-cli --no-gui --norc --eval "run('output/claude/run_oob_spurious_analysis.m')"
% =============================================================================================

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
    fid = fopen(path, 'w'); fprintf(fid, '%s\n', strjoin(header, ','));
    for i = 1:numel(rows)
        r = rows{i}; c = cell(1, numel(r));
        for j = 1:numel(r); c{j} = csvnum(r{j}); end
        fprintf(fid, '%s\n', strjoin(strrep(c, ',', ';'), ','));
    end
    fclose(fid);
end

function logm(fid, varargin)
    s = sprintf(varargin{:}); fprintf(fid, '%s\n', s); fprintf('%s\n', s);
end

function T = readCsvSimple(path)
    L = strsplit(strrep(fileread(path), char(13), ''), char(10)); L = L(~cellfun(@isempty, strtrim(L)));
    h = regexp(L{1}, ',', 'split'); T = struct('nRows', numel(L) - 1);
    V = cellfun(@(x) regexp(x, ',', 'split'), L(2:end), 'UniformOutput', false);
    for j = 1:numel(h); T.(h{j}) = cellfun(@(v) v{j}, V, 'UniformOutput', false); end
end

function D = harringtonDbi(f_Hz, a_m)
    %HARRINGTONDBI Maximum directivity of a normal antenna enclosed in a sphere of radius a (Harrington 1960).
    ka = 2 * pi * f_Hz / 299792458 * a_m; D = 10 * log10(ka .^ 2 + 2 * ka);
end

function A = wr42EvanescentDb(f_Hz)
    %WR42EVANESCENTDB Attenuation of a WR-42 section of length 2 lambda_c below the TE10 cut-off (dB).
    fc = 299792458 / (2 * 10.668e-3);
    A = 20 / log(10) * 4 * pi * sqrt(max(0, 1 - (f_Hz / fc) .^ 2));
end

function b = ap3Boundary(fc, BN)
    %AP3BOUNDARY RR AP3 Annex 1 Table 1 separation (Hz) between centre frequency and spurious domain.
    T = [1e9 3e9 100e3 250e3 50e6; 3e9 10e9 100e3 250e3 100e6; 10e9 15e9 300e3 750e3 250e6; ...
         15e9 26e9 500e3 1.25e6 500e6; 26e9 Inf 1e6 2.5e6 500e6];
    r = find(fc > T(:, 1) & fc <= T(:, 2), 1);
    if BN < T(r, 3); b = T(r, 4); elseif BN > T(r, 5); b = 1.5 * BN + T(r, 5); else; b = 2.5 * BN; end
end

% ------------------------------------------------------------------------------------------------
here = fileparts(mfilename('fullpath'));
if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'src')); addpath(fullfile(here, 'code'));
outDir = fullfile(here, 'results', 'oob_spurious'); if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
logf = fopen(fullfile(outDir, 'run_log.txt'), 'w');
pv = rfi_provenance(repo, fullfile(here, 'results'), 'run_oob_spurious_analysis.m', 'Claude OOB/spurious standard analysis (freeze 8469e89)');
logm(logf, 'Claude OOB/spurious RFI run %s (GNU Octave %s); analysis base commit %s, working tree %s', pv.run_time, ...
    OCTAVE_VERSION, pv.analysis_base_commit, pv.working_tree);

P = rfscreen.psd.PsdMath; V = rfscreen.psd.VictimBandPsdPath; C = rfscreen.psd.VictimBandCoupling;
RB = rfscreen.psd.ReceiverBaseline; A = rfscreen.kaa.CstLocalFrameAdapter;
B = RB.read(fullfile(repo, 'data', 'rfi_psd', 'receiver_baseline.csv'));
FS = rfscreen.psd.FilterScenario.read(fullfile(repo, 'data', 'rfi_psd', 'filter_scenarios.csv'));
[S, X] = rfscreen.psd.EmissionMaskTable.read(fullfile(here, 'inputs', 'tx_emission_sources_claude.csv'));
variantOf = cellfun(@(x) x.variant, X, 'UniformOutput', false);
prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));
PR = readCsvSimple(fullfile(here, 'results', 'pair_results.csv'));
RS = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir(), 'rf_systems.csv'));
logm(logf, 'Sources: %d rows (%s); filter scenarios %s', numel(S), strjoin(unique(variantOf), ' '), ...
    strjoin(cellfun(@(f) f.id, FS, 'UniformOutput', false), ' '));

model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
pos = containers.Map(); Rbl = containers.Map();
for i = 1:numel(model.installationRecords)
    rc = model.installationRecords(i); pn = model.panels(strcmp({model.panels.id}, rc.panelId));
    pos(rc.antennaId) = rc.position_m(:); Rbl(rc.antennaId) = A.fixedMount(pn.normal_B);
end
bandOfRx = struct('S_TC_RX', 'S_TC', 'GPS_L1_RX', 'L1', 'GPS_L2_RX', 'L2', 'GPS_L5_RX', 'L5', 'ISL_X_RX', 'ISL');
famOfMount = struct('SBA_NADIR', 'S', 'SBA_ZENITH', 'S', 'GPSA_1', 'L', 'GPSA_2', 'L', 'ISL', 'ISL', 'KAA_1', 'KA', 'KAA_2', 'KA');
% enclosing-sphere radii for the directivity bound
aKAA = sqrt(0.110 ^ 2 + (0.0922 / 2) ^ 2);      % KAA datasheet: D < 222 mm (220 used), height < 92.2 mm
aS = sqrt(0.0325 ^ 2 + (0.084 / 2) ^ 2);        % CST S surrogate: base 65 mm dia., 32 mm base + 52 mm helix
txInfo = struct('S_TM_TX', struct('fc', 2.25e9, 'BN', 2.7e6, 'P', 36.9897), 'ISL_X_TX', struct('fc', 10.6e9, 'BN', 20e6, 'P', 30), ...
    'KA_DLS_TX', struct('fc', 26.25e9, 'BN', 1500e6, 'P', 48.451));
resp = containers.Map(); nF = 21;

% ============ standards derivation tables ============
der = {};
for t = fieldnames(txInfo).'
    ti = txInfo.(t{1}); Pw = 10 ^ ((ti.P - 30) / 10);
    ap3 = min(43 + 10 * log10(Pw), 60); bnd = ap3Boundary(ti.fc, ti.BN);
    rows = {{'RR AP3 Table I (space stations)', 'PRIMARY_RR_AP3', ap3, 'BROADBAND_PSD (4 kHz ref. BW)', 4000}, ...
            {'ECSS-E-ST-50-05C Table 5-6', 'SENS_ECSS_50_05C', 60, 'BROADBAND_PSD (4 kHz ref. BW)', 4000}, ...
            {'RR AP3 Table I - discrete component', 'DISCRETE_RR_AP3', ap3, 'DISCRETE_SPUR (power in 4 kHz)', 4000}, ...
            {'CCSDS 401.0-B-32 rec. 2.4.16 (B-2 Oct 2004)', 'DISCRETE_CCSDS_2_4_16', 60, 'DISCRETE_SPUR (total power of a single spur)', NaN}};
    for r = rows
        q = r{1}; abs4k = ti.P - q{3};
        psd = NaN; if strncmp(q{4}, 'BROADBAND', 9); psd = abs4k - 10 * log10(q{5}); end
        der{end+1} = {t{1}, q{1}, q{2}, ti.fc, ti.BN, bnd, ti.P, Pw, 43 + 10 * log10(Pw), q{3}, abs4k, q{4}, q{5}, psd, ...
            ifelse(strncmp(q{2}, 'DISCRETE', 8), 'secondary (receiver channel)', 'PSD path')}; %#ok<AGROW>
    end
end
writeTable(fullfile(outDir, 'source_emission_derivation.csv'), {'tx_system', 'standard', 'variant', 'carrier_hz', ...
    'necessary_bw_hz_assumed', 'ap3_oob_spurious_boundary_offset_hz', 'carrier_power_dbm', 'carrier_power_w', '43_plus_10logP_db', ...
    'applied_attenuation_dbc', 'absolute_limit_dbm_in_ref_bw', 'emission_type', 'reference_bw_hz', 'broadband_equiv_psd_dbm_hz', 'use'}, der);
% harmonics / domain check
hrm = {};
for t = fieldnames(txInfo).'
    ti = txInfo.(t{1}); bnd = ap3Boundary(ti.fc, ti.BN);
    for b = B
        if strcmp(b.receiver, 'SAR_X_RX'); continue; end
        off = min(abs([b.tuning_lo_Hz b.tuning_hi_Hz] - ti.fc)); if ti.fc >= b.tuning_lo_Hz && ti.fc <= b.tuning_hi_Hz; off = 0; end
        n = 2:20; h = n * ti.fc; inb = n(h >= b.tuning_lo_Hz & h <= b.tuning_hi_Hz);
        hrm{end+1} = {t{1}, b.receiver, b.tuning_lo_Hz, b.tuning_hi_Hz, off, bnd, ifelse(off > bnd, 'SPURIOUS', 'OOB_OR_INBAND'), ...
            ifelse(isempty(inb), 'none', sprintf('%d ', inb))}; %#ok<AGROW>
    end
end
writeTable(fullfile(outDir, 'domain_and_harmonic_check.csv'), {'tx_system', 'victim_receiver', 'victim_lo_hz', 'victim_hi_hz', ...
    'min_offset_from_carrier_hz', 'ap3_spurious_boundary_offset_hz', 'domain', 'harmonic_orders_in_victim_band'}, hrm);

% ============ pair loop ============
pairs = {}; seen = containers.Map();
for i = 1:PR.nRows
    k = [PR.tx_system{i} '>' PR.rx_system{i}];
    if ~seen.isKey(k); seen(k) = 1; pairs{end+1} = i; end %#ok<AGROW>
end
freqRows = {}; sumRows = {}; spurRows = {};
variants = {'PRIMARY_RR_AP3', 'SENS_ECSS_50_05C', 'SENS_KAA_WR42_2LC'};
for ii = 1:numel(pairs)
    i = pairs{ii}; tx = PR.tx_system{i}; rx = PR.rx_system{i}; tm = PR.tx_mount{i}; rm = PR.rx_mount{i};
    rt = regexprep(rx, '@.*$', ''); tt = regexprep(tx, '@.*$', ''); vband = bandOfRx.(rt); b = RB.lookup(B, rt);
    tfam = famOfMount.(tm); rfam = famOfMount.(rm); isKa = strcmp(tfam, 'KA'); carrier = txInfo.(tt).P;
    f = RB.tuningSweep(b, nF);
    if strcmp(tm, rm)
        sumRows{end+1} = {tx, rx, vband, 'ALL', 'NOT_APPLICABLE_SAME_PORT', '', '', NaN, NaN, NaN, b.allowable_psd_dBmHz, NaN, NaN, ...
            '', '', '', '', '', '', 'same antenna port: diplexer isolation + TX noise PSD needed'}; %#ok<AGROW>
        continue;
    end
    d = pos(rm) - pos(tm); dist = norm(d); u = d / dist;
    dT = A.bodyToLocal(Rbl(tm), u); dR = A.bodyToLocal(Rbl(rm), -u);
    rk = [rfam '/' vband]; if ~resp.isKey(rk); resp(rk) = rfscreen.psd.BandResponse.fromRepository(repo, rfam, vband, prov); end
    rr = resp(rk);
    tr = rfscreen.psd.BandResponse.missing('KA', vband, 'KAA victim-band response not computed');
    if ~isKa
        tk = [tfam '/' vband]; if ~resp.isKey(tk); resp(tk) = rfscreen.psd.BandResponse.fromRepository(repo, tfam, vband, prov); end
        tr = resp(tk);
    end
    cRad = arrayfun(@(x) C.patternRoute([], rr, vband, x, dT, dR, dist, false).coupling_dB, f);
    if tr.isAvailable()
        cPrim = arrayfun(@(x) C.patternRoute(tr, rr, vband, x, dT, dR, dist, true).coupling_dB, f); route = sprintf('CST %s %s/%s + %s', ...
            tr.cstCase, tfam, vband, rr.cstCase);
    else
        aB = ifelse(isKa, aKAA, aS);
        cPrim = cRad + harringtonDbi(f, aB);
        route = sprintf('BOUND: Harrington D_max (a = %.1f mm) replaces %s victim-band gain (%s); rx %s', aB * 1e3, tfam, tr.status, rr.cstCase);
    end
    for v = variants
        if strcmp(v{1}, 'SENS_KAA_WR42_2LC')
            if ~isKa; continue; end
            src = 'PRIMARY_RR_AP3'; cUse = cPrim - wr42EvanescentDb(f); rUse = [route ' - WR-42 2 lambda_c evanescent (CONDITIONAL)'];
        else
            src = v{1}; cUse = cPrim; rUse = route;
        end
        sp = S(strcmp(variantOf, src)); sp = rfscreen.psd.EmissionMaskTable.select(sp, tt, vband);
        res = cell(1, numel(FS));
        for q = 1:numel(FS)
            R = V.evaluate(f, cUse, cRad, b.allowable_psd_dBmHz, sp, carrier, FS{q}, NaN, false);
            res{q} = R;
            for k = 1:nF
                freqRows{end+1} = {v{1}, tx, rx, vband, f(k), sp{1}.standardOrSource, R.source_psd_dBmHz(k), FS{q}.id, R.filter_dB(k), ...
                    cUse(k), R.port_psd_dBmHz(k), R.allowable_dBmHz(k), R.margin_dB(k), R.required_add_supp_dB(k), R.status{k}, rUse}; %#ok<AGROW>
            end
        end
        m0 = min(res{1}.margin_dB); req = max(res{1}.required_add_supp_dB);
        att = cellfun(@(r) r.filter_dB(1), res); st = cellfun(@(r) ifelse(all(strcmp(r.status, 'PASS')), 'PASS', 'FAIL'), res, 'UniformOutput', false);
        firstPass = 'NONE_UP_TO_80DB'; ip = find(strcmp(st, 'PASS'), 1); if ~isempty(ip); firstPass = FS{ip}.id; end
        [~, kw] = max(res{1}.port_psd_dBmHz);
        sumRows{end+1} = {tx, rx, vband, v{1}, ifelse(tr.isAvailable(), 'CST_EVALUATED', 'BOUNDED'), sp{1}.standardOrSource, ...
            X{find(strcmp(variantOf, src) & cellfun(@(s) strcmp(s.txSystem, tt) && strcmp(s.victimBand, vband), S), 1)}.clause, ...
            max(res{1}.source_psd_dBmHz), max(cUse), max(res{1}.port_psd_dBmHz), b.allowable_psd_dBmHz, m0, req, firstPass, ...
            st{2}, st{3}, st{4}, st{5}, sprintf('%.6g', f(kw) / 1e6), rUse}; %#ok<AGROW>
    end
    % discrete spur (secondary): a single tone at the limit, landing inside the victim channel
    nI = b.noise_psd_dBmHz + 10 * log10(b.integration_bw_Hz);
    for dv = {{'RR AP3 discrete component (power in 4 kHz)', -min(43 + 10 * log10(10 ^ ((carrier - 30) / 10)), 60)}, ...
              {'CCSDS 401 2.4.16 single spur total power', -60}}
        tone = carrier + dv{1}{2} + max(cPrim);
        spurRows{end+1} = {tx, rx, vband, dv{1}{1}, carrier + dv{1}{2}, max(cPrim), tone, b.integration_bw_Hz, b.allowable_integrated_dBm, ...
            b.allowable_integrated_dBm - tone, tone - nI, ifelse(tr.isAvailable(), 'CST_EVALUATED', 'BOUNDED'), ...
            'SECONDARY: applies only if a discrete spur falls inside the operating channel; not converted to dBm/Hz'}; %#ok<AGROW>
    end
end
writeTable(fullfile(outDir, 'victim_psd_results.csv'), {'variant', 'tx_system', 'rx_system', 'victim_band', 'frequency_hz', ...
    'standard', 'source_psd_dbm_hz', 'filter_scenario_id', 'filter_attenuation_db', 'coupling_db', 'victim_port_psd_dbm_hz', ...
    'allowable_psd_dbm_hz', 'psd_margin_db', 'required_additional_suppression_db', 'status', 'coupling_route'}, freqRows);
writeTable(fullfile(outDir, 'pair_margin_summary.csv'), {'tx_system', 'rx_system', 'victim_band', 'variant', 'coupling_basis', ...
    'standard', 'clause', 'source_psd_dbm_hz', 'coupling_max_db', 'victim_port_psd_dbm_hz_0db', 'allowable_psd_dbm_hz', ...
    'margin_0db', 'minimum_required_additional_suppression_db', 'first_passing_scenario', 'FILTER_40DB', 'FILTER_60DB', ...
    'FILTER_70DB', 'FILTER_80DB', 'worst_frequency_mhz', 'coupling_route'}, sumRows);
writeTable(fullfile(outDir, 'discrete_spur_check.csv'), {'tx_system', 'rx_system', 'victim_band', 'limit', 'tone_at_tx_port_dbm', ...
    'coupling_max_db', 'tone_at_victim_port_dbm', 'rx_integration_bw_hz', 'allowable_integrated_dbm', 'margin_db', 'I_over_N_db', ...
    'coupling_basis', 'note'}, spurRows);

% ============ TX design summary (PRIMARY) ============
txRows = {};
for t = {'S_TM_TX', 'ISL_X_TX', 'KA_DLS_TX'}
    sel = sumRows(cellfun(@(r) strcmp(regexprep(r{1}, '@.*$', ''), t{1}) && strcmp(r{4}, 'PRIMARY_RR_AP3'), sumRows));
    cls = @(q) ifelse(q <= 0, 'NO_EXTERNAL_FILTER_SUFFICIENT', ifelse(q <= 40, '>=40 dB', ifelse(q <= 60, '>=60 dB', ...
        ifelse(q <= 70, '>=70 dB', ifelse(q <= 80, '>=80 dB', '>80 dB / separate design required')))));
    for basis = {'CST_EVALUATED', 'BOUNDED'}
        sb = sel(cellfun(@(r) strcmp(r{5}, basis{1}), sel));
        if isempty(sb); continue; end
        req = cellfun(@(r) r{13}, sb); [qm, j] = max(req);
        txRows{end+1} = {t{1}, basis{1}, [sb{j}{2} ' (' sb{j}{3} ')'], qm, sb{j}{12}, cls(qm), numel(sb), sb{j}{14}}; %#ok<AGROW>
    end
end
writeTable(fullfile(outDir, 'tx_filter_requirement.csv'), {'tx_system', 'coupling_basis', 'worst_victim', ...
    'required_additional_suppression_db', 'margin_0db', 'screening_filter_class', 'n_pairs', 'first_passing_scenario'}, txRows);
for k = 1:numel(txRows)
    logm(logf, 'TX %-10s %-14s worst %-34s req %6.1f dB -> %s', txRows{k}{1}, txRows{k}{2}, txRows{k}{3}, txRows{k}{4}, txRows{k}{6});
end
logm(logf, 'Rows: freq %d, pair summary %d, spur %d, derivation %d', numel(freqRows), numel(sumRows), numel(spurRows), numel(der));
fclose(logf);
