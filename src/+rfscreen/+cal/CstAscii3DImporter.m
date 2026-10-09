classdef CstAscii3DImporter
    %CSTASCII3DIMPORTER Reader of CST Studio full-sphere far-field ASCII (.txt) exports.
    %   Native 3D ingestion path (separate from the 2D XZ/YZ CsvPatternImporter /
    %   CutPatternAssembler path, which is left unchanged).
    %
    %   File contract (docs/icd/cal_cst_3d.md):
    %     - whitespace-delimited ASCII (any run of spaces / tabs; CR/LF tolerated);
    %     - leading non-numeric lines (CST header + "-----" separator) are skipped WITHOUT
    %       reading their text: header names are never part of the contract, so a renamed,
    %       truncated or broken header is harmless;
    %     - every following non-empty line is a numeric data row with the same column count
    %       (>= 3); a non-numeric or short row after the data started is an error with its
    %       line number (truncated / corrupted export);
    %     - columns are read BY POSITION only: col1 = Theta [deg], col2 = Phi [deg],
    %       col3 = Realized Gain [dBi]. Columns 4..8 (|E_theta|, phase, |E_phi|, phase, AR)
    %       are parsed for well-formedness but not used.
    %   Row order is never assumed: the (theta, phi) grid is rebuilt from the values and
    %   validated by CstSphericalPatternData (range, finiteness, duplicates, missing
    %   samples, step identification, completeness).
    methods (Static)
        function p = read(filePath, opts)
            %READ Parse + validate one CST ASCII file -> CstSphericalPatternData.
            if nargin < 2; opts = struct(); end
            if exist(filePath, 'file') ~= 2
                error('rfscreen:cal:fileNotFound', 'CST ASCII file not found: %s', filePath);
            end
            txt = fileread(filePath);
            [data, info] = rfscreen.cal.CstAscii3DImporter.parseText(txt, filePath);
            info.sourceFile = filePath;
            info.fileBytes = numel(txt);
            p = rfscreen.cal.CstSphericalPatternData.fromColumns(data(:, 1), data(:, 2), data(:, 3), info, opts);
        end

        function [data, info] = parseText(txt, label)
            %PARSETEXT Numeric matrix (nRows x nCols) from the CST ASCII text (error on the first malformed row).
            if nargin < 2; label = '<text>'; end
            [data, info, err] = rfscreen.cal.CstAscii3DImporter.parseTextDiag(txt, label);
            if ~isempty(err); error(err.identifier, '%s', err.message); end
        end

        function [data, info, err, lineNo] = parseTextDiag(txt, label)
            %PARSETEXTDIAG parseText without throwing (same acceptance rules), for diagnostics.
            %   err = [] or struct(identifier, message, line). On a malformed row, data holds the rows parsed
            %   before it (partial). lineNo(k) = 1-based file line of data row k.
            if nargin < 2; label = '<text>'; end
            data = zeros(0, 3); err = []; lineNo = zeros(0, 1);
            info = struct('preambleLines', NaN, 'nColumns', NaN, 'nRows', 0);
            lines = regexp(txt, '\r\n|\r|\n', 'split');
            first = 0; nCols = 0;
            for i = 1:numel(lines)
                ln = strtrim(lines{i});
                if isempty(ln); continue; end
                [v, ok] = rfscreen.cal.CstAscii3DImporter.numericLine(ln);
                if ok && numel(v) >= 3
                    first = i; nCols = numel(v); break;
                end
            end
            if first == 0
                err = struct('identifier', 'rfscreen:cal:noData', ...
                    'message', sprintf('%s: no numeric data row with >= 3 columns found.', label), 'line', NaN);
                info.preambleLines = numel(lines);
                return;
            end
            info.preambleLines = first - 1; info.nColumns = nCols;
            body = lines(first:end);
            blk = strjoin(body, sprintf('\n'));
            % Per-line token counts (vectorised): a token starts where non-space follows space.
            isTok = ~isspace(blk);
            starts = isTok & [true, ~isTok(1:end-1)];
            lineIdx = cumsum([1, blk(1:end-1) == sprintf('\n')]);
            nTok = accumarray(lineIdx(starts).', 1, [numel(body) 1]);
            keep = nTok > 0;                                   % blank lines are ignored
            lineNo = find(keep) + first - 1;
            body = body(keep);
            % Fast path: one sscanf over the whole numeric block, verified by count.
            [v, cnt, ~, nxt] = sscanf(blk, '%f');
            if nxt > numel(blk) && cnt == nCols * numel(body) && all(nTok(keep) == nCols)
                data = reshape(v, nCols, []).';
                info.nRows = size(data, 1);
                return;
            end
            % Slow path: locate the first malformed row for a precise diagnostic (rows before it kept).
            data = NaN(numel(body), nCols);
            for k = 1:numel(body)
                [vk, ok] = rfscreen.cal.CstAscii3DImporter.numericLine(strtrim(body{k}));
                msg = '';
                if ~ok
                    msg = sprintf('%s line %d: non-numeric data row "%s".', ...
                        label, lineNo(k), rfscreen.cal.CstAscii3DImporter.clip(body{k}));
                elseif numel(vk) ~= nCols
                    msg = sprintf('%s line %d: %d columns, expected %d (truncated row?) "%s".', ...
                        label, lineNo(k), numel(vk), nCols, rfscreen.cal.CstAscii3DImporter.clip(body{k}));
                end
                if ~isempty(msg)
                    err = struct('identifier', 'rfscreen:cal:malformedRow', 'message', msg, 'line', lineNo(k));
                    data = data(1:k-1, :); lineNo = lineNo(1:k-1); info.nRows = k - 1;
                    return;
                end
                data(k, :) = vk(:).';
            end
            err = struct('identifier', 'rfscreen:cal:malformedRow', ...
                'message', sprintf('%s: numeric block could not be parsed.', label), 'line', NaN);
            info.nRows = size(data, 1);
        end
    end

    methods (Static, Access = private)
        function [v, ok] = numericLine(ln)
            % Whole-line numeric parse; a partially numeric line is NOT numeric.
            [v, cnt, ~, nxt] = sscanf(ln, '%f');
            ok = cnt > 0 && nxt > numel(ln);
        end

        function s = clip(s)
            s = strtrim(s);
            if numel(s) > 80; s = [s(1:77) '...']; end
        end
    end
end
