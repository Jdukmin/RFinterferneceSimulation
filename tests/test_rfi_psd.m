function test_rfi_psd(h)
%TEST_RFI_PSD PRIMARY victim-band PSD path, filter scenarios, source planes, SECONDARY blocker path.
    h.setGroup('rfi_psd');
    repo = fileparts(fileparts(mfilename('fullpath')));
    P = rfscreen.psd.PsdMath; V = rfscreen.psd.VictimBandPsdPath; C = rfscreen.psd.VictimBandCoupling;
    O = rfscreen.psd.OobBlockerPath; RB = rfscreen.psd.ReceiverBaseline; FSc = @rfscreen.psd.FilterScenario;
    A = rfscreen.kaa.CstLocalFrameAdapter;
    flat = @(a) FSc(sprintf('T_%g', a), 'FLAT', [], a, 'SCREENING_FILTER_SCENARIO');
    F0 = flat(0); fL1 = 1.57542e9;

    % ---- source emission specs (units, RBW, planes) ----
    s = spec('S_TM_TX', 'L1', fL1, 'BROADBAND_PSD', -150, 'dBc/Hz', NaN, 'ANTENNA_PORT');
    h.eqTol('dBc/Hz + carrier dBm -> dBm/Hz', s.psdDbmHz(36.9897), -113.0103, 1e-9);
    s4k = spec('S_TM_TX', 'L1', fL1, 'BROADBAND_PSD', -60, 'dBc', 4e3, 'ANTENNA_PORT');
    h.eqTol('dBc per 4 kHz RBW -> dBc/Hz - 36.02', s4k.psdDbmHz(30), 30 - 60 - 10 * log10(4e3), 1e-9);
    h.throws('broadband dBc without RBW refused', @() spec('X', 'L1', fL1, 'BROADBAND_PSD', -60, 'dBc', NaN, 'ANTENNA_PORT'), 'rfscreen:psd:unitTypeMismatch');
    h.throws('spur in dBm/Hz refused', @() spec('X', 'L1', fL1, 'DISCRETE_SPUR', -80, 'dBm/Hz', 1e3, 'ANTENNA_PORT'), 'rfscreen:psd:unitTypeMismatch');
    h.throws('spur without RBW refused', @() spec('X', 'L1', fL1, 'DISCRETE_SPUR', -80, 'dBc', NaN, 'ANTENNA_PORT'), 'rfscreen:psd:spurRbw');
    h.throws('relative EIRP refused', @() spec('X', 'L1', fL1, 'BROADBAND_PSD', -80, 'dBc/Hz', NaN, 'RADIATED_EIRP_PSD'), 'rfscreen:psd:eirpRelative');
    sp = spec('X', 'L1', fL1, 'DISCRETE_SPUR', -70, 'dBc', 1e3, 'ANTENNA_PORT');
    h.throws('spur has no PSD', @() sp.psdDbmHz(30), 'rfscreen:psd:notAPsd');
    h.throws('broadband has no discrete power', @() s.powerDbm(30), 'rfscreen:psd:notAPower');
    h.throws('spur not evaluated on the PSD mask', @() V.evaluate(fL1, 0, 0, -178, {sp}, 30, F0), 'rfscreen:psd:notAPsd');
    h.eqTol('spur port power [dBm] (filter 10 dB, coupling -50 dB)', V.spurPortPower(sp, 30, 10, -50), -100, 1e-12);
    sr = spec('X', 'L1', NaN, 'BROADBAND_PSD', -130, 'dBm/Hz', NaN, 'ANTENNA_PORT', 1563e6, 1588e6);
    h.isTrue('range source covers its band', sr.covers(1570e6) && ~sr.covers(1600e6));

    % ---- filter scenarios (0/40/60/70/80 dB flat; table) ----
    FS = rfscreen.psd.FilterScenario.read(fullfile(repo, 'data', 'rfi_psd', 'filter_scenarios.csv'));
    h.eqTol('default scenarios 0/40/60/70/80 dB', cellfun(@(f) f.atten_dB, FS), [0 40 60 70 80], 0);
    h.isTrue('default scenarios labelled SCREENING_FILTER_SCENARIO', all(cellfun(@(f) strcmp(f.provenance, 'SCREENING_FILTER_SCENARIO'), FS)));
    ref = {spec('REF', 'L1', NaN, 'BROADBAND_PSD', -120, 'dBm/Hz', NaN, 'FILTER_INPUT', 1563e6, 1588e6)};
    out = zeros(1, numel(FS));
    for q = 1:numel(FS)
        R = V.evaluate(fL1, 0, NaN, -178, ref, NaN, FS{q}, 0);
        out(q) = R.port_psd_dBmHz;
        h.eqTol(sprintf('%s: victim PSD drops exactly by the attenuation', FS{q}.id), R.port_psd_dBmHz, -120 - FS{q}.atten_dB, 1e-12);
        h.eqStr(sprintf('%s result carries the scenario id', FS{q}.id), R.filter_id, FS{q}.id);
    end
    R0 = V.evaluate(fL1, 0, NaN, -178, ref, NaN, FS{1}, 0); R60 = V.evaluate(fL1, 0, NaN, -178, ref, NaN, FS{3}, 0);
    h.eqTol('reference: -120 dBm/Hz pre-filter -> margin -58 dB', R0.margin_dB, -58, 1e-12);
    h.eqStr('reference pre-filter FAIL', R0.status{1}, 'FAIL');
    h.eqTol('reference: 60 dB filter -> -180 dBm/Hz', R60.port_psd_dBmHz, -180, 1e-12);
    h.eqTol('reference: +2 dB margin after 60 dB', R60.margin_dB, 2, 1e-12);
    h.eqTol('required additional suppression = max(0, PSD - allowable)', [R0.required_add_supp_dB R60.required_add_supp_dB], [58 0], 1e-12);
    tb = FSc('BPF_TABLE', 'TABLE', [1.5e9 1.6e9], [20 40], 'SYNTHETIC_TEST');
    h.eqTol('table filter interpolates in dB', tb.attenuationAt(1.55e9), 30, 1e-12);
    h.isNaNval('table filter not extrapolated', tb.attenuationAt(1.7e9));
    Rt = V.evaluate(1.7e9, 0, NaN, -178, {spec('REF', 'L1', 1.7e9, 'BROADBAND_PSD', -120, 'dBm/Hz', NaN, 'FILTER_INPUT')}, NaN, tb, 0);
    h.eqStr('outside filter table -> not evaluated', Rt.status{1}, V.ST_FILTER);
    h.throws('negative filter attenuation refused', @() flat(-3), 'rfscreen:psd:negativeAttenuation');

    % ---- allowable TX PSD back-calculation ----
    Rm = V.evaluate([1.57e9 1.58e9], [-80 -82], [-60 -61], -178, {}, 36.99, flat(60));
    h.eqTol('max allowable conducted TX PSD = allowable - C + L_filter', Rm.max_tx_psd_conducted_dBmHz, [-178 + 80 + 60, -178 + 82 + 60], 1e-12);
    h.eqTol('max allowable EIRP PSD = allowable - (G_rx - FSPL) + L_filter', Rm.max_tx_eirp_psd_dBmHz, [-178 + 60 + 60, -178 + 61 + 60], 1e-12);
    h.isTrue('no source -> no PASS/FAIL', all(strcmp(Rm.status, V.ST_SPEC)) && all(isnan(Rm.port_psd_dBmHz)) && all(isnan(Rm.margin_dB)));

    % ---- source planes: radiated EIRP vs conducted ----
    ei = {spec('KA_DLS_TX', 'L1', fL1, 'BROADBAND_PSD', -100, 'dBm/Hz', NaN, 'RADIATED_EIRP_PSD')};
    Re = V.evaluate(fL1, -50, -70, -178, ei, NaN, F0, NaN, true);
    h.eqTol('EIRP PSD: victim = EIRP - FSPL + G_rx (TX gain not re-applied)', Re.port_psd_dBmHz, -170, 1e-12);
    Re2 = V.evaluate(fL1, NaN, -70, -178, ei, NaN, F0, NaN, true);
    h.eqTol('EIRP PSD works without any TX victim-band pattern (Ka)', Re2.port_psd_dBmHz, -170, 1e-12);
    cd_ = {spec('KA_DLS_TX', 'L1', fL1, 'BROADBAND_PSD', -100, 'dBm/Hz', NaN, 'FILTER_OUTPUT')};
    Rc = V.evaluate(fL1, NaN, -70, -178, cd_, NaN, F0, NaN, true);
    h.eqStr('Ka conducted PSD without KAA victim-band response', Rc.status{1}, V.ST_KAA);
    Rc2 = V.evaluate(fL1, -50, -70, -178, cd_, NaN, F0, 3, false);
    h.eqTol('conducted PSD uses G_tx + G_rx - FSPL and post-filter loss', Rc2.port_psd_dBmHz, -100 - 3 - 50, 1e-12);
    Rc3 = V.evaluate(fL1, -50, -70, -178, cd_, NaN, F0, NaN, false);
    h.eqStr('unknown post-filter loss -> 0 dB conservative, flagged', Rc3.post_flag, 'POST_FILTER_LOSS_UNKNOWN_0DB_CONSERVATIVE');
    ap = {spec('X', 'L1', fL1, 'BROADBAND_PSD', -100, 'dBm/Hz', NaN, 'ANTENNA_PORT')};
    h.eqTol('ANTENNA_PORT: no post-filter loss re-applied', V.evaluate(fL1, -50, -70, -178, ap, NaN, F0, 6, false).port_psd_dBmHz, -150, 1e-12);
    h.throws('EIRP with S21 refused', @() C.s21Route(-60, false), 'rfscreen:psd:eirpWithS21');
    h.throws('mixed source planes refused', @() V.evaluate(fL1, -50, -70, -178, [ap ei], NaN, F0), 'rfscreen:psd:mixedPlanes');

    % ---- receiver criteria / tuning vs integration BW ----
    B = RB.read(fullfile(repo, 'data', 'rfi_psd', 'receiver_baseline.csv'));
    for g = {'GPS_L1_RX', 'GPS_L2_RX', 'GPS_L5_RX'}
        b = RB.lookup(B, g{1});
        h.eqTol([g{1} ' allowable PSD -178 dBm/Hz'], b.allowable_psd_dBmHz, -178, 0);
        h.eqTol([g{1} ' desired reference -130 dBm (separate)'], b.desired_signal_reference_dbm, -130, 0);
        h.isTrue([g{1} ' 20.46 MHz integration BW is an assumption'], strncmp(b.integration_bw_prov, 'ASSUMPTION', 10));
    end
    st = RB.lookup(B, 'S_TC_RX');
    h.eqTol('S-TC allowable PSD -177 dBm/Hz', st.allowable_psd_dBmHz, -177, 0);
    h.eqTol('ISL allowable PSD -177 dBm/Hz', RB.lookup(B, 'ISL_X_RX').allowable_psd_dBmHz, -177, 0);
    h.eqTol('S-TC integration BW 5529.6 Hz', st.integration_bw_Hz, 5529.6, 1e-9);
    f = RB.tuningSweep(st, 21);
    h.eqTol('S-TC PSD sweep spans the tuning band 2025-2110 MHz', [f(1) f(end)], [2025e6 2110e6], 1e-3);
    [fc, H2] = RB.channelSamples(st, 101);
    h.eqTol('integration channel = 5529.6 Hz, not the tuning range', fc(end) - fc(1), 5529.6, 1e-6);
    h.eqTol('flat -180 dBm/Hz integrated', P.integrate(fc, -180 * ones(size(fc)), H2), -180 + 10 * log10(5529.6), 1e-9);

    % ---- CST victim-band responses; blocker-band mesh limit does not block the main path ----
    prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));
    BR = @(fam, band) rfscreen.psd.BandResponse.fromRepository(repo, fam, band, prov);
    iL1 = BR('ISL', 'L1'); lL1 = BR('L', 'L1'); lISL = BR('L', 'ISL');
    h.eqStr('GPS antenna @ 10.6 GHz (blocker band) mesh-limited', lISL.status, 'INPUT_MISSING');
    c = C.patternRoute(iL1, lL1, 'L1', fL1, [0; 0; 1], [0; 0; 1], 4);
    h.isTrue('ISL -> GPS victim-band coupling evaluates despite that mesh limit', isfinite(c.coupling_dB));
    h.throws('S_TM (attacker band) pattern refused on the L1 victim path', ...
        @() C.patternRoute(BR('S', 'S_TM'), lL1, 'L1', fL1, [0; 0; 1], [0; 0; 1], 2), 'rfscreen:psd:wrongBandResponse');
    h.throws('victim response of another band refused', @() lL1.gainAt('L2', 1.2276e9, [0; 0; 1]), 'rfscreen:psd:wrongBandResponse');
    h.throws('no extrapolation outside computed monitors', @() lL1.gainAt('L1', 1.60e9, [0; 0; 1]), 'rfscreen:psd:outsideComputedBand');
    h.eqStr('S @ L2 normalization unreliable -> not used', BR('S', 'L2').status, 'INPUT_UNRELIABLE');

    % ---- regression of the key numbers (geometry + CST responses, independent of output files) ----
    m = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
    pos = containers.Map(); R_ = containers.Map();
    for i = 1:numel(m.installationRecords)
        rc = m.installationRecords(i); pn = m.panels(strcmp({m.panels.id}, rc.panelId));
        pos(rc.antennaId) = rc.position_m(:); R_(rc.antennaId) = A.fixedMount(pn.normal_B);
    end
    geo = @(t, r) deal(norm(pos(r) - pos(t)), A.bodyToLocal(R_(t), (pos(r) - pos(t)) / norm(pos(r) - pos(t))), ...
        A.bodyToLocal(R_(r), (pos(t) - pos(r)) / norm(pos(r) - pos(t))));
    [d, dT, dR] = geo('SBA_ZENITH', 'GPSA_1');
    sTM = BR('S', 'S_TM'); lTM = BR('L', 'S_TM');
    blk = 36.9897 + sTM.gainAt('S_TM', 2.25e9, dT) + lTM.gainAt('S_TM', 2.25e9, dR) - P.fspl(2.25e9, d);
    h.eqTol('blocker S-TM@ZENITH -> GPSA_1 = -21.3 dBm', blk, -21.32, 0.05);
    cL1 = arrayfun(@(x) C.patternRoute(BR('S', 'L1'), lL1, 'L1', x, dT, dR, d).coupling_dB, linspace(1563e6, 1588e6, 21));
    h.eqTol('victim-band C_EM S-TM@ZENITH -> GPS L1 ~ -81 dB', [min(cL1) max(cL1)], [-81.38 -80.98], 0.01);
    h.eqTol('max allowable TX PSD S-TM -> GPS L1 ~ -97 dBm/Hz', -178 - max(cL1), -97.02, 0.01);
    [d, dT, dR] = geo('SBA_NADIR', 'SBA_ZENITH');
    blk2 = 36.9897 + sTM.gainAt('S_TM', 2.25e9, dT) + sTM.gainAt('S_TM', 2.25e9, dR) - P.fspl(2.25e9, d);
    h.eqTol('blocker S-TM -> opposite S-TC = -32.3 dBm', blk2, -32.29, 0.05);
    sST = BR('S', 'S_TC');
    cST = arrayfun(@(x) C.patternRoute(sST, sST, 'S_TC', x, dT, dR, d).coupling_dB, linspace(2025e6, 2110e6, 21));
    h.eqTol('victim-band C_EM S-TM -> opposite S-TC -69..-70 dB', [min(cST) max(cST)], [-70.23 -69.09], 0.01);
    h.eqTol('max allowable TX PSD S-TM -> opposite S-TC ~ -108 dBm/Hz', -177 - max(cST), -107.91, 0.01);

    % ---- secondary blocker path ----
    ob = O.evaluate(-21.3, NaN, NaN);
    h.eqStr('blocker without receiver data', ob.status, 'PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN');
    h.eqStr('blocker analysis class is secondary', O.CLASS, 'SECONDARY_OOB_BLOCKER_ANALYSIS');
    h.isFalse('blocker and PSD path ids differ', strcmp(O.PATH, V.PATH));
    h.eqTol('screening suppression = diagnostic difference only', O.screeningSuppression(-21.32, -104.87), 83.55, 1e-12);

    % ---- input tables: mission sources empty (nothing defaulted), reference scenario present ----
    S = rfscreen.psd.EmissionMaskTable.read(fullfile(repo, 'data', 'rfi_psd', 'tx_emission_masks.csv'));
    h.isTrue('tx_emission_masks.csv holds no fabricated mission source', isempty(S));
    [Rf, X] = rfscreen.psd.EmissionMaskTable.read(fullfile(repo, 'data', 'rfi_psd', 'reference_scenarios.csv'));
    h.isTrue('reference scenario is REFERENCE_CROSSCHECK', numel(Rf) >= 1 && strcmp(Rf{1}.assumptionClass, 'REFERENCE_CROSSCHECK') ...
        && isfield(X{1}, 'scenario_id'));
end

function s = spec(tx, band, f, type, level, unit, rbw, plane, flo, fhi)
    if nargin < 9; flo = NaN; fhi = NaN; end
    t = rfscreen.psd.EmissionSpec.blank();
    t.tx_system = tx; t.victim_band = band; t.frequency_hz = f; t.frequency_lo_hz = flo; t.frequency_hi_hz = fhi;
    t.emission_type = type; t.level = level; t.unit = unit; t.reference_bandwidth_hz = rbw; t.reference_plane = plane;
    t.carrier_frequency_hz = 2.25e9; t.filter_state = 'UNKNOWN'; t.standard_or_source = 'SYNTHETIC_TEST';
    t.provenance = 'SYNTHETIC_TEST'; t.assumption_class = 'ENGINEERING_ASSUMPTION';
    s = rfscreen.psd.EmissionSpec(t);
end
