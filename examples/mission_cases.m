%MISSION_CASES Build and screen the six RFC/RFI analysis cases of the simplified spacecraft.
%   Cases: SBA variant {SBA1, SBA4} x GPS band {L1, L2(1207 MHz proxy), L5}; ISL (CST
%   ISL_C4_CUP_R14P7, 10.4 GHz) and KAA (Ka-band DLS, candidate binding) are the same in every
%   case; SAR_ANT is geometry-only here (RF analysis later in the closed network).
%   Output per case: pattern binding + structure-FOV lobe occupancy of each RF function
%   (geometry + pattern evidence only; no gain loss / S21 / attenuation value is produced).
%   Pairwise RF screening needs TX power / bandwidth / receiver data, which are not in the
%   dataset: register RFTransmitter / RFReceiver objects on c.scenario to run it.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(here), 'src'));
MB = rfscreen.mission.MissionCaseBuilder;

opts = struct('patternCache', containers.Map('KeyType', 'char', 'ValueType', 'any'));  % 2 deg grid
cases = MB.listCases();
for i = 1:numel(cases)
    c = MB.buildCase(cases(i).caseId, opts);
    fprintf('\n=== %s  (SBA %s, GPS %s) ===\n', c.caseId, c.sbaVariant, c.gpsBand);
    rows = MB.structureFov(c);
    for k = 1:numel(c.functions)
        f = c.functions(k);
        if ~f.included
            fprintf('  %-14s %-24s (%s)\n', f.functionId, '-', f.bindingStatus);
            continue;
        end
        r = rows(strcmp({rows.functionId}, f.functionId));
        nMain = sum(cellfun(@(x) any(strcmp(x, 'MAIN')), {r.occupiedLobes}));
        nSide = sum(cellfun(@(x) any(strcmp(x, 'SIDE')), {r.occupiedLobes}));
        fprintf('  %-14s %-4s %-9s %8.2f GHz  panels in MAIN %d / SIDE %d  (%s)\n', f.functionId, ...
            f.role, f.patternKey, f.frequency_Hz / 1e9, nMain, nSide, f.bindingStatus);
    end
    for w = 1:numel(c.warnings); fprintf('  ! %s\n', c.warnings{w}); end
end
