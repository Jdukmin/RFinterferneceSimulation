classdef CalPatternCatalog
    %CALPATTERNCATALOG Scan data/cal/{gps,isl,kaa,sba}/*.txt, recognise the owner naming convention,
    %   validate every file with CstAscii3DImporter and build one native pattern object per
    %   (file, canonical frequency).
    %
    %   Owner naming convention (explicit; nothing else is inferred from a filename):
    %     gps/GPSA_ORIGINAL_f1.2   free-space, generic GPS, shared by L5 / L2 / L1
    %     gps/GPSA_GPSA1_f1.2      installed on GPSA_1, shared by L5 / L2 / L1
    %     gps/GPSA_GPSA2_f1.2      installed on GPSA_2, shared by L5 / L2 / L1
    %     isl/RFC_ISL_f<tok>      free-space ISL at <tok>
    %     kaa/RFC_KAA_f<tok>      free-space KAA (reflector included) at <tok>
    %     sba/RFC_SBA_f<tok>      free-space generic SBA at <tok>
    %     sba/RFC_SBA_NADIR_f<tok> / RFC_SBA_ZENITH_f<tok>   installed on SBA_NADIR / SBA_ZENITH
    %   <tok> must be listed in cal_frequency_aliases.csv. GPS "f1.2" = the single CST solve (~1.2 GHz); it
    %   is never an evaluation plane: the one spatial pattern is bound as a SURROGATE at L5 / L2 / L1.
    %   Entry status: VALID | UNRECOGNIZED_NAME | WRONG_FOLDER | UNMAPPED_FREQUENCY | READ_ERROR |
    %   PARSE_ERROR | GRID_VALIDATION_ERROR | DUPLICATE_BINDING | PATTERN_CONSTRUCTION_ERROR.
    %   Only VALID entries are bound; every entry carries e.diag (rfscreen.cal.CalIngestDiagnostics: failing
    %   stage, error identifier / message / line, theta / phi / sample statistics) for the inventory.
    %   Source frame: FREE_SPACE = CST_LOCAL; INSTALLED = SPACECRAFT_BODY_FIXED (mount R_BA from the SSOT
    %   model, passed as scan(..., model) or built from SimplifiedSpacecraftBuilder when needed).
    properties (Constant)
        FOLDERS = {'gps', 'isl', 'kaa', 'sba'}
    end
    properties (SetAccess = private)
        calDir = ''
        entries = struct([])
        patterns            % containers.Map key -> CstNative*Pattern (key = patternKey())
        discovery = {}      % file_discovery notes (ignored files / folders), cellstr
    end
    methods (Static)
        function c = scan(calDir, freqMap, model)
            if nargin < 3; model = []; end
            D = rfscreen.cal.CalIngestDiagnostics;
            c = rfscreen.cal.CalPatternCatalog();
            c.calDir = calDir;
            c.patterns = containers.Map('KeyType', 'char', 'ValueType', 'any');
            E = struct('file', {}, 'relPath', {}, 'folder', {}, 'stem', {}, 'family', {}, 'installationId', {}, ...
                'patternType', {}, 'token', {}, 'freqs_Hz', {}, 'freqLabels', {}, 'status', {}, 'message', {}, ...
                'data', {}, 'keys', {}, 'sourceFrame', {}, 'sourceSimulationFrequency_Hz', {}, ...
                'frequencyTreatment', {}, 'diag', {});
            if exist(calDir, 'dir') ~= 7
                c.entries = E;
                c.discovery = {sprintf('CAL directory not found: %s', calDir)};
                return;
            end
            F = rfscreen.cal.CalPatternCatalog.FOLDERS;
            notes = rfscreen.cal.CalPatternCatalog.discoveryNotes(calDir);
            for i = 1:numel(F)
                d = fullfile(calDir, F{i});
                if exist(d, 'dir') ~= 7
                    notes{end+1} = sprintf('%s/ folder absent', F{i}); %#ok<AGROW>
                    continue;
                end
                L = dir(d);
                sub = L([L.isdir] & ~ismember({L.name}, {'.', '..'}));
                for j = 1:numel(sub)
                    notes{end+1} = sprintf('%s/%s/ sub-folder ignored (files are read from %s/ only)', F{i}, sub(j).name, F{i}); %#ok<AGROW>
                end
                L = L(~[L.isdir]);
                names = sort({L.name});
                names = names(~strncmp(names, '.', 1));          % hidden files (.gitkeep) are not inputs
                [~, ~, exts] = cellfun(@fileparts, names, 'UniformOutput', false);
                if ~any(strcmpi(exts, '.txt'))
                    notes{end+1} = sprintf('%s/ holds no .txt file (INPUT_MISSING for this family)', F{i}); %#ok<AGROW>
                end
                for j = 1:numel(names)
                    [~, stem, ext] = fileparts(names{j});
                    if ~strcmpi(ext, '.txt')
                        notes{end+1} = sprintf('%s/%s ignored (not a .txt file)', F{i}, names{j}); %#ok<AGROW>
                        continue;
                    end
                    e = rfscreen.cal.CalPatternCatalog.classify(stem, F{i}, freqMap);
                    e.file = fullfile(d, names{j}); e.relPath = [F{i} '/' names{j}];
                    E(end+1) = e; %#ok<AGROW>
                end
            end
            c.discovery = notes;
            % Duplicate bindings (same family / installation / type / frequency): none is chosen.
            for a = 1:numel(E)
                if ~strcmp(E(a).status, 'VALID'); continue; end
                for b = a+1:numel(E)
                    if strcmp(E(b).status, 'VALID') && strcmp(E(a).family, E(b).family) && ...
                            strcmp(E(a).installationId, E(b).installationId) && strcmp(E(a).patternType, E(b).patternType) && ...
                            any(ismember(round(E(a).freqs_Hz), round(E(b).freqs_Hz)))
                        msg = sprintf('same binding as %s and %s: neither is used', E(a).relPath, E(b).relPath);
                        E(a).status = 'DUPLICATE_BINDING'; E(a).message = msg;
                        E(b).status = 'DUPLICATE_BINDING'; E(b).message = msg;
                        E(a).diag = D.fail(E(a).diag, 'DUPLICATE_BINDING', 'catalog_binding', '', msg, NaN);
                        E(b).diag = D.fail(E(b).diag, 'DUPLICATE_BINDING', 'catalog_binding', '', msg, NaN);
                    end
                end
            end
            % Read / parse / validate (only recognised, uniquely bound files), stage by stage.
            for a = 1:numel(E)
                if ~strcmp(E(a).status, 'VALID'); continue; end
                [E(a).data, dg] = D.readFile(E(a).file);
                E(a).diag = dg;
                if ~isempty(dg.status)
                    E(a).status = dg.status;
                    E(a).message = sprintf('%s: %s (%s)', dg.failure_stage, dg.error_message, dg.error_identifier);
                    continue;
                end
                if ~isempty(E(a).data.warnings)
                    E(a).message = strjoin(E(a).data.warnings, '; ');
                end
                % pattern_construction (installed: body-frame raw grid + SSOT mount R_BA)
                try
                    meta = struct('family', E(a).family, 'installationId', E(a).installationId, ...
                        'sourceSimulationFrequency_Hz', E(a).sourceSimulationFrequency_Hz, ...
                        'frequencyTreatment', E(a).frequencyTreatment);
                    if strcmp(E(a).patternType, 'INSTALLED')
                        if isempty(model); model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build(); end
                        if ~model.installations.isKey(E(a).installationId)
                            error('rfscreen:cal:unknownInstallation', '%s is not an installation of the spacecraft model.', ...
                                E(a).installationId);
                        end
                        meta.R_BA = model.installations(E(a).installationId).R_BA;
                    end
                    P = cell(1, numel(E(a).freqs_Hz));
                    for k = 1:numel(E(a).freqs_Hz)
                        name = sprintf('CAL_%s_%s', E(a).stem, E(a).freqLabels{k});
                        if strcmp(E(a).patternType, 'INSTALLED')
                            P{k} = rfscreen.cal.CstNativeInstalledPattern(name, E(a).data, E(a).freqs_Hz(k), meta);
                        else
                            P{k} = rfscreen.cal.CstNativeFreeSpacePattern(name, E(a).data, E(a).freqs_Hz(k), meta);
                        end
                    end
                catch err
                    E(a).diag = D.fail(E(a).diag, 'PATTERN_CONSTRUCTION_ERROR', 'pattern_construction', err.identifier, err.message, NaN);
                    E(a).status = 'PATTERN_CONSTRUCTION_ERROR';
                    E(a).message = sprintf('pattern_construction: %s (%s)', err.message, err.identifier);
                    continue;
                end
                E(a).diag.last_stage_completed = 'pattern_construction';
                % catalog_binding
                for k = 1:numel(E(a).freqs_Hz)
                    key = rfscreen.cal.CalPatternCatalog.patternKey(E(a).family, E(a).installationId, ...
                        E(a).patternType, E(a).freqs_Hz(k));
                    c.patterns(key) = P{k};
                    E(a).keys{end+1} = key;
                end
                E(a).diag.last_stage_completed = 'catalog_binding';
                E(a).diag.status = 'VALID';
            end
            c.entries = E;
        end

        function notes = discoveryNotes(calDir)
            %DISCOVERYNOTES .txt files directly under calDir and unknown sub-folders (never read).
            notes = {};
            L = dir(calDir);
            for k = 1:numel(L)
                n = L(k).name;
                if any(strcmp(n, {'.', '..'})); continue; end
                if L(k).isdir
                    if ~any(strcmp(n, rfscreen.cal.CalPatternCatalog.FOLDERS))
                        notes{end+1} = sprintf('%s/ is not a CAL family folder (gps, isl, kaa, sba): not scanned', n); %#ok<AGROW>
                    end
                else
                    [~, ~, ext] = fileparts(n);
                    if strcmpi(ext, '.txt')
                        notes{end+1} = sprintf('%s sits directly in the CAL root: not scanned (place it in gps/isl/kaa/sba)', n); %#ok<AGROW>
                    end
                end
            end
        end

        function key = patternKey(family, installationId, patternType, f_Hz)
            if isempty(installationId); installationId = 'GENERIC'; end
            key = sprintf('%s|%s|%s|%.0f', family, installationId, patternType, round(f_Hz));
        end

        function e = classify(stem, folder, freqMap)
            D = rfscreen.cal.CalIngestDiagnostics;
            e = struct('file', '', 'relPath', '', 'folder', folder, 'stem', stem, 'family', '', 'installationId', '', ...
                'patternType', '', 'token', '', 'freqs_Hz', [], 'freqLabels', {{}}, 'status', 'VALID', 'message', '', ...
                'data', [], 'keys', {{}}, 'sourceFrame', '', 'sourceSimulationFrequency_Hz', NaN, ...
                'frequencyTreatment', '', 'diag', D.blank());
            e.diag.last_stage_completed = 'file_discovery';
            tok = regexpi(stem, '^GPSA_(ORIGINAL|GPSA1|GPSA2)_f1\.2$', 'tokens', 'once');
            if ~isempty(tok)
                e.family = 'GPS'; e.token = '1.2';
                switch upper(tok{1})
                    case 'ORIGINAL'; e.patternType = 'FREE_SPACE';
                    case 'GPSA1';    e.patternType = 'INSTALLED'; e.installationId = 'GPSA_1';
                    case 'GPSA2';    e.patternType = 'INSTALLED'; e.installationId = 'GPSA_2';
                end
                [e.freqs_Hz, e.freqLabels] = freqMap.gpsCommon();
                % One CST solve at ~1.2 GHz (filename token) reused as a surrogate at L5 / L2 / L1.
                e.sourceSimulationFrequency_Hz = 1.2e9; e.frequencyTreatment = 'SURROGATE';
            else
                t2 = regexpi(stem, '^RFC_SBA_(NADIR|ZENITH)_f([0-9]+(\.[0-9]+)?)$', 'tokens', 'once');
                t1 = regexpi(stem, '^RFC_(ISL|KAA|SBA)_f([0-9]+(\.[0-9]+)?)$', 'tokens', 'once');
                if ~isempty(t2)
                    e.family = 'SBA'; e.patternType = 'INSTALLED'; e.installationId = ['SBA_' upper(t2{1})]; e.token = t2{2};
                elseif ~isempty(t1)
                    e.family = upper(t1{1}); e.patternType = 'FREE_SPACE'; e.token = t1{2};
                else
                    e.status = 'UNRECOGNIZED_NAME';
                    e.message = 'filename does not follow the CAL naming convention: not used';
                    e.diag = D.fail(e.diag, e.status, 'filename_classification', '', e.message, NaN);
                    return;
                end
                e.sourceFrame = rfscreen.cal.CalPatternCatalog.frameOf(e.patternType);
                [ok, f, lab] = freqMap.resolve(e.token);
                if ~ok
                    e.status = 'UNMAPPED_FREQUENCY';
                    e.message = sprintf('frequency token %s is not in cal_frequency_aliases.csv: not used (no extrapolation)', e.token);
                    e.diag = D.fail(e.diag, e.status, 'frequency_binding', '', e.message, NaN);
                    e.diag.last_stage_completed = 'filename_classification';
                    return;
                end
                e.freqs_Hz = f; e.freqLabels = {lab};
                e.sourceSimulationFrequency_Hz = str2double(e.token) * 1e9; e.frequencyTreatment = 'NATIVE_PLANE';
            end
            e.sourceFrame = rfscreen.cal.CalPatternCatalog.frameOf(e.patternType);
            if ~strcmpi(folder, e.family)
                e.status = 'WRONG_FOLDER';
                e.message = sprintf('%s file found in %s/: not used', e.family, folder);
                e.diag = D.fail(e.diag, e.status, 'filename_classification', '', e.message, NaN);
                return;
            end
            e.diag.last_stage_completed = 'frequency_binding';
        end

        function f = frameOf(patternType)
            %FRAMEOF Raw CST source frame of a pattern type.
            if strcmp(patternType, 'INSTALLED'); f = 'SPACECRAFT_BODY_FIXED'; else; f = 'CST_LOCAL'; end
        end
    end

    methods
        function [p, key] = find(c, family, installationId, patternType, f_Hz)
            %FIND Pattern object or [] (exact canonical frequency only).
            key = rfscreen.cal.CalPatternCatalog.patternKey(family, installationId, patternType, f_Hz);
            if c.patterns.isKey(key); p = c.patterns(key); else; p = []; end
        end

        function n = nValid(c)
            if isempty(c.entries); n = 0; return; end
            n = sum(strcmp({c.entries.status}, 'VALID'));
        end
    end
end
