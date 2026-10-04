1;  % Octave script with local functions -- RFI analysis (output/claude)
% =============================================================================================
% RFI interference analysis of the simplified spacecraft, using ONLY existing outputs:
%   * mission cases / RF systems / installation geometry : src/+rfscreen (existing engine)
%   * frozen reference free-space patterns              : data/... via pattern_bindings.csv
%   * CST fixed-geometry free-space port responses       : data/antenna_port_response_cst
%   * CST provisional local installed S cuts (sensitivity only): cst/results/rfc_frequency_cases
%   * Ka source routing: KAA TX -> REFLECTOR_APERTURE_NEAR_FIELD (src/+rfscreen/+kaa, validated KAA
%     aperture); S/ISL TX keep the free-space pattern (Friis) path unchanged. The frozen Ka export
%     stays as the far-field reference (variant B). Gimbal screening: run_ka_nearfield_analysis.m
% No CST run, no geometry change, no frozen-file change. Run in Octave from any directory:
%   octave-cli --eval "run('output/claude/run_rfi_analysis.m')"
% =============================================================================================

function s = ifelse_str(c, a, b)
    if c; s = a; else; s = b; end
end

function logm(fid, varargin)
    s = sprintf(varargin{:});
    fprintf(fid, '%s\n', s); fprintf('%s\n', s);
end

function set = cst_set(prov, repo, family, band, quantity)
    % CST fixed-geometry port response (public cuts) for one family/band/quantity.
    set = [];
    cuts = prov.cuts; if iscell(cuts); cuts = [cuts{:}]; end
    sel = strcmp({cuts.family}, family) & strcmp({cuts.band}, band) & strcmp({cuts.quantity}, quantity);
    c = cuts(sel);
    if isempty(c); return; end
    F = unique([c.frequency_hz]);
    set = struct('freqs', F, 'xz', {cell(1, numel(F))}, 'yz', {cell(1, numel(F))}, ...
        'validRange', [min(F) max(F)], 'mode', 'MONITORS', 'reliable', true, 'acc', zeros(1, numel(F)), ...
        'files', {repmat({''}, 1, numel(F))}, 'cstCase', c(1).source_case, 'quantity', quantity, ...
        'sourceType', 'CST_PORT_RESPONSE_FREE_SPACE', 'key', [family '/' band]);
    for k = 1:numel(F)
        for pl = {'XZ', 'YZ'}
            m = c([c.frequency_hz] == F(k) & strcmp({c.plane}, pl{1}));
            if numel(m) ~= 1; set = []; return; end
            [~, g] = rfi_read_cut(fullfile(repo, m.path));
            if strcmp(pl{1}, 'XZ'); set.xz{k} = g; else; set.yz{k} = g; end
            if ~m.normalization_reliable; set.reliable = false; end
            a = m.accepted_power_fraction; if isempty(a); a = NaN; end
            set.acc(k) = a;
            set.files{k} = [set.files{k} ' ' m.path];
        end
    end
end

function set = frozen_set(B, keys)
    % Frozen reference pattern(s) from pattern_bindings (one key = band-reused single pattern;
    % several keys = monitor set of one band).
    F = zeros(1, numel(keys)); xz = cell(1, numel(keys)); yz = xz; files = xz;
    lo = Inf; hi = -Inf;
    for k = 1:numel(keys)
        b = B(keys{k});
        [~, xz{k}] = rfi_read_cut(b.xzPath); [~, yz{k}] = rfi_read_cut(b.yzPath);
        F(k) = b.frequency_Hz; lo = min(lo, b.bandMin_Hz); hi = max(hi, b.bandMax_Hz);
        files{k} = [b.xzPath ' ' b.yzPath];
    end
    [F, o] = sort(F); xz = xz(o); yz = yz(o); files = files(o);
    mode = 'MONITORS'; if numel(keys) == 1; mode = 'BAND_REUSE'; end
    set = struct('freqs', F, 'xz', {xz}, 'yz', {yz}, 'validRange', [lo hi], 'mode', mode, 'reliable', true, ...
        'acc', NaN(1, numel(F)), 'files', {files}, 'cstCase', '', 'quantity', b.fidelity, ...
        'sourceType', 'FROZEN_REFERENCE_FREE_SPACE', 'key', strjoin(keys, '+'));
end

function set = raw_set(repo, caseName, freqsGHz)
    % Provisional local installed (or matched free) raw CST cuts: realized_gain_dbi column only.
    F = freqsGHz * 1e9; xz = cell(1, numel(F)); yz = xz; files = xz;
    for k = 1:numel(F)
        tag = regexprep(sprintf('%.6g', freqsGHz(k)), '\.?0+$', '');
        fx = fullfile(repo, 'cst', 'results', 'rfc_frequency_cases', caseName, sprintf('f%s_XZ.csv', tag));
        fy = strrep(fx, '_XZ.csv', '_YZ.csv');
        [~, xz{k}] = rfi_read_cut(fx, 'realized_gain_dbi'); [~, yz{k}] = rfi_read_cut(fy, 'realized_gain_dbi');
        files{k} = [fx ' ' fy];
    end
    set = struct('freqs', F, 'xz', {xz}, 'yz', {yz}, 'validRange', [min(F) max(F)], 'mode', 'MONITORS', ...
        'reliable', true, 'acc', NaN(1, numel(F)), 'files', {files}, 'cstCase', caseName, ...
        'quantity', 'realized_gain_dbi (raw)', 'sourceType', 'CST_LOCAL_INSTALLED_PROVISIONAL', 'key', caseName);
end

function R = local_frame(n)
    xB = [1; 0; 0]; z = n(:) / norm(n); y = cross(z, xB);
    R = [xB, y, z];   % columns = local axes in body: +X_L = +X_B, +Y_L = Z x X, +Z_L = boresight
