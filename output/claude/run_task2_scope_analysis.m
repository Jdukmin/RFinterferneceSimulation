1;  % Octave script with local functions -- Task 2: primary scope simplification, SAR/ISL victim-only, Ka cutoff route
% =============================================================================================
% (A) primary scope matrix (data/rfi_psd/rfi_scope_matrix.csv): ISL TX / SAR TX excluded; KAA gain bound -> legacy sensitivity
% (B) SAR K8 normalised pattern rebuilt from owner-extracted values (no CST, no 1601-point export) -> data/Xband_SAR_K8_owner
% (C) S-TC TX harmonic overlap with the SAR band (machine readable; never merged with generic spurious)
% (D) S-TC TX -> SAR RX generic ITU spurious route (SAR absolute peak gain unknown -> result expressed with G_peak symbolic)
% (E) S-TC TX -> ISL RX: Task-1 results (run_stc_lband_rescaling.m) re-tabulated, not recomputed
% (F) Ka DLS: max EIRP (70 W + 31 dBi = 49.451 dBW) x ITU -60 dBc/4 kHz -> WAVEGUIDE_BELOW_CUTOFF_BOUND -> G_rx - FSPL -> PSD
% No CST run. From the repository root (after run_stc_lband_rescaling.m):
%   octave-cli --no-gui --norc --eval "run('output/claude/run_task2_scope_analysis.m')"
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

function s = firstPass(att, req)
    k = find(att >= req - 1e-9, 1);
    if isnan(req); s = 'NOT_EVALUATED'; elseif isempty(k); s = sprintf('NONE (> %g dB)', max(att)); else; s = sprintf('%g dB', att(k)); end
end

function T = readCsv(path)
    L = strsplit(strrep(fileread(path), char(13), ''), char(10)); L = L(~cellfun(@isempty, strtrim(L)));
    h = strsplit(L{1}, ','); T = struct('nRows', numel(L) - 1);
    V = cellfun(@(x) strsplit(x, ',', 'CollapseDelimiters', false), L(2:end), 'UniformOutput', false);
    for j = 1:numel(h); T.(h{j}) = cellfun(@(v) v{j}, V, 'UniformOutput', false); end
end

% ------------------------------------------------------------------------------------------------
here = fileparts(mfilename('fullpath'));
if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'src')); addpath(fullfile(here, 'code'));
outDir = fullfile(here, 'results');
logf = fopen(fullfile(outDir, 'task2_run_log.txt'), 'w');
pv = rfi_provenance(repo, outDir, 'run_task2_scope_analysis.m', 'Task 2 scope / SAR victim / Ka cutoff route');
logm(logf, 'Task 2 run %s (GNU Octave %s); analysis base commit %s, working tree %s', pv.run_time, OCTAVE_VERSION, ...
    pv.analysis_base_commit, pv.working_tree);

P = rfscreen.psd.PsdMath; RB = rfscreen.psd.ReceiverBaseline; A = rfscreen.kaa.CstLocalFrameAdapter;
W = rfscreen.psd.WaveguideCutoff; SD = rfscreen.spacecraft.SpacecraftDataReader;
psdDir = fullfile(repo, 'data', 'rfi_psd');
B = RB.read(fullfile(psdDir, 'receiver_baseline.csv'));
FS = rfscreen.psd.FilterScenario.read(fullfile(psdDir, 'filter_scenarios.csv')); att = cellfun(@(f) f.atten_dB, FS);
prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));
T = SD.readTable(fullfile(rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir(), 'rf_systems.csv'));
row = @(id) find(strcmp(T.system_id, id), 1);

% =========================== (A) scope ===========================
S = SD.readTable(fullfile(psdDir, 'rfi_scope_matrix.csv'));
for i = 1:S.nRows; logm(logf, 'scope %-10s -> %-8s %-8s %s', S.attacker{i}, S.victim{i}, S.victim_band{i}, S.scope{i}); end

