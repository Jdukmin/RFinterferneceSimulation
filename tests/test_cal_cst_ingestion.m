function test_cal_cst_ingestion(h)
%TEST_CAL_CST_INGESTION Native 3D CST ASCII path: parser, coordinates, cuts, binding (SYNTHETIC_TEST only).
    h.setGroup('cal_cst');
    repo = fileparts(fileparts(mfilename('fullpath')));
    fx = fullfile(repo, 'tests', 'fixtures', 'cal_cst');
    tmp = tempname(); mkdir(tmp); cleanup = onCleanup(@() rmdir(tmp, 's')); %#ok<NASGU>
    S = testutil.CalSynthetic;
    I = rfscreen.cal.CstAscii3DImporter;
    base = struct('peak', 5, 'back', -20, 'tiltX', 2);
    [T, P, G] = S.grid(15, base);

    %% ---------------- parser ----------------
    a = I.read(fullfile(fx, 'SYNTHETIC_TEST_standard_15deg.txt'));
    h.isTrue('std: 13 theta x 24 phi', numel(a.theta_deg) == 13 && numel(a.phi_deg) == 24);
    h.eqTol('std: theta step identified', a.thetaStep_deg, 15, 1e-12);
    h.eqTol('std: phi step identified', a.phiStep_deg, 15, 1e-12);
    h.isTrue('std: header + separator skipped', a.info.preambleLines == 2);
    h.eqTol('std: col3 = gain (exact)', max(abs(a.gain_dBi(:) - reshape(G, [], 1))), 0, 1e-6);
    b = I.read(fullfile(fx, 'SYNTHETIC_TEST_tabs_crlf_broken_header_15deg.txt'));
    h.isTrue('broken header + tabs + CRLF parsed', isequal(size(b.gain_dBi), [13 24]));
    h.eqTol('broken header: same data', max(abs(b.gain_dBi(:) - a.gain_dBi(:))), 0, 1e-6);
    h.isTrue('broken header: 1 preamble line', b.info.preambleLines == 1);

    % renamed header text is irrelevant (header is never parsed)
    f = fullfile(tmp, 'renamed.txt'); S.write(f, T, P, G, 'cst');
    txt = fileread(f); nl = find(txt == sprintf('\n'), 1);
    fid = fopen(f, 'w'); fprintf(fid, 'Foo  Bar  Something Else Entirely [x]%s', txt(nl:end)); fclose(fid);
    c = I.read(f);
    h.eqTol('renamed header: same data', max(abs(c.gain_dBi(:) - a.gain_dBi(:))), 0, 1e-6);
    f = fullfile(tmp, 'nohdr.txt'); S.write(f, T, P, G, 'noheader');
    h.eqTol('no header at all: same data', max(abs(I.read(f).gain_dBi(:) - a.gain_dBi(:))), 0, 1e-6);
    f = fullfile(tmp, 'tabs.txt'); S.write(f, T, P, G, 'tabs');
    h.eqTol('tabs + multiple delimiters', max(abs(I.read(f).gain_dBi(:) - a.gain_dBi(:))), 0, 1e-6);
    f = fullfile(tmp, 'shuf.txt'); S.write(f, T, P, G, 'shuffled');
    d = I.read(f);
    h.eqTol('shuffled rows: grid rebuilt from values', max(abs(d.gain_dBi(:) - a.gain_dBi(:))), 0, 1e-6);

    % columns by position: other columns never change the gain
    M = [T(:) P(:) G(:) 99 + 0 * T(:) -G(:) G(:) + 7 0 * T(:) 1 + 0 * T(:)];
    f = fullfile(tmp, 'cols.txt'); writeRows(f, M, 'h\n----\n');
    h.eqTol('gain read from column 3 only', max(abs(I.read(f).gain_dBi(:) - a.gain_dBi(:))), 0, 1e-6);

    M0 = [T(:) P(:) G(:) G(:) T(:) G(:) P(:) 3 + 0 * T(:)];
    % malformed numeric row after data start
    f = fullfile(tmp, 'bad.txt'); writeRows(f, M0, 'h\n---\n', 5, '30.0  45.0  abc  1 2 3 4 5');
    h.throws('malformed numeric row', @() I.read(f), 'rfscreen:cal:malformedRow');
    try; I.read(f); catch e; h.isTrue('malformed row: line number reported', ~isempty(strfind(e.message, 'line 7'))); end %#ok<NOCOM>
    f = fullfile(tmp, 'short.txt'); writeRows(f, M0, 'h\n---\n', 10, '30.0  45.0  1.5');
    h.throws('truncated row (column count)', @() I.read(f), 'rfscreen:cal:malformedRow');
    Mn = M0; Mn(20, 3) = NaN;
    f = fullfile(tmp, 'nan.txt'); writeRows(f, Mn, 'h\n---\n');
    h.throws('non-finite gain', @() I.read(f), 'rfscreen:cal:nonFinite');
    Md = [M0; M0(40, :)];
    f = fullfile(tmp, 'dup.txt'); writeRows(f, Md, 'h\n---\n');
    h.throws('duplicate (theta,phi)', @() I.read(f), 'rfscreen:cal:duplicateSample');
    Mm = M0([1:49 51:end], :);
    f = fullfile(tmp, 'miss.txt'); writeRows(f, Mm, 'h\n---\n');
    h.throws('missing angular sample', @() I.read(f), 'rfscreen:cal:missingSample');
    Mp = M0(M0(:, 2) ~= 45, :);
    f = fullfile(tmp, 'missplane.txt'); writeRows(f, Mp, 'h\n---\n');
    h.throws('missing phi plane', @() I.read(f), 'rfscreen:cal:missingSample');
    Mh = M0(M0(:, 1) < 180, :);
    f = fullfile(tmp, 'nopole.txt'); writeRows(f, Mh, 'h\n---\n');
    h.throws('theta must reach 180 (full sphere)', @() I.read(f), 'rfscreen:cal:incompleteGrid');
    Mr = M0; Mr(M0(:, 1) == 180, 1) = 190;
    f = fullfile(tmp, 'range.txt'); writeRows(f, Mr, 'h\n---\n');
    h.throws('theta range', @() I.read(f), 'rfscreen:cal:thetaRange');
    h.throws('no numeric data', @() I.parseText(sprintf('a b c\n----\n'), 'x'), 'rfscreen:cal:noData');

    % independent theta / phi steps, never hard-coded
    [T2, P2] = ndgrid(0:2:180, 0:5:355); G2 = S.gain(T2, P2, base);
    f = fullfile(tmp, 'steps.txt'); S.write(f, T2, P2, G2, 'cst');
    e2 = I.read(f);
    h.isTrue('theta 2 deg / phi 5 deg identified', e2.thetaStep_deg == 2 && e2.phiStep_deg == 5 && e2.nRows == 91 * 72);
    % phi = 360 alias
    Ma = [M0; M0(M0(:, 2) == 0, :)]; Ma(end-12:end, 2) = 360;
    f = fullfile(tmp, 'alias.txt'); writeRows(f, Ma, 'h\n---\n');
    h.eqTol('phi = 360 accepted as alias of phi = 0', max(abs(I.read(f).gain_dBi(:) - a.gain_dBi(:))), 0, 1e-6);
    % pole noise: consolidated, phi-independent, reported
    Mz = M0; k0 = M0(:, 1) == 0; Mz(k0, 3) = Mz(k0, 3) + 0.4 * sind(3 * Mz(k0, 2)) + 0.6 * (Mz(k0, 2) == 90);
    f = fullfile(tmp, 'pole.txt'); writeRows(f, Mz, 'h\n---\n');
    pz = I.read(f);
    h.isTrue('pole spread reported', pz.poleSpread_dB(1) > 0.5 && ~isempty(pz.warnings));
    gp = pz.gainAt(zeros(1, 24), 0:15:345);
    h.eqTol('pole query independent of phi', max(gp) - min(gp), 0, 1e-12);
    h.eqTol('pole = linear-power mean', gp(1), 10 * log10(mean(10 .^ (Mz(k0, 3) / 10))), 1e-5);   % file holds 6 decimals
    h.eqTol('raw pole values kept', max(abs(sort(pz.gain_dBi(1, :)) - sort(Mz(k0, 3).'))), 0, 1e-6);
    gn = pz.gainAt([0.5 0.5], [0 180]);
    h.isTrue('near-pole interpolation stable', abs(gn(1) - gn(2)) < 0.1);

    %% ---------------- coordinates ----------------
    M_AL = rfscreen.kaa.CstLocalFrameAdapter.localToAntenna();
    vA = M_AL * [0; 0; 1];
    [az, el] = rfscreen.geometry.DirectionCalculator.directionToAzEl(vA);
    h.isTrue('CST theta=0 -> +Z_L -> +X_A', norm(vA - [1; 0; 0]) < 1e-15);
    h.isTrue('CST theta=0 -> repository az=0 el=0', abs(az) < 1e-12 && abs(el) < 1e-12);
    fq = 1.57542e9;
    pf = rfscreen.cal.CstNativeFreeSpacePattern('SYNTHETIC_TEST_FS', a, fq);
    h.eqTol('az0/el0 = CST boresight gain', pf.evaluate(fq, 0, 0), a.poleGain_dBi(1), 1e-12);
    h.eqTol('el=+90 (+Z_A) = CST +X_L (theta 90, phi 0)', pf.evaluate(fq, 0, 90), a.gain_dBi(7, 1), 1e-9);
    h.eqTol('az=-90 (-Y_A) = CST +Y_L (theta 90, phi 90)', pf.evaluate(fq, -90, 0), a.gain_dBi(7, 7), 1e-9);
    h.eqTol('az=+90 (+Y_A) = CST -Y_L (theta 90, phi 270)', pf.evaluate(fq, 90, 0), a.gain_dBi(7, 19), 1e-9);
    h.eqTol('az=180 = CST -Z_L back lobe', pf.evaluate(fq, 180, 0), a.poleGain_dBi(2), 1e-9);
    h.isTrue('free-space type, SIMULATED_3D (not APPROX_FROM_CUTS)', isa(pf, 'rfscreen.antenna.FreeSpacePattern') && ...
        ~pf.isInstalled() && strcmp(pf.provenance, 'SIMULATED_3D'));
    h.eqTol('compat PatternGrid agrees at a node', pf.grid.evaluate(fq, 0, 90), pf.evaluate(fq, 0, 90), 1e-9);
    h.throws('other frequency refused', @() pf.evaluate(1.2276e9, 0, 0), 'rfscreen:cal:wrongFrequencyPlane');

    model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
    pn = @(id) model.panels(strcmp({model.panels.id}, id)).normal_B;
    expect = {'GPSA_1', 'PANEL_3'; 'GPSA_2', 'PANEL_3'; 'SBA_NADIR', 'PANEL_6'; 'SBA_ZENITH', 'PANEL_4'};
    pin = rfscreen.cal.CstNativeInstalledPattern('SYNTHETIC_TEST_INST', a, fq);
    for i = 1:size(expect, 1)
        inst = model.installations(expect{i, 1});
        R_BL = rfscreen.kaa.CstLocalFrameAdapter.fromR_BA(inst.R_BA);
        n = pn(expect{i, 2});
        h.isTrue(sprintf('%s: +Z_CST = %s outward normal', expect{i, 1}, expect{i, 2}), norm(R_BL(:, 3) - n) < 1e-9);
        h.isTrue(sprintf('%s: +X_CST = +X_B (orthogonalised roll)', expect{i, 1}), norm(R_BL(:, 1) - [1; 0; 0]) < 1e-9);
        h.eqTol(sprintf('%s: body query along normal = boresight gain', expect{i, 1}), ...
            pin.gainAntenna(fq, inst.R_BA.' * n), a.poleGain_dBi(1), 1e-9);
    end
    h.isTrue('GPSA_1/GPSA_2 normal (0,-0.866,-0.5)', norm(pn('PANEL_3') - [0; -0.866025404; -0.5]) < 1e-6);
    h.isTrue('GPSA_1/GPSA_2 distinct positions', abs(model.installations('GPSA_2').position_m(1) - ...
        model.installations('GPSA_1').position_m(1) - 1.1) < 1e-9);
    h.isTrue('SBA_NADIR normal (0,0.866,0.5)', norm(pn('PANEL_6') - [0; 0.866025404; 0.5]) < 1e-6);
    h.isTrue('SBA_ZENITH normal (0,0,-1)', norm(pn('PANEL_4') - [0; 0; -1]) < 1e-12);

    %% ---------------- cuts ----------------
    [ang, g, th, ph] = a.planeCut('XZ');
    k = find(ang == 60); km = find(ang == -60);
    h.isTrue('XZ +side uses phi 0', ph(k) == 0 && th(k) == 60);
    h.isTrue('XZ -side uses phi 180', ph(km) == 180 && th(km) == 60);
    h.eqTol('XZ +60 = raw (60, 0)', g(k), a.gain_dBi(5, 1), 1e-9);
    h.eqTol('XZ -60 = raw (60, 180)', g(km), a.gain_dBi(5, 13), 1e-9);
    [angY, gY, ~, phY] = a.planeCut('YZ');
    h.isTrue('YZ uses phi 90 / 270', phY(angY == 60) == 90 && phY(angY == -60) == 270);
    h.eqTol('YZ +60 = raw (60, 90)', gY(angY == 60), a.gain_dBi(5, 7), 1e-9);
    h.isTrue('cut spans -180..180 through boresight', ang(1) == -180 && ang(end) == 180 && any(ang == 0));
    h.isTrue('XZ != YZ for an asymmetric pattern', abs(g(k) - gY(angY == 60)) > 0.5);

    % body cuts query the transformed 3D pattern: an off-cut feature (phi far from 0/90/180/270)
    inst = model.installations('GPSA_1');
    R_BL = rfscreen.kaa.CstLocalFrameAdapter.fromR_BA(inst.R_BA);
    dB = [cosd(-60); sind(-60); 0];                       % body XY plane, alpha = -60 deg
    [t0, p0] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi(R_BL.' * dB);
    h.isTrue('feature lies off the CST XZ/YZ planes', min(abs(mod(p0, 90) - [0 90])) > 10 && t0 > 10 && t0 < 170);
    sb = base; sb.tiltX = 0; sb.bump = [t0 p0 12 8];
    [Tb, Pb] = ndgrid(0:2:180, 0:2:358); Gb = S.gain(Tb, Pb, sb);
    f = fullfile(tmp, 'bump.txt'); S.write(f, Tb, Pb, Gb, 'cst');
    nb = I.read(f);
    pb = rfscreen.cal.CstNativeInstalledPattern('SYNTHETIC_TEST_BUMP', nb, fq);
    cuts = rfscreen.cal.CalPlotter.bodyCutData(inst.R_BA, pb, fq);
    cxy = cuts(strcmp({cuts.plane}, 'XY'));
    [gmax, kmax] = max(cxy.gain_dBi);
    h.isTrue('body XY cut sees the off-cut 3D feature at alpha -60', abs(cxy.alpha_deg(kmax) + 60) <= 2 && gmax > sb.back + 10);
    direct = nb.gainAtLocal(R_BL.' * cxy.dir_B);
    h.eqTol('body cut = body->antenna->local->theta/phi->native query', max(abs(direct - cxy.gain_dBi)), 0, 1e-12);
    [~, gxz] = nb.planeCut('XZ'); [~, gyz] = nb.planeCut('YZ');
    h.isTrue('feature above the boresight peak in the body cut', gmax > sb.peak + 3);
    h.isTrue('feature absent from both CST XZ/YZ cuts (no rotated-2D shortcut)', max([gxz gyz]) < sb.peak + 0.5);

    %% ---------------- binding ----------------
    cfg = fullfile(repo, 'data', 'cal_config');
    fmap = rfscreen.cal.CalFrequencyMap.load(fullfile(cfg, 'cal_frequency_aliases.csv'), fullfile(model.datasetDir, 'rf_systems.csv'));
    [ok5, f5] = fmap.resolve('1.1764'); [ok1, f1] = fmap.resolve('1.5754'); [~, f2] = fmap.resolve('1.2276');
    h.isTrue('alias 1.1764 -> 1176.45 MHz (SSOT)', ok5 && abs(f5 - 1176.45e6) < 1);
    h.isTrue('alias 1.5754 -> 1575.42 MHz (SSOT)', ok1 && abs(f1 - 1575.42e6) < 1);
    h.isFalse('unknown token not resolved', fmap.resolve('3.3'));
    h.isFalse('GPS f1.2 is not a frequency', fmap.resolve('1.2'));
    bad = fullfile(tmp, 'alias_bad.csv');
    fid = fopen(bad, 'w'); fprintf(fid, 'token,canonical_source,canonical_mhz,label,note\n1.3,RF_SYSTEM:GPS_L2_RX,,L2,x\n'); fclose(fid);
    h.throws('alias beyond display precision refused', @() rfscreen.cal.CalFrequencyMap.load(bad, ...
        fullfile(model.datasetDir, 'rf_systems.csv')), 'rfscreen:cal:aliasTooFar');

    root = fullfile(tmp, 'cal');
    S.buildTree(root, 15, {'GPS_GPSA2_f1.2', 'RFC_KAA_f1.5754'});
    % extra files: unrecognised name, wrong folder, unmapped token, duplicate binding
    [Tq, Pq, Gq] = S.grid(15, base);
    S.write(fullfile(root, 'isl', 'RFC_ISL_NADIR_f10.6.txt'), Tq, Pq, Gq);
    S.write(fullfile(root, 'isl', 'RFC_KAA_f2.25.txt'), Tq, Pq, Gq);
    S.write(fullfile(root, 'kaa', 'RFC_KAA_f3.3.txt'), Tq, Pq, Gq);
    S.write(fullfile(root, 'sba', 'RFC_SBA_f10.60.txt'), Tq, Pq, Gq);
    fid = fopen(fullfile(root, 'sba', 'RFC_SBA_f9.65.txt'), 'a'); fprintf(fid, 'junk line\n'); fclose(fid);
    cat = rfscreen.cal.CalPatternCatalog.scan(root, fmap);
    st = @(name) cat.entries(strcmp({cat.entries.relPath}, name)).status;
    h.eqStr('unrecognised name', st('isl/RFC_ISL_NADIR_f10.6.txt'), 'UNRECOGNIZED_NAME');
    h.eqStr('wrong folder', st('isl/RFC_KAA_f2.25.txt'), 'WRONG_FOLDER');
    h.eqStr('unmapped frequency token', st('kaa/RFC_KAA_f3.3.txt'), 'UNMAPPED_FREQUENCY');
    h.eqStr('duplicate binding (a)', st('sba/RFC_SBA_f10.6.txt'), 'DUPLICATE_BINDING');
    h.eqStr('duplicate binding (b)', st('sba/RFC_SBA_f10.60.txt'), 'DUPLICATE_BINDING');
    h.eqStr('corrupt file rejected', st('sba/RFC_SBA_f9.65.txt'), 'PARSE_ERROR');
    h.eqStr('owner GPS installed file valid', st('gps/GPS_GPSA1_f1.2.txt'), 'VALID');
    B = rfscreen.cal.CalPatternBinder(cat, fullfile(cfg, 'cal_installations.csv'));
    g1 = {}; for fr = [f5 f2 f1]; g1{end+1} = B.bind('GPSA_1', 'RX', fr); end %#ok<AGROW>
    h.isTrue('GPS: L5/L2/L1 share GPS_GPSA1_f1.2', all(cellfun(@(x) strcmp(x.status, 'BOUND') && ...
        ~isempty(strfind(x.file, 'GPS_GPSA1_f1.2')) && strcmp(x.patternType, 'INSTALLED'), g1)));
    u = [0.3; -0.5; 0.81]; u = u / norm(u);
    gg = cellfun(@(x, fr) x.pattern.gainAntenna(fr, u), g1, {f5, f2, f1});
    h.eqTol('GPS: identical spatial pattern at L5/L2/L1', max(gg) - min(gg), 0, 1e-12);
    b2 = B.bind('GPSA_2', 'RX', f1);
    h.isTrue('GPSA_2 without installed file -> GPS_ORIGINAL free-space fallback, flagged', strcmp(b2.patternType, 'FREE_SPACE') && ...
        b2.fallback && ~isempty(strfind(b2.file, 'GPS_ORIGINAL')) && ~isempty(strfind(b2.warnings{1}, 'FALLBACK')));
    cat2 = rfscreen.cal.CalPatternCatalog.scan(fullfile(fx, 'none'), fmap);
    h.isTrue('missing cal dir -> empty catalog', isempty(cat2.entries) && cat2.patterns.Count == 0);
    root3 = fullfile(tmp, 'cal3'); S.buildTree(root3, 15);
    cat3 = rfscreen.cal.CalPatternCatalog.scan(root3, fmap);
    B3 = rfscreen.cal.CalPatternBinder(cat3, fullfile(cfg, 'cal_installations.csv'));
    a1 = B3.bind('GPSA_1', 'RX', f1); a2 = B3.bind('GPSA_2', 'RX', f1);
    h.isTrue('GPSA1 != GPSA2 installed patterns', ~strcmp(a1.file, a2.file) && ...
        abs(a1.pattern.gainAntenna(f1, u) - a2.pattern.gainAntenna(f1, u)) > 0.1 && ~a1.fallback && ~a2.fallback);
    s206 = B3.bind('SBA_NADIR', 'TX', 2.06e9); s225 = B3.bind('SBA_ZENITH', 'RX', 2.25e9);
    sL1 = B3.bind('SBA_NADIR', 'TX', f1); sX = B3.bind('SBA_ZENITH', 'TX', 10.6e9);
    h.isTrue('SBA_NADIR 2.06 -> installed override', strcmp(s206.patternType, 'INSTALLED') && ~isempty(strfind(s206.file, 'RFC_SBA_NADIR_f2.06')));
    h.isTrue('SBA_ZENITH 2.25 -> installed override', strcmp(s225.patternType, 'INSTALLED') && ~isempty(strfind(s225.file, 'RFC_SBA_ZENITH_f2.25')));
    h.isTrue('SBA L1 -> generic free-space', strcmp(sL1.patternType, 'FREE_SPACE') && ~isempty(strfind(sL1.file, 'RFC_SBA_f1.5754')) && ~sL1.fallback);
    h.isTrue('SBA 10.6 -> generic free-space', strcmp(sX.patternType, 'FREE_SPACE') && ~isempty(strfind(sX.file, 'RFC_SBA_f10.6')));
    iX = B3.bind('ISL', 'RX', 10.6e9); iT = B3.bind('ISL', 'TX', f1);
    h.isTrue('ISL victim 10.6 -> RFC_ISL_f10.6 free-space (no installed override)', strcmp(iX.patternType, 'FREE_SPACE') && ...
        isa(iX.pattern, 'rfscreen.cal.CstNativeFreeSpacePattern') && ~isempty(strfind(iX.file, 'RFC_ISL_f10.6')));
    h.isTrue('ISL attacker at victim frequency', ~isempty(strfind(iT.file, 'RFC_ISL_f1.5754')));
    h.throws('KAA is attacker only', @() B3.bind('KAA_1', 'RX', 2.25e9), 'rfscreen:cal:kaaAttackerOnly');
    kL1 = B3.bind('KAA_2', 'TX', f1);
    h.isTrue('KAA -> L1 uses RFC_KAA_f1.5754', ~isempty(strfind(kL1.file, 'RFC_KAA_f1.5754')) && strcmp(kL1.patternType, 'FREE_SPACE'));
    k206 = B3.bind('KAA_1', 'TX', 2.06e9);
    h.isTrue('no KAA 2.06 file -> INPUT_MISSING (no other band used)', strcmp(k206.status, 'INPUT_MISSING') && isempty(k206.pattern));
    kMiss = B.bind('KAA_1', 'TX', f1);
    h.isTrue('RFC_KAA_f1.5754 absent -> INPUT_MISSING although f1.2276 exists', strcmp(kMiss.status, 'INPUT_MISSING'));
    h.throws('pattern refuses another victim frequency', @() kL1.pattern.gainAntenna(f2, u), 'rfscreen:cal:wrongFrequencyPlane');
    keys = cat3.patterns.keys(); nInst = 0; nFs = 0; okProv = true;
    for i = 1:numel(keys)
        p = cat3.patterns(keys{i});
        okProv = okProv && strcmp(p.provenance, 'SIMULATED_3D');
        if p.isInstalled()
            nInst = nInst + 1;
            okProv = okProv && isa(p, 'rfscreen.antenna.InstalledPattern') && strcmp(p.installedSource, 'CST') && ...
                strcmp(p.patternType, 'INSTALLED') && ~isempty(strfind(keys{i}, '|INSTALLED|'));
        else
            nFs = nFs + 1;
            okProv = okProv && ~isa(p, 'rfscreen.antenna.InstalledPattern') && strcmp(p.patternType, 'FREE_SPACE') && ...
                ~isempty(strfind(keys{i}, '|FREE_SPACE|'));
        end
    end
    h.isTrue('free-space / installed never share type or provenance key', okProv);
    h.isTrue('installed planes: GPSA1x3 + GPSA2x3 + SBA 4', nInst == 10);
    h.isTrue('free-space planes: GPS x3 + ISL 8 + KAA 8 + SBA 9', nFs == 28);

    %% ---------------- architecture ----------------
    % The native 3D path never goes through the 2D-cut pipeline (no XZ/YZ degradation) and never labels
    % itself APPROX_FROM_CUTS; the 2D pipeline does not depend on the CAL package.
    calDir = fullfile(repo, 'src', '+rfscreen', '+cal');
    hits = codeTokens(calDir, {'CutPatternAssembler', 'CsvPatternImporter', 'TablePatternImporter', 'APPROX_FROM_CUTS', 'system('});
    h.isTrue('CAL code free of the 2D-cut pipeline', isempty(hits));
    if ~isempty(hits); h.fail('2D tokens in +cal', strjoin(hits, '; ')); end
    back = codeTokens(fullfile(repo, 'src', '+rfscreen', '+patterndata'), {'rfscreen.cal.'});
    h.isTrue('2D pipeline does not depend on +cal', isempty(back));
end

function hits = codeTokens(d, tokens)
    hits = {}; L = dir(fullfile(d, '*.m'));
    for i = 1:numel(L)
        lines = regexp(fileread(fullfile(d, L(i).name)), '\r\n|\n', 'split');
        code = lines(cellfun(@(x) isempty(regexp(x, '^\s*%', 'once')), lines));
        txt = strjoin(code, sprintf('\n'));
        for t = 1:numel(tokens)
            if ~isempty(strfind(txt, tokens{t})); hits{end+1} = [tokens{t} ' in ' L(i).name]; end %#ok<AGROW>
        end
    end
end

function writeRows(f, M, header, insertAt, insertLine)
    fid = fopen(f, 'w'); fprintf(fid, header);
    for r = 1:size(M, 1)
        if nargin >= 4 && r == insertAt; fprintf(fid, '%s\n', insertLine); end
        fprintf(fid, '  %.6f   %.6f   %.6f', M(r, 1:3)); fprintf(fid, '  %.6g', M(r, 4:end)); fprintf(fid, '\n');
    end
    fclose(fid);
end
