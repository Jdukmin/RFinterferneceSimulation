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
    T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(islDir, 'f10.4_XZ.csv'));
    isl0 = str2double(T.gain{1}); isl30 = str2double(T.gain{31});
    h.eqTol('ISL 10.4 GHz boresight 10.02 dBi', isl0, 10.020177967159514, 0);

    % ================= VR-441 build all six cases =================
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    opts = struct('patternCache', cache, 'azStep_deg', 10, 'elStep_deg', 10);
    built = cell(1, 6);
    expFuncs = sort({'SBA_NADIR_TC','SBA_NADIR_TM','SBA_ZENITH_TC','SBA_ZENITH_TM','GPSA_1','GPSA_2', ...
        'KAA_1','KAA_2','ISL'});
    gpsBand_Hz = struct('L1', [1563 1588] * 1e6, 'L2', [1207 1207] * 1e6, 'L5', [1164 1189] * 1e6);
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
        expPat = sort({[cs.sbaVariant '_TC'], [cs.sbaVariant '_TM'], ['GPS_' cs.gpsBand], 'ISL_10P4', 'KA_DLS'});
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
        a = sc.antennas('ISL'); h.eqStr([id ' ISL pattern 10.4 GHz'], a.patternId, 'ISL_10P4');
        h.eqTol([id ' ISL band'], [a.freqMin_Hz a.freqMax_Hz], [10.3e9 10.5e9], 0);
        h.eqTol([id ' no transmitters invented'], sc.transmitters.Count, 0, 0);
        h.eqTol([id ' no receivers invented'], sc.receivers.Count, 0, 0);
        h.isTrue([id ' warns SAR deferred'], any(~cellfun(@isempty, strfind(c.warnings, 'SAR_ANT'))));
        h.isTrue([id ' warns KAA candidate'], any(~cellfun(@isempty, strfind(c.warnings, 'CANDIDATE'))));
        fs = c.functions(strcmp({c.functions.functionId}, 'SAR_ANT'));
        h.isTrue([id ' SAR function not included'], ~fs.included && strcmp(fs.bindingStatus, 'DEFERRED_CLOSED_NETWORK'));
    end
    h.eqTol('pattern cache: 9 distinct patterns over 6 cases', cache.Count, 9, 0);

    % ---- pattern content: boresight equals the source CSV theta=0 value; cases really differ ----
    B = MB.readBindings(fullfile(rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir(), 'pattern_bindings.csv'));
    keys = cache.keys();
    for i = 1:numel(keys)
        b = B(keys{i}); p = cache(keys{i});
        T = rfscreen.spacecraft.SpacecraftDataReader.readTable(b.xzPath);
        h.eqTol([keys{i} ' boresight == CSV theta 0'], p.evaluate(b.frequency_Hz, 0, 0), str2double(T.gain{1}), 1e-9);
        h.eqStr([keys{i} ' provenance APPROX_FROM_CUTS'], p.provenance, 'APPROX_FROM_CUTS');
    end
    pI = cache('ISL_10P4');
    h.eqTol('ISL 30 deg off-axis (az) == CSV', pI.evaluate(10.4e9, 30, 0), isl30, 1e-3);
    h.eqTol('ISL 30 deg off-axis (el) == CSV', pI.evaluate(10.4e9, 0, 30), isl30, 1e-3);
    h.isTrue('ISL ~ -3 dB at 30 deg (HPBW ~60 deg)', abs((isl0 - isl30) - 3) < 0.5);
    h.isTrue('SBA1 and SBA4 TM patterns differ', patternsDiffer(cache('SBA1_TM'), cache('SBA4_TM'), 2.25e9));
    h.isTrue('GPS L1 vs L2 differ', patternsDiffer(cache('GPS_L1'), cache('GPS_L2'), 1.4e9));
    h.isTrue('GPS L1 vs L5 differ', patternsDiffer(cache('GPS_L1'), cache('GPS_L5'), 1.4e9));
    h.isTrue('GPS L2 vs L5 differ', patternsDiffer(cache('GPS_L2'), cache('GPS_L5'), 1.2e9));
    h.isTrue('datasheet cut fidelity is a 2D-cut class', ...
        rfscreen.patterndata.PatternFidelity.is2DCut('DATASHEET_ENVELOPE_2D_CUT'));
    h.eqStr('ISL cut fidelity SIMULATED_2D_CUT', B('ISL_10P4').fidelity, 'SIMULATED_2D_CUT');

    % ================= VR-442 geometry + pattern evidence, no EM fabrication =================
    c = built{1};
    g0 = pI.evaluate(10.4e9, 17, -23);
    rows = MB.structureFov(c);
    h.eqTol('FOV rows = 9 functions x 8 panels', numel(rows), 72, 0);
    h.isTrue('all FOV rows FOV_WITH_PATTERN', all(strcmp({rows.validity}, 'FOV_WITH_PATTERN')));
    h.eqTol('FOV does not change pattern gain', pI.evaluate(10.4e9, 17, -23), g0, 0);
    h.isFalse('FOV rows carry no gain/loss field', anyContains(fieldnames(rows), {'gain','loss','attenuation','s21','margin'}));
    mDir = fullfile(repoRoot, 'src', '+rfscreen', '+mission');
    h.ok('mission creates no RF systems', isempty(scan(mDir, {'RFTransmitter(', 'RFReceiver('})));
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
