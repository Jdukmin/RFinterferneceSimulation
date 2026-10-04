function [theta, gain, quantity] = rfi_read_cut(path, rawColumn)
%RFI_READ_CUT Read one 1-degree cut CSV (theta 0..359).
%   Public cuts: header "theta,gain" -> gain is the quantity named by the file/manifest.
%   Raw CST cuts (cst/results/...): pass rawColumn (e.g. 'realized_gain_dbi'); the legacy
%   'gain' column is NOT used for raw files (it may be RealizedGain or Gain depending on the case).
    if nargin < 2; rawColumn = ''; end
    txt = fileread(path);
    lines = regexp(txt, '\r\n|\r|\n', 'split');
    lines = lines(~cellfun(@isempty, strtrim(lines)));
    hdr = strtrim(regexp(lines{1}, ',', 'split'));
    it = find(strcmp(hdr, 'theta'), 1);
    if isempty(rawColumn)
        ig = find(strcmp(hdr, 'gain'), 1);
        quantity = 'AS_LABELLED_BY_FILE';
    else
        ig = find(strcmp(hdr, rawColumn), 1);
        quantity = rawColumn;
    end
    if isempty(it) || isempty(ig)
        error('rfi:badCut', '%s: column %s not found', path, rawColumn);
    end
    n = numel(lines) - 1;
    theta = zeros(1, n); gain = zeros(1, n);
    for k = 1:n
        v = str2double(regexp(lines{k + 1}, ',', 'split'));
        theta(k) = v(it); gain(k) = v(ig);
    end
    [theta, o] = sort(mod(theta, 360)); gain = gain(o);
    if numel(theta) ~= 360 || any(abs(theta - (0:359)) > 1e-9)
        error('rfi:badCut', '%s: expected theta 0..359 at 1 degree', path);
    end
end
