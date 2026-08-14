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
    f1 = 1.60e9; f2 = 1.625e9;                     % chosen so 2f1-f2 = 1.575 GHz (GNSS L1)
    inputs = struct('txId', {'I1','I2'}, 'freq_Hz', {f1, f2}, ...
        'lnaInputPower_dBm', {-30, -30}, 'isAbsolute', {true, true}, ...
        'couplingValidity', {'FAR_FIELD_VALID','FAR_FIELD_VALID'});
    gnssBand = [1.56e9 1.59e9];                    % ~ GNSS L1 band
    chan = rfscreen.receiver.IdealBandpassFilter(gnssBand, 0, -Inf);
    im = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(inputs, fe, chan, gnssBand, []);
    pLow = byType(im, '2F1_MINUS_F2');
    h.eqTol('RC-RF-01 IM3 2f1-f2 = 1.575 GHz', pLow.productFrequency_Hz, 1.575e9, 1);
    h.isTrue('RC-RF-01 IM3 lands in GNSS band', pLow.inPassband);
    pHigh = byType(im, '2F2_MINUS_F1');
    h.eqTol('RC-RF-01 IM3 2f2-f1 = 1.65 GHz', pHigh.productFrequency_Hz, 1.65e9, 1);
    h.isFalse('RC-RF-01 upper IM3 outside GNSS band', pHigh.inPassband);

    % ================= Promoted RC invariant: structure FOV occupancy (RC-KARI-01) ===
    p = rfscreen.antenna.SyntheticPatternFactory.mainSideBack(15, -10, -30, 2.2e9, 15);
    stBoresight = rfscreen.geometry.SpacecraftStructure('S','s','SOLAR_ARRAY', ...
        rfscreen.geometry.BoxGeometry([1;1;1]), eye(3), [10;0;0], struct('provenance','SYNTHETIC_TEST'));
    fovB = rfscreen.geometry.AntennaToStructureFOV.analyze('A',[0;0;0],eye(3), stBoresight, ...
        struct('pattern', p, 'frequency_Hz', 2.2e9));
    h.isTrue('RC-01 boresight structure occupies MAIN', fovB.occupies('MAIN'));
    h.isTrue('RC-01 boresight structure centre-ray hits', fovB.centerRayHits);
    h.eqTol('RC-01 boresight centre off-boresight = 0', fovB.centerOffBoresight_deg, 0, 1e-6);
end

function p = byType(im, ptype)
    p = [];
    for k = 1:numel(im.products)
        if strcmp(im.products{k}.productType, ptype); p = im.products{k}; return; end
    end
end
