function test_task2_scope(h)
%TEST_TASK2_SCOPE Task 2: waveguide below-cutoff bound, SAR owner envelope, harmonic check, scope, Ka cutoff route outputs.
    h.setGroup('task2_scope');
    repo = fileparts(fileparts(mfilename('fullpath')));
    W = rfscreen.psd.WaveguideCutoff; SD = rfscreen.spacecraft.SpacecraftDataReader;

    % ---- waveguide TE10 below cutoff ----
    a42 = 10.668e-3; a34 = 8.636e-3;
    h.eqTol('WR-42 TE10 cutoff [GHz]', W.cutoffTE10(a42) / 1e9, 14.051, 1e-3);
    h.eqTol('WR-34 TE10 cutoff [GHz]', W.cutoffTE10(a34) / 1e9, 17.357, 1e-3);
    f = 1.2276e9; fc = W.cutoffTE10(a42);
    h.eqTol('alpha = 8.686 (2 pi fc / c) sqrt(1 - (f/fc)^2) [dB/m]', W.alphaDbPerM(f, a42), ...
        20 / log(10) * 2 * pi * fc / W.C0 * sqrt(1 - (f / fc) ^ 2), 1e-9);
    h.eqTol('WR-42 at L2 ~ 2.548 dB/mm', W.alphaDbPerM(f, a42) / 1e3, 2.548, 1e-3);
    h.eqTol('no evanescent attenuation above cutoff', W.alphaDbPerM(26.25e9, a42), 0, 0);
    h.eqTol('total attenuation linear in length', W.totalDb(f, a42, 0.02), 2 * W.totalDb(f, a42, 0.01), 1e-9);
    h.eqTol('length for 50 dB inverts the total', W.totalDb(f, a42, W.lengthForDb(f, a42, 50)), 50, 1e-9);
    h.isTrue('WR-42 attenuates less than WR-34 at every victim band (conservative primary)', ...
        all(W.alphaDbPerM([1.176 1.575 2.05 9.65 10.6] * 1e9, a42) < W.alphaDbPerM([1.176 1.575 2.05 9.65 10.6] * 1e9, a34)));
    h.throws('negative length refused', @() W.totalDb(f, a42, -1), 'rfscreen:psd:negativeLength');
    WG = SD.readTable(fullfile(repo, 'data', 'rfi_psd', 'ka_waveguide_cutoff.csv'));
    i42 = strcmp(WG.waveguide, 'WR-42');
    h.eqStr('WR-42 is the primary (owner assumption)', WG.role{i42}, 'PRIMARY_OWNER_ASSUMPTION');
    h.isTrue('WR-42 effective length 50 mm = owner conservative engineering assumption', strcmp(WG.effective_length_mm{i42}, '50') && ...
        strcmp(WG.length_status{i42}, 'OWNER_CONSERVATIVE_ENGINEERING_ASSUMPTION'));

    % ---- SAR owner envelope ----
    SP = rfscreen.psd.SarOwnerPattern.fromFile(fullfile(repo, 'data', 'Xband_SAR_K8_owner', 'owner_cut_values.csv'));
    h.eqTol('azimuth envelope -3 dB at the exact 3-dB point', SP.cutGain('AZIMUTH', 0.121147), -3, 1e-9);
    h.eqTol('elevation envelope -3 dB at the exact 3-dB point', SP.cutGain('ELEVATION', 0.556111), -3, 1e-9);
    h.eqTol('boresight 0 dB', SP.directionGain(0), 0, 0);
    for c = SP.cuts
        h.isTrue(sprintf('%s envelope never below an owner sample', c.name), all(SP.cutGain(c.name, c.sampleDeg) >= c.sampleDb - 1e-12));
        h.isTrue(sprintf('%s envelope does not dip into the first null', c.name), SP.cutGain(c.name, c.thetaNull) >= c.gNull);
        tt = 0:0.05:180;
        h.isTrue(sprintf('%s envelope symmetric', c.name), isequal(SP.cutGain(c.name, -tt), SP.cutGain(c.name, tt)));
    end
    h.eqTol('azimuth sidelobe region holds -13.565 dB up to 1 deg', SP.cutGain('AZIMUTH', 0.8), -13.565, 1e-9);
    h.eqTol('upper envelope between samples (az 20-30 deg uses the higher -51.82)', SP.cutGain('AZIMUTH', 25), -51.82, 1e-9);
    h.eqTol('outer hold elevation (max sample >= 10 deg)', SP.cutGain('ELEVATION', 120), -34.674, 1e-9);
    h.eqTol('direction gain = max of the cuts', SP.directionGain(100), max(SP.cutGain('AZIMUTH', 100), SP.cutGain('ELEVATION', 100)), 0);
    SP2 = SP.withOutsideCeiling(-50);
    h.eqTol('owner ceiling -50 dB beyond +/-80 deg', SP2.directionGain([85 124 180]), [-50 -50 -50], 0);
    h.eqTol('outer hold still applies 60-80 deg (owner range)', SP2.directionGain(70), -34.674, 1e-9);
    h.eqTol('ceiling does not change the owner-range envelope', SP2.directionGain(0:0.1:80), SP.directionGain(0:0.1:80), 0);
    h.throws('positive ceiling refused', @() SP.withOutsideCeiling(3), 'rfscreen:psd:badSarCeiling');
    OA = SD.readTable(fullfile(repo, 'data', 'Xband_SAR_K8_owner', 'owner_absolute_inputs.csv'));
    v = @(k) str2double(OA.value{strcmp(OA.item, k)});
    h.eqTol('SAR peak gain 52 dBi (owner HPBW estimate)', v('SAR_PEAK_GAIN'), 52, 0);
    h.eqTol('back absolute ceiling = peak + outside ceiling = +2 dBi', v('SAR_PEAK_GAIN') + v('OUTSIDE_80_CEILING'), v('BACK_ABSOLUTE_CEILING'), 0);
    h.eqTol('HPBW cross-check 41253/(HPBW_az HPBW_el) ~ 51.9 dBi', 10 * log10(41253 / (0.242294 * 1.112221)), 51.85, 0.01);

    % ---- scope ----
    S = SD.readTable(fullfile(repo, 'data', 'rfi_psd', 'rfi_scope_matrix.csv'));
    h.isTrue('ISL TX and SAR TX excluded', all(strcmp(S.scope(ismember(S.attacker, {'ISL TX', 'SAR TX'})), 'EXCLUDED')));
    h.isTrue('KAA gain bound kept only as legacy sensitivity', any(strcmp(S.scope, 'LEGACY_SENSITIVITY')) && ...
        ~any(strcmp(S.route(strcmp(S.scope, 'PRIMARY')), 'KAA GAIN_BOUND_ONLY (Tier 3 ceiling)')));

    % ---- stored results ----
    rd = fullfile(repo, 'output', 'claude', 'results');
    if exist(fullfile(rd, 'task2_stc_sar_harmonics.csv'), 'file') == 2
        H = rdcsv(fullfile(rd, 'task2_stc_sar_harmonics.csv'));
        h.isTrue('S-TC harmonics do not overlap the SAR band', all(strcmp(H.status, 'NO_HARMONIC_OVERLAP')));
        K = rdcsv(fullfile(rd, 'task2_ka_cutoff_pairs.csv'));
        h.isTrue('Ka max EIRP 49.451 dBW', all(abs(str2double(K.max_eirp_dbw) - 49.451) < 1e-3));
        h.isTrue('Ka unattenuated EIRP PSD -16.5696 dBm/Hz', all(abs(str2double(K.unattenuated_eirp_psd_dbm_hz) + 16.5696) < 1e-3));
        w42 = strcmp(K.waveguide, 'WR-42');
        h.isTrue('WR-42 50 mm credited = alpha x 50 mm', all(abs(str2double(K.cutoff_attenuation_credited_db(w42)) - ...
            50 * str2double(K.alpha_min_db_per_mm(w42))) < 0.01));
        r20 = str2double(K.required_with_20mm_db); r50 = str2double(K.required_additional_suppression_db);
        h.isTrue('50 mm credit never needs more than the 20 mm sensitivity', all(r50 <= r20 + 1e-9));
        h.isTrue('Ka -> SAR now quantified with the owner peak gain', all(isfinite(str2double(K.required_additional_suppression_db(strcmp(K.victim_band, 'SAR'))))));
        z = r50 == 0; dt = str2double(K.design_target_db);
        h.isTrue('no design target when no additional suppression is required', all(dt(z) == 0) && all(dt(~z) >= r50(~z) + 10));
        X = rdcsv(fullfile(rd, 'task2_stc_sar_spurious.csv'));
        h.isTrue('S-TC -> SAR labelled generic spurious, not harmonic', all(~cellfun(@isempty, strfind(X.route, 'GENERIC_ITU_SPURIOUS'))));
        h.isTrue('S-TC -> SAR uses +2 dBi (outside +/-80 deg ceiling)', all(abs(str2double(X.sar_gain_toward_tx_dbi) - 2) < 1e-9));
        h.eqTol('S-TC -> SAR worst required suppression [dB]', max(str2double(X.required_additional_suppression_db)), 63.36, 0.01);
    end
end

function T = rdcsv(path)
    L = strsplit(strrep(fileread(path), char(13), ''), char(10)); L = L(~cellfun(@isempty, strtrim(L)));
    hd = strsplit(L{1}, ','); T = struct();
    V = cellfun(@(x) strsplit(x, ',', 'CollapseDelimiters', false), L(2:end), 'UniformOutput', false);
    for j = 1:numel(hd); T.(hd{j}) = cellfun(@(v) v{j}, V, 'UniformOutput', false); end
end
