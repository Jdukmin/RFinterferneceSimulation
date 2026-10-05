1;  % Octave script -- Claude worker: OOB/spurious-standard-based victim-band PSD RFI analysis
% =============================================================================================
% Shared engine src/+rfscreen/+psd unchanged. Source limits: output/claude/inputs/tx_emission_sources_claude.csv
% (RR AP3 primary, ECSS sensitivity). Owner engineering inputs (2026-10-05):
% output/claude/inputs/owner_engineering_inputs_claude.csv (SAR RX pattern anchors / NF 4 dB / -176 dBm/Hz;
% Ka 70 W, 31 dBi gain reference, WR-42 a = 10.668 mm, below-cutoff length 50 mm).
% Scope (owner): attackers S-TC TX (legacy S_TM_TX, 2.25 GHz) and Ka DLS TX; SAR TX is NOT an attacker;
% SAR RX IS a victim (the former SAR_X_RX skip was removed). ISL TX rows are kept from the earlier run (reference).
% Coupling at the VICTIM frequency:
%   CST       : G_tx(f_v) + G_rx(f_v) - FSPL(f_v) from data/antenna_port_response_cst (simulation data)
%   SAR RX    : G_rx = owner-reconstructed SAR receive envelope (52 dBi peak; -50 dB / +2 dBi ceiling
%               outside +/-80 deg and in the rear hemisphere)
%   Ka DLS    : conducted spurious PSD (TX output = waveguide input plane) - WR-42 below-cutoff attenuation
%               A = 8.685889638 * alpha * L (L = 50 mm) + 31 dBi gain reference + G_rx(f_v) - FSPL(f_v)
%   S -> L2/L5: S-antenna L2/L5 CST normalisation unreliable -> TX gain = Harrington maximum directivity of
%               the enclosing sphere D = (ka)^2 + 2ka (physical upper limit, worst pointing).
% Filter scenarios: data/rfi_psd/filter_scenarios.csv (FILTER_0/40/60/70/80DB).
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

function A = wr42BelowCutoffDb(f_Hz, a_m, L_m)
    %WR42BELOWCUTOFFDB Below-cutoff (evanescent) TE10 attenuation of a rectangular waveguide of length L (dB).
    %   alpha = sqrt((pi/a)^2 - (2 pi f / c)^2) [Np/m];  A = 20 log10(e) * alpha * L = 8.685889638 * alpha * L.
    alpha = sqrt(max(0, (pi / a_m) ^ 2 - (2 * pi * f_Hz / 299792458) .^ 2));
    A = 20 / log(10) * alpha * L_m;
end

function O = readOwner(path)
    %READOWNER key/value owner engineering input table (numeric where possible).
    L = strsplit(strrep(fileread(path), char(13), ''), char(10));
    L = L(~cellfun(@isempty, strtrim(L)) & ~strncmp(L, '#', 1)); O = struct();
    for i = 2:numel(L)
        c = regexp(L{i}, ',', 'split'); v = str2double(c{2}); if isnan(v); v = c{2}; end
        O.(c{1}) = v; O.([c{1} '_prov']) = c{4};
    end
end

function rel = sarCutEnvelope(th, hpbw, slL, dom, rear)
    %SARCUTENVELOPE Conservative relative envelope (dB) of one SAR principal cut at |th| (deg):
    %   Gaussian main lobe -12 (th/HPBW)^2, floored at the maximum side-lobe level up to the pattern domain
    %   limit (no credit for the first null or the side-lobe roll-off), rear envelope beyond the domain.
    th = abs(th);
    if th <= dom; rel = min(0, max(-12 * (th / hpbw) ^ 2, slL)); else; rel = rear; end
end

