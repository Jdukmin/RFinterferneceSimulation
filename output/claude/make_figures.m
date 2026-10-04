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
    vmax = ceil(max([A(:); Bv(:)]) / 10) * 10; vmin = 0; sc = (W - left - 40) / (vmax - vmin);
    f = fopen(path, 'w');
    fprintf(f, '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" font-family="sans-serif" font-size="12">\n', W, H);
    fprintf(f, '<rect width="100%%" height="100%%" fill="white"/>\n<text x="%d" y="24" font-size="15" font-weight="bold">%s</text>\n', 10, titleStr);
    for g = 0:10:vmax
        x = left + (g - vmin) * sc;
        fprintf(f, '<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="#ddd"/><text x="%.1f" y="%d" text-anchor="middle">%d</text>\n', x, top - 6, x, top + n * rowH, x, top + n * rowH + 16, g);
    end
    for i = 1:n
        y = top + (i - 1) * rowH;
        fprintf(f, '<text x="%d" y="%d" text-anchor="end">%s</text>\n', left - 6, y + 16, labels{i});
        if isfinite(A(i)); fprintf(f, '<rect x="%d" y="%d" width="%.1f" height="10" fill="#1f5fa8"/>\n', left, y + 4, max(0, A(i) * sc)); end
        if isfinite(Bv(i)); fprintf(f, '<rect x="%d" y="%d" width="%.1f" height="10" fill="#e08a1e"/>\n', left, y + 14, max(0, Bv(i) * sc)); end
        if isfinite(A(i)); fprintf(f, '<text x="%.1f" y="%d" font-size="10">%.1f</text>\n', left + A(i) * sc + 4, y + 13, A(i)); end
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
    sel = find(strcmp(T.case_id, cid{1}) & ~strcmp(T.received_A_dbm, 'NaN'));
    A = str2double(T.required_rejection_A_db(sel)); Bv = str2double(T.required_rejection_B_db(sel));
    [~, o] = sort(A, 'descend'); sel = sel(o); A = A(o); Bv = Bv(o);
    lab = cellfun(@(a, b) [strrep(a, '_TX', '') ' > ' strrep(b, '_RX', '')], T.tx_system(sel), T.rx_system(sel), 'UniformOutput', false);
    svgbars(fullfile(figDir, ['required_rejection_' cid{1} '.svg']), ...
        sprintf('%s: required out-of-band rejection at the victim (received level - allowable) [dB]', cid{1}), lab, A, Bv, ...
        'dB (free-space; no polarization / blockage loss applied)', 'A: CST RealizedGain both ends', 'B: frozen reference TX pattern');
end
S = readcsv(fullfile(here, 'results', 'sar_assessment.csv'));
sel = find(strcmp(S.status, 'ASSUMPTION_SENSITIVITY') & strcmp(S.assumed_sar_gain_dbi, '0.0000'));
lab = cellfun(@(v, p) sprintf('SAR (%s dBm) > %s', p(1:5), v), S.victim(sel), S.power_dbm(sel), 'UniformOutput', false);
r = str2double(S.required_rejection_db(sel));
svgbars(fullfile(figDir, 'sar_assumption_required_rejection.svg'), ...
    'Hypothetical SAR TX (SAR gain toward victim assumed 0 dBi): required rejection [dB]', lab, r, NaN(size(r)), ...
    'dB (ASSUMPTION sensitivity; victim SAR-band RealizedGain from CST)', 'SAR gain 0 dBi (assumed)', '');
printf('figures written to %s\n', figDir);
