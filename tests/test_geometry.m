function test_geometry(h)
%TEST_GEOMETRY Antenna-to-antenna relative geometry (VR-010..014).
    h.setGroup('geometry');
    FOV = rfscreen.geometry.AntennaToAntennaFOV;
    F   = @testutil.Fixtures.rbaBoresight;
    eyeR = eye(3);

    % --- VR-010 same-axis: TX faces +X at origin, RX at [10,0,0] faces -X ---
    g = FOV.relativeGeometry([0;0;0], eyeR, [10;0;0], F([-1;0;0]));
    h.eqTol('same-axis distance', g.distance_m, 10, 1e-12);
    h.eqTol('same-axis txAz', g.txAz_deg, 0, 1e-9);
    h.eqTol('same-axis txEl', g.txEl_deg, 0, 1e-9);
    h.eqTol('same-axis rxAz', g.rxAz_deg, 0, 1e-9);
    h.eqTol('same-axis rxEl', g.rxEl_deg, 0, 1e-9);

    % --- VR-011 opposite-facing: both boresights +X (RX's back toward TX) ---
    g = FOV.relativeGeometry([0;0;0], eyeR, [10;0;0], eyeR);
    h.eqTol('opp txAz (boresight)', g.txAz_deg, 0, 1e-9);
    h.eqTol('opp rxAz (behind=180)', abs(g.rxAz_deg), 180, 1e-9);

    % --- VR-012 90-degree: RX at [0,10,0], boresight +X ---
    g = FOV.relativeGeometry([0;0;0], eyeR, [0;10;0], eyeR);
    h.eqTol('90deg txAz', g.txAz_deg, 90, 1e-9);
    h.eqTol('90deg rxAz', g.rxAz_deg, -90, 1e-9);
    h.eqTol('90deg el zero', [g.txEl_deg g.rxEl_deg], [0 0], 1e-9);

    % --- VR-013 translated in-plane: RX at [5,5,0] boresight +X ---
    g = FOV.relativeGeometry([0;0;0], eyeR, [5;5;0], eyeR);
    h.eqTol('translated distance', g.distance_m, sqrt(50), 1e-12);
    h.eqTol('translated txAz 45', g.txAz_deg, 45, 1e-9);

    % elevation: RX straight up boresight +X
    g = FOV.relativeGeometry([0;0;0], eyeR, [0;0;10], eyeR);
    h.eqTol('up txEl 90', g.txEl_deg, 90, 1e-9);

    % --- VR-014 arbitrary installation: RX at [3,4,12] (dist 13) ---
    RBA_rx = testutil.Fixtures.rbaBoresight([1; -2; 0.5]);
    g = FOV.relativeGeometry([1;1;1], eye(3), [4;5;13], RBA_rx);
    h.eqTol('arbitrary distance', g.distance_m, 13, 1e-12);
    % Reconstruct: az/el in TX frame must reproduce the unit direction.
    DC = rfscreen.geometry.DirectionCalculator;
    urec = DC.azElToDirection(g.txAz_deg, g.txEl_deg);
    uexp = ([4;5;13] - [1;1;1]) / 13;    % TX frame == body (eye)
    h.eqTol('arbitrary az/el reconstructs dir', urec, uexp, 1e-9);

    % off-boresight angle helper
    ang = DC.offBoresightAngle(0, 0);
    h.eqTol('offBoresight at boresight', ang, 0, 1e-9);
    ang2 = DC.offBoresightAngle(90, 0);
    h.eqTol('offBoresight at az90', ang2, 90, 1e-9);
    ang3 = DC.offBoresightAngle(180, 0);
    h.eqTol('offBoresight behind', ang3, 180, 1e-9);
end
