function test_local_facets(h)
%TEST_LOCAL_FACETS Cropped actual facets around one antenna in the CST local frame (VR-453..455).
    h.setGroup('local_facets');
    m = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
    LF = rfscreen.mission.LocalFacetExporter;

    % ---- clipping primitives ----
    sq = [-1 1 1 -1; -1 -1 1 1; 0 0 0 0];                       % 2x2 square in z=0
    c = LF.clipToBox(sq, [-0.5; -5; -1], [0.5; 5; 1]);
    h.eqTol('clip square to |x|<=0.5 -> area 2', LF.polygonArea(c), 2, 1e-12);
    h.eqTol('fully inside stays unchanged', LF.polygonArea(LF.clipToBox(sq, -3 * ones(3, 1), 3 * ones(3, 1))), 4, 1e-12);
    h.isTrue('fully outside -> empty', isempty(LF.clipToBox(sq, [5; 5; -1], [6; 6; 1])));
    h.isTrue('plane outside the box in z -> empty', isempty(LF.clipToBox(sq, [-3; -3; 0.5], [3; 3; 1])));
    tri = [0 2 0; 0 0 2; 0 0 0];
    h.eqTol('triangle clipped by x<=1: area 1.5', LF.polygonArea(LF.clipToBox(tri, [-5; -5; -1], [1; 5; 1])), 1.5, 1e-12);
    % distance to a finite facet: the foot lies outside -> distance includes the in-plane offset
    sqz = [-1 1 1 -1; -1 -1 1 1; 2 2 2 2];                       % plane z = 2, origin at 2 below
    h.eqTol('foot inside the facet: perpendicular distance', LF.pointPolygonDistance(sqz, [0; 0; 1]), 2, 1e-12);
    sqs = sqz + repmat([5; 0; 0], 1, 4);                         % shifted so the foot is outside
    h.eqTol('foot outside: distance to the nearest edge point', LF.pointPolygonDistance(sqs, [0; 0; 1]), sqrt(4^2 + 2^2), 1e-12);
    h.eqTol('edge distance of the shifted square', LF.pointEdgeDistance(sqs), sqrt(4^2 + 2^2), 1e-12);

    % ---- SBA_NADIR (panel #6): frame + distances ----
    ex = LF.export(m, 'SBA_NADIR', 0.35);
    h.isTrue('R_BL proper rotation', rfscreen.geometry.Rotation.isRotationMatrix(ex.R_BL));
    h.eqTol('+X_L = +X_B', ex.R_BL(:, 1), [1; 0; 0], 0);
    h.eqTol('+Z_L = boresight = panel normal', ex.R_BL(:, 3), [0; 0.866025404; 0.5], 2e-9);
    h.eqTol('+Y_L = +Z_L x +X_L', ex.R_BL(:, 2), cross(ex.R_BL(:, 3), ex.R_BL(:, 1)), 1e-15);
    h.eqTol('reference point unchanged (not snapped)', ex.position_B_m, [0.255; 0.870; 1.030], 0);
    h.eqTol('repo antenna frame boresight untouched', ex.R_BA_repo(:, 1), ex.R_BL(:, 3), 1e-12);
    ids = {ex.facets.structureId};
    h.isTrue('assigned panel #6 present', any(strcmp(ids, 'PANEL_6')));
    h.isTrue('rear panel #8 (X=0) present within 0.35 m', any(strcmp(ids, 'PANEL_8')));
    h.isFalse('forward panel #7 (X=6) not in the crop', any(strcmp(ids, 'PANEL_7')));
    f6 = ex.facets(strcmp(ids, 'PANEL_6'));
    h.isTrue('flagged as the assigned panel', f6.isAssignedPanel);
    h.eqTol('support-plane distance = +190.181 mm (outside)', f6.supportPlaneSignedDistance_m, 0.190181, 1e-6);
    h.isTrue('min distance to the finite facet >= plane distance', f6.minDistanceToFacet_m >= f6.supportPlaneSignedDistance_m - 1e-12);
    h.isTrue('facet distance and plane distance are reported separately', ...
        isfield(f6, 'minDistanceToFacet_m') && isfield(f6, 'supportPlaneSignedDistance_m') && isfield(f6, 'minDistanceToEdge_m'));
    f8 = ex.facets(strcmp(ids, 'PANEL_8'));
    h.eqTol('rear-panel plane distance = 255 mm (X = 0)', abs(f8.supportPlaneSignedDistance_m), 0.255, 1e-9);
    maxAbs = 0;
    for i = 1:numel(ex.facets); maxAbs = max(maxAbs, max(abs(ex.facets(i).verticesLocal_m(:)))); end
    h.isTrue('every cropped vertex lies inside the box', maxAbs <= 0.35 + 1e-12);
    h.isTrue('crops are subsets of the full facets', all([ex.facets.croppedArea_m2] <= [ex.facets.fullArea_m2] + 1e-12));
    h.isTrue('large panels are cropped, not the whole bus', any([ex.facets.isCropped]));
    % cropped polygons stay planar (all vertices on the facet plane)
    planar = true;
    for i = 1:numel(ex.facets)
        f = ex.facets(i);
        d = f.outwardNormalLocal.' * (f.verticesLocal_m - repmat(f.verticesLocal_m(:, 1), 1, size(f.verticesLocal_m, 2)));
        planar = planar && all(abs(d) < 1e-9);
    end
    h.isTrue('cropped facets stay planar', planar);

    % ---- an in-plane antenna: SAR_ANT lies exactly on the panel #1 plane ----
    exS = LF.export(m, 'SAR_ANT', 0.35);
    fS = exS.facets(strcmp({exS.facets.structureId}, 'PANEL_1'));
    h.eqTol('SAR_ANT exactly on its plane (0 distance)', fS.supportPlaneSignedDistance_m, 0, 1e-12);
    h.eqTol('...and the facet distance is 0', fS.minDistanceToFacet_m, 0, 1e-12);

    % ---- radius monotonicity (extent-convergence set) ----
    a25 = sum([LF.export(m, 'GPSA_1', 0.25).facets.croppedArea_m2]);
    a35 = sum([LF.export(m, 'GPSA_1', 0.35).facets.croppedArea_m2]);
    a50 = sum([LF.export(m, 'GPSA_1', 0.50).facets.croppedArea_m2]);
    h.isTrue('cropped area grows with the radius', a25 < a35 && a35 < a50);
    h.throws('unknown antenna rejected', @() LF.export(m, 'NOPE', 0.3), 'rfscreen:mission:badRef');
    h.throws('non-positive radius rejected', @() LF.export(m, 'GPSA_1', 0), 'rfscreen:validate:positiveScalar');

    % ---- export files ----
    tmp = tempname(); mkdir(tmp);
    LF.writeCsv(ex, fullfile(tmp, 'f.csv'));
    T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(tmp, 'f.csv'));
    h.eqTol('CSV vertex rows = total cropped vertices', T.nRows, sum(arrayfun(@(f) size(f.verticesLocal_m, 2), ex.facets)), 0);
    LF.writeSummaryCsv({ex, exS}, fullfile(tmp, 's.csv'));
    T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(tmp, 's.csv'));
    h.eqTol('summary rows = facets of both antennas', T.nRows, numel(ex.facets) + numel(exS.facets), 0);
    delete(fullfile(tmp, '*.csv')); rmdir(tmp);

    % ---- pure geometry ----
    txt = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'src', '+rfscreen', '+mission', 'LocalFacetExporter.m'));
    h.isTrue('no EM / coupling value in the exporter', isempty(strfind(txt, 'S21')) && isempty(strfind(txt, 'FreeSpacePathLoss')));
end