% =========================== (B) SAR pattern ===========================
sarDir = fullfile(repo, 'data', 'Xband_SAR_K8_owner');
SP = rfscreen.psd.SarOwnerPattern.fromFile(fullfile(sarDir, 'owner_cut_values.csv'));
OA = SD.readTable(fullfile(sarDir, 'owner_absolute_inputs.csv')); oa = @(k) str2double(OA.value{strcmp(OA.item, k)});
Gpk = oa('SAR_PEAK_GAIN'); SP = SP.withOutsideCeiling(oa('OUTSIDE_80_CEILING'));
if abs(Gpk + oa('OUTSIDE_80_CEILING') - oa('BACK_ABSOLUTE_CEILING')) > 1e-9
    error('SAR owner inputs inconsistent: peak + outside ceiling ~= back absolute ceiling');
end
logm(logf, 'SAR owner inputs: peak gain %.1f dBi (%s), outside +/-80 deg ceiling %.1f dB re peak = %.1f dBi; HPBW cross-check %.2f dBi', ...
    Gpk, OA.nature{strcmp(OA.item, 'SAR_PEAK_GAIN')}, oa('OUTSIDE_80_CEILING'), oa('BACK_ABSOLUTE_CEILING'), 10 * log10(41253 / (0.242294 * 1.112221)));
th = 0:0.1:180; gaz = SP.cutGain('AZIMUTH', th); gel = SP.cutGain('ELEVATION', th); gd = SP.directionGain(th);
envRows = cell(1, numel(th));
for i = 1:numel(th)
    reg = 'OWNER_RANGE'; if th(i) > SP.DATA_RANGE_DEG; reg = 'OUTSIDE_OWNER_RANGE_OWNER_CEILING'; end
    envRows{i} = {th(i), gaz(i), gel(i), gd(i), reg};
end
writeTable(fullfile(sarDir, 'sar_envelope_0p1deg.csv'), {'theta_deg', 'azimuth_co_envelope_db', 'elevation_co_envelope_db', ...
    'direction_envelope_db', 'region'}, envRows);
sumRows = {};
for c = SP.cuts
    smp = SP.cutGain(c.name, c.sampleDeg);
    sumRows{end+1} = {c.name, 2 * c.theta3, SP.cutGain(c.name, c.theta3), c.thetaNull, c.gNull, SP.cutGain(c.name, c.thetaNull), ...
        c.thetaSl, c.gSl, SP.cutGain(c.name, c.thetaSl), min(smp - c.sampleDb), c.outerHold, SP.outsideCeiling_dB, Gpk, -120, SP.XPOL, 'OWNER_HPBW_ENGINEERING_ESTIMATE', SP.PROVENANCE}; %#ok<AGROW>
    logm(logf, 'SAR %-9s HPBW %.6f deg (env %.3f dB at 3-dB point), null %.1f deg %.3f dB (env %.3f), sidelobe %.3f @ %.1f, env-sample min %.3f dB, outer hold %.3f dB', ...
        c.name, 2 * c.theta3, SP.cutGain(c.name, c.theta3), c.thetaNull, c.gNull, SP.cutGain(c.name, c.thetaNull), c.gSl, c.thetaSl, ...
        min(smp - c.sampleDb), c.outerHold);
end
writeTable(fullfile(outDir, 'task2_sar_pattern_summary.csv'), {'cut', 'hpbw_deg', 'envelope_at_3db_point_db', 'first_null_deg', ...
    'owner_first_null_db', 'envelope_at_first_null_db', 'max_sidelobe_deg', 'owner_max_sidelobe_db', 'envelope_at_sidelobe_db', ...
    'min_envelope_minus_owner_sample_db', 'outer_hold_60_to_80deg_db', 'outside_80deg_ceiling_db', 'peak_gain_dbi', 'cx_re_co_peak_db', 'cross_pol', 'peak_gain_basis', 'provenance'}, sumRows);

