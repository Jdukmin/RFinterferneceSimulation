function test_invalid_inputs(h)
%TEST_INVALID_INPUTS Robust rejection of bad inputs (VR-060..064).
    h.setGroup('invalid');

    Role = rfscreen.antenna.Role; Pol = rfscreen.antenna.Polarization;
    SP = rfscreen.antenna.SyntheticPatternFactory;

    % --- VR-060 missing pattern reference -> validate errors ---
    sc = rfscreen.scenario.Scenario('BAD');
    sc.addInstallation(rfscreen.antenna.AntennaInstallation('ANT', [0;0;0], eye(3)));
    sc.addAntenna(rfscreen.antenna.Antenna('ANT', 'a', Role.TX, 1e9, 4e9, Pol.RHCP, 'MISSING_PAT', 'ANT'));
    h.throws('missing pattern ref', @() sc.validate(), 'rfscreen:scenario:badRef');

    % --- VR-061 invalid rotation matrix ---
    badR = [1 0 0; 0 1 0; 0 0 2];   % not orthonormal (det=2)
    h.throws('invalid rotation', ...
        @() rfscreen.antenna.AntennaInstallation('ANT', [0;0;0], badR), 'rfscreen:geometry:invalidRotation');
    h.isFalse('isRotationMatrix false', rfscreen.geometry.Rotation.isRotationMatrix(badR));
    h.isTrue('isRotationMatrix true for eye', rfscreen.geometry.Rotation.isRotationMatrix(eye(3)));

    % --- VR-062 frequency ordering / range ---
    h.throws('freqMin>freqMax', ...
        @() rfscreen.antenna.Antenna('X', 'x', Role.TX, 4e9, 1e9, Pol.RHCP, 'P', 'X'), ...
        'rfscreen:antenna:freqOrder');
    % out-of-range pattern frequency with 'error' policy
    grid = rfscreen.antenna.PatternGrid([-180 0 180], [-90 0 90], [1e9 2e9], zeros(3,3,2));
    p = rfscreen.antenna.FreeSpacePattern('SYNTHETIC_TEST_z', rfscreen.antenna.PatternProvenance.SYNTHETIC_TEST, grid);
    polErr = rfscreen.config.PatternInterpolationPolicy(struct('outOfBandFreq', 'error'));
    h.throws('freq out of range error', @() p.evaluate(9e9, 0, 0, polErr), ...
        'rfscreen:pattern:freqOutOfRange');

    % --- VR-063 NaN inputs rejected ---
    h.throws('NaN power', ...
        @() rfscreen.rf.RFTransmitter('T', 'ANT', 2.2e9, 20e6, NaN), ...
        'rfscreen:validate:finiteScalar');
    h.throws('NaN position', ...
        @() rfscreen.antenna.AntennaInstallation('ANT', [NaN;0;0], eye(3)), ...
        'rfscreen:validate:vector3');
    h.throws('invalid role', ...
        @() rfscreen.antenna.Antenna('X', 'x', 'BOGUS', 1e9, 4e9, Pol.RHCP, 'P', 'X'), ...
        'rfscreen:validate:member');

    % --- VR-064 duplicate id ---
    sc2 = rfscreen.scenario.Scenario('DUP');
    sc2.addAntenna(rfscreen.antenna.Antenna('DUPID', 'a', Role.TX, 1e9, 4e9, Pol.RHCP, 'P', 'DUPID'));
    h.throws('duplicate antenna id', ...
        @() sc2.addAntenna(rfscreen.antenna.Antenna('DUPID', 'b', Role.RX, 1e9, 4e9, Pol.RHCP, 'P', 'DUPID')), ...
        'rfscreen:scenario:duplicateId');

    % --- reserved coupling models must not fabricate physics (SR-120) ---
    ctx = rfscreen.coupling.CouplingModel.newContext();
    h.throws('HFSS reserved not implemented', ...
        @() rfscreen.coupling.HFSSCouplingModel().computeCoupling(ctx), ...
        'rfscreen:coupling:NotImplementedPhase1');
    h.throws('MeasuredS21 reserved not implemented', ...
        @() rfscreen.coupling.MeasuredS21CouplingModel().computeCoupling(ctx), ...
        'rfscreen:coupling:NotImplementedPhase1');
    % AntennaToStructureFOV was a reserved stub in Phase 1; it is ACTIVATED in Phase 5.
    % (Structure-FOV physics is geometry-only; see the Phase-5 suite.)
    h.isTrue('structure FOV activated (Phase 5)', ...
        rfscreen.geometry.AntennaToStructureFOV.isSupported());
end
