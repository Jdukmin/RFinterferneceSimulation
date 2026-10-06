1;  % Octave script with local functions -- KAA victim-band antenna response (Tier 3 bound) -> victim-port PSD
% =============================================================================================
% Chain:  ITU-compliant unwanted emission at the KAA antenna input (data/rfi_psd/kaa_itu_spurious_source.csv)
%         -> KAA antenna-only radiation response at f_victim (Tier-3 ENGINEERING_BOUND, no pattern exists)
%         -> free-space coupling (FSPL) -> victim antenna G_rx(f_victim) (CST, as in run_psd_analysis.m)
%         -> victim-port PSD -> allowable PSD -> margin / required additional suppression.
%   PSD_RX = PSD_TX_spurious + G_KAA(f_victim) - FSPL + G_RX(f_victim)         [dBm/Hz]
% NO WR-42 cutoff / feed-line / BPF / diplexer / PA-internal attenuation (0 dB; instruction). ITU source suppression and the
% antenna gain are separate terms and are reported separately. A missing victim response is never replaced by 0 dBi.
% Steps: (1) feasibility classification, (2) per-band response table (data/antenna_port_response_cst/KAA),
%        (3) gimbal screening (OUTWARD_HEMISPHERE_SCREENING), (4) victim-port PSD for 0/10/20 dBi and the Tier-3 bound.
% No CST run, no frozen-file change. From the repository root:
%   octave-cli --no-gui --norc --eval "run('output/claude/run_kaa_victimband_analysis.m')"
% =============================================================================================

function logm(fid, varargin)
    s = sprintf(varargin{:}); fprintf(fid, '%s\n', s); fprintf('%s\n', s);
end

function v = ifelse(c, a, b)
    if c; v = a; else; v = b; end
end

function s = csvnum(x)
    if ischar(x); s = x; return; end
    if islogical(x); x = double(x); end
    if isempty(x) || isnan(x); s = 'NaN'; elseif isinf(x); if x < 0; s = '-Inf'; else; s = 'Inf'; end
    else; s = sprintf('%.4f', x); end
end

function writeTable(path, header, rows)
    fid = fopen(path, 'w');
    fprintf(fid, '%s\n', strjoin(header, ','));
    for i = 1:numel(rows)
        r = rows{i}; c = cell(1, numel(r));
        for j = 1:numel(r); c{j} = csvnum(r{j}); end
        fprintf(fid, '%s\n', strjoin(strrep(c, ',', ';'), ','));
    end
    fclose(fid);
end

function rows = addRow(rows, item, status, evidence)
    rows{end+1} = {item, status, evidence};
end

function v = nmax(x)
    x = x(~isnan(x)); if isempty(x); v = NaN; else; v = max(x); end
end

function v = nmin(x)
    x = x(~isnan(x)); if isempty(x); v = NaN; else; v = min(x); end
end

function st = worstStatus(s)
    if any(strcmp(s, 'FAIL')); st = 'FAIL';
    elseif all(strcmp(s, 'PASS')); st = 'PASS';
    else; o = s(~strcmp(s, 'PASS') & ~strcmp(s, 'FAIL')); st = o{1}; end
end

% ------------------------------------------------------------------------------------------------
here = fileparts(mfilename('fullpath'));
if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'src')); addpath(fullfile(here, 'code'));
outDir = fullfile(here, 'results'); if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
kaaDir = fullfile(repo, 'data', 'antenna_port_response_cst', 'KAA'); if exist(kaaDir, 'dir') ~= 7; mkdir(kaaDir); end
logf = fopen(fullfile(outDir, 'kaa_vb_run_log.txt'), 'w');
pv = rfi_provenance(repo, outDir, 'run_kaa_victimband_analysis.m', 'KAA victim-band Tier-3 bound -> victim-port PSD');
logm(logf, 'KAA victim-band run %s (GNU Octave %s); analysis base commit %s, working tree %s', pv.run_time, OCTAVE_VERSION, ...
    pv.analysis_base_commit, pv.working_tree);