function [g, th, region] = sarRxGain(vL, O)
    %SARRXGAIN Owner-reconstructed SAR receive gain (dBi) toward the local direction vL
    %   (+Z_L boresight, +X_L = azimuth axis). Inside +/-80 deg: the LESS attenuated of the two principal-cut
    %   envelopes at the polar off-axis angle (conservative). Outside +/-80 deg or rear: peak + rear envelope,
    %   capped by the absolute rear ceiling.
    th = acosd(max(-1, min(1, vL(3) / norm(vL))));
    if th > O.sar_pattern_domain_limit
        g = min(O.sar_peak_gain + O.sar_rear_envelope, O.sar_rear_gain_ceiling); region = 'OUTSIDE_80DEG_REAR_CEILING';
        return;
    end
    ra = sarCutEnvelope(th, O.sar_az_hpbw, O.sar_az_max_sidelobe_level, O.sar_pattern_domain_limit, O.sar_rear_envelope);
    re = sarCutEnvelope(th, O.sar_el_hpbw, O.sar_el_max_sidelobe_level, O.sar_pattern_domain_limit, O.sar_rear_envelope);
    g = O.sar_peak_gain + max(ra, re); region = 'INSIDE_80DEG_RECONSTRUCTED_ENVELOPE';
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
pv = rfi_provenance(repo, fullfile(here, 'results'), 'run_oob_spurious_analysis.m', 'Claude OOB/spurious PSD analysis incl. SAR RX victim and Ka WR-42 owner route');
logm(logf, 'Claude OOB/spurious RFI run %s (GNU Octave %s); analysis base commit %s, working tree %s', pv.run_time, ...
    OCTAVE_VERSION, pv.analysis_base_commit, pv.working_tree);

P = rfscreen.psd.PsdMath; V = rfscreen.psd.VictimBandPsdPath; C = rfscreen.psd.VictimBandCoupling;
RB = rfscreen.psd.ReceiverBaseline; A = rfscreen.kaa.CstLocalFrameAdapter;
B = RB.read(fullfile(repo, 'data', 'rfi_psd', 'receiver_baseline.csv'));
FS = rfscreen.psd.FilterScenario.read(fullfile(repo, 'data', 'rfi_psd', 'filter_scenarios.csv'));
[S, X] = rfscreen.psd.EmissionMaskTable.read(fullfile(here, 'inputs', 'tx_emission_sources_claude.csv'));
variantOf = cellfun(@(x) x.variant, X, 'UniformOutput', false);
O = readOwner(fullfile(here, 'inputs', 'owner_engineering_inputs_claude.csv'));
% SAR receiver criterion: owner NF 4 dB / I/N -6 dB -> -176 dBm/Hz (replaces the NF 5 dB proxy of the shared baseline)
iS = find(strcmp({B.receiver}, 'SAR_X_RX'));
B(iS).nf_dB = O.sar_rx_nf; B(iS).nf_prov = O.sar_rx_nf_prov; B(iS).i_n_max_dB = O.sar_rx_i_n_max;
B(iS).noise_psd_dBmHz = P.noisePsd(B(iS).nf_dB); B(iS).allowable_psd_dBmHz = P.allowablePsd(B(iS).nf_dB, B(iS).i_n_max_dB);
B(iS).allowable_integrated_dBm = B(iS).allowable_psd_dBmHz + 10 * log10(B(iS).integration_bw_Hz);
B(iS).note = 'owner engineering input 2026-10-05: NF 4 dB / I/N -6 dB / -176 dBm/Hz';
if abs(B(iS).allowable_psd_dBmHz - O.sar_rx_allowable_psd) > 1e-9; error('claude:sar', 'SAR allowable PSD mismatch'); end
aWG = O.ka_waveguide_broad_wall * 1e-3; LWG = O.ka_waveguide_below_cutoff_length * 1e-3; gKa = O.ka_antenna_gain_reference;
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
bandOfRx = struct('S_TC_RX', 'S_TC', 'GPS_L1_RX', 'L1', 'GPS_L2_RX', 'L2', 'GPS_L5_RX', 'L5', 'ISL_X_RX', 'ISL', 'SAR_X_RX', 'SAR');
famOfMount = struct('SBA_NADIR', 'S', 'SBA_ZENITH', 'S', 'GPSA_1', 'L', 'GPSA_2', 'L', 'ISL', 'ISL', 'KAA_1', 'KA', 'KAA_2', 'KA', 'SAR_ANT', 'SAR');
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
% harmonics / domain check (all victim receivers incl. SAR RX; SAR TX is not an attacker)
hrm = {};
for t = fieldnames(txInfo).'
    ti = txInfo.(t{1}); bnd = ap3Boundary(ti.fc, ti.BN);
    for b = B
        off = min(abs([b.tuning_lo_Hz b.tuning_hi_Hz] - ti.fc)); if ti.fc >= b.tuning_lo_Hz && ti.fc <= b.tuning_hi_Hz; off = 0; end
        n = 2:20; inb = n(n * (ti.fc + ti.BN / 2) >= b.tuning_lo_Hz & n * (ti.fc - ti.BN / 2) <= b.tuning_hi_Hz);
        hrm{end+1} = {t{1}, b.receiver, b.tuning_lo_Hz, b.tuning_hi_Hz, off, bnd, ifelse(off > bnd, 'SPURIOUS', 'OOB_OR_INBAND'), ...
            ifelse(isempty(inb), 'none', sprintf('%d ', inb))}; %#ok<AGROW>
    end
