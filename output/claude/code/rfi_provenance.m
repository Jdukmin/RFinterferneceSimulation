function p = rfi_provenance(repo, outDir, scriptName, note)
%RFI_PROVENANCE Record the input/source state of an analysis run (no SHA hard-coded in reports).
%   analysis_base_commit = git HEAD when the script ran. Results are produced from the working tree
%   on top of that commit; if the tree was dirty, the commit that stores the results is a later one
%   (git log -- output/claude/results). Writes/updates one row per script in results/run_provenance.csv.
    if nargin < 4; note = ''; end
    [~, head] = system(sprintf('git -C "%s" rev-parse HEAD', repo)); head = strtrim(head);
    [~, st] = system(sprintf('git -C "%s" status --porcelain -- src data tests output/claude/run_*.m output/claude/code', repo));
    st = strtrim(st);
    if isempty(st); tree = 'CLEAN'; else; tree = sprintf('DIRTY (%d uncommitted input/code paths)', numel(strsplit(st, char(10)))); end
    p = struct('script', scriptName, 'run_time', datestr(now, 'yyyy-mm-dd HH:MM:SS'), 'analysis_base_commit', head, ...
        'working_tree', tree, 'note', note);
    f = fullfile(outDir, 'run_provenance.csv'); hdr = 'script,run_time,analysis_base_commit,working_tree,note';
    rows = {};
    if exist(f, 'file') == 2
        L = strsplit(strrep(fileread(f), char(13), ''), char(10)); L = L(~cellfun(@isempty, strtrim(L)));
        rows = L(2:end); rows = rows(~strncmp(rows, [scriptName ','], numel(scriptName) + 1));
    end
    rows{end+1} = strjoin({p.script, p.run_time, p.analysis_base_commit, p.working_tree, strrep(note, ',', ';')}, ',');
    fid = fopen(f, 'w'); fprintf(fid, '%s\n', hdr); fprintf(fid, '%s\n', rows{:}); fclose(fid);
end
