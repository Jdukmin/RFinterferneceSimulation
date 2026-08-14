function test_compression(h)
%TEST_COMPRESSION Aggregate power + P1dB compression (VR-300, VR-301).
    h.setGroup('compression');
    U = rfscreen.util.Units;

    % ---- VR-300 linear-domain aggregate (dBm never summed directly) ----
    h.eqTol('agg(-10,-10) = -6.99', U.sumPowers_dBm([-10 -10]), -6.98970, 1e-4);
    h.eqTol('agg(-10,-10,-10) = -5.23', U.sumPowers_dBm([-10 -10 -10]), -5.22879, 1e-4);
    h.eqTol('agg(single -10) = -10', U.sumPowers_dBm([-10]), -10, 1e-9);
    h.isTrue('agg not -20 (not dB-summed)', U.sumPowers_dBm([-10 -10]) > -11);

    fe = feWith(-5, 0);   % P1dB_in = -5 dBm, IIP3 = 0

    % ---- VR-301 single interferer below / at / above P1dB ----
    below = compAnalyze(mk({'A'},[2.4e9],[-20],[true]), fe, []);
    h.eqTol('single below: margin +15', below.compressionMargin_dB, 15, 1e-9);
    h.eqStr('single below PASS', below.passFail, 'PASS');

    atP1 = compAnalyze(mk({'A'},[2.4e9],[-5],[true]), fe, []);
    h.eqTol('single at P1dB: margin 0', atP1.compressionMargin_dB, 0, 1e-9);
    h.eqStr('at P1dB PASS(boundary)', atP1.passFail, 'PASS');

    above = compAnalyze(mk({'A'},[2.4e9],[0],[true]), fe, []);
    h.eqTol('single above: margin -5', above.compressionMargin_dB, -5, 1e-9);
    h.eqStr('single above FAIL', above.passFail, 'FAIL');

    % ---- multiple individually below but aggregate above ----
    twoHi = compAnalyze(mk({'A','B'},[2.4e9 2.41e9],[-8 -8],[true true]), fe, []);
    h.eqTol('two -8 aggregate ~ -4.99', twoHi.aggregateInputPower_dBm, -4.98970, 1e-4);
    h.isTrue('aggregate above P1dB -> FAIL', twoHi.compressionMargin_dB < 0);
    h.eqStr('aggregate above FAIL', twoHi.passFail, 'FAIL');

    % ---- multiple aggregate below ----
    twoLo = compAnalyze(mk({'A','B'},[2.4e9 2.41e9],[-10 -10],[true true]), fe, []);
    h.eqTol('two -10 aggregate -6.99', twoLo.aggregateInputPower_dBm, -6.98970, 1e-4);
    h.eqTol('aggregate below: margin +1.99', twoLo.compressionMargin_dB, 1.98970, 1e-4);
    h.eqStr('aggregate below PASS', twoLo.passFail, 'PASS');
    h.eqStr('reference plane LNA_INPUT', twoLo.referencePlane, 'LNA_INPUT');

    % ---- criterion with required backoff ----
    crit = rfscreen.receiver.CompressionCriterion(3);   % require 3 dB backoff
    backoff = compAnalyze(mk({'A','B'},[2.4e9 2.41e9],[-10 -10],[true true]), fe, crit);
    h.eqTol('backoff margin = (P1dB-3)-agg', backoff.compressionMargin_dB, (-5-3) - (-6.98970), 1e-4);
    h.eqStr('backoff FAIL', backoff.passFail, 'FAIL');
end

function res = compAnalyze(inputs, fe, crit)
    res = rfscreen.nonlinear.CompressionAnalyzer.analyze(inputs, fe, crit);
end
function fe = feWith(p1db, iip3)
    fe = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm', p1db, 'iip3_in_dBm', iip3, ...
        'linearGain_dB', 20, 'provenance', 'SYNTHETIC_TEST'));
end
function inputs = mk(ids, freqs, pows, absflags)
    inputs = struct('txId', {}, 'freq_Hz', {}, 'lnaInputPower_dBm', {}, 'isAbsolute', {}, 'couplingValidity', {});
    for k = 1:numel(ids)
        inputs(end+1) = struct('txId', ids{k}, 'freq_Hz', freqs(k), ...
            'lnaInputPower_dBm', pows(k), 'isAbsolute', absflags(k), ...
            'couplingValidity', 'FAR_FIELD_VALID'); %#ok<AGROW>
    end
end
