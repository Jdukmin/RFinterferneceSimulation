function test_invariants(h)
%TEST_INVARIANTS Numerical invariants (VR-070..073).
    h.setGroup('invariants');
    FOV = rfscreen.geometry.AntennaToAntennaFOV;
    R = rfscreen.geometry.Rotation;

    pA = [1; 2; 3];  RA = R.aboutZ(35);
    pB = [7; -4; 9]; RB = R.aboutY(-20) * R.aboutX(15);

    gAB = FOV.relativeGeometry(pA, RA, pB, RB);
    gBA = FOV.relativeGeometry(pB, RB, pA, RA);

    % VR-070 distance symmetry
    h.eqTol('distance(A,B)==distance(B,A)', gAB.distance_m, gBA.distance_m, 1e-12);

    % VR-071 direction anti-symmetry d_AB = -d_BA
    h.eqTol('d_AB == -d_BA', gAB.dBody, -gBA.dBody, 1e-12);

    % VR-072 rotation round-trip for several fixed quaternions
    qs = { [1 0 0 0], [0.5 0.5 0.5 0.5], [0.707106781 0 0.707106781 0], ...
           [0.2 -0.3 0.4 0.8] };
    v = [2.5; -1.5; 0.75];
    for i = 1:numel(qs)
        Rq = R.fromQuaternion(qs{i});
        vr = Rq.' * (Rq * v);
        h.eqTol(sprintf('round-trip q%d', i), vr, v, 1e-9);
        h.isTrue(sprintf('q%d is rotation', i), R.isRotationMatrix(Rq));
    end

    % VR-073 pattern lookup deterministic
    p = rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(10, 2e9, 2);
    a = p.evaluate(2e9, 23, -14);
    b = p.evaluate(2e9, 23, -14);
    h.eqTol('pattern deterministic', a, b, 0);
end