end

function T = readCsvSimple(path)
    % Plain CSV (no quoting, no comments) -> struct of cellstr columns + nRows.
    L = strsplit(strrep(fileread(path), char(13), ''), char(10)); L = L(~cellfun(@isempty, strtrim(L)));
    h = regexp(L{1}, ',', 'split'); T = struct('nRows', numel(L) - 1);
    V = cellfun(@(x) regexp(x, ',', 'split'), L(2:end), 'UniformOutput', false);
    for j = 1:numel(h); T.(h{j}) = cellfun(@(v) v{j}, V, 'UniformOutput', false); end
end

function v = fspl(f, d)
    v = 20 * log10(4 * pi * d * f / 299792458);
end

function s = csvnum(x)
    if ischar(x); s = x; return; end
    if isempty(x) || isnan(x); s = 'NaN'; elseif isinf(x); if x < 0; s = '-Inf'; else; s = 'Inf'; end
    else; s = sprintf('%.4f', x); end
end

function writeTable(path, header, rows)
    fid = fopen(path, 'w');
    fprintf(fid, '%s\n', strjoin(header, ','));
    for i = 1:numel(rows)
        r = rows{i}; c = cell(1, numel(r));
        for j = 1:numel(r); c{j} = csvnum(r{j}); end
        c = strrep(c, ',', ';');
        fprintf(fid, '%s\n', strjoin(c, ','));
    end
    fclose(fid);
end

% ------------------------------------------------------------------------------------------------
here = fileparts(mfilename('fullpath'));
if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'src')); addpath(fullfile(here, 'code'));
outDir = fullfile(here, 'results'); if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
logf = fopen(fullfile(outDir, 'run_log.txt'), 'w');
logm(logf, 'RFI analysis run %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
logm(logf, 'Environment: GNU Octave %s on %s (MATLAB not used)', OCTAVE_VERSION, computer());
pv = rfi_provenance(repo, outDir, 'run_rfi_analysis.m', 'pair results / secondary blocker inputs');
logm(logf, 'Analysis base commit (HEAD at run time; results are committed on top of it): %s, working tree %s', pv.analysis_base_commit, pv.working_tree);

MB = rfscreen.mission.MissionCaseBuilder;
model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
dsDir = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
B = MB.readBindings(fullfile(dsDir, 'pattern_bindings.csv'));
prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));
FT = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(dsDir, 'antenna_functions.csv'));
dims = containers.Map();
for r = 1:FT.nRows
    v = str2double(FT.max_dimension_m{r}); dims(FT.installation_id{r}) = v;
end

% ---- mounts (unchanged installation reference points and boresights) ----
mounts = containers.Map();
for i = 1:numel(model.installationRecords)
    rc = model.installationRecords(i);
    pn = model.panels(strcmp({model.panels.id}, rc.panelId));
    mounts(rc.antennaId) = struct('id', rc.antennaId, 'p', rc.position_m, 'n', pn.normal_B, ...
        'R', local_frame(pn.normal_B), 'panel', rc.panelId);
end

% ---- source sets ----
famOf = struct('SBA_NADIR', 'S', 'SBA_ZENITH', 'S', 'GPSA_1', 'L', 'GPSA_2', 'L', 'ISL', 'ISL', ...
    'KAA_1', 'KA', 'KAA_2', 'KA', 'SAR_ANT', 'SAR');
bandKeys = {'S_TC', 'S_TM', 'L1', 'L2', 'L5', 'ISL', 'SAR', 'KA'};
CST = struct();
avail = {};
for fam = {'S', 'L', 'ISL'}
    for bk = bandKeys
        s = cst_set(prov, repo, fam{1}, bk{1}, 'RealizedGain');
        CST.(fam{1}).(bk{1}) = s;
        if isempty(s)
            st = 'NOT_COMPUTED_MESH_LIMIT'; nm = ''; cs = ''; ac = NaN;
        elseif ~s.reliable
            st = 'NORMALIZATION_UNRELIABLE_NOT_USED'; nm = sprintf('%.6g;', s.freqs / 1e9); cs = s.cstCase; ac = min(s.acc);
        else
            st = 'AVAILABLE'; nm = sprintf('%.6g;', s.freqs / 1e9); cs = s.cstCase; ac = min(s.acc);
        end
        avail{end+1} = {fam{1}, bk{1}, 'RealizedGain', st, nm, cs, ac}; %#ok<AGROW>
    end
end
avail{end+1} = {'KA', 'KA', 'frozen KAA_CST (accepted-power model + envelope)', 'AVAILABLE_FROZEN_REFERENCE', '25.5;26.25;27;', 'Kaband_KAA_CST', NaN};
for bk = {'S_TC', 'S_TM', 'L1', 'L2', 'L5', 'ISL', 'SAR'}
    avail{end+1} = {'KA', bk{1}, 'full reflector response', 'NOT_COMPUTED (feed-only CST not substituted)', '', '', NaN}; %#ok<AGROW>
end
for bk = bandKeys
    avail{end+1} = {'SAR', bk{1}, 'any', 'NO_PATTERN_BOUND', '', '', NaN}; %#ok<AGROW>
end
writeTable(fullfile(outDir, 'source_availability.csv'), ...
    {'antenna_family', 'evaluation_band', 'quantity', 'status', 'monitors_ghz', 'cst_case_or_dataset', 'min_accepted_fraction'}, avail);
logm(logf, 'Source availability written (%d rows).', numel(avail));

