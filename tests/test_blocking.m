function test_blocking(h)
%TEST_BLOCKING Blocking independent of P1dB and spectral overlap (VR-302).
    h.setGroup('blocking');
    rxCenter = 2.40e9;

    % ---- constant threshold: below / at / above ----
    bc = rfscreen.receiver.BlockingCriterion(-20);
    r1 = blkAnalyze(mk({'A'},[2.40e9],[-30],[true]), rxCenter, bc);
    h.eqTol('below threshold: margin +10', r1.worstMargin_dB, 10, 1e-9);
    h.eqStr('below threshold PASS', r1.entries(1).passFail, 'PASS');

    r2 = blkAnalyze(mk({'A'},[2.40e9],[-20],[true]), rxCenter, bc);
    h.eqTol('at threshold: margin 0', r2.worstMargin_dB, 0, 1e-9);
    h.eqStr('at threshold PASS(boundary)', r2.entries(1).passFail, 'PASS');

    r3 = blkAnalyze(mk({'A'},[2.40e9],[-10],[true]), rxCenter, bc);
    h.eqTol('above threshold: margin -10', r3.worstMargin_dB, -10, 1e-9);
    h.eqStr('above threshold FAIL', r3.entries(1).passFail, 'FAIL');

    % ---- MANDATORY: out-of-band blocker with NO spectral overlap still evaluated ----
    % interferer at 2.5 GHz, RX centered 2.4 GHz -> far out of band, yet blocking assessed
    oob = blkAnalyze(mk({'OOB'},[2.5e9],[-10],[true]), rxCenter, bc);
    h.isTrue('out-of-band blocker evaluated (not skipped)', isfinite(oob.worstMargin_dB));
    h.eqTol('OOB offset = +100 MHz', oob.entries(1).offset_Hz, 100e6, 1e-3);
    h.eqStr('OOB blocking FAIL', oob.entries(1).passFail, 'FAIL');

    % ---- frequency-offset-dependent (tabulated) threshold ----
    spec = struct('offset_Hz', [0 10e6 100e6], 'allowable_dBm', [-40 -20 0]);
    bt = rfscreen.receiver.BlockingCriterion(spec);
    h.eqTol('tab allowable at 10 MHz', bt.allowableFor(10e6), -20, 1e-9);
    h.eqTol('tab interp at 5 MHz', bt.allowableFor(5e6), -30, 1e-9);        % between -40 and -20
    h.eqTol('tab clamp beyond 100 MHz', bt.allowableFor(200e6), 0, 1e-9);
    rt = blkAnalyze(mk({'A'},[2.41e9],[-25],[true]), rxCenter, bt);          % offset 10 MHz, allow -20
    h.eqTol('tabulated margin = -20 - (-25) = +5', rt.worstMargin_dB, 5, 1e-9);

    % ---- missing criterion -> withheld ----
    none = blkAnalyze(mk({'A'},[2.40e9],[-10],[true]), rxCenter, []);
    h.eqStr('no criterion MISSING_BLOCKING_CRITERION', none.validity, 'MISSING_BLOCKING_CRITERION');
    h.isTrue('no criterion -> no entries scored', isempty(none.entries));

    % ---- reference plane ----
    h.eqStr('blocking reference plane LNA_INPUT', r1.referencePlane, 'LNA_INPUT');
end

function res = blkAnalyze(inputs, rxCenter, crit)
    res = rfscreen.nonlinear.BlockingAnalyzer.analyze(inputs, rxCenter, crit);
end
function inputs = mk(ids, freqs, pows, absflags)
    inputs = struct('txId', {}, 'freq_Hz', {}, 'lnaInputPower_dBm', {}, 'isAbsolute', {}, 'couplingValidity', {});
    for k = 1:numel(ids)
        inputs(end+1) = struct('txId', ids{k}, 'freq_Hz', freqs(k), ...
            'lnaInputPower_dBm', pows(k), 'isAbsolute', absflags(k), ...
            'couplingValidity', 'FAR_FIELD_VALID'); %#ok<AGROW>
    end
end
