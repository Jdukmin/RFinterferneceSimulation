1;  % Octave script with local functions -- KAA reflector-aperture near-field RFI (output/claude)
% =============================================================================================
% KAA (Ka 25.5-27 GHz TX) -> S_TC / GPS / SAR / ISL RX, source model REFLECTOR_APERTURE_NEAR_FIELD.
%   source  : validated KAA model re-used as-is (CST feed KA_FEED_C_OEWG + equivalent-paraboloid
%             aperture, cst/results/KA_REFLECTOR_KA_FEED_C_OEWG, data/Kaband_KAA_CST)  -> src/+rfscreen/+kaa
%   path    : KA_FUNDAMENTAL_OOB_BLOCKING (victim Ka out-of-band response) kept apart from
%             KA_SPUR_INBAND (victim in-band gain + KAA emission mask -> INPUT_MISSING)
%   scope   : DIRECT_REFLECTOR_FIELD_ONLY, STRUCTURE_SCATTERING_NOT_MODELED (not an upper bound)
% No CST run, no geometry change, no frozen-file change. From the repository root:
%   octave-cli --no-gui --norc --eval "run('output/claude/run_ka_nearfield_analysis.m')"
% =============================================================================================

function logm(fid, varargin)
    s = sprintf(varargin{:}); fprintf(fid, '%s\n', s); fprintf('%s\n', s);
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
        c = strrep(c, ',', ';');
        fprintf(fid, '%s\n', strjoin(c, ','));
    end
    fclose(fid);
end

function v = ifelse(c, a, b)
    if c; v = a; else; v = b; end
end

function s = vec(v)
    s = sprintf('%.4f;%.4f;%.4f', v(1), v(2), v(3));
end