end
writeTable(fullfile(outDir, 'domain_and_harmonic_check.csv'), {'tx_system', 'victim_receiver', 'victim_lo_hz', 'victim_hi_hz', ...
    'min_offset_from_carrier_hz', 'ap3_spurious_boundary_offset_hz', 'domain', 'harmonic_orders_in_victim_band'}, hrm);
% S-TC TX (legacy S_TM_TX) -> SAR RX: integer-harmonic overlap of the occupied band n*[fc - BN/2, fc + BN/2]
bS = RB.lookup(B, 'SAR_X_RX'); hs = {};
for cs = {{'NOMINAL_2250MHZ_BN_2P7MHZ', 2.25e9 - 1.35e6, 2.25e9 + 1.35e6}, {'S_DOWNLINK_ALLOCATION_2200_2290MHZ', 2.2e9, 2.29e9}}
    for n = 1:6
        lo = n * cs{1}{2}; hi = n * cs{1}{3}; ov = max(0, min(hi, bS.tuning_hi_Hz) - max(lo, bS.tuning_lo_Hz));
        gap = max([bS.tuning_lo_Hz - hi, lo - bS.tuning_hi_Hz, 0]);
        hs{end+1} = {cs{1}{1}, n, lo, hi, bS.tuning_lo_Hz, bS.tuning_hi_Hz, ov, gap, ifelse(ov > 0, 'HARMONIC_OVERLAP', 'NO_HARMONIC_OVERLAP')}; %#ok<AGROW>
    end
end
writeTable(fullfile(outDir, 'stc_sar_harmonic_check.csv'), {'carrier_case', 'harmonic_order', 'harmonic_lo_hz', 'harmonic_hi_hz', ...
    'sar_lo_hz', 'sar_hi_hz', 'overlap_hz', 'gap_to_sar_band_hz', 'status'}, hs);
nOv = sum(cellfun(@(r) r{7} > 0, hs));
logm(logf, 'S-TC -> SAR integer harmonic check: %d overlapping orders (4th %.4f-%.4f GHz, 5th %.4f-%.4f GHz) -> %s', nOv, ...
    hs{4}{3} / 1e9, hs{4}{4} / 1e9, hs{5}{3} / 1e9, hs{5}{4} / 1e9, ifelse(nOv == 0, 'NO_HARMONIC_OVERLAP', 'HARMONIC_OVERLAP'));
