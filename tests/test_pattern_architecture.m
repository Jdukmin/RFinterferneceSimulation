function test_pattern_architecture(h)
%TEST_PATTERN_ARCHITECTURE Phase-2 architecture-boundary guards (VR-121).
    h.setGroup('pattern_arch');
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    srcDir = fullfile(repoRoot, 'src');
    pdDir  = fullfile(srcDir, '+rfscreen', '+patterndata');

    % ---- importer/patterndata has no interference-engine dependency ----
    engineTokens = {'PairwiseAnalyzer', 'InterferenceAnalyzer', 'InterferenceClassifier', ...
                    'RiskLevel', 'PairResult', 'MatrixResult', 'CouplingModel'};
    hitsEngine = scanTokens(pdDir, engineTokens);
    h.ok('patterndata has no interference dep', isempty(hitsEngine));
    if ~isempty(hitsEngine); h.fail('engine tokens in patterndata', strjoin(hitsEngine, '; ')); end

    % ---- CanonicalPatternCut has no file-format dependency ----
    fmtTokens = {'fileread', 'fopen', 'csvread', 'dlmread', 'textscan'};
    hitsFmtCanon = scanTokens(fullfile(pdDir, 'CanonicalPatternCut.m'), fmtTokens);
    h.ok('canonical cut has no file-format dep', isempty(hitsFmtCanon));

    % ---- core interference/coupling/rf/geometry does not parse files ----
    for pkg = {'+interference', '+coupling', '+rf', '+geometry'}
        d = fullfile(srcDir, '+rfscreen', pkg{1});
        hitsCore = scanTokens(d, fmtTokens);
        h.ok(sprintf('%s does not parse files', pkg{1}), isempty(hitsCore));
    end

    % ---- pattern object assumes no global fixed step ----
    globalStepTokens = {'0:0.25:', '0:1:359', '0:0.5:', '361', '721'};
    hitsGlobal = scanTokens(pdDir, globalStepTokens);
    h.ok('no hard-coded global step/count in patterndata', isempty(hitsGlobal));
    if ~isempty(hitsGlobal); h.fail('global-step tokens', strjoin(hitsGlobal, '; ')); end
    % two cuts with different native steps both work (no global grid)
    c025 = quickCut('XZ', -180:0.25:180);
    c1   = quickCut('YZ', -180:1:180);
    h.isFalse('different steps coexist', c025.nominalStep_deg == c1.nominalStep_deg);

    % ---- 2D cut never falsely labeled true 3D ----
    p = rfscreen.patterndata.CutPatternAssembler.assembleFreeSpacePattern( ...
        'SYNTHETIC_TEST_ARCH', quickCut('XZ', -180:1:180), quickCut('YZ', -180:1:180), ...
        struct('frequency_Hz', 2.2e9));
    h.eqStr('assembled 3D labeled APPROX_FROM_CUTS', p.provenance, 'APPROX_FROM_CUTS');
    h.isFalse('cut fidelity is not MEASURED_3D', strcmp(c1.fidelity, 'MEASURED_3D'));

    % ---- duplicate periodic endpoints never silently retained ----
    dupCut = quickCutGain('XZ', [-180 0 180], [-25 5 -25]);
    h.ok('one canonical 180 sample', sum(abs(dupCut.theta_deg - 180) < 1e-9) == 1);
    h.ok('duplicate handling recorded', dupCut.provenance.duplicateHandlingApplied);

    % ---- source +Z convention does not overwrite internal frame contracts ----
    % Phase-1 antenna boresight is still +X_A (unchanged by Phase 2)
    b = rfscreen.geometry.DirectionCalculator.azElToDirection(0, 0);
    h.eqTol('Phase-1 boresight still +X', b, [1;0;0], 1e-12);
    % the source +Z -> antenna +X map is explicit and confined to the assembler
    M = rfscreen.patterndata.CutPatternAssembler.canonicalToAntenna();
    h.eqTol('explicit source +Z -> antenna +X', M*[0;0;1], [1;0;0], 1e-12);
    % core geometry package does not reference the source boresight convention
    hitsLeak = scanTokens(fullfile(srcDir, '+rfscreen', '+geometry'), ...
        {'SourceCoordinateConvention', 'patterndata'});
    h.ok('geometry core free of pattern-source convention', isempty(hitsLeak));
end

function cut = quickCut(plane, theta)
    g = 10 + 20*log10(max(cosd(theta/2).^2, 1e-3));
    cut = quickCutGain(plane, theta, g);
end
function cut = quickCutGain(plane, theta, g)
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane',plane,'angleRange','[-180,180]'));
    imp = rfscreen.patterndata.TablePatternImporter(theta, g, conv, ...
        struct('patternId','SYNTHETIC_TEST_arch','fidelity','SYNTHETIC_TEST','frequency_Hz',2.2e9));
    cut = imp.importCut();
end

function hits = scanTokens(pathIn, tokens)
    hits = {};
    if exist(pathIn, 'dir') == 7
        files = listMFiles(pathIn);
    else
        files = {pathIn};
    end
    for i = 1:numel(files)
        if exist(files{i}, 'file') ~= 2; continue; end
        txt = fileread(files{i});
        for t = 1:numel(tokens)
            if ~isempty(strfind(txt, tokens{t}))
                hits{end+1} = sprintf('%s in %s', tokens{t}, files{i}); %#ok<AGROW>
            end
        end
    end
end

function files = listMFiles(d)
    files = {};
    items = dir(d);
    for i = 1:numel(items)
        it = items(i);
        if strcmp(it.name, '.') || strcmp(it.name, '..'); continue; end
        p = fullfile(d, it.name);
        if it.isdir
            files = [files, listMFiles(p)]; %#ok<AGROW>
        elseif numel(it.name) > 2 && strcmp(it.name(end-1:end), '.m')
            files{end+1} = p; %#ok<AGROW>
        end
    end
end
