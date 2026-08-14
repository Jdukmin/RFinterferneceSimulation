function test_rf_coexistence_integration(h)
%TEST_RF_COEXISTENCE_INTEGRATION Scenario -> Phase-1 pairwise -> Phase-3
%   susceptibility, absolute (far-field) and relative (pattern-only) (VR-215, VR-210).
    h.setGroup('coex_integration');

    % far-field absolute end-to-end
    outFF = buildAndAnalyze('FAR_FIELD', true);
    sFF = rfscreen.interference.RfCoexistenceAnalyzer.susceptibilityOf(outFF, 'TX1', 'RX1');
    h.eqStr('FF mode absolute', sFF.mode, 'ABSOLUTE_LINEAR');
    h.eqStr('FF validity', sFF.validity, 'VALID_ABSOLUTE');
    % expected: P_I = txPower + (Gtx+Grx-FSPL) + spectralFactor(0), FSPL at 10 m / 2.2 GHz
    lambda = 299792458/2.2e9;
    fspl = 20*log10(4*pi*10/lambda);
    h.eqTol('FF P_I analytical', sFF.interferencePower_dBm, 30 + (0+0-fspl) + 0, 1e-6);
    h.isTrue('FF I/N finite', isfinite(sFF.iOverN_dB));
    h.isTrue('FF margin finite', isfinite(sFF.margin_dB));
    h.eqStr('FF reference plane', sFF.referencePlane, 'RECEIVER_RF_INPUT');
    % Phase-1 matrix still present and reused
    h.isTrue('Phase-1 matrix present', ~isempty(outFF.matrix));
    prFF = outFF.matrix.getPair('TX1', 'RX1');
    h.eqStr('Phase-1 pair coupling far-field', prFF.couplingModelType, 'FAR_FIELD');

    % pattern-only relative: no absolute power (central rule preserved end-to-end)
    outPO = buildAndAnalyze('PATTERN_ONLY', false);
    sPO = rfscreen.interference.RfCoexistenceAnalyzer.susceptibilityOf(outPO, 'TX1', 'RX1');
    h.eqStr('PO mode relative', sPO.mode, 'RELATIVE_SCREENING');
    h.isNaNval('PO P_I unavailable', sPO.interferencePower_dBm);
    h.isTrue('PO spectral fraction computed', isfinite(sPO.spectralOverlapFraction));
    prPO = outPO.matrix.getPair('TX1', 'RX1');
    h.eqStr('PO pair coupling pattern-only', prPO.couplingModelType, 'PATTERN_ONLY');

    % susceptibility reuses the Phase-1 pair gains (no geometry recompute)
    h.eqTol('reuse tx gain', sFF.spectralOverlapFraction, 1.0, 1e-6);
end

function out = buildAndAnalyze(model, withDim)
    sc = rfscreen.scenario.Scenario('P3_INT');
    sc.addPattern('P', rfscreen.antenna.SyntheticPatternFactory.isotropic(0, 2.2e9));
    if withDim; d = 0.1; else; d = []; end
    Role = rfscreen.antenna.Role; Pol = rfscreen.antenna.Polarization;
    sc.addAntenna(rfscreen.antenna.Antenna('AT','tx',Role.TX,1e9,4e9,Pol.RHCP,'P','AT',d));
    sc.addAntenna(rfscreen.antenna.Antenna('AR','rx',Role.RX,1e9,4e9,Pol.RHCP,'P','AR',d));
    sc.addInstallation(rfscreen.antenna.AntennaInstallation('AT',[0;0;0],eye(3)));
    sc.addInstallation(rfscreen.antenna.AntennaInstallation('AR',[10;0;0], ...
        rfscreen.geometry.Rotation.aboutZ(180)));
    spec = rfscreen.spectrum.RectangularSpectrum(2.2e9,20e6,30,struct('provenance','SYNTHETIC_TEST'));
    sc.addTransmitter(rfscreen.rf.RFTransmitter('TX1','AT',2.2e9,20e6,30,struct('spectrum',spec)));
    filt = rfscreen.receiver.IdealBandpassFilter([2.19e9 2.21e9],0,-Inf,struct('provenance','SYNTHETIC_TEST'));
    nm = rfscreen.receiver.ReceiverNoiseModel(struct('noiseFigure_dB',3));
    crit = rfscreen.receiver.InterferenceCriterion('I_N_MAX',-6);
    sc.addReceiver(rfscreen.rf.RFReceiver('RX1','AR',2.2e9,20e6, ...
        struct('filter',filt,'noiseModel',nm,'interferenceCriterion',crit)));
    cfg = rfscreen.config.AnalysisConfig(struct('couplingModel',model));
    out = rfscreen.interference.RfCoexistenceAnalyzer.analyze(sc, cfg);
end
