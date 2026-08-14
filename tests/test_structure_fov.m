function test_structure_fov(h)
%TEST_STRUCTURE_FOV Antenna-to-structure FOV incl. angular footprint (VR-402..404).
    h.setGroup('structure_fov');
    FOV = @(pos, R, st, opts) rfscreen.geometry.AntennaToStructureFOV.analyze('ANT', pos, R, st, opts);
    box = @(hs, R, o) mkStruct(rfscreen.geometry.BoxGeometry(hs), R, o);
    eyeR = eye(3);

    % ---- structure in boresight ----
    f = FOV([0;0;0], eyeR, box([0.5;0.5;0.5], eyeR, [10;0;0]), struct());
    h.eqTol('boresight centerAz', f.centerAz_deg, 0, 1e-9);
    h.eqTol('boresight centerEl', f.centerEl_deg, 0, 1e-9);
    h.eqTol('boresight off', f.centerOffBoresight_deg, 0, 1e-9);
    h.isTrue('boresight ray hits', f.centerRayHits);
    h.eqStr('fidelity vertex-sampled', f.geometryFidelity, 'VERTEX_SAMPLED');
    h.eqStr('no pattern -> geometry only', f.validity, 'GEOMETRY_ONLY');

    % ---- 90 degrees off boresight ----
    f90 = FOV([0;0;0], eyeR, box([0.5;0.5;0.5], eyeR, [0;10;0]), struct());
    h.eqTol('90deg centerAz', f90.centerAz_deg, 90, 1e-6);
    h.eqTol('90deg off', f90.centerOffBoresight_deg, 90, 1e-6);

    % ---- behind antenna ----
    fb = FOV([0;0;0], eyeR, box([0.5;0.5;0.5], eyeR, [-10;0;0]), struct());
    h.eqTol('behind off = 180', fb.centerOffBoresight_deg, 180, 1e-6);
    h.isTrue('behind ray still hits structure', fb.centerRayHits);

    % ---- translated structure ----
    ft = FOV([0;0;0], eyeR, box([0.5;0.5;0.5], eyeR, [10;5;0]), struct());
    h.eqTol('translated centerAz', ft.centerAz_deg, atan2d(5,10), 1e-6);

    % ---- antenna translated (structure still on boresight) ----
    fat = FOV([2;0;0], eyeR, box([0.5;0.5;0.5], eyeR, [10;0;0]), struct());
    h.eqTol('antenna translated off = 0', fat.centerOffBoresight_deg, 0, 1e-6);

    % ---- antenna rotated (boresight +Y): +X structure appears to the side ----
    far = FOV([0;0;0], rfscreen.geometry.Rotation.aboutZ(90), box([0.5;0.5;0.5], eyeR, [10;0;0]), struct());
    h.eqTol('antenna rotated centerAz = -90', far.centerAz_deg, -90, 1e-6);

    % ---- VR-403/404 angular footprint: center in SIDE, an edge reaches MAIN ----
    % Flat panel in the body XY plane (z=0, no elevation spread); a wide main lobe
    % (<=15 deg) so a corner near boresight cleanly classifies MAIN.
    p = rfscreen.antenna.SyntheticPatternFactory.mainSideBack(15, -10, -30, 2.2e9, 15);
    center = [10*cosd(20); 10*sind(20); 0];    % centroid at 20 deg off boresight -> SIDE
    panelStruct = rfscreen.geometry.SpacecraftStructure('S', 'SYNTHETIC_TEST_struct', 'SOLAR_ARRAY', ...
        rfscreen.geometry.PanelGeometry(5, 5), eyeR, center, struct('provenance', 'SYNTHETIC_TEST'));
    fbig = FOV([0;0;0], eyeR, panelStruct, struct('pattern', p, 'frequency_Hz', 2.2e9));
    h.eqStr('center lobe is SIDE', fbig.centerLobe, 'SIDE');
    h.isTrue('footprint occupies MAIN (edge enters main lobe)', fbig.occupies('MAIN'));
    h.isTrue('footprint also occupies SIDE', fbig.occupies('SIDE'));
    h.isTrue('maxAngularRadius > 0', fbig.maxAngularRadius_deg > 3);
    h.eqStr('with pattern -> FOV_WITH_PATTERN', fbig.validity, 'FOV_WITH_PATTERN');
    % center-point-only would classify SIDE and MISS the main-lobe overlap:
    h.isTrue('footprint set larger than center-only', numel(fbig.occupiedLobes) >= 2);
end

function st = mkStruct(geom, R_BS, origin)
    st = rfscreen.geometry.SpacecraftStructure('S', 'SYNTHETIC_TEST_struct', 'PANEL', ...
        geom, R_BS, origin, struct('provenance', 'SYNTHETIC_TEST'));
end
