classdef MissionCaseBuilder
    %MISSIONCASEBUILDER Build one RFC/RFI analysis case of the simplified spacecraft baseline
    %   (ICD mission_spacecraft.md 9). Orchestration only:
    %     spacecraft geometry (SimplifiedSpacecraftBuilder)
    %     + per-case pattern binding (analysis_cases / antenna_functions / pattern_bindings CSV)
    %     -> EXISTING Phase-2 pipeline (CsvPatternImporter -> CutPatternAssembler)
    %     -> Scenario with structures, installations, antennas (one per RF function), patterns.
    %   No RF transmitter/receiver is created: TX power / bandwidth / receiver data are not in
    %   the dataset and are never invented. Geometry never alters any gain (central rule).
    methods (Static)
        function cases = listCases(datasetDir)
            %LISTCASES Struct array (caseId, sbaVariant, gpsBand, note) from analysis_cases.csv.
            if nargin < 1 || isempty(datasetDir)
                datasetDir = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
            end
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(datasetDir, 'analysis_cases.csv'));
            cases = struct('caseId', T.case_id, 'sbaVariant', T.sba_variant, 'gpsBand', T.gps_band, 'note', T.note);
            if numel(unique(T.case_id)) ~= T.nRows
                error('rfscreen:mission:duplicateId', 'duplicate case id in analysis_cases.csv.');
            end
        end

        function c = buildCase(caseId, opts)
            %BUILDCASE Scenario + bookkeeping for one case.
            %   opts.datasetDir   dataset folder (default simplified_spacecraft_v1)
            %   opts.patternCache containers.Map (pattern_key -> FreeSpacePattern) reused across cases
            %   opts.azStep_deg / opts.elStep_deg  assembly grid (default 2 deg)
            if nargin < 2 || isempty(opts); opts = struct(); end
            MB = rfscreen.mission.MissionCaseBuilder;
            R = rfscreen.spacecraft.SpacecraftDataReader;
            dsDir = MB.opt(opts, 'datasetDir', rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir());
            if isfield(opts, 'patternCache') && isa(opts.patternCache, 'containers.Map')
                cache = opts.patternCache;      % handle: shared across cases (may start empty)
            else
                cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
            end

            cases = MB.listCases(dsDir);
            ci = find(strcmp({cases.caseId}, caseId));
            if isempty(ci)
                error('rfscreen:mission:unknownCase', 'unknown case %s.', caseId);
            end
            cs = cases(ci);
            B = MB.readBindings(fullfile(dsDir, 'pattern_bindings.csv'));
            F = R.readTable(fullfile(dsDir, 'antenna_functions.csv'));

            model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build(dsDir);
            sc = rfscreen.scenario.Scenario(caseId);
            rfscreen.spacecraft.SimplifiedSpacecraftBuilder.attachToScenario(sc, model);

            funcs = struct('functionId', {}, 'installationId', {}, 'role', {}, 'patternKey', {}, ...
                'bindingStatus', {}, 'included', {}, 'frequency_Hz', {}, 'band_Hz', {}, ...
                'fidelity', {}, 'patternSourceFiles', {}, 'note', {});
            warnings = {};
            for r = 1:F.nRows
                fid = F.function_id{r};
                if ~model.installations.isKey(F.installation_id{r})
                    error('rfscreen:mission:badRef', '%s references unknown installation %s.', fid, F.installation_id{r});
                end
                key = MB.resolveSelector(F.pattern_selector{r}, cs);
                f = struct('functionId', fid, 'installationId', F.installation_id{r}, 'role', F.role{r}, ...
                    'patternKey', key, 'bindingStatus', F.binding_status{r}, 'included', ~isempty(key), ...
                    'frequency_Hz', NaN, 'band_Hz', [NaN NaN], 'fidelity', '', 'patternSourceFiles', {{}}, ...
                    'note', F.note{r});
                if isempty(key)
                    warnings{end+1} = sprintf('%s not instantiated (%s): geometry only', fid, F.binding_status{r}); %#ok<AGROW>
                    funcs(end+1) = f; %#ok<AGROW>
                    continue;
                end
                if ~B.isKey(key)
                    error('rfscreen:mission:badRef', '%s: pattern key %s not in pattern_bindings.csv.', fid, key);
                end
                b = B(key);
                if ~cache.isKey(key)
                    cache(key) = MB.assemblePattern(b, opts);
                end
                if ~sc.patterns.isKey(key)
                    sc.addPattern(key, cache(key));
                end
                sc.addAntenna(rfscreen.antenna.Antenna(fid, fid, F.role{r}, b.bandMin_Hz, b.bandMax_Hz, ...
                    b.polarization, key, F.installation_id{r}));
                f.frequency_Hz = b.frequency_Hz; f.band_Hz = [b.bandMin_Hz b.bandMax_Hz];
                f.fidelity = b.fidelity; f.patternSourceFiles = {b.xzPath, b.yzPath};
                if strcmp(F.binding_status{r}, 'CANDIDATE')
                    warnings{end+1} = sprintf('%s uses CANDIDATE pattern %s (binding not confirmed)', fid, key); %#ok<AGROW>
                end
                funcs(end+1) = f; %#ok<AGROW>
            end
            warnings{end+1} = 'no RF transmitter/receiver registered: TX power, bandwidth and receiver data are not in the dataset';

            c = struct('caseId', caseId, 'sbaVariant', cs.sbaVariant, 'gpsBand', cs.gpsBand, ...
                'scenario', sc, 'model', model, 'functions', funcs, 'patternCache', cache);
            c.warnings = warnings;
        end

        function rows = structureFov(c, lobePolicy)
            %STRUCTUREFOV Pattern-aware structure FOV for every instantiated function x panel,
            %   at each installation's reference orientation (KAA: gimbal zero; sweep separately).
            if nargin < 2; lobePolicy = []; end
            sc = c.scenario; structs = sc.activeStructures();
            rows = struct('functionId', {}, 'structureId', {}, 'centerOffBoresight_deg', {}, ...
                'maxAngularRadius_deg', {}, 'closestDistance_m', {}, 'centerLobe', {}, ...
                'occupiedLobes', {}, 'centerRayHits', {}, 'validity', {});
            for i = 1:numel(c.functions)
                f = c.functions(i);
                if ~f.included; continue; end
                inst = sc.installations(f.installationId);
                p = sc.patterns(f.patternKey);
                for k = 1:numel(structs)
                    r = rfscreen.geometry.AntennaToStructureFOV.analyze(f.functionId, inst.position_m, inst.R_BA, ...
                        structs{k}, struct('pattern', p, 'frequency_Hz', f.frequency_Hz, 'lobePolicy', lobePolicy));
                    rows(end+1) = struct('functionId', f.functionId, 'structureId', structs{k}.id, ...
                        'centerOffBoresight_deg', r.centerOffBoresight_deg, ...
                        'maxAngularRadius_deg', r.maxAngularRadius_deg, 'closestDistance_m', r.closestDistance_m, ...
                        'centerLobe', r.centerLobe, 'occupiedLobes', {r.occupiedLobes}, ...
                        'centerRayHits', r.centerRayHits, 'validity', r.validity); %#ok<AGROW>
                end
            end
        end

        function p = assemblePattern(b, opts)
            %ASSEMBLEPATTERN XZ/YZ CSV cuts -> FreeSpacePattern via the existing Phase-2 pipeline.
            if nargin < 2 || isempty(opts); opts = struct(); end
            MB = rfscreen.mission.MissionCaseBuilder;
            cuts = cell(1, 2); planes = {'XZ', 'YZ'}; paths = {b.xzPath, b.yzPath};
            for i = 1:2
                conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane', planes{i}, 'angleRange', '[0,360)'));
                meta = struct('patternId', [b.key '_' planes{i}], 'fidelity', b.fidelity, 'frequency_Hz', b.frequency_Hz);
                cuts{i} = rfscreen.patterndata.CsvPatternImporter(paths{i}, conv, meta).importCut();
            end
            p = rfscreen.patterndata.CutPatternAssembler.assembleFreeSpacePattern(b.key, cuts{1}, cuts{2}, ...
                struct('azStep_deg', MB.opt(opts, 'azStep_deg', 2), 'elStep_deg', MB.opt(opts, 'elStep_deg', 2), ...
                'name', ['APPROX_FROM_CUTS_' b.key], 'polarization', b.polarization));
        end

        function B = readBindings(filePath)
            %READBINDINGS pattern_key -> struct (absolute file paths, Hz, fidelity, polarization).
            R = rfscreen.spacecraft.SpacecraftDataReader;
            T = R.readTable(filePath);
            repo = fileparts(fileparts(fileparts(fileparts(filePath))));   % <repo>/data/spacecraft/<ds>/file
            B = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for r = 1:T.nRows
                k = T.pattern_key{r};
                if B.isKey(k); error('rfscreen:mission:duplicateId', 'duplicate pattern key %s.', k); end
                dsd = fullfile(repo, strrep(T.dataset_dir{r}, '/', filesep));
                b = struct('key', k, 'xzPath', fullfile(dsd, T.xz_file{r}), 'yzPath', fullfile(dsd, T.yz_file{r}), ...
                    'frequency_Hz', 1e6 * R.num(T, 'pattern_freq_mhz', r, k), ...
                    'bandMin_Hz', 1e6 * R.num(T, 'band_min_mhz', r, k), ...
                    'bandMax_Hz', 1e6 * R.num(T, 'band_max_mhz', r, k), ...
                    'fidelity', rfscreen.util.Validate.member(T.fidelity{r}, ...
                        rfscreen.patterndata.PatternFidelity.values(), [k ' fidelity']), ...
                    'polarization', rfscreen.util.Validate.member(T.polarization{r}, ...
                        rfscreen.antenna.Polarization.values(), [k ' polarization']), ...
                    'freqProvenance', T.freq_provenance{r}, 'note', T.note{r});
                B(k) = b;
            end
        end
    end

    methods (Static, Access = private)
        function key = resolveSelector(sel, cs)
            switch sel
                case 'CASE_SBA_TC'; key = [cs.sbaVariant '_TC'];
                case 'CASE_SBA_TM'; key = [cs.sbaVariant '_TM'];
                case 'CASE_GPS';    key = ['GPS_' cs.gpsBand];
                case 'NONE';        key = '';
                otherwise
                    if strncmp(sel, 'FIXED_', 6)
                        key = sel(7:end);
                    else
                        error('rfscreen:mission:badSelector', 'unknown pattern_selector %s.', sel);
                    end
            end
        end
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
    end
end