FROZ.ISL = frozen_set(B, {'ISL_10P55', 'ISL_10P6', 'ISL_10P65'});
FROZ.KA = frozen_set(B, {'KAA_KA_25P5', 'KAA_KA_26P25', 'KAA_KA_27P0'});
% Ka source model routing (KAA TX only): reflector-aperture near field at the CST feed monitors
KA = struct('model', rfscreen.kaa.ReflectorApertureModel.fromRepository(repo), 'F', [25.5e9 26.25e9 27e9]);
for fam = {'S', 'L', 'ISL'}; KA.resp.(fam{1}) = rfscreen.kaa.KaVictimResponse.fromRepository(repo, fam{1}); end
KA.cache = containers.Map();
gwPath = fullfile(outDir, 'ka_gimbal_worstcase.csv');
if exist(gwPath, 'file') ~= 2
    error('rfi:kaFirst', 'run output/claude/run_ka_nearfield_analysis.m first (writes %s)', gwPath);
end
KA.gw = readCsvSimple(gwPath); KA.asm = readCsvSimple(fullfile(outDir, 'ka_assumption_only_sensitivity.csv'));
logm(logf, 'Ka routing: KAA TX -> %s (%s; %s), victim gain = Ka OOB response only', ...
    rfscreen.kaa.KaRfiPath.NEAR_FIELD, rfscreen.kaa.ApertureNearFieldSolver.FIELD_SCOPE, rfscreen.kaa.ApertureNearFieldSolver.STRUCTURE_FLAG);
INST.SBA_NADIR = raw_set(repo, 'RFC_S_LOW_SBA_NADIR_R1P75', [2.0 2.06 2.12 2.2 2.25 2.3]);
INST.SBA_ZENITH = raw_set(repo, 'RFC_S_LOW_SBA_ZENITH_R1P75', [2.0 2.06 2.12 2.2 2.25 2.3]);
INST.FREE = raw_set(repo, 'RFC_S_LOW_FREE_M4R10', [2.0 2.06 2.12 2.2 2.25 2.3]);

% ---- cut-direction self check (exact plane directions must return the cut value) ----
s = CST.S.S_TM; kchk = 2; chk = {};
for t = [0 30 60 90 120]
    gx = rfi_cut_gain(s.xz{kchk}, s.yz{kchk}, [sind(t); 0; cosd(t)]);
    gy = rfi_cut_gain(s.xz{kchk}, s.yz{kchk}, [0; sind(t); cosd(t)]);
    chk{end+1} = {'S/S_TM 2.25 GHz', t, gx, s.xz{kchk}(t + 1), gy, s.yz{kchk}(t + 1)}; %#ok<AGROW>
end
writeTable(fullfile(outDir, 'check_cut_directions.csv'), {'set', 'theta_deg', 'eval_in_XZ_plane', 'XZ_cut_value', 'eval_in_YZ_plane', 'YZ_cut_value'}, chk);
logm(logf, 'Cut-direction check: max |eval-cut| = %.2e dB', max(cellfun(@(r) max(abs(r{3} - r{4}), abs(r{5} - r{6})), chk)));

% ---- peak cross-check against docs/reports/rfi_handoff/realized_gain_peaks.csv ----
PK = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(repo, 'docs', 'reports', 'rfi_handoff', 'realized_gain_peaks.csv'));
mx = 0;
for r = 1:PK.nRows
    [~, g] = rfi_read_cut(fullfile(repo, PK.source_csv{r}));
    mx = max(mx, abs(max(g) - str2double(PK.peak_realized_gain_dbi{r})));
end
logm(logf, 'Peak table cross-check: %d cuts, max |cut max - table| = %.2e dB', PK.nRows, mx);

