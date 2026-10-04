%RFC_LEVEL_REPORT Received level (S21) of every interferer -> victim pair for the six analysis cases.
%   Coupling policy (owner, 2026-10-04): X-band (ISL), Ka and SAR use free space; L- and S-band use an
%   installed pattern / S21 where available (none accepted yet -> free space, flagged). Writes
%   docs/reports/rfc_levels/rfc_levels_all.csv and docs/reports/installed_local/ (cropped facets for
%   the local installed-pattern EM model of the four L/S antennas).
here = fileparts(mfilename('fullpath'));
repo = fileparts(here);
addpath(fullfile(repo, 'src'));
MB = rfscreen.mission.MissionCaseBuilder;
RL = rfscreen.mission.RfcLevelReport;
cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
modes = {'SCREENING_ALL_TX', 'NOM_NADIR_KAA1', 'NOM_ZENITH_KAA2'};
cases = MB.listCases();
all = [];
for i = 1:numel(cases)
    for m = 1:numel(modes)
        c = MB.buildCase(cases(i).caseId, struct('patternCache', cache, 'modeId', modes{m}));
        r = RL.build(c, RL.couplingModel());
        if isempty(all); all = r; else; all = [all, r]; end %#ok<AGROW>
        fprintf('%-14s %-18s %3d pairs\n', cases(i).caseId, modes{m}, numel(r));
    end
end
outDir = fullfile(repo, 'docs', 'reports', 'rfc_levels');
if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
RL.writeCsv(all, fullfile(outDir, 'rfc_levels_all.csv'));
fprintf('\nWrote %d rows to %s\n', numel(all), outDir);

% ---- headline table: CASE_SBA1_L1, all-TX stress case, strongest received levels ----
sel = all(strcmp({all.caseId}, 'CASE_SBA1_L1') & strcmp({all.modeId}, 'SCREENING_ALL_TX'));
[~, ord] = sort([sel.receivedLevel_dBm], 'descend');
fprintf('\nCASE_SBA1_L1 / SCREENING_ALL_TX: strongest received levels at the victim antenna port\n');
fprintf('%-20s %-20s %6s %-7s %9s %9s %10s %-22s\n', 'interferer', 'victim', 'd[m]', 'LOS', 'S21[dB]', 'recv[dBm]', 'req.rej[dB]', 'coupling');
for k = ord(1:min(12, numel(ord)))
    x = sel(k);
    fprintf('%-20s %-20s %6.2f %-7s %9.2f %9.2f %10.1f %-22s\n', x.interfererId, x.victimId, x.distance_m, x.los, ...
        x.s21_dB, x.receivedLevel_dBm, x.requiredRejection_dB, x.couplingValidity);
end

% ---- local facets for the L/S installed-pattern model ----
LF = rfscreen.mission.LocalFacetExporter;
model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
locDir = fullfile(repo, 'docs', 'reports', 'installed_local');
if exist(locDir, 'dir') ~= 7; mkdir(locDir); end
exList = {};
for a = {'SBA_NADIR', 'SBA_ZENITH', 'GPSA_1', 'GPSA_2'}
    for R = [0.25 0.35 0.50]
        ex = LF.export(model, a{1}, R);
        exList{end+1} = ex; %#ok<AGROW>
        LF.writeCsv(ex, fullfile(locDir, sprintf('facets_%s_R%03d.csv', a{1}, round(R * 100))));
    end
end
LF.writeSummaryCsv(exList, fullfile(locDir, 'facet_summary.csv'));
fprintf('\nWrote local facets (4 antennas x 3 radii) to %s\n', locDir);
