classdef CalRunner
    %CALRUNNER main('--cal'): data/cal CST ASCII -> validation -> catalog -> binding -> plots -> RFI -> exports.
    %   opts (all optional): repoRoot, calDir (default <repo>/data/cal), configDir (<repo>/data/cal_config),
    %   outDir (<repo>/output/cal), plots (true), clean (true: remove this runner's stale png/csv/txt in outDir),
    %   verbose (true).
    %   Missing CST input is reported as INPUT_MISSING; no synthetic pattern is ever substituted.
    properties (Constant)
        OUT_SUBDIRS = {'validation', 'pattern_plots', 'installed_plots', 'rfi'}
    end
    methods (Static)
        function res = run(opts)
            if nargin < 1; opts = struct(); end
            C = rfscreen.cal.CalRunner;
            here = fileparts(mfilename('fullpath'));
            repo = C.opt(opts, 'repoRoot', fileparts(fileparts(fileparts(here))));
            calDir = C.opt(opts, 'calDir', fullfile(repo, 'data', 'cal'));
            cfg = C.opt(opts, 'configDir', fullfile(repo, 'data', 'cal_config'));
            out = C.opt(opts, 'outDir', fullfile(repo, 'output', 'cal'));
            doPlots = C.opt(opts, 'plots', true);
            verbose = C.opt(opts, 'verbose', true);
            say = @(varargin) C.say(verbose, varargin{:});
            t0 = clock();

            if C.opt(opts, 'clean', true); C.cleanOutputs(out); end
            for i = 1:numel(C.OUT_SUBDIRS)
                d = fullfile(out, C.OUT_SUBDIRS{i}); if exist(d, 'dir') ~= 7; mkdir(d); end
            end
            say('[CAL] 1/11 paths ready (repo %s)', repo);

            % 2-4. scan, validate, catalog
            model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
            fmap = rfscreen.cal.CalFrequencyMap.load(fullfile(cfg, 'cal_frequency_aliases.csv'), ...
                fullfile(model.datasetDir, 'rf_systems.csv'));
            say('[CAL] 2/11 scanning %s', calDir);
            cat = rfscreen.cal.CalPatternCatalog.scan(calDir, fmap);
            nFiles = numel(cat.entries); nValid = cat.nValid();
            say('[CAL] 3/11 validated %d CST ASCII file(s): %d valid, %d not used', nFiles, nValid, nFiles - nValid);
            invFile = fullfile(out, 'validation', 'pattern_inventory.csv');
            C.writeInventory(invFile, cat, calDir);
            say('[CAL] 4/11 catalog: %d pattern plane(s) (inventory %s)', cat.patterns.Count, invFile);

            % 5. binding
            binder = rfscreen.cal.CalPatternBinder(cat, fullfile(cfg, 'cal_installations.csv'));
            bindFile = fullfile(out, 'validation', 'pattern_binding.csv');
            C.writeBinding(bindFile, binder, fmap, cfg, calDir);
            say('[CAL] 5/11 bindings written (%s)', bindFile);

            % 6-8. figures
            figs = struct('pattern', {{}}, 'installed3d', {{}}, 'bodyCuts', {{}}, 'failed', {{}});
            plotsOk = doPlots && nValid > 0 && rfscreen.cal.CalPlotter.setupGraphics();
            if doPlots && nValid > 0 && ~plotsOk
                say('[CAL] WARNING: no graphics toolkit available - figures skipped');
            end
            if plotsOk
                figs = C.makeFigures(cat, model, out, say);
            else
                say('[CAL] 6-8/11 figures skipped (%s)', C.ternary(nValid == 0, 'no valid CST pattern', 'plots disabled'));
            end

            % 9-10. RFI
            say('[CAL] 9/11 CAL interference analysis (existing VictimBandCoupling / PsdMath path)');
            rows = rfscreen.cal.CalRfiAnalyzer.run(repo, cat, binder, model, fmap, cfg);
            for k = 1:numel(rows)
                rows(k).tx_pattern_file = C.relTo(rows(k).tx_pattern_file, calDir);
                rows(k).rx_pattern_file = C.relTo(rows(k).rx_pattern_file, calDir);
            end
            summary = C.summarize(rows);
            C.writeStructCsv(fullfile(out, 'rfi', 'pair_results.csv'), rows);
            C.writeStructCsv(fullfile(out, 'rfi', 'summary.csv'), summary);
            txt = C.runSummaryText(cat, rows, summary, figs, calDir, out, etime(clock(), t0));
            fid = fopen(fullfile(out, 'rfi', 'run_summary.txt'), 'w');
            fprintf(fid, '%s', txt); fclose(fid);
            say('[CAL] 10/11 exported rfi/pair_results.csv (%d rows), rfi/summary.csv, rfi/run_summary.txt', numel(rows));
            say('[CAL] 11/11 summary:');
            if verbose; fprintf('%s', txt); end

            res = struct('catalog', cat, 'binder', binder, 'rows', rows, 'summary', summary, 'figures', figs, ...
                'outDir', out, 'model', model, 'freqMap', fmap, 'runSummary', txt);
        end

        function figs = makeFigures(cat, model, out, say)
            P = rfscreen.cal.CalPlotter;
            figs = struct('pattern', {{}}, 'installed3d', {{}}, 'bodyCuts', {{}}, 'failed', {{}});
            E = cat.entries;
            for a = 1:numel(E)
                if ~strcmp(E(a).status, 'VALID'); continue; end
                p = cat.patterns(E(a).keys{1});
                ttl = sprintf('%s [%s, %s]', E(a).stem, E(a).patternType, strjoin(E(a).freqLabels, '/'));
                try
                    f = P.planeCuts(p.native, ttl, fullfile(out, 'pattern_plots', lower(E(a).folder), E(a).stem));
                    figs.pattern = [figs.pattern f];
                catch err
                    figs.failed{end+1} = sprintf('%s XZ/YZ: %s', E(a).stem, err.message);
                end
            end
            say('[CAL] 6/11 pattern-coordinate XZ/YZ figures: %d', numel(figs.pattern));
            for a = 1:numel(E)
                if ~strcmp(E(a).status, 'VALID') || ~strcmp(E(a).patternType, 'INSTALLED'); continue; end
                p = cat.patterns(E(a).keys{1});
                base = rfscreen.cal.CalRunner.installedName(E(a));
                ttl = sprintf('%s on %s (%s)', E(a).stem, E(a).installationId, strjoin(E(a).freqLabels, '/'));
                try
                    figs.installed3d{end+1} = P.installed3D(model, E(a).installationId, p, ttl, ...
                        fullfile(out, 'installed_plots', '3d', [base '_INSTALLED_3D.png']));
                catch err
                    figs.failed{end+1} = sprintf('%s 3D: %s', base, err.message);
                end
                try
                    fb = P.bodyCuts(model, E(a).installationId, p, E(a).freqs_Hz(1), ttl, ...
                        fullfile(out, 'installed_plots', 'body_cuts', base));
                    figs.bodyCuts = [figs.bodyCuts fb];
                catch err
                    figs.failed{end+1} = sprintf('%s body cuts: %s', base, err.message);
                end
            end
            say('[CAL] 7/11 installed spacecraft 3D figures: %d', numel(figs.installed3d));
            say('[CAL] 8/11 installed body XZ/YZ/XY figures: %d', numel(figs.bodyCuts));
            for k = 1:numel(figs.failed); say('[CAL] WARNING figure not produced: %s', figs.failed{k}); end
        end

        function n = installedName(e)
            %INSTALLEDNAME GPSA1_L1L2L5 (band-common GPS pattern) | SBA_NADIR_2p06.
            if strcmp(e.family, 'GPS')
                n = sprintf('%s_%s', strrep(e.installationId, '_', ''), strjoin(fliplr(e.freqLabels), ''));
            else
                n = sprintf('%s_%s', e.installationId, e.freqLabels{1});
            end
        end

        function S = summarize(rows)
            S = struct([]);
            if isempty(rows); return; end
            keys = strcat({rows.victim_band}, '|', {rows.frequency_label}, '|', {rows.rx_installation});
            [u, first, j] = unique(keys);            % (no 'stable' 3rd output in Octave)
            [~, order] = sort(first);
            for k = order(:).'
                R = rows(j == k);
                ev = strcmp({R.status}, 'EVALUATED');
                m = [R.margin_db];
                s = struct('victim_band', R(1).victim_band, 'frequency_label', R(1).frequency_label, ...
                    'analysis_frequency_hz', R(1).analysis_frequency_hz, 'rx_installation', R(1).rx_installation, ...
                    'rx_pattern_type', R(1).rx_pattern_type, 'n_pairs', numel(R), 'n_evaluated', nnz(ev), ...
                    'n_pattern_missing', nnz(strcmp({R.status}, 'INPUT_MISSING_PATTERN')), ...
                    'n_source_missing', nnz(strcmp({R.status}, 'COUPLING_EVALUATED_SOURCE_MISSING')), ...
                    'worst_tx_installation', '', 'worst_tx_pattern_type', '', 'worst_coupling_db', NaN, ...
                    'worst_victim_psd_dbm_hz', NaN, 'allowable_psd_dbm_hz', R(1).allowable_psd_dbm_hz, ...
                    'worst_margin_db', NaN, 'required_suppression_db', NaN, 'verdict', 'UNKNOWN', 'note', '');
                if any(ev)
                    mm = m; mm(~ev) = Inf; [~, w] = min(mm);
                    s.worst_tx_installation = R(w).tx_installation; s.worst_tx_pattern_type = R(w).tx_pattern_type;
                    s.worst_coupling_db = R(w).coupling_db; s.worst_victim_psd_dbm_hz = R(w).victim_psd_dbm_hz;
                    s.worst_margin_db = R(w).margin_db; s.required_suppression_db = R(w).required_suppression_db;
                end
                if any(strcmp({R.verdict}, 'FAIL'))
                    s.verdict = 'FAIL';
                elseif all(ev)
                    s.verdict = 'PASS';
                end
                if ~all(ev)
                    s.note = sprintf('%d of %d pair(s) not fully evaluated (input missing): worst case is over evaluated pairs only', ...
                        nnz(~ev), numel(R));
                end
                if isempty(S); S = s; else; S(end+1) = s; end %#ok<AGROW>
            end
        end

        function txt = runSummaryText(cat, rows, S, figs, calDir, out, secs)
            nl = sprintf('\n');
            E = cat.entries;
            nF = numel(E); nV = cat.nValid();
            ev = strcmp({rows.status}, 'EVALUATED');
            nFail = nnz(strcmp({rows.verdict}, 'FAIL')); nPass = nnz(strcmp({rows.verdict}, 'PASS'));
            nUnk = numel(rows) - nFail - nPass;
            L = {};
            L{end+1} = 'CAL native-3D CST RFI run summary';
            L{end+1} = sprintf('Generated %s; runtime %.1f s; CST input %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'), secs, calDir);
            L{end+1} = '';
            L{end+1} = '1. 결론 (Executive summary)';
            if nV == 0
                L{end+1} = ['   입력 미확보로 계산/판정 보류: data/cal 에 유효한 CST ASCII full-sphere 패턴이 없다. ' ...
                    'RFI pair는 모두 INPUT_MISSING 이며 합성 패턴으로 대체하지 않았다.'];
            else
                L{end+1} = sprintf(['   %d개 pair 중 %d개 판정 완료: %d개 해당 기준 초과(FAIL), %d개 해당 기준 충족(PASS); ' ...
                    '%d개는 입력 미확보로 최종 판정 보류(UNKNOWN).'], numel(rows), nnz(ev), nFail, nPass, nUnk);
                if any(ev)
                    m = [rows.margin_db]; m(~ev) = Inf; [~, w] = min(m); r = rows(w);
                    L{end+1} = sprintf(['   대표 worst case: %s -> %s, %s band @ %.6g GHz: victim-port PSD %.2f dBm/Hz vs 허용 %.2f dBm/Hz, ' ...
                        'margin %.2f dB (요구 억제량 %.2f dB). TX %s %.2f dBi, RX %s %.2f dBi, 거리 %.3f m.'], ...
                        r.tx_installation, r.rx_installation, r.victim_band, r.analysis_frequency_hz / 1e9, r.victim_psd_dbm_hz, ...
                        r.allowable_psd_dbm_hz, r.margin_db, r.required_suppression_db, r.tx_pattern_type, r.tx_gain_dbi, ...
                        r.rx_pattern_type, r.rx_gain_dbi, r.distance_m);
                end
                L{end+1} = ['   판정 범위: CST 시뮬레이션 데이터(Realized Gain, 단일 주파수 plane) + far-field FSPL + ITU spurious ' ...
                    'source(규격 한계값 가정) + kT0+NF+I/N 기준(engineering assumption). 위성 전체 적합성 판정이 아니다.'];
            end
            L{end+1} = '';
            L{end+1} = '2. 주요 결과 (victim band x frequency x victim; worst evaluated attacker)';
            L{end+1} = sprintf('   %-13s %-6s %-11s %-10s %10s %10s %9s %s', 'band', 'freq', 'victim', 'worst TX', 'PSD dBm/Hz', ...
                'allow', 'margin', 'verdict');
            for k = 1:numel(S)
                s = S(k);
                L{end+1} = sprintf('   %-13s %-6s %-11s %-10s %10s %10.2f %9s %s', s.victim_band, s.frequency_label, ...
                    s.rx_installation, rfscreen.cal.CalRunner.ternary(isempty(s.worst_tx_installation), '-', s.worst_tx_installation), ...
                    rfscreen.cal.CalRunner.num(s.worst_victim_psd_dbm_hz), s.allowable_psd_dbm_hz, ...
                    rfscreen.cal.CalRunner.num(s.worst_margin_db), rfscreen.cal.CalRunner.verdictText(s.verdict)); %#ok<AGROW>
            end
            L{end+1} = '   margin = 허용 PSD - victim-port PSD [dB] (양수 = 여유, 음수 = 초과). 상세: rfi/pair_results.csv';
            L{end+1} = '';
            L{end+1} = sprintf('3. 패턴 입력: %d개 파일 발견, %d개 유효, %d개 미사용', nF, nV, nF - nV);
            for a = 1:nF
                if ~strcmp(E(a).status, 'VALID')
                    L{end+1} = sprintf('   - %s: %s (%s)', E(a).relPath, E(a).status, E(a).message); %#ok<AGROW>
                end
            end
            L{end+1} = '';
            L{end+1} = '4. 입력 누락 (계산/판정 보류 원인)';
            miss = {};
            for k = 1:numel(rows)
                if ~ev(k)
                    w = strsplit(rows(k).warnings, ' | ');
                    w = w(~cellfun(@isempty, regexp(w, '^(TX|RX): |^EMISSION_SOURCE_MISSING', 'once')));
                    miss = [miss w]; %#ok<AGROW>
                end
            end
            miss = unique(miss);
            if nV == 0
                miss = {sprintf('CST ASCII 패턴 전체 (data/cal/{gps,isl,kaa,sba}/*.txt): %d개 pair 계산 보류', numel(rows))};
            end
            if isempty(miss); L{end+1} = '   없음'; end
            for k = 1:numel(miss); L{end+1} = ['   - ' miss{k}]; end %#ok<AGROW>
            L{end+1} = '';
            L{end+1} = '5. 분석 한계';
            L{end+1} = '   - 단일 CST 주파수 plane(victim 대표 주파수) 평가: victim band 전체 sweep 아님.';
            L{end+1} = '   - Far-field FSPL 결합 모델: 근접장/구조 산란 경로는 installed CST 패턴에 포함된 범위만 반영.';
            L{end+1} = '   - KAA는 gimbal 기준(패널 법선) 자세: 지향 tracking case 아님. LOS BLOCKED는 감쇠 미적용(geometry evidence).';
            L{end+1} = '   - ISL 자세는 antenna_installations.csv(PANEL_3 법선) SSOT; closed-network geometry의 +X end-face override와 다름.';
            L{end+1} = '   - Source = ITU spurious 한계값(4 kHz, 규격 가정); TX chain/filter 손실 0 dB.';
            L{end+1} = '';
            L{end+1} = sprintf('6. 출력: %s', out);
            L{end+1} = sprintf('   validation/pattern_inventory.csv, validation/pattern_binding.csv; figures: %d pattern-cut, %d installed 3D, %d body-cut', ...
                numel(figs.pattern), numel(figs.installed3d), numel(figs.bodyCuts));
            L{end+1} = '   rfi/pair_results.csv, rfi/summary.csv, rfi/run_summary.txt';
            for k = 1:numel(figs.failed); L{end+1} = ['   FIGURE NOT PRODUCED: ' figs.failed{k}]; end %#ok<AGROW>
            txt = [strjoin(L, nl) nl];
        end

        function writeInventory(path, cat, calDir)
            E = cat.entries;
            rows = struct([]);
            for a = 1:numel(E)
                r = struct('file', E(a).relPath, 'family', E(a).family, 'installation', E(a).installationId, ...
                    'pattern_type', E(a).patternType, 'frequency_token', E(a).token, ...
                    'frequencies_ghz', strjoin(arrayfun(@(f) sprintf('%.6g', f / 1e9), E(a).freqs_Hz, 'UniformOutput', false), ';'), ...
                    'band_labels', strjoin(E(a).freqLabels, ';'), 'status', E(a).status, 'n_rows', NaN, 'n_columns', NaN, ...
                    'n_theta', NaN, 'n_phi', NaN, 'theta_step_deg', NaN, 'phi_step_deg', NaN, 'peak_gain_dbi', NaN, ...
                    'peak_theta_deg', NaN, 'peak_phi_deg', NaN, 'boresight_gain_dbi', NaN, 'min_gain_dbi', NaN, ...
                    'pole_spread_north_db', NaN, 'pole_spread_south_db', NaN, 'provenance', '', 'message', E(a).message);
                if ~isempty(E(a).data)
                    s = E(a).data.summary();
                    r.n_rows = s.nRows; r.n_columns = E(a).data.info.nColumns; r.n_theta = s.nTheta; r.n_phi = s.nPhi;
                    r.theta_step_deg = s.thetaStep_deg; r.phi_step_deg = s.phiStep_deg;
                    r.peak_gain_dbi = s.peakGain_dBi; r.peak_theta_deg = s.peakTheta_deg; r.peak_phi_deg = s.peakPhi_deg;
                    r.boresight_gain_dbi = s.boresightGain_dBi; r.min_gain_dbi = s.minGain_dBi;
                    r.pole_spread_north_db = s.poleSpreadNorth_dB; r.pole_spread_south_db = s.poleSpreadSouth_dB;
                    r.provenance = sprintf('SIMULATED_3D; CST ASCII native grid; %s', E(a).patternType);
                end
                if isempty(rows); rows = r; else; rows(end+1) = r; end %#ok<AGROW>
            end
            if isempty(rows)
                rows = struct('file', '', 'status', 'INPUT_MISSING', 'message', ...
                    sprintf('no .txt file under %s/{gps,isl,kaa,sba}', calDir));
            end
            rfscreen.cal.CalRunner.writeStructCsv(path, rows);
        end

        function writeBinding(path, binder, fmap, cfg, calDir)
            plan = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(cfg, 'cal_rfi_plan.csv'));
            rows = struct([]); seen = {};
            for r = 1:plan.nRows
                [~, f, lab] = fmap.resolve(plan.freq_token{r});
                ids = [strcat(strsplit(plan.attackers{r}, ';'), '#TX'), strcat(strsplit(plan.victims{r}, ';'), '#RX')];
                for k = 1:numel(ids)
                    key = sprintf('%s@%s', ids{k}, lab);
                    if any(strcmp(seen, key)); continue; end
                    seen{end+1} = key; %#ok<AGROW>
                    t = strsplit(ids{k}, '#');
                    info = binder.roleInfo(t{1});
                    if strcmp(info.family, 'SAR')
                        b = struct('status', 'OWNER_BASELINE', 'patternType', 'OWNER_ENGINEERING_BASELINE', 'file', '', ...
                            'fallback', false, 'warnings', {{}}, 'reason', 'existing SAR owner engineering receive baseline');
                    else
                        b = binder.bind(t{1}, t{2}, f);
                    end
                    row = struct('installation', t{1}, 'role', t{2}, 'frequency_label', lab, 'frequency_hz', f, ...
                        'status', b.status, 'pattern_type', b.patternType, ...
                        'pattern_file', rfscreen.cal.CalRunner.relTo(b.file, calDir), 'fallback', double(b.fallback), ...
                        'note', strjoin([b.warnings {b.reason}], ' | '));
                    if isempty(rows); rows = row; else; rows(end+1) = row; end %#ok<AGROW>
                end
            end
            rfscreen.cal.CalRunner.writeStructCsv(path, rows);
        end

        function writeStructCsv(path, S)
            d = fileparts(path); if exist(d, 'dir') ~= 7; mkdir(d); end
            fid = fopen(path, 'w');
            if fid < 0; error('rfscreen:cal:writeFailed', 'cannot write %s', path); end
            if isempty(S); fclose(fid); return; end
            fn = fieldnames(S);
            fprintf(fid, '%s\n', strjoin(fn.', ','));
            for k = 1:numel(S)
                vals = cell(1, numel(fn));
                for j = 1:numel(fn)
                    v = S(k).(fn{j});
                    if isnumeric(v) || islogical(v)
                        if isempty(v) || (isscalar(v) && isnan(v)); v = ''; else; v = sprintf('%.12g', v); end
                    end
                    if ~isempty(regexp(v, '[,"\r\n]', 'once')); v = ['"' strrep(v, '"', '""') '"']; end
                    vals{j} = v;
                end
                fprintf(fid, '%s\n', strjoin(vals, ','));
            end
            fclose(fid);
        end

        function cleanOutputs(out)
            sub = rfscreen.cal.CalRunner.OUT_SUBDIRS;
            for i = 1:numel(sub)
                rfscreen.cal.CalRunner.cleanDir(fullfile(out, sub{i}));
            end
        end

        function cleanDir(d)
            if exist(d, 'dir') ~= 7; return; end
            L = dir(d);
            for k = 1:numel(L)
                if any(strcmp(L(k).name, {'.', '..'})); continue; end
                p = fullfile(d, L(k).name);
                if L(k).isdir
                    rfscreen.cal.CalRunner.cleanDir(p);
                else
                    [~, ~, ext] = fileparts(L(k).name);
                    if any(strcmpi(ext, {'.png', '.csv', '.txt'})); delete(p); end
                end
            end
        end

        function s = relTo(p, calDir)
            s = p;
            if isempty(p); return; end
            a = strrep(p, '\', '/'); b = [strrep(calDir, '\', '/') '/'];
            if strncmp(a, b, numel(b)); s = a(numel(b)+1:end); end
        end
    end

    methods (Static, Access = private)
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
        function say(verbose, varargin)
            if verbose; fprintf([varargin{1} '\n'], varargin{2:end}); end
        end
        function v = ternary(c, a, b)
            if c; v = a; else; v = b; end
        end
        function s = num(x)
            if isnan(x); s = '-'; else; s = sprintf('%.2f', x); end
        end
        function s = verdictText(v)
            switch v
                case 'PASS'; s = 'PASS (해당 기준 충족)';
                case 'FAIL'; s = 'FAIL (해당 기준 초과)';
                otherwise;   s = 'UNKNOWN (최종 판정 보류)';
            end
        end
    end
end