% ---- mission cases (existing engine) ----
cases = MB.listCases();
modes = {'SCREENING_ALL_TX', 'NOM_NADIR_KAA1', 'NOM_ZENITH_KAA2'};
cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
pairRows = {}; bandRows = {}; usage = {}; aggRows = {}; sensRows = {}; xRows = {}; engRows = {};
nSamples = 21;
RLR = rfscreen.mission.RfcLevelReport;
for ci = 1:numel(cases)
    cs = cases(ci);
    c = MB.buildCase(cs.caseId, struct('patternCache', cache, 'modeId', 'SCREENING_ALL_TX'));
    sysById = containers.Map();
    for q = 1:numel(c.rfSystems); sysById(c.rfSystems(q).systemId) = c.rfSystems(q); end
    txIds = c.scenario.transmitters.keys(); rxIds = c.scenario.receivers.keys();
    % existing engine reference run (frozen patterns both ends, single frequency, free space)
    er = RLR.build(c, RLR.couplingModel());
    for k = 1:numel(er)
        engRows{end+1} = {cs.caseId, er(k).interfererId, er(k).victimId, er(k).txGain_dBi, er(k).rxGain_dBi, ...
            er(k).fspl_dB, er(k).s21_dB, er(k).receivedLevel_dBm, er(k).couplingValidity}; %#ok<AGROW>
    end
    for it = 1:numel(txIds)
        tx = sysById(txIds{it}); txSys = c.scenario.transmitters(txIds{it});
        ta = c.scenario.antennas(txSys.antennaId); tm = mounts(ta.installationId);
        tfam = famOf.(ta.installationId);
        if strncmp(tx.systemId, 'S_TM', 4); tband = 'S_TM'; tfroz = frozen_set(B, {[cs.sbaVariant '_TM']});
        elseif strncmp(tx.systemId, 'ISL', 3); tband = 'ISL'; tfroz = FROZ.ISL;
        else; tband = 'KA'; tfroz = FROZ.KA; end
        if any(strcmp(tfam, {'S', 'L', 'ISL'})); tcst = CST.(tfam).(tband); else; tcst = []; end
        txLo = tx.fc_Hz - tx.bw_Hz / 2; txHi = tx.fc_Hz + tx.bw_Hz / 2;
        for ir = 1:numel(rxIds)
            rx = sysById(rxIds{ir}); rxSys = c.scenario.receivers(rxIds{ir});
            ra = c.scenario.antennas(rxSys.antennaId); rm = mounts(ra.installationId);
            rfam = famOf.(ra.installationId);
            rxLo = rx.fc_Hz - rx.bw_Hz / 2; rxHi = rx.fc_Hz + rx.bw_Hz / 2;
            pairId = [tx.systemId '>' rx.systemId];
            rel = 'OUT_OF_BAND'; ov = [max(txLo, rxLo) min(txHi, rxHi)];
            if ov(2) > ov(1); rel = 'IN_BAND'; end
            base = {cs.caseId, cs.sbaVariant, cs.gpsBand, pairId, tx.systemId, ta.installationId, tfam, rx.systemId, ...
                ra.installationId, rfam, txLo / 1e9, txHi / 1e9, rxLo / 1e9, rxHi / 1e9, rel, tx.power_dBm};
            if strcmp(ta.installationId, ra.installationId)
                pairRows{end+1} = [base, {NaN, '', '', NaN, NaN, NaN, NaN, NaN, '', '', NaN, '', '', '', NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
                    rx.allowableInterference_dBm, rx.noise_dBm, NaN, NaN, '', NaN, 'NONE', 'NOT_EVALUATED', ...
                    'SAME_ANTENNA_PORT', 'diplexer/T-R isolation and TX noise in the RX band are not in the inputs'}]; %#ok<AGROW>
                continue;
            end
            % geometry
            d = rm.p - tm.p; dist = norm(d); u = d / dist;
            dT = tm.R' * u; dR = rm.R' * (-u);
            los = rfscreen.geometry.LineOfSight.segment(ta.installationId, ra.installationId, tm.p, rm.p, model.structures);
            % receive-side response at the TX frequencies (CST RealizedGain, fixed geometry, free space)
            rset = []; if any(strcmp(rfam, {'S', 'L', 'ISL'})); rset = CST.(rfam).(tband); end
            rxStatus = 'OK';
            if isempty(rset); rxStatus = 'INPUT_MISSING'; elseif ~rset.reliable; rxStatus = 'INPUT_UNRELIABLE'; end
            fs = linspace(txLo, txHi, nSamples);
            gA = NaN(1, nSamples); gB = gA; gR = gA; L = gA;
            for k = 1:nSamples
                if ~isempty(tcst); gA(k) = rfi_eval_set(tcst, fs(k), dT); else; gA(k) = rfi_eval_set(tfroz, fs(k), dT); end
                gB(k) = rfi_eval_set(tfroz, fs(k), dT);
                if strcmp(rxStatus, 'OK'); gR(k) = rfi_eval_set(rset, fs(k), dR); end
                L(k) = fspl(fs(k), dist);
            end
            s21A = gA + gR - L; s21B = gB + gR - L;
            lin = @(x) 10 * log10(mean(10 .^ (x / 10)));
            dmax = max(dims(ta.installationId), dims(ra.installationId)); lam = 299792458 / txHi;
            rff = max(2 * dmax ^ 2 / lam, 5 * lam);
            ff = 'FAR_FIELD_OK'; if dist < rff; ff = 'NEAR_FIELD_FRIIS_ESTIMATE'; end
            kq = [];
            if strcmp(tband, 'KA')                % KAA TX: aperture near field (nominal gimbal reference)
                kkey = [ta.installationId '>' ra.installationId];
                if ~KA.cache.isKey(kkey)
                    KA.cache(kkey) = rfi_ka_point(KA.model, KA.F, tx.power_dBm, tm.p, ...
                        rfscreen.kaa.CstLocalFrameAdapter.fixedMount(tm.n), rm.p, rfscreen.kaa.CstLocalFrameAdapter.fixedMount(rm.n), KA.resp.(rfam));
                end
                kq = KA.cache(kkey);
                ff = 'NEAR_FIELD_APERTURE_INTEGRATION';
                if ~KA.resp.(rfam).isAvailable(); rxStatus = 'INPUT_MISSING'; end
            end
            if strcmp(rxStatus, 'OK')
                recA = tx.power_dBm + lin(s21A); recB = tx.power_dBm + lin(s21B);
                inbA = -Inf;
                if strcmp(rel, 'IN_BAND')
                    fo = linspace(ov(1), ov(2), nSamples); so = zeros(1, nSamples);
                    for k = 1:nSamples
                        if ~isempty(tcst); ga = rfi_eval_set(tcst, fo(k), dT); else; ga = rfi_eval_set(tfroz, fo(k), dT); end
                        so(k) = ga + rfi_eval_set(rset, fo(k), dR) - fspl(fo(k), dist);
                    end
                    inbA = tx.power_dBm + 10 * log10((ov(2) - ov(1)) / (txHi - txLo)) + lin(so);
                end
                reqA = recA - rx.allowableInterference_dBm; reqB = recB - rx.allowableInterference_dBm;
                if strcmp(rel, 'IN_BAND')
                    mar = rx.allowableInterference_dBm - inbA; verdict = 'PASS'; if mar < 0; verdict = 'FAIL'; end
                    status = 'EVALUATED_IN_BAND';
                else
                    mar = NaN; verdict = [rfscreen.psd.OobBlockerPath.ST_UNKNOWN ' (FUNDAMENTAL_OOB_BLOCKER; victim-band emission: victim_band_psd_results.csv)'];
                    status = 'EVALUATED_OOB_LEVEL';
                end
                if strcmp(ff, 'NEAR_FIELD_FRIIS_ESTIMATE'); status = [status '_ESTIMATE']; end
                miss = '';
                if ~isempty(kq)                    % Ka: replace the Friis A value by the near-field port power
                    recA = kq.P_port_band_dBm; reqA = recA - rx.allowableInterference_dBm;
                    gA = repmat(10 * log10(mean(10 .^ (kq.Geq_dBi / 10))), 1, nSamples);
                    s21A = repmat(recA - tx.power_dBm, 1, nSamples);
                    status = 'EVALUATED_OOB_LEVEL_NEAR_FIELD';
                    verdict = [rfscreen.kaa.KaRfiPath.RX_UNKNOWN ' (' rfscreen.kaa.KaRfiPath.FUNDAMENTAL ')'];
                end
            else
                recA = NaN; recB = NaN; inbA = NaN; reqA = NaN; reqB = NaN; mar = NaN;
                status = rxStatus; verdict = 'NOT_EVALUATED';
                miss = sprintf('no reliable %s RealizedGain of the %s antenna in the %s band (CST %s)', 'free-space', rfam, tband, ...
                    'MESH_LIMIT / not computed');
                if ~isempty(kq); miss = KA.resp.(rfam).reason; verdict = rfscreen.kaa.KaRfiPath.RX_NOT_REACHED; end
            end
            txSrcA = 'CST'; txQA = 'RealizedGain'; txCaseA = ''; if ~isempty(tcst); txCaseA = tcst.cstCase; else; txSrcA = 'FROZEN'; txQA = tfroz.quantity; end
            rxCase = ''; if ~isempty(rset); rxCase = rset.cstCase; end
            cmeth = 'FRIIS_FREE_SPACE_PATTERN (no polarization/blockage loss applied)';
            if ~isempty(kq)
                txSrcA = 'KAA_APERTURE_NEAR_FIELD'; txQA = 'Geq = 4 pi d^2 S / P (accepted-power basis; 3-monitor mean)';
                txCaseA = 'KA_FEED_C_OEWG + KA_REFLECTOR_KA_FEED_C_OEWG';
                cmeth = [rfscreen.kaa.KaRfiPath.NEAR_FIELD '; ' rfscreen.kaa.ApertureNearFieldSolver.FIELD_SCOPE '; ' ...
                    rfscreen.kaa.ApertureNearFieldSolver.STRUCTURE_FLAG '; B = frozen-export Friis reference'];
            end
            pairRows{end+1} = [base, {dist, los.status, strjoin(los.blockingStructureIds, ';'), ...
                acosd(max(-1, min(1, dT(3)))), mod(atan2d(dT(2), dT(1)), 360), acosd(max(-1, min(1, dR(3)))), mod(atan2d(dR(2), dR(1)), 360), ...
                lin(gA), txSrcA, txQA, lin(gB), lin(gR), [rfam '/' tband], 'RealizedGain', rxCase, ...
                fspl(tx.fc_Hz, dist), lin(s21A), lin(s21B), recA, recB, inbA, ...
                rx.allowableInterference_dBm, rx.noise_dBm, reqA, reqB, ff, rff, ...
                cmeth, status, verdict, miss}]; %#ok<AGROW>
            % per-monitor band rows (exact CST monitors of the TX evaluation band)
            mons = []; if ~isempty(tcst); mons = tcst.freqs; elseif ~isempty(tfroz); mons = tfroz.freqs; end
            if strcmp(tband, 'S_TM'); mons = [2.2e9 2.25e9 2.3e9]; end
            for fm = mons
                gb = rfi_eval_set(tfroz, fm, dT);
                % Ka: A = aperture near-field equivalent gain Geq at the same monitor (same rule as pair rows)
                if ~isempty(tcst); ga = rfi_eval_set(tcst, fm, dT); else; ga = gb; end
                if ~isempty(kq); ga = kq.Geq_dBi(abs(KA.F - fm) < 1); end
                gr = NaN; if strcmp(rxStatus, 'OK'); gr = rfi_eval_set(rset, fm, dR); end
                bandRows{end+1} = {cs.caseId, pairId, tband, fm / 1e9, ga, gb, gr, fspl(fm, dist), ga + gr - fspl(fm, dist), ...
                    gb + gr - fspl(fm, dist), txCaseA, rxCase, rxStatus}; %#ok<AGROW>
            end
            % usage manifest (analysis basis)
            if ~isempty(tcst); aKey = tcst.key; aFiles = strjoin(tcst.files, ' | ');
            else; aKey = tfroz.key; aFiles = strjoin(tfroz.files, ' | '); end
            if isempty(rset); rSrc = 'NONE'; rFiles = rxStatus; else; rSrc = 'CST'; rFiles = strjoin(rset.files, ' | '); end
            usage{end+1} = {cs.caseId, pairId, 'TX', tx.systemId, ta.installationId, tband, 'A_PORT_CONSISTENT', ...
                txSrcA, txQA, aKey, txCaseA, aFiles}; %#ok<AGROW>
            usage{end+1} = {cs.caseId, pairId, 'TX', tx.systemId, ta.installationId, tband, 'B_REFERENCE_TX', ...
                'FROZEN', tfroz.quantity, tfroz.key, '', strjoin(tfroz.files, ' | ')}; %#ok<AGROW>
            usage{end+1} = {cs.caseId, pairId, 'RX', rx.systemId, ra.installationId, tband, 'A_and_B', ...
                rSrc, 'RealizedGain', [rfam '/' tband], rxCase, rFiles}; %#ok<AGROW>
            % engine cross-check: frozen patterns both ends at fc (same as the existing engine)
            rfrozKey = '';
            if strncmp(rx.systemId, 'S_TC', 4); rfrozKey = {[cs.sbaVariant '_TC']};
            elseif strncmp(rx.systemId, 'GPS', 3); rfrozKey = {['GPS_' cs.gpsBand]};
            else; rfrozKey = {'ISL_10P55', 'ISL_10P6', 'ISL_10P65'}; end
            rfz = frozen_set(B, rfrozKey);
            gtE = rfi_eval_set(tfroz, tx.fc_Hz, dT);
            rfzE = rfz; rfzE.validRange = [0 Inf]; rfzE.mode = 'BAND_REUSE';     % engine reuses single-frequency patterns at any f
            if numel(rfz.freqs) > 1; rfzE.xz = rfz.xz(2); rfzE.yz = rfz.yz(2); rfzE.freqs = rfz.freqs(2); end
            grE = rfi_eval_set(rfzE, tx.fc_Hz, dR);
            xRows{end+1} = {cs.caseId, pairId, gtE, grE, fspl(tx.fc_Hz, dist), gtE + grE - fspl(tx.fc_Hz, dist)}; %#ok<AGROW>
            % sensitivities ------------------------------------------------------------------
            if ~strcmp(rxStatus, 'OK')
                for gass = [-10 0 5]
                    s21 = lin(gA + gass - L); basis = 'ASSUMPTION (not computed data)';
                    if ~isempty(kq)            % Ka: near-field power density x assumed victim gain
                        s21 = 10 * log10(mean(10 .^ ((kq.Pref0_dBm + gass - tx.power_dBm) / 10)));
                        basis = 'ASSUMPTION_ONLY (victim Ka response missing; aperture near-field S x lambda^2/4pi x assumed gain; not a result)';
                    end
                    sensRows{end+1} = {'MISSING_RX_BAND_RESPONSE_BOUND', cs.caseId, pairId, sprintf('assumed victim gain %+d dBi', gass), ...
                        tx.power_dBm + s21, tx.power_dBm + s21 - rx.allowableInterference_dBm, s21, basis}; %#ok<AGROW>
                end
            end
            if strncmp(ta.installationId, 'KAA', 3)        % near-field gimbal screening (run_ka_nearfield_analysis.m)
                gi = find(strcmp(KA.gw.case_id, ['KA_NF_' ta.installationId '>' ra.installationId]) & ...
                    strcmp(KA.gw.gimbal_state, rfscreen.kaa.KaGimbalScreening.WORST));
                ai = find(strcmp(KA.asm.case_id, ['KA_NF_' ta.installationId '>' ra.installationId]) & ...
                    strcmp(KA.asm.gimbal_state, rfscreen.kaa.KaGimbalScreening.WORST));
                desc = sprintf('max-coupling steering theta_ap=%s deg, boresight %s off-ref %s deg (allowed=%s)', KA.gw.aperture_theta_deg{gi}, ...
                    KA.gw.boresight_B{gi}, KA.gw.off_axis_from_reference_deg{gi}, KA.gw.allowed_in_domain{gi});
                rv = str2double(KA.gw.P_port_band_dBm{gi});
                sensRows{end+1} = {'KAA_GIMBAL_MAX_COUPLING_NEAR_FIELD', cs.caseId, pairId, desc, rv, rv - rx.allowableInterference_dBm, ...
                    rv - tx.power_dBm, 'REFLECTOR_APERTURE_NEAR_FIELD; HEMISPHERE steering ASSUMPTION; DIRECT_REFLECTOR_FIELD_ONLY (ka_gimbal_worstcase.csv)'}; %#ok<AGROW>
                if ~isempty(ai)
                    p0 = str2double(KA.asm.P_ref0dBi_band_dBm{ai});
                    sensRows{end+1} = {'KAA_GIMBAL_MAX_COUPLING_ASSUMPTION_ONLY', cs.caseId, pairId, [desc '; assumed victim gain 0 dBi'], ...
                        p0, p0 - rx.allowableInterference_dBm, p0 - tx.power_dBm, ...
                        'ASSUMPTION_ONLY (victim Ka response missing; not a result)'}; %#ok<AGROW>
                end
            end
            if strcmp(tband, 'S_TM') && strcmp(rxStatus, 'OK') && strcmp(cs.caseId, 'CASE_SBA1_L1')
                fsi = [2.2e9 2.25e9 2.3e9]; dG = zeros(1, 3);
                for k = 1:3
                    dG(k) = rfi_eval_set(INST.(ta.installationId), fsi(k), dT) - rfi_eval_set(INST.FREE, fsi(k), dT);
                    if strcmp(rfam, 'S'); dG(k) = dG(k) + rfi_eval_set(INST.(ra.installationId), fsi(k), dR) - rfi_eval_set(INST.FREE, fsi(k), dR); end
                end
                sensRows{end+1} = {'S_PROVISIONAL_INSTALLED_DELTA', cs.caseId, pairId, sprintf('dG(2.2/2.25/2.3)=%.2f/%.2f/%.2f dB', dG), ...
                    recA + mean(dG), recA + mean(dG) - rx.allowableInterference_dBm, lin(s21A) + mean(dG), ...
                    'PROVISIONAL (RFC_S_LOW_*_R1P75 vs RFC_S_LOW_FREE_M4R10; extent/mesh not converged)'}; %#ok<AGROW>
            end
        end
    end
    % mode aggregates (linear power sum over the active TX of each mode)
    for mi = 1:numel(modes)
        cm = MB.buildCase(cs.caseId, struct('patternCache', cache, 'modeId', modes{mi}));
        aTx = cm.scenario.resolveActiveTxIds(); aRx = cm.scenario.resolveActiveRxIds();
        for ir = 1:numel(aRx)
            sumA = 0; nOk = 0; nMiss = 0; nSame = 0; top = ''; topv = -Inf; contrib = {};
            for it = 1:numel(aTx)
                pid = [aTx{it} '>' aRx{ir}];
                row = pairRows(cellfun(@(r) strcmp(r{1}, cs.caseId) && strcmp(r{4}, pid), pairRows));
                if isempty(row); continue; end
                r = row{1}; st = r{end-2}; v = r{35};
                if strcmp(st, 'NOT_EVALUATED'); nSame = nSame + 1; continue; end
                if isnan(v); nMiss = nMiss + 1; contrib{end+1} = [aTx{it} ':MISSING']; continue; end %#ok<AGROW>
                sumA = sumA + 10 ^ (v / 10); nOk = nOk + 1; contrib{end+1} = sprintf('%s:%.1f', aTx{it}, v); %#ok<AGROW>
                if v > topv; topv = v; top = aTx{it}; end
            end
            rxs = sysById(aRx{ir});
            agg = 10 * log10(sumA); if sumA == 0; agg = -Inf; end
            comp = 'COMPLETE'; if nMiss > 0; comp = 'PARTIAL_LOWER_BOUND (missing responses)'; end
            aggRows{end+1} = {cs.caseId, modes{mi}, aRx{ir}, numel(aTx), nOk, nMiss, nSame, agg, ...
                agg - rxs.allowableInterference_dBm, rxs.allowableInterference_dBm, top, topv, comp, strjoin(contrib, ' | ')}; %#ok<AGROW>
        end
    end
    logm(logf, '%s: %d TX x %d RX evaluated', cs.caseId, numel(txIds), numel(rxIds));
