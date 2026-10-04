1;  % Octave: SVG figures from results/*.csv (headless; no graphics toolkit needed)
function T = readcsv(p)
    L = regexp(fileread(p), '\r\n|\r|\n', 'split'); L = L(~cellfun(@isempty, L));
    h = regexp(L{1}, ',', 'split'); T = struct();
    for j = 1:numel(h); T.(h{j}) = cell(1, numel(L) - 1); end
    for i = 2:numel(L)
        v = regexp(L{i}, ',', 'split');
        for j = 1:numel(h); T.(h{j}){i - 1} = v{j}; end
    end
end
function svgbars(path, titleStr, labels, A, Bv, xlab, legendA, legendB)
    n = numel(labels); W = 980; rowH = 26; top = 60; left = 330; H = top + n * rowH + 60;
    vmax = ceil(max([A(:); Bv(:)]) / 10) * 10; vmin = min(0, floor(min([A(:); Bv(:)]) / 10) * 10);
    sc = (W - left - 40) / (vmax - vmin); x0 = left + (0 - vmin) * sc;
    f = fopen(path, 'w');
    fprintf(f, '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" font-family="sans-serif" font-size="12">\n', W, H);
    fprintf(f, '<rect width="100%%" height="100%%" fill="white"/>\n<text x="%d" y="24" font-size="15" font-weight="bold">%s</text>\n', 10, titleStr);
    for g = vmin:10:vmax
        x = left + (g - vmin) * sc;
        fprintf(f, '<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="#ddd"/><text x="%.1f" y="%d" text-anchor="middle">%d</text>\n', x, top - 6, x, top + n * rowH, x, top + n * rowH + 16, g);
    end
    for i = 1:n
        y = top + (i - 1) * rowH;
        fprintf(f, '<text x="%d" y="%d" text-anchor="end">%s</text>\n', left - 6, y + 16, labels{i});
        if isfinite(A(i)); fprintf(f, '<rect x="%.1f" y="%d" width="%.1f" height="10" fill="#1f5fa8"/>\n', min(x0, x0 + A(i) * sc), y + 4, abs(A(i)) * sc); end
        if isfinite(Bv(i)); fprintf(f, '<rect x="%.1f" y="%d" width="%.1f" height="10" fill="#e08a1e"/>\n', min(x0, x0 + Bv(i) * sc), y + 14, abs(Bv(i)) * sc); end
        if isfinite(A(i)); fprintf(f, '<text x="%.1f" y="%d" font-size="10">%.1f</text>\n', x0 + max(A(i), 0) * sc + 4, y + 13, A(i)); end
    end
    fprintf(f, '<text x="%d" y="%d" text-anchor="middle">%s</text>\n', left + (W - left - 40) / 2, H - 14, xlab);
    fprintf(f, '<rect x="%d" y="34" width="12" height="10" fill="#1f5fa8"/><text x="%d" y="44">%s</text>\n', W - 420, W - 404, legendA);
    fprintf(f, '<rect x="%d" y="34" width="12" height="10" fill="#e08a1e"/><text x="%d" y="44">%s</text>\n', W - 210, W - 194, legendB);
    fprintf(f, '</svg>\n'); fclose(f);
end

here = fileparts(mfilename('fullpath')); if isempty(here); here = fullfile(pwd, 'output', 'claude'); end
T = readcsv(fullfile(here, 'results', 'pair_results.csv'));
figDir = fullfile(here, 'figures'); if exist(figDir, 'dir') ~= 7; mkdir(figDir); end
for cid = {'CASE_SBA1_L1', 'CASE_SBA4_L1'}
    sel = find(strcmp(T.case_id, cid{1}) & ~strcmp(T.oob_blocker_port_A_dbm, 'NaN'));
    A = str2double(T.oob_blocker_port_A_dbm(sel)); Bv = str2double(T.oob_blocker_port_B_dbm(sel));
    [~, o] = sort(A, 'descend'); sel = sel(o); A = A(o); Bv = Bv(o);
    lab = cellfun(@(a, b) [strrep(a, '_TX', '') ' > ' strrep(b, '_RX', '')], T.tx_system(sel), T.rx_system(sel), 'UniformOutput', false);
    svgbars(fullfile(figDir, ['oob_blocker_exposure_' cid{1} '.svg']), ...
        sprintf('%s: fundamental OOB blocker power at the victim antenna port [dBm] (blocking not judged)', cid{1}), lab, A, Bv, ...
        'dBm at the TX carrier (free-space; no polarization / blockage loss; Ka A = direct reflector field only)', ...
        'A: CST RealizedGain / KAA aperture near field', 'B: frozen reference TX pattern (Friis)');
end
S = readcsv(fullfile(here, 'results', 'sar_assessment.csv'));
sel = find(strcmp(S.status, 'ASSUMPTION_SENSITIVITY') & strcmp(S.assumed_sar_gain_dbi, '0.0000'));
lab = cellfun(@(v, p) sprintf('SAR (%s dBm) > %s', p(1:5), v), S.victim(sel), S.power_dbm(sel), 'UniformOutput', false);
r = str2double(S.received_dbm(sel));
svgbars(fullfile(figDir, 'sar_assumption_blocker_exposure.svg'), ...
    'Hypothetical SAR TX (SAR gain toward victim assumed 0 dBi): OOB blocker power at the victim port [dBm]', lab, r, NaN(size(r)), ...
    'dB (ASSUMPTION sensitivity; victim SAR-band RealizedGain from CST)', 'SAR gain 0 dBi (assumed)', '');
% ---- Ka: near-field -> far-field convergence on boresight (26.25 GHz) ----
V = readcsv(fullfile(here, 'results', 'ka_nearfield_validation.csv'));
sel = find(strcmp(V.region, 'BORESIGHT_DISTANCE_SWEEP'));
x = str2double(V.distance_m(sel)); y = str2double(V.Geq_nearfield_dbi(sel)); gff = str2double(V.G_farfield_aperture_dbi{sel(1)});
W = 760; H = 420; L0 = 70; T0 = 50; PW = W - L0 - 30; PH = H - T0 - 60;
lx = @(v) L0 + (log10(v) - log10(0.3)) / (log10(1000) - log10(0.3)) * PW;
ymin = floor(min(y) / 5) * 5 - 5; ymax = 35; ly = @(v) T0 + (ymax - v) / (ymax - ymin) * PH;
f = fopen(fullfile(figDir, 'ka_nearfield_convergence.svg'), 'w');
fprintf(f, '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" font-family="sans-serif" font-size="12">\n', W, H);
fprintf(f, '<rect width="100%%" height="100%%" fill="white"/>\n<text x="10" y="24" font-size="15" font-weight="bold">KAA 26.25 GHz boresight: aperture near-field Geq = 4 pi d^2 S / P vs distance</text>\n');
for g = [0.3 1 3 10 30 100 300 1000]
    fprintf(f, '<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="#ddd"/><text x="%.1f" y="%d" text-anchor="middle">%g</text>\n', lx(g), T0, lx(g), T0 + PH, lx(g), T0 + PH + 16, g);
end
for g = ymin:5:ymax
    fprintf(f, '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#ddd"/><text x="%d" y="%.1f" text-anchor="end">%d</text>\n', L0, ly(g), L0 + PW, ly(g), L0 - 6, ly(g) + 4, g);
end
pts = sprintf('%.1f,%.1f ', [arrayfun(lx, x(:).'); arrayfun(ly, y(:).')]);
fprintf(f, '<polyline points="%s" fill="none" stroke="#1f5fa8" stroke-width="2"/>\n', pts);
fprintf(f, '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#e08a1e" stroke-dasharray="6,4" stroke-width="2"/>\n', L0, ly(gff), L0 + PW, ly(gff));
rff = x(1) / str2double(V.distance_over_Rff{sel(1)});
fprintf(f, '<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="#888" stroke-dasharray="2,3"/><text x="%.1f" y="%d">2D^2/lambda = %.2f m</text>\n', lx(rff), T0, lx(rff), T0 + PH, lx(rff) + 4, T0 + 14, rff);
for d = [1.778 2.342]
    fprintf(f, '<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="#c33" stroke-dasharray="2,3"/>\n', lx(d), T0, lx(d), T0 + PH);
end
fprintf(f, '<text x="%.1f" y="%d" fill="#c33">KAA-ISL 1.78 / 2.34 m</text>\n', lx(1.778) + 4, T0 + PH - 8);
fprintf(f, '<text x="%d" y="%d" text-anchor="middle">distance from aperture centre [m] (log)</text>\n', L0 + PW / 2, H - 14);
fprintf(f, '<text x="16" y="%d" transform="rotate(-90 16 %d)" text-anchor="middle">dBi</text>\n', T0 + PH / 2, T0 + PH / 2);
fprintf(f, '<line x1="%d" y1="38" x2="%d" y2="38" stroke="#1f5fa8" stroke-width="2"/><text x="%d" y="42">near field (aperture integration)</text>\n', W - 430, W - 410, W - 404);
fprintf(f, '<line x1="%d" y1="38" x2="%d" y2="38" stroke="#e08a1e" stroke-dasharray="6,4" stroke-width="2"/><text x="%d" y="42">far-field gain %.2f dBi</text>\n', W - 190, W - 170, W - 164, gff);
fprintf(f, '</svg>\n'); fclose(f);
% ---- Ka: gimbal nominal vs max-coupling incident power density ----
Gw = readcsv(fullfile(here, 'results', 'ka_gimbal_worstcase.csv'));
nom = find(strcmp(Gw.gimbal_state, 'NOMINAL_GIMBAL_REFERENCE')); wor = find(strcmp(Gw.gimbal_state, 'MAX_COUPLING_ALLOWED'));
lab = cellfun(@(a, b) [a ' > ' b], Gw.kaa_id(nom), Gw.victim_mount(nom), 'UniformOutput', false);
svgbars(fullfile(figDir, 'ka_gimbal_power_density.svg'), ...
    'KAA direct reflector field at the victim: incident power density (3-monitor mean) [dBm/m2]', lab, ...
    str2double(Gw.S_band_dbmpm2(nom)), str2double(Gw.S_band_dbmpm2(wor)), ...
    'dBm/m2 (DIRECT_REFLECTOR_FIELD_ONLY; STRUCTURE_SCATTERING_NOT_MODELED; hemisphere steering assumption)', ...
    'nominal gimbal reference', 'max-coupling steering');
% ---- victim-band PSD path: emission limit implied at the TX antenna port (no mask available) ----
Q = readcsv(fullfile(here, 'results', 'psd_pair_summary.csv'));
sel = find(strcmp(Q.case_id, 'CASE_SBA1_L1') & ~strcmp(Q.min_max_tx_psd_at_antenna_port_dbm_hz, 'NaN'));
v = str2double(Q.min_max_tx_psd_at_antenna_port_dbm_hz(sel)); [v, o] = sort(v); sel = sel(o);
lab = cellfun(@(a, b) [strrep(a, '_TX', '') ' > ' strrep(b, '_RX', '')], Q.tx_system(sel), Q.rx_system(sel), 'UniformOutput', false);
svgbars(fullfile(figDir, 'psd_emission_limit_CASE_SBA1_L1.svg'), ...
    'Victim-band path: max TX unwanted-emission PSD at the TX antenna port that meets the victim PSD criterion [dBm/Hz]', ...
    lab, v, NaN(size(v)), 'dBm/Hz (= allowable PSD - C_EM(f) worst over the victim tuning band; derived limit, no TX mask available)', ...
    'derived TX emission PSD limit', '');
printf('figures written to %s\n', figDir);
