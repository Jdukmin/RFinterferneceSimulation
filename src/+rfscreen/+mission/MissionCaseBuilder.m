classdef MissionCaseBuilder
    %MISSIONCASEBUILDER Build one RFC/RFI analysis case of the simplified spacecraft baseline
    %   (ICD mission_spacecraft.md 9). Orchestration only:
    %     spacecraft geometry (SimplifiedSpacecraftBuilder)
    %     + per-case pattern binding (analysis_cases / antenna_functions / pattern_bindings CSV)
    %     -> EXISTING Phase-2 pipeline (CsvPatternImporter -> CutPatternAssembler)
    %     -> Scenario with structures, installations, antennas (one per RF function), patterns.
    %   RF systems (rf_systems.csv, owner-specified baseline) -> RFTransmitter (rectangular
    %   spectrum) and RFReceiver (ideal bandpass filter + NF noise + I_N_MAX criterion).
    %   Unknown P1dB/IIP3 stay NaN (no ReceiverFrontEnd is created). Geometry never alters any
    %   gain (central rule).
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
            %   opts.powerMode    'NOMINAL' (default) | 'SCREENING' (uses tx_power_screen_dbm)
            %   opts.modeId       operating mode (operating_modes.csv); default SCREENING_ALL_TX,
            %                     which is an explicit all-TX stress case, not an operating mode
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
            powerMode = MB.opt(opts, 'powerMode', 'NOMINAL');
            rfSystems = MB.registerRfSystems(sc, funcs, fullfile(dsDir, 'rf_systems.csv'), powerMode);
            for q = 1:numel(rfSystems)
                if ~rfSystems(q).included
                    warnings{end+1} = sprintf('%s not registered (%s)', rfSystems(q).systemId, rfSystems(q).bindingStatus); %#ok<AGROW>
                end
            end
            warnings{end+1} = 'receiver P1dB/IIP3 unknown (NaN): nonlinear analyses report MISSING_P1DB/MISSING_IIP3';
            warnings{end+1} = 'GPS acceptance uses a temporary thermal I/N criterion; final GNSS acceptance needs C/N0 or J/S';
            [mode, mwarn] = MB.applyMode(sc, rfSystems, MB.opt(opts, 'modeId', 'SCREENING_ALL_TX'), ...
                fullfile(dsDir, 'operating_modes.csv'), fullfile(dsDir, 'rf_systems.csv'));
            warnings = [warnings, mwarn]; %#ok<AGROW>

            c = struct('caseId', caseId, 'sbaVariant', cs.sbaVariant, 'gpsBand', cs.gpsBand, ...
                'scenario', sc, 'model', model, 'functions', funcs, 'rfSystems', rfSystems, 'mode', mode, ...
                'powerMode', powerMode, 'patternCache', cache);
            c.warnings = warnings;
        end

        function modes = listModes(datasetDir)
            %LISTMODES Struct array (modeId, kind, status, activeTx, activeRx, description).
            if nargin < 1 || isempty(datasetDir)
                datasetDir = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
            end
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(datasetDir, 'operating_modes.csv'));
            modes = struct('modeId', {}, 'kind', {}, 'status', {}, 'activeTx', {}, 'activeRx', {}, 'description', {});
            for r = 1:T.nRows
                modes(end+1) = struct('modeId', T.mode_id{r}, 'kind', T.kind{r}, 'status', T.status{r}, ...
                    'activeTx', {rfscreen.mission.MissionCaseBuilder.splitList(T.active_tx{r})}, ...
                    'activeRx', {rfscreen.mission.MissionCaseBuilder.splitList(T.active_rx{r})}, ...
                    'description', T.description{r}); %#ok<AGROW>
            end
            if numel(unique({modes.modeId})) ~= numel(modes)
                error('rfscreen:mission:duplicateId', 'duplicate mode id in operating_modes.csv.');
            end
        end

        function [mode, warn] = applyMode(sc, rfSystems, modeId, modesFile, rfFile)
            %APPLYMODE Set the scenario's active TX/RX sets and operatingModeId from a mode.
            MB = rfscreen.mission.MissionCaseBuilder;
            V = rfscreen.util.Validate;
            modes = MB.listModes(fileparts(modesFile));
            mi = find(strcmp({modes.modeId}, modeId));
            if isempty(mi)
                error('rfscreen:mission:unknownMode', 'unknown operating mode %s.', modeId);
            end
            m = modes(mi);
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(rfFile);
            known = struct('TX', {T.system_id(strcmp(T.kind, 'TX'))}, 'RX', {T.system_id(strcmp(T.kind, 'RX'))});
            V.member(m.kind, {'SCREENING', 'NOMINAL'}, [modeId ' kind']);
            warn = {};
            regTx = sc.transmitters.keys(); regRx = sc.receivers.keys();
            if strcmp(m.kind, 'SCREENING') || (isscalar(m.activeTx) && strcmp(m.activeTx{1}, 'ALL') ...
                    && isscalar(m.activeRx) && strcmp(m.activeRx{1}, 'ALL'))
                sc.activeTxIds = {}; sc.activeRxIds = {};     % {} = all registered
                txIds = regTx; rxIds = regRx;
            else
                for k = 1:numel(m.activeTx)
                    if ~any(strcmp(known.TX, m.activeTx{k}))
                        error('rfscreen:mission:badRef', 'mode %s lists unknown TX %s.', modeId, m.activeTx{k});
                    end
                end
                for k = 1:numel(m.activeRx)
                    if ~any(strcmp(known.RX, m.activeRx{k}))
                        error('rfscreen:mission:badRef', 'mode %s lists unknown RX %s.', modeId, m.activeRx{k});
                    end
                end
                txIds = m.activeTx(ismember(m.activeTx, regTx));
                rxIds = m.activeRx(ismember(m.activeRx, regRx));
                skipped = [m.activeTx(~ismember(m.activeTx, regTx)), m.activeRx(~ismember(m.activeRx, regRx))];
                if ~isempty(skipped)
                    warn{end+1} = sprintf('mode %s: not registered in this case, skipped: %s', modeId, strjoin(skipped, ', '));
                end
                if isempty(txIds) || isempty(rxIds)
                    error('rfscreen:mission:emptyMode', 'mode %s leaves no active TX or no active RX in this case.', modeId);
                end
                sc.activeTxIds = txIds; sc.activeRxIds = rxIds;
            end
            sc.operatingModeId = modeId;
            if strcmp(m.kind, 'SCREENING')
                warn{end+1} = sprintf('%s: stress case, every registered TX active at once (%d TX, %d RX); not an operating mode', ...
                    modeId, numel(txIds), numel(rxIds));
            else
                warn{end+1} = sprintf('%s: operating-mode template, status %s', modeId, m.status);
            end
            mode = struct('modeId', modeId, 'kind', m.kind, 'status', m.status, 'isScreening', strcmp(m.kind, 'SCREENING'), ...
                'activeTxIds', {txIds}, 'activeRxIds', {rxIds}, 'description', m.description);
        end

        function sys = registerRfSystems(sc, funcs, filePath, powerMode)
            %REGISTERRFSYSTEMS rf_systems.csv -> RFTransmitter / RFReceiver on the scenario.
            %   Systems whose antenna function is not instantiated are returned with
            %   included = false and are not registered.
            R = rfscreen.spacecraft.SpacecraftDataReader;
            V = rfscreen.util.Validate;
            V.member(powerMode, {'NOMINAL', 'SCREENING'}, 'powerMode');
            T = R.readTable(filePath);
            numOrNaN = @(c) str2double(c);
            sys = struct('systemId', {}, 'templateId', {}, 'functionId', {}, 'kind', {}, 'included', {}, ...
                'bindingStatus', {}, 'fc_Hz', {}, 'bw_Hz', {}, 'power_dBm', {}, 'noiseFigure_dB', {}, ...
                'iOverNMax_dB', {}, 'noise_dBm', {}, 'allowableInterference_dBm', {}, ...
                'p1dB_in_dBm', {}, 'iip3_in_dBm', {});
            incl = {funcs([funcs.included]).functionId};
            keyOf = containers.Map({funcs.functionId}, {funcs.patternKey});
            for r = 1:T.nRows
                sid = T.system_id{r}; fid = T.function_id{r};
                fc = 1e6 * R.num(T, 'fc_mhz', r, sid); bw = 1e6 * R.num(T, 'bw_mhz', r, sid);
                s = struct('systemId', sid, 'templateId', T.template_id{r}, 'functionId', fid, ...
                    'kind', T.kind{r}, 'included', any(strcmp(incl, fid)), 'bindingStatus', T.binding_status{r}, ...
                    'fc_Hz', fc, 'bw_Hz', bw, 'power_dBm', NaN, 'noiseFigure_dB', NaN, 'iOverNMax_dB', NaN, ...
                    'noise_dBm', NaN, 'allowableInterference_dBm', NaN, 'p1dB_in_dBm', NaN, 'iip3_in_dBm', NaN);
                req = T.requires_pattern_key{r};
                if s.included && ~isempty(req) && ~strcmp(keyOf(fid), req)
                    s.included = false; s.bindingStatus = 'NO_BASELINE_FOR_CASE';
                end
                pol = V.member(T.polarization{r}, rfscreen.antenna.Polarization.values(), [sid ' polarization']);
                switch T.kind{r}
                    case 'TX'
                        pw = numOrNaN(T.tx_power_dbm{r});
                        if strcmp(powerMode, 'SCREENING') && ~isempty(T.tx_power_screen_dbm{r})
                            pw = numOrNaN(T.tx_power_screen_dbm{r});
                        end
                        if ~isfinite(pw); error('rfscreen:mission:badRf', '%s: tx_power_dbm missing.', sid); end
                        s.power_dBm = pw;
                        if s.included
                            spec = rfscreen.spectrum.RectangularSpectrum(fc, bw, pw, ...
                                struct('provenance', rfscreen.spectrum.SpectrumProvenance.IDEAL_MODEL));
                            sc.addTransmitter(rfscreen.rf.RFTransmitter(sid, fid, fc, bw, pw, ...
                                struct('polarization', pol, 'spectrum', spec)));
                        end
                    case 'RX'
                        nf = numOrNaN(T.nf_db{r}); inmax = numOrNaN(T.i_n_max_db{r});
                        if ~(isfinite(nf) && isfinite(inmax))
                            error('rfscreen:mission:badRf', '%s: nf_db / i_n_max_db missing.', sid);
                        end
                        nm = rfscreen.receiver.ReceiverNoiseModel(struct('noiseFigure_dB', nf, ...
                            'provenance', 'ENGINEERING_ASSUMPTION'));
                        n_dBm = rfscreen.util.Units.w2dbm(nm.noisePower_W(bw));
                        s.noiseFigure_dB = nf; s.iOverNMax_dB = inmax;
                        s.noise_dBm = n_dBm; s.allowableInterference_dBm = n_dBm + inmax;
                        p1 = numOrNaN(T.p1db_in_dbm{r}); ip3 = numOrNaN(T.iip3_in_dbm{r});
                        s.p1dB_in_dBm = p1; s.iip3_in_dBm = ip3;
                        if s.included
                            filt = rfscreen.receiver.IdealBandpassFilter([fc - bw/2, fc + bw/2], 0, -Inf);
                            crit = rfscreen.receiver.InterferenceCriterion('I_N_MAX', inmax, ...
                                struct('provenance', 'ENGINEERING_ASSUMPTION'));
                            ro = struct('polarization', pol, 'filter', filt, 'noiseModel', nm, 'interferenceCriterion', crit);
                            if isfinite(p1) || isfinite(ip3)
                                fprov = T.frontend_prov{r};
                                if isempty(fprov)
                                    error('rfscreen:mission:badRf', '%s: p1dB/iip3 given without frontend_prov.', sid);
                                end
                                fo = struct('noiseFigure_dB', nf, 'provenance', fprov);
                                if isfinite(p1); fo.p1dB_in_dBm = p1; end
                                if isfinite(ip3); fo.iip3_in_dBm = ip3; end
                                ro.receiverFrontEnd = rfscreen.receiver.ReceiverFrontEnd(fo);
                            end
                            sc.addReceiver(rfscreen.rf.RFReceiver(sid, fid, fc, bw, ro));
                        end
                    otherwise
                        error('rfscreen:mission:badRf', '%s: kind must be TX or RX.', sid);
                end
                sys(end+1) = s; %#ok<AGROW>
            end
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
        function c = splitList(s)
            if isempty(s); c = {}; return; end
            idx = [0, strfind(s, ';'), numel(s) + 1];
            c = cell(1, numel(idx) - 1);
            for k = 1:numel(idx) - 1
                c{k} = strtrim(s(idx(k) + 1 : idx(k + 1) - 1));
            end
        end
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
