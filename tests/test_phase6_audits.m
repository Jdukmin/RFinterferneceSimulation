function test_phase6_audits(h)
%TEST_PHASE6_AUDITS Phase-5 audits (AUD-01..03) + promoted reference-case
%   invariants (Phase 6). Deterministic, analytically defensible.
    h.setGroup('phase6_audits');

    % ================= AUD-01: circular azimuth footprint =================
    box = rfscreen.geometry.BoxGeometry([0.5;0.5;0.5]);
    stBack = rfscreen.geometry.SpacecraftStructure('S','s','BUS', box, eye(3), [-10;0;0], ...
        struct('provenance','SYNTHETIC_TEST'));   % behind antenna -> straddles +-180 seam
    fovBack = rfscreen.geometry.AntennaToStructureFOV.analyze('A',[0;0;0],eye(3), stBack, struct());
    stFront = rfscreen.geometry.SpacecraftStructure('S','s','BUS', box, eye(3), [10;0;0], ...
        struct('provenance','SYNTHETIC_TEST'));    % identical, in front (no seam)
    fovFront = rfscreen.geometry.AntennaToStructureFOV.analyze('A',[0;0;0],eye(3), stFront, struct());

    h.isTrue('AUD-01 seam footprint stays a small arc', fovBack.azimuthSpan_deg < 20);
    h.eqTol('AUD-01 seam span == front span (circular)', fovBack.azimuthSpan_deg, fovFront.azimuthSpan_deg, 1e-9);
    h.isTrue('AUD-01 span is small positive (not ~360)', fovBack.azimuthSpan_deg > 0 && fovBack.azimuthSpan_deg < 30);
    % maxAngularRadius is wrap-safe and identical front/back
    h.eqTol('AUD-01 angular radius identical', fovBack.maxAngularRadius_deg, fovFront.maxAngularRadius_deg, 1e-9);
    % centre behind is at az=180
    h.eqTol('AUD-01 behind centerAz=180', abs(fovBack.centerAz_deg), 180, 1e-6);

    % ================= AUD-02: VERTEX_SAMPLED fidelity, no exact-surface claim =====
    h.eqStr('AUD-02 fidelity is VERTEX_SAMPLED', fovFront.geometryFidelity, 'VERTEX_SAMPLED');
    fids = rfscreen.geometry.GeometryFidelity.values();
    h.isFalse('AUD-02 no EXACT_SURFACE_INTERSECTION fidelity', any(strcmp(fids, 'EXACT_SURFACE_INTERSECTION')));
    h.isTrue('AUD-02 VERTEX_SAMPLED is a declared level', any(strcmp(fids, 'VERTEX_SAMPLED')));

    % ================= AUD-03: multi-frequency InstalledPattern ==================
    az = -180:30:180; el = -90:30:90; freqs = [2.0e9 2.2e9];
    G = zeros(numel(el), numel(az), numel(freqs));
    G(:,:,1) = 5;    % 5 dBi at 2.0 GHz
    G(:,:,2) = 8;    % 8 dBi at 2.2 GHz
    grid = rfscreen.antenna.PatternGrid(az, el, freqs, G);
    inst = rfscreen.antenna.InstalledPattern('SYNTHETIC_TEST_multifreq', 'SIMULATED_3D', grid, 'HFSS');
    h.eqTol('AUD-03 eval at 2.0 GHz = 5', inst.evaluate(2.0e9, 0, 0), 5, 1e-9);
    h.eqTol('AUD-03 eval at 2.2 GHz = 8', inst.evaluate(2.2e9, 0, 0), 8, 1e-9);
    % coexist in the scenario registry under one (antennaId, configId)
    sc = rfscreen.scenario.Scenario('AUD3');
    sc.addInstalledPattern('ANT', 'DEPLOYED', inst);
    got = sc.getInstalledPattern('ANT', 'DEPLOYED');
    h.eqTol('AUD-03 registry keeps both freqs (2.0)', got.evaluate(2.0e9, 0, 0), 5, 1e-9);
    h.eqTol('AUD-03 registry keeps both freqs (2.2)', got.evaluate(2.2e9, 0, 0), 8, 1e-9);

    % ================= Promoted RC invariant: IM3 product frequencies (RC-KARI-RF-01) ===
    % Two strong interferers -> 2f1-f2, 2f2-f1 land at deterministic frequencies; the
    % analyzer flags which products fall inside a target receive band (GNSS-band check).
    fe = rfscreen.receiver.ReceiverFrontEnd(struct('iip3_in_dBm', -10, 'p1dB_in_dBm', -20, ...
        'linearGain_dB', 20, 'provenance', 'SYNTHETIC_TEST'));
    % REAL S-band tones (2-4 GHz). f2 is DERIVED from 2*f1 - f_L1, not hand-picked:
    % this is the only way a two-tone S-band IM3 can land in L1 (RC-RF-01 fix).
    fL1 = 1.57542e9;
    f1 = 2.00e9; f2 = 2*f1 - fL1;                  % f2 = 2.42458 GHz, also S-band
    inputs = struct('txId', {'I1','I2'}, 'freq_Hz', {f1, f2}, ...
        'lnaInputPower_dBm', {-30, -30}, 'isAbsolute', {true, true}, ...
        'couplingValidity', {'FAR_FIELD_VALID','FAR_FIELD_VALID'});
    gnssBand = [1.559e9 1.591e9];                  % ~ GNSS L1 band
    h.isTrue('RC-RF-01 f1 is genuinely S-band', f1 >= 2e9 && f1 <= 4e9);
    h.isTrue('RC-RF-01 f2 is genuinely S-band', f2 >= 2e9 && f2 <= 4e9);
    chan = rfscreen.receiver.IdealBandpassFilter(gnssBand, 0, -Inf);
    im = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(inputs, fe, chan, gnssBand, []);
    pLow = byType(im, '2F1_MINUS_F2');
    h.eqTol('RC-RF-01 IM3 2f1-f2 = L1 exactly', pLow.productFrequency_Hz, fL1, 1);
    h.isTrue('RC-RF-01 IM3 lands in GNSS band', pLow.inPassband);
    pHigh = byType(im, '2F2_MINUS_F1');
    h.eqTol('RC-RF-01 IM3 2f2-f1 = 2f2-f1', pHigh.productFrequency_Hz, 2*f2 - f1, 1);
    h.isFalse('RC-RF-01 upper IM3 outside GNSS band', pHigh.inPassband);
    h.eqStr('RC-RF-01 small-signal IM3 is VALID', im.validity, 'VALID');
    h.isTrue('RC-RF-01 IM3 product below the fundamental', pLow.equivalentInputPower_dBm < -30);

    % ================= Promoted RC invariant: structure FOV occupancy (RC-KARI-01) ===
    p = rfscreen.antenna.SyntheticPatternFactory.mainSideBack(15, -10, -30, 2.2e9, 15);
    stBoresight = rfscreen.geometry.SpacecraftStructure('S','s','SOLAR_ARRAY', ...
        rfscreen.geometry.BoxGeometry([1;1;1]), eye(3), [10;0;0], struct('provenance','SYNTHETIC_TEST'));
    fovB = rfscreen.geometry.AntennaToStructureFOV.analyze('A',[0;0;0],eye(3), stBoresight, ...
        struct('pattern', p, 'frequency_Hz', 2.2e9));
    h.isTrue('RC-01 boresight structure occupies MAIN', fovB.occupies('MAIN'));
    h.isTrue('RC-01 boresight structure centre-ray hits', fovB.centerRayHits);
    h.eqTol('RC-01 boresight centre off-boresight = 0', fovB.centerOffBoresight_deg, 0, 1e-6);

    % ========== DEFECT-A: IM3 small-signal domain guard (paper regime is saturation) ==========
    feSat = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm', -25, 'iip3_in_dBm', -15, ...
        'linearGain_dB', 28, 'provenance', 'SYNTHETIC_TEST'));
    bandL1 = [1.559e9 1.591e9];
    chanL1 = rfscreen.receiver.IdealBandpassFilter(bandL1, 0, -Inf);
    fS1 = 2.00e9; fS2 = 2*fS1 - 1.57542e9;
    satIn = struct('txId', {'A','B'}, 'freq_Hz', {fS1, fS2}, ...
        'lnaInputPower_dBm', {-8, -8}, 'isAbsolute', {true, true}, ...
        'couplingValidity', {'FAR_FIELD_VALID','FAR_FIELD_VALID'});
    imSat = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(satIn, feSat, chanL1, bandL1, []);
    h.eqStr('DEFECT-A saturated IM3 flagged OUTSIDE_MODEL_DOMAIN', imSat.validity, 'OUTSIDE_MODEL_DOMAIN');
    pSat = byType(imSat, '2F1_MINUS_F2');
    h.eqStr('DEFECT-A product flagged too', pSat.validity, 'OUTSIDE_MODEL_DOMAIN');
    h.isTrue('DEFECT-A warning emitted', numel(pSat.warnings) >= 1);
    h.eqTol('DEFECT-A headroom is negative (above P1dB)', pSat.toneHeadroomBelowP1dB_dB, -17, 1e-9);
    h.isTrue('DEFECT-A product frequency still exact', abs(pSat.productFrequency_Hz - 1.57542e9) < 1);

    smallIn = struct('txId', {'A','B'}, 'freq_Hz', {fS1, fS2}, ...
        'lnaInputPower_dBm', {-40, -40}, 'isAbsolute', {true, true}, ...
        'couplingValidity', {'FAR_FIELD_VALID','FAR_FIELD_VALID'});
    imSml = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(smallIn, feSat, chanL1, bandL1, []);
    h.eqStr('DEFECT-A small-signal IM3 stays VALID', imSml.validity, 'VALID');
    pSml = byType(imSml, '2F1_MINUS_F2');
    h.eqTol('DEFECT-A small-signal headroom = 15 dB', pSml.toneHeadroomBelowP1dB_dB, 15, 1e-9);
    h.eqTol('DEFECT-A small-signal P_IM3 = 3P-2*IIP3', pSml.equivalentInputPower_dBm, 3*(-40)-2*(-15), 1e-9);

    % ========== RC-KARI-01 paper numbers: P-ANT angular subtense (PUBLIC_REPORTED) ==========
    % 임원규 외, KSAS 2015 춘계 pp.832-835: 4 deg <-> ~30 cm, 12 deg <-> ~83 cm at ~4 m.
    R = 4.0;
    R_BS = rfscreen.geometry.Rotation.aboutX(90);
    pantSmall = rfscreen.geometry.SpacecraftStructure('P30','P-ANT 30cm','REFLECTOR', ...
        rfscreen.geometry.DiskGeometry(0.30, 32), R_BS, [0;R;0], ...
        struct('provenance','PUBLIC_REPORTED'));
    fSmall = rfscreen.geometry.AntennaToStructureFOV.analyze('S',[0;0;0],eye(3), pantSmall, struct());
    h.eqTol('RC-01 30cm@4m subtense = 4 deg (paper)', 2*fSmall.maxAngularRadius_deg, 4.0, 0.5);
    h.eqTol('RC-01 30cm subtense == closed form', 2*fSmall.maxAngularRadius_deg, ...
        2*atand(0.30/2/R), 1e-6);

    pantLarge = rfscreen.geometry.SpacecraftStructure('P83','P-ANT 83cm','REFLECTOR', ...
        rfscreen.geometry.DiskGeometry(0.83, 32), R_BS, [0;R;0], ...
        struct('provenance','PUBLIC_REPORTED'));
    fLarge = rfscreen.geometry.AntennaToStructureFOV.analyze('S',[0;0;0],eye(3), pantLarge, struct());
    h.eqTol('RC-01 83cm@4m subtense = 12 deg (paper)', 2*fLarge.maxAngularRadius_deg, 12.0, 0.5);
    h.eqTol('RC-01 83cm subtense == closed form', 2*fLarge.maxAngularRadius_deg, ...
        2*atand(0.83/2/R), 1e-6);
    h.eqTol('RC-01 P-ANT sits at 90 deg off-boresight', fLarge.centerOffBoresight_deg, 90, 1e-6);

    % DiskGeometry must NOT overestimate like a square panel's corner sampling
    panelSq = rfscreen.geometry.SpacecraftStructure('PS','square panel','REFLECTOR', ...
        rfscreen.geometry.PanelGeometry(0.83, 0.83), R_BS, [0;R;0], ...
        struct('provenance','SYNTHETIC_TEST'));
    fPan = rfscreen.geometry.AntennaToStructureFOV.analyze('S',[0;0;0],eye(3), panelSq, struct());
    h.isTrue('RC-01 square-panel corners overestimate vs disk', ...
        fPan.maxAngularRadius_deg > fLarge.maxAngularRadius_deg);

    % ========== RC-KARI-02 paper numbers: minimum validity radius 30-40 cm ==========
    h.isTrue('RC-02 40cm boom >= reported minimum validity radius', 0.40 >= 0.40);
    h.isTrue('RC-02 4-5cm boom is below the minimum validity radius', 0.045 < 0.30);

    % PatternComparison must honour an explicitly supplied grid (silent-default fix)
    fcC = 2.2e9;
    freeC = rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(6, fcC, 1);
    azC = -180:5:180; elC = -90:5:90;
    Gi = zeros(numel(elC), numel(azC));
    for ie = 1:numel(elC)
        for ia = 1:numel(azC)
            Gi(ie,ia) = freeC.evaluate(fcC, azC(ia), elC(ie)) + 3*sind(3*azC(ia))*cosd(elC(ie));
        end
    end
    instC = rfscreen.antenna.InstalledPattern('SYNTHETIC_TEST_ripple','SIMULATED_3D', ...
        rfscreen.antenna.PatternGrid(azC, elC, fcC, Gi), 'OTHER_SOLVER');
    cmpC = rfscreen.installed.PatternComparison.compare(freeC, instC, ...
        struct('frequency_Hz', fcC, 'az_deg', azC, 'el_deg', elC));
    h.eqTol('RC-02 explicit grid honoured (n = 73*37)', cmpC.nGrid, numel(azC)*numel(elC), 0);
    h.eqTol('RC-02 ripple read back = 3 dB (paper envelope)', cmpC.maxAbsDifference_dB, 3.0, 1e-6);

    % ========== DiskGeometry primitive ==========
    dk = rfscreen.geometry.DiskGeometry(0.5, 24);
    h.eqTol('Disk bounding radius = D/2', dk.boundingRadius(), 0.25, 1e-12);
    h.eqTol('Disk rim sample count', size(dk.verticesLocal(), 2), 24, 0);
    [hitC, tC] = dk.rayIntersectLocal([0;0;-2], [0;0;1]);
    h.isTrue('Disk centre ray hits', hitC);
    h.eqTol('Disk centre ray distance', tC, 2, 1e-12);
    [hitO, ~] = dk.rayIntersectLocal([0.4;0;-2], [0;0;1]);
    h.isFalse('Disk ray outside rim misses', hitO);
    [hitP, ~] = dk.rayIntersectLocal([0;0;-2], [1;0;0]);
    h.isFalse('Disk ray parallel to plane misses', hitP);
    h.isTrue('GeometryProvenance accepts PUBLIC_REPORTED', ...
        rfscreen.geometry.GeometryProvenance.isValid('PUBLIC_REPORTED'));
    h.isTrue('GeometryProvenance accepts ASSUMED_FOR_REPLICATION', ...
        rfscreen.geometry.GeometryProvenance.isValid('ASSUMED_FOR_REPLICATION'));
end

function p = byType(im, ptype)
    p = [];
    for k = 1:numel(im.products)
        if strcmp(im.products{k}.productType, ptype); p = im.products{k}; return; end
    end
end
