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

    h.eqStr('free-space source frame = CST_LOCAL', pf.sourceFrame, 'CST_LOCAL');

    % Installed CST exports are in the spacecraft BODY frame: G_B(theta_B, phi_B). A body query is a direct
    % raw-grid lookup (no R_BL / R_BA / M_AL); only antenna-frame / antenna-local requests are mapped
    % LOCAL -> BODY (d_B = R_BA u_A, d_B = R_BL d_L) before the raw lookup.
    model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
    pn = @(id) model.panels(strcmp({model.panels.id}, id)).normal_B;
    M_AL = rfscreen.kaa.CstLocalFrameAdapter.localToAntenna();
    h.throws('installed pattern needs its SSOT mount R_BA', @() rfscreen.cal.CstNativeInstalledPattern('SYNTHETIC_TEST_INST', a, fq), ...
        'rfscreen:cal:installedMountRequired');
    expect = {'GPSA_1', 'PANEL_3'; 'GPSA_2', 'PANEL_3'; 'SBA_NADIR', 'PANEL_6'; 'SBA_ZENITH', 'PANEL_4'};
    for i = 1:size(expect, 1)
        id = expect{i, 1};
        inst = model.installations(id);
        R_BL = rfscreen.kaa.CstLocalFrameAdapter.fromR_BA(inst.R_BA);
        n = pn(expect{i, 2});
        % frame adapter (free-space / antenna-local view): +Z_L = panel outward normal, +X_L = +X_B orthogonalised
        h.isTrue(sprintf('%s: local +Z_L = %s outward normal', id, expect{i, 2}), norm(R_BL(:, 3) - n) < 1e-9);
        h.isTrue(sprintf('%s: local +X_L = +X_B (orthogonalised roll)', id), norm(R_BL(:, 1) - [1; 0; 0]) < 1e-9);
        % body-frame installed raw export: main lobe along n_B
        sp = struct('peak', 6, 'back', -20, 'tiltX', 0, 'axis', n.');
        [Ti, Pi] = ndgrid(0:5:180, 0:5:355); Gi = S.gain(Ti, Pi, sp);
        fi = fullfile(tmp, sprintf('inst_%s.txt', id)); S.write(fi, Ti, Pi, Gi, 'cst');
        ni = I.read(fi);
        pin = rfscreen.cal.CstNativeInstalledPattern(['SYNTHETIC_TEST_' id], ni, fq, struct('R_BA', inst.R_BA, 'installationId', id));
        h.eqStr(sprintf('%s: installed source frame = SPACECRAFT_BODY_FIXED', id), pin.sourceFrame, 'SPACECRAFT_BODY_FIXED');
        [tn, pnn] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi(n);
        h.eqTol(sprintf('%s: gainBody(n_B) = raw G(theta_B, phi_B) of n_B (no rotation)', id), ...
            pin.gainBody(fq, n), ni.gainAt(tn, pnn), 1e-12);
        h.eqTol(sprintf('%s: gainBody(n_B) = main-lobe peak', id), pin.gainBody(fq, n), ni.peakGain_dBi, 1e-6);
        dPk = rfscreen.cal.CalPlotter.installedRawDirections(pin, ni.peakTheta_deg, ni.peakPhi_deg);
        h.isTrue(sprintf('%s: raw peak direction (3D plot) = %s normal', id, expect{i, 2}), norm(dPk - n) < 1e-6);
        h.eqTol(sprintf('%s: antenna boresight +X_A -> d_B = R_BA u_A = n_B', id), pin.gainAntenna(fq, [1; 0; 0]), pin.gainBody(fq, n), 1e-12);
        h.eqTol(sprintf('%s: antenna-local +Z_L -> d_B = R_BL d_L = n_B', id), pin.gainLocal(fq, [0; 0; 1]), pin.gainBody(fq, n), 1e-12);
        h.eqTol(sprintf('%s: evaluate(az 0, el 0) = gain along n_B', id), pin.evaluate(fq, 0, 0), pin.gainBody(fq, n), 1e-12);
        u = [0.3; -0.5; 0.81]; u = u / norm(u);
        h.eqTol(sprintf('%s: arbitrary body direction queried as is', id), pin.gainBody(fq, u), ...
            ni.gainAtDirection(u), 1e-12);
        % the former (wrong) body -> local re-interpretation reads raw +Z_B/other directions, not the main lobe
        old = ni.gainAtLocal(M_AL.' * (inst.R_BA.' * n));
        h.isTrue(sprintf('%s: raw installed data NOT re-rotated by R_BL (old convention differs)', id), ...
            abs(old - pin.gainBody(fq, n)) > 1);
        [tq, pq] = pin.sourceThetaPhi([1; 0; 0]);
        h.isTrue(sprintf('%s: queried raw (theta, phi) = body angles of n_B', id), abs(tq - tn) < 1e-9 && abs(mod(pq - pnn + 180, 360) - 180) < 1e-9);
    end
    h.isTrue('SBA_NADIR mount position [255 870 1030] mm', norm(model.installations('SBA_NADIR').position_m - [0.255; 0.870; 1.030]) < 1e-12);
    h.isTrue('SBA_ZENITH mount position [255 -530 -1240] mm', norm(model.installations('SBA_ZENITH').position_m - [0.255; -0.530; -1.240]) < 1e-12);
    rec = model.installationRecords;
    h.eqStr('SBA_NADIR on PANEL_6', rec(strcmp({rec.antennaId}, 'SBA_NADIR')).panelId, 'PANEL_6');
    h.eqStr('SBA_ZENITH on PANEL_4', rec(strcmp({rec.antennaId}, 'SBA_ZENITH')).panelId, 'PANEL_4');
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

    % body cuts of an installed (body-frame) pattern query the raw grid directly; an off-plane feature
    % (phi far from 0/90/180/270) defined in BODY coordinates appears exactly where it is in the body XY cut.
    inst = model.installations('SBA_NADIR');
    dB = [cosd(-60); sind(-60); 0];                       % body XY plane, alpha = -60 deg
    [t0, p0] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi(dB);
    h.isTrue('feature lies off the raw XZ/YZ planes', min(abs(mod(p0, 90) - [0 90])) > 10 && t0 > 10 && t0 < 170);
    sb = base; sb.tiltX = 0; sb.bump = [t0 p0 30 8]; sb.axis = pn('PANEL_6').';
    [Tb, Pb] = ndgrid(0:2:180, 0:2:358); Gb = S.gain(Tb, Pb, sb);
    f = fullfile(tmp, 'bump.txt'); S.write(f, Tb, Pb, Gb, 'cst');
    nb = I.read(f);
    pb = rfscreen.cal.CstNativeInstalledPattern('SYNTHETIC_TEST_BUMP', nb, fq, struct('R_BA', inst.R_BA));
    cuts = rfscreen.cal.CalPlotter.bodyCutData(pb, fq);
    cxy = cuts(strcmp({cuts.plane}, 'XY'));
    [gmax, kmax] = max(cxy.gain_dBi);
    h.isTrue('body XY cut sees the body-frame 3D feature at alpha -60', abs(cxy.alpha_deg(kmax) + 60) <= 2 && gmax > sb.back + 10);
    direct = nb.gainAtDirection(cxy.dir_B);
    h.eqTol('body cut = raw body-frame query (no R_BL / R_BA / M_AL)', max(abs(direct - cxy.gain_dBi)), 0, 1e-12);
    R_BL = rfscreen.kaa.CstLocalFrameAdapter.fromR_BA(inst.R_BA);
    h.isTrue('body cut differs from the former body->local re-rotation', max(abs(nb.gainAtLocal(R_BL.' * cxy.dir_B) - cxy.gain_dBi)) > 1);
    cxz = cuts(strcmp({cuts.plane}, 'XZ')); cyz = cuts(strcmp({cuts.plane}, 'YZ'));
    h.isTrue('body XZ cut lies in Y_B = 0, YZ in X_B = 0, XY in Z_B = 0', all(cxz.dir_B(2, :) == 0) && ...
        all(cyz.dir_B(1, :) == 0) && all(cxy.dir_B(3, :) == 0));
    [~, gxz] = nb.planeCut('XZ'); [~, gyz] = nb.planeCut('YZ');
    h.isTrue('feature above the main-lobe peak in the body cut', gmax > sb.peak + 3);
    h.isTrue('feature absent from both raw XZ/YZ cuts (no rotated-2D shortcut)', max([gxz gyz]) < sb.peak + 0.5);
    h.eqTol('body XZ alpha 30 = raw node (theta 60, phi 0)', cxz.gain_dBi(cxz.alpha_deg == 30), nb.gain_dBi(31, 1), 1e-9);
    h.eqTol('body XZ alpha 150 = raw node (theta 60, phi 180)', cxz.gain_dBi(cxz.alpha_deg == 150), nb.gain_dBi(31, 91), 1e-9);
    h.eqTol('body YZ alpha 30 = raw node (theta 60, phi 90)', cyz.gain_dBi(cyz.alpha_deg == 30), nb.gain_dBi(31, 46), 1e-9);
    % antenna-local cuts: the ONLY local -> body mapping (d_B = R_BL d_L), never body -> local
    lc = rfscreen.cal.CalPlotter.localCutData(pb, fq);
    for i = 1:numel(lc)
        h.eqTol(sprintf('local %s cut: d_B = R_BL d_L', lc(i).plane), max(max(abs(lc(i).dir_B - R_BL * lc(i).dir_L))), 0, 1e-15);
        h.eqTol(sprintf('local %s cut: gain = raw body query of d_B', lc(i).plane), ...
            max(abs(lc(i).gain_dBi - nb.gainAtDirection(lc(i).dir_B))), 0, 1e-12);
        h.isTrue(sprintf('local %s cut: angle 0 = panel normal n_B', lc(i).plane), norm(lc(i).dir_B(:, lc(i).ang_deg == 0) - pn('PANEL_6')) < 1e-9);
    end
    pz = rfscreen.cal.CstNativeInstalledPattern('SYNTHETIC_TEST_Z', nb, fq, struct('R_BA', model.installations('SBA_ZENITH').R_BA));
    lz = rfscreen.cal.CalPlotter.localCutData(pz, fq);
    h.isTrue('SBA_ZENITH local +Z_L = -Z_B (PANEL_4)', norm(lz(1).dir_B(:, lz(1).ang_deg == 0) - [0; 0; -1]) < 1e-12);
    h.throws('body cuts refuse a CST_LOCAL (free-space) pattern', @() rfscreen.cal.CalPlotter.bodyCutData(pf, fq), ...
        'rfscreen:cal:notBodyFramePattern');

    % one coordinate definition for every frequency: 2.06 / 2.25 GHz planes of the same installation share R_BA / R_BL
    p206 = rfscreen.cal.CstNativeInstalledPattern('SYNTHETIC_TEST_206', nb, 2.06e9, struct('R_BA', inst.R_BA));
    p225 = rfscreen.cal.CstNativeInstalledPattern('SYNTHETIC_TEST_225', nb, 2.25e9, struct('R_BA', inst.R_BA));
    h.isTrue('same frame at 2.06 and 2.25 GHz', isequal(p206.R_BL, p225.R_BL) && ...
        abs(p206.gainBody(2.06e9, dB) - p225.gainBody(2.25e9, dB)) < 1e-12);

    %% ---------------- ingestion diagnostics (no parser relaxation) ----------------
    D = rfscreen.cal.CalIngestDiagnostics;
    [pv, dv] = D.readFile(fullfile(fx, 'SYNTHETIC_TEST_standard_15deg.txt'));
    h.isTrue('diag: full-sphere fixture passes all read stages', ~isempty(pv) && isempty(dv.status) && ...
        strcmp(dv.last_stage_completed, 'spherical_grid_validation') && isempty(dv.failure_stage));
    h.isTrue('diag: full-sphere statistics', dv.n_rows == 312 && dv.n_columns == 8 && dv.n_theta == 13 && dv.n_phi == 24 && ...
        dv.theta_step_deg == 15 && dv.phi_step_deg == 15 && dv.expected_samples == 312 && dv.actual_samples == 312 && ...
        dv.missing_samples == 0 && dv.duplicate_samples == 0 && dv.expected_full_sphere_samples == 312);
    h.isTrue('diag: pole statistics', dv.n_rows_theta0 == 24 && dv.n_phi_at_theta0 == 24 && dv.n_rows_theta180 == 24);
    h.isTrue('diag: gain range', abs(dv.gain_min_dbi - min(G(:))) < 1e-5 && abs(dv.gain_max_dbi - max(G(:))) < 1e-5);
    [~, dm] = D.readFile(fullfile(tmp, 'bad.txt'));
    h.isTrue('diag: malformed row -> PARSE_ERROR at numeric_parsing, line 7', strcmp(dm.status, 'PARSE_ERROR') && ...
        strcmp(dm.failure_stage, 'numeric_parsing') && strcmp(dm.error_identifier, 'rfscreen:cal:malformedRow') && dm.line_number == 7);
    h.isTrue('diag: malformed row keeps partial statistics', dm.n_rows == 4 && dm.preamble_lines == 2 && dm.n_columns == 8);
    [~, ds] = D.readFile(fullfile(tmp, 'short.txt'));
    h.isTrue('diag: column-count mismatch line reported', strcmp(ds.status, 'PARSE_ERROR') && ds.line_number == 12 && ...
        ~isempty(strfind(ds.error_message, '3 columns, expected 8')));
    [~, dmi] = D.readFile(fullfile(tmp, 'miss.txt'));
    h.isTrue('diag: missing sample -> GRID_VALIDATION_ERROR with sample statistics', strcmp(dmi.status, 'GRID_VALIDATION_ERROR') && ...
        strcmp(dmi.failure_stage, 'spherical_grid_validation') && strcmp(dmi.error_identifier, 'rfscreen:cal:missingSample') && ...
        dmi.expected_samples == 312 && dmi.actual_samples == 311 && dmi.missing_samples == 1 && dmi.missing_theta_planes == 0 && ...
        dmi.example_missing_theta_deg == M0(50, 1) && dmi.example_missing_phi_deg == M0(50, 2));
    [~, dpl] = D.readFile(fullfile(tmp, 'missplane.txt'));
    h.isTrue('diag: missing phi plane counted', strcmp(dpl.error_identifier, 'rfscreen:cal:missingSample') && ...
        dpl.missing_phi_planes == 1 && dpl.missing_samples == 13 && dpl.n_phi == 23);
    [~, dnp] = D.readFile(fullfile(tmp, 'nopole.txt'));
    h.isTrue('diag: incomplete theta range with min/max', strcmp(dnp.error_identifier, 'rfscreen:cal:incompleteGrid') && ...
        dnp.theta_min_deg == 0 && dnp.theta_max_deg == 165 && dnp.missing_samples == 0 && dnp.expected_full_sphere_samples == 312 && ...
        dnp.actual_samples == 288 && dnp.n_rows_theta180 == 0);
    [~, dd] = D.readFile(fullfile(tmp, 'dup.txt'));
    h.isTrue('diag: duplicate count and line', strcmp(dd.error_identifier, 'rfscreen:cal:duplicateSample') && ...
        dd.duplicate_samples == 1 && dd.line_number == 2 + 313 && dd.actual_samples == 312);
    [~, dn] = D.readFile(fullfile(tmp, 'nan.txt'));
    h.isTrue('diag: NaN gain -> GRID_VALIDATION_ERROR nonFinite with line', strcmp(dn.status, 'GRID_VALIDATION_ERROR') && ...
        strcmp(dn.error_identifier, 'rfscreen:cal:nonFinite') && dn.n_nonfinite_gain == 1 && dn.line_number == 22);
    Mi = M0; Mi(30, 3) = Inf;
    f = fullfile(tmp, 'inf.txt'); writeRows(f, Mi, 'h\n---\n');
    [~, di] = D.readFile(f);
    h.isTrue('diag: Inf gain identified', strcmp(di.error_identifier, 'rfscreen:cal:nonFinite') && di.n_nonfinite_gain == 1 && di.line_number == 32);
    Mpl = M0(~(M0(:, 1) == 0 & M0(:, 2) > 0), :);
    f = fullfile(tmp, 'polecollapsed.txt'); writeRows(f, Mpl, 'h\n---\n');
    [~, dpc] = D.readFile(f);
    h.isTrue('diag: pole with a single phi sample', strcmp(dpc.error_identifier, 'rfscreen:cal:missingSample') && ...
        dpc.n_rows_theta0 == 1 && dpc.n_phi_at_theta0 == 1 && dpc.missing_samples == 23 && dpc.n_phi_at_theta180 == 24);
    Mneg = M0; Mneg(:, 2) = mod(Mneg(:, 2) + 180, 360) - 180;
    f = fullfile(tmp, 'phineg.txt'); writeRows(f, Mneg, 'h\n---\n');
    [~, dng] = D.readFile(f);
    h.isTrue('diag: phi -180..180 export identified (still refused)', strcmp(dng.status, 'GRID_VALIDATION_ERROR') && ...
        strcmp(dng.error_identifier, 'rfscreen:cal:phiRange') && strcmp(dng.failure_stage, 'spherical_grid_construction') && ...
        dng.phi_min_deg == -180 && dng.phi_max_deg == 165 && ~isempty(strfind(dng.phi_convention, '-180')));
    h.throws('parser policy unchanged: phi -180..180 still refused by read()', @() I.read(f), 'rfscreen:cal:phiRange');
    [~, dr] = D.readFile(fullfile(tmp, 'does_not_exist.txt'));
    h.isTrue('diag: unreadable file -> READ_ERROR at ascii_read', strcmp(dr.status, 'READ_ERROR') && ...
        strcmp(dr.failure_stage, 'ascii_read') && strcmp(dr.error_identifier, 'rfscreen:cal:fileNotFound'));
    f = fullfile(tmp, 'hdronly.txt'); fid = fopen(f, 'w'); fprintf(fid, 'Theta Phi\n------\n'); fclose(fid);
    [~, dh] = D.readFile(f);
    h.isTrue('diag: header only -> PARSE_ERROR noData', strcmp(dh.status, 'PARSE_ERROR') && strcmp(dh.error_identifier, 'rfscreen:cal:noData'));

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
    dg = @(name) cat.entries(strcmp({cat.entries.relPath}, name)).diag;
    h.isTrue('corrupt file: stage numeric_parsing + line number', strcmp(dg('sba/RFC_SBA_f9.65.txt').failure_stage, 'numeric_parsing') && ...
        isfinite(dg('sba/RFC_SBA_f9.65.txt').line_number));
    h.eqStr('unrecognised name stage', dg('isl/RFC_ISL_NADIR_f10.6.txt').failure_stage, 'filename_classification');
    h.eqStr('unmapped token stage', dg('kaa/RFC_KAA_f3.3.txt').failure_stage, 'frequency_binding');
    h.eqStr('duplicate binding stage', dg('sba/RFC_SBA_f10.6.txt').failure_stage, 'catalog_binding');
    h.isTrue('valid file: all stages completed', strcmp(dg('gps/GPS_GPSA1_f1.2.txt').status, 'VALID') && ...
        strcmp(dg('gps/GPS_GPSA1_f1.2.txt').last_stage_completed, 'catalog_binding'));
    eg = cat.entries(strcmp({cat.entries.relPath}, 'gps/GPS_GPSA1_f1.2.txt'));
    h.isTrue('GPS provenance: 1.2 GHz CST solve as SURROGATE, body frame', strcmp(eg.frequencyTreatment, 'SURROGATE') && ...
        eg.sourceSimulationFrequency_Hz == 1.2e9 && strcmp(eg.sourceFrame, 'SPACECRAFT_BODY_FIXED'));
    h.eqStr('owner GPS installed file valid', st('gps/GPS_GPSA1_f1.2.txt'), 'VALID');
    B = rfscreen.cal.CalPatternBinder(cat, fullfile(cfg, 'cal_installations.csv'));
    g1 = {}; for fr = [f5 f2 f1]; g1{end+1} = B.bind('GPSA_1', 'RX', fr); end %#ok<AGROW>
    h.isTrue('GPS: L5/L2/L1 share GPS_GPSA1_f1.2', all(cellfun(@(x) strcmp(x.status, 'BOUND') && ...
        ~isempty(strfind(x.file, 'GPS_GPSA1_f1.2')) && strcmp(x.patternType, 'INSTALLED'), g1)));
    u = [0.3; -0.5; 0.81]; u = u / norm(u);
    gg = cellfun(@(x, fr) x.pattern.gainAntenna(fr, u), g1, {f5, f2, f1});
    h.eqTol('GPS: identical spatial pattern at L5/L2/L1', max(gg) - min(gg), 0, 1e-12);
    h.isTrue('GPS: pattern provenance SURROGATE of the 1.2 GHz solve', all(cellfun(@(x) strcmp(x.pattern.frequencyTreatment, 'SURROGATE') && ...
        x.pattern.sourceSimulationFrequency_Hz == 1.2e9, g1)));

    % GPS read / validation failures are reported per file with the failing stage and grid statistics
    root4 = fullfile(tmp, 'cal4');
    [Tg, Pg, Gg] = S.grid(15, base);
    S.write(fullfile(root4, 'gps', 'GPS_GPSA2_f1.2.txt'), Tg, Pg, Gg);
    Mg = [Tg(:) Pg(:) Gg(:) 0 * Tg(:) 0 * Tg(:) 0 * Tg(:) 0 * Tg(:) 0 * Tg(:)];
    writeRows(fullfile(root4, 'gps', 'GPS_ORIGINAL_f1.2.txt'), Mg([1:99 101:end], :), 'h\n---\n');
    writeRows(fullfile(root4, 'gps', 'GPS_GPSA1_f1.2.txt'), Mg, 'h\n---\n', 40, '15.0 30.0 1.0 x');
    fid = fopen(fullfile(root4, 'gps', 'notes.csv'), 'w'); fprintf(fid, 'x\n'); fclose(fid);
    fid = fopen(fullfile(root4, 'stray.txt'), 'w'); fprintf(fid, 'x\n'); fclose(fid);
    cat4 = rfscreen.cal.CalPatternCatalog.scan(root4, fmap, model);
    e4 = @(name) cat4.entries(strcmp({cat4.entries.relPath}, name));
    eo = e4('gps/GPS_ORIGINAL_f1.2.txt'); ea = e4('gps/GPS_GPSA1_f1.2.txt'); eb = e4('gps/GPS_GPSA2_f1.2.txt');
    h.isTrue('GPS missing sample: GRID_VALIDATION_ERROR + statistics', strcmp(eo.status, 'GRID_VALIDATION_ERROR') && ...
        eo.diag.missing_samples == 1 && eo.diag.expected_samples == 312 && eo.diag.actual_samples == 311);
    h.isTrue('GPS malformed row: PARSE_ERROR + line', strcmp(ea.status, 'PARSE_ERROR') && ea.diag.line_number == 42);
    h.isTrue('GPS valid file bound as surrogate', strcmp(eb.status, 'VALID') && numel(eb.keys) == 3);
    txo = strjoin(D.consoleLines(eo), sprintf('\n')); txb = strjoin(D.consoleLines(eb), sprintf('\n'));
    h.isTrue('console: failing GPS file shows status / stage / id / samples', ~isempty(strfind(txo, '[CAL] gps/GPS_ORIGINAL_f1.2.txt')) && ...
        ~isempty(strfind(txo, 'status: GRID_VALIDATION_ERROR')) && ~isempty(strfind(txo, 'stage : spherical_grid_validation')) && ...
        ~isempty(strfind(txo, 'error id: rfscreen:cal:missingSample')) && ~isempty(strfind(txo, 'missing samples : 1')) && ...
        ~isempty(strfind(txo, 'theta : 0 .. 180 deg, unique=13, step=15')));
    h.isTrue('console: valid GPS file shows the surrogate binding', ~isempty(strfind(txb, 'status: VALID')) && ...
        ~isempty(strfind(txb, 'source simulation frequency: 1.2 GHz')) && ~isempty(strfind(txb, 'bound as surrogate for: L5 / L2 / L1')));
    h.isTrue('file discovery notes: stray root file and non-.txt file', any(~cellfun(@isempty, strfind(cat4.discovery, 'stray.txt'))) && ...
        any(~cellfun(@isempty, strfind(cat4.discovery, 'notes.csv'))));
    B4 = rfscreen.cal.CalPatternBinder(cat4, fullfile(cfg, 'cal_installations.csv'));
    b4 = B4.bind('GPSA_1', 'RX', f1);
    h.isTrue('failed GPS files are not used (no repair, no fallback to a failed file)', strcmp(b4.status, 'INPUT_MISSING'));
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
