%SIMPLIFIED_SPACECRAFT_GEOMETRY Simplified spacecraft baseline v1 -> geometry/FOV/LOS evidence.
%   Workflow (ICD mission_spacecraft.md):
%     load dataset -> Panel #1..#8 SpacecraftStructure -> antenna installation points
%     -> fixed boresights (panel outward normal) + KAA gimbal reference & hemisphere
%     -> register in a Scenario -> run LOS / structure-FOV geometry checks.
%   GEOMETRY EVIDENCE ONLY: no gain loss, S21, attenuation, reflection or diffraction
%   value is produced. Patterns are not loaded here (pattern binding is TBD per antenna).
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(here), 'src'));

m = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
hull = m.hull;
fprintf('Dataset %s  (geometry provenance %s)\n', m.name, m.geometryProvenance);
fprintf('Cross-section: %d vertices, area %.9f m^2, perimeter %.9f m, circumdiameter %.9f m\n', ...
    hull.nVertices(), hull.area(), hull.perimeter(), 2 * hull.circumradius());
fprintf('Prism X = %.3f..%.3f m, volume %.9f m^3, side area %.9f m^2\n\n', ...
    hull.xMin_m, hull.xMax_m, hull.volume(), sum(hull.sideAreas()));

fprintf('%-8s %-7s %-6s %-12s %-34s\n', 'panel', 'kind', 'class', 'width [m]', 'outward normal (B)');
for i = 1:numel(m.panels)
    p = m.panels(i);
    fprintf('%-8s %-7s %-6s %-12.9f [%+.9f %+.9f %+.9f]\n', p.id, p.kind, p.sizeClass, p.width_m, p.normal_B);
end

fprintf('\n%-11s %-26s %-8s %-7s %-12s %-34s %s\n', 'antenna', 'position [m] (as given)', ...
    'panel', 'mount', 'offset [mm]', 'boresight / gimbal reference (B)', 'pattern');
for i = 1:numel(m.installationRecords)
    r = m.installationRecords(i);
    inst = m.installations(r.antennaId);
    fprintf('%-11s [%+.3f %+.3f %+.3f]   %-8s %-7s %+11.3f  [%+.6f %+.6f %+.6f]  %s %s\n', r.antennaId, ...
        r.position_m, r.panelId, r.mountType, 1000 * r.panelNormalOffset_m, inst.R_BA(:, 1), ...
        r.patternStatus, r.patternDataset);
end

% ---- KAA: steering domain, not a fixed boresight ----
fprintf('\nGimbal steering domains (simplified RFC/RFI assumption, not hardware limits):\n');
kids = m.steering.keys();
for i = 1:numel(kids)
    d = m.steering(kids{i});
    U = d.sampleDirections(15);
    fprintf('  %s: %s about [%+.6f %+.6f %+.6f], off-axis <= %g deg, %d sweep samples @15 deg\n', ...
        d.antennaId, d.steeringModel, d.referenceAxis_B, d.maxOffAxis_deg, size(U, 2));
end

% ---- scenario registries + geometry checks ----
sc = rfscreen.scenario.Scenario('SIMPLIFIED_SC_V1');
rfscreen.spacecraft.SimplifiedSpacecraftBuilder.attachToScenario(sc, m);
structs = sc.activeStructures();
ids = {m.installationRecords.antennaId};
fprintf('\nDirect LOS (geometry evidence only):\n');
for i = 1:numel(ids)
    for j = i+1:numel(ids)
        a = sc.installations(ids{i}); b = sc.installations(ids{j});
        los = rfscreen.geometry.LineOfSight.segment(ids{i}, ids{j}, a.position_m, b.position_m, structs);
        fprintf('  %-10s <-> %-10s %-8s %s\n', ids{i}, ids{j}, los.status, strjoin(los.blockingStructureIds, ','));
    end
end

fprintf('\nStructure FOV of the reference orientations (centre off-boresight [deg], centre ray hits):\n');
for i = 1:numel(ids)
    inst = sc.installations(ids{i});
    fprintf('  %-10s', ids{i});
    for k = 1:numel(structs)
        f = rfscreen.geometry.AntennaToStructureFOV.analyze(ids{i}, inst.position_m, inst.R_BA, structs{k}, struct());
        mark = {' ', '*'};
        fprintf(' %s:%5.1f%s', strrep(structs{k}.id, 'PANEL_', 'P'), f.centerOffBoresight_deg, ...
            mark{1 + double(f.centerRayHits)});
    end
    fprintf('\n');
end

% ---- KAA hemisphere sweep hook: FOV evidence per commanded boresight ----
d = m.steering('KAA_1');
base = sc.installations('KAA_1');
U = d.sampleDirections(30);
p7 = sc.structures('PANEL_7');
minOff = Inf;
for k = 1:size(U, 2)
    s = d.steeredInstallation(base, U(:, k));
    f = rfscreen.geometry.AntennaToStructureFOV.analyze('KAA_1', s.position_m, s.R_BA, p7, struct());
    minOff = min(minOff, f.centerOffBoresight_deg);
end
fprintf('\nKAA_1 sweep (%d samples @30 deg): min centre off-boresight to PANEL_7 = %.2f deg\n', size(U, 2), minOff);