% ------------------------------------------------------------------------------------------------
here = fileparts(mfilename('fullpath'));
if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
repo = fileparts(fileparts(here));
addpath(fullfile(repo, 'src')); addpath(fullfile(here, 'code'));
outDir = fullfile(here, 'results'); if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
logf = fopen(fullfile(outDir, 'ka_nearfield_run_log.txt'), 'w');
logm(logf, 'KAA aperture near-field RFI run %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
logm(logf, 'Environment: GNU Octave %s on %s (MATLAB not used)', OCTAVE_VERSION, computer());
pv = rfi_provenance(repo, outDir, 'run_ka_nearfield_analysis.m', 'Ka near-field (appendix; secondary blocker)');
logm(logf, 'Analysis base commit (HEAD at run time; results are committed on top of it): %s, working tree %s', pv.analysis_base_commit, pv.working_tree);
t0 = tic;

A = rfscreen.kaa.CstLocalFrameAdapter; S = rfscreen.kaa.ApertureNearFieldSolver;
K = rfscreen.kaa.KaRfiPath; GS = rfscreen.kaa.KaGimbalScreening;
F = [25.5e9 26.25e9 27e9]; fTag = {'25p5', '26p25', '27'}; c0 = 299792458;
kaM = rfscreen.kaa.ReflectorApertureModel.fromRepository(repo);                   % 400 x 720 aperture samples
kaQ = kaM.withSampling(struct('nRho', 160, 'nPhi', 360));                         % coarse gimbal sweep only
logm(logf, 'KAA source: %s, D=%.0f mm, Fe=%.2f mm, Ds=%.0f mm, status %s, files %s', kaM.label, kaM.D_m * 1e3, ...
    kaM.Fe_m * 1e3, kaM.Ds_m * 1e3, kaM.provenance.status, strjoin(kaM.provenance.files, ' | '));
logm(logf, 'R_ff = 2D^2/lambda: %.2f / %.2f / %.2f m', kaM.farFieldDistance(F));

% ---- geometry / RF baseline ----
model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
dsDir = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
RD = rfscreen.spacecraft.SpacecraftDataReader;
T = RD.readTable(fullfile(dsDir, 'rf_systems.csv'));
pos = containers.Map(); nrm = containers.Map();
for i = 1:numel(model.installationRecords)
    rc = model.installationRecords(i); pn = model.panels(strcmp({model.panels.id}, rc.panelId));
    pos(rc.antennaId) = rc.position_m(:); nrm(rc.antennaId) = pn.normal_B(:);
end
sysRow = @(id) find(strcmp(T.system_id, id));
P_ka = str2double(T.tx_power_dbm{sysRow('KA_DLS_TX@KAA_1')});
kaas = {'KAA_1', 'KAA_2'};
victims = { ...   % system id, mount, family
    'S_TC_RX@SBA_NADIR', 'SBA_NADIR', 'S'; 'S_TC_RX@SBA_ZENITH', 'SBA_ZENITH', 'S'; ...
    'GPS_L1_RX@GPSA_1', 'GPSA_1', 'L'; 'GPS_L2_RX@GPSA_1', 'GPSA_1', 'L'; 'GPS_L5_RX@GPSA_1', 'GPSA_1', 'L'; ...
    'GPS_L1_RX@GPSA_2', 'GPSA_2', 'L'; 'GPS_L2_RX@GPSA_2', 'GPSA_2', 'L'; 'GPS_L5_RX@GPSA_2', 'GPSA_2', 'L'; ...
    'SAR_X_RX', 'SAR_ANT', 'SAR'; 'ISL_X_RX', 'ISL', 'ISL'};
mountsV = unique(victims(:, 2), 'stable');
resp = struct();
for fam = {'S', 'L', 'ISL', 'SAR'}; resp.(fam{1}) = rfscreen.kaa.KaVictimResponse.fromRepository(repo, fam{1}); end
famOfMount = containers.Map(victims(:, 2), victims(:, 3));

% frozen far-field export (validated main beam + legacy envelope) for the Friis reference only
frz = cell(1, 3);
for k = 1:3
    b = fullfile(repo, 'data', 'Kaband_KAA_CST', sprintf('KA_DLS_physical_f%s_', fTag{k}));
    frz{k} = struct('xz', rfscreen.kaa.KaVictimResponse.readCut([b 'XZ.csv']), 'yz', rfscreen.kaa.KaVictimResponse.readCut([b 'YZ.csv']));
end

% =========================== 1. near-field vs far-field validation ===========================
valRows = {};
pyFine = cell(1, 3); pyFull = cell(1, 3);
for k = 1:3
    pyFine{k} = dlmread(fullfile(repo, 'cst', 'results', 'KA_REFLECTOR_KA_FEED_C_OEWG', sprintf('fine_0p05deg_f%g.csv', F(k) / 1e9)), ',', 1, 0);
    pyFull{k} = dlmread(fullfile(repo, 'cst', 'results', 'KA_REFLECTOR_KA_FEED_C_OEWG', sprintf('full_1deg_f%g.csv', F(k) / 1e9)), ',', 1, 0);
end
angs = [0 0.5 1 1.5 2 3 3.75 5.1 6 10 20 30 60 90 120 150];
facs = [0.2 1 10 100];
for k = 1:3
    f = F(k); Rff = kaM.farFieldDistance(f);
    th = angs; if k ~= 2; th = [0 0.5 1 2 5.1 10 30 90]; end
    for phi0 = [0 90]
        Gff = S.farFieldGain(kaM, f, th, phi0 * ones(size(th)));
        for fac = facs
            R = fac * Rff;
            r = R * [sind(th) * cosd(phi0); sind(th) * sind(phi0); cosd(th)];
            e = S.evaluate(kaM, f, P_ka, r);
            for i = 1:numel(th)
                if th(i) <= 10; py = interp1(pyFine{k}(:, 1), pyFine{k}(:, 2), th(i)); pysrc = 'fine_0p05deg';
                else; py = interp1(pyFull{k}(:, 1), pyFull{k}(:, 2), th(i)); pysrc = 'full_1deg'; end
                reg = 'MAIN_LOBE'; if th(i) > 1.6; reg = 'SIDELOBE_FAR_ANGLE'; end
                if any(abs(th(i) - [3.75]) < 1e-9); reg = 'NEAR_NULL'; end
                st = 'INFO_NEAR_FIELD';
                if fac >= 10
                    tol = 0.05; if fac >= 100; tol = 0.005; end
                    if strcmp(reg, 'NEAR_NULL'); tol = Inf; end
                    st = 'PASS'; if abs(e.Geq_dBi(i) - Gff(i)) > tol; st = 'FAIL'; end
                    if isinf(tol); st = 'INFO_NULL'; end
                end
                valRows{end+1} = {f / 1e9, th(i), phi0, fac, R, e.Geq_dBi(i), Gff(i), e.Geq_dBi(i) - Gff(i), py, Gff(i) - py, ...
                    pysrc, reg, e.E_dBuVpm(i), e.S_dBmpm2(i), st}; %#ok<AGROW>
            end
        end
    end
end
vr = cell2mat(cellfun(@(r) [r{4} r{8} r{10} strcmp(r{12}, 'MAIN_LOBE') strcmp(r{15}, 'FAIL')], valRows, 'UniformOutput', false)');
logm(logf, 'Validation: %d rows; MATLAB FF vs Python CSV max |diff| = %.4f dB (main lobe %.4f dB)', numel(valRows), ...
    max(abs(vr(:, 3))), max(abs(vr(vr(:, 4) == 1, 3))));
for fac = facs
    sel = vr(:, 1) == fac;
    logm(logf, '  R = %5.1f R_ff : max |NF-FF| all %.4f dB, main lobe %.4f dB', fac, max(abs(vr(sel, 2))), max(abs(vr(sel & vr(:, 4) == 1, 2))));
end
logm(logf, '  convergence FAIL rows: %d', sum(vr(:, 5)));
% boresight distance sweep (26.25 GHz)
Rs = logspace(log10(0.3), log10(1000), 40);
e = S.evaluate(kaM, 26.25e9, P_ka, [zeros(2, numel(Rs)); Rs]);
for i = 1:numel(Rs)
    valRows{end+1} = {26.25, 0, 0, Rs(i) / kaM.farFieldDistance(26.25e9), Rs(i), e.Geq_dBi(i), S.farFieldGain(kaM, 26.25e9, 0, 0), ...
        e.Geq_dBi(i) - S.farFieldGain(kaM, 26.25e9, 0, 0), interp1(pyFine{2}(:, 1), pyFine{2}(:, 2), 0), 0, 'fine_0p05deg', ...
        'BORESIGHT_DISTANCE_SWEEP', e.E_dBuVpm(i), e.S_dBmpm2(i), 'INFO'}; %#ok<AGROW>
end
writeTable(fullfile(outDir, 'ka_nearfield_validation.csv'), {'frequency_ghz', 'theta_ap_deg', 'phi_ap_deg', 'distance_over_Rff', ...
    'distance_m', 'Geq_nearfield_dbi', 'G_farfield_aperture_dbi', 'nf_minus_ff_db', 'G_python_reflector_csv_dbi', ...
    'ff_minus_python_db', 'python_csv', 'region', 'E_dbuvpm_at_48p45dbm', 'S_dbmpm2_at_48p45dbm', 'status'}, valRows);

% =========================== 2. input availability ===========================
av = {};
for fam = {'S', 'L', 'ISL', 'SAR'}
    r = resp.(fam{1});
    av{end+1} = {'VICTIM_KA_OOB_RESPONSE', fam{1}, '25.5;26.25;27', r.status, r.cstCase, r.reason, r.evidence}; %#ok<AGROW>
end
rxIds = {'S_TC_RX@SBA_NADIR', 'GPS_L1_RX@GPSA_1', 'GPS_L2_RX@GPSA_1', 'GPS_L5_RX@GPSA_1', 'SAR_X_RX', 'ISL_X_RX'};
for i = 1:numel(rxIds)
    q = sysRow(rxIds{i});
    p1 = str2double(T.p1db_in_dbm{q}); ip = str2double(T.iip3_in_dbm{q});
    for it = {{'RX_BPF_PRESELECTOR_REJECTION_AT_KA', NaN}, {'LNA_MIXER_BLOCKING_LEVEL_AT_KA', NaN}, ...
            {'RX_P1DB_INPUT', p1}, {'RX_IIP3_INPUT', ip}}
        v = it{1}{2}; st = 'INPUT_MISSING'; if isfinite(v); st = sprintf('AVAILABLE %.2f dBm', v); end
        av{end+1} = {it{1}{1}, rxIds{i}, '25.5-27', st, 'rf_systems.csv', ...
            'not in rf_systems.csv / no receiver datasheet in the inputs (NaN kept)', 'data/spacecraft/simplified_spacecraft_v1/rf_systems.csv'}; %#ok<AGROW>
    end
end
av{end+1} = {'KAA_TX_EMISSION_MASK_SPUR_HARMONIC', 'KA_DLS_TX', 'S/L/X RX bands', 'INPUT_MISSING', '', ...
    'needed for KA_SPUR_INBAND; KAA response at spur frequencies also absent', 'rf_systems.csv (no mask column)'};
av{end+1} = {'KAA_REFLECTOR_SOURCE', 'KAA_1/KAA_2', '25.5;26.25;27', 'AVAILABLE_VALIDATED', 'KA_FEED_C_OEWG + equivalent paraboloid', ...
    'datasheet main-beam anchors PASS (worst 0.54 of limit); far side lobes not anchored', strjoin(kaM.provenance.files, '; ')};
av{end+1} = {'KAA_GIMBAL_DOMAIN', 'KAA_1/KAA_2', '-', 'ASSUMPTION', 'steering_constraints.csv', ...
    'HEMISPHERE (90 deg) simplified; hard stops / keep-outs / mechanical shadowing NOT defined', 'data/spacecraft/simplified_spacecraft_v1/steering_constraints.csv'};
av{end+1} = {'KAA_APERTURE_CENTRE_VS_PIVOT', 'KAA_1/KAA_2', '-', 'ASSUMPTION', '', ...
    'aperture centre taken at the installation reference point for every pointing (pivot offset undefined)', 'antenna_installations.csv'};
av{end+1} = {'STRUCTURE_SCATTERING_SHADOWING', 'all Ka pairs', '25.5-27', 'NOT_MODELED', '', ...
    'direct reflector field only; hull reflection/diffraction may raise or lower the coupling', '-'};
av{end+1} = {'KAA_FEED_SPILLOVER_SUBREFLECTOR_STRUTS', 'KAA_1/KAA_2', '25.5-27', 'NOT_MODELED', '', ...
    'aperture integration carries the reflected (aperture) field only, as in the validated far-field model', 'cst/ka_reflector_po.py'};
writeTable(fullfile(outDir, 'ka_input_availability.csv'), {'item', 'subject', 'frequency_ghz', 'status', 'source', 'reason', 'evidence'}, av);

% =========================== 3. per KAA x victim mount: nominal + gimbal screening ===========================
G = struct();
gimRows = {}; asmRows = {};
for ka = kaas
    pK = pos(ka{1}); dom = model.steering(ka{1}); Rnom = A.gimbalPointing(dom, dom.referenceAxis_B);
    for mv = mountsV(:).'
        pV = pos(mv{1}); Rv = A.fixedMount(nrm(mv{1})); r = resp.(famOfMount(mv{1}));
        los = rfscreen.geometry.LineOfSight.segment(ka{1}, mv{1}, pK, pV, model.structures);
        dV = A.bodyToLocal(Rv, (pK - pV) / norm(pK - pV));
        w = 10 * log10((c0 ./ F) .^ 2 / (4 * pi));
        if r.isAvailable(); w = w + arrayfun(@(f) r.gainAt(f, dV), F); end
        tg = tic;
        sc = GS.screen(kaQ, F, P_ka, pK, dom, pV, w, kaM);
        res = cell(1, 3);
        for s = 1:3; res{s} = rfi_ka_point(kaM, F, P_ka, pK, sc(s).R_BL, pV, Rv, r); end
        nominal = res{1};
        aoa = S.arrivalDirection(kaM, 26.25e9, nominal.r_L);
        aoaDev = acosd(max(-1, min(1, dot(aoa, nominal.r_L / norm(nominal.r_L)))));
        % far-field Friis references at the nominal pointing (same geometry)
        gModel = arrayfun(@(k) S.farFieldGain(kaM, F(k), nominal.theta_ap, nominal.phi_ap), 1:3);
        gFrz = arrayfun(@(k) rfscreen.kaa.KaVictimResponse.cutGain(frz{k}.xz, frz{k}.yz, nominal.r_L), 1:3);
        fspl = 20 * log10(4 * pi * nominal.d * F / c0);
        key = [ka{1} '>' mv{1}];
        G.(strrep(strrep(key, '>', '__'), '@', '_')) = struct('sc', sc, 'res', {res}, 'los', los, 'aoaDev', aoaDev, ...
            'gModel', gModel, 'gFrz', gFrz, 'fspl', fspl, 'dV', dV);
        for s = 1:3
            q = res{s};
            if r.isAvailable(); metric = q.P_port_band_dBm; mname = 'P_port_band_dBm'; else; metric = q.S_band_dBmpm2; mname = 'S_band_dBmpm2'; end
            gimRows{end+1} = {['KA_NF_' key], ka{1}, mv{1}, famOfMount(mv{1}), sc(s).state, vec(sc(s).u_B), sc(s).offAxisFromRef_deg, ...
                dom.steeringModel, dom.maxOffAxis_deg, double(sc(s).allowed), 'SIMPLIFIED_ASSUMPTION (no hard-stop/shadowing data)', ...
                sc(1).sweep.alpha_deg, sprintf('%.2f-%.2f', sc(1).sweep.reachable_deg), q.theta_ap, q.phi_ap, q.d, ...
                q.E_dBuVpm(1), q.E_dBuVpm(2), q.E_dBuVpm(3), q.S_dBmpm2(1), q.S_dBmpm2(2), q.S_dBmpm2(3), q.S_band_dBmpm2, ...
                q.Geq_dBi(2), q.P_port_dBm(1), q.P_port_dBm(2), q.P_port_dBm(3), q.P_port_band_dBm, mname, metric, ...
                metric - ifelse(r.isAvailable(), res{1}.P_port_band_dBm, res{1}.S_band_dBmpm2), r.status, los.status, ...
                K.NEAR_FIELD, [S.FIELD_SCOPE ';' S.STRUCTURE_FLAG]}; %#ok<AGROW>
            if ~r.isAvailable()
                asmRows{end+1} = {['KA_NF_' key], ka{1}, mv{1}, sc(s).state, 'ASSUMPTION_ONLY_ISOTROPIC_0DBI_REFERENCE', ...
                    q.Pref0_dBm(1), q.Pref0_dBm(2), q.Pref0_dBm(3), 10 * log10(mean(10 .^ (q.Pref0_dBm / 10))), ...
                    'NOT A RESULT: victim Ka response missing; S*lambda^2/(4 pi) shown only to size the missing input'}; %#ok<AGROW>
            end
        end
        logm(logf, '%-18s d=%.3f m LOS %-8s nominal th=%6.2f S=%7.2f dBm/m2 | worst th=%6.2f (u off-ref %.1f) S=%7.2f | P_port nom/worst %s / %s dBm  [%.0f s]', ...
            key, nominal.d, los.status, nominal.theta_ap, nominal.S_band_dBmpm2, res{3}.theta_ap, sc(3).offAxisFromRef_deg, ...
            res{3}.S_band_dBmpm2, csvnum(nominal.P_port_band_dBm), csvnum(res{3}.P_port_band_dBm), toc(tg));
    end
end

% =========================== 4. pair rows (nominal pointing; fundamental + spur paths) ===========================
pairRows = {};
for ka = kaas
    pK = pos(ka{1}); dom = model.steering(ka{1});
    for v = 1:size(victims, 1)
        sid = victims{v, 1}; mv = victims{v, 2}; fam = victims{v, 3}; r = resp.(fam);
        key = [ka{1} '>' mv]; g = G.(strrep(key, '>', '__')); q = g.res{1};
        avail = r.isAvailable();
        if avail
            status = 'EVALUATED_PORT_COUPLING'; rxst = K.receiverImpact(struct('p1db_in_dBm', NaN, 'iip3_in_dBm', NaN, 'kaRejection_dB', NaN), true);
            vsrc = sprintf('CST %s RealizedGain (Ka OOB, free space, two cuts)', r.cstCase);
            pffF = P_ka + g.gFrz + q.Grx_dBi - g.fspl; pffM = P_ka + g.gModel + q.Grx_dBi - g.fspl;
            pff = 10 * log10(mean(10 .^ (pffF / 10))); pfm = 10 * log10(mean(10 .^ (pffM / 10)));
        else
            status = 'INPUT_MISSING'; rxst = K.receiverImpact(struct(), false);
            vsrc = 'NONE (not substituted: no isotropic / no assumed rejection)'; pff = NaN; pfm = NaN;
        end
        rxBand = [str2double(T.fc_mhz{sysRow(sid)}) str2double(T.bw_mhz{sysRow(sid)})];
        common = {['KA_NF_' ka{1} '>' sid], ka{1}, ['KA_DLS_TX@' ka{1}], sid, mv, fam, vec(pK), vec(pos(mv)), q.d, ...
            kaM.farFieldDistance(27e9), g.los.status, strjoin(g.los.blockingStructureIds, ';'), GS.NOMINAL, vec(dom.referenceAxis_B), ...
            q.theta_ap, q.phi_ap, q.theta_v, q.phi_v};
        pairRows{end+1} = [common, {K.FUNDAMENTAL, '25.5;26.25;27', K.NEAR_FIELD, vsrc, r.status, ...
            q.E_dBuVpm(1), q.E_dBuVpm(2), q.E_dBuVpm(3), q.S_dBmpm2(1), q.S_dBmpm2(2), q.S_dBmpm2(3), ...
            q.Geq_dBi(2), g.gModel(2), g.gFrz(2), q.Grx_dBi(1), q.Grx_dBi(2), q.Grx_dBi(3), ...
            q.P_port_dBm(1), q.P_port_dBm(2), q.P_port_dBm(3), q.P_port_band_dBm, pfm, pff, g.aoaDev, ...
            status, rxst, S.FIELD_SCOPE, S.STRUCTURE_FLAG, ...
            ifelse(avail, '', r.reason), [strjoin(kaM.provenance.files, '; ') '; ' r.evidence]}]; %#ok<AGROW>
        sp = K.spurPath(sid, (rxBand(1) + [-0.5 0.5] * rxBand(2)) * 1e6, []);
        pairRows{end+1} = [common, {K.SPUR, sprintf('%.2f-%.2f MHz (victim RX band)', rxBand(1) - rxBand(2) / 2, rxBand(1) + rxBand(2) / 2), ...
            'NOT_COMPUTED', sp.victimGainBasis, 'NOT_REQUESTED', NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
            NaN, NaN, NaN, NaN, NaN, NaN, NaN, sp.status, K.RX_NOT_REACHED, S.FIELD_SCOPE, S.STRUCTURE_FLAG, sp.reason, ...
            'rf_systems.csv (no emission mask)'}]; %#ok<AGROW>
    end
end
pairHdr = {'case_id', 'kaa_id', 'tx_system', 'victim_system', 'victim_mount', 'victim_family', 'kaa_position_m', ...
    'victim_position_m', 'distance_m', 'R_ff_27GHz_m', 'los', 'blocking_panels', 'gimbal_state', 'kaa_boresight_B', ...
    'aperture_theta_deg', 'aperture_phi_deg', 'victim_local_theta_deg', 'victim_local_phi_deg', 'path', 'frequency_ghz', ...
    'source_model', 'victim_response_source', 'victim_response_status', ...
    'E_25p5_dbuvpm', 'E_26p25_dbuvpm', 'E_27_dbuvpm', 'S_25p5_dbmpm2', 'S_26p25_dbmpm2', 'S_27_dbmpm2', ...
    'Geq_nearfield_26p25_dbi', 'G_farfield_aperture_26p25_dbi', 'G_frozen_export_26p25_dbi', ...
    'victim_gain_25p5_dbi', 'victim_gain_26p25_dbi', 'victim_gain_27_dbi', ...
    'P_port_25p5_dBm', 'P_port_26p25_dBm', 'P_port_27_dBm', 'P_port_band_dBm', ...
    'P_port_farfield_aperture_friis_dBm', 'P_port_frozen_export_friis_dBm', 'aoa_deviation_deg', ...
    'status', 'receiver_status', 'field_scope', 'structure_scattering', 'missing_reason', 'evidence'};
writeTable(fullfile(outDir, 'ka_nearfield_pair_results.csv'), pairHdr, pairRows);
writeTable(fullfile(outDir, 'ka_gimbal_worstcase.csv'), {'case_id', 'kaa_id', 'victim_mount', 'victim_family', 'gimbal_state', ...
    'boresight_B', 'off_axis_from_reference_deg', 'domain_model', 'domain_limit_deg', 'allowed_in_domain', 'domain_provenance', ...
    'victim_angle_from_reference_deg', 'reachable_theta_ap_deg', 'aperture_theta_deg', 'aperture_phi_deg', 'distance_m', ...
    'E_25p5_dbuvpm', 'E_26p25_dbuvpm', 'E_27_dbuvpm', 'S_25p5_dbmpm2', 'S_26p25_dbmpm2', 'S_27_dbmpm2', 'S_band_dbmpm2', ...
    'Geq_26p25_dbi', 'P_port_25p5_dBm', 'P_port_26p25_dBm', 'P_port_27_dBm', 'P_port_band_dBm', 'screening_metric', ...
    'screening_metric_value', 'delta_vs_nominal_db', 'victim_response_status', 'los', 'source_model', 'scope'}, gimRows);
writeTable(fullfile(outDir, 'ka_assumption_only_sensitivity.csv'), {'case_id', 'kaa_id', 'victim_mount', 'gimbal_state', ...
    'assumption', 'P_ref0dBi_25p5_dBm', 'P_ref0dBi_26p25_dBm', 'P_ref0dBi_27_dBm', 'P_ref0dBi_band_dBm', 'note'}, asmRows);

nEval = containers.Map(kaas, {0, 0}); nMiss = containers.Map(kaas, {0, 0});
for i = 1:numel(pairRows)
    rr = pairRows{i}; if ~strcmp(rr{19}, K.FUNDAMENTAL); continue; end
    if strcmp(rr{end-5}, 'EVALUATED_PORT_COUPLING'); nEval(rr{2}) = nEval(rr{2}) + 1; else; nMiss(rr{2}) = nMiss(rr{2}) + 1; end
end
for ka = kaas
    logm(logf, '%s fundamental pairs: evaluated %d, INPUT_MISSING %d (spur pairs: all INPUT_MISSING)', ka{1}, nEval(ka{1}), nMiss(ka{1}));
end
logm(logf, 'Rows: pairs %d, gimbal %d, validation %d, availability %d, assumption-only %d; run %.0f s', numel(pairRows), ...
    numel(gimRows), numel(valRows), numel(av), numel(asmRows), toc(t0));
fclose(logf);
