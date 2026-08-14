function test_installed_environment_integration(h)
%TEST_INSTALLED_ENVIRONMENT_INTEGRATION Evidence around the existing engine (VR-410).
    h.setGroup('installed_env');
    sc = buildScenario();
    cfg = rfscreen.config.AnalysisConfig.default();

    % ---- installed-environment evidence (LOS + FOV + pattern source) ----
    env = rfscreen.interference.InstalledEnvironmentAnalyzer.analyzePair(sc, 'TX1', 'RX1', struct());
    h.eqStr('direct LOS blocked by panel', env.directLOS.status, 'BLOCKED');
    h.ok('one blocking structure', numel(env.directLOS.blockingStructureIds) == 1);
    h.eqStr('RX uses installed pattern', env.rxPatternSourceUsed, 'INSTALLED');
    h.eqStr('TX free-space fallback', env.txPatternSourceUsed, 'FREE_SPACE_FALLBACK');
    h.eqStr('installation effect unknown (TX fallback)', env.installationValidity, 'INSTALLATION_EFFECT_UNKNOWN');
    h.eqStr('geometry risk HIGH (blocked/main)', env.geometryRisk, 'HIGH');
    h.ok('TX structure FOV computed', numel(env.txStructureFOV) == 1);
    h.ok('RX structure FOV computed (symmetric)', numel(env.rxStructureFOV) == 1);

    % ---- installed pattern flows through the EXISTING PairwiseAnalyzer ----
    in = sc.buildPairInput('TX1', 'RX1');            % free-space patterns
    prFree = rfscreen.interference.PairwiseAnalyzer.analyze(in, [], cfg);
    h.eqTol('free-space RX gain = 10', prFree.rxGain_dBi, 10, 1e-6);

    rxAnt = sc.antennas('ANT_RX');
    sel = rfscreen.interference.InstalledEnvironmentAnalyzer.selectedPatternFor( ...
        sc, rxAnt.id, sc.patterns(rxAnt.patternId), 'PREFER_INSTALLED');
    in2 = in; in2.rxPattern = sel.pattern;           % substitute installed pattern
    prInst = rfscreen.interference.PairwiseAnalyzer.analyze(in2, [], cfg);
    h.eqTol('installed RX gain = 6', prInst.rxGain_dBi, 6, 1e-6);
    h.isTrue('installed pattern changed gain via existing engine', ...
        abs(prFree.rxGain_dBi - prInst.rxGain_dBi) > 3);

    % ---- geometry blockage does NOT modify the RF gain ----
    % (PairwiseAnalyzer ignores structures entirely; the blocked LOS above did not
    %  change prFree's gain, which equals the pure free-space value.)
    h.eqTol('blocked LOS did not change gain', prFree.rxGain_dBi, 10, 1e-9);
    h.eqStr('coupling still pattern-only (unchanged)', prFree.couplingModelType, 'PATTERN_ONLY');
end

function sc = buildScenario()
    sc = rfscreen.scenario.Scenario('P5_INT');
    freq = 2.2e9;
    sc.addPattern('PF_TX', rfscreen.antenna.SyntheticPatternFactory.isotropic(12, freq));
    sc.addPattern('PF_RX', rfscreen.antenna.SyntheticPatternFactory.isotropic(10, freq));
    Role = rfscreen.antenna.Role; Pol = rfscreen.antenna.Polarization;
    sc.addAntenna(rfscreen.antenna.Antenna('ANT_TX','tx',Role.TX,1e9,4e9,Pol.RHCP,'PF_TX','ANT_TX'));
    sc.addAntenna(rfscreen.antenna.Antenna('ANT_RX','rx',Role.RX,1e9,4e9,Pol.RHCP,'PF_RX','ANT_RX'));
    sc.addInstallation(rfscreen.antenna.AntennaInstallation('ANT_TX',[0;0;0],eye(3)));
    sc.addInstallation(rfscreen.antenna.AntennaInstallation('ANT_RX',[10;0;0], ...
        rfscreen.geometry.Rotation.aboutZ(180)));
    sc.addTransmitter(rfscreen.rf.RFTransmitter('TX1','ANT_TX',freq,20e6,30));
    sc.addReceiver(rfscreen.rf.RFReceiver('RX1','ANT_RX',freq,20e6));

    % installed pattern for the RX antenna (config DEPLOYED), 6 dBi
    G = 6 * ones(numel(-90:5:90), numel(-180:5:180), 1);
    grid = rfscreen.antenna.PatternGrid(-180:5:180, -90:5:90, freq, G);
    inst = rfscreen.antenna.InstalledPattern('SYNTHETIC_TEST_installed_rx', 'SIMULATED_3D', grid, 'HFSS');
    sc.activeConfigId = 'DEPLOYED';
    sc.addInstalledPattern('ANT_RX', 'DEPLOYED', inst);

    % blocking panel between TX and RX (normal +X at x=5)
    panel = rfscreen.geometry.PanelGeometry(4, 4);
    st = rfscreen.geometry.SpacecraftStructure('PANEL','SYNTHETIC_TEST_panel', ...
        rfscreen.geometry.StructureType.SOLAR_ARRAY, panel, ...
        rfscreen.geometry.Rotation.aboutY(90), [5;0;0], struct('provenance','SYNTHETIC_TEST'));
    sc.addStructure(st);
end