end

% ---- SAR (no bound pattern): assumption-based sensitivity using actual victim SAR-band responses ----
sm = mounts('SAR_ANT');
TSAR = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(dsDir, 'rf_systems.csv'));
isar = find(strcmp(TSAR.system_id, 'SAR_X_TX'));
sLo = (str2double(TSAR.fc_mhz{isar}) - str2double(TSAR.bw_mhz{isar}) / 2) * 1e6;
sHi = (str2double(TSAR.fc_mhz{isar}) + str2double(TSAR.bw_mhz{isar}) / 2) * 1e6;
pSar = [str2double(TSAR.tx_power_dbm{isar}) str2double(TSAR.tx_power_screen_dbm{isar})];
c1 = MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache));
victims = {'S_TC_RX@SBA_NADIR', 'SBA_NADIR', 'S'; 'S_TC_RX@SBA_ZENITH', 'SBA_ZENITH', 'S'; 'ISL_X_RX', 'ISL', 'ISL'; ...
    'GPS_L1_RX@GPSA_1', 'GPSA_1', 'L'; 'GPS_L1_RX@GPSA_2', 'GPSA_2', 'L'};
sarRows = {};
for v = 1:size(victims, 1)
    vm = mounts(victims{v, 2}); d = vm.p - sm.p; dist = norm(d); dR = vm.R' * (-d / dist);
    rs = CST.(victims{v, 3}).SAR;
    vs = c1.rfSystems(strcmp({c1.rfSystems.systemId}, victims{v, 1}));
    los = rfscreen.geometry.LineOfSight.segment('SAR_ANT', victims{v, 2}, sm.p, vm.p, model.structures);
    fs = linspace(sLo, sHi, nSamples);
    if isempty(rs)
        sarRows{end+1} = {'SAR_TX(hyp)', victims{v, 1}, dist, los.status, NaN, NaN, NaN, NaN, NaN, NaN, vs.allowableInterference_dBm, 'INPUT_MISSING', ...
            'no L-antenna response in the SAR band (CST MESH_LIMIT)'}; %#ok<AGROW>
        continue;
    end
    gR = arrayfun(@(f) rfi_eval_set(rs, f, dR), fs); Lf = arrayfun(@(f) fspl(f, dist), fs);
    base = 10 * log10(mean(10 .^ ((gR - Lf) / 10)));      % coupling excluding the SAR antenna gain
    for gs = [-10 0 10]
        for pp = pSar
            sarRows{end+1} = {'SAR_TX(hyp)', victims{v, 1}, dist, los.status, mean(gR), base, gs, pp, pp + gs + base, ...
                pp + gs + base - vs.allowableInterference_dBm, vs.allowableInterference_dBm, 'ASSUMPTION_SENSITIVITY', ...
                'SAR pattern not bound: SAR gain toward victim is an assumed parameter; victim SAR-band RealizedGain is CST data'}; %#ok<AGROW>
        end
    end
