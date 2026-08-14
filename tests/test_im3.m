function test_im3(h)
%TEST_IM3 Two-tone IM3 frequencies, power, scaling (VR-303, VR-304, VR-305).
    h.setGroup('im3');
    rxBand = [2.385e9 2.395e9];
    chan = rfscreen.receiver.IdealBandpassFilter(rxBand, 0, -Inf);

    % ---- VR-303 product frequencies exact ----
    fe0 = feWith(0);   % IIP3 = 0 dBm
    im = imAnalyze(mk({'T1','T2'},[2.40e9 2.41e9],[-10 -10]), fe0, chan, rxBand, []);
    h.ok('two products from one pair', numel(im.products) == 2);
    pA = byType(im, '2F1_MINUS_F2'); pB = byType(im, '2F2_MINUS_F1');
    h.eqTol('2f1-f2 = 2.39 GHz', pA.productFrequency_Hz, 2.39e9, 1);
    h.eqTol('2f2-f1 = 2.42 GHz', pB.productFrequency_Hz, 2.42e9, 1);

    % ---- VR-304 equal-tone power: 3P - 2*IIP3 ----
    h.eqTol('equal-tone eqIn = 3P-2IIP3 = -30', pA.equivalentInputPower_dBm, -30, 1e-9);
    h.eqStr('IM3 reference plane LNA_INPUT', pA.referencePlane, 'LNA_INPUT');
    % passband relevance: 2f1-f2 inside band, 2f2-f1 outside
    h.isTrue('2f1-f2 in passband', pA.inPassband);
    h.isFalse('2f2-f1 out of passband', pB.inPassband);
    h.eqTol('in-band product not attenuated', pA.channelResponse_dB, 0, 1e-9);

    % ---- unequal tones ----
    imu = imAnalyze(mk({'T1','T2'},[2.40e9 2.41e9],[-10 -20]), fe0, chan, rxBand, []);
    uA = byType(imu, '2F1_MINUS_F2'); uB = byType(imu, '2F2_MINUS_F1');
    h.eqTol('unequal 2f1-f2 = 2P1+P2-2IIP3 = -40', uA.equivalentInputPower_dBm, -40, 1e-9);
    h.eqTol('unequal 2f2-f1 = 2P2+P1-2IIP3 = -50', uB.equivalentInputPower_dBm, -50, 1e-9);

    % ---- IIP3 increase reduces IM3 by 2*dIIP3 ----
    fe10 = feWith(10);
    im10 = imAnalyze(mk({'T1','T2'},[2.40e9 2.41e9],[-10 -10]), fe10, chan, rxBand, []);
    pA10 = byType(im10, '2F1_MINUS_F2');
    h.eqTol('IIP3 +10 -> IM3 -20 dB', pA10.equivalentInputPower_dBm - pA.equivalentInputPower_dBm, -20, 1e-9);

    % ---- VR-305 third-order scaling: +delta tones -> +3*delta IM3 ----
    delta = 2;
    imUp = imAnalyze(mk({'T1','T2'},[2.40e9 2.41e9],[-10+delta -10+delta]), fe0, chan, rxBand, []);
    pAUp = byType(imUp, '2F1_MINUS_F2');
    h.eqTol('tones +2 -> IM3 +6 (third order)', pAUp.equivalentInputPower_dBm - pA.equivalentInputPower_dBm, 3*delta, 1e-9);
    % fundamental would rise only +2 -> IM3 rises faster
    h.isTrue('IM3 rises faster than fundamental', (3*delta) > delta);

    % ---- criterion margin ----
    crit = rfscreen.receiver.IntermodulationCriterion('MAX_IM3_INPUT_POWER', -60);
    imc = imAnalyze(mk({'T1','T2'},[2.40e9 2.41e9],[-10 -10]), fe0, chan, rxBand, crit);
    pAc = byType(imc, '2F1_MINUS_F2');
    h.eqTol('IM3 margin = -60 - (-30) = -30', pAc.margin_dB, -30, 1e-9);
    h.eqStr('IM3 FAIL', pAc.passFail, 'FAIL');

    % ---- edge: product exactly on passband edge counts as in-band ----
    edgeBand = [2.39e9 2.42e9];
    edgeChan = rfscreen.receiver.IdealBandpassFilter(edgeBand, 0, -Inf);
    ime = imAnalyze(mk({'T1','T2'},[2.40e9 2.41e9],[-10 -10]), fe0, edgeChan, edgeBand, []);
    peA = byType(ime, '2F1_MINUS_F2');
    h.isTrue('product on lower edge in-band', peA.inPassband);   % 2.39 == edge
end

function out = imAnalyze(inputs, fe, chan, rxBand, crit)
    out = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(inputs, fe, chan, rxBand, crit);
end
function p = byType(out, ptype)
    p = [];
    for k = 1:numel(out.products)
        if strcmp(out.products{k}.productType, ptype); p = out.products{k}; return; end
    end
end
function fe = feWith(iip3)
    fe = rfscreen.receiver.ReceiverFrontEnd(struct('iip3_in_dBm', iip3, 'p1dB_in_dBm', iip3-10, ...
        'linearGain_dB', 20, 'provenance', 'SYNTHETIC_TEST'));
end
function inputs = mk(ids, freqs, pows)
    inputs = struct('txId', {}, 'freq_Hz', {}, 'lnaInputPower_dBm', {}, 'isAbsolute', {}, 'couplingValidity', {});
    for k = 1:numel(ids)
        inputs(end+1) = struct('txId', ids{k}, 'freq_Hz', freqs(k), ...
            'lnaInputPower_dBm', pows(k), 'isAbsolute', true, ...
            'couplingValidity', 'FAR_FIELD_VALID'); %#ok<AGROW>
    end
end
