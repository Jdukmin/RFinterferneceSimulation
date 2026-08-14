function test_susceptibility_validity(h)
%TEST_SUSCEPTIBILITY_VALIDITY No absolute metric without sufficient evidence (VR-209).
    h.setGroup('susc_validity');
    Anlz = @(req) rfscreen.receiver.ReceiverSusceptibilityAnalyzer.analyze(req);

    spec = rfscreen.spectrum.RectangularSpectrum(2.2e9, 20e6, 30, struct());
    filt = rfscreen.receiver.IdealBandpassFilter([2.18e9 2.22e9], 0, -Inf);
    noise = rfscreen.receiver.ReceiverNoiseModel(struct('noiseFigure_dB', 3));
    crit = rfscreen.receiver.InterferenceCriterion('I_N_MAX', -6);

    absSpatial = struct('txGain_dBi',0,'rxGain_dBi',0,'txPower_dBm',30, ...
        'absoluteTransfer_dB',-60,'isAbsolute',true,'couplingValidity','FAR_FIELD_VALID');
    poSpatial = struct('txGain_dBi',0,'rxGain_dBi',0,'txPower_dBm',30, ...
        'absoluteTransfer_dB',NaN,'isAbsolute',false,'couplingValidity','PATTERN_ONLY');

    % ---- 1. full absolute ----
    r = Anlz(struct('spatial',absSpatial,'txSpectrum',spec,'rxFilter',filt,'noiseModel',noise,'criterion',crit));
    h.eqStr('full mode', r.mode, 'ABSOLUTE_LINEAR');
    h.eqStr('full validity', r.validity, 'VALID_ABSOLUTE');
    h.eqTol('full P_I = -30 dBm', r.interferencePower_dBm, -30, 1e-9);   % 30 - 60 + 0
    h.isTrue('full N finite', isfinite(r.noisePower_dBm));
    h.isTrue('full I/N finite', isfinite(r.iOverN_dB));
    h.isTrue('full margin finite', isfinite(r.margin_dB));
    h.eqStr('full reference plane', r.referencePlane, 'RECEIVER_RF_INPUT');

    % ---- 2. pattern-only: no absolute power (the central rule) ----
    rpo = Anlz(struct('spatial',poSpatial,'txSpectrum',spec,'rxFilter',filt,'noiseModel',noise,'criterion',crit));
    h.eqStr('pattern-only mode', rpo.mode, 'RELATIVE_SCREENING');
    h.eqStr('pattern-only validity', rpo.validity, 'ABSOLUTE_COUPLING_UNAVAILABLE');
    h.isNaNval('pattern-only P_I unavailable', rpo.interferencePower_dBm);
    h.isNaNval('pattern-only I/N unavailable', rpo.iOverN_dB);
    h.isNaNval('pattern-only margin unavailable', rpo.margin_dB);
    h.isTrue('pattern-only spectral fraction still computed', isfinite(rpo.spectralOverlapFraction));

    % ---- 3. absolute, missing noise -> no I/N ----
    rN = Anlz(struct('spatial',absSpatial,'txSpectrum',spec,'rxFilter',filt,'noiseModel',[],'criterion',crit));
    h.eqStr('missing noise mode still absolute', rN.mode, 'ABSOLUTE_LINEAR');
    h.isTrue('missing noise P_I still finite', isfinite(rN.interferencePower_dBm));
    h.isNaNval('missing noise -> N NaN', rN.noisePower_dBm);
    h.isNaNval('missing noise -> I/N NaN', rN.iOverN_dB);
    h.eqStr('missing noise validity', rN.validity, 'NOISE_MODEL_INCOMPLETE');

    % ---- 4. absolute + noise, missing criterion -> no PASS/FAIL ----
    rC = Anlz(struct('spatial',absSpatial,'txSpectrum',spec,'rxFilter',filt,'noiseModel',noise,'criterion',[]));
    h.isNaNval('missing criterion -> margin NaN', rC.margin_dB);
    h.eqStr('missing criterion passFail UNKNOWN', rC.passFail, 'UNKNOWN');
    h.eqStr('missing criterion validity', rC.validity, 'MISSING_CRITERION');

    % ---- 5. missing filter -> degraded, no spectral coupling ----
    rF = Anlz(struct('spatial',absSpatial,'txSpectrum',spec,'rxFilter',[],'noiseModel',noise,'criterion',crit));
    h.eqStr('missing filter mode relative', rF.mode, 'RELATIVE_SCREENING');
    h.eqStr('missing filter validity', rF.validity, 'MISSING_FILTER');
    h.isNaNval('missing filter -> P_I NaN', rF.interferencePower_dBm);

    % ---- 6. missing spectrum ----
    rS = Anlz(struct('spatial',absSpatial,'txSpectrum',[],'rxFilter',filt,'noiseModel',noise,'criterion',crit));
    h.eqStr('missing spectrum validity', rS.validity, 'MISSING_SPECTRUM');
    h.isNaNval('missing spectrum P_I NaN', rS.interferencePower_dBm);
end
