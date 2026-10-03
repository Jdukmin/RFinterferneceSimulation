classdef SpacecraftDataReader
    %SPACECRAFTDATAREADER Read simplified-spacecraft dataset CSV tables (ICD mission_spacecraft.md 3).
    %   The ONLY file-parsing class of +spacecraft (+geometry stays file-free).
    %   Format: '#'/'%' comment lines and blank lines are skipped; the first
    %   remaining line is the comma-separated header; fields contain no commas.
    %   Values are returned as text (cellstr columns); numeric conversion and the
    %   single mm -> m unit conversion (mmToM) are explicit at the call site.
    methods (Static)
        function T = readTable(filePath)
            %READTABLE Struct of cellstr columns keyed by header name (+ nRows).
            if exist(filePath, 'file') ~= 2
                error('rfscreen:spacecraft:fileNotFound', 'dataset file not found: %s', filePath);
            end
            lines = regexp(fileread(filePath), '\r\n|\r|\n', 'split');
            header = {}; rows = {};
            for i = 1:numel(lines)
                ln = strtrim(lines{i});
                if isempty(ln) || ln(1) == '#' || ln(1) == '%'; continue; end
                toks = cellfun(@strtrim, rfscreen.spacecraft.SpacecraftDataReader.splitFields(ln), 'UniformOutput', false);
                if isempty(header)
                    header = toks;
                    continue;
                end
                if numel(toks) ~= numel(header)
                    error('rfscreen:spacecraft:badRow', ...
                        '%s: row "%s" has %d fields, header has %d.', filePath, ln, numel(toks), numel(header));
                end
                rows{end+1} = toks; %#ok<AGROW>
            end
            if isempty(header)
                error('rfscreen:spacecraft:badTable', '%s: no header row.', filePath);
            end
            T = struct('nRows', numel(rows));
            for c = 1:numel(header)
                col = cell(1, numel(rows));
                for r = 1:numel(rows); col{r} = rows{r}{c}; end
                T.(header{c}) = col;
            end
        end

        function v = num(T, col, r, label)
            %NUM Numeric value of T.(col){r}; error if not a finite number.
            v = str2double(T.(col){r});
            if ~(isscalar(v) && isfinite(v))
                error('rfscreen:spacecraft:badNumber', '%s: "%s" is not a finite number.', ...
                    label, T.(col){r});
            end
        end

        function m = mmToM(mm)
            %MMTOM Canonical unit conversion for the dataset (source mm -> metres).
            m = mm / 1000;
        end
    end
    methods (Static, Access = private)
        function toks = splitFields(ln)
            % split on commas, keeping empty fields (portable MATLAB/Octave)
            idx = [0, strfind(ln, ','), numel(ln) + 1];
            toks = cell(1, numel(idx) - 1);
            for k = 1:numel(idx) - 1
                toks{k} = ln(idx(k) + 1 : idx(k + 1) - 1);
            end
        end
    end
end