end
% SAR as victim: interferer side only (SAR antenna gain unknown)
ctx = MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache));
txList = ctx.scenario.transmitters.keys();
for it = 1:numel(txList)
    t = ctx.rfSystems(strcmp({ctx.rfSystems.systemId}, txList{it}));
    tsys = ctx.scenario.transmitters(txList{it}); tan = ctx.scenario.antennas(tsys.antennaId); tm = mounts(tan.installationId);
    d = sm.p - tm.p; dist = norm(d); dT = tm.R' * (d / dist);
    if strncmp(t.systemId, 'KA', 2)          % KAA TX -> SAR RX: near field; SAR Ka response missing (no 0 dBi result)
        q = rfi_ka_point(KA.model, KA.F, t.power_dBm, tm.p, rfscreen.kaa.CstLocalFrameAdapter.fixedMount(tm.n), sm.p, ...
            rfscreen.kaa.CstLocalFrameAdapter.fixedMount(sm.n), rfscreen.kaa.KaVictimResponse.fromRepository(repo, 'SAR'));
        sarRows{end+1} = {t.systemId, 'SAR_X_RX', dist, '', 10 * log10(mean(10 .^ (q.Geq_dBi / 10))), NaN, NaN, t.power_dBm, ...
            NaN, NaN, NaN, 'INPUT_MISSING (KA_FUNDAMENTAL_OOB_BLOCKING)', sprintf(['REFLECTOR_APERTURE_NEAR_FIELD: S = %.2f dBm/m2 at the SAR mount ' ...
            '(3-monitor mean; DIRECT_REFLECTOR_FIELD_ONLY); SAR antenna Ka response NO_PATTERN_BOUND -> port power not evaluated; ' ...
            'see ka_nearfield_pair_results.csv'], q.S_band_dBmpm2)}; %#ok<AGROW>
        continue;
    end
    if strncmp(t.systemId, 'S_TM', 4); ts = CST.S.S_TM; else; ts = CST.ISL.ISL; end
    g = rfi_eval_set(ts, t.fc_Hz, dT);
    sarRows{end+1} = {t.systemId, 'SAR_X_RX(hyp)', dist, '', g, g - fspl(t.fc_Hz, dist), NaN, t.power_dBm, ...
        t.power_dBm + g - fspl(t.fc_Hz, dist), NaN, NaN, 'PARTIAL_INTERFERER_SIDE_ONLY', ...
        'level at a 0 dBi reference antenna at the SAR mount; add the (unknown) SAR gain and SAR receiver criteria'}; %#ok<AGROW>
