function test_architecture_boundary(h)
%TEST_ARCHITECTURE_BOUNDARY Structural guarantees, not just numerics (VR-080..085).
    h.setGroup('architecture');

    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    srcDir = fullfile(repoRoot, 'src');

    % --- VR-080 Core has no dependency on UI ---
    uiTokens = {'uifigure', 'uicontrol', 'uipanel', 'uimenu', 'uiaxes', ...
                'appdesigner', 'App Designer'};
    hitsUI = scanTokens(srcDir, uiTokens);
    h.ok('core has no UI construction', isempty(hitsUI));
    if ~isempty(hitsUI); h.fail('UI tokens found', strjoin(hitsUI, '; ')); end

    % --- VR-081 Core does not call an external EM solver at run time ---
    solverTokens = {'actxserver', 'system(', 'dos(', 'hfssExecute', '!hfss'};
    hitsSolver = scanTokens(srcDir, solverTokens);
    h.ok('core does not invoke a solver', isempty(hitsSolver));
    if ~isempty(hitsSolver); h.fail('solver tokens found', strjoin(hitsSolver, '; ')); end
    % reserved solver models refuse to fabricate a result
    ctx = rfscreen.coupling.CouplingModel.newContext();
    h.throws('HFSS model refuses', ...
        @() rfscreen.coupling.HFSSCouplingModel().computeCoupling(ctx), ...
        'rfscreen:coupling:NotImplementedPhase1');

    % --- VR-082 PatternOnly is not measured S21 ---
    ctx2 = rfscreen.coupling.CouplingModel.newContext();
    ctx2.txGain_dBi = 5; ctx2.rxGain_dBi = 3;
    res = rfscreen.coupling.PatternOnlyCouplingModel().computeCoupling(ctx2);
    h.eqStr('pattern-only type', res.modelType, 'PATTERN_ONLY');
    h.isFalse('pattern-only not physical', res.isPhysicalCoupling);
    h.isFalse('pattern-only not measured S21', strcmp(res.modelType, 'MEASURED_S21'));
    h.eqTol('DCI = Gtx+Grx', res.metric_dB, 8, 1e-12);

    % --- near-field caution: FSPL never auto-applied without far-field validity (SR-081) ---
    ff = rfscreen.coupling.FarFieldCouplingModel();
    ctxNF = rfscreen.coupling.CouplingModel.newContext();
    ctxNF.distance_m = 0.5; ctxNF.frequency_Hz = 2.2e9;
    ctxNF.txGain_dBi = 10; ctxNF.rxGain_dBi = 5; ctxNF.txPower_dBm = 30;
    % apertures unknown (NaN) -> must NOT produce an FSPL number
    rNF = ff.computeCoupling(ctxNF);
    h.eqStr('far-field unknown validity', rNF.validity, 'FAR_FIELD_INVALID_OR_UNKNOWN');
    h.isNaNval('far-field no FSPL when unverified', rNF.metric_dB);
    h.isFalse('far-field unverified not physical', rNF.isPhysicalCoupling);
    % far-field valid case (large separation, known small apertures) -> FSPL applied
    ctxFF = ctxNF; ctxFF.distance_m = 1000; ctxFF.txMaxDim_m = 0.1; ctxFF.rxMaxDim_m = 0.1;
    rFF = ff.computeCoupling(ctxFF);
    h.eqStr('far-field valid validity', rFF.validity, 'FAR_FIELD_VALID');
    h.isTrue('far-field valid is physical', rFF.isPhysicalCoupling);
    fsplExpect = 20 * log10(4 * pi * 1000 / (299792458 / 2.2e9));
    h.eqTol('far-field FSPL value', rFF.metric_dB, fsplExpect, 1e-6);

    % --- VR-083 Antenna hardware owns no installation geometry ---
    props = properties('rfscreen.antenna.Antenna');
    h.isFalse('Antenna has no position_m', any(strcmp(props, 'position_m')));
    h.isFalse('Antenna has no R_BA', any(strcmp(props, 'R_BA')));
    h.isTrue('Antenna references installation by id', any(strcmp(props, 'installationId')));

    % --- VR-084 FreeSpace vs Installed remain distinguishable ---
    grid = rfscreen.antenna.PatternGrid([-180 0 180], [-90 0 90], 1e9, zeros(3,3,1));
    fs = rfscreen.antenna.FreeSpacePattern('SYNTHETIC_TEST_fs', ...
        rfscreen.antenna.PatternProvenance.SYNTHETIC_TEST, grid);
    ins = rfscreen.antenna.InstalledPattern('SYNTHETIC_TEST_ins', ...
        rfscreen.antenna.PatternProvenance.SIMULATED_3D, grid, ...
        rfscreen.antenna.InstalledPatternSource.HFSS);
    h.isFalse('free-space isInstalled=false', fs.isInstalled());
    h.isTrue('installed isInstalled=true', ins.isInstalled());
    h.isTrue('installed isa InstalledPattern', isa(ins, 'rfscreen.antenna.InstalledPattern'));
    h.isFalse('free-space not InstalledPattern', isa(fs, 'rfscreen.antenna.InstalledPattern'));
    h.isTrue('installed has source', ~isempty(ins.installedSource));

    % --- VR-085 synthetic data cannot be mistaken for mission data ---
    syn = { rfscreen.antenna.SyntheticPatternFactory.isotropic(0, 1e9), ...
            rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(10, 1e9, 2), ...
            rfscreen.antenna.SyntheticPatternFactory.mainSideBack(10, -10, -30, 1e9) };
    for i = 1:numel(syn)
        p = syn{i};
        h.eqStr(sprintf('synthetic%d provenance', i), p.provenance, 'SYNTHETIC_TEST');
        h.isTrue(sprintf('synthetic%d name marked', i), ~isempty(strfind(p.name, 'SYNTHETIC_TEST')));
        h.isTrue(sprintf('synthetic%d isSyntheticTest', i), p.isSyntheticTest());
    end
end

function hits = scanTokens(srcDir, tokens)
    hits = {};
    files = listMFiles(srcDir);
    for i = 1:numel(files)
        txt = fileread(files{i});
        for t = 1:numel(tokens)
            if ~isempty(strfind(txt, tokens{t}))
                hits{end+1} = sprintf('%s in %s', tokens{t}, files{i}); %#ok<AGROW>
            end
        end
    end
end

function files = listMFiles(d)
    files = {};
    items = dir(d);
    for i = 1:numel(items)
        it = items(i);
        if strcmp(it.name, '.') || strcmp(it.name, '..'); continue; end
        p = fullfile(d, it.name);
        if it.isdir
            files = [files, listMFiles(p)]; %#ok<AGROW>
        elseif numel(it.name) > 2 && strcmp(it.name(end-1:end), '.m')
            files{end+1} = p; %#ok<AGROW>
        end
    end
end
