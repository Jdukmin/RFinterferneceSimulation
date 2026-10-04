%MISSION_CASES Build and screen the six RFC/RFI analysis cases of the simplified spacecraft.
%   Cases: SBA variant {SBA1, SBA4} x GPS band {L1, L2(1207 MHz proxy), L5}; ISL (CST
%   CST ISL geometry, 10.6 GHz owner band) and KAA (Ka-band DLS, candidate binding) are the same in every
%   case; SAR_ANT is geometry-only here (RF analysis later in the closed network).
%   Output per case: pattern binding + structure-FOV lobe occupancy of each RF function
%   (geometry + pattern evidence only; no gain loss / S21 / attenuation value is produced),
%   the registered RF baseline (rf_systems.csv), and the coexistence matrix summary from the
%   EXISTING analyzers (pattern-only coupling => relative screening; absolute interference
%   power needs far-field-valid coupling, which needs antenna max dimensions).
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
    fprintf('  RF baseline (allowable interference = kTB + NF + I/N_max):\n');
    for q = 1:numel(c.rfSystems)
        s = c.rfSystems(q);
        if ~s.included
            fprintf('    %-20s not registered (%s)\n', s.systemId, s.bindingStatus);
        elseif strcmp(s.kind, 'TX')
            fprintf('    %-20s TX %8.3f GHz %9.3f MHz %7.2f dBm\n', s.systemId, s.fc_Hz/1e9, s.bw_Hz/1e6, s.power_dBm);
        else
            fprintf('    %-20s RX %8.3f GHz %9.3f MHz  N %7.2f dBm  allowable %7.2f dBm\n', s.systemId, ...
                s.fc_Hz/1e9, s.bw_Hz/1e6, s.noise_dBm, s.allowableInterference_dBm);
        end
    end
    out = rfscreen.interference.RfCoexistenceAnalyzer.analyze(c.scenario);
    nPairs = numel(out.matrix.pairs);
    fprintf('  coexistence matrix: %d TX x %d RX pairs analysed (existing engine)\n', numel(out.txIds), numel(out.rxIds));
    for w = 1:numel(c.warnings); fprintf('  ! %s\n', c.warnings{w}); end
end