% WR-42 below-cutoff attenuation per victim band (owner L = 50 mm); the band's highest frequency is the worst case
wg = {}; fcWG = 299792458 / (2 * aWG);
for vb = {'L1', 'GPS_L1_RX'; 'L2', 'GPS_L2_RX'; 'L5', 'GPS_L5_RX'; 'S_TM', 'S_TC_RX'; 'ISL', 'ISL_X_RX'; 'SAR', 'SAR_X_RX'}.'
    bb = RB.lookup(B, vb{2}); fr = [bb.tuning_lo_Hz bb.tuning_hi_Hz];
    al = sqrt((pi / aWG) ^ 2 - (2 * pi * fr / 299792458) .^ 2);
    wg{end+1} = {vb{1}, vb{2}, fr(1), fr(2), fcWG, fr(2) / fcWG, al(2), LWG, wr42BelowCutoffDb(fr(1), aWG, LWG), ...
        wr42BelowCutoffDb(fr(2), aWG, LWG), 'OWNER_ENGINEERING_INPUT (WR-42 a = 10.668 mm; L = 50 mm)'}; %#ok<AGROW>
    logm(logf, 'WR-42 50 mm below-cutoff attenuation %-4s %.4f-%.4f GHz: %.2f-%.2f dB', vb{1}, fr / 1e9, wg{end}{10}, wg{end}{9});
end
writeTable(fullfile(outDir, 'ka_wr42_below_cutoff_attenuation.csv'), {'victim_band', 'victim_receiver', 'band_lo_hz', 'band_hi_hz', ...
    'te10_cutoff_hz', 'f_hi_over_fc', 'alpha_np_per_m_at_f_hi', 'below_cutoff_length_m', 'attenuation_db_at_f_lo', ...
    'attenuation_db_at_f_hi_worst', 'provenance'}, wg);

% ============ pair loop ============
% pairs of the earlier run (pair_results.csv: S-TC TX / ISL TX / Ka DLS TX -> S-TM, GPS, ISL) + SAR RX victim pairs
pairs = {}; seen = containers.Map();
for i = 1:PR.nRows
    k = [PR.tx_system{i} '>' PR.rx_system{i}];
    if ~seen.isKey(k); seen(k) = 1; pairs{end+1} = {PR.tx_system{i}, PR.rx_system{i}, PR.tx_mount{i}, PR.rx_mount{i}}; end %#ok<AGROW>
end
for t = {{'S_TM_TX@SBA_NADIR', 'SBA_NADIR'}, {'S_TM_TX@SBA_ZENITH', 'SBA_ZENITH'}, {'KA_DLS_TX@KAA_1', 'KAA_1'}, {'KA_DLS_TX@KAA_2', 'KAA_2'}}
    pairs{end+1} = {t{1}{1}, 'SAR_X_RX@SAR_ANT', t{1}{2}, 'SAR_ANT'}; %#ok<AGROW>
end
ownerTx = @(x) strrep(strrep(strrep(x, 'S_TM_TX@', 'S-TC TX @ '), 'KA_DLS_TX@', 'Ka DLS TX @ '), 'ISL_X_TX', 'ISL TX');
ownerRx = @(x) strrep(strrep(strrep(strrep(strrep(strrep(strrep(x, 'S_TC_RX@', 'S-TM RX @ '), 'GPS_L1_RX@', 'GPS L1 RX @ '), ...
    'GPS_L2_RX@', 'GPS L2 RX @ '), 'GPS_L5_RX@', 'GPS L5 RX @ '), 'ISL_X_RX', 'ISL RX'), 'SAR_X_RX@SAR_ANT', 'SAR RX'), '@ SAR_ANT', '');
