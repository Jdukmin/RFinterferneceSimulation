%EM_SWEEP_PLAN Generate the installed-geometry EM sweep plan (planning only; no solver is run).
%   Writes docs/reports/em_sweep/{sweep_grids,local_models,pair_models,band_feasibility}.csv
%   and prints a summary. Inputs: data/spacecraft/simplified_spacecraft_v1/{rf_systems,
%   em_sweep_policy}.csv and the antenna installation points.
here = fileparts(mfilename('fullpath'));
repo = fileparts(here);
addpath(fullfile(repo, 'src'));
EP = rfscreen.mission.EmSweepPlan;
plan = EP.build();
outDir = fullfile(repo, 'docs', 'reports', 'em_sweep');
EP.writeCsv(plan, outDir);

pol = plan.policy;
fprintf('Coarse grid: %.0f-%.0f GHz every %.0f MHz (%d points)\n', plan.coarseGrid_Hz(1)/1e9, ...
    plan.coarseGrid_Hz(end)/1e9, pol.coarse_step_mhz, numel(plan.coarseGrid_Hz));
fprintf('Dense bands (%d points each):\n', pol.dense_points_per_band);
for b = 1:numel(plan.bands)
    x = plan.bands(b);
    fprintf('  %-10s %-2s %9.4f - %9.4f GHz  step %9.4f MHz%s\n', x.bandId, x.kind, x.lo_Hz/1e9, x.hi_Hz/1e9, ...
        x.step_Hz/1e6, repmat(' [deferred: closed network]', 1, x.deferred));
end
v = plan.vehicle;
fprintf('\nWhole vehicle %.2f x %.2f x %.2f m: lower-bound cells %.3g at 1 GHz, %.3g at 27 GHz (limit %d) -> max feasible %.3f GHz\n', ...
    v.extents_m, v.cellsAtCoarseMin, v.cellsAtCoarseMax, pol.max_cells, v.maxFeasibleFrequency_Hz/1e9);

fprintf('\nLocal models (%.2f m box): max feasible frequency [GHz]\n', 2*pol.local_radius_m);
for l = 1:numel(plan.local)
    fprintf('  %-16s %7.3f\n', plan.local(l).modelId, plan.local(l).maxFeasibleFrequency_Hz/1e9);
end
mf = [plan.pairs.maxFeasibleFrequency_Hz] / 1e9;
fprintf('\nPairwise models: %d, max feasible frequency [GHz]: min %.3f  median %.3f  max %.3f; %d of %d pairs have none (>= 1 GHz)\n', ...
    numel(plan.pairs), min(mf), median(mf), max(mf), sum(mf == 0), numel(mf));
fprintf('  %-34s %8s %-8s %s\n', 'pair', 'dist [m]', 'LOS', 'max feasible [GHz]');
[~, ord] = sort(mf, 'descend');
for k = ord(1:min(10, numel(ord)))
    x = plan.pairs(k);
    fprintf('  %-34s %8.3f %-8s %7.3f\n', x.modelId, x.distance_m, x.losStatus, x.maxFeasibleFrequency_Hz/1e9);
end

fprintf('\nPair x dense-band feasibility (cells at the band upper edge <= %d): %d of %d within limit (non-deferred)\n', ...
    pol.max_cells, sum([plan.feasibility.withinLimit] & ~[plan.feasibility.deferred]), sum(~[plan.feasibility.deferred]));
fprintf('Wrote CSVs to %s\n', outDir);
