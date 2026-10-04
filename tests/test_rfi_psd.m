function test_rfi_psd(h)
%TEST_RFI_PSD Victim-band unwanted-emission PSD path vs fundamental OOB blocker path.
    h.setGroup('rfi_psd');
    repo = fileparts(fileparts(mfilename('fullpath')));
    P = rfscreen.psd.PsdMath; E = @rfscreen.psd.EmissionSpec; V = rfscreen.psd.VictimBandPsdPath;
    C = rfscreen.psd.VictimBandCoupling; O = rfscreen.psd.OobBlockerPath; RB = rfscreen.psd.ReceiverBaseline;
    noChain = struct('filter_dB', NaN, 'post_dB', NaN);

    % ---- dBc/Hz -> dBm/Hz ----
    s = E('S_TM_TX', 'ANTENNA_PORT', 2.25e9, 'L1', 1.57542e9, 'BROADBAND_PSD', -150, 'dBc/Hz', NaN, 'UNKNOWN', 'SYNTHETIC_TEST');
    h.eqTol('dBc/Hz + carrier dBm -> dBm/Hz', s.psdDbmHz(36.9897), -113.0103, 1e-9);
    s2 = E('S_TM_TX', 'ANTENNA_PORT', 2.25e9, 'L1', 1.57542e9, 'BROADBAND_PSD', -113, 'dBm/Hz', NaN, 'UNKNOWN', 'SYNTHETIC_TEST');
    h.eqTol('dBm/Hz passes unchanged (carrier ignored)', s2.psdDbmHz(99), -113, 0);

    % ---- 60 dB TX filter lowers the PSD by 60 dB ----
    h.eqTol('60 dB filter -> PSD - 60 dB', P.victimPortPsd(-100, 60, 0), -160, 0);
    h.eqTol('filter + coupling', P.victimPortPsd(-100, 60, -40), -200, 0);
    h.throws('negative attenuation refused', @() P.applyAttenuation(-100, -3), 'rfscreen:psd:negativeAttenuation');

    % ---- reference cross-check: -120 dBm/Hz, 60 dB filter -> -180 dBm/Hz vs GPS -178 ----
    ref = {E('REF_S_TX', 'FILTER_INPUT', 2.25e9, 'L1', 1.57542e9, 'BROADBAND_PSD', -120, 'dBm/Hz', NaN, 'PRE_FILTER', 'REFERENCE_CROSSCHECK')};
    after = V.evaluate(1.57542e9, 0, -178, ref, NaN, struct('filter_dB', 60, 'post_dB', 0));
    h.eqTol('reference after filter = -180 dBm/Hz', after.port_psd_dBmHz, -180, 1e-12);
    h.eqTol('reference after filter margin +2 dB', after.margin_dB, 2, 1e-12);
    h.eqStr('reference after filter PASS', after.status{1}, 'PASS');
    before = V.evaluate(1.57542e9, 0, -178, ref, NaN, struct('filter_dB', 0, 'post_dB', 0));
    h.eqTol('reference before filter margin -58 dB', before.margin_dB, -58, 1e-12);
    h.eqStr('reference before filter FAIL', before.status{1}, 'FAIL');
    h.eqTol('required PSD suppression before filter = 58 dB', before.required_psd_suppression_dB, 58, 1e-12);

    % ---- receiver criteria ----
    B = RB.read(fullfile(repo, 'data', 'rfi_psd', 'receiver_baseline.csv'));
    for g = {'GPS_L1_RX', 'GPS_L2_RX', 'GPS_L5_RX'}
        b = RB.lookup(B, g{1});
        h.eqTol([g{1} ' noise PSD -172 dBm/Hz'], b.noise_psd_dBmHz, -172, 0);
        h.eqTol([g{1} ' allowable PSD -178 dBm/Hz'], b.allowable_psd_dBmHz, -178, 0);
        h.eqTol([g{1} ' desired signal reference -130 dBm (separate field)'], b.desired_signal_reference_dbm, -130, 0);
        h.isTrue([g{1} ' desired reference is not the interference threshold'], b.desired_signal_reference_dbm ~= b.allowable_psd_dBmHz);
    end
    st = RB.lookup(B, 'S_TC_RX');
    h.eqTol('S-TC noise PSD -171 dBm/Hz', st.noise_psd_dBmHz, -171, 0);
    h.eqTol('S-TC allowable PSD -177 dBm/Hz', st.allowable_psd_dBmHz, -177, 0);

    % ---- whole tuning band sweep / integration BW kept separate ----
    f = RB.tuningSweep(st, 21);
    h.eqTol('S-TC sweep spans 2025-2110 MHz', [f(1) f(end)], [2025e6 2110e6], 1e-3);
    flat = {E('X', 'ANTENNA_PORT', 2.25e9, 'S_TC', 2025e6, 'BROADBAND_PSD', -170, 'dBm/Hz', NaN, 'UNKNOWN', 'SYNTHETIC_TEST'), ...
            E('X', 'ANTENNA_PORT', 2.25e9, 'S_TC', 2110e6, 'BROADBAND_PSD', -190, 'dBm/Hz', NaN, 'UNKNOWN', 'SYNTHETIC_TEST')};
    sw = V.evaluate(f, zeros(1, 21), st.allowable_psd_dBmHz, flat, NaN, noChain);
    h.eqTol('sweep: one verdict per frequency', numel(sw.status), 21, 0);
    h.isTrue('sweep: mask compliance is frequency dependent', any(strcmp(sw.status, 'FAIL')) && any(strcmp(sw.status, 'PASS')));
    h.eqTol('S-TC integration BW 5529.6 Hz (4096 bps x 1.35)', st.integration_bw_Hz, 5529.6, 1e-9);
    h.isTrue('integration BW is not the tuning range', st.integration_bw_Hz < 1e-3 * (st.tuning_hi_Hz - st.tuning_lo_Hz));
    [fc, H2] = RB.channelSamples(st, 101);
    h.eqTol('channel width = integration BW', fc(end) - fc(1), st.integration_bw_Hz, 1e-6);
    h.isTrue('channel inside the tuning band', fc(1) >= st.tuning_lo_Hz && fc(end) <= st.tuning_hi_Hz);
    h.eqTol('flat -180 dBm/Hz integrated over 5529.6 Hz', P.integrate(fc, -180 * ones(size(fc)), H2), -180 + 10 * log10(5529.6), 1e-9);
    h.eqTol('allowable integrated power (2nd stage)', st.allowable_integrated_dBm, -177 + 10 * log10(5529.6), 1e-12);

    % ---- OOB blocker path and PSD path are separate ----
    ob = O.evaluate(-21.3, NaN, NaN);
    h.eqStr('blocker without receiver data', ob.status, 'PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN');
    h.isFalse('blocker result carries no PSD', isfield(ob, 'port_psd_dBmHz'));
    h.isFalse('PSD result carries no blocker power', isfield(after, 'blocker_port_dBm'));
    h.isFalse('path ids differ', strcmp(O.PATH, V.PATH));
    ob2 = O.evaluate(-21.3, 60, -50);
    h.eqTol('blocker post-filter = port - rejection', ob2.post_filter_dBm, -81.3, 1e-12);
    h.eqStr('blocker with receiver data judged', ob2.status, 'PASS');
    h.eqStr('blocker missing port power', O.evaluate(NaN, 60, -50).status, 'INPUT_MISSING');
    h.eqTol('screening suppression is only the diagnostic difference', O.screeningSuppression(-21.32, -104.87), 83.55, 1e-12);
    nm = V.evaluate(1.57542e9, -60, -178, {}, 36.99, noChain);
    h.eqStr('no mask -> coupling evaluated, PSD not', nm.status{1}, V.ST_MISSING);
    h.isNaNval('no mask -> no victim PSD', nm.port_psd_dBmHz);
    h.eqTol('derived emission limit at TX antenna port', nm.max_tx_psd_at_antenna_port_dBmHz, -118, 1e-12);

    % ---- reference planes: no double application ----
    ap = {E('X', 'ANTENNA_PORT', 2.25e9, 'L1', 1.57542e9, 'BROADBAND_PSD', -120, 'dBm/Hz', NaN, 'POST_FILTER', 'SYNTHETIC_TEST')};
    r = V.evaluate(1.57542e9, -50, -178, ap, NaN, struct('filter_dB', 60, 'post_dB', 2));
    h.eqTol('ANTENNA_PORT: no upstream loss re-applied', r.port_psd_dBmHz, -170, 1e-12);
    fo = {E('X', 'FILTER_OUTPUT', 2.25e9, 'L1', 1.57542e9, 'BROADBAND_PSD', -120, 'dBm/Hz', NaN, 'POST_FILTER', 'SYNTHETIC_TEST')};
    r = V.evaluate(1.57542e9, -50, -178, fo, NaN, struct('filter_dB', 60, 'post_dB', 2));
    h.eqTol('FILTER_OUTPUT: only post-filter loss', r.port_psd_dBmHz, -172, 1e-12);
    pa = {E('X', 'PA_OUTPUT', 2.25e9, 'L1', 1.57542e9, 'BROADBAND_PSD', -120, 'dBm/Hz', NaN, 'PRE_FILTER', 'SYNTHETIC_TEST')};
    r = V.evaluate(1.57542e9, -50, -178, pa, NaN, struct('filter_dB', 60, 'post_dB', 2));
    h.eqTol('PA_OUTPUT: filter + post loss', r.port_psd_dBmHz, -232, 1e-12);
    r = V.evaluate(1.57542e9, -50, -178, pa, NaN, noChain);
    h.eqStr('PA_OUTPUT with unknown chain -> TX_CHAIN_LOSS_MISSING', r.status{1}, V.ST_CHAIN);
    ei = {E('X', 'RADIATED_EIRP_PSD', 2.25e9, 'L1', 1.57542e9, 'BROADBAND_PSD', -120, 'dBm/Hz', NaN, 'POST_FILTER', 'SYNTHETIC_TEST')};
    h.throws('EIRP PSD refused on the G_tx route', @() V.evaluate(1.57542e9, -50, -178, ei, NaN, noChain), 'rfscreen:psd:eirpNeedsRxOnlyCoupling');
    re = V.evaluateEirp(1.57542e9, -45, -178, ei);
    h.eqTol('EIRP PSD + (G_rx - FSPL), no TX gain', re.port_psd_dBmHz, -165, 1e-12);
    h.throws('EIRP with S21 refused', @() C.s21Route(-60, false), 'rfscreen:psd:eirpWithS21');
    s21 = C.s21Route(-60, true);
    h.eqTol('S21 route: coupling = S21 only', s21.coupling_dB, -60, 0);
    h.isTrue('S21 route: no G_tx/G_rx/FSPL added', isnan(s21.gtx_dBi) && isnan(s21.grx_dBi) && isnan(s21.fspl_dB));
    h.throws('mixed reference planes refused', @() V.evaluate(1.57542e9, -50, -178, [ap fo], NaN, noChain), 'rfscreen:psd:mixedPlanes');

    % ---- CST victim-band responses are used ----
    prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));
    BR = @(fam, band) rfscreen.psd.BandResponse.fromRepository(repo, fam, band, prov);
    sL1 = BR('S', 'L1'); lL1 = BR('L', 'L1'); iL1 = BR('ISL', 'L1'); iST = BR('ISL', 'S_TC'); sST = BR('S', 'S_TC');
    for rr = {sL1, lL1, iL1, iST, sST}
        h.eqStr(sprintf('%s @ %s CST response available', rr{1}.family, rr{1}.band), rr{1}.status, 'AVAILABLE');
    end
    h.eqStr('S @ L2 normalization unreliable -> not used', BR('S', 'L2').status, 'INPUT_UNRELIABLE');
    h.eqStr('L @ ISL band missing (mesh limit)', BR('L', 'ISL').status, 'INPUT_MISSING');
    c = C.patternRoute(sL1, lL1, 'L1', 1.57542e9, [0; 0; 1], [0; 0; 1], 2);
    h.eqTol('C_EM = Gtx(f_v) + Grx(f_v) - FSPL(f_v)', c.coupling_dB, sL1.gainAt('L1', 1.57542e9, [0; 0; 1]) + ...
        lL1.gainAt('L1', 1.57542e9, [0; 0; 1]) - P.fspl(1.57542e9, 2), 1e-12);
    h.eqTol('C_EM uses the victim frequency FSPL', c.fspl_dB, 20 * log10(4 * pi * 2 * 1.57542e9 / 299792458), 1e-12);

    % ---- attacker-band pattern never re-used on the victim-band path ----
    sTM = BR('S', 'S_TM');
    h.throws('S_TM (attacker band) pattern refused for the L1 victim band', ...
        @() C.patternRoute(sTM, lL1, 'L1', 1.57542e9, [0; 0; 1], [0; 0; 1], 2), 'rfscreen:psd:wrongBandResponse');
    h.throws('victim response of another band refused', @() lL1.gainAt('L2', 1.2276e9, [0; 0; 1]), 'rfscreen:psd:wrongBandResponse');
    h.throws('no extrapolation outside computed monitors', @() lL1.gainAt('L1', 1.60e9, [0; 0; 1]), 'rfscreen:psd:outsideComputedBand');
    h.throws('missing response refused', @() BR('L', 'ISL').gainAt('ISL', 10.6e9, [0; 0; 1]), 'rfscreen:psd:responseMissing');

    % ---- discrete spur vs broadband PSD units ----
    h.throws('spur in dBm/Hz refused', @() E('X', 'ANTENNA_PORT', 2.25e9, 'L1', 1.5e9, 'DISCRETE_SPUR', -80, 'dBm/Hz', 1e3, 'UNKNOWN', 'T'), 'rfscreen:psd:unitTypeMismatch');
    h.throws('broadband in dBc refused', @() E('X', 'ANTENNA_PORT', 2.25e9, 'L1', 1.5e9, 'BROADBAND_PSD', -80, 'dBc', NaN, 'UNKNOWN', 'T'), 'rfscreen:psd:unitTypeMismatch');
    h.throws('spur without RBW refused', @() E('X', 'ANTENNA_PORT', 2.25e9, 'L1', 1.5e9, 'DISCRETE_SPUR', -80, 'dBc', NaN, 'UNKNOWN', 'T'), 'rfscreen:psd:spurRbw');
    sp = E('X', 'ANTENNA_PORT', 2.25e9, 'L1', 1.5e9, 'DISCRETE_SPUR', -70, 'dBc', 1e3, 'UNKNOWN', 'SYNTHETIC_TEST');
    h.throws('spur has no PSD', @() sp.psdDbmHz(30), 'rfscreen:psd:notAPsd');
    h.throws('broadband has no discrete power', @() s.powerDbm(30), 'rfscreen:psd:notAPower');
    h.throws('spur not evaluated on the PSD mask', @() V.evaluate(1.5e9, 0, -178, {sp}, 30, noChain), 'rfscreen:psd:notAPsd');
    h.eqTol('spur port power [dBm]', V.spurPortPower(sp, 30, noChain, -50), -90, 1e-12);
    hm = E('X', 'FILTER_OUTPUT', 2.25e9, 'L1', 4.5e9, 'HARMONIC', -60, 'dBm', NaN, 'POST_FILTER', 'SYNTHETIC_TEST');
    h.eqTol('harmonic [dBm] after post-filter loss', V.spurPortPower(hm, 30, struct('filter_dB', 40, 'post_dB', 1), -50), -111, 1e-12);

    % ---- mission emission table: present, empty, nothing defaulted ----
    S = rfscreen.psd.EmissionMaskTable.read(fullfile(repo, 'data', 'rfi_psd', 'tx_emission_masks.csv'));
    h.isTrue('tx_emission_masks.csv has no fabricated mission mask', isempty(S));
end
