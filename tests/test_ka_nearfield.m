function test_ka_nearfield(h)
%TEST_KA_NEARFIELD KAA reflector-aperture near-field source model (Ka RFI, output/claude).
%   Normalization, far-field convergence to the validated reflector pattern, symmetry, frequency
%   scaling, KAA_1/KAA_2 frames, gimbal steering, an intentionally asymmetric frame regression,
%   missing victim Ka response and the in-band-gain guard.
    h.setGroup('ka_nearfield');
    repo = fileparts(fileparts(mfilename('fullpath')));
    S = rfscreen.kaa.ApertureNearFieldSolver; A = rfscreen.kaa.CstLocalFrameAdapter;
    K = rfscreen.kaa.KaRfiPath; GS = rfscreen.kaa.KaGimbalScreening;
    F = [25.5e9 26.25e9 27e9]; c0 = 299792458;

    m = rfscreen.kaa.ReflectorApertureModel.fromRepository(repo);
    mq = m.withSampling(struct('nRho', 160, 'nPhi', 360));           % reduced sampling for sweeps

    % ---- provenance: validated model re-used, not regenerated ----
    R1 = jsondecode(fileread(fullfile(repo, 'cst', 'results', 'KA_REFLECTOR_KA_FEED_C_OEWG', 'reflector_validation.json')));
    R2 = jsondecode(fileread(fullfile(repo, 'data', 'Kaband_KAA_CST', 'ka_final_validation.json')));
    h.eqStr('reflector status PASS', R1.status, 'KA_DATASHEET_ANCHOR_PASS');
    h.eqTol('D/Fe/Ds cst == data export', [R1.reflector.D_mm R1.reflector.Fe_mm R1.reflector.Ds_mm], ...
        [R2.reflector.D_mm R2.reflector.Fe_mm R2.reflector.Ds_mm], 0);
    h.eqTol('D = 220 mm, Ds = 44 mm', [m.D_m m.Ds_m], [0.220 0.044], 1e-12);
    h.eqTol('feed monitors 25.5/26.25/27 GHz', m.freqs_Hz, F, 1);

    % ---- aperture field normalization ----
    for f = F
        h.eqTol(sprintf('aperture power == feed annulus power %.2f GHz', f / 1e9), ...
            m.interceptedPowerFraction(f), m.feedAnnulusFraction(f), 2e-4);
    end
    un = rfscreen.kaa.ReflectorApertureModel.synthetic('SYNTHETIC_TEST_UNIFORM', 0.22, 0.044, F, ...
        @(r, p, f) ones(size(r)), struct('nRho', 200, 'nPhi', 64));
    Aann = pi * (0.11 ^ 2 - 0.022 ^ 2);
    for f = F
        Dir = 10 ^ (S.farFieldGain(un, f, 0, 0) / 10) / un.interceptedPowerFraction(f);
        h.eqTol(sprintf('uniform annulus directivity = 4 pi A / lambda^2 (%.2f GHz)', f / 1e9), ...
            10 * log10(Dir), 10 * log10(4 * pi * Aann / (c0 / f) ^ 2), 2e-3);
    end
    E1 = S.evaluate(m, 26.25e9, 30, [0; 0; 3]); E2 = S.evaluate(m, 26.25e9, 40, [0; 0; 3]);
    h.eqTol('power density scales linearly with P', E2.S_dBmpm2 - E1.S_dBmpm2, 10, 1e-9);
    h.eqTol('port power = S lambda^2/(4 pi) G', S.portPower_dBm(1, 0, 26.25e9), ...
        10 * log10((c0 / 26.25e9) ^ 2 / (4 * pi)) + 30, 1e-12);

    % ---- far-field convergence to the validated reflector pattern (26.25 GHz) ----
    f = 26.25e9; th = [0 0.5 1 2 3 5.1 10 30];
    Gff = S.farFieldGain(m, f, th, zeros(size(th)));
    fine = dlmread(fullfile(repo, 'cst', 'results', 'KA_REFLECTOR_KA_FEED_C_OEWG', 'fine_0p05deg_f26.25.csv'), ',', 1, 0);
    full = dlmread(fullfile(repo, 'cst', 'results', 'KA_REFLECTOR_KA_FEED_C_OEWG', 'full_1deg_f26.25.csv'), ',', 1, 0);
    ref = [interp1(fine(:, 1), fine(:, 2), th(th <= 10)), interp1(full(:, 1), full(:, 2), th(th > 10))];
    h.isTrue('MATLAB far field == validated Python reflector CSV (<=0.01 dB)', max(abs(Gff - ref)) <= 0.01);
    Rff = m.farFieldDistance(f);
    for fac = [10 100]
        r = fac * Rff * [sind(th); zeros(size(th)); cosd(th)];
        e = S.evaluate(m, f, 30, r);
        tol = 0.05; if fac == 100; tol = 1e-3; end
        h.isTrue(sprintf('near field -> far field at %d R_ff (max err %.2g dB)', fac, max(abs(e.Geq_dBi - Gff))), ...
            max(abs(e.Geq_dBi - Gff)) <= tol);
    end
    eNear = S.evaluate(m, f, 30, [0; 0; 1.78]);
    h.isTrue('at 1.78 m (< R_ff) boresight Geq is below the far-field gain', eNear.Geq_dBi < Gff(1) - 0.5);

    % ---- boresight symmetry / XZ-YZ axisymmetric consistency ----
    for t = [0.8 4 25 120]
        p = 2.0 * [sind(t) -sind(t) 0 0; 0 0 sind(t) -sind(t); cosd(t) cosd(t) cosd(t) cosd(t)];
        e = S.evaluate(mq, f, 30, p);
        h.eqTol(sprintf('+X/-X symmetric at %g deg', t), e.S_dBmpm2(1), e.S_dBmpm2(2), 1e-6);
        h.eqTol(sprintf('+Y/-Y symmetric at %g deg', t), e.S_dBmpm2(3), e.S_dBmpm2(4), 1e-6);
        h.eqTol(sprintf('XZ == YZ at %g deg', t), e.S_dBmpm2(1), e.S_dBmpm2(3), 1e-6);
    end

    % ---- frequency scaling ----
    g1 = S.farFieldGain(un, 25.5e9, 0, 0); g2 = S.farFieldGain(un, 27e9, 0, 0);
    h.eqTol('uniform boresight gain scales as f^2', g2 - g1, 20 * log10(27 / 25.5), 1e-6);
    h.eqTol('R_ff scales as f', m.farFieldDistance(27e9) / m.farFieldDistance(25.5e9), 27 / 25.5, 1e-12);
    gb = arrayfun(@(x) S.farFieldGain(m, x, 0, 0), F);
    h.isTrue('validated model boresight increases with f (32.28/32.63/32.98)', all(diff(gb) > 0) && abs(gb(1) - 32.284) < 0.01);

    % ---- KAA_1 / KAA_2 coordinate transforms ----
    model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
    pos = containers.Map(); nrm = containers.Map();
    for i = 1:numel(model.installationRecords)
        rc = model.installationRecords(i); pn = model.panels(strcmp({model.panels.id}, rc.panelId));
        pos(rc.antennaId) = rc.position_m(:); nrm(rc.antennaId) = pn.normal_B(:);
    end
    Rk1 = A.fixedMount(nrm('KAA_1')); Rk2 = A.fixedMount(nrm('KAA_2'));
    h.eqTol('KAA_1 aperture frame = body (Panel #1 +Z)', Rk1, eye(3), 1e-12);
    h.eqTol('KAA_2 aperture frame', Rk2, [1 0 0; 0 -0.5 0.866025404; 0 -0.866025404 -0.5], 1e-9);
    for id = {'KAA_1', 'KAA_2', 'SBA_NADIR', 'ISL'}
        n = nrm(id{1}); legacy = [[1; 0; 0], cross(n, [1; 0; 0]), n];          % run_rfi_analysis local_frame
        h.eqTol(['adapter == CST local frame ' id{1}], A.fixedMount(n), legacy, 1e-12);
    end
    dom1 = model.steering('KAA_1'); dom2 = model.steering('KAA_2');
    h.eqTol('gimbal reference pointing == fixed mount (KAA_1)', A.gimbalPointing(dom1, dom1.referenceAxis_B), Rk1, 1e-12);
    h.eqTol('gimbal reference pointing == fixed mount (KAA_2)', A.gimbalPointing(dom2, dom2.referenceAxis_B), Rk2, 1e-12);
    rL = A.pointToLocal(Rk1, pos('KAA_1'), pos('ISL'));
    h.eqTol('KAA_1 -> ISL in aperture frame (body delta)', rL, pos('ISL') - pos('KAA_1'), 1e-12);
    rL2 = A.pointToLocal(Rk2, pos('KAA_2'), pos('ISL'));
    h.eqTol('KAA_2 -> ISL aperture-frame z = d . n', rL2(3), dot(pos('ISL') - pos('KAA_2'), nrm('KAA_2')), 1e-12);
    h.eqTol('rotation preserves distance', norm(rL2), norm(pos('ISL') - pos('KAA_2')), 1e-12);
    h.isFalse('explicit adapter is not CutPatternAssembler.canonicalToAntenna', ...
        isequal(A.localToAntenna(), rfscreen.patterndata.CutPatternAssembler.canonicalToAntenna()));
    h.eqTol('adapter is a proper rotation', det(A.localToAntenna()), 1, 1e-12);

    % ---- gimbal rotation ----
    v = pos('SBA_NADIR') - pos('KAA_1');
    Rp = A.gimbalPointing(dom1, v / norm(v));
    rp = A.pointToLocal(Rp, pos('KAA_1'), pos('SBA_NADIR'));
    [tp, ~] = A.thetaPhi(rp);
    h.eqTol('steered at victim -> victim on +Z_L', tp, 0, 1e-9);
    Ru = A.gimbalPointing(dom1, [0; 1; 0]);
    h.eqTol('steered +Y_B boresight -> Z_L = +Y_B', Ru(:, 3), [0; 1; 0], 1e-12);
    h.eqTol('steered frame keeps X_L = +X_B (roll convention)', Ru(:, 1), [1; 0; 0], 1e-12);
    h.throws('steering outside the hemisphere refused', @() A.gimbalPointing(dom1, [0; 0; -1]), ...
        'rfscreen:spacecraft:outsideSteeringDomain');
    wt = 0;
    sc = GS.screen(mq, 26.25e9, 48.451, pos('KAA_1'), dom1, pos('SBA_NADIR'), wt);
    h.isTrue('screen: all states allowed', all([sc.allowed]));
    h.isTrue('screen: worst >= nominal and >= directed', sc(3).metric_dB >= sc(1).metric_dB - 1e-9 && sc(3).metric_dB >= sc(2).metric_dB - 1e-9);
    h.eqTol('screen: victim-directed theta = 0 when reachable', sc(2).theta_ap_deg, 0, 1e-9);
    U = dom1.sampleDirections(6); best = -Inf;
    for q = 1:size(U, 2)
        Rq = A.gimbalPointing(dom1, U(:, q)); r = A.pointToLocal(Rq, pos('KAA_1'), pos('SBA_NADIR'));
        e = S.evaluate(mq, 26.25e9, 48.451, r); best = max(best, e.S_dBmpm2);
    end
    h.isTrue(sprintf('brute-force 3D steering (6 deg) <= 1-D worst (%.2f <= %.2f dBm/m2)', best, sc(3).metric_dB + 30), ...
        best <= sc(3).metric_dB + 30 + 0.01);
    scI = GS.screen(mq, 26.25e9, 48.451, pos('KAA_1'), dom1, pos('ISL'), wt);
    h.isTrue('ISL is behind KAA_1: victim-directed is a boundary pointing (90 deg off ref)', ...
        abs(scI(2).offAxisFromRef_deg - 90) < 1e-6 && scI(2).allowed);
    h.isTrue('ISL behind KAA_1: worst case <= main beam density at that distance', ...
        scI(3).metric_dB <= 10 * log10(GS.densityAt(mq, 26.25e9, 48.451, norm(pos('ISL') - pos('KAA_1')), 0)) + 1e-9);

    % ---- intentionally asymmetric synthetic frame regression ----
    tilt = 15;
    asy = rfscreen.kaa.ReflectorApertureModel.synthetic('SYNTHETIC_TEST_TILT_X', 0.22, 0, 26.25e9, ...
        @(r, p, f) exp(-1j * 2 * pi * f / c0 * sind(tilt) * r .* cos(p)) .* (1 + 0 * r), struct('nRho', 120, 'nPhi', 256));
    gpk = S.farFieldGain(asy, 26.25e9, tilt, 0);
    h.isTrue('synthetic beam peaks at +15 deg toward +X_L', gpk > S.farFieldGain(asy, 26.25e9, tilt, 180) + 20 && ...
        gpk > S.farFieldGain(asy, 26.25e9, tilt, 90) + 20);
    dL = [sind(tilt); 0; cosd(tilt)];
    R_BA2 = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.sideMountR_BA(nrm('KAA_2'));
    dRight = Rk2 * dL;                                                % explicit adapter
    dWrong = R_BA2 * rfscreen.patterndata.CutPatternAssembler.canonicalToAntenna() * dL;
    h.eqTol('asymmetric beam body direction = R_BL * d_L (x toward +X_B)', dRight, ...
        cosd(tilt) * nrm('KAA_2') + sind(tilt) * [1; 0; 0], 1e-9);
    h.isTrue('generic canonical map points the beam elsewhere (>10 deg)', acosd(dot(dRight, dWrong)) > 10);
    far = 200 * asy.farFieldDistance(26.25e9);
    pR = pos('KAA_2') + far * dRight; pW = pos('KAA_2') + far * dWrong;
    eR = S.evaluate(asy, 26.25e9, 30, A.pointToLocal(Rk2, pos('KAA_2'), pR));
    eW = S.evaluate(asy, 26.25e9, 30, A.pointToLocal(Rk2, pos('KAA_2'), pW));
    h.eqTol('field at body beam direction == synthetic peak', eR.Geq_dBi, gpk, 1e-3);
    h.isTrue('frame swap would change the coupling by > 15 dB', eR.Geq_dBi - eW.Geq_dBi > 15);
    eMir = S.evaluate(asy, 26.25e9, 30, far * [-sind(tilt); 0; cosd(tilt)]);
    h.isTrue('asymmetric field is not X-mirror symmetric', eR.Geq_dBi - eMir.Geq_dBi > 20);

    % ---- victim Ka responses: missing -> INPUT_MISSING, never substituted ----
    rS = rfscreen.kaa.KaVictimResponse.fromRepository(repo, 'S');
    rL_ = rfscreen.kaa.KaVictimResponse.fromRepository(repo, 'L');
    rSar = rfscreen.kaa.KaVictimResponse.fromRepository(repo, 'SAR');
    rI = rfscreen.kaa.KaVictimResponse.fromRepository(repo, 'ISL');
    h.eqStr('S Ka response INPUT_MISSING', rS.status, 'INPUT_MISSING');
    h.isTrue('S missing reason cites MESH_LIMIT', ~isempty(strfind(rS.reason, 'MESH_LIMIT')));
    h.eqStr('L Ka response INPUT_MISSING', rL_.status, 'INPUT_MISSING');
    h.isTrue('L missing reason cites MESH_LIMIT', ~isempty(strfind(rL_.reason, 'MESH_LIMIT')));
    h.eqStr('SAR Ka response INPUT_MISSING', rSar.status, 'INPUT_MISSING');
    h.isTrue('SAR reason NO_PATTERN_BOUND', ~isempty(strfind(rSar.reason, 'NO_PATTERN_BOUND')));
    h.eqStr('ISL Ka response AVAILABLE', rI.status, 'AVAILABLE');
    h.eqTol('ISL Ka monitors', rI.freqs_Hz, F, 1);
    h.throws('missing S Ka response cannot be evaluated', @() rS.gainAt(26.25e9, [0; 0; 1]), 'rfscreen:kaa:victimResponseMissing');
    h.throws('missing SAR Ka response cannot be evaluated', @() rSar.gainAt(26.25e9, [0; 0; 1]), 'rfscreen:kaa:victimResponseMissing');
    h.isTrue('missing response carries no cuts (no isotropic fill)', isempty(rS.xz) && isempty(rS.freqs_Hz));
    h.eqTol('ISL Ka gain on +Z_L at 26.25 GHz == XZ cut(0)', rI.gainAt(26.25e9, [0; 0; 1]), rI.xz{2}(1), 1e-12);

    % ---- no accidental use of the victim in-band gain for the Ka fundamental ----
    prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));
    cuts = prov.cuts; if iscell(cuts); cuts = [cuts{:}]; end
    c = cuts(strcmp({cuts.family}, 'S') & strcmp({cuts.band}, 'S_TC') & strcmp({cuts.quantity}, 'RealizedGain') & strcmp({cuts.plane}, 'XZ'));
    g = rfscreen.kaa.KaVictimResponse.readCut(fullfile(repo, c(1).path));
    inb = rfscreen.kaa.KaVictimResponse.fromCuts('S', 'S_TC', c(1).frequency_hz, {g}, {g}, 'S/S_TC in-band');
    h.throws('S_TC in-band gain refused for Ka fundamental', @() inb.gainAt(26.25e9, [0; 0; 1]), 'rfscreen:kaa:inBandGainForbidden');
    h.throws('Ka response refused outside 25.5-27 GHz', @() rI.gainAt(10.6e9, [0; 0; 1]), 'rfscreen:kaa:outsideKaBand');
    h.throws('near-field source only at CST feed monitors', @() m.feedGain(26e9, 0.1), 'rfscreen:kaa:notAMonitor');

    % ---- routing / status vocabulary ----
    h.eqStr('S TX keeps free-space pattern path', K.sourceModelFor('S', 2, 1), K.FREE_SPACE);
    h.eqStr('ISL TX keeps free-space pattern path', K.sourceModelFor('ISL', 2, 1), K.FREE_SPACE);
    h.eqStr('KAA onboard -> aperture near field', K.sourceModelFor('KA', 1.78, m.farFieldDistance(27e9)), K.NEAR_FIELD);
    h.eqStr('KAA beyond R_ff -> far-field pattern', K.sourceModelFor('KA', 50, m.farFieldDistance(27e9)), K.FAR_FIELD);
    h.eqStr('KAA validation -> far-field pattern', K.sourceModelFor('KA', 1.78, 8.7, 'VALIDATION'), K.FAR_FIELD);
    rx = struct('p1db_in_dBm', NaN, 'iip3_in_dBm', NaN, 'kaRejection_dB', NaN);
    h.eqStr('no receiver data -> blocking unknown', K.receiverImpact(rx, true), K.RX_UNKNOWN);
    h.eqStr('no port coupling -> not evaluated', K.receiverImpact(rx, false), K.RX_NOT_REACHED);
    sp = K.spurPath('S_TC_RX@SBA_NADIR', [2.0499e9 2.0501e9], []);
    h.eqStr('spur path without mask INPUT_MISSING', sp.status, 'INPUT_MISSING');
    h.isNaNval('spur path no port power', sp.P_port_dBm);
    h.isFalse('spur and fundamental path ids differ', strcmp(K.SPUR, K.FUNDAMENTAL));
    h.eqStr('solver scope flag', S.FIELD_SCOPE, 'DIRECT_REFLECTOR_FIELD_ONLY');
    h.eqStr('solver structure flag', S.STRUCTURE_FLAG, 'STRUCTURE_SCATTERING_NOT_MODELED');
end