freqRows = {}; sumRows = {}; spurRows = {}; primRows = {}; refRows = {}; sarGeo = {};
variants = {'PRIMARY_RR_AP3', 'SENS_ECSS_50_05C', 'SENS_KA_SOURCE_AT_ANTENNA_OUTPUT', 'SENS_KA_HARRINGTON_GAIN'};
for ii = 1:numel(pairs)
    tx = pairs{ii}{1}; rx = pairs{ii}{2}; tm = pairs{ii}{3}; rm = pairs{ii}{4};
    rt = regexprep(rx, '@.*$', ''); tt = regexprep(tx, '@.*$', ''); vband = bandOfRx.(rt); b = RB.lookup(B, rt);
    tfam = famOfMount.(tm); rfam = famOfMount.(rm); isKa = strcmp(tfam, 'KA'); isSar = strcmp(rfam, 'SAR'); carrier = txInfo.(tt).P;
    f = RB.tuningSweep(b, nF);
    if strcmp(tm, rm)
        sumRows{end+1} = {tx, rx, vband, 'ALL', 'NOT_APPLICABLE_SAME_PORT', '', '', NaN, NaN, NaN, NaN, b.allowable_psd_dBmHz, NaN, NaN, ...
            '', '', '', '', '', '', 'same antenna port: diplexer isolation + TX noise PSD needed'}; %#ok<AGROW>
        continue;
    end
    d = pos(rm) - pos(tm); dist = norm(d); u = d / dist;
    dT = A.bodyToLocal(Rbl(tm), u); dR = A.bodyToLocal(Rbl(rm), -u);
    fsp = arrayfun(@(x) P.fspl(x, dist), f);
    % ---- victim (RX) gain at the victim frequency ----
    if isSar
        [gS, thS, regS] = sarRxGain(dR, O); grx = gS * ones(1, nF);
        rxLabel = sprintf('owner SAR RX envelope (%s; off-boresight %.1f deg)', regS, thS);
        los = rfscreen.geometry.LineOfSight.segment(tm, rm, pos(tm), pos(rm), model.structures);
        sarGeo{end+1} = {tx, rx, dist, thS, regS, gS, los.status, O.sar_peak_gain_prov, O.sar_rear_envelope_prov}; %#ok<AGROW>
    else
        rk = [rfam '/' vband]; if ~resp.isKey(rk); resp(rk) = rfscreen.psd.BandResponse.fromRepository(repo, rfam, vband, prov); end
        rr = resp(rk); grx = arrayfun(@(x) rr.gainAt(vband, x, dR), f); rxLabel = ['CST ' rr.cstCase];
    end
    % ---- interferer (TX) antenna gain at the victim frequency ----
    if isKa
        gtx = gKa * ones(1, nF); basis = 'OWNER_31DBI_GAIN_REFERENCE_WR42_50MM';
        txLabel = sprintf('owner KAA gain reference %.0f dBi', gKa); wgA = wr42BelowCutoffDb(f, aWG, LWG);
    else
        tk = [tfam '/' vband]; if ~resp.isKey(tk); resp(tk) = rfscreen.psd.BandResponse.fromRepository(repo, tfam, vband, prov); end
        tr = resp(tk); wgA = zeros(1, nF);
        if tr.isAvailable()
            gtx = arrayfun(@(x) tr.gainAt(vband, x, dT), f); txLabel = ['CST ' tr.cstCase];
            basis = ifelse(isSar, 'CST_TX_GAIN_OWNER_SAR_RX_ENVELOPE', 'CST_SIMULATED_GAIN');
        else
            gtx = harringtonDbi(f, aS); basis = 'HARRINGTON_MAX_DIRECTIVITY_TX';
            txLabel = sprintf('Harrington max directivity (a = %.1f mm; %s/%s %s)', aS * 1e3, tfam, vband, tr.status);
        end
    end
    cRad = grx - fsp;                       % G_rx - FSPL
    cPath = gtx + grx - fsp;                % antenna-to-antenna path coupling (TX gain incl.), WG attenuation excluded
    route = sprintf('%s + %s - FSPL(%.3f m)', txLabel, rxLabel, dist);
    for v = variants
        src = v{1}; cP = cPath; wU = wgA; rUse = route;
        if strncmp(v{1}, 'SENS_KA', 7)
            if ~isKa; continue; end
            src = 'PRIMARY_RR_AP3';
            if strcmp(v{1}, 'SENS_KA_SOURCE_AT_ANTENNA_OUTPUT')
                wU = zeros(1, nF); rUse = [route '; source referenced to the antenna output (WR-42 attenuation not re-applied)'];
            else
                cP = harringtonDbi(f, aKAA) + cRad; rUse = sprintf('Harrington max directivity KAA (a = %.1f mm) + %s - FSPL; WR-42 50 mm', aKAA * 1e3, rxLabel);
            end
        elseif isKa
            rUse = [route '; WR-42 50 mm below-cutoff attenuation'];
        end
        cUse = cP - wU;
        sp = S(strcmp(variantOf, src)); sp = rfscreen.psd.EmissionMaskTable.select(sp, tt, vband);
        res = cell(1, numel(FS));
        for q = 1:numel(FS)
            R = V.evaluate(f, cUse, cRad, b.allowable_psd_dBmHz, sp, carrier, FS{q}, NaN, false);
            res{q} = R;
            for k = 1:nF
                freqRows{end+1} = {v{1}, tx, rx, vband, f(k), sp{1}.standardOrSource, R.source_psd_dBmHz(k), FS{q}.id, R.filter_dB(k), ...
                    wU(k), cP(k), R.port_psd_dBmHz(k), R.allowable_dBmHz(k), R.margin_dB(k), R.required_add_supp_dB(k), R.status{k}, rUse}; %#ok<AGROW>
            end
        end
        m0 = min(res{1}.margin_dB); req = max(res{1}.required_add_supp_dB);
        st = cellfun(@(r) ifelse(all(strcmp(r.status, 'PASS')), 'PASS', 'FAIL'), res, 'UniformOutput', false);
        firstPass = 'NONE_UP_TO_80DB'; ip = find(strcmp(st, 'PASS'), 1); if ~isempty(ip); firstPass = FS{ip}.id; end
        [~, kw] = max(res{1}.port_psd_dBmHz);
        sumRows{end+1} = {tx, rx, vband, v{1}, basis, sp{1}.standardOrSource, ...
            X{find(strcmp(variantOf, src) & cellfun(@(s) strcmp(s.txSystem, tt) && strcmp(s.victimBand, vband), S), 1)}.clause, ...
            res{1}.source_psd_dBmHz(kw), wU(kw), cP(kw), res{1}.port_psd_dBmHz(kw), b.allowable_psd_dBmHz, m0, req, firstPass, ...
            st{2}, st{3}, st{4}, st{5}, sprintf('%.6g', f(kw) / 1e6), rUse}; %#ok<AGROW>
        if strcmp(v{1}, 'PRIMARY_RR_AP3') && ~strcmp(tt, 'ISL_X_TX')
            plane = ifelse(isKa, 'TX output = WR-42 input (conducted)', 'antenna input port (conducted)');
            primRows{end+1} = {ownerTx(tx), ownerRx(rx), tx, rx, vband, f(kw), res{1}.source_psd_dBmHz(kw), plane, ...
                ifelse(isKa, wU(kw), NaN), cP(kw), res{1}.port_psd_dBmHz(kw), b.allowable_psd_dBmHz, res{1}.margin_dB(kw), ...
                res{1}.required_add_supp_dB(kw), gtx(kw), grx(kw), fsp(kw), dist, basis, rUse}; %#ok<AGROW>
        end
        if isKa
            refRows{end+1} = {ownerTx(tx), ownerRx(rx), vband, v{1}, f(kw), res{1}.source_psd_dBmHz(kw), wU(kw), cP(kw), ...
                res{1}.port_psd_dBmHz(kw), b.allowable_psd_dBmHz, req}; %#ok<AGROW>
        end
    end
    % discrete spur (secondary): a single tone at the limit, landing inside the victim channel
    nI = b.noise_psd_dBmHz + 10 * log10(b.integration_bw_Hz); cS = max(cPath - wgA);
    for dv = {{'RR AP3 discrete component (power in 4 kHz)', -min(43 + 10 * log10(10 ^ ((carrier - 30) / 10)), 60)}, ...
              {'CCSDS 401 2.4.16 single spur total power', -60}}
        tone = carrier + dv{1}{2} + cS;
        spurRows{end+1} = {tx, rx, vband, dv{1}{1}, carrier + dv{1}{2}, cS, tone, b.integration_bw_Hz, b.allowable_integrated_dBm, ...
            b.allowable_integrated_dBm - tone, tone - nI, basis, ...
            'SECONDARY: applies only if a discrete spur falls inside the operating channel; not converted to dBm/Hz'}; %#ok<AGROW>
    end
