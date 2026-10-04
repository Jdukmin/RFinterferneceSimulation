function test_mission_cases(h)
%TEST_MISSION_CASES Six RFC/RFI analysis cases (SBA1/SBA4 x GPS L1/L2/L5) (VR-439..VR-442).
%   Uses the real repository pattern datasets through the existing Phase-2 pipeline.
%   A coarse 10 deg assembly grid keeps the run short; every checked angle is a grid node.
    h.setGroup('mission_cases');
    MB = rfscreen.mission.MissionCaseBuilder;
    repoRoot = fileparts(fileparts(mfilename('fullpath')));

    % ================= VR-439 case catalogue =================
    cases = MB.listCases();
    h.eqTol('6 cases', numel(cases), 6, 0);
    combos = strcat({cases.sbaVariant}, '_', {cases.gpsBand});
    exp = {'SBA1_L1','SBA1_L2','SBA1_L5','SBA4_L1','SBA4_L2','SBA4_L5'};
    h.isTrue('cases = {SBA1,SBA4} x {L1,L2,L5}', isequal(sort(combos), sort(exp)));
    h.eqTol('case ids unique', numel(unique({cases.caseId})), 6, 0);
    h.throws('unknown case rejected', @() MB.buildCase('CASE_NOPE'), 'rfscreen:mission:unknownCase');

    % ================= VR-440 ISL dataset (CST ISL_C4_CUP_R14P7) =================
    islDir = fullfile(repoRoot, 'data', 'Xband_ISL');
    for f = {'f10.3', 'f10.4', 'f10.5'}
        for pl = {'XZ', 'YZ'}
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(islDir, [f{1} '_' pl{1} '.csv']));
            th = str2double(T.theta);
            h.isTrue(sprintf('ISL %s_%s: 360 rows theta 0..359', f{1}, pl{1}), T.nRows == 360 && isequal(th, 0:359));
        end
    end
    T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(islDir, 'f10.6_XZ.csv'));
    isl0 = str2double(T.gain{1}); isl30 = str2double(T.gain{31});
    h.eqTol('ISL 10.6 GHz boresight 10.1424 dBi', isl0, 10.142443733246253, 0);

    % ================= VR-441 build all six cases =================
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    opts = struct('patternCache', cache, 'azStep_deg', 10, 'elStep_deg', 10);
    built = cell(1, 6);
    expFuncs = sort({'SBA_NADIR_TC','SBA_NADIR_TM','SBA_ZENITH_TC','SBA_ZENITH_TM','GPSA_1','GPSA_2', ...
        'KAA_1','KAA_2','ISL'});
    gpsBand_Hz = struct('L1', [1563 1588] * 1e6, 'L2', [1207 1227.6] * 1e6, 'L5', [1164 1189] * 1e6);
    for i = 1:numel(cases)
        cs = cases(i);
        c = MB.buildCase(cs.caseId, opts);
        built{i} = c;
        sc = c.scenario; id = cs.caseId;
        ok = true; try; sc.validate(); catch; ok = false; end
        h.isTrue([id ' scenario validates'], ok);
        h.isTrue([id ' 9 RF functions (SAR excluded)'], isequal(sort(sc.antennas.keys()), expFuncs));
        h.isTrue([id ' SAR installation kept for geometry'], sc.installations.isKey('SAR_ANT'));
        h.eqTol([id ' 8 structures'], sc.structures.Count, 8, 0);
        expPat = sort({[cs.sbaVariant '_TC'], [cs.sbaVariant '_TM'], ['GPS_' cs.gpsBand], 'ISL_10P6', 'KAA_KA_26P25'});
        h.isTrue([id ' pattern set'], isequal(sort(sc.patterns.keys()), expPat));
        a = sc.antennas('SBA_NADIR_TC'); h.eqStr([id ' SBA_NADIR_TC pattern'], a.patternId, [cs.sbaVariant '_TC']);
        h.eqStr([id ' SBA_NADIR_TC role RX'], a.role, 'RX');
        a = sc.antennas('SBA_ZENITH_TM'); h.eqStr([id ' SBA_ZENITH_TM pattern'], a.patternId, [cs.sbaVariant '_TM']);
        h.eqStr([id ' SBA_ZENITH_TM role TX'], a.role, 'TX');
        h.eqStr([id ' SBA_ZENITH_TM on SBA_ZENITH mount'], a.installationId, 'SBA_ZENITH');
        for g = {'GPSA_1', 'GPSA_2'}
            a = sc.antennas(g{1});
            h.eqStr([id ' ' g{1} ' pattern'], a.patternId, ['GPS_' cs.gpsBand]);
            h.eqTol([id ' ' g{1} ' band'], [a.freqMin_Hz a.freqMax_Hz], gpsBand_Hz.(cs.gpsBand), 0);
        end
        a = sc.antennas('ISL'); h.eqStr([id ' ISL pattern 10.6 GHz'], a.patternId, 'ISL_10P6');
        h.eqTol([id ' ISL band'], [a.freqMin_Hz a.freqMax_Hz], [10.55e9 10.65e9], 0);
        h.isTrue([id ' warns SAR deferred'], any(~cellfun(@isempty, strfind(c.warnings, 'SAR_ANT'))));
        h.isTrue([id ' no KAA candidate warning (bound to CST surrogate)'], isempty(strfind(strjoin(c.warnings, '|'), 'CANDIDATE')));
        a = sc.antennas('KAA_1'); h.eqStr([id ' KAA_1 pattern = CST reflector surrogate'], a.patternId, 'KAA_KA_26P25');
        nGps = 2;      % one GPS receiver per GPSA in every case (L1 / L2 / L5 baseline of the case band)
        h.eqTol([id ' TX count (2 TM + 2 KAA + ISL)'], sc.transmitters.Count, 5, 0);
        h.eqTol([id ' RX count (2 TC + ISL + 2 GPS of the case band)'], sc.receivers.Count, 3 + nGps, 0);
        h.isFalse([id ' SAR RF not registered'], sc.transmitters.isKey('SAR_X_TX') || sc.receivers.isKey('SAR_X_RX'));
        h.isTrue([id ' warns P1dB/IIP3 unknown'], any(~cellfun(@isempty, strfind(c.warnings, 'P1dB'))));
        h.isTrue([id ' GPS receivers match the case band'], sc.receivers.isKey(['GPS_' cs.gpsBand '_RX@GPSA_1']) && ...
            sc.receivers.isKey(['GPS_' cs.gpsBand '_RX@GPSA_2']));
        fs = c.functions(strcmp({c.functions.functionId}, 'SAR_ANT'));
        h.isTrue([id ' SAR function not included'], ~fs.included && strcmp(fs.bindingStatus, 'DEFERRED_CLOSED_NETWORK'));
    end
    h.eqTol('pattern cache: 9 distinct patterns over 6 cases', cache.Count, 9, 0);

    % ================= VR-444 operating modes =================
    h.eqStr('default mode is explicit SCREENING_ALL_TX', built{1}.mode.modeId, 'SCREENING_ALL_TX');
    h.isTrue('default mode flagged screening', built{1}.mode.isScreening);
    h.eqStr('scenario carries operatingModeId', built{1}.scenario.operatingModeId, 'SCREENING_ALL_TX');
    h.eqTol('all-TX: 5 active TX', numel(built{1}.scenario.resolveActiveTxIds()), 5, 0);
    h.isTrue('screening warning says not an operating mode', any(~cellfun(@isempty, strfind(built{1}.warnings, 'not an operating mode'))));
    modes = MB.listModes();
    h.isTrue('modes: 1 screening + 2 nominal', isequal(sort({modes.kind}), {'NOMINAL','NOMINAL','SCREENING'}));
    cN = MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache, 'modeId', 'NOM_NADIR_KAA1'));
    h.isFalse('nominal mode not screening', cN.mode.isScreening);
    h.isTrue('nominal active TX = nadir TM + KAA_1 + ISL', isequal(sort(cN.scenario.resolveActiveTxIds()), ...
        sort({'S_TM_TX@SBA_NADIR', 'KA_DLS_TX@KAA_1', 'ISL_X_TX'})));
    h.eqTol('nominal active RX count (TC nadir + 2 GPS + ISL)', numel(cN.scenario.resolveActiveRxIds()), 4, 0);
    h.isFalse('zenith TM inactive in nadir mode', any(strcmp(cN.scenario.resolveActiveTxIds(), 'S_TM_TX@SBA_ZENITH')));
    h.isFalse('KAA_2 inactive in nadir mode', any(strcmp(cN.scenario.resolveActiveTxIds(), 'KA_DLS_TX@KAA_2')));
    h.isTrue('nominal warns PROVISIONAL', any(~cellfun(@isempty, strfind(cN.warnings, 'PROVISIONAL'))));
    h.eqTol('all registered TX remain registered', cN.scenario.transmitters.Count, 5, 0);
    outN = rfscreen.interference.InterferenceAnalyzer.analyze(cN.scenario);
    h.isTrue('matrix follows the mode (3 TX x 4 RX)', numel(outN.txIds) == 3 && numel(outN.rxIds) == 4);
    cL2 = MB.buildCase('CASE_SBA1_L2', struct('patternCache', cache, 'modeId', 'NOM_ZENITH_KAA2'));
    h.eqTol('L2 nominal: L1/L5 receivers skipped, RX = TC + ISL + 2 L2', numel(cL2.scenario.resolveActiveRxIds()), 4, 0);
    h.isTrue('L2 nominal warns skipped GPS', any(~cellfun(@isempty, strfind(cL2.warnings, 'skipped'))));
    h.throws('unknown mode rejected', @() MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache, 'modeId', 'NOPE')), 'rfscreen:mission:unknownMode');

    % ================= VR-443 RF baseline numbers (CASE_SBA1_L1 has every system) =================
    sc = built{1}.scenario; c1 = built{1};

    % ================= VR-445 receiver front-end data path (P7d-6) =================
    for q = 1:numel(c1.rfSystems)
        if strcmp(c1.rfSystems(q).kind, 'RX')
            h.isNaNval([c1.rfSystems(q).systemId ' P1dB unknown (NaN)'], c1.rfSystems(q).p1dB_in_dBm);
            h.isNaNval([c1.rfSystems(q).systemId ' IIP3 unknown (NaN)'], c1.rfSystems(q).iip3_in_dBm);
        end
    end
    noFe = true; rkeys = c1.scenario.receivers.keys();
    for q = 1:numel(rkeys)
        rq = c1.scenario.receivers(rkeys{q}); noFe = noFe && isempty(rq.receiverFrontEnd);
    end
    h.isTrue('baseline creates no ReceiverFrontEnd', noFe);
    srcDs = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
    tmpDs = tempname(); mkdir(tmpDs);
    dsFiles = dir(srcDs);
    for q = 1:numel(dsFiles)
        if ~dsFiles(q).isdir; copyfile(fullfile(srcDs, dsFiles(q).name), fullfile(tmpDs, dsFiles(q).name)); end
    end
    rfTxt = fileread(fullfile(srcDs, 'rf_systems.csv'));
    lines = regexp(rfTxt, '\r\n|\r|\n', 'split'); iL = find(strncmp(lines, 'ISL_X_RX,', 9));
    fld = regexp(lines{iL}, ',', 'split');                 % 22 fields; p1dB=11 iip3=12 frontend_prov=22
    fld{11} = '-30'; fld{12} = '-10'; fld{22} = 'SYNTHETIC_TEST';
    lines{iL} = strjoin(fld, ',');
    fid = fopen(fullfile(tmpDs, 'rf_systems.csv'), 'w'); fwrite(fid, strjoin(lines, char(10))); fclose(fid);
    cF = MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache, 'datasetDir', tmpDs));
    rxI = cF.scenario.receivers('ISL_X_RX');
    h.isTrue('front end created when P1dB/IIP3 given', ~isempty(rxI.receiverFrontEnd));
    h.eqTol('P1dB applied', rxI.receiverFrontEnd.p1dB_in_dBm, -30, 0);
    h.eqTol('IIP3 applied', rxI.receiverFrontEnd.iip3_in_dBm, -10, 0);
    h.eqStr('front-end provenance recorded', rxI.receiverFrontEnd.provenance, 'SYNTHETIC_TEST');
    h.isTrue('no compression/blocking/IM3 criterion invented', isempty(rxI.compressionCriterion) && ...
        isempty(rxI.blockingCriterion) && isempty(rxI.intermodulationCriterion));
    rxS = cF.scenario.receivers('S_TC_RX@SBA_NADIR');
    h.isTrue('other receivers stay without a front end', isempty(rxS.receiverFrontEnd));
    h.eqTol('rfSystems reports the P1dB', cF.rfSystems(strcmp({cF.rfSystems.systemId}, 'ISL_X_RX')).p1dB_in_dBm, -30, 0);
    fld{22} = '';
    lines{iL} = strjoin(fld, ',');
    fid = fopen(fullfile(tmpDs, 'rf_systems.csv'), 'w'); fwrite(fid, strjoin(lines, char(10))); fclose(fid);
    h.throws('P1dB without provenance rejected', @() MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache, 'datasetDir', tmpDs)), 'rfscreen:mission:badRf');
    delete(fullfile(tmpDs, '*')); rmdir(tmpDs);

    rfs = struct();
    for q = 1:numel(c1.rfSystems)
        rfs.(strrep(c1.rfSystems(q).systemId, '@', '_')) = c1.rfSystems(q);
    end
    tx = sc.transmitters('S_TM_TX@SBA_NADIR');
    h.eqTol('S TM TX fc 2.250 GHz', tx.fc_Hz, 2.25e9, 0);
    h.eqTol('S TM TX BW 2.7 MHz', tx.bw_Hz, 2.7e6, 0);
    h.eqTol('S TM TX 5 W = 36.99 dBm', tx.power_dBm, 36.99, 0.005);
    h.isTrue('TX carries rectangular spectrum', tx.hasSpectrum());
    tx = sc.transmitters('KA_DLS_TX@KAA_2');
    h.eqTol('Ka TX fc 26.25 GHz', tx.fc_Hz, 26.25e9, 0);
    h.eqTol('Ka TX BW 1.5 GHz (full 25.5-27.0 GHz allocation)', tx.bw_Hz, 1.5e9, 0);
    h.eqTol('Ka TX 70 W = 48.45 dBm', tx.power_dBm, 48.45, 0.005);
    h.eqTol('Ka occupied band 25.50-27.00 GHz', tx.occupiedBand_Hz(), [25.50e9 27.00e9], 1);
    tx = sc.transmitters('ISL_X_TX');
    h.eqTol('ISL TX 1 W = 30 dBm', tx.power_dBm, 30, 1e-9);
    h.eqTol('ISL fc 10.6 GHz / BW 20 MHz', [tx.fc_Hz tx.bw_Hz], [10.6e9 20e6], 0);
    rx = sc.receivers('S_TC_RX@SBA_ZENITH');
    h.eqTol('S TC RX fc/BW', [rx.fc_Hz rx.bw_Hz], [2.05e9 0.2e6], 0);
    h.eqTol('S TC RX filter 200 kHz', rx.filter.band_Hz, [2.05e9 - 1e5, 2.05e9 + 1e5], 1e-3);
    h.eqTol('S TC allowable ~ -124 dBm', rfs.S_TC_RX_SBA_NADIR.allowableInterference_dBm, -124, 0.1);
    h.eqTol('S TC noise ~ -118 dBm', rfs.S_TC_RX_SBA_NADIR.noise_dBm, -118, 0.1);
    h.eqTol('GPS L1 filter 1.56519-1.58565 GHz', sc.receivers('GPS_L1_RX@GPSA_1').filter.band_Hz, [1.56519e9 1.58565e9], 1e-3);
    h.eqTol('GPS allowable ~ -105 dBm', rfs.GPS_L1_RX_GPSA_1.allowableInterference_dBm, -105, 0.2);
    h.eqTol('ISL allowable ~ -104 dBm', rfs.ISL_X_RX.allowableInterference_dBm, -104, 0.1);
    rx = sc.receivers('GPS_L1_RX@GPSA_2');
    h.eqStr('criterion I_N_MAX', rx.interferenceCriterion.type, 'I_N_MAX');
    h.eqTol('criterion -6 dB', rx.interferenceCriterion.thresholdValue, -6, 0);
    h.eqTol('GPS NF 2 dB', rx.noiseModel.noiseFigure_dB, 2, 0);
    h.isTrue('no front end -> P1dB/IIP3 stay unknown', isempty(rx.receiverFrontEnd));
    h.isFalse('threshold dBm not used', rx.hasThreshold());
    rk = sc.receivers.keys(); allM6 = true;
    for q = 1:numel(rk)
        r = sc.receivers(rk{q});
        allM6 = allM6 && r.interferenceCriterion.thresholdValue == -6 && strcmp(r.interferenceCriterion.type, 'I_N_MAX');
    end
    h.isTrue('all RX use I_N_MAX with -6 dB', allM6);
    ok = true; try; sc.validate(); catch; ok = false; end
    h.isTrue('scenario with RF systems validates', ok);
    sar = c1.rfSystems(strcmp({c1.rfSystems.systemId}, 'SAR_X_TX'));
    h.isTrue('SAR TX deferred, not registered', ~sar.included && strcmp(sar.bindingStatus, 'DEFERRED_CLOSED_NETWORK'));
    h.eqTol('SAR nominal 2.5 kW = 63.98 dBm', sar.power_dBm, 63.98, 0.005);
    h.eqTol('SAR fc 9.65 GHz / BW 525 MHz', [sar.fc_Hz sar.bw_Hz], [9.65e9 525e6], 0);
    cS = MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache, 'powerMode', 'SCREENING'));
    sarS = cS.rfSystems(strcmp({cS.rfSystems.systemId}, 'SAR_X_TX'));
    h.eqTol('SAR screening 5 kW = 66.99 dBm', sarS.power_dBm, 66.99, 0.005);
    h.eqTol('screening mode leaves other TX unchanged', cS.scenario.transmitters('ISL_X_TX').power_dBm, 30, 0);
    sarR = c1.rfSystems(strcmp({c1.rfSystems.systemId}, 'SAR_X_RX'));
    h.eqTol('SAR RX allowable ~ -87.8 dBm', sarR.allowableInterference_dBm, -87.8, 0.1);
    h.throws('bad powerMode rejected', @() MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache, 'powerMode', 'X')), 'rfscreen:validate:member');

    % ---- pattern content: boresight equals the source CSV theta=0 value; cases really differ ----
    B = MB.readBindings(fullfile(rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir(), 'pattern_bindings.csv'));
    keys = cache.keys();
    for i = 1:numel(keys)
        b = B(keys{i}); p = cache(keys{i});
        T = rfscreen.spacecraft.SpacecraftDataReader.readTable(b.xzPath);
        h.eqTol([keys{i} ' boresight == CSV theta 0'], p.evaluate(b.frequency_Hz, 0, 0), str2double(T.gain{1}), 1e-9);
        h.eqStr([keys{i} ' provenance APPROX_FROM_CUTS'], p.provenance, 'APPROX_FROM_CUTS');
    end
    pI = cache('ISL_10P6');
    h.eqTol('ISL 30 deg off-axis (az) == CSV', pI.evaluate(10.6e9, 30, 0), isl30, 1e-3);
    h.eqTol('ISL 30 deg off-axis (el) == CSV', pI.evaluate(10.6e9, 0, 30), isl30, 1e-3);
    h.isTrue('ISL ~ -3 dB at 30 deg (HPBW ~60 deg)', abs((isl0 - isl30) - 3) < 0.5);
    h.isTrue('SBA1 and SBA4 TM patterns differ', patternsDiffer(cache('SBA1_TM'), cache('SBA4_TM'), 2.25e9));
    h.isTrue('GPS L1 vs L2 differ', patternsDiffer(cache('GPS_L1'), cache('GPS_L2'), 1.4e9));
    h.isTrue('GPS L1 vs L5 differ', patternsDiffer(cache('GPS_L1'), cache('GPS_L5'), 1.4e9));
    h.isTrue('GPS L2 vs L5 differ', patternsDiffer(cache('GPS_L2'), cache('GPS_L5'), 1.2e9));
    h.isTrue('datasheet cut fidelity is a 2D-cut class', ...
        rfscreen.patterndata.PatternFidelity.is2DCut('DATASHEET_ENVELOPE_2D_CUT'));
    h.eqStr('ISL cut fidelity SIMULATED_2D_CUT', B('ISL_10P6').fidelity, 'SIMULATED_2D_CUT');

    % ================= VR-442 geometry + pattern evidence, no EM fabrication =================
    c = built{1};
    g0 = pI.evaluate(10.6e9, 17, -23);
    rows = MB.structureFov(c);
    h.eqTol('FOV rows = 9 functions x 8 panels', numel(rows), 72, 0);
    h.isTrue('all FOV rows FOV_WITH_PATTERN', all(strcmp({rows.validity}, 'FOV_WITH_PATTERN')));
    h.eqTol('FOV does not change pattern gain', pI.evaluate(10.6e9, 17, -23), g0, 0);
    h.isFalse('FOV rows carry no gain/loss field', anyContains(fieldnames(rows), {'gain','loss','attenuation','s21','margin'}));
    mDir = fullfile(repoRoot, 'src', '+rfscreen', '+mission');
    h.ok('mission code holds no hard-coded P1dB/IIP3 value (data-driven only)', isempty(scan(mDir, ...
        {'p1dB_in_dBm'', -', 'iip3_in_dBm'', -', 'p1dB_in_dBm = -', 'iip3_in_dBm = -', 'p1dB_in_dBm'', 0', 'iip3_in_dBm'', 0'})));
    h.ok('mission generates no EM loss', isempty(scan(mDir, ...
        {'reflectionCoeff','diffractionLoss','scatteringLoss','FreeSpacePathLoss','applyBlockage','attenuation_dB','S21_dB'})));
    deps = {};
    pk = dir(fullfile(repoRoot, 'src', '+rfscreen', '+*'));
    for i = 1:numel(pk)
        if strcmp(pk(i).name, '+mission'); continue; end
        deps = [deps, scan(fullfile(repoRoot, 'src', '+rfscreen', pk(i).name), {'rfscreen.mission'})]; %#ok<AGROW>
    end
    h.ok('no other package depends on +mission', isempty(deps));
end

% ---- helpers ----
function tf = patternsDiffer(p1, p2, f)
    tf = false;
    for az = -180:10:180
        for el = -80:10:80
            if abs(p1.evaluate(f, az, el) - p2.evaluate(f, az, el)) > 1e-6; tf = true; return; end
        end
    end
end
function tf = anyContains(props, needles)
    tf = false;
    for i = 1:numel(props)
        for j = 1:numel(needles)
            if ~isempty(strfind(lower(props{i}), lower(needles{j}))); tf = true; return; end
        end
    end
end
function hits = scan(pathIn, tokens)
    hits = {};
    items = dir(pathIn);
    for i = 1:numel(items)
        it = items(i);
        if strcmp(it.name, '.') || strcmp(it.name, '..'); continue; end
        p = fullfile(pathIn, it.name);
        if it.isdir; hits = [hits, scan(p, tokens)]; continue; end %#ok<AGROW>
        if numel(it.name) < 3 || ~strcmp(it.name(end-1:end), '.m'); continue; end
        t = fileread(p);
        for k = 1:numel(tokens)
            if ~isempty(strfind(t, tokens{k})); hits{end+1} = sprintf('%s in %s', tokens{k}, p); end %#ok<AGROW>
        end
    end
end