% =========================== (C) harmonic overlap ===========================
bS = RB.lookup(B, 'SAR_X_RX'); sar = [bS.tuning_lo_Hz bS.tuning_hi_Hz];
fcS = str2double(T.fc_mhz{row('S_TM_TX@SBA_NADIR')}) * 1e6; bwS = str2double(T.bw_mhz{row('S_TM_TX@SBA_NADIR')}) * 1e6;
cand = {'S-TC TX occupied band (rf_systems.csv fc 2250 MHz +/- bw/2)', fcS - bwS / 2, fcS + bwS / 2; ...
    'S-TC TX carrier (point)', fcS, fcS; 'S-band space-to-Earth allocation 2200-2290 MHz (sensitivity)', 2200e6, 2290e6};
hRows = {}; anyOv = false;
for c = 1:size(cand, 1)
    for n = 1:10
        lo = n * cand{c, 2}; hi = n * cand{c, 3}; ov = hi >= sar(1) && lo <= sar(2); anyOv = anyOv || (ov && c <= 2);
        hRows{end+1} = {'S-TC TX (legacy id S_TM_TX)', cand{c, 1}, n, lo / 1e6, hi / 1e6, sar(1) / 1e6, sar(2) / 1e6, ...
            ifelse(ov, 'HARMONIC_OVERLAP', 'NO_HARMONIC_OVERLAP')}; %#ok<AGROW>
    end
end
writeTable(fullfile(outDir, 'task2_stc_sar_harmonics.csv'), {'attacker', 'basis', 'harmonic_order', 'harmonic_lo_mhz', 'harmonic_hi_mhz', ...
    'sar_lo_mhz', 'sar_hi_mhz', 'status'}, hRows);
logm(logf, 'S-TC harmonics vs SAR %.1f-%.1f MHz: %s (n=4 %.1f-%.1f MHz, n=5 %.1f-%.1f MHz)', sar / 1e6, ...
    ifelse(anyOv, 'HARMONIC_OVERLAP', 'NO_HARMONIC_OVERLAP'), 4 * cand{1, 2} / 1e6, 4 * cand{1, 3} / 1e6, 5 * cand{1, 2} / 1e6, 5 * cand{1, 3} / 1e6);

% =========================== geometry ===========================
model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
pos = containers.Map(); Rbl = containers.Map();
for i = 1:numel(model.installationRecords)
    rc = model.installationRecords(i); pn = model.panels(strcmp({model.panels.id}, rc.panelId));
    pos(rc.antennaId) = rc.position_m(:); Rbl(rc.antennaId) = A.fixedMount(pn.normal_B);
end
resp = containers.Map();
getR = @(fam, vb) rfscreen.psd.BandResponse.fromRepository(repo, fam, vb, prov);
nF = 21;