end
writeTable(fullfile(outDir, 'victim_psd_results.csv'), {'variant', 'tx_system', 'rx_system', 'victim_band', 'frequency_hz', ...
    'standard', 'source_psd_dbm_hz', 'filter_scenario_id', 'filter_attenuation_db', 'wg_below_cutoff_attenuation_db', ...
    'path_coupling_db', 'victim_port_psd_dbm_hz', 'allowable_psd_dbm_hz', 'psd_margin_db', 'required_additional_suppression_db', ...
    'status', 'coupling_route'}, freqRows);
writeTable(fullfile(outDir, 'pair_margin_summary.csv'), {'tx_system', 'rx_system', 'victim_band', 'variant', 'coupling_basis', ...
    'standard', 'clause', 'source_psd_dbm_hz', 'wg_below_cutoff_attenuation_db', 'path_coupling_db', 'victim_port_psd_dbm_hz_0db', ...
    'allowable_psd_dbm_hz', 'margin_0db', 'minimum_required_additional_suppression_db', 'first_passing_scenario', 'FILTER_40DB', ...
    'FILTER_60DB', 'FILTER_70DB', 'FILTER_80DB', 'worst_frequency_mhz', 'coupling_route'}, sumRows);
writeTable(fullfile(outDir, 'primary_psd_results.csv'), {'interferer', 'victim', 'tx_system', 'rx_system', 'victim_band', ...
    'worst_frequency_hz', 'source_psd_dbm_hz', 'source_reference_plane', 'wg_below_cutoff_attenuation_db', 'path_coupling_db', ...
    'victim_psd_dbm_hz', 'allowable_psd_dbm_hz', 'margin_db', 'required_additional_suppression_db', 'tx_gain_dbi', 'rx_gain_dbi', ...
    'fspl_db', 'distance_m', 'coupling_basis', 'coupling_route'}, primRows);
