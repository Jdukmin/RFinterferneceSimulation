function test_cst_coupling(h)
%TEST_CST_COUPLING CouplingModelType.CST: tabulated S21(f) -> absoluteTransfer_dB (P7d-3, VR-446..449).
%   All S21 tables here are SYNTHETIC_TEST fixtures (no solver data is created or implied).
    h.setGroup('cst_coupling');
    TB = @rfscreen.coupling.CstS21Table;
    opt = struct('provenance', 'SYNTHETIC_TEST', 'geometryId', 'SYNTH');

    % ================= VR-446 table validation / interpolation / band reduction =================
    t = TB('A', 'B', [1e9 2e9 3e9], [-50 -40 -30], opt);
    h.eqTol('S21 at node', t.atFrequency_dB(2e9), -40, 1e-12);
    h.eqTol('S21 linear-in-dB interpolation', t.atFrequency_dB(2.5e9), -35, 1e-12);
    h.isNaNval('below range -> NaN (no extrapolation)', t.atFrequency_dB(0.9e9));
    h.isNaNval('above range -> NaN (no extrapolation)', t.atFrequency_dB(3.1e9));
    h.eqTol('range', t.range_Hz(), [1e9 3e9], 0);
    h.isTrue('coversBand inside', t.coversBand([1.5e9 2.5e9]));
    h.isFalse('coversBand partial', t.coversBand([2.5e9 3.5e9]));
    h.isNaNval('partial band -> NaN', t.bandPower_dB([2.5e9 3.5e9], 'MEAN_POWER'));
    flat = TB('A', 'B', [1e9 5e9], [-47 -47], opt);
    h.eqTol('flat table band mean', flat.bandPower_dB([2e9 3e9], 'MEAN_POWER'), -47, 1e-9);
    h.eqTol('flat table band max', flat.bandPower_dB([2e9 3e9], 'MAX'), -47, 1e-12);
    f = linspace(1e9, 3e9, 1001); ramp = TB('A', 'B', f, -50 + 10 * (f / 1e9 - 1), opt);
    h.eqTol('ramp MEAN_POWER == analytic -36.676 dB', ramp.bandPower_dB([1e9 3e9], 'MEAN_POWER'), ...
        10 * log10(1e-5 * 99 / log(10) / 2), 0.01);
    h.eqTol('ramp MAX == -30 dB', ramp.bandPower_dB([1e9 3e9], 'MAX'), -30, 1e-9);
    h.isTrue('MEAN_POWER <= MAX', ramp.bandPower_dB([1e9 3e9], 'MEAN_POWER') <= ramp.bandPower_dB([1e9 3e9], 'MAX'));
    h.eqTol('zero-width band == point value', t.bandPower_dB([2e9 2e9], 'MEAN_POWER'), -40, 1e-12);
    h.throws('active S21 (> 0 dB) rejected', @() TB('A', 'B', [1e9 2e9], [-10 3], opt), 'rfscreen:coupling:activeS21');
    h.throws('self coupling rejected', @() TB('A', 'A', [1e9 2e9], [-40 -40], opt), 'rfscreen:coupling:badS21');
    h.throws('non-monotonic frequency rejected', @() TB('A', 'B', [2e9 1e9], [-40 -40], opt), 'rfscreen:validate:monotonicVector');
    h.throws('NaN S21 rejected', @() TB('A', 'B', [1e9 2e9], [-40 NaN], opt), 'rfscreen:coupling:badS21');
    h.throws('length mismatch rejected', @() TB('A', 'B', [1e9 2e9], -40, opt), 'rfscreen:coupling:badS21');
    h.throws('bad reduction rejected', @() t.bandPower_dB([1e9 2e9], 'MEDIAN'), 'rfscreen:coupling:badReduction');

    % ================= VR-447 importers =================
    tmp = tempname(); mkdir(tmp);
    IMP = rfscreen.couplingdata.CstS21Importer();
    % CSV, GHz units + phase
    fn = fullfile(tmp, 'pair.csv');
    writeText(fn, sprintf('# synthetic\nfrequency_ghz,s21_db,phase_deg\n1.0,-60,10\n2.0,-50,20\n3.0,-40,30\n'));
    c = IMP.fromCsv(fn, 'TX1', 'RX1', opt);
    h.eqTol('CSV GHz -> Hz', c.freq_Hz, [1e9 2e9 3e9], 0);
    h.eqTol('CSV S21', c.s21_dB, [-60 -50 -40], 0);
    h.eqTol('CSV phase kept', c.phase_deg, [10 20 30], 0);
    h.eqStr('CSV source recorded', c.sourceFile, fn);
    writeText(fn, sprintf('frequency_mhz,s21_db\n1000,-60\n2000,-50\n'));
    c = IMP.fromCsv(fn, 'TX1', 'RX1', opt);
    h.eqTol('CSV MHz -> Hz', c.freq_Hz, [1e9 2e9], 0);
    h.isTrue('CSV without phase -> NaN phase', all(isnan(c.phase_deg)));
    writeText(fn, sprintf('freq,s21\n1,-60\n'));
    h.throws('CSV bad header rejected', @() IMP.fromCsv(fn, 'TX1', 'RX1', opt), 'rfscreen:coupling:badS21');
    h.throws('CSV missing file', @() IMP.fromCsv(fullfile(tmp, 'nope.csv'), 'A', 'B', opt), 'rfscreen:coupling:fileNotFound');

    % Touchstone 2-port, DB: file order S11 S21 S12 S22 -> S21 and S12 deliberately different
    fn2 = fullfile(tmp, 'two.s2p');
    writeText(fn2, sprintf(['! synthetic\n# GHZ S DB R 50\n' ...
        '1.0 -10 0 -40 90 -50 10 -12 0\n2.0 -10 0 -41 80 -51 20 -12 0\n']));
    tabs = IMP.fromTouchstone(fn2, {'P1', 'P2'}, opt);
    h.eqTol('2-port gives 2 ordered pairs', numel(tabs), 2, 0);
    t12 = pick(tabs, 'P1', 'P2'); t21 = pick(tabs, 'P2', 'P1');
    h.eqTol('P1->P2 is S21 (-40,-41 dB)', t12.s21_dB, [-40 -41], 1e-9);
    h.eqTol('P2->P1 is S12 (-50,-51 dB)', t21.s21_dB, [-50 -51], 1e-9);
    h.eqTol('Touchstone GHz -> Hz', t12.freq_Hz, [1e9 2e9], 0);
    h.eqTol('Touchstone phase of S21 (deg)', t12.phase_deg, [90 80], 1e-9);
    h.eqTol('reference impedance 50', t12.referenceImpedance_ohm, 50, 0);
    % Touchstone 3-port, RI, MHz: row-major; S(j,i) = coupling i -> j
    fn3 = fullfile(tmp, 'three.s3p');
    S = zeros(3, 3); mags = [0.1 0.01 0.02; 0.03 0.1 0.004; 0.005 0.006 0.1];   % S(r,c)
    rowTxt = '1000';
    for r = 1:3; for cc = 1:3; rowTxt = [rowTxt sprintf(' %.6g 0', mags(r, cc))]; end; end %#ok<AGROW>
    writeText(fn3, sprintf('# MHZ S RI R 50\n%s\n', rowTxt));
    t3 = IMP.fromTouchstone(fn3, {'A1', 'A2', 'A3'}, opt);
    h.eqTol('3-port gives 6 ordered pairs', numel(t3), 6, 0);
    h.eqTol('A1->A3 is S(3,1) = 0.005', pick(t3, 'A1', 'A3').s21_dB, 20 * log10(0.005), 1e-9);
    h.eqTol('A3->A1 is S(1,3) = 0.02', pick(t3, 'A3', 'A1').s21_dB, 20 * log10(0.02), 1e-9);
    h.eqTol('A2->A3 is S(3,2) = 0.006', pick(t3, 'A2', 'A3').s21_dB, 20 * log10(0.006), 1e-9);
    h.eqTol('Touchstone MHz -> Hz', pick(t3, 'A1', 'A2').freq_Hz, 1e9, 0);
    % MA format
    fma = fullfile(tmp, 'ma.s2p');
    writeText(fma, sprintf('# HZ S MA R 75\n1e9 0.1 0 0.01 45 0.02 0 0.1 0\n'));
    tm = IMP.fromTouchstone(fma, {'M1', 'M2'}, opt);
    h.eqTol('MA magnitude -> dB', pick(tm, 'M1', 'M2').s21_dB, -40, 1e-9);
    h.eqTol('MA reference impedance 75', pick(tm, 'M1', 'M2').referenceImpedance_ohm, 75, 0);
    h.throws('port-count mismatch rejected', @() IMP.fromTouchstone(fn3, {'A1', 'A2'}, opt), 'rfscreen:coupling:badPorts');
    h.throws('duplicate port ids rejected', @() IMP.fromTouchstone(fn2, {'P1', 'P1'}, opt), 'rfscreen:coupling:badPorts');
    writeText(fullfile(tmp, 'bad.s2p'), sprintf('# GHZ S DB R 50\n1.0 -10 0 -40\n'));
    h.throws('truncated record rejected', @() IMP.fromTouchstone(fullfile(tmp, 'bad.s2p'), {'P1', 'P2'}, opt), 'rfscreen:coupling:badTouchstone');
    writeText(fullfile(tmp, 'y.s2p'), sprintf('# GHZ Y DB R 50\n1.0 -10 0 -40 0 -50 0 -12 0\n'));
    h.throws('non-S parameters rejected', @() IMP.fromTouchstone(fullfile(tmp, 'y.s2p'), {'P1', 'P2'}, opt), 'rfscreen:coupling:badTouchstone');

    % ================= VR-448 CstCouplingModel =================
    ctx = rfscreen.coupling.CouplingModel.newContext();
    ctx.txAntennaId = 'A'; ctx.rxAntennaId = 'B'; ctx.frequency_Hz = 2.5e9;
    % two tables for the same pair are a duplicate
    h.throws('duplicate pair rejected', @() rfscreen.coupling.CstCouplingModel({t, ramp}), 'rfscreen:coupling:duplicateId');
    M = rfscreen.coupling.CstCouplingModel({t});
    r = M.computeCoupling(ctx);
    h.eqStr('modelType CST', r.modelType, 'CST');
    h.eqStr('validity FULL_WAVE_COUPLING', r.validity, 'FULL_WAVE_COUPLING');
    h.isTrue('isPhysicalCoupling', r.isPhysicalCoupling);
    h.eqStr('metric name', r.metricName, 'S21_PortToPort_dB');
    h.eqTol('single-frequency S21', r.metric_dB, -35, 1e-12);
    h.isTrue('provenance in warnings', any(~cellfun(@isempty, strfind(r.warnings, 'SYNTHETIC_TEST'))));
    ctx.band_Hz = [1.5e9 2.5e9];
    r = M.computeCoupling(ctx);
    h.eqTol('band MEAN_POWER default', r.metric_dB, t.bandPower_dB([1.5e9 2.5e9], 'MEAN_POWER'), 1e-12);
    Mmax = rfscreen.coupling.CstCouplingModel({t}, struct('bandReduction', 'MAX'));
    h.eqTol('band MAX option', Mmax.computeCoupling(ctx).metric_dB, -35, 1e-12);
    ctx.band_Hz = [2.5e9 3.5e9];
    r = M.computeCoupling(ctx);
    h.eqStr('band outside table -> S21_UNAVAILABLE', r.validity, 'S21_UNAVAILABLE');
    h.isNaNval('unavailable metric NaN', r.metric_dB);
    h.isFalse('unavailable is not physical', r.isPhysicalCoupling);
    ctx.band_Hz = [NaN NaN]; ctx.frequency_Hz = 4e9;
    h.eqStr('single frequency outside -> S21_UNAVAILABLE', M.computeCoupling(ctx).validity, 'S21_UNAVAILABLE');
    ctx.frequency_Hz = 2e9; ctx.rxAntennaId = 'Z';
    h.eqStr('unknown pair -> S21_UNAVAILABLE', M.computeCoupling(ctx).validity, 'S21_UNAVAILABLE');
    ctx.txAntennaId = 'B'; ctx.rxAntennaId = 'A';
    rr = M.computeCoupling(ctx);
    h.eqTol('reciprocity (reverse table) used', rr.metric_dB, -40, 1e-12);
    h.isTrue('reciprocity flagged', any(~cellfun(@isempty, strfind(rr.warnings, 'reciprocity'))));
    Mno = rfscreen.coupling.CstCouplingModel({t}, struct('assumeReciprocal', false));
    h.eqStr('reciprocity can be disabled', Mno.computeCoupling(ctx).validity, 'S21_UNAVAILABLE');
    h.throws('empty table list rejected', @() rfscreen.coupling.CstCouplingModel({}), 'rfscreen:coupling:badS21');
    h.isTrue('CouplingValidity knows S21_UNAVAILABLE', rfscreen.coupling.CouplingValidity.isValid('S21_UNAVAILABLE'));
    h.throws('CST cannot be selected by name', @() rfscreen.interference.InterferenceAnalyzer.makeCouplingModel('CST'), ...
        'rfscreen:interference:unsupportedCoupling');
    h.throws('HFSS stays reserved', @() rfscreen.coupling.HFSSCouplingModel().computeCoupling(ctx), ...
        'rfscreen:coupling:NotImplementedPhase1');

    % ================= VR-449 end-to-end through the EXISTING analyzers =================
    MB = rfscreen.mission.MissionCaseBuilder;
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    c1 = MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache, 'azStep_deg', 10, 'elStep_deg', 10));
    sc = c1.scenario;
    % test RX co-channel with the S-band TM transmitter, on the zenith TC antenna
    nm = rfscreen.receiver.ReceiverNoiseModel(struct('noiseFigure_dB', 3, 'provenance', 'SYNTHETIC_TEST'));
    flt = rfscreen.receiver.IdealBandpassFilter([2.25e9 - 1.35e6, 2.25e9 + 1.35e6], 0, -Inf);
    fe = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm', -20, 'iip3_in_dBm', -5, 'linearGain_dB', 20, ...
        'noiseFigure_dB', 3, 'provenance', 'SYNTHETIC_TEST'));
    sc.addReceiver(rfscreen.rf.RFReceiver('TEST_RX', 'SBA_ZENITH_TC', 2.25e9, 2.7e6, struct('filter', flt, ...
        'noiseModel', nm, 'interferenceCriterion', rfscreen.receiver.InterferenceCriterion('I_N_MAX', -6), ...
        'receiverFrontEnd', fe, 'compressionCriterion', rfscreen.receiver.CompressionCriterion(0), ...
        'interferenceThreshold_dBm', -100)));   % legacy Phase-1 threshold so the pair validity reaches the S21 branches
    fS = [1e9 27e9];
    tab = TB('SBA_NADIR_TM', 'SBA_ZENITH_TC', fS, [-60 -60], opt);
    cstModel = rfscreen.coupling.CstCouplingModel({tab});
    sc.activeTxIds = {'S_TM_TX@SBA_NADIR'}; sc.activeRxIds = {'TEST_RX'};
    cfg = rfscreen.config.AnalysisConfig(struct('couplingModel', 'CST'));
    out = rfscreen.interference.RfCoexistenceAnalyzer.analyze(sc, cfg, cstModel);
    pr = out.matrix.pairs{1, 1};
    h.eqStr('PairResult couplingModelType CST', pr.couplingModelType, 'CST');
    h.isTrue('PairResult physical', pr.isPhysicalCoupling);
    h.eqTol('PairResult coupling metric = S21', pr.couplingMetric_dB, -60, 1e-9);
    tx = sc.transmitters('S_TM_TX@SBA_NADIR');
    h.eqTol('received power = P + S21 (gains NOT added)', pr.receiverInputPower_dBm, tx.power_dBm - 60, 1e-9);
    h.eqStr('pair validity APPROXIMATE', pr.validity, 'APPROXIMATE');
    s = rfscreen.interference.RfCoexistenceAnalyzer.susceptibilityOf(out, 'S_TM_TX@SBA_NADIR', 'TEST_RX');
    h.eqStr('susceptibility mode ABSOLUTE_LINEAR', s.mode, 'ABSOLUTE_LINEAR');
    h.eqStr('coupling validity FULL_WAVE_COUPLING', s.couplingValidity, 'FULL_WAVE_COUPLING');
    h.eqTol('interference power = P + S21 + spectral factor', s.interferencePower_dBm, tx.power_dBm - 60 + s.spectralFactor_dB, 1e-9);
    h.eqTol('co-channel spectral factor 0 dB (TX inside RX filter)', s.spectralFactor_dB, 0, 1e-6);
    h.isTrue('I/N finite', isfinite(s.iOverN_dB));
    h.eqTol('I/N = P_I - N', s.iOverN_dB, s.interferencePower_dBm - s.noisePower_dBm, 1e-9);
    h.eqStr('I/N criterion evaluated: FAIL (I/N >> -6 dB)', s.passFail, 'FAIL');
    h.eqTol('confidence reflects full-wave coupling', s.confidence, 0.95, 1e-9);
    % the SAME pair with pattern-only coupling stays relative (unchanged behaviour)
    outP = rfscreen.interference.RfCoexistenceAnalyzer.analyze(sc);
    sP = rfscreen.interference.RfCoexistenceAnalyzer.susceptibilityOf(outP, 'S_TM_TX@SBA_NADIR', 'TEST_RX');
    h.eqStr('pattern-only unchanged: ABSOLUTE_COUPLING_UNAVAILABLE', sP.validity, 'ABSOLUTE_COUPLING_UNAVAILABLE');
    % missing S21 for the pair -> no absolute number, explicit
    cstEmpty = rfscreen.coupling.CstCouplingModel({TB('X1', 'X2', fS, [-60 -60], opt)});
    outE = rfscreen.interference.RfCoexistenceAnalyzer.analyze(sc, cfg, cstEmpty);
    sE = rfscreen.interference.RfCoexistenceAnalyzer.susceptibilityOf(outE, 'S_TM_TX@SBA_NADIR', 'TEST_RX');
    h.eqStr('no S21 table: absolute withheld', sE.validity, 'ABSOLUTE_COUPLING_UNAVAILABLE');
    h.eqStr('no S21 table: pair requires full-wave', outE.matrix.pairs{1, 1}.validity, 'REQUIRES_FULL_WAVE_VERIFICATION');
    % frequency dependence: S21 table that varies across the TX band changes the transfer
    fv = linspace(2.2e9, 2.3e9, 101);
    tabV = TB('SBA_NADIR_TM', 'SBA_ZENITH_TC', fv, -60 + 20 * (fv - 2.2e9) / 1e8, opt);   % -60 .. -40 dB
    outV = rfscreen.interference.RfCoexistenceAnalyzer.analyze(sc, cfg, rfscreen.coupling.CstCouplingModel({tabV}));
    mV = outV.matrix.pairs{1, 1}.couplingMetric_dB;
    h.eqTol('band-reduced S21 over the overlap (2.2485-2.2515 GHz)', mV, tabV.bandPower_dB([2.25e9 - 1.35e6, 2.25e9 + 1.35e6], 'MEAN_POWER'), 1e-9);
    h.isTrue('frequency-dependent S21 differs from the flat table', abs(mV - (-60)) > 1);
    % nonlinear receiver path consumes the same absolute transfer
    nl = rfscreen.nonlinear.NonlinearSusceptibilityAnalyzer.analyze(sc, 'TEST_RX', cfg, struct('couplingModel', cstModel));
    h.eqStr('nonlinear validity VALID with absolute S21', nl.validity, 'VALID');
    h.eqTol('LNA-input power = P + S21 (no preselector)', nl.compression.aggregateInputPower_dBm, tx.power_dBm - 60, 1e-9);
    h.eqTol('compression margin = P1dB - P_agg', nl.compression.compressionMargin_dB, -20 - (tx.power_dBm - 60), 1e-9);
    nlP = rfscreen.nonlinear.NonlinearSusceptibilityAnalyzer.analyze(sc, 'TEST_RX', rfscreen.config.AnalysisConfig.default());
    h.eqStr('nonlinear pattern-only unchanged', nlP.validity, 'ABSOLUTE_COUPLING_UNAVAILABLE');

    % ================= architecture guards =================
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    cDir = fullfile(repoRoot, 'src', '+rfscreen', '+coupling');
    h.ok('coupling package imports no geometry/antenna', isempty(scan(cDir, {'rfscreen.geometry', 'rfscreen.antenna', 'rfscreen.scenario'})));
    h.ok('no solver execution in coupling', isempty(scan(cDir, {'actxserver', 'system(', 'dos('})));
    h.ok('no invented S21 constants in the model', isempty(scan(fullfile(cDir, 'CstCouplingModel.m'), {'FreeSpacePathLoss', 'fspl', '4 * pi'})));
    delete(fn); delete(fn2); delete(fn3); delete(fma); delete(fullfile(tmp, 'bad.s2p')); delete(fullfile(tmp, 'y.s2p'));
    rmdir(tmp);
end

function t = pick(tabs, tx, rx)
    t = [];
    for i = 1:numel(tabs)
        if strcmp(tabs{i}.txAntennaId, tx) && strcmp(tabs{i}.rxAntennaId, rx); t = tabs{i}; return; end
    end
    error('table %s -> %s not found', tx, rx);
end
function writeText(p, txt)
    fid = fopen(p, 'w'); fwrite(fid, txt); fclose(fid);
end
function hits = scan(pathIn, tokens)
    hits = {};
    if exist(pathIn, 'dir') == 7
        items = dir(pathIn); files = {};
        for i = 1:numel(items)
            if items(i).isdir; continue; end
            if numel(items(i).name) > 2 && strcmp(items(i).name(end-1:end), '.m'); files{end+1} = fullfile(pathIn, items(i).name); end %#ok<AGROW>
        end
    else
        files = {pathIn};
    end
    for i = 1:numel(files)
        txt = fileread(files{i});
        for k = 1:numel(tokens)
            if ~isempty(strfind(txt, tokens{k})); hits{end+1} = sprintf('%s in %s', tokens{k}, files{i}); end %#ok<AGROW>
        end
    end
end
