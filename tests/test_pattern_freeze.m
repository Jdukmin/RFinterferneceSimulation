function test_pattern_freeze(h)
%TEST_PATTERN_FREEZE The frozen free-space patterns are byte-stable (P7d-2, VR-445).
%   Hash = SHA-256 of the file content with every CR removed (line-ending independent).
    h.setGroup('pattern_freeze');
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(repoRoot, 'data', 'pattern_freeze_manifest.csv'));
    h.isTrue('manifest has 56 files', T.nRows == 56);
    nBad = 0; badList = {};
    for r = 1:T.nRows
        p = fullfile(repoRoot, strrep(T.path{r}, '/', filesep));
        if exist(p, 'file') ~= 2
            nBad = nBad + 1; badList{end+1} = ['missing ' T.path{r}]; continue; %#ok<AGROW>
        end
        [hex, nBytes] = sha256File(p);
        if ~strcmp(hex, T.sha256_lf{r}) || nBytes ~= str2double(T.bytes_lf{r})
            nBad = nBad + 1; badList{end+1} = ['changed ' T.path{r}]; %#ok<AGROW>
        end
    end
    h.ok(['frozen files unchanged: ' strjoin(badList, '; ')], nBad == 0);

    % no file added to / removed from a frozen directory
    dirs = {'Sband_TMTC', 'Lband_GPS', 'Lband_GPS_CST_L2', 'Xband_ISL', 'Kaband_KAA_CST', 'Kaband_DLS'};
    listed = T.path; nExtra = 0; extra = {};
    for i = 1:numel(dirs)
        items = dir(fullfile(repoRoot, 'data', dirs{i}));
        for k = 1:numel(items)
            nm = items(k).name;
            if items(k).isdir || strcmpi(nm, 'README.md'); continue; end
            if ~any(strcmp(listed, ['data/' dirs{i} '/' nm]))
                nExtra = nExtra + 1; extra{end+1} = ['data/' dirs{i} '/' nm]; %#ok<AGROW>
            end
        end
    end
    h.ok(['no unlisted files in frozen dirs: ' strjoin(extra, '; ')], nExtra == 0);

    % every pattern bound for the analysis cases is frozen
    B = rfscreen.mission.MissionCaseBuilder.readBindings( ...
        fullfile(rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir(), 'pattern_bindings.csv'));
    keys = B.keys(); allListed = true;
    for i = 1:numel(keys)
        b = B(keys{i});
        for f = {b.xzPath, b.yzPath}
            rel = strrep(strrep(f{1}, [repoRoot filesep], ''), filesep, '/');
            allListed = allListed && any(strcmp(listed, rel));
        end
    end
    h.isTrue('all bound patterns are in the freeze manifest', allListed);

    % the legacy Ka cuts stay unbound
    legacyBound = false;
    for i = 1:numel(keys)
        b = B(keys{i});
        legacyBound = legacyBound || ~isempty(strfind(b.xzPath, 'Kaband_DLS'));
    end
    h.isFalse('legacy Kaband_DLS is bound to no antenna', legacyBound);
    h.ok('policy files exist', exist(fullfile(repoRoot, 'data', 'PATTERN_FREEZE.md'), 'file') == 2 ...
        && exist(fullfile(repoRoot, 'cst', 'PATTERN_FREEZE.md'), 'file') == 2);
end

function [hex, nBytes] = sha256File(p)
    fid = fopen(p, 'r'); raw = fread(fid, Inf, 'uint8'); fclose(fid);
    raw = raw(raw ~= 13);
    nBytes = numel(raw);
    if exist('OCTAVE_VERSION', 'builtin') ~= 0
        hex = hash('sha256', char(raw.'));
    else
        md = java.security.MessageDigest.getInstance('SHA-256');
        md.update(int8(raw - 256 * (raw > 127)));
        d = typecast(md.digest(), 'uint8');
        hex = lower(reshape(dec2hex(d, 2).', 1, []));
    end
end
