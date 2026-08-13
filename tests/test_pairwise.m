function test_pairwise(h)
%TEST_PAIRWISE main/side/back lobe combinations + pattern-only coupling
%   semantics (VR-040..043, VR-082).
    h.setGroup('pairwise');
    SP = rfscreen.antenna.SyntheticPatternFactory;
    L  = rfscreen.results.LobeClass;

    mkPr = @(txB, rxB) runPair(SP, txB, rxB);

    % --- VR-040 main-main: TX +X, RX faces -X ---
    pr = mkPr([1;0;0], [-1;0;0]);
    h.eqStr('main-main txLobe', pr.txLobeClass, L.MAIN);
    h.eqStr('main-main rxLobe', pr.rxLobeClass, L.MAIN);
    h.eqTol('main-main DCI', pr.couplingMetric_dB, 20, 1e-9);
    % pattern-only coupling never masquerades as measured S21 (VR-082)
    h.eqStr('coupling type', pr.couplingModelType, 'PATTERN_ONLY');
    h.isFalse('not physical coupling', pr.isPhysicalCoupling);
    h.eqStr('metric name', pr.couplingMetricName, 'DirectionalCouplingIndex_dB');

    % --- VR-041 main-side: RX boresight 30deg off the TX direction ---
    pr = mkPr([1;0;0], [-cosd(30); sind(30); 0]);
    h.eqStr('main-side txLobe', pr.txLobeClass, L.MAIN);
    h.eqStr('main-side rxLobe', pr.rxLobeClass, L.SIDE);
    h.eqTol('main-side DCI', pr.couplingMetric_dB, 0, 1e-9);

    % --- VR-042 side-side: both 30deg off ---
    pr = mkPr([cosd(30); sind(30); 0], [-cosd(30); sind(30); 0]);
    h.eqStr('side-side txLobe', pr.txLobeClass, L.SIDE);
    h.eqStr('side-side rxLobe', pr.rxLobeClass, L.SIDE);
    h.eqTol('side-side DCI', pr.couplingMetric_dB, -20, 1e-9);

    % --- VR-043 back-main: RX boresight +X so TX is behind it ---
    pr = mkPr([1;0;0], [1;0;0]);
    h.eqStr('back-main txLobe', pr.txLobeClass, L.MAIN);
    h.eqStr('back-main rxLobe', pr.rxLobeClass, L.BACK);
    h.eqTol('back-main DCI', pr.couplingMetric_dB, -20, 1e-9);

    % --- out-of-band frequency relation downgrades interference type ---
    prOut = runPairFreq(SP, [1;0;0], [-1;0;0], 2.2e9, 3.5e9);
    h.eqStr('out-of-band freqRel', prOut.frequencyRelation, 'OUT_OF_BAND');
    h.eqStr('out-of-band interfType', prOut.interferenceType, 'NONE');
end

function pr = runPair(SP, txB, rxB)
    pr = runPairFreq(SP, txB, rxB, 2.2e9, 2.2e9);
end

function pr = runPairFreq(SP, txB, rxB, txFc, rxFc)
    pTx = SP.mainSideBack(10, -10, -30, txFc);
    pRx = SP.mainSideBack(10, -10, -30, txFc);
    opts = struct('txBoresight_B', txB, 'txFc_Hz', txFc, 'rxFc_Hz', rxFc, ...
                  'rxThreshold_dBm', -60);
    sc = testutil.Fixtures.twoAntennaScenario(pTx, pRx, [10;0;0], rxB, opts);
    mr = rfscreen.interference.InterferenceAnalyzer.analyze(sc);
    pr = mr.getPair('TX1', 'RX1');
end
