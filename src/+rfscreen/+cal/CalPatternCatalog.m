classdef CalPatternCatalog
    %CALPATTERNCATALOG Scan data/cal/{gps,isl,kaa,sba}/*.txt, recognise the owner naming convention,
    %   validate every file with CstAscii3DImporter and build one native pattern object per
    %   (file, canonical frequency).
    %
    %   Owner naming convention (explicit; nothing else is inferred from a filename):
    %     gps/GPS_ORIGINAL_f1.2   free-space, generic GPS, shared by L5 / L2 / L1
    %     gps/GPS_GPSA1_f1.2      installed on GPSA_1, shared by L5 / L2 / L1
    %     gps/GPS_GPSA2_f1.2      installed on GPSA_2, shared by L5 / L2 / L1
    %     isl/RFC_ISL_f<tok>      free-space ISL at <tok>
    %     kaa/RFC_KAA_f<tok>      free-space KAA (reflector included) at <tok>
    %     sba/RFC_SBA_f<tok>      free-space generic SBA at <tok>
    %     sba/RFC_SBA_NADIR_f<tok> / RFC_SBA_ZENITH_f<tok>   installed on SBA_NADIR / SBA_ZENITH
    %   <tok> must be listed in cal_frequency_aliases.csv ("f1.2" is never read as 1.2 GHz).
    %   Entry status: VALID | UNRECOGNIZED_NAME | WRONG_FOLDER | UNMAPPED_FREQUENCY | PARSE_ERROR |
    %   DUPLICATE_BINDING. Only VALID entries are bound; the others are reported in the inventory.
    properties (Constant)
        FOLDERS = {'gps', 'isl', 'kaa', 'sba'}
    end
    properties (SetAccess = private)
        calDir = ''
        entries = struct([])
        patterns            % containers.Map key -> CstNative*Pattern (key = patternKey())
    end
    methods (Static)
        function c = scan(calDir, freqMap)
            c = rfscreen.cal.CalPatternCatalog();
            c.calDir = calDir;
            c.patterns = containers.Map('KeyType', 'char', 'ValueType', 'any');
            E = struct('file', {}, 'relPath', {}, 'folder', {}, 'stem', {}, 'family', {}, 'installationId', {}, ...
                'patternType', {}, 'token', {}, 'freqs_Hz', {}, 'freqLabels', {}, 'status', {}, 'message', {}, ...
                'data', {}, 'keys', {});
            if exist(calDir, 'dir') ~= 7
                c.entries = E; return;
            end
            F = rfscreen.cal.CalPatternCatalog.FOLDERS;
            for i = 1:numel(F)
                d = fullfile(calDir, F{i});
                if exist(d, 'dir') ~= 7; continue; end
                L = dir(d);
                L = L(~[L.isdir]);
                names = sort({L.name});
                for j = 1:numel(names)
                    [~, stem, ext] = fileparts(names{j});
                    if ~strcmpi(ext, '.txt'); continue; end
                    e = rfscreen.cal.CalPatternCatalog.classify(stem, F{i}, freqMap);
                    e.file = fullfile(d, names{j}); e.relPath = [F{i} '/' names{j}];
                    E(end+1) = e; %#ok<AGROW>
                end
            end
            % Duplicate bindings (same family / installation / type / frequency): none is chosen.
            for a = 1:numel(E)
                if ~strcmp(E(a).status, 'VALID'); continue; end
                for b = a+1:numel(E)
                    if strcmp(E(b).status, 'VALID') && strcmp(E(a).family, E(b).family) && ...
                            strcmp(E(a).installationId, E(b).installationId) && strcmp(E(a).patternType, E(b).patternType) && ...
                            any(ismember(round(E(a).freqs_Hz), round(E(b).freqs_Hz)))
                        msg = sprintf('same binding as %s and %s: neither is used', E(a).relPath, E(b).relPath);
                        E(a).status = 'DUPLICATE_BINDING'; E(a).message = msg;
                        E(b).status = 'DUPLICATE_BINDING'; E(b).message = msg;
                    end
                end
            end
            % Parse + validate (only recognised, uniquely bound files).
            for a = 1:numel(E)
                if ~strcmp(E(a).status, 'VALID'); continue; end
                try
                    E(a).data = rfscreen.cal.CstAscii3DImporter.read(E(a).file);
                    if ~isempty(E(a).data.warnings)
                        E(a).message = strjoin(E(a).data.warnings, '; ');
                    end
                catch err
                    E(a).status = 'PARSE_ERROR';
                    E(a).message = sprintf('%s (%s)', err.message, err.identifier);
                    continue;
                end
                for k = 1:numel(E(a).freqs_Hz)
                    key = rfscreen.cal.CalPatternCatalog.patternKey(E(a).family, E(a).installationId, ...
                        E(a).patternType, E(a).freqs_Hz(k));
                    meta = struct('family', E(a).family, 'installationId', E(a).installationId);
                    name = sprintf('CAL_%s_%s', E(a).stem, E(a).freqLabels{k});
                    if strcmp(E(a).patternType, 'INSTALLED')
                        p = rfscreen.cal.CstNativeInstalledPattern(name, E(a).data, E(a).freqs_Hz(k), meta);
                    else
                        p = rfscreen.cal.CstNativeFreeSpacePattern(name, E(a).data, E(a).freqs_Hz(k), meta);
                    end
                    c.patterns(key) = p;
                    E(a).keys{end+1} = key;
                end
            end
            c.entries = E;
        end

        function key = patternKey(family, installationId, patternType, f_Hz)
            if isempty(installationId); installationId = 'GENERIC'; end
            key = sprintf('%s|%s|%s|%.0f', family, installationId, patternType, round(f_Hz));
        end

        function e = classify(stem, folder, freqMap)
            e = struct('file', '', 'relPath', '', 'folder', folder, 'stem', stem, 'family', '', 'installationId', '', ...
                'patternType', '', 'token', '', 'freqs_Hz', [], 'freqLabels', {{}}, 'status', 'VALID', 'message', '', ...
                'data', [], 'keys', {{}});
            tok = regexpi(stem, '^GPS_(ORIGINAL|GPSA1|GPSA2)_f1\.2$', 'tokens', 'once');
            if ~isempty(tok)
                e.family = 'GPS'; e.token = '1.2';
                switch upper(tok{1})
                    case 'ORIGINAL'; e.patternType = 'FREE_SPACE';
                    case 'GPSA1';    e.patternType = 'INSTALLED'; e.installationId = 'GPSA_1';
                    case 'GPSA2';    e.patternType = 'INSTALLED'; e.installationId = 'GPSA_2';
                end
                [e.freqs_Hz, e.freqLabels] = freqMap.gpsCommon();
            else
                t2 = regexpi(stem, '^RFC_SBA_(NADIR|ZENITH)_f([0-9]+(\.[0-9]+)?)$', 'tokens', 'once');
                t1 = regexpi(stem, '^RFC_(ISL|KAA|SBA)_f([0-9]+(\.[0-9]+)?)$', 'tokens', 'once');
                if ~isempty(t2)
                    e.family = 'SBA'; e.patternType = 'INSTALLED'; e.installationId = ['SBA_' upper(t2{1})]; e.token = t2{2};
                elseif ~isempty(t1)
                    e.family = upper(t1{1}); e.patternType = 'FREE_SPACE'; e.token = t1{2};
                else
                    e.status = 'UNRECOGNIZED_NAME';
                    e.message = 'filename does not follow the CAL naming convention: not used';
                    return;
                end
                [ok, f, lab] = freqMap.resolve(e.token);
                if ~ok
                    e.status = 'UNMAPPED_FREQUENCY';
                    e.message = sprintf('frequency token %s is not in cal_frequency_aliases.csv: not used (no extrapolation)', e.token);
                    return;
                end
                e.freqs_Hz = f; e.freqLabels = {lab};
            end
            if ~strcmpi(folder, e.family)
                e.status = 'WRONG_FOLDER';
                e.message = sprintf('%s file found in %s/: not used', e.family, folder);
            end
        end
    end

    methods
        function [p, key] = find(c, family, installationId, patternType, f_Hz)
            %FIND Pattern object or [] (exact canonical frequency only).
            key = rfscreen.cal.CalPatternCatalog.patternKey(family, installationId, patternType, f_Hz);
            if c.patterns.isKey(key); p = c.patterns(key); else; p = []; end
        end

        function n = nValid(c)
            if isempty(c.entries); n = 0; return; end
            n = sum(strcmp({c.entries.status}, 'VALID'));
        end
    end
end
