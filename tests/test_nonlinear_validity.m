function test_nonlinear_validity(h)
%TEST_NONLINEAR_VALIDITY No nonlinear physics without evidence/hardware (VR-307).
    h.setGroup('nl_validity');
    feFull = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm',-5,'iip3_in_dBm',0, ...
        'linearGain_dB',20,'provenance','SYNTHETIC_TEST'));
    rxBand = [2.395e9 2.405e9];
    chan = rfscreen.receiver.IdealBandpassFilter(rxBand,0,-Inf);

    % ---- pattern-only interferers cannot drive compression (central rule) ----
    po = mk({'A','B'},[2.4e9 2.41e9],[NaN NaN],[false false]);
    cpo = rfscreen.nonlinear.CompressionAnalyzer.analyze(po, feFull, []);
    h.eqStr('pattern-only compression withheld', cpo.validity, 'ABSOLUTE_COUPLING_UNAVAILABLE');
    h.isNaNval('pattern-only aggregate NaN', cpo.aggregateInputPower_dBm);
    h.isNaNval('pattern-only margin NaN', cpo.compressionMargin_dB);

    % pattern-only IM3 withheld
    ipo = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(po, feFull, chan, rxBand, []);
    h.eqStr('pattern-only IM3 withheld', ipo.validity, 'ABSOLUTE_COUPLING_UNAVAILABLE');
    h.isTrue('pattern-only IM3 no products', isempty(ipo.products));

    valid2 = mk({'A','B'},[2.4e9 2.41e9],[-10 -10],[true true]);

    % ---- missing P1dB -> MISSING_P1DB ----
    feNoP1 = rfscreen.receiver.ReceiverFrontEnd(struct('iip3_in_dBm',0,'provenance','SYNTHETIC_TEST'));
    cNoP1 = rfscreen.nonlinear.CompressionAnalyzer.analyze(valid2, feNoP1, []);
    h.eqStr('missing P1dB', cNoP1.validity, 'MISSING_P1DB');
    h.isNaNval('missing P1dB margin NaN', cNoP1.compressionMargin_dB);

    % ---- missing IIP3 -> MISSING_IIP3 ----
    feNoIp3 = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm',-5,'provenance','SYNTHETIC_TEST'));
    iNoIp3 = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(valid2, feNoIp3, chan, rxBand, []);
    h.eqStr('missing IIP3', iNoIp3.validity, 'MISSING_IIP3');
    h.isTrue('missing IIP3 no products', isempty(iNoIp3.products));

    % ---- missing front end -> withheld ----
    cNoFE = rfscreen.nonlinear.CompressionAnalyzer.analyze(valid2, [], []);
    h.eqStr('missing front end (compression)', cNoFE.validity, 'MISSING_FRONT_END');
    iNoFE = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(valid2, [], chan, rxBand, []);
    h.eqStr('missing front end (IM3)', iNoFE.validity, 'MISSING_FRONT_END');

    % ---- missing blocking criterion ----
    bNoCrit = rfscreen.nonlinear.BlockingAnalyzer.analyze(valid2, 2.4e9, []);
    h.eqStr('missing blocking criterion', bNoCrit.validity, 'MISSING_BLOCKING_CRITERION');

    % ---- incomplete interferer set: one valid, one pattern-only ----
    mixed = mk({'A','B'},[2.4e9 2.41e9],[-10 NaN],[true false]);
    cMix = rfscreen.nonlinear.CompressionAnalyzer.analyze(mixed, feFull, []);
    h.eqStr('incomplete set flagged', cMix.validity, 'INCOMPLETE_INTERFERER_SET');
    h.eqTol('aggregate uses only valid interferer', cMix.aggregateInputPower_dBm, -10, 1e-9);
    h.ok('nValid=1 of 2', cMix.nValidInterferers == 1 && cMix.nInterferers == 2);

    % IM3 needs >= 2 valid: mixed -> no pairs
    iMix = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(mixed, feFull, chan, rxBand, []);
    h.isTrue('IM3 with <2 valid -> no products', isempty(iMix.products));
end

function inputs = mk(ids, freqs, pows, absflags)
    inputs = struct('txId', {}, 'freq_Hz', {}, 'lnaInputPower_dBm', {}, 'isAbsolute', {}, 'couplingValidity', {});
    for k = 1:numel(ids)
        cv = 'FAR_FIELD_VALID'; if ~absflags(k); cv = 'PATTERN_ONLY'; end
        inputs(end+1) = struct('txId', ids{k}, 'freq_Hz', freqs(k), ...
            'lnaInputPower_dBm', pows(k), 'isAbsolute', absflags(k), 'couplingValidity', cv); %#ok<AGROW>
    end
end
