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
    h.isTrue('no confirmed effective length (INPUT_MISSING, not invented)', all(cellfun(@isempty, WG.effective_length_mm)));
    h.eqStr('WR-42 is the primary (datasheet baseline + conservative)', WG.role{strcmp(WG.waveguide, 'WR-42')}, 'PRIMARY_DATASHEET_BASELINE_CONSERVATIVE');

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
    h.eqStr('absolute peak gain unknown (no 0 dBi)', SP.PEAK_STATUS, 'SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN');

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
        h.isTrue('no cutoff credited without a confirmed length', all(str2double(K.cutoff_attenuation_credited_db) == 0));
        sar = strcmp(K.victim_band, 'SAR');
        h.isTrue('Ka -> SAR: no absolute required suppression (peak gain unknown)', all(strcmp(K.required_additional_suppression_db(sar), 'NaN')) && ...
            all(~strcmp(K.sar_required_minus_peak_gain_db(sar), 'NaN')));
        r20 = str2double(K.required_with_20mm_db(~sar)); r0 = str2double(K.required_additional_suppression_db(~sar));
        h.isTrue('20 mm sensitivity lowers the requirement', all(r20 < r0));
        X = rdcsv(fullfile(rd, 'task2_stc_sar_spurious.csv'));
        h.isTrue('S-TC -> SAR labelled generic spurious, not harmonic', all(~cellfun(@isempty, strfind(X.route, 'GENERIC_ITU_SPURIOUS'))));
    end
end

function T = rdcsv(path)
    L = strsplit(strrep(fileread(path), char(13), ''), char(10)); L = L(~cellfun(@isempty, strtrim(L)));
    hd = strsplit(L{1}, ','); T = struct();
    V = cellfun(@(x) strsplit(x, ',', 'CollapseDelimiters', false), L(2:end), 'UniformOutput', false);
    for j = 1:numel(hd); T.(hd{j}) = cellfun(@(v) v{j}, V, 'UniformOutput', false); end
end