end

% ---- write results ----
pairHdr = {'case_id', 'sba_variant', 'gps_band', 'pair_id', 'tx_system', 'tx_mount', 'tx_family', 'rx_system', 'rx_mount', 'rx_family', ...
    'tx_band_lo_ghz', 'tx_band_hi_ghz', 'rx_band_lo_ghz', 'rx_band_hi_ghz', 'freq_relation', 'tx_power_dbm_at_antenna_input', ...
    'distance_m', 'los', 'blocking_panels', 'tx_off_boresight_deg', 'tx_phi_local_deg', 'rx_off_boresight_deg', 'rx_phi_local_deg', ...
    'tx_gain_A_dbi', 'tx_source_A', 'tx_quantity_A', 'tx_gain_B_ref_dbi', 'rx_gain_dbi', 'rx_source', 'rx_quantity', 'rx_cst_case', ...
    'fspl_fc_db', 's21_A_db', 's21_B_db', 'oob_blocker_port_A_dbm', 'oob_blocker_port_B_dbm', 'inband_interference_A_dbm', ...
    'allowable_dbm', 'noise_dbm', 'screening_suppression_to_inband_limit_A_db', 'screening_suppression_to_inband_limit_B_db', 'far_field', 'far_field_distance_m', ...
    'coupling_method', 'status', 'verdict', 'missing_reason'};
