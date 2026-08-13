function test_coordinate(h)
%TEST_COORDINATE Body/Local transforms, round-trip, DCM validity (VR-020..023, VR-072).
    h.setGroup('coordinate');
    R  = rfscreen.geometry.Rotation;
    DC = rfscreen.geometry.DirectionCalculator;

    % --- VR-020 Body -> Local ---
    % R_BA = aboutZ(90): antenna frame rotated +90deg about body Z.
    RBA = R.aboutZ(90);
    vB = [1; 0; 0];
    vA = DC.bodyToLocal(RBA, vB);         % expect [0; -1; 0]
    h.eqTol('bodyToLocal aboutZ90', vA, [0; -1; 0], 1e-12);

    % --- VR-021 Local -> Body (inverse) ---
    vB2 = DC.localToBody(RBA, vA);
    h.eqTol('localToBody inverts', vB2, vB, 1e-12);

    % --- VR-022 round-trip v = R_AB * R_BA * v (VR-072) ---
    q = [0.5, 0.5, -0.5, 0.5];            % a valid unit quaternion
    Rq = R.fromQuaternion(q);
    h.isTrue('fromQuaternion is a rotation', R.isRotationMatrix(Rq));
    v = [0.3; -1.2; 4.7];
    vRound = Rq.' * (Rq * v);
    h.eqTol('rotation round-trip', vRound, v, 1e-12);

    % quaternion <-> DCM round trip
    q2 = R.toQuaternion(Rq);
    Rq2 = R.fromQuaternion(q2);
    h.eqTol('quat->dcm->quat->dcm', Rq2, Rq, 1e-9);

    % --- inverse == transpose ---
    h.eqTol('inverse==transpose', R.inverse(RBA), RBA.', 1e-12);

    % --- boresight is first column of R_BA ---
    b = DC.boresightInBody(RBA);
    h.eqTol('boresight=col1', b, RBA(:, 1), 1e-12);

    % --- direction <-> az/el exactness at nodes ---
    u = DC.azElToDirection(0, 0);
    h.eqTol('boresight dir +X', u, [1; 0; 0], 1e-12);
    u2 = DC.azElToDirection(90, 0);
    h.eqTol('az90 dir +Y', u2, [0; 1; 0], 1e-12);
    u3 = DC.azElToDirection(0, 90);
    h.eqTol('el90 dir +Z', u3, [0; 0; 1], 1e-12);
    [az, el, def] = DC.directionToAzEl([0; 1; 0]);
    h.isTrue('dir->azel defined', def);
    h.eqTol('az of +Y', az, 90, 1e-12);
    h.eqTol('el of +Y', el, 0, 1e-12);

    % zero vector -> undefined (AR-015)
    [~, ~, def0] = DC.directionToAzEl([0; 0; 0]);
    h.isFalse('zero vector undefined', def0);
end