Kb = rfscreen.kaa.KaaVictimBandBound; P = rfscreen.psd.PsdMath; V = rfscreen.psd.VictimBandPsdPath;
RB = rfscreen.psd.ReceiverBaseline; C = rfscreen.psd.VictimBandCoupling; A = rfscreen.kaa.CstLocalFrameAdapter;
GS = rfscreen.kaa.KaGimbalScreening;
psdDir = fullfile(repo, 'data', 'rfi_psd');
B = RB.read(fullfile(psdDir, 'receiver_baseline.csv'));
masks = rfscreen.psd.EmissionMaskTable.read(fullfile(psdDir, 'kaa_itu_spurious_source.csv'));
F0 = rfscreen.psd.FilterScenario('KAA_NO_ADDITIONAL_SUPPRESSION_0DB', 'FLAT', [], 0, ...
    'WR42_CUTOFF_FEED_FILTER_ATTENUATION_EXCLUDED_BY_INSTRUCTION (0 dB, no design basis)');
prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));
D = Kb.reflectorDiameter_m(repo);
carrier = 10 * log10(70e3);   % rf_systems.csv KA_DLS_TX 70 W (checked below)
RD = rfscreen.spacecraft.SpacecraftDataReader;
dsDir = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
T = RD.readTable(fullfile(dsDir, 'rf_systems.csv'));
carrier = str2double(T.tx_power_dbm{find(strcmp(T.system_id, 'KA_DLS_TX@KAA_1'), 1)});
logm(logf, 'KAA: D = %.0f mm (validated equivalent paraboloid), carrier power %.3f dBm; ITU sources: %d rows', D * 1e3, carrier, numel(masks));

