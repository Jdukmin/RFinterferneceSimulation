classdef CstS21Importer
    %CSTS21IMPORTER Import CST/solver S-parameter exports into CstS21Table objects (ICD coupling.md 6).
    %   Formats: Touchstone (.sNp; CST "Export Touchstone", DB/MA/RI) and a simple CSV
    %   (frequency_*, s21_db [, phase_deg]). Pure file -> data translation: no physics, no
    %   defaults for missing data. Port <-> antenna mapping is explicit (never guessed).
    methods (Static)
        function tbl = fromCsv(filePath, txAntennaId, rxAntennaId, opts)
            %FROMCSV Single-pair table from a CSV with header
            %   frequency_hz|frequency_mhz|frequency_ghz , s21_db [, phase_deg]
            if nargin < 4 || isempty(opts); opts = struct(); end
            if exist(filePath, 'file') ~= 2
                error('rfscreen:coupling:fileNotFound', 'S21 CSV not found: %s', filePath);
            end
            lines = regexp(fileread(filePath), '\r\n|\r|\n', 'split');
            header = {}; rows = [];
            for i = 1:numel(lines)
                ln = strtrim(lines{i});
                if isempty(ln) || ln(1) == '#' || ln(1) == '%' || ln(1) == '!'; continue; end
                toks = strtrim(regexp(ln, ',', 'split'));
                if isempty(header)
                    header = lower(toks); continue;
                end
                v = str2double(toks);
                if numel(v) ~= numel(header) || any(isnan(v))
                    error('rfscreen:coupling:badS21', '%s: bad data row "%s".', filePath, ln);
                end
                rows(end+1, :) = v; %#ok<AGROW>
            end
            if isempty(header) || isempty(rows)
                error('rfscreen:coupling:badS21', '%s: no data.', filePath);
            end
            fi = find(ismember(header, {'frequency_hz', 'frequency_mhz', 'frequency_ghz'}), 1);
            si = find(strcmp(header, 's21_db'), 1);
            if isempty(fi) || isempty(si)
                error('rfscreen:coupling:badS21', '%s: header needs frequency_hz|mhz|ghz and s21_db.', filePath);
            end
            scale = struct('frequency_hz', 1, 'frequency_mhz', 1e6, 'frequency_ghz', 1e9);
            f = rows(:, fi).' * scale.(header{fi});
            pi_ = find(strcmp(header, 'phase_deg'), 1);
            o = opts; o.sourceFile = filePath;
            if ~isempty(pi_); o.phase_deg = rows(:, pi_).'; end
            tbl = rfscreen.coupling.CstS21Table(txAntennaId, rxAntennaId, f, rows(:, si).', o);
        end

        function tables = fromTouchstone(filePath, portAntennaIds, opts)
            %FROMTOUCHSTONE All ordered pairs i->j (i ~= j) of an N-port file as CstS21Table:
            %   table(txAntennaId = portAntennaIds{i}, rxAntennaId = portAntennaIds{j}) holds S(j,i).
            %   Returns a cell array of tables.
            if nargin < 3 || isempty(opts); opts = struct(); end
            if exist(filePath, 'file') ~= 2
                error('rfscreen:coupling:fileNotFound', 'Touchstone file not found: %s', filePath);
            end
            N = numel(portAntennaIds);
            if N < 2 || ~iscellstr(portAntennaIds) || numel(unique(portAntennaIds)) ~= N
                error('rfscreen:coupling:badPorts', 'portAntennaIds must be >= 2 unique antenna ids (one per port).');
            end
            tok = regexp(filePath, '\.s(\d+)p$', 'tokens', 'once');
            if ~isempty(tok) && str2double(tok{1}) ~= N
                error('rfscreen:coupling:badPorts', '%s has %s ports but %d antenna ids were given.', filePath, tok{1}, N);
            end
            lines = regexp(fileread(filePath), '\r\n|\r|\n', 'split');
            unitScale = 1e9; fmt = 'MA'; z0 = 50; haveOpt = false; vals = [];
            for i = 1:numel(lines)
                ln = lines{i};
                k = strfind(ln, '!'); if ~isempty(k); ln = ln(1:k(1)-1); end
                ln = strtrim(ln);
                if isempty(ln); continue; end
                if ln(1) == '#'
                    if haveOpt; continue; end
                    haveOpt = true;
                    t = upper(strtrim(regexp(ln(2:end), '\s+', 'split')));
                    t = t(~cellfun(@isempty, t));
                    for q = 1:numel(t)
                        switch t{q}
                            case 'HZ';  unitScale = 1;
                            case 'KHZ'; unitScale = 1e3;
                            case 'MHZ'; unitScale = 1e6;
                            case 'GHZ'; unitScale = 1e9;
                            case {'DB', 'MA', 'RI'}; fmt = t{q};
                            case 'S'
                            case 'R'; z0 = str2double(t{min(q + 1, numel(t))});
                            case {'Y', 'Z', 'G', 'H'}
                                error('rfscreen:coupling:badTouchstone', 'only S-parameter files are supported.');
                        end
                    end
                    continue;
                end
                v = str2double(regexp(ln, '\s+', 'split'));
                if any(isnan(v))
                    error('rfscreen:coupling:badTouchstone', '%s: non-numeric data "%s".', filePath, ln);
                end
                vals = [vals, v]; %#ok<AGROW>
            end
            per = 1 + 2 * N * N;
            if isempty(vals) || mod(numel(vals), per) ~= 0
                error('rfscreen:coupling:badTouchstone', '%s: %d values is not a multiple of %d (N=%d).', ...
                    filePath, numel(vals), per, N);
            end
            nF = numel(vals) / per;
            rec = reshape(vals, per, nF);
            f = rec(1, :) * unitScale;
            S = zeros(N, N, nF);
            for k = 1:N * N
                a = rec(1 + 2 * k - 1, :); b = rec(1 + 2 * k, :);
                switch fmt
                    case 'DB'; c = 10.^(a / 20) .* exp(1j * b * pi / 180);
                    case 'MA'; c = a .* exp(1j * b * pi / 180);
                    case 'RI'; c = a + 1j * b;
                end
                if N == 2                      % 2-port order: S11 S21 S12 S22
                    rc = [1 1; 2 1; 1 2; 2 2];
                    r = rc(k, 1); cc = rc(k, 2);
                else                           % N >= 3: row-major
                    r = ceil(k / N); cc = k - (r - 1) * N;
                end
                S(r, cc, :) = reshape(c, 1, 1, nF);
            end
            tables = {};
            for i = 1:N
                for j = 1:N
                    if i == j; continue; end
                    s = squeeze(S(j, i, :)).';           % coupling port i -> port j
                    mag = abs(s); mag(mag < 1e-12) = 1e-12;
                    o = opts; o.sourceFile = filePath; o.referenceImpedance_ohm = z0;
                    o.phase_deg = angle(s) * 180 / pi;
                    tables{end+1} = rfscreen.coupling.CstS21Table(portAntennaIds{i}, portAntennaIds{j}, ...
                        f, 20 * log10(mag), o); %#ok<AGROW>
                end
            end
        end
    end
end