% =========================== (D) S-TC TX -> SAR RX generic spurious ===========================
stc = rfscreen.psd.EmissionMaskTable.read(fullfile(psdDir, 'stc_itu_spurious_source.csv'));
spS = rfscreen.psd.EmissionMaskTable.select(stc, 'S_TM_TX', 'SAR'); Pstc = str2double(T.tx_power_dbm{row('S_TM_TX@SBA_NADIR')});
srcS = spS{1}.psdDbmHz(Pstc); fS = RB.tuningSweep(bS, nF);
rS = getR('S', 'SAR');
sarRows = {};
for tm = {'SBA_NADIR', 'SBA_ZENITH'}
    d = pos('SAR_ANT') - pos(tm{1}); dist = norm(d); u = d / dist;
    dT = A.bodyToLocal(Rbl(tm{1}), u); dR = A.bodyToLocal(Rbl('SAR_ANT'), -u);
    thS = acosd(max(-1, min(1, dR(3) / norm(dR)))); gn = SP.directionGain(thS);
    gtx = arrayfun(@(f) rS.gainAt('SAR', f, dT), fS); fspl = P.fspl(fS, dist);
    psdX = srcS + gtx - fspl + gn + Gpk;                          % victim PSD with the owner SAR peak gain
    x = nmax(psdX); req = max(0, x - bS.allowable_psd_dBmHz); mg = bS.allowable_psd_dBmHz - x;
    los = rfscreen.geometry.LineOfSight.segment(tm{1}, 'SAR_ANT', pos(tm{1}), pos('SAR_ANT'), model.structures);
    sarRows{end+1} = {['S_TM_TX@' tm{1} '>SAR_X_RX@SAR_ANT'], 'S-TC TX (legacy id S_TM_TX)', tm{1}, 'SAR RX', 'GENERIC_ITU_SPURIOUS (not harmonic)', ...
        srcS, nmax(gtx), nmin(fspl), dist, thS, ifelse(thS > SP.DATA_RANGE_DEG, 'OUTSIDE_OWNER_RANGE_OWNER_CEILING', 'OWNER_RANGE'), gn, Gpk, gn + Gpk, ...
        nmax(gtx - fspl) + gn + Gpk, x, bS.allowable_psd_dBmHz, mg, mg + 40, mg + 60, mg + 70, mg + 80, req, firstPass(att, req), ...
        (req > 0) * ceil((req + 10) / 10 - 1e-9) * 10, los.status, 'SAR peak 52 dBi OWNER HPBW ENGINEERING ESTIMATE', sprintf('CST %s S/SAR RealizedGain', rS.cstCase)}; %#ok<AGROW>
    logm(logf, 'S-TC@%-10s -> SAR: d=%.3f m, SAR off-axis %.1f deg (norm %.2f dB -> %.2f dBi), G_tx %.2f dBi, PSD %.2f dBm/Hz -> required %.2f dB, first pass %s', ...
        tm{1}, dist, thS, gn, gn + Gpk, nmax(gtx), x, req, firstPass(att, req));
end
writeTable(fullfile(outDir, 'task2_stc_sar_spurious.csv'), {'pair', 'attacker', 'tx_mount', 'victim', 'route', 'itu_source_psd_dbm_hz', ...
    'tx_gain_max_dbi', 'fspl_min_db', 'distance_m', 'sar_off_axis_deg', 'sar_pattern_region', 'sar_normalised_gain_db', ...
    'sar_peak_gain_dbi', 'sar_gain_toward_tx_dbi', 'coupling_max_db', 'victim_psd_max_dbm_hz', 'allowable_psd_dbm_hz', 'margin_0db_db', ...
    'margin_40db_db', 'margin_60db_db', 'margin_70db_db', 'margin_80db_db', 'required_additional_suppression_db', 'first_passing_scenario', ...
    'design_target_db', 'los', 'sar_peak_gain_basis', 'tx_response_source'}, sarRows);

% =========================== (E) S-TC TX -> ISL RX (Task 1 results) ===========================
D1 = readCsv(fullfile(outDir, 'stc_filter_design.csv')); isl = find(strcmp(D1.victim_band, 'ISL'));
for i = isl(:).'
    logm(logf, 'S-TC -> ISL (Task 1): %s PSD %s dBm/Hz, margin %s dB, required %s dB, first pass %s', D1.pair{i}, ...
        D1.victim_psd_0db_max_dbm_hz{i}, D1.margin_0db_db{i}, D1.required_additional_suppression_db{i}, D1.first_passing_scenario{i});
end

% =========================== (F) Ka max EIRP + waveguide below cutoff ===========================
WG = SD.readTable(fullfile(psdDir, 'ka_waveguide_cutoff.csv'));
Pka = str2double(T.tx_power_dbm{row('KA_DLS_TX@KAA_1')}); Gref = 31; Aitu = min(43 + 10 * log10(10 ^ ((Pka - 30) / 10)), 60);
eirp_dBW = Pka - 30 + Gref; eirpPsd = Pka + Gref - Aitu - 10 * log10(4e3);
logm(logf, 'Ka: P %.3f dBm (%.3f dBW) + G_ref %g dBi -> max EIRP %.3f dBW; ITU %.2f dBc/4 kHz -> unattenuated EIRP PSD %.4f dBm/Hz', ...
    Pka, Pka - 30, Gref, eirp_dBW, -Aitu, eirpPsd);
