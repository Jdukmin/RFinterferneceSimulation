classdef CsvPatternImporter < rfscreen.patterndata.PatternImporter
    %CSVPATTERNIMPORTER Import a cut from a 2-column CSV (theta,gain) (§23).
    %   A single optional header line (non-numeric first token) is skipped.
    %   Fidelity/plane/convention are supplied explicitly; NEVER inferred from
    %   the filename (§22).
    properties (SetAccess = private)
        filePath
        conv
        meta
    end
    methods
        function obj = CsvPatternImporter(filePath, conv, meta)
            if nargin < 3 || isempty(meta); meta = struct(); end
            obj.filePath = rfscreen.util.Validate.id(filePath, 'filePath');
            if ~isa(conv, 'rfscreen.patterndata.SourceCoordinateConvention')
                error('rfscreen:patterndata:badConvention', ...
                    'conv must be a rfscreen.patterndata.SourceCoordinateConvention.');
            end
            obj.conv = conv;
            if ~isfield(meta, 'sourceType') || isempty(meta.sourceType)
                meta.sourceType = 'CSV';
            end
            if ~isfield(meta, 'sourceFile') || isempty(meta.sourceFile)
                meta.sourceFile = filePath;
            end
            obj.meta = meta;
        end

        function [theta, gain, conv, meta] = readRaw(obj)
            if exist(obj.filePath, 'file') ~= 2
                error('rfscreen:patterndata:fileNotFound', 'CSV file not found: %s', obj.filePath);
            end
            txt = fileread(obj.filePath);
            lines = regexp(txt, '\r\n|\r|\n', 'split');
            theta = []; gain = [];
            for i = 1:numel(lines)
                ln = strtrim(lines{i});
                if isempty(ln) || ln(1) == '#' || ln(1) == '%'; continue; end
                toks = regexp(ln, '[,;\t ]+', 'split');
                toks = toks(~cellfun(@isempty, toks));
                if numel(toks) < 2; continue; end
                a = str2double(toks{1}); b = str2double(toks{2});
                if isnan(a) || isnan(b)
                    continue;   % header or non-numeric line: skip
                end
                theta(end+1) = a; %#ok<AGROW>
                gain(end+1) = b;  %#ok<AGROW>
            end
            conv = obj.conv; meta = obj.meta;
        end
    end
end
