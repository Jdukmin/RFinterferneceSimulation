function test_simplified_spacecraft(h)
%TEST_SIMPLIFIED_SPACECRAFT Simplified spacecraft baseline v1 (VR-431..VR-437).
%   Expected values are the baseline SSOT numbers (data/spacecraft/simplified_spacecraft_v1/README.md);
%   the dataset is the SSOT for geometry, these literals are independent regression checks.
    h.setGroup('simplified_sc');
    m = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
    hull = m.hull;

    % ================= VR-431 cross-section geometry =================
    h.eqTol('vertex count == 6', hull.nVertices(), 6, 0);
    h.eqTol('unique vertex count == 6', size(unique(hull.yz_m.', 'rows'), 1), 6, 0);
    h.eqTol('unique vertex ids == 6', numel(unique(hull.vertexIds)), 6, 0);
    h.isTrue('vertex order V12..V61', isequal(hull.vertexIds, {'V12','V23','V34','V45','V56','V61'}));
    expYZ = [-783.188191 -1084.414419 -301.226227  301.226227 1084.414419 783.188191;
              800.000000   278.260870 -1078.260870 -1078.260870 278.260870 800.000000] / 1000;
    h.eqTol('vertices == SSOT (m)', hull.yz_m, expYZ, 1e-15);

    L = hull.edgeLengths();               % edge k: vertex k -> k+1 => P2,P3,P4,P5,P6,P1
    w = containers.Map();
    for i = 1:numel(m.panels)
        if strcmp(m.panels(i).kind, 'SIDE'); w(m.panels(i).id) = m.panels(i).width_m; end
    end
    longW = 1.566376383; shortW = 0.602452455;
    for p = {'PANEL_1','PANEL_3','PANEL_5'}
        h.eqTol(['LONG width ' p{1}], w(p{1}), longW, 2e-9);
    end
    for p = {'PANEL_2','PANEL_4','PANEL_6'}
        h.eqTol(['SHORT width ' p{1}], w(p{1}), shortW, 2e-9);
    end
    h.eqTol('width ratio == 2.6', w('PANEL_1') / w('PANEL_2'), 2.6, 1e-8);
    h.isTrue('LONG-SHORT-LONG-SHORT-LONG-SHORT (P1..P6)', ...
        all(cellfun(@(p) w(p), {'PANEL_1','PANEL_3','PANEL_5'}) > 2.5 * cellfun(@(p) w(p), {'PANEL_2','PANEL_4','PANEL_6'})));
    h.isTrue('edges alternate SHORT/LONG around the section', ...
        all(abs(L([1 3 5]) - shortW) < 2e-9) && all(abs(L([2 4 6]) - longW) < 2e-9));

    % not a regular hexagon (and not an approximation of one)
    h.isTrue('Panel #7/#8 polygon is NOT regular (edge lengths differ)', max(L) - min(L) > 0.9);
    ang = zeros(1, 6);
    for k = 1:6
        a = hull.yz_m(:, mod(k-2, 6) + 1) - hull.yz_m(:, k); b = hull.yz_m(:, mod(k, 6) + 1) - hull.yz_m(:, k);
        ang(k) = acosd(dot(a, b) / norm(a) / norm(b));
    end
    h.eqTol('equiangular: interior angles 120 deg', ang, 120 * ones(1, 6), 1e-6);

    for i = 1:numel(m.panels)
        pn = m.panels(i);
        if ~strcmp(pn.kind, 'SIDE'); continue; end
        if strcmp(pn.sizeClass, 'LONG'); d = 0.8; else; d = 1.078260870; end
        h.eqTol(['support distance ' pn.id], pn.supportDistance_m, d, 1e-9);
    end
    h.eqTol('circumradius', hull.circumradius(), 1.119546222, 1e-9);
    h.eqTol('all vertex radii equal circumradius', hull.vertexRadii(), 1.119546222 * ones(1, 6), 1e-9);
    h.eqTol('circumdiameter = 2.239092444 m', 2 * hull.circumradius(), 2.239092444, 2e-9);
    h.isTrue('circumdiameter < 2.5 m', 2 * hull.circumradius() < 2.5);
    h.eqTol('X extent exactly 0..6 m', [hull.xMin_m hull.xMax_m], [0 6], 0);
    h.eqTol('cross-section area', hull.area(), 2.854053021, 1e-9);
    h.eqTol('cross-section perimeter', hull.perimeter(), 6.506486512, 1e-8);
    h.eqTol('centroid (0,0)', hull.centroid(), [0; 0], 1e-9);
    h.eqTol('prism volume', hull.volume(), 17.124318124, 1e-8);
    h.eqTol('total side-panel area', sum(hull.sideAreas()), 39.038919071, 1e-8);
    h.eqTol('one LONG side area', w('PANEL_1') * 6, 9.398258295, 1e-8);
    h.eqTol('one SHORT side area', w('PANEL_2') * 6, 3.614714729, 1e-8);
    h.eqTol('Y extent', [min(hull.yz_m(1,:)) max(hull.yz_m(1,:))], [-1.084414419 1.084414419], 1e-15);
    h.eqTol('Z extent', [min(hull.yz_m(2,:)) max(hull.yz_m(2,:))], [-1.078260870 0.8], 1e-15);

    % ================= VR-432 panel structures =================
    expN = struct('PANEL_1', [0;0;1], 'PANEL_2', [0;-0.866025404;0.5], 'PANEL_3', [0;-0.866025404;-0.5], ...
        'PANEL_4', [0;0;-1], 'PANEL_5', [0;0.866025404;-0.5], 'PANEL_6', [0;0.866025404;0.5], ...
        'PANEL_7', [1;0;0], 'PANEL_8', [-1;0;0]);
    expC = struct('PANEL_1', [3000;0;800], 'PANEL_2', [3000;-933.801305;539.130435], ...
        'PANEL_3', [3000;-692.820323;-400], 'PANEL_4', [3000;0;-1078.260870], ...
        'PANEL_5', [3000;692.820323;-400], 'PANEL_6', [3000;933.801305;539.130435]);
    h.eqTol('8 panel structures', numel(m.structures), 8, 0);
    for i = 1:numel(m.structures)
        st = m.structures{i}; pid = st.id;
        h.eqStr([pid ' type PANEL'], st.structureType, 'PANEL');
        h.eqStr([pid ' provenance USER_DEFINED (not CAD)'], st.provenance, 'USER_DEFINED');
        h.isTrue([pid ' R_BS proper'], rfscreen.geometry.Rotation.isRotationMatrix(st.R_BS));
        h.eqTol([pid ' local normal == outward normal'], st.R_BS(:, 3), expN.(pid), 2e-9);
        if isfield(expC, pid)
            h.isTrue([pid ' reuses PanelGeometry'], isa(st.geometry, 'rfscreen.geometry.PanelGeometry'));
            h.eqTol([pid ' local +X == +X_B'], st.R_BS(:, 1), [1;0;0], 0);
            h.eqTol([pid ' center'], st.origin_m, expC.(pid) / 1000, 1e-9);
            h.eqTol([pid ' length 6 m'], st.geometry.width_m, 6, 0);
            % panel corners coincide with the hull edge end points at X = 0 and X = 6
            k = m.panels(strcmp({m.panels.id}, pid)).edgeIndex;
            a = hull.yz_m(:, k); b = hull.yz_m(:, mod(k, 6) + 1);
            exp4 = [0 6 0 6; a a b b];      % {X=0,6} x {edge start, edge end}
            h.eqTol([pid ' corners == hull edge'], sortCols(st.verticesBody()), sortCols(exp4), 1e-12);
        else
            h.isTrue([pid ' exact ConvexPolygonGeometry'], isa(st.geometry, 'rfscreen.geometry.ConvexPolygonGeometry'));
            vb = st.verticesBody();
            h.eqTol([pid ' 6 vertices'], size(vb, 2), 6, 0);
            xf = 6 * strcmp(pid, 'PANEL_7');
            h.eqTol([pid ' vertices == SSOT hexagon at X=' num2str(xf)], vb, [xf * ones(1, 6); expYZ], 1e-12);
            h.eqTol([pid ' end-cap area == section area'], st.geometry.area(), 2.854053021, 1e-9);
        end
    end

    % end-cap ray intersection == the single exact hexagon (grid equivalence)
    p7 = m.structures{strcmp(cellfun(@(s) s.id, m.structures, 'UniformOutput', false), 'PANEL_7')};
    p8 = m.structures{strcmp(cellfun(@(s) s.id, m.structures, 'UniformOutput', false), 'PANEL_8')};
    nAgree = 0; nTot = 0;
    for y = -1.2:0.05:1.2
        for z = -1.2:0.05:1.0
            inside = true; margin = Inf;
            for k = 1:6
                o = hull.sideOffset([0; y; z], k); inside = inside && o <= 0; margin = min(margin, abs(o));
            end
            if margin < 1e-6; continue; end
            [h7, t7] = p7.rayIntersectBody([7; y; z], [-1; 0; 0]);
            [h8, t8] = p8.rayIntersectBody([-1; y; z], [1; 0; 0]);
            nTot = nTot + 1;
            nAgree = nAgree + double(h7 == inside && h8 == inside && ...
                (~inside || (abs(t7 - 1) < 1e-12 && abs(t8 - 1) < 1e-12)));
        end
    end
    h.isTrue('end-cap ray grid sampled', nTot > 1500);
    h.eqTol('end-cap ray hits == exact hexagon membership (all samples)', nAgree, nTot, 0);
    [hc, ~] = p7.rayIntersectBody([7; -1.0; 0.7], [-1; 0; 0]);   % inside bounding box, outside Panel #2
    h.isFalse('corner region outside Panel #2 plane misses end cap', hc);

    % ================= VR-433 antenna installation points (exact, never snapped) =========
    src = struct('SBA_NADIR', [255 870 1030], 'SBA_ZENITH', [255 -530 -1240], ...
        'GPSA_1', [2045 -265 -1295], 'GPSA_2', [3145 -265 -1295], 'KAA_1', [5965 -1100 850], ...
        'KAA_2', [5965 1285 530], 'ISL', [6375 -595 -805], 'SAR_ANT', [3250 0 800]);
    expM = struct('SBA_NADIR', [0.255 0.870 1.030], 'SBA_ZENITH', [0.255 -0.530 -1.240], ...
        'GPSA_1', [2.045 -0.265 -1.295], 'GPSA_2', [3.145 -0.265 -1.295], 'KAA_1', [5.965 -1.100 0.850], ...
        'KAA_2', [5.965 1.285 0.530], 'ISL', [6.375 -0.595 -0.805], 'SAR_ANT', [3.250 0.000 0.800]);
    ids = fieldnames(src);
    I = struct(); RC = struct();          % id -> installation / record (Octave: no Map(key).field chaining)
    for i = 1:numel(m.installationRecords)
        RC.(m.installationRecords(i).antennaId) = m.installationRecords(i);
        I.(m.installationRecords(i).antennaId) = m.installations(m.installationRecords(i).antennaId);
    end
    h.eqTol('8 installations', m.installations.Count, 8, 0);
    for i = 1:numel(ids)
        id = ids{i};
        inst = m.installations(id);
        rec = m.installationRecords(strcmp({m.installationRecords.antennaId}, id));
        h.isTrue([id ' source mm preserved exactly'], isequal(rec.position_mm, src.(id)(:)));
        h.isTrue([id ' position_m == source exactly (no snapping)'], isequal(inst.position_m, expM.(id)(:)));
        h.isTrue([id ' outside or on hull'], rec.hullSignedDistance_m >= -1e-12);
    end
    h.isTrue('ISL beyond end cap kept (X = 6.375 > 6.0)', I.ISL.position_m(1) == 6.375);

    % ================= VR-434 panel assignment + normal offsets =================
    expP = struct('SBA_NADIR', 'PANEL_6', 'SBA_ZENITH', 'PANEL_4', 'GPSA_1', 'PANEL_3', 'GPSA_2', 'PANEL_3', ...
        'KAA_1', 'PANEL_1', 'KAA_2', 'PANEL_5', 'ISL', 'PANEL_3', 'SAR_ANT', 'PANEL_1');
    expOff = struct('SBA_NADIR', 190.2, 'SBA_ZENITH', 161.7, 'GPSA_1', 77.0, 'GPSA_2', 77.0, ...
        'KAA_1', 50.0, 'KAA_2', 47.8, 'ISL', 117.8, 'SAR_ANT', 0.0);
    for i = 1:numel(ids)
        id = ids{i};
        rec = m.installationRecords(strcmp({m.installationRecords.antennaId}, id));
        h.eqStr([id ' -> ' expP.(id)], rec.panelId, expP.(id));
        h.eqTol([id ' normal offset ~ ' num2str(expOff.(id)) ' mm'], rec.panelNormalOffset_m * 1000, expOff.(id), 0.06);
    end
    h.eqTol('KAA_1 offset exactly +50 mm', RC.KAA_1.panelNormalOffset_m, 0.05, 1e-12);
    h.eqTol('SAR_ANT exactly on Panel #1 plane', RC.SAR_ANT.panelNormalOffset_m, 0, 1e-12);
    h.eqStr('SBA_NADIR assignment provenance', RC.SBA_NADIR.assignmentProvenance, 'INFERRED_FROM_SIMPLIFIED_GEOMETRY');
    h.eqStr('SBA_ZENITH assignment provenance', RC.SBA_ZENITH.assignmentProvenance, 'INFERRED_FROM_SIMPLIFIED_GEOMETRY');

    % ================= VR-435 fixed boresights (+X_A = R_BA(:,1)) =================
    expB = struct('SBA_NADIR', [0;0.866025404;0.5], 'SBA_ZENITH', [0;0;-1], ...
        'GPSA_1', [0;-0.866025404;-0.5], 'GPSA_2', [0;-0.866025404;-0.5], ...
        'ISL', [0;-0.866025404;-0.5], 'SAR_ANT', [0;0;1]);
    fb = fieldnames(expB);
    for i = 1:numel(fb)
        inst = I.(fb{i});
        h.isTrue([fb{i} ' R_BA proper'], rfscreen.geometry.Rotation.isRotationMatrix(inst.R_BA));
        h.eqTol([fb{i} ' R_BA(:,1) == boresight'], inst.R_BA(:, 1), expB.(fb{i}), 2e-9);
        h.eqTol([fb{i} ' roll: z_A == +X_B'], inst.R_BA(:, 3), [1;0;0], 0);
        h.eqStr([fb{i} ' FIXED'], RC.(fb{i}).mountType, 'FIXED');
        h.eqTol([fb{i} ' record boresight'], RC.(fb{i}).nominalBoresight_B, expB.(fb{i}), 2e-9);
    end

    % ================= VR-436 KAA gimbal hemisphere =================
    h.eqTol('2 steering domains', m.steering.Count, 2, 0);
    kaaN = struct('KAA_1', [0;0;1], 'KAA_2', [0;0.866025404;-0.5]);
    for kid = {'KAA_1', 'KAA_2'}
        k = kid{1};
        dom = m.steering(k);
        n = kaaN.(k);
        h.eqStr([k ' GIMBAL mount'], RC.(k).mountType, 'GIMBAL');
        h.isTrue([k ' no single fixed boresight'], isempty(RC.(k).nominalBoresight_B));
        h.eqStr([k ' HEMISPHERE'], dom.steeringModel, 'HEMISPHERE');
        h.eqTol([k ' max off-axis 90'], dom.maxOffAxis_deg, 90, 0);
        h.eqStr([k ' simplified assumption'], dom.provenance, 'SIMPLIFIED_ASSUMPTION');
        h.eqTol([k ' base normal'], dom.referenceAxis_B, n, 2e-9);
        h.eqTol([k ' reference R_BA(:,1) == base normal'], I.(k).R_BA(:, 1), n, 2e-9);
        t = cross(dom.referenceAxis_B, [1;0;0]); t = t / norm(t);
        u = @(a) cosd(a) * dom.referenceAxis_B + sind(a) * t;
        h.isTrue([k ' 0 deg PASS'], dom.isAllowed(u(0)));
        h.isTrue([k ' 89.999 deg PASS'], dom.isAllowed(u(89.999)));
        h.isTrue([k ' 90 deg PASS'], dom.isAllowed(u(90)));
        h.isFalse([k ' 90.001 deg FAIL'], dom.isAllowed(u(90.001)));
        h.isFalse([k ' 90+1e-6 deg FAIL'], dom.isAllowed(u(90 + 1e-6)));
        h.isFalse([k ' 180 deg FAIL'], dom.isAllowed(-dom.referenceAxis_B));
        h.isTrue([k ' +X_B tangent on boundary PASS'], dom.isAllowed([1;0;0]));
        h.eqTol([k ' off-axis 45'], dom.offAxisAngle_deg(u(45)), 45, 1e-9);
        h.throws([k ' non-unit vector rejected'], @() dom.isAllowed(2 * dom.referenceAxis_B), ...
            'rfscreen:spacecraft:notUnitVector');
        h.throws([k ' zero vector rejected'], @() dom.isAllowed([0;0;0]), 'rfscreen:spacecraft:notUnitVector');
        h.eqTol([k ' steered at reference == installation R_BA'], dom.steeredR_BA(dom.referenceAxis_B), ...
            I.(k).R_BA, 1e-12);
        R45 = dom.steeredR_BA(u(45));
        h.isTrue([k ' steered R_BA proper'], rfscreen.geometry.Rotation.isRotationMatrix(R45));
        h.eqTol([k ' steered boresight'], R45(:, 1), u(45), 1e-12);
        h.throws([k ' steering outside domain rejected'], @() dom.steeredR_BA(-dom.referenceAxis_B), ...
            'rfscreen:spacecraft:outsideSteeringDomain');
        sInst = dom.steeredInstallation(I.(k), u(60));
        h.isTrue([k ' steered installation keeps position'], isequal(sInst.position_m, I.(k).position_m));
        U = dom.sampleDirections(15);
        allOk = true;
        for j = 1:size(U, 2); allOk = allOk && dom.isAllowed(U(:, j)); end
        h.isTrue([k ' hemisphere samples all allowed + unit'], allOk);
        h.eqTol([k ' sample count (1 + 6 rings x 24)'], size(U, 2), 1 + 6 * 24, 0);
        h.eqTol([k ' samples reach the 90 deg boundary'], max(acosd(min(1, U.' * dom.referenceAxis_B))), 90, 1e-9);
    end
    h.throws('HEMISPHERE must be 90 deg', @() rfscreen.spacecraft.GimbalSteeringDomain('X', [0;0;1], ...
        'HEMISPHERE', 60, 'SIMPLIFIED_ASSUMPTION'), 'rfscreen:spacecraft:badSteering');
    cone = rfscreen.spacecraft.GimbalSteeringDomain('X', [0;0;1], 'CONE', 60, 'TEST');
    h.isFalse('CONE 60 narrows the domain (70 deg FAIL)', cone.isAllowed([sind(70); 0; cosd(70)]));

    % ================= VR-437 scenario workflow + geometry-only invariants ==============
    sc = rfscreen.scenario.Scenario('SIMPLIFIED_SC_V1');
    rfscreen.spacecraft.SimplifiedSpacecraftBuilder.attachToScenario(sc, m);
    h.eqTol('scenario has 8 structures', sc.structures.Count, 8, 0);
    h.eqTol('scenario has 8 installations', sc.installations.Count, 8, 0);
    h.eqTol('no pattern created by geometry', sc.patterns.Count, 0, 0);
    h.eqTol('no installed pattern created', sc.installedPatterns.Count, 0, 0);
    act = sc.activeStructures();
    los = @(a, b) rfscreen.geometry.LineOfSight.segment(a, b, I.(a).position_m, I.(b).position_m, act);
    h.eqStr('SBA_NADIR <-> SBA_ZENITH blocked by hull', los('SBA_NADIR', 'SBA_ZENITH').status, 'BLOCKED');
    h.eqStr('GPSA_1 <-> GPSA_2 clear', los('GPSA_1', 'GPSA_2').status, 'CLEAR');
    r1 = los('SAR_ANT', 'KAA_1'); r2 = los('KAA_1', 'SAR_ANT');
    h.eqStr('LOS symmetric', r1.status, r2.status);
    sarInst = sc.installations('SAR_ANT');
    fov = rfscreen.geometry.AntennaToStructureFOV.analyze('SAR_ANT', sarInst.position_m, sarInst.R_BA, p7, struct());
    h.eqStr('FOV without pattern is GEOMETRY_ONLY', fov.validity, 'GEOMETRY_ONLY');
    h.isTrue('ISL bound to data/Xband_ISL', strcmp(RC.ISL.patternStatus, 'BOUND') && ...
        strcmp(RC.ISL.patternDataset, 'data/Xband_ISL'));
    h.isTrue('SAR deferred to closed network, no dataset', ...
        strcmp(RC.SAR_ANT.patternStatus, 'DEFERRED_CLOSED_NETWORK') && isempty(RC.SAR_ANT.patternDataset));
    h.isTrue('SBA / GPSA case-dependent', strcmp(RC.SBA_NADIR.patternStatus, 'CASE_DEPENDENT') && ...
        strcmp(RC.GPSA_1.patternStatus, 'CASE_DEPENDENT'));

    banned = {'gain','loss','s21','attenuation','reflection','diffraction','scatter','isolation'};
    h.isFalse('model has no EM field', anyContains(fieldnames(m), banned));
    h.isFalse('records have no EM field', anyContains(fieldnames(m.installationRecords), banned));
    h.isFalse('panels have no EM field', anyContains(fieldnames(m.panels), banned));

    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    scDir = fullfile(repoRoot, 'src', '+rfscreen', '+spacecraft');
    h.ok('spacecraft creates no pattern objects', isempty(scan(scDir, ...
        {'FreeSpacePattern','InstalledPattern(','SyntheticPatternFactory','PatternGrid','CsvPatternImporter'})));
    h.ok('spacecraft generates no EM loss', isempty(scan(scDir, ...
        {'reflectionCoeff','diffractionLoss','scatteringLoss','fresnel','FreeSpacePathLoss', ...
         'FarFieldCouplingModel','applyBlockage','S21_dB','s21_dB','attenuation_dB','loss_dB'})));
    h.ok('spacecraft does not depend on interference engine', isempty(scan(scDir, {'rfscreen.interference'})));
    otherPkgs = {'+util','+geometry','+antenna','+rf','+coupling','+config','+results','+interference', ...
        '+patterndata','+spectrum','+receiver','+nonlinear','+installed','+scenario'};
    deps = {};
    for i = 1:numel(otherPkgs)
        deps = [deps, scan(fullfile(repoRoot, 'src', '+rfscreen', otherPkgs{i}), {'rfscreen.spacecraft'})]; %#ok<AGROW>
    end
    h.ok('no core package depends on +spacecraft', isempty(deps));
    h.ok('geometry still parses no files (ConvexPolygonGeometry)', ...
        isempty(scan(fullfile(repoRoot, 'src', '+rfscreen', '+geometry', 'ConvexPolygonGeometry.m'), ...
        {'fileread','fopen','csvread','dlmread','textscan'})));

    % ---- dataset validation: corrupted inputs are refused, never repaired ----
    tmp = tempname(); mkdir(tmp);
    srcDir = m.datasetDir;
    fl = {'hull_cross_section.csv','hull_parameters.csv','panels.csv','antenna_installations.csv','steering_constraints.csv'};
    for i = 1:numel(fl); copyfile(fullfile(srcDir, fl{i}), fullfile(tmp, fl{i})); end
    B = @() rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build(tmp);
    txt = fileread(fullfile(srcDir, 'hull_cross_section.csv'));
    writeText(fullfile(tmp, 'hull_cross_section.csv'), strrep(txt, '-783.188191,800.000000', '-790.000000,800.000000'));
    h.throws('perturbed vertex rejected (normal mismatch)', B, 'rfscreen:spacecraft:normalMismatch');
    writeText(fullfile(tmp, 'hull_cross_section.csv'), regexprep(txt, 'V61,[^\r\n]*[\r\n]*', ''));
    h.throws('5-vertex section rejected', B, 'rfscreen:spacecraft:badHull');
    writeText(fullfile(tmp, 'hull_cross_section.csv'), txt);
    htxt = fileread(fullfile(srcDir, 'hull_parameters.csv'));
    writeText(fullfile(tmp, 'hull_parameters.csv'), strrep(htxt, 'd_short_mm,1078.260870', 'd_short_mm,1100.000000'));
    h.throws('design parameter inconsistent with vertices rejected', B, 'rfscreen:spacecraft:designMismatch');
    writeText(fullfile(tmp, 'hull_parameters.csv'), htxt);
    ptxt = fileread(fullfile(srcDir, 'panels.csv'));
    writeText(fullfile(tmp, 'panels.csv'), strrep(ptxt, 'PANEL_1,SIDE,LONG,V61,V12,,0,0,1', 'PANEL_1,SIDE,LONG,V61,V12,,0,0,-1'));
    h.throws('wrong tabulated normal rejected', B, 'rfscreen:spacecraft:normalMismatch');
    writeText(fullfile(tmp, 'panels.csv'), ptxt);
    stxt = fileread(fullfile(srcDir, 'steering_constraints.csv'));
    writeText(fullfile(tmp, 'steering_constraints.csv'), regexprep(stxt, 'KAA_2,[^\r\n]*[\r\n]*', ''));
    h.throws('GIMBAL antenna without steering rejected', B, 'rfscreen:spacecraft:missingSteering');
    writeText(fullfile(tmp, 'steering_constraints.csv'), stxt);
    h.isTrue('restored copy builds', isstruct(B()));
    for i = 1:numel(fl); delete(fullfile(tmp, fl{i})); end
    rmdir(tmp);
end

% ---- helpers ----
function c = sortCols(v)
    c = sortrows(round(v.' * 1e9) / 1e9).';
end
function writeText(p, t)
    fid = fopen(p, 'w'); fwrite(fid, t); fclose(fid);
end
function tf = anyContains(props, needles)
    tf = false;
    for i = 1:numel(props)
        for j = 1:numel(needles)
            if ~isempty(strfind(lower(props{i}), lower(needles{j}))); tf = true; return; end
        end
    end
end
function hits = scan(pathIn, tokens)
    hits = {};
    if exist(pathIn, 'dir') == 7; files = listM(pathIn); else; files = {pathIn}; end
    for i = 1:numel(files)
        if exist(files{i}, 'file') ~= 2; continue; end
        t = fileread(files{i});
        for k = 1:numel(tokens)
            if ~isempty(strfind(t, tokens{k})); hits{end+1} = sprintf('%s in %s', tokens{k}, files{i}); end %#ok<AGROW>
        end
    end
end
function files = listM(d)
    files = {}; items = dir(d);
    for i = 1:numel(items)
        it = items(i);
        if strcmp(it.name, '.') || strcmp(it.name, '..'); continue; end
        p = fullfile(d, it.name);
        if it.isdir; files = [files, listM(p)]; %#ok<AGROW>
        elseif numel(it.name) > 2 && strcmp(it.name(end-1:end), '.m'); files{end+1} = p; end %#ok<AGROW>
    end
end
