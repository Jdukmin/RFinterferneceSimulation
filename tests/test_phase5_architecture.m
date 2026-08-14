function test_phase5_architecture(h)
%TEST_PHASE5_ARCHITECTURE No-fake-physics + boundary guards (VR-408, VR-409).
    h.setGroup('phase5_arch');
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    srcDir = fullfile(repoRoot, 'src', '+rfscreen');
    geomDir = fullfile(srcDir, '+geometry');
    instDir = fullfile(srcDir, '+installed');

    % ---- geometry does not parse pattern files ----
    fileTokens = {'fileread','fopen','csvread','dlmread','textscan','patterndata'};
    h.ok('geometry parses no files', isempty(scan(geomDir, fileTokens)));

    % ---- geometry does not depend on RF receiver physics ----
    rxPhysTokens = {'ReceiverFrontEnd','CompressionAnalyzer','BlockingAnalyzer', ...
                    'IntermodulationAnalyzer','IIP3','p1dB','noisePower','InterferenceCriterion'};
    h.ok('geometry free of receiver physics', isempty(scan(geomDir, rxPhysTokens)));

    % ---- pattern importer computes no structure intersections ----
    pdTokens = {'rayIntersect','SpacecraftStructure','AntennaToStructureFOV','LineOfSight'};
    h.ok('pattern importer computes no intersections', ...
        isempty(scan(fullfile(srcDir, '+patterndata'), pdTokens)));

    % ---- no fake EM: geometry generates no scattering/reflection/diffraction/loss ----
    % (concrete fabricated-EM identifiers + the Phase-1 coupling machinery; the
    %  structural "no loss field" guarantee is checked separately below.)
    fakeEmTokens = {'reflectionCoeff','diffractionLoss','scatteringLoss','fresnel', ...
                    'FreeSpacePathLoss','couplingMetric','FarFieldCouplingModel','applyBlockage'};
    h.ok('geometry generates no EM loss', isempty(scan(geomDir, fakeEmTokens)));

    % ---- no HFSS/CST solver execution anywhere in Phase-5 packages ----
    solverTokens = {'actxserver','system(','dos(','hfssExecute','cstExecute'};
    h.ok('no solver execution in geometry', isempty(scan(geomDir, solverTokens)));
    h.ok('no solver execution in installed', isempty(scan(instDir, solverTokens)));

    % ---- geometry blockage does not modify antenna gain (structural) ----
    % LineOfSightResult carries no gain/loss/attenuation/margin field.
    losProps = properties('rfscreen.results.LineOfSightResult');
    h.isFalse('LOS result has no gain field', anyContains(losProps, {'gain','loss','attenuation','margin','fspl'}));
    fovProps = properties('rfscreen.results.AntennaStructureFOVResult');
    h.isFalse('FOV result has no gain/loss field', anyContains(fovProps, {'gain_dBi','loss','attenuation','margin'}));

    % ---- structure intersection does not create an InstalledPattern ----
    box = rfscreen.geometry.BoxGeometry([0.5;0.5;0.5]);
    st = rfscreen.geometry.SpacecraftStructure('S','SYNTHETIC_TEST','BUS', box, eye(3), [10;0;0], ...
        struct('provenance','SYNTHETIC_TEST'));
    fov = rfscreen.geometry.AntennaToStructureFOV.analyze('A', [0;0;0], eye(3), st, struct());
    h.isTrue('FOV result is geometry evidence', isa(fov, 'rfscreen.results.AntennaStructureFOVResult'));
    h.isFalse('FOV result is NOT a pattern', isa(fov, 'rfscreen.antenna.AntennaPattern'));
    h.ok('geometry never constructs InstalledPattern', isempty(scan(geomDir, {'InstalledPattern'})));

    % ---- blocked LOS is not infinite loss ----
    Rx = rfscreen.geometry.Rotation.aboutY(90);
    panel = rfscreen.geometry.SpacecraftStructure('P','SYNTHETIC_TEST','PANEL', ...
        rfscreen.geometry.PanelGeometry(4,4), Rx, [5;0;0], struct('provenance','SYNTHETIC_TEST'));
    los = rfscreen.geometry.LineOfSight.segment('A','B',[0;0;0],[10;0;0], {panel});
    h.eqStr('LOS blocked', los.status, 'BLOCKED');
    h.isTrue('blocked LOS carries only geometry ids (no loss value)', iscell(los.blockingStructureIds));

    % ---- installed selection does not alter provenance ----
    grid = rfscreen.antenna.PatternGrid(-180:30:180, -90:30:90, 2.2e9, ...
        6*ones(numel(-90:30:90), numel(-180:30:180)));
    inst = rfscreen.antenna.InstalledPattern('SYNTHETIC_TEST_i','APPROX_FROM_CUTS', grid, 'APPROXIMATE');
    free = rfscreen.antenna.SyntheticPatternFactory.isotropic(10, 2.2e9);
    sel = rfscreen.installed.InstalledPatternSelector.select(free, inst, 'PREFER_INSTALLED');
    h.eqStr('selection preserves provenance', sel.provenance, inst.provenance);

    % ---- free-space fallback is explicit ----
    selF = rfscreen.installed.InstalledPatternSelector.select(free, [], 'PREFER_INSTALLED');
    h.eqStr('fallback validity explicit', selF.installationValidity, 'INSTALLATION_EFFECT_UNKNOWN');
    h.isTrue('fallback warns', ~isempty(selF.warnings));

    % ---- geometry risk is not a physical margin ----
    envProps = properties('rfscreen.results.InstalledEnvironmentResult');
    h.isFalse('installed-env result has no physical margin field', ...
        anyContains(envProps, {'margin_dB','iOverN','p1dB','compressionMargin'}));
    h.isTrue('GeometryRisk is a label set (screening)', ...
        iscell(rfscreen.installed.GeometryRisk.values()));

    % ---- Phase-1..4 result semantics unchanged (spot check) ----
    prProps = properties('rfscreen.results.PairResult');
    h.isTrue('PairResult still has couplingModelType', anyExact(prProps, 'couplingModelType'));
    h.isFalse('PairResult gained no blockage field', anyContains(prProps, {'blockage','structureIntersection','losStatus'}));
