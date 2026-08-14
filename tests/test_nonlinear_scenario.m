function test_nonlinear_scenario(h)
%TEST_NONLINEAR_SCENARIO Scenario-level multi-interferer nonlinear analysis (VR-306).
    h.setGroup('nl_scenario');
    NSA = @(sc, rxId, cfg, opts) rfscreen.nonlinear.NonlinearSusceptibilityAnalyzer.analyze(sc, rxId, cfg, opts);
    cfgFF = rfscreen.config.AnalysisConfig(struct('couplingModel','FAR_FIELD'));
    cfgPO = rfscreen.config.AnalysisConfig(struct('couplingModel','PATTERN_ONLY'));

    % ---- 2 TX -> 1 RX ----
    sc2 = buildScenario({'X1','X2'}, [2.40e9 2.41e9], {}, false);
    r2 = NSA(sc2, 'RX1', cfgFF, struct());
    h.ok('2 interferers', numel(r2.interfererIds) == 2);
    h.eqStr('validity VALID', r2.validity, 'VALID');
    h.isTrue('compression finite', isfinite(r2.compression.compressionMargin_dB));
    h.eqStr('compression plane LNA_INPUT', r2.compression.referencePlane, 'LNA_INPUT');
    h.ok('IM3 products = 1 pair x 2', numel(r2.im3) == 2);
    h.eqStr('IM2 not implemented', r2.im2, 'NOT_IMPLEMENTED');

    % ---- 3 TX -> 1 RX : C(3,2)=3 pairs x 2 products = 6, no self/duplicate ----
    sc3 = buildScenario({'X1','X2','X3'}, [2.40e9 2.41e9 2.42e9], {}, false);
    r3 = NSA(sc3, 'RX1', cfgFF, struct());
    h.ok('3 interferers', numel(r3.interfererIds) == 3);
    h.ok('IM3 products = 3 pairs x 2 = 6', numel(r3.im3) == 6);
    h.isTrue('no self/duplicate IM3 pairs', noDuplicatePairs(r3.im3));

    % ---- inactive TX excluded ----
    scA = buildScenario({'X1','X2','X3'}, [2.40e9 2.41e9 2.42e9], {'X1','X2'}, false);
    rA = NSA(scA, 'RX1', cfgFF, struct());
    h.ok('inactive TX excluded (2 of 3)', numel(rA.interfererIds) == 2);

    % ---- wanted TX excluded ----
    rW = NSA(sc3, 'RX1', cfgFF, struct('wantedTxId','X1'));
    h.ok('wanted TX excluded', numel(rW.interfererIds) == 2);
    h.isFalse('wanted not among interferers', any(strcmp(rW.interfererIds, 'X1')));

    % ---- multiple RX ----
    scM = buildScenario({'X1','X2'}, [2.40e9 2.41e9], {}, true);
    rM1 = NSA(scM, 'RX1', cfgFF, struct());
    rM2 = NSA(scM, 'RX2', cfgFF, struct());
    h.eqStr('RX1 analyzed', rM1.rxId, 'RX1');
    h.eqStr('RX2 analyzed', rM2.rxId, 'RX2');

    % ---- pattern-only -> nonlinear physics withheld end-to-end ----
    rPO = NSA(sc2, 'RX1', cfgPO, struct());
    h.eqStr('pattern-only scenario withheld', rPO.validity, 'ABSOLUTE_COUPLING_UNAVAILABLE');
    h.eqStr('pattern-only compression withheld', rPO.compression.validity, 'ABSOLUTE_COUPLING_UNAVAILABLE');
    h.isTrue('pattern-only no IM3 products', isempty(rPO.im3));
end

function tf = noDuplicatePairs(products)
    seen = {}; tf = true;
    for k = 1:numel(products)
        p = products{k};
        if strcmp(p.txId1, p.txId2); tf = false; return; end   % no self
        key = sprintf('%s|%s', p.txId1, p.txId2);
        rev = sprintf('%s|%s', p.txId2, p.txId1);
        if any(strcmp(seen, rev)); tf = false; return; end       % no reversed duplicate
        seen{end+1} = key; %#ok<AGROW>
    end
end

function sc = buildScenario(txIds, freqs, activeSubset, twoRx)
    sc = rfscreen.scenario.Scenario('NL_SCN');
    sc.addPattern('P', rfscreen.antenna.SyntheticPatternFactory.isotropic(0, 2.41e9));
    Role = rfscreen.antenna.Role; Pol = rfscreen.antenna.Polarization;
    d = 0.1;   % small aperture -> far-field valid at 10 m
    % RX antenna at origin
    sc.addAntenna(rfscreen.antenna.Antenna('AR', 'rx', Role.RX, 1e9, 4e9, Pol.RHCP, 'P', 'AR', d));
    sc.addInstallation(rfscreen.antenna.AntennaInstallation('AR', [0;0;0], eye(3)));
    fe = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm', -5, 'iip3_in_dBm', 0, ...
        'linearGain_dB', 20, 'provenance', 'SYNTHETIC_TEST'));
    ropts = struct('receiverFrontEnd', fe, ...
        'compressionCriterion', rfscreen.receiver.CompressionCriterion(0), ...
        'blockingCriterion', rfscreen.receiver.BlockingCriterion(-40), ...
        'intermodulationCriterion', rfscreen.receiver.IntermodulationCriterion('MAX_IM3_INPUT_POWER', -80));
    sc.addReceiver(rfscreen.rf.RFReceiver('RX1', 'AR', 2.41e9, 20e6, ropts));
    if twoRx
        sc.addAntenna(rfscreen.antenna.Antenna('AR2', 'rx2', Role.RX, 1e9, 4e9, Pol.RHCP, 'P', 'AR2', d));
        sc.addInstallation(rfscreen.antenna.AntennaInstallation('AR2', [0;0;1], eye(3)));
        sc.addReceiver(rfscreen.rf.RFReceiver('RX2', 'AR2', 2.41e9, 20e6, ropts));
    end
    % TX antennas at distance 10 m along varied directions
    dirs = {[10;0;0], [0;10;0], [0;0;10], [10;10;0], [0;10;10]};
    for i = 1:numel(txIds)
        aid = sprintf('AT%d', i);
        sc.addAntenna(rfscreen.antenna.Antenna(aid, aid, Role.TX, 1e9, 4e9, Pol.RHCP, 'P', aid, d));
        sc.addInstallation(rfscreen.antenna.AntennaInstallation(aid, dirs{i}, eye(3)));
        sc.addTransmitter(rfscreen.rf.RFTransmitter(txIds{i}, aid, freqs(i), 20e6, 30));
    end
    if ~isempty(activeSubset)
        sc.activeTxIds = activeSubset;
    end
end
