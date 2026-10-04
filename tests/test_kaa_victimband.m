function test_kaa_victimband(h)
%TEST_KAA_VICTIMBAND Tier-3 KAA victim-band ceiling, ITU source row, and PSD chain (no filter, no 0 dBi substitution).
    h.setGroup('kaa_victimband');
    repo = fileparts(fileparts(mfilename('fullpath')));
    K = rfscreen.kaa.KaaVictimBandBound; P = rfscreen.psd.PsdMath; V = rfscreen.psd.VictimBandPsdPath;
    D = K.reflectorDiameter_m(repo);
    h.eqTol('KAA equivalent-paraboloid D from the validation record [m]', D, 0.22, 1e-12);

    % ---- ceiling formulas ----
    f = 10.6e9; lam = K.C0 / f; A = pi * D ^ 2 / 4;
    h.eqTol('aperture bound = 10log10(4 pi A / lambda^2)', K.apertureBound_dBi(f, D), 10 * log10(4 * pi * A / lam ^ 2), 1e-9);
    h.eqTol('aperture bound at 10.6 GHz [dBi]', K.apertureBound_dBi(f, D), 27.76, 0.01);
    ka = 2 * pi * f * (D / 2) / K.C0;
    h.eqTol('sphere bound = 10log10((ka)^2 + 2ka)', K.sphereBound_dBi(f, D / 2), 10 * log10(ka ^ 2 + 2 * ka), 1e-9);
    fs = [1.176e9 1.575e9 2.1e9 9.65e9 10.6e9];
    h.isTrue('Tier-3 ceiling >= both bounds at every victim band', all(K.bound_dBi(fs, D) >= K.apertureBound_dBi(fs, D) - 1e-12) && ...
        all(K.bound_dBi(fs, D) >= K.sphereBound_dBi(fs, D / 2) - 1e-12));
    h.isTrue('ceiling rises with frequency', all(diff(K.bound_dBi(fs, D)) > 0));
    h.eqTol('L5 ceiling [dBi] (sphere bound governs, ka = 2.7)', K.bound_dBi(1.17645e9, D), 11.07, 0.02);
    h.eqTol('X-band: sphere vs aperture bound differ < 0.5 dB', K.sphereBound_dBi(f, D / 2) - K.apertureBound_dBi(f, D), 0.35, 0.1);
    h.isTrue('larger enclosing sphere raises the ceiling (sensitivity)', K.bound_dBi(1.176e9, D, K.SPHERE_RADIUS_FACTOR) > K.bound_dBi(1.176e9, D));
    h.isTrue('L/S ceilings are below the 20 dBi sensitivity, X ceilings above it', K.bound_dBi(2.11e9, D) < 20 && K.bound_dBi(9.65e9, D) > 20);
    h.eqTol('fixed sensitivities', K.FIXED_SENSITIVITY_DBI, [0 10 20], 0);
    h.eqStr('classification', K.CLASSIFICATION, 'GAIN_BOUND_ONLY');
    h.isTrue('tags state bound / not measured / not CST validated', all(cellfun(@(t) ~isempty(strfind(K.TAGS, t)), ...
        {'ENGINEERING_BOUND', 'NOT_MEASURED', 'NOT_CST_VALIDATED'})));
    h.eqTol('far-field ratio d / (2 D^2 / lambda), ISL 1.778 m', K.farFieldRatio(f, D, 1.778), 1.778 / (2 * D ^ 2 / lam), 1e-12);
    h.isTrue('near-field flag below 1 at X band for 1.778 m', K.farFieldRatio(f, D, 1.778) < 1);
    h.isTrue('applicability text names the regime', ~isempty(strfind(K.applicability(1.176e9, D), 'ELECTRICALLY_SMALL')) && ...
        ~isempty(strfind(K.applicability(10.6e9, D), 'LARGE_APERTURE')));

    % ---- ITU source (separate from the antenna term) ----
    masks = rfscreen.psd.EmissionMaskTable.read(fullfile(repo, 'data', 'rfi_psd', 'kaa_itu_spurious_source.csv'));
    h.eqTol('six victim bands in the KAA ITU source', numel(masks), 6, 0);
    h.isTrue('all ITU rows: KA_DLS_TX, conducted antenna port, -60 dBc, 4 kHz', all(cellfun(@(s) strcmp(s.txSystem, 'KA_DLS_TX') && ...
        strcmp(s.referencePlane, 'ANTENNA_PORT') && s.level == -60 && strcmp(s.unit, 'dBc') && s.refBw_Hz == 4000, masks)));
    P_dBm = 10 * log10(70e3);
    h.eqTol('ITU attenuation min(43+10log10(70 W); 60) = 60 dB', min(43 + 10 * log10(70), 60), 60, 0);
    h.eqTol('source PSD = P - 60 dB - 10log10(4 kHz) [dBm/Hz]', masks{1}.psdDbmHz(P_dBm), P_dBm - 60 - 10 * log10(4e3), 1e-9);
    h.isTrue('source rows carry no radiated-EIRP plane (antenna gain is a separate term)', ~any(cellfun(@(s) s.isRadiated(), masks)));

    % ---- chain: PSD_RX = PSD_TX + G_KAA - FSPL + G_RX, no filter ----
    F0 = rfscreen.psd.FilterScenario('T0', 'FLAT', [], 0, 'TEST');
    sp = masks(cellfun(@(s) strcmp(s.victimBand, 'ISL'), masks));
    fv = 10.6e9; d = 1.778; gk = 28.1; gr = -13.5; fspl = P.fspl(fv, d);
    R = V.evaluate(fv, gk + gr - fspl, NaN, -177, sp, P_dBm, F0, NaN, true);
    h.eqTol('victim-port PSD = source + G_KAA + G_RX - FSPL', R.port_psd_dBmHz, sp{1}.psdDbmHz(P_dBm) + gk + gr - fspl, 1e-9);
    h.eqTol('required additional suppression = PSD - allowable', R.required_add_supp_dB, R.port_psd_dBmHz + 177, 1e-9);
    h.eqTol('no filter / cutoff attenuation applied', R.filter_dB, 0, 0);
    Rm = V.evaluate(fv, NaN, NaN, -177, sp, P_dBm, F0, NaN, true);
    h.isNaNval('missing coupling is NaN, never a 0 dBi substitute', Rm.port_psd_dBmHz);
    h.eqStr('missing KAA response status kept', Rm.status{1}, V.ST_KAA);

    % ---- stored results (when generated) ----
    pf = fullfile(repo, 'output', 'claude', 'results', 'kaa_vb_pair_summary.csv');
    if exist(pf, 'file') == 2
        L = strsplit(strrep(fileread(pf), char(13), ''), char(10)); L = L(~cellfun(@isempty, strtrim(L)));
        hd = strsplit(L{1}, ','); Rw = cellfun(@(x) strsplit(x, ',', 'CollapseDelimiters', false), L(2:end), 'UniformOutput', false);
        col = @(n) cellfun(@(r) r{strcmp(hd, n)}, Rw, 'UniformOutput', false);
        sc = col('kaa_gain_scenario'); st = col('result_status'); tg = col('tags'); pr = col('victim_port_psd_max_dbm_hz');
        h.eqTol('20 pairs x 4 gain scenarios', numel(Rw), 80, 0);
        h.isTrue('every row tagged ENGINEERING_BOUND;NOT_MEASURED;NOT_CST_VALIDATED', all(strcmp(tg, K.TAGS)));
        sar = strcmp(col('victim_band'), 'SAR');
        h.isTrue('SAR victim: no port PSD (victim response missing, not 0 dBi)', all(strcmp(st(sar), 'VICTIM_RX_RESPONSE_MISSING_NO_PORT_PSD')) && all(strcmp(pr(sar), 'NaN')));
        h.isTrue('only SAR rows lack a port PSD', all(~strcmp(pr(~sar), 'NaN')));
        g = cellfun(@str2double, col('kaa_gain_dbi_max'));
        h.isTrue('sensitivity rows carry exactly 0/10/20 dBi', all(g(strcmp(sc, 'SENS_0DBI')) == 0) && all(g(strcmp(sc, 'SENS_10DBI')) == 10) && all(g(strcmp(sc, 'SENS_20DBI')) == 20));
    end
end