writeTable(fullfile(outDir, 'ka_reference_plane_comparison.csv'), {'interferer', 'victim', 'victim_band', 'variant', ...
    'worst_frequency_hz', 'source_psd_dbm_hz', 'wg_below_cutoff_attenuation_db', 'path_coupling_db', 'victim_psd_dbm_hz', ...
    'allowable_psd_dbm_hz', 'required_additional_suppression_db'}, refRows);
writeTable(fullfile(outDir, 'sar_victim_geometry.csv'), {'tx_system', 'rx_system', 'distance_m', 'sar_off_boresight_deg', ...
    'sar_pattern_region', 'sar_rx_gain_dbi', 'line_of_sight', 'peak_gain_provenance', 'rear_envelope_provenance'}, sarGeo);
writeTable(fullfile(outDir, 'discrete_spur_check.csv'), {'tx_system', 'rx_system', 'victim_band', 'limit', 'tone_at_tx_port_dbm', ...
    'coupling_max_db', 'tone_at_victim_port_dbm', 'rx_integration_bw_hz', 'allowable_integrated_dbm', 'margin_db', 'I_over_N_db', ...
    'coupling_basis', 'note'}, spurRows);

% ============ TX design summary (PRIMARY) ============
% sumRows columns: 1 tx, 2 rx, 3 band, 4 variant, 5 basis, ..., 13 margin_0db, 14 required, 15 first passing
txRows = {};
cls = @(q) ifelse(q <= 0, 'NO_EXTERNAL_FILTER_NEEDED', ifelse(q <= 40, '>=40 dB', ifelse(q <= 60, '>=60 dB', ...
    ifelse(q <= 70, '>=70 dB', ifelse(q <= 80, '>=80 dB', '>80 dB / separate design required')))));