% =========================== 1. feasibility classification ===========================
fd = jsondecode(fileread(fullfile(repo, 'cst', 'results', 'KA_FEED_C_OEWG', 'feed_pattern.json')));
feedGHz = sort(cellfun(@(n) str2double(strrep(regexprep(n, '^x', ''), '_', '.')), fieldnames(fd)).');
rv = jsondecode(fileread(fullfile(repo, 'cst', 'results', 'KA_REFLECTOR_KA_FEED_C_OEWG', 'reflector_validation.json')));
geomV2 = exist(fullfile(repo, 'cst', 'projects', 'SPACECRAFT_KA_MODEL_ONLY_V2.cst'), 'file') == 2;
bands = { ...   % key, label, f_lo, f_center, f_hi (GHz)
    'ISL',  'ISL X-band 10.55-10.65 GHz',  10.55,    10.6,     10.65; ...
    'SAR',  'SAR X-band ~9.65 GHz',        9.3875,   9.65,     9.9125; ...
    'S_TC', 'S-band RX 2.025-2.110 GHz',   2.025,    2.0675,   2.110; ...
    'L1',   'GPS L1 1.575 GHz',            1.563,    1.57542,  1.588; ...
    'L2',   'GPS L2 1.228 GHz',            1.21737,  1.2276,   1.23783; ...
    'L5',   'GPS L5 1.176 GHz',            1.164,    1.17645,  1.189};
Dmm = D * 1e3; Fe = rv.reflector.Fe_mm; depth = (Dmm / 2) ^ 2 / (4 * Fe);
feRows = {}; cellsEst = containers.Map();
for b = 1:size(bands, 1)
    lamHi = 299.792458 / bands{b, 5}; lamLo = 299.792458 / bands{b, 3}; pad = lamLo / 4;
    est = @(s) prod(ceil([Dmm + 2 * pad, Dmm + 2 * pad, depth + 2 * pad] / (lamHi / s)));
    cellsEst(bands{b, 1}) = [est(10) est(5)];
end
feRows = addRow(feRows, 'CLASSIFICATION', Kb.CLASSIFICATION, 'FULL_REFLECTOR_VICTIM_BAND_AVAILABLE / EQUIVALENT_REFLECTOR_MODEL_AVAILABLE / FEED_ONLY_AVAILABLE all not met at L/S/X; see rows below');
feRows = addRow(feRows, 'KAA_REFLECTOR_GEOMETRY_IN_CST_SOLVER', ifelse(geomV2, 'GEOMETRY_ONLY_NOT_SOLVED', 'NOT_FOUND'), ...
    'AnalyticalFace paraboloid D=220 mm exists only in cst/projects/SPACECRAFT_KA_MODEL_ONLY_V2.cst (separate untracked workspace; no ports/mesh/solver); no reflector is solved anywhere');
feRows = addRow(feRows, 'KAA_CST_SOLVER_MODEL', 'FEED_ONLY', sprintf('KA_FEED_C_OEWG open-ended circular waveguide, CST monitors %s GHz only', strjoin(arrayfun(@(x) sprintf('%g', x), feedGHz, 'UniformOutput', false), '/')));
feRows = addRow(feRows, 'KAA_REFLECTOR_STAGE', 'NON_CST_EQUIVALENT_PARABOLOID_KA_ONLY', sprintf('%s; D=%.0f mm Fe=%.1f mm Ds=%.0f mm; anchors %s; needs the Ka feed pattern -> defined only at the CST feed monitors', ...
    rv.reflector.stage, rv.reflector.D_mm, rv.reflector.Fe_mm, rv.reflector.Ds_mm, rv.status));
feRows = addRow(feRows, 'KAA_FEED_PATTERN_AT_VICTIM_BANDS', 'INPUT_MISSING', 'feed_pattern.json holds 25.5/26.25/27 GHz only; the 26 GHz pattern/aperture illumination is NOT extrapolated to L/S/X');
feRows = addRow(feRows, 'VICTIM_BAND_EXCITATION_DEFINITION', 'UNDEFINED', ['how unwanted energy at f_victim reaches the radiating structure (feed throat / flange / port impedance) is exactly the WR-42 / feed-chain behaviour ' ...
    'excluded by instruction; without an excitation definition a full-wave KAA solve has no source']);
feRows = addRow(feRows, 'ACTUAL_CASSEGRAIN_CAD', 'INPUT_MISSING', 'feed horn / subreflector / struts / WR-42 chain / hinge CAD not in the repository (equivalent paraboloid only)');
feRows = addRow(feRows, 'LEARNING_EDITION_MESH', 'ESTIMATE_ONLY_NOT_DEMONSTRATED', ['limit 100000 cells; uniform-hex estimate of the bare PEC reflector (lambda_hi/10, lambda_lo/4 padding) in feasibility rows; ' ...
    'CST Mesh.Update was attempted in this task and did not return (aborted after 420 s) -> no solver-verified cell count']);
for b = 1:size(bands, 1)
    ce = cellsEst(bands{b, 1});
    feRows = addRow(feRows, ['MESH_ESTIMATE_' bands{b, 1}], ifelse(ce(1) < 1e5, 'BARE_REFLECTOR_BELOW_LIMIT_FEED_AND_HULL_NOT_INCLUDED', 'ABOVE_LIMIT'), ...
        sprintf('%s: ~%d cells at lambda/10, ~%d at lambda/5 (reflector surface only, lower bound; feed/subreflector/hull add cells)', bands{b, 2}, ce(1), ce(2)));
end
feRows = addRow(feRows, 'FULL_REFLECTOR_VICTIM_BAND_REQUIRES', 'NEXT_INPUT', ['real Cassegrain CAD + feed-throat excitation definition at f_victim + a solver beyond the Learning Edition 100k-cell limit ' ...
    '(or the licensed T/I/asymptotic solver) -> Tier 1; or a victim-band feed pattern (measured/CST) for the Tier-2 equivalent paraboloid']);
writeTable(fullfile(outDir, 'kaa_vb_model_feasibility.csv'), {'item', 'status', 'evidence'}, feRows);
logm(logf, 'Classification: %s (feed-only CST at Ka; reflector stage non-CST; no feed pattern or excitation below Ka)', Kb.CLASSIFICATION);

% =========================== 2. per-band response table (Tier 3) ===========================
respRows = {};
for b = 1:size(bands, 1)
    for f = [bands{b, 3}, bands{b, 4}, bands{b, 5}]
        fH = f * 1e9; ap = Kb.apertureBound_dBi(fH, D); sp = Kb.sphereBound_dBi(fH, D / 2);
        sp15 = Kb.sphereBound_dBi(fH, Kb.SPHERE_RADIUS_FACTOR * D / 2); gm = Kb.bound_dBi(fH, D);
        respRows{end+1} = {bands{b, 1}, bands{b, 2}, f, Kb.MODEL_TYPE, Kb.TIER, Kb.CLASSIFICATION, Kb.REFLECTOR_INCLUDED, ...
            'GEOMETRY_ONLY_NOT_SOLVED', 'DIRECTIVITY_UPPER_BOUND (ceiling on RealizedGain; mismatch/ohmic loss only lower it)', ...
            'NOT_CST (analytical ceiling)', gm, ap, sp, max(ap, sp15), 0, 10, 20, ...
            'NOT_COMPUTABLE_NO_PATTERN (<= peak ceiling)', 'NOT_AVAILABLE (no pattern)', 'NOT_AVAILABLE (no pattern)', ...
            'NOT_APPLICABLE (no pattern; not normalised to a CST accepted-power)', Kb.applicability(fH, D), Kb.TAGS, ...
            'max(4piA/lambda^2 [A=pi D^2/4, eta=1]; (ka)^2+2ka [a=D/2])'}; %#ok<AGROW>
    end
end
respHdr = {'victim_band', 'description', 'frequency_ghz', 'model_type', 'fidelity_tier', 'classification', 'reflector_included', ...
    'reflector_geometry_status', 'realized_gain_vs_directivity', 'cst_analytical_bounded', 'peak_gain_ceiling_dbi', ...
    'aperture_bound_dbi', 'sphere_bound_dbi', 'sphere_bound_a_1p5x_sensitivity_dbi', 'sensitivity_dbi_a', 'sensitivity_dbi_b', 'sensitivity_dbi_c', ...
    'victim_direction_gain', 'xz_realized_gain_cut', 'yz_realized_gain_cut', 'normalization_validity', 'applicability_regime', ...
    'tags', 'formula'};
writeTable(fullfile(kaaDir, 'kaa_victim_band_response.csv'), respHdr, respRows);
logm(logf, 'Tier-3 ceilings at band centres: %s', strjoin(arrayfun(@(b) sprintf('%s %.2f dBi', bands{b, 1}, Kb.bound_dBi(bands{b, 4} * 1e9, D)), 1:size(bands, 1), 'UniformOutput', false), '; '));

% =========================== 3/4. gimbal screening and victim-port PSD ===========================
model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
pos = containers.Map(); nrm = containers.Map();
for i = 1:numel(model.installationRecords)
    rc = model.installationRecords(i); pn = model.panels(strcmp({model.panels.id}, rc.panelId));
    pos(rc.antennaId) = rc.position_m(:); nrm(rc.antennaId) = pn.normal_B(:);
end
victims = { ...   % receiver template, mount, family, victim band
    'S_TC_RX', 'SBA_NADIR', 'S', 'S_TC'; 'S_TC_RX', 'SBA_ZENITH', 'S', 'S_TC'; ...
    'GPS_L1_RX', 'GPSA_1', 'L', 'L1'; 'GPS_L2_RX', 'GPSA_1', 'L', 'L2'; 'GPS_L5_RX', 'GPSA_1', 'L', 'L5'; ...
    'GPS_L1_RX', 'GPSA_2', 'L', 'L1'; 'GPS_L2_RX', 'GPSA_2', 'L', 'L2'; 'GPS_L5_RX', 'GPSA_2', 'L', 'L5'; ...
    'SAR_X_RX', 'SAR_ANT', 'SAR', 'SAR'; 'ISL_X_RX', 'ISL', 'ISL', 'ISL'};
nF = 21; resp = containers.Map();
gimRows = {}; psdRows = {}; sumRows = {}; cplRows = {};
for ka = {'KAA_1', 'KAA_2'}
    pK = pos(ka{1}); dom = model.steering(ka{1});
    for q = 1:size(victims, 1)
        rt = victims{q, 1}; mv = victims{q, 2}; fam = victims{q, 3}; vb = victims{q, 4};
        b = RB.lookup(B, rt); f = RB.tuningSweep(b, nF);
        pV = pos(mv); d_B = pV - pK; dist = norm(d_B); v = d_B / dist;
        Rv = A.fixedMount(nrm(mv)); dR = A.bodyToLocal(Rv, -v);
        rk = [fam '/' vb];
        if ~resp.isKey(rk)
            try; resp(rk) = rfscreen.psd.BandResponse.fromRepository(repo, fam, vb, prov);
            catch err; resp(rk) = rfscreen.psd.BandResponse.missing(fam, vb, ['response lookup failed: ' err.message]); end
        end
        rr = resp(rk);
        los = rfscreen.geometry.LineOfSight.segment(ka{1}, mv, pK, pV, model.structures);
        nAxis = dom.referenceAxis_B; alpha = atan2d(norm(cross(nAxis, v)), dot(nAxis, v));
        [uDir, thDir] = GS.nearestAllowed(dom, v);
        fsplV = P.fspl(f, dist); gb = Kb.bound_dBi(f, D); ffr = Kb.farFieldRatio(f, D, dist);
        grx = NaN(1, nF);
        if rr.isAvailable(); for k = 1:nF; grx(k) = rr.gainAt(vb, f(k), dR); end; end
        rxSrc = ifelse(rr.isAvailable(), sprintf('CST %s %s/%s RealizedGain', rr.cstCase, fam, vb), [rr.status ': ' rr.reason]);
        specs = rfscreen.psd.EmissionMaskTable.select(masks, 'KA_DLS_TX', vb);
        if isempty(specs); error('no ITU source row for KA_DLS_TX / %s', vb); end
        srcPsd = max(cellfun(@(s) s.psdDbmHz(carrier), specs));
        key = [ka{1} '>' mv ':' vb];
        % ---- gimbal states: a ceiling carries no pattern shape, so every state shares the same ceiling ----
        states = {'NOMINAL_GIMBAL_REFERENCE', nAxis, alpha; 'VICTIM_DIRECTED_OR_NEAREST_ALLOWED', uDir, thDir; ...
            'MAX_COUPLING_ALLOWED', uDir, thDir};
        for s = 1:3
            gimRows{end+1} = {key, ka{1}, mv, vb, states{s, 1}, sprintf('%.4f;%.4f;%.4f', states{s, 2}), dom.steeringModel, dom.maxOffAxis_deg, ...
                'OUTWARD_HEMISPHERE_SCREENING (SIMPLIFIED_ASSUMPTION; no hard-stop/keep-out/shadowing data)', alpha, states{s, 3}, ...
                ifelse(alpha <= dom.maxOffAxis_deg, 'VICTIM_IN_OUTWARD_HEMISPHERE (boresight can be aimed at the victim)', 'VICTIM_BEHIND_HEMISPHERE (boresight cannot reach; ceiling not tightened)'), dist, los.status, ...
                nmax(gb), 'CEILING_APPLIES_TO_EVERY_POINTING (no pattern shape)', Kb.TAGS}; %#ok<AGROW>
        end
        % ---- victim-port PSD per gain scenario ----
        scen = {'TIER3_BOUND', gb; 'SENS_0DBI', 0 * f; 'SENS_10DBI', 10 + 0 * f; 'SENS_20DBI', 20 + 0 * f};
        for s = 1:size(scen, 1)
            gk = scen{s, 2}; cCond = gk + grx - fsplV;
            R = V.evaluate(f, cCond, NaN(1, nF), b.allowable_psd_dBmHz, specs, carrier, F0, NaN, true);
            st = R.status;
            if ~rr.isAvailable(); st(:) = {'VICTIM_RX_RESPONSE_MISSING_NO_PORT_PSD'}; end
            flux = srcPsd + gk - fsplV;                        % PSD before G_rx: no victim-antenna term
            above = max(gk - gb) > 1e-9;
            for k = 1:nF
                psdRows{end+1} = {key, ka{1}, mv, rt, vb, f(k), scen{s, 1}, ifelse(strcmp(scen{s, 1}, 'TIER3_BOUND'), 3, 3), ...
                    srcPsd, gk(k), fsplV(k), grx(k), flux(k), R.port_psd_dBmHz(k), R.allowable_dBmHz(k), R.margin_dB(k), ...
                    R.required_add_supp_dB(k), st{k}, ffr(k), ifelse(ffr(k) < 1, 'NEARFIELD_FRIIS_UNVERIFIED', 'FARFIELD_FRIIS_VALID'), ...
                    ifelse(above, 'SENSITIVITY_EXCEEDS_PHYSICAL_CEILING', ''), los.status}; %#ok<AGROW>
            end
            rs = ifelse(rr.isAvailable(), worstStatus(st), 'VICTIM_RX_RESPONSE_MISSING_NO_PORT_PSD');
            sumRows{end+1} = {key, ka{1}, mv, rt, vb, sprintf('%.4f-%.4f MHz', f(1) / 1e6, f(end) / 1e6), scen{s, 1}, nmax(gk), srcPsd, ...
                nmax(fsplV), nmin(fsplV), nmax(grx), nmax(flux), nmax(R.port_psd_dBmHz), b.allowable_psd_dBmHz, nmin(R.margin_dB), ...
                nmax(R.required_add_supp_dB), rs, rxSrc, dist, los.status, nmin(ffr), ifelse(nmin(ffr) < 1, 'NEARFIELD_FRIIS_UNVERIFIED', 'FARFIELD_FRIIS_VALID'), ...
                ifelse(above, 'SENSITIVITY_EXCEEDS_PHYSICAL_CEILING', ''), Kb.TAGS}; %#ok<AGROW>
        end
        cplRows{end+1} = {key, ka{1}, mv, vb, dist, alpha, thDir, los.status, nmax(gb + grx - fsplV), nmax(0 - fsplV + grx), nmax(10 - fsplV + grx), ...
            nmax(20 - fsplV + grx), nmax(grx), rxSrc, 'MAX over allowed gimbal range = ceiling (OUTWARD_HEMISPHERE_SCREENING)', Kb.TAGS}; %#ok<AGROW>
        sc = sumRows{end - 3};
        logm(logf, '%-26s d=%.3f m alpha=%6.1f deg LOS %-8s ceiling %.2f dBi | PSD %s dBm/Hz vs %.1f -> add. supp. %s dB (%s)', key, dist, alpha, los.status, ...
            nmax(gb), csvnum(sc{14}), b.allowable_psd_dBmHz, csvnum(sc{17}), sc{18});
    end
end

writeTable(fullfile(outDir, 'kaa_vb_gimbal.csv'), {'pair', 'kaa', 'victim_mount', 'victim_band', 'gimbal_state', 'boresight_B', 'steering_model', ...
    'domain_limit_deg', 'domain_provenance', 'victim_angle_from_reference_deg', 'boresight_to_victim_deg', 'victim_reachability', 'distance_m', 'los', ...
    'kaa_gain_ceiling_dbi', 'gain_basis', 'tags'}, gimRows);
writeTable(fullfile(outDir, 'kaa_vb_psd_results.csv'), {'pair', 'kaa', 'victim_mount', 'victim_receiver', 'victim_band', 'frequency_hz', 'kaa_gain_scenario', ...
    'fidelity_tier', 'itu_source_psd_dbm_hz_at_antenna_port', 'kaa_gain_dbi', 'fspl_db', 'victim_gain_dbi', 'psd_before_victim_gain_dbm_hz', ...
    'victim_port_psd_dbm_hz', 'allowable_psd_dbm_hz', 'psd_margin_db', 'required_additional_suppression_db', 'status', 'distance_over_rff', ...
    'friis_validity', 'scenario_flag', 'los'}, psdRows);
writeTable(fullfile(outDir, 'kaa_vb_pair_summary.csv'), {'pair', 'kaa', 'victim_mount', 'victim_receiver', 'victim_band', 'victim_frequency_range', ...
    'kaa_gain_scenario', 'kaa_gain_dbi_max', 'itu_source_psd_dbm_hz_at_antenna_port', 'fspl_max_db', 'fspl_min_db', 'victim_gain_dbi_max', ...
    'psd_before_victim_gain_max_dbm_hz', 'victim_port_psd_max_dbm_hz', 'allowable_psd_dbm_hz', 'psd_margin_min_db', ...
    'required_additional_suppression_max_db', 'result_status', 'victim_response_source', 'distance_m', 'los', 'distance_over_rff_min', ...
    'friis_validity', 'scenario_flag', 'tags'}, sumRows);
writeTable(fullfile(outDir, 'kaa_vb_max_coupling.csv'), {'pair', 'kaa', 'victim_mount', 'victim_band', 'distance_m', 'victim_angle_from_reference_deg', ...
    'boresight_to_victim_deg', 'los', 'coupling_ceiling_max_db', 'coupling_0dbi_max_db', 'coupling_10dbi_max_db', 'coupling_20dbi_max_db', ...
    'victim_gain_dbi_max', 'victim_response_source', 'scope', 'tags'}, cplRows);
logm(logf, 'Rows: gimbal %d, PSD %d, pair summary %d, max coupling %d, feasibility %d, response %d', numel(gimRows), numel(psdRows), numel(sumRows), ...
    numel(cplRows), numel(feRows), numel(respRows));
fclose(logf);