writeTable(fullfile(outDir, 'pair_results.csv'), pairHdr, pairRows);
writeTable(fullfile(outDir, 'band_results.csv'), {'case_id', 'pair_id', 'tx_band', 'monitor_ghz', 'tx_gain_cst_realized_dbi', ...
    'tx_gain_frozen_ref_dbi', 'rx_gain_cst_realized_dbi', 'fspl_db', 's21_A_db', 's21_B_db', 'tx_cst_case', 'rx_cst_case', 'rx_status'}, bandRows);
writeTable(fullfile(outDir, 'aggregate_by_victim.csv'), {'case_id', 'mode_id', 'victim', 'n_active_tx', 'n_evaluated', 'n_missing', ...
    'n_same_port', 'aggregate_oob_blocker_port_A_dbm', 'aggregate_screening_suppression_to_inband_limit_db', 'allowable_dbm', 'top_interferer', ...
    'top_received_dbm', 'completeness', 'contributions_dbm'}, aggRows);
writeTable(fullfile(outDir, 'sensitivity.csv'), {'kind', 'case_id', 'pair_id', 'assumption', 'received_dbm', 'screening_suppression_to_inband_limit_db', ...
    's21_db', 'basis'}, sensRows);
writeTable(fullfile(outDir, 'sar_assessment.csv'), {'interferer', 'victim', 'distance_m', 'los', 'victim_or_tx_gain_dbi', ...
    'coupling_excl_sar_gain_db', 'assumed_sar_gain_dbi', 'power_dbm', 'received_dbm', 'screening_suppression_to_inband_limit_db', 'allowable_dbm', 'status', 'note'}, sarRows);
writeTable(fullfile(outDir, 'pattern_usage_manifest.csv'), {'case_id', 'pair_id', 'side', 'system', 'mount', 'evaluated_band', 'variant', ...
    'source', 'quantity', 'pattern_key', 'cst_case', 'files'}, usage);
for k = 1:numel(xRows)
    e = engRows(cellfun(@(r) strcmp(r{1}, xRows{k}{1}) && strcmp([r{2} '>' r{3}], xRows{k}{2}), engRows));
    if isempty(e); xRows{k}(end+1:end+3) = {NaN, NaN, 'ENGINE_ROW_MISSING'};
    else; xRows{k}(end+1:end+3) = {e{1}{7}, xRows{k}{6} - e{1}{7}, e{1}{9}}; end
end
writeTable(fullfile(outDir, 'engine_crosscheck.csv'), {'case_id', 'pair_id', 'tx_gain_frozen_dbi', 'rx_gain_frozen_dbi', 'fspl_db', ...
    's21_evaluator_db', 's21_engine_db', 'difference_db', 'engine_coupling_validity'}, xRows);
dx = cellfun(@(r) r{8}, xRows); dx = dx(isfinite(dx));
logm(logf, 'Engine cross-check: %d pairs, max |evaluator - engine| S21 = %.3f dB, mean %.3f dB', numel(dx), max(abs(dx)), mean(abs(dx)));
logm(logf, 'Rows: pairs %d, band %d, aggregates %d, sensitivity %d, SAR %d, usage %d', numel(pairRows), numel(bandRows), ...
    numel(aggRows), numel(sensRows), numel(sarRows), numel(usage));
fclose(logf);