for t = {'S_TM_TX', 'ISL_X_TX', 'KA_DLS_TX'}
    sel = sumRows(cellfun(@(r) strcmp(regexprep(r{1}, '@.*$', ''), t{1}) && strcmp(r{4}, 'PRIMARY_RR_AP3'), sumRows));
    for basis = unique(cellfun(@(r) r{5}, sel, 'UniformOutput', false))
        sb = sel(cellfun(@(r) strcmp(r{5}, basis{1}), sel));
        req = cellfun(@(r) r{14}, sb); [qm, j] = max(req);
        txRows{end+1} = {t{1}, basis{1}, [sb{j}{2} ' (' sb{j}{3} ')'], qm, sb{j}{13}, cls(qm), numel(sb), sb{j}{15}}; %#ok<AGROW>
    end
end
writeTable(fullfile(outDir, 'tx_filter_requirement.csv'), {'tx_system', 'coupling_basis', 'worst_victim', ...
    'required_additional_suppression_db', 'margin_0db', 'filter_class', 'n_pairs', 'first_passing_scenario'}, txRows);
for k = 1:numel(txRows)
    logm(logf, 'TX %-10s %-36s worst %-34s req %6.1f dB -> %s', txRows{k}{1}, txRows{k}{2}, txRows{k}{3}, txRows{k}{4}, txRows{k}{6});
end
for k = 1:numel(primRows)
    r = primRows{k};
    logm(logf, 'PRIMARY %-22s -> %-20s src %7.2f WG %7.2f C %8.2f victim %8.2f allow %6.1f margin %7.2f req %6.2f', r{1}, r{2}, ...
        r{7}, r{9}, r{10}, r{11}, r{12}, r{13}, r{14});
end

% ============ SECONDARY: S-TC fundamental (2.25 GHz) at the SAR RX port (blocker exposure, not a PSD result) ============
blk = {}; rS = rfscreen.psd.BandResponse.fromRepository(repo, 'S', 'S_TM', prov);
for tmc = {'SBA_NADIR', 'SBA_ZENITH'}
    d = pos('SAR_ANT') - pos(tmc{1}); dist = norm(d); u = d / dist;
    gT = rS.gainAt('S_TM', 2.25e9, A.bodyToLocal(Rbl(tmc{1}), u)); [gR, thR] = sarRxGain(A.bodyToLocal(Rbl('SAR_ANT'), -u), O);
    pw = txInfo.S_TM_TX.P + gT - P.fspl(2.25e9, dist) + gR;
    blk{end+1} = {['S_TM_TX@' tmc{1}], 'SAR_X_RX@SAR_ANT', 2.25e9, txInfo.S_TM_TX.P, gT, P.fspl(2.25e9, dist), gR, thR, pw, ...
        'SECONDARY_OOB_BLOCKER: SAR antenna response at 2.25 GHz unknown -> owner +2 dBi rear ceiling ASSUMED; SAR RX preselector/blocking data missing -> no verdict'}; %#ok<AGROW>
    logm(logf, 'SECONDARY S-TC@%s fundamental at SAR RX port: %.2f dBm (G_tx %.2f dBi, FSPL %.2f dB, G_SAR %.1f dBi assumed)', tmc{1}, pw, gT, ...
        P.fspl(2.25e9, dist), gR);
end
writeTable(fullfile(outDir, 'sar_secondary_fundamental_exposure.csv'), {'tx_system', 'rx_system', 'frequency_hz', 'tx_power_dbm', ...
    'tx_gain_dbi', 'fspl_db', 'sar_rx_gain_dbi_assumed', 'sar_off_boresight_deg', 'power_at_sar_port_dbm', 'note'}, blk);
logm(logf, 'Rows: freq %d, pair summary %d, primary %d, spur %d, derivation %d', numel(freqRows), numel(sumRows), numel(primRows), ...
    numel(spurRows), numel(der));
fclose(logf);
