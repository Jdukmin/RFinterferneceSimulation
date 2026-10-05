1;  % Octave script -- Claude worker validation of the OOB/spurious analysis (no shared code changed)
%   octave-cli --no-gui --norc --eval "run('output/claude/validate_oob_spurious.m')"
here = fileparts(mfilename('fullpath')); if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
repo = fileparts(fileparts(here)); addpath(fullfile(repo, 'src')); addpath(fullfile(repo, 'tests'));
h = testutil.Harness(); h.setGroup('claude_oob_spurious');
V = rfscreen.psd.VictimBandPsdPath; RB = rfscreen.psd.ReceiverBaseline;
[S, X] = rfscreen.psd.EmissionMaskTable.read(fullfile(here, 'inputs', 'tx_emission_sources_claude.csv'));
var = cellfun(@(x) x.variant, X, 'UniformOutput', false);
P = struct('S_TM_TX', 36.9897, 'ISL_X_TX', 30, 'KA_DLS_TX', 48.451);
% 1. RR AP3 attenuation = min(43 + 10 log P, 60) per TX (whichever less stringent)
for t = fieldnames(P).'
    Pw = 10 ^ ((P.(t{1}) - 30) / 10); exp = -min(43 + 10 * log10(Pw), 60);
    rows = S(strcmp(var, 'PRIMARY_RR_AP3') & cellfun(@(s) strcmp(s.txSystem, t{1}), S));
    h.eqTol([t{1} ' AP3 level (dBc in 4 kHz)'], cellfun(@(s) s.level, rows), exp * ones(1, numel(rows)), 1e-3);
    h.isTrue([t{1} ' AP3 rows are 4 kHz / ANTENNA_PORT / REGULATORY_LIMIT'], all(cellfun(@(s) s.refBw_Hz == 4000 && ...
        strcmp(s.referencePlane, 'ANTENNA_PORT') && strcmp(s.assumptionClass, 'REGULATORY_LIMIT'), rows)));
    % 2. dBc per 4 kHz -> broadband-equivalent dBm/Hz
    h.eqTol([t{1} ' broadband PSD = P + level - 10log10(4000)'], rows{1}.psdDbmHz(P.(t{1})), P.(t{1}) + exp - 10 * log10(4000), 1e-9);
end
h.eqTol('S_TM AP3 absolute = -13.0 dBm / 4 kHz', P.S_TM_TX - 49.9897, -13.0, 1e-3);
h.eqTol('Ka AP3 absolute = 10 log P - 30 = -11.55 dBm / 4 kHz (SM.329 Table 8)', 10 * log10(70) - 30, P.KA_DLS_TX - 60, 2e-3);
h.isTrue('ECSS rows are -60 dBc / 4 kHz', all(cellfun(@(s) s.level == -60 && s.refBw_Hz == 4000, S(strcmp(var, 'SENS_ECSS_50_05C')))));
% 3. discrete spurs are not forced into dBm/Hz
t = rfscreen.psd.EmissionSpec.blank(); t.tx_system = 'S_TM_TX'; t.victim_band = 'L1'; t.frequency_hz = 1.575e9;
t.emission_type = 'DISCRETE_SPUR'; t.level = -49.99; t.unit = 'dBc'; t.reference_bandwidth_hz = 4000; t.reference_plane = 'ANTENNA_PORT';
t.standard_or_source = 'RR AP3'; t.provenance = 'test'; t.assumption_class = 'REGULATORY_LIMIT';
sp = rfscreen.psd.EmissionSpec(t);
h.throws('discrete spur has no PSD', @() sp.psdDbmHz(36.99), 'rfscreen:psd:notAPsd');
h.eqTol('discrete spur power = -13 dBm', sp.powerDbm(36.9897), -13.0, 1e-3);
% 4. reference cross-check unchanged (-120 dBm/Hz -> 60 dB -> -180 dBm/Hz, +2 dB vs GPS -178)
[R, RX] = rfscreen.psd.EmissionMaskTable.read(fullfile(repo, 'data', 'rfi_psd', 'reference_scenarios.csv'));
FS = rfscreen.psd.FilterScenario.read(fullfile(repo, 'data', 'rfi_psd', 'filter_scenarios.csv'));
B = RB.read(fullfile(repo, 'data', 'rfi_psd', 'receiver_baseline.csv')); bG = RB.lookup(B, 'GPS_L1_RX');
r60 = V.evaluate(bG.channel_fc_Hz, 0, NaN, bG.allowable_psd_dBmHz, R, NaN, FS{3}, 0);
h.eqTol('reference: -180 dBm/Hz after 60 dB', r60.port_psd_dBmHz, -180, 1e-12);
h.eqTol('reference: +2 dB margin vs -178', r60.margin_dB, 2, 1e-12);
h.isTrue('reference scenario not in the Claude source table', ~any(cellfun(@(s) strcmp(s.txSystem, 'REF_S_TX'), S)));
% 5. secondary blocker values preserved in pair_results.csv
T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(here, 'results', 'pair_results.csv'));
g = @(pid) str2double(T.oob_blocker_port_A_dbm{find(strcmp(T.case_id, 'CASE_SBA1_L1') & strcmp(T.pair_id, pid), 1)});
h.eqTol('blocker S-TM@ZENITH -> GPSA_1 = -21.3 dBm', g('S_TM_TX@SBA_ZENITH>GPS_L1_RX@GPSA_1'), -21.32, 0.01);
h.eqTol('blocker S-TM@NADIR -> S-TC@ZENITH = -32.3 dBm', g('S_TM_TX@SBA_NADIR>S_TC_RX@SBA_ZENITH'), -32.29, 0.01);
% 6. primary result regression (this analysis)
Q = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(here, 'results', 'oob_spurious', 'pair_margin_summary.csv'));
q = @(tx, rx, v) find(strcmp(Q.tx_system, tx) & strcmp(Q.rx_system, rx) & strcmp(Q.variant, v), 1);
k = q('S_TM_TX@SBA_ZENITH', 'S_TC_RX@SBA_NADIR', 'PRIMARY_RR_AP3');
h.eqTol('S-TM -> opposite S-TC 0 dB margin = source + C - allowable', str2double(Q.margin_0db{k}), ...
    -177 - (-49.0206 + str2double(Q.coupling_max_db{k})), 1e-3);
h.eqStr('S-TM -> opposite S-TC first passing scenario', Q.first_passing_scenario{k}, 'FILTER_60DB');
% 7. bound functions
ka = 2 * pi * 2.11e9 / 299792458 * sqrt(0.11 ^ 2 + 0.0461 ^ 2);
h.eqTol('Harrington D at 2.11 GHz (KAA sphere)', 10 * log10(ka ^ 2 + 2 * ka), 15.82, 0.02);
fc = 299792458 / (2 * 10.668e-3);
h.eqTol('WR-42 cut-off 14.05 GHz', fc / 1e9, 14.05, 0.01);
h.eqTol('WR-42 2 lambda_c attenuation at 10.6 GHz', 20 / log(10) * 4 * pi * sqrt(1 - (10.6e9 / fc) ^ 2), 71.6, 0.2);
ok = h.report();
fid = fopen(fullfile(here, 'results', 'oob_spurious', 'validation_log.txt'), 'w');
msg = 'FAILURES (see console)'; if ok; msg = sprintf('ALL PASS (%d checks)', h.nPass); end
fprintf(fid, 'Claude OOB/spurious validation %s: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'), msg);
fclose(fid);
