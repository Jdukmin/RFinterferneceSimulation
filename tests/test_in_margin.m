function test_in_margin(h)
%TEST_IN_MARGIN I/N and margin sign convention (VR-207, VR-208).
    h.setGroup('in_margin');

    % ---- I/N = I_dBm - N_dBm ----
    c = rfscreen.receiver.InterferenceCriterion('I_N_MAX', -6);
    e1 = c.evaluate(-120, -110);
    h.eqTol('I/N (-120,-110) = -10', e1.actual, -10, 1e-12);
    e2 = c.evaluate(-100, -110);
    h.eqTol('I/N (-100,-110) = +10', e2.actual, 10, 1e-12);
    e3 = c.evaluate(-115, -110);
    h.eqTol('I/N (-115,-110) = -5', e3.actual, -5, 1e-12);

    % ---- margin = Allowable - Actual ; >0 PASS (criterion I/N <= -6) ----
    m10 = c.evaluate(-120, -110);   % I/N = -10
    h.eqTol('actual -10 -> margin +4', m10.margin_dB, 4, 1e-12);
    h.eqStr('actual -10 -> PASS', m10.pass, 'PASS');
    m6 = c.evaluate(-116, -110);    % I/N = -6
    h.eqTol('actual -6 -> margin 0', m6.margin_dB, 0, 1e-12);
    h.eqStr('actual -6 -> PASS(boundary)', m6.pass, 'PASS');
    m3 = c.evaluate(-113, -110);    % I/N = -3
    h.eqTol('actual -3 -> margin -3', m3.margin_dB, -3, 1e-12);
    h.eqStr('actual -3 -> FAIL', m3.pass, 'FAIL');

    % ---- MAX_INTERFERENCE_POWER criterion ----
    cp = rfscreen.receiver.InterferenceCriterion('MAX_INTERFERENCE_POWER', -90);
    p1 = cp.evaluate(-100, NaN);
    h.eqTol('P_I -100 vs -90 -> margin +10', p1.margin_dB, 10, 1e-12);
    h.eqStr('P_I -100 PASS', p1.pass, 'PASS');
    p2 = cp.evaluate(-80, NaN);
    h.eqTol('P_I -80 -> margin -10', p2.margin_dB, -10, 1e-12);
    h.eqStr('P_I -80 FAIL', p2.pass, 'FAIL');

    % ---- I/N criterion with missing noise -> UNKNOWN (no fabricated margin) ----
    eU = c.evaluate(-120, NaN);
    h.isNaNval('I/N unknown actual', eU.actual);
    h.isNaNval('I/N unknown margin', eU.margin_dB);
    h.eqStr('I/N unknown pass', eU.pass, 'UNKNOWN');
end