victims = {'GPS_L1_RX', 'GPSA_1', 'L', 'L1'; 'GPS_L1_RX', 'GPSA_2', 'L', 'L1'; 'GPS_L2_RX', 'GPSA_1', 'L', 'L2'; 'GPS_L2_RX', 'GPSA_2', 'L', 'L2'; ...
    'GPS_L5_RX', 'GPSA_1', 'L', 'L5'; 'GPS_L5_RX', 'GPSA_2', 'L', 'L5'; 'S_TC_RX', 'SBA_NADIR', 'S', 'S_TC'; 'S_TC_RX', 'SBA_ZENITH', 'S', 'S_TC'; ...
    'ISL_X_RX', 'ISL', 'ISL', 'ISL'; 'SAR_X_RX', 'SAR_ANT', 'SAR', 'SAR'};
vname = struct('L1', 'GPS L1 RX', 'L2', 'GPS L2 RX', 'L5', 'GPS L5 RX', 'S_TC', 'S-TM RX (legacy id S_TC_RX)', 'ISL', 'ISL RX', 'SAR', 'SAR RX');
tabRows = {}; kaRows = {};
for w = 1:WG.nRows
    a = str2double(WG.broad_wall_a_mm{w}) / 1e3; fc = W.cutoffTE10(a); Lsens = str2double(strsplit(WG.sensitivity_lengths_mm{w}, ';')) / 1e3;
    Lconf = str2double(WG.effective_length_mm{w}) / 1e3; lenStat = ifelse(isnan(Lconf), 'INPUT_MISSING (0 mm credited)', WG.length_status{w});
    if isnan(Lconf); Lc = 0; else; Lc = Lconf; end
    for vbk = {'L1', 'L2', 'L5', 'S_TC', 'ISL', 'SAR'}
        vb = vbk{1}; rt = victims{find(strcmp(victims(:, 4), vb), 1), 1}; b = RB.lookup(B, rt); f0 = b.channel_fc_Hz;
        al = W.alphaDbPerM(f0, a) / 1e3;
        tabRows{end+1} = {WG.waveguide{w}, WG.role{w}, vname.(vb), f0 / 1e9, a * 1e3, fc / 1e9, f0 / fc, al, lenStat, Lc * 1e3, al * Lc * 1e3, ...
            al * Lsens(1) * 1e3, al * Lsens(2) * 1e3, al * Lsens(3) * 1e3, eirp_dBW, eirpPsd, eirpPsd - al * Lc * 1e3, W.PROVENANCE, W.TAGS}; %#ok<AGROW>
    end
    for ka = {'KAA_1', 'KAA_2'}
        for q = 1:size(victims, 1)
            rt = victims{q, 1}; rm = victims{q, 2}; rfam = victims{q, 3}; vb = victims{q, 4}; b = RB.lookup(B, rt); f = RB.tuningSweep(b, nF);
            d = pos(rm) - pos(ka{1}); dist = norm(d); u = d / dist; dR = A.bodyToLocal(Rbl(rm), -u); fspl = P.fspl(f, dist);
            if strcmp(rfam, 'SAR')
                thS = acosd(max(-1, min(1, dR(3) / norm(dR)))); grx = (SP.directionGain(thS) + Gpk) * ones(1, nF);
                rxSrc = sprintf('SAR owner envelope %.2f dB at %.1f deg + peak %.0f dBi (owner HPBW estimate)', grx(1) - Gpk, thS, Gpk);
            else
                rk = [rfam '/' vb]; if ~resp.isKey(rk); resp(rk) = getR(rfam, vb); end
                rr = resp(rk); grx = arrayfun(@(x) rr.gainAt(vb, x, dR), f); rxSrc = sprintf('CST %s %s/%s RealizedGain', rr.cstCase, rfam, vb);
            end
            alf = W.alphaDbPerM(f, a) / 1e3;                              % dB/mm
            psd0 = eirpPsd + grx - fspl;                                  % no cutoff credit
            psdC = psd0 - alf * Lc * 1e3;
            req0 = max(0, nmax(psd0 - b.allowable_psd_dBmHz)); reqC = max(0, nmax(psdC - b.allowable_psd_dBmHz));
            Lreq = nmax((psd0 - b.allowable_psd_dBmHz) ./ alf);           % mm of below-cutoff guide that closes the path
            reqS = arrayfun(@(L) max(0, nmax(psd0 - alf * L * 1e3 - b.allowable_psd_dBmHz)), Lsens);
            isSar = false;
            kaRows{end+1} = {WG.waveguide{w}, WG.role{w}, [ka{1} '>' rt '@' rm], 'Ka DLS TX', ka{1}, vname.(vb), rm, vb, dist, eirp_dBW, eirpPsd, ...
                nmin(alf), lenStat, Lc * 1e3, nmin(alf) * Lc * 1e3, nmax(grx), nmin(fspl), nmax(grx - fspl), nmax(psdC), b.allowable_psd_dBmHz, ...
                ifelse(isSar, NaN, -nmax(psdC - b.allowable_psd_dBmHz)), ifelse(isSar, NaN, reqC), ifelse(isSar, 'NOT_EVALUATED', firstPass(att, reqC)), ...
                ifelse(isSar, NaN, max(0, Lreq)), ifelse(isSar, NaN, reqS(1)), ifelse(isSar, NaN, reqS(2)), ifelse(isSar, NaN, reqS(3)), ...
                firstPass(att, req0), (reqC > 0) * ceil((reqC + 10) / 10 - 1e-9) * 10, rxSrc, [W.PROVENANCE ';' W.TAGS]}; %#ok<AGROW>
        end
    end
