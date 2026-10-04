function test_rfc_levels(h)
%TEST_RFC_LEVELS Free-space assumption, preferred coupling and the per-pair level table (VR-456..460).
    h.setGroup('rfc_levels');
    FF = @rfscreen.coupling.FarFieldCouplingModel;
    ctx = rfscreen.coupling.CouplingModel.newContext();
    ctx.distance_m = 2; ctx.frequency_Hz = 26.25e9; ctx.txMaxDim_m = 0.22; ctx.rxMaxDim_m = 0.2;
    lam = rfscreen.util.Units.wavelength_m(26.25e9);
    expF = 20 * log10(4 * pi * 2 / lam);

    % ---- guarded default is unchanged; the free-space assumption is explicit ----
    r = FF().computeCoupling(ctx);
    h.eqStr('default model: near-field -> FAR_FIELD_INVALID_OR_UNKNOWN', r.validity, 'FAR_FIELD_INVALID_OR_UNKNOWN');
    h.isNaNval('default model: no FSPL applied', r.metric_dB);
    r = FF(5, struct('assumeFreeSpace', true)).computeCoupling(ctx);
    h.eqStr('assumed: validity FREE_SPACE_ASSUMED (never FAR_FIELD_VALID)', r.validity, 'FREE_SPACE_ASSUMED');
    h.eqTol('assumed: FSPL analytic', r.metric_dB, expF, 1e-9);
    h.isTrue('assumed: physical flag set so absolute transfer is produced', r.isPhysicalCoupling);
    h.isTrue('assumed: explicit warning', any(~cellfun(@isempty, strfind(r.warnings, 'NOT verified'))));
    ctx2 = ctx; ctx2.txMaxDim_m = NaN;
    r = FF(5, struct('assumeFreeSpace', true)).computeCoupling(ctx2);
    h.eqStr('unknown dimensions also flagged', r.validity, 'FREE_SPACE_ASSUMED');
    ctx3 = ctx; ctx3.distance_m = 50;
    r = FF(5, struct('assumeFreeSpace', true)).computeCoupling(ctx3);
    h.eqStr('true far field stays FAR_FIELD_VALID with the option on', r.validity, 'FAR_FIELD_VALID');
    ctx4 = ctx; ctx4.distance_m = NaN;
    h.eqStr('no distance: still unavailable (nothing invented)', FF(5, struct('assumeFreeSpace', true)).computeCoupling(ctx4).validity, 'FAR_FIELD_INVALID_OR_UNKNOWN');

    % ---- preferred model: installed S21 where available, explicit fallback otherwise ----
    tab = rfscreen.coupling.CstS21Table('A', 'B', [1e9 30e9], [-60 -60], struct('provenance', 'SYNTHETIC_TEST'));
    P = rfscreen.coupling.PreferredCouplingModel(rfscreen.coupling.CstCouplingModel({tab}), FF(5, struct('assumeFreeSpace', true)));
    c = ctx; c.txAntennaId = 'A'; c.rxAntennaId = 'B';
    r = P.computeCoupling(c);
    h.eqStr('S21 available -> CST', r.modelType, 'CST');
    h.eqTol('...with the tabulated value', r.metric_dB, -60, 0);
    c.rxAntennaId = 'Z';
    r = P.computeCoupling(c);
    h.eqStr('no table -> fallback keeps its own type', r.modelType, 'FAR_FIELD');
    h.eqStr('...and its own validity', r.validity, 'FREE_SPACE_ASSUMED');
    h.isTrue('fallback is announced', any(~cellfun(@isempty, strfind(r.warnings, 'fallback'))));
    h.throws('bad models rejected', @() rfscreen.coupling.PreferredCouplingModel(1, 2), 'rfscreen:coupling:badModel');

    % ---- level table for a real case ----
    MB = rfscreen.mission.MissionCaseBuilder; RL = rfscreen.mission.RfcLevelReport;
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    cs = MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache, 'azStep_deg', 10, 'elStep_deg', 10));
    rows = RL.build(cs, RL.couplingModel());
    h.eqTol('22 pairs (5 TX x 5 RX minus same-mount pairs)', numel(rows), 22, 0);
    ids = strcat({rows.interfererId}, '>', {rows.victimId});
    h.isFalse('no TM -> TC on the same SBA mount', any(strcmp(ids, 'S_TM_TX@SBA_NADIR>S_TC_RX@SBA_NADIR')));
    h.isFalse('no ISL TX -> ISL RX self path', any(strcmp(ids, 'ISL_X_TX>ISL_X_RX')));
    ok = true; okR = true; okF = true; okFlag = true; okRej = true;
    for k = 1:numel(rows)
        x = rows(k);
        ok = ok && abs(x.s21_dB - (x.txGain_dBi + x.rxGain_dBi - x.fspl_dB)) < 1e-9;
        okR = okR && abs(x.receivedLevel_dBm - (x.txPower_dBm + x.s21_dB)) < 1e-9;
        okF = okF && (x.farFieldVerified == strcmp(x.couplingValidity, 'FAR_FIELD_VALID'));
        if x.txFreq_Hz >= 3e9
            okFlag = okFlag && strcmp(x.installedEffect, 'FREE_SPACE_BY_DECISION') && strcmp(x.band, 'X_KA_FREE_SPACE');
        else
            okFlag = okFlag && strcmp(x.installedEffect, 'FREE_SPACE_INSTALLATION_EFFECT_UNKNOWN') && strcmp(x.band, 'L_S');
        end
        okRej = okRej && abs(x.requiredRejection_dB - (x.receivedLevel_dBm - x.allowable_dBm)) < 1e-6;
    end
    h.isTrue('S21 = Gtx + Grx - FSPL on every row', ok);
    h.isTrue('received level = P_tx + S21 on every row', okR);
    h.isTrue('far-field flag consistent with the validity', okF);
    h.isTrue('installed-effect flag by coupling frequency', okFlag);
    h.isTrue('required rejection = received level - allowable level', okRej);
    kaRows = rows(strncmp({rows.interfererId}, 'KA_DLS', 6));
    h.isTrue('every Ka row is FREE_SPACE_ASSUMED (far field never verified at 26 GHz)', ...
        all(strcmp({kaRows.couplingValidity}, 'FREE_SPACE_ASSUMED')) && ~any([kaRows.farFieldVerified]));
    h.isTrue('S-band TM rows have a verified far field (small apertures)', ...
        all([rows(strncmp({rows.interfererId}, 'S_TM', 4)).farFieldVerified]));
    h.isTrue('no in-band victim in this baseline (all out-of-band)', all(strcmp({rows.frequencyRelation}, 'OUT_OF_BAND')));
    h.isTrue('in-band interference is -Inf for out-of-band pairs', all(isinf([rows.inBandInterference_dBm])));
    pz = rows(strcmp(ids, 'S_TM_TX@SBA_ZENITH>GPS_L1_RX@GPSA_1'));
    h.isTrue('strongest L1 exposure: zenith TM -> GPSA_1 above -30 dBm at the antenna port', pz.receivedLevel_dBm > -30);
    h.eqTol('allowable level at the GPS receiver ~ -104.87 dBm', pz.allowable_dBm, -104.87, 0.05);
    h.isTrue('LOS evidence is carried (not a loss)', any(strcmp({rows.los}, 'BLOCKED')) && any(strcmp({rows.los}, 'CLEAR')));

    % ---- installed-pattern hook (table is empty in the repository) ----
    h.isTrue('no function uses an installed pattern today', all(strcmp({cs.functions.patternSource}, 'FREE_SPACE')));
    srcDs = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
    tmpDs = tempname(); mkdir(tmpDs);
    items = dir(srcDs);
    for q = 1:numel(items)
        if ~items(q).isdir; copyfile(fullfile(srcDs, items(q).name), fullfile(tmpDs, items(q).name)); end
    end
    tmpCuts = tempname(); mkdir(tmpCuts);
    th = (0:359).'; g = 5 * cosd(th / 2).^2 - 3;                     % synthetic installed cut
    for pl = {'XZ', 'YZ'}
        fid = fopen(fullfile(tmpCuts, ['inst_' pl{1} '.csv']), 'w'); fprintf(fid, 'theta,gain\n');
        fprintf(fid, '%d,%.6f\n', [th, g].'); fclose(fid);
    end
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    rel = @(f) strrep(strrep(fullfile(tmpCuts, f), [repoRoot filesep], ''), filesep, '/');
    % tmpCuts is outside the repo, so use an absolute path through a relative '..' chain is not portable:
    % store the absolute path in the table (fullfile with an absolute second part is used as is below).
    fid = fopen(fullfile(tmpDs, 'installed_patterns.csv'), 'a');
    fprintf(fid, 'SBA_NADIR_TM,SYNTH,%s,%s,2250,CST,SYNTHETIC_TEST,ACCEPTED,synthetic\n', ...
        strrep(fullfile(tmpCuts, 'inst_XZ.csv'), filesep, '/'), strrep(fullfile(tmpCuts, 'inst_YZ.csv'), filesep, '/'));
    fprintf(fid, 'SBA_ZENITH_TM,SYNTH,x.csv,y.csv,2250,CST,SYNTHETIC_TEST,PENDING,ignored row\n');
    fclose(fid);
    ir = MB.readInstalled(fullfile(tmpDs, 'installed_patterns.csv'), tmpDs);
    h.eqTol('only ACCEPTED rows are loaded', numel(ir), 1, 0);
    h.eqStr('row function', ir.functionId, 'SBA_NADIR_TM');
    h.eqTol('row frequency', ir.frequency_Hz, 2.25e9, 0);
    h.eqStr('absolute XZ path used as given', strrep(ir.xzPath, '\', '/'), strrep(fullfile(tmpCuts, 'inst_XZ.csv'), '\', '/'));
    B = MB.readBindings(fullfile(tmpDs, 'pattern_bindings.csv'));
    ip = MB.assembleInstalled(ir, B('SBA1_TM'), struct('azStep_deg', 10, 'elStep_deg', 10));
    h.isTrue('InstalledPattern class (never a FreeSpacePattern)', isa(ip, 'rfscreen.antenna.InstalledPattern') && ip.isInstalled());
    h.eqStr('2D cuts stay APPROX_FROM_CUTS', ip.provenance, 'APPROX_FROM_CUTS');
    h.eqStr('installed source recorded', ip.installedSource, 'CST');
    h.eqTol('boresight of the synthetic cut', ip.evaluate(2.25e9, 0, 0), 2, 1e-9);
    free = cache('SBA1_TM');
    h.isTrue('differs from the frozen free-space pattern', abs(ip.evaluate(2.25e9, 0, 0) - free.evaluate(2.25e9, 0, 0)) > 0.01);
    h.isFalse('free-space pattern object untouched (still FreeSpace)', free.isInstalled());
    % end to end through buildCase + the level report
    cI = MB.buildCase('CASE_SBA1_L1', struct('patternCache', cache, 'datasetDir', tmpDs, 'azStep_deg', 10, 'elStep_deg', 10));
    kk = find(strcmp({cI.functions.functionId}, 'SBA_NADIR_TM'));
    h.eqStr('function switched to the installed pattern', cI.functions(kk).patternSource, 'INSTALLED');
    h.eqStr('provenance tag carried', cI.functions(kk).installedTag, 'SYNTHETIC_TEST');
    aI = cI.scenario.antennas('SBA_NADIR_TM');
    h.eqStr('antenna bound to the installed pattern id', aI.patternId, 'INSTALLED_SBA_NADIR_TM');
    h.isTrue('registered pattern is an InstalledPattern', cI.scenario.patterns(aI.patternId).isInstalled());
    h.isTrue('the other S-band function stays free-space', strcmp(cI.functions(strcmp({cI.functions.functionId}, 'SBA_ZENITH_TM')).patternSource, 'FREE_SPACE'));
    h.isTrue('warning names the installed pattern', any(~cellfun(@isempty, strfind(cI.warnings, 'INSTALLED pattern'))));
    rI = RL.build(cI, RL.couplingModel());
    iid = strcat({rI.interfererId}, '>', {rI.victimId});
    h.eqStr('pair with the installed antenna flagged INSTALLED_PATTERN', rI(strcmp(iid, 'S_TM_TX@SBA_NADIR>GPS_L1_RX@GPSA_1')).installedEffect, 'INSTALLED_PATTERN');
    h.eqStr('pair without it stays unknown', rI(strcmp(iid, 'S_TM_TX@SBA_ZENITH>GPS_L1_RX@GPSA_1')).installedEffect, 'FREE_SPACE_INSTALLATION_EFFECT_UNKNOWN');
    gI = rI(strcmp(iid, 'S_TM_TX@SBA_NADIR>GPS_L1_RX@GPSA_1')).txGain_dBi;
    g0 = rows(strcmp(ids, 'S_TM_TX@SBA_NADIR>GPS_L1_RX@GPSA_1')).txGain_dBi;
    h.isTrue('installed gain differs from the free-space gain toward the victim', abs(gI - g0) > 0.01);
    delete(fullfile(tmpCuts, '*')); rmdir(tmpCuts); delete(fullfile(tmpDs, '*')); rmdir(tmpDs);

    % ---- terminology is configuration, provisional until confirmed ----
    T = RL.readTerms();
    h.eqStr('interferer term', T.interferer.ko, '간섭원');
    h.eqStr('victim term', T.victim.ko, '피간섭원');
    h.eqStr('interferer term confirmed by the owner', T.interferer.status, 'OWNER_CONFIRMED');
    h.eqStr('victim term confirmed by the owner', T.victim.status, 'OWNER_CONFIRMED');
    h.eqStr('other terms stay provisional', T.received_level.status, 'PROVISIONAL_STANDARD_EMC');
    h.eqStr('the attested KARI phrase is recorded as such', T.inter_antenna_rf_interference.status, 'KARI_PAPER_ATTESTED');

    % ---- export ----
    tmp = tempname(); mkdir(tmp);
    RL.writeCsv(rows, fullfile(tmp, 'l.csv'));
    txt = fileread(fullfile(tmp, 'l.csv'));
    h.isTrue('header comment carries the terms', ~isempty(strfind(txt, '간섭원')));
    X = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(tmp, 'l.csv'));
    h.eqTol('CSV rows', X.nRows, 22, 0);
    h.isTrue('CSV has the required-rejection column', isfield(X, 'required_rejection_db'));
    delete(fullfile(tmp, '*')); rmdir(tmp);

    % ---- boundary ----
    mDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'src', '+rfscreen', '+mission');
    t = fileread(fullfile(mDir, 'RfcLevelReport.m'));
    h.isTrue('report invents no gain/loss constants', isempty(strfind(t, 'attenuation_dB')) && isempty(strfind(t, 'blockageLoss')));
end