end

% ---- helpers ----
function tf = anyContains(props, needles)
    tf = false;
    for i = 1:numel(props)
        for j = 1:numel(needles)
            if ~isempty(strfind(lower(props{i}), lower(needles{j}))); tf = true; return; end
        end
    end
end
function tf = anyExact(props, name)
    tf = any(strcmp(props, name));
end
function tf = isemptyCI(c); tf = isempty(c); end
function hits = scan(pathIn, tokens); hits = scanImpl(pathIn, tokens, false); end
function hits = scanCI(pathIn, tokens); hits = scanImpl(pathIn, tokens, true); end
function hits = scanImpl(pathIn, tokens, ci)
    hits = {};
    if exist(pathIn, 'dir') == 7; files = listM(pathIn); else; files = {pathIn}; end
    for i = 1:numel(files)
        if exist(files{i}, 'file') ~= 2; continue; end
        t = fileread(files{i});
        if ci; t = lower(t); end
        for k = 1:numel(tokens)
            tok = tokens{k}; if ci; tok = lower(tok); end
            if ~isempty(strfind(t, tok)); hits{end+1} = sprintf('%s in %s', tokens{k}, files{i}); end %#ok<AGROW>
        end
    end
end
function files = listM(d)
    files = {}; items = dir(d);
    for i = 1:numel(items)
        it = items(i);
        if strcmp(it.name,'.')||strcmp(it.name,'..'); continue; end
        p = fullfile(d, it.name);
        if it.isdir; files = [files, listM(p)]; %#ok<AGROW>
        elseif numel(it.name)>2 && strcmp(it.name(end-1:end),'.m'); files{end+1} = p; end %#ok<AGROW>
    end
end
