function test_cal_runner(h)
%TEST_CAL_RUNNER main('--cal') end-to-end on a SYNTHETIC_TEST data/cal-like tree in a temp dir + no-data run.
%   Verifies provenance columns and recomputes one pair independently through the existing engine terms.
    h.setGroup('cal_runner');
    repo = fileparts(fileparts(mfilename('fullpath')));
    addpath(repo);                                   % main.m lives at the repository root
    tmp = tempname(); mkdir(tmp); cleanup = onCleanup(@() rmdir(tmp, 's')); %#ok<NASGU>
    S = testutil.CalSynthetic;
    root = fullfile(tmp, 'cal'); out = fullfile(tmp, 'out');
    S.buildTree(root, 15);
    plots = rfscreen.cal.CalPlotter.setupGraphics();
    res = main('--cal', 'calDir', root, 'outDir', out, 'plots', plots, 'verbose', false);
    R = res.rows;
    for f = {'validation/pattern_inventory.csv', 'validation/pattern_binding.csv', 'rfi/pair_results.csv', ...
            'rfi/summary.csv', 'rfi/run_summary.txt'}
        h.isTrue(['output ' f{1}], exist(fullfile(out, f{1}), 'file') == 2);
    end
    h.isTrue('32 files valid', res.catalog.nValid() == 32);
    inv = fileread(fullfile(out, 'validation', 'pattern_inventory.csv'));
    hdr = strsplit(strtok(inv, sprintf('\n')), ',');
    need = {'rel_path', 'family', 'installation_id', 'pattern_type', 'status', 'failure_stage', 'error_identifier', ...
        'error_message', 'n_rows', 'n_columns', 'theta_min_deg', 'theta_max_deg', 'n_theta', 'theta_step_deg', 'phi_min_deg', ...
        'phi_max_deg', 'n_phi', 'phi_step_deg', 'expected_samples', 'actual_samples', 'duplicate_samples', 'missing_samples', ...
        'source_frame', 'source_simulation_frequency_ghz', 'frequency_treatment', 'n_phi_at_theta0', 'n_phi_at_theta180'};
    h.isTrue('inventory carries the diagnostic columns', all(ismember(need, hdr)));
    jf = fullfile(out, 'validation', 'pattern_diagnostics.json');
    h.isTrue('diagnostics JSON written', exist(jf, 'file') == 2);
    if exist('jsondecode', 'builtin') || exist('jsondecode', 'file')
        J = jsondecode(fileread(jf));
        h.isTrue('diagnostics JSON parses: one record per file', numel(J.files) == numel(res.catalog.entries));
    end
    h.isTrue('run summary appendix lists every file', ~isempty(strfind(res.runSummary, '[CAL] gps/GPS_GPSA1_f1.2.txt')) && ...
        ~isempty(strfind(res.runSummary, 'bound as surrogate for: L5 / L2 / L1')));
    if plots
        h.isTrue('64 pattern-coordinate figures', numel(res.figures.pattern) == 64 && ...
            exist(fullfile(out, 'pattern_plots', 'kaa', 'RFC_KAA_f10.6_XZ.png'), 'file') == 2);
        h.isTrue('6 installed 3D figures', numel(res.figures.installed3d) == 6 && ...
            exist(fullfile(out, 'installed_plots', '3d', 'GPSA1_L1L2L5_INSTALLED_3D.png'), 'file') == 2 && ...
            exist(fullfile(out, 'installed_plots', '3d', 'SBA_NADIR_2p06_INSTALLED_3D.png'), 'file') == 2);
        h.isTrue('18 body-cut figures', numel(res.figures.bodyCuts) == 18 && ...
            exist(fullfile(out, 'installed_plots', 'body_cuts', 'SBA_ZENITH_2p25_BODY_XY.png'), 'file') == 2);
        h.isTrue('12 antenna-local cut figures', numel(res.figures.localCuts) == 12 && ...
            exist(fullfile(out, 'installed_plots', 'local_cuts', 'SBA_NADIR_2p06_LOCAL_XZ.png'), 'file') == 2);
        h.isTrue('no figure failures', isempty(res.figures.failed));
    else
        h.pass('figures skipped: no graphics toolkit');
    end
    h.isFalse('KAA never a victim', any(strncmp({R.rx_installation}, 'KAA', 3)));
    h.isFalse('no self pair', any(strcmp({R.tx_installation}, {R.rx_installation})));
    h.isFalse('SBA not an attacker in its own TX band (STM)', any(strcmp({R.victim_band}, 'STM') & strncmp({R.tx_installation}, 'SBA', 3)));
    k = find(strcmp({R.tx_installation}, 'KAA_1') & strcmp({R.rx_installation}, 'GPSA_1') & strcmp({R.victim_band}, 'L1'));
    r = R(k);
    h.isTrue('KAA->GPSA_1 L1: one row', numel(k) == 1);
    h.eqStr('KAA->L1 TX file at victim frequency', r.tx_pattern_file, 'kaa/RFC_KAA_f1.5754.txt');
    h.eqStr('GPSA_1 RX installed file', r.rx_pattern_file, 'gps/GPS_GPSA1_f1.2.txt');
    h.isTrue('TX FREE_SPACE / RX INSTALLED', strcmp(r.tx_pattern_type, 'FREE_SPACE') && strcmp(r.rx_pattern_type, 'INSTALLED'));
    h.isTrue('provenance strings separate', ~isempty(strfind(r.rx_pattern_provenance, 'installedSource=CST')) && ...
        isempty(strfind(r.tx_pattern_provenance, 'installed')) && isempty(strfind([r.tx_pattern_provenance r.rx_pattern_provenance], 'APPROX')));
    h.eqTol('analysis frequency = L1 canonical', r.analysis_frequency_hz, 1575.42e6, 1e-3);
    % independent recomputation
    m = res.model; iT = m.installations('KAA_1'); iR = m.installations('GPSA_1');
    d = iR.position_m - iT.position_m; dist = norm(d); u = d / dist;
    pT = res.catalog.find('KAA', '', 'FREE_SPACE', 1575.42e6); pR = res.catalog.find('GPS', 'GPSA_1', 'INSTALLED', 1575.42e6);
    M = rfscreen.kaa.CstLocalFrameAdapter.localToAntenna();
    % free-space TX: body -> antenna -> CST local; installed RX: raw body-frame grid queried with -u as is
    gT = pT.native.gainAtLocal(M.' * (iT.R_BA.' * u)); gR = pR.native.gainAtDirection(-u);
    [thR, phR] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi(-u);
    h.isTrue('RX installed: raw (theta_B, phi_B) of -u reported, body source frame', abs(r.rx_cst_theta_deg - thR) < 1e-9 && ...
        abs(mod(r.rx_cst_phi_deg - phR + 180, 360) - 180) < 1e-9 && strcmp(r.rx_pattern_source_frame, 'SPACECRAFT_BODY_FIXED') && ...
        strcmp(r.tx_pattern_source_frame, 'CST_LOCAL'));
    h.isTrue('RX provenance: GPS surrogate of the 1.2 GHz CST solve', ~isempty(strfind(r.rx_pattern_provenance, 'SURROGATE')));
    h.eqTol('TX directional gain', r.tx_gain_dbi, gT, 1e-9);
    h.eqTol('RX directional gain', r.rx_gain_dbi, gR, 1e-9);
    h.eqTol('distance', r.distance_m, dist, 1e-12);
    h.eqTol('FSPL (existing PsdMath)', r.fspl_db, 20 * log10(4 * pi * dist * 1575.42e6 / 299792458), 1e-9);
    h.eqTol('C_EM = Gtx + Grx - FSPL', r.coupling_db, gT + gR - r.fspl_db, 1e-9);
    h.eqTol('KAA ITU source -60 dBc/4 kHz at 48.451 dBm', r.source_psd_dbm_hz, 48.4510 - 60 - 10 * log10(4000), 1e-9);
    h.eqTol('victim PSD = source + C_EM', r.victim_psd_dbm_hz, r.source_psd_dbm_hz + r.coupling_db, 1e-9);
    h.eqTol('GPS L1 criterion -178 dBm/Hz', r.allowable_psd_dbm_hz, -178, 1e-12);
    h.eqTol('margin = allowable - victim PSD', r.margin_db, -178 - r.victim_psd_dbm_hz, 1e-9);
    h.eqStr('route', r.coupling_route, 'PATTERN_GTX_GRX_FSPL');
    h.isTrue('status/verdict consistent', strcmp(r.status, 'EVALUATED') && any(strcmp(r.verdict, {'PASS', 'FAIL'})));
    s = R(strcmp({R.victim_band}, 'S_TC') & strcmp({R.tx_installation}, 'SBA_NADIR'));
    h.isTrue('SBA->opposite SBA S_TC: both installed 2.06', numel(s) == 1 && strcmp(s.rx_installation, 'SBA_ZENITH') && ...
        strcmp(s.tx_pattern_file, 'sba/RFC_SBA_NADIR_f2.06.txt') && strcmp(s.rx_pattern_file, 'sba/RFC_SBA_ZENITH_f2.06.txt'));
    kst = R(strcmp({R.victim_band}, 'S_TC') & strncmp({R.tx_installation}, 'KAA', 3));
    h.isTrue('KAA->S_TC 2.06: pattern missing, not substituted', ~isempty(kst) && all(strcmp({kst.status}, 'INPUT_MISSING_PATTERN')) && ...
        all(isnan([kst.coupling_db])) && all(strcmp({kst.verdict}, 'UNKNOWN')));
    isl = R(strcmp({R.victim_band}, 'ISL'));
    h.isTrue('ISL victim uses RFC_ISL_f10.6 free-space', all(strcmp({isl.rx_pattern_file}, 'isl/RFC_ISL_f10.6.txt')) && ...
        all(strcmp({isl.rx_pattern_type}, 'FREE_SPACE')));
    sar = R(strcmp({R.rx_installation}, 'SAR_ANT'));
    h.isTrue('SAR victim: owner engineering baseline, not CST', ~isempty(sar) && all(strcmp({sar.rx_pattern_type}, 'OWNER_ENGINEERING_BASELINE')));
    stm = R(strcmp({R.victim_band}, 'STM') & strcmp({R.tx_installation}, 'ISL'));
    h.isTrue('ISL->SBA STM: RFC_ISL_f2.25 + installed SBA 2.25', all(strcmp({stm.tx_pattern_file}, 'isl/RFC_ISL_f2.25.txt')) && ...
        all(strcmp({stm.rx_pattern_type}, 'INSTALLED')));
    ev = strcmp({R.status}, 'EVALUATED');
    h.isTrue('every evaluated row carries criterion / margin / route', all(isfinite([R(ev).margin_db])) && ...
        all(~cellfun(@isempty, {R(ev).receiver_criterion})) && all(~cellfun(@isempty, {R(ev).source_provenance})));
    txt = fileread(fullfile(out, 'rfi', 'run_summary.txt'));
    h.isTrue('run summary leads with the conclusion', ~isempty(strfind(txt, '1. 결론')) && ~isempty(strfind(txt, '대표 worst case')));

    % ---- no data: INPUT_MISSING everywhere, nothing synthesised ----
    empty = fullfile(tmp, 'empty'); mkdir(empty);
    r0 = main('--cal', 'calDir', empty, 'outDir', fullfile(tmp, 'out0'), 'plots', false, 'verbose', false);
    h.isTrue('no data: all rows INPUT_MISSING_PATTERN', numel(r0.rows) == numel(R) && all(strcmp({r0.rows.status}, 'INPUT_MISSING_PATTERN')));
    h.isTrue('no data: no gain values produced', all(isnan([r0.rows.tx_gain_dbi])) && all(isnan([r0.rows.coupling_db])));
    inv = fileread(fullfile(tmp, 'out0', 'validation', 'pattern_inventory.csv'));
    h.isTrue('no data: inventory says INPUT_MISSING', ~isempty(strfind(inv, 'INPUT_MISSING')));
    h.isTrue('no data: summary states input missing', ~isempty(strfind(r0.runSummary, '입력 미확보')));
end