end
writeTable(fullfile(outDir, 'task2_ka_cutoff_table.csv'), {'waveguide', 'role', 'victim', 'victim_frequency_ghz', 'broad_wall_a_mm', ...
    'te10_cutoff_ghz', 'f_over_fc', 'alpha_db_per_mm', 'effective_length_status', 'effective_length_credited_mm', 'cutoff_attenuation_credited_db', ...
    'cutoff_attenuation_5mm_db', 'cutoff_attenuation_10mm_db', 'cutoff_attenuation_20mm_db', 'max_eirp_dbw', 'unattenuated_eirp_psd_dbm_hz', ...
    'attenuated_eirp_psd_dbm_hz', 'provenance', 'tags'}, tabRows);
writeTable(fullfile(outDir, 'task2_ka_cutoff_pairs.csv'), {'waveguide', 'role', 'pair', 'attacker', 'kaa', 'victim', 'victim_mount', 'victim_band', ...
    'distance_m', 'max_eirp_dbw', 'unattenuated_eirp_psd_dbm_hz', 'alpha_min_db_per_mm', 'effective_length_status', 'effective_length_credited_mm', ...
    'cutoff_attenuation_credited_db', 'victim_gain_max_dbi', 'fspl_min_db', 'coupling_max_db', 'victim_psd_max_dbm_hz', 'allowable_psd_dbm_hz', ...
    'margin_db', 'required_additional_suppression_db', 'first_passing_scenario', 'below_cutoff_length_to_close_mm', ...
    'required_with_5mm_db', 'required_with_10mm_db', 'required_with_20mm_db', 'first_passing_scenario_without_cutoff', 'design_target_db', 'victim_response_source', 'provenance'}, kaRows);
logm(logf, 'Rows: SAR envelope %d, harmonics %d, S-TC->SAR %d, Ka table %d, Ka pairs %d', numel(envRows), numel(hRows), numel(sarRows), ...
    numel(tabRows), numel(kaRows));
fclose(logf);
