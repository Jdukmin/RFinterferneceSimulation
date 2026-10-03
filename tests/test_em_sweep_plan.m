function test_em_sweep_plan(h)
%TEST_EM_SWEEP_PLAN Installed-geometry EM sweep plan (P7d-4, VR-450..451). Planning only.
    h.setGroup('em_sweep_plan');
    EP = rfscreen.mission.EmSweepPlan;
    pol = EP.readPolicy();

    % ---- policy ----
    h.eqTol('coarse 1..27 GHz', [pol.coarse_start_ghz pol.coarse_stop_ghz], [1 27], 0);
    h.eqTol('Hex 8 cells/wavelength (CST worker rule)', pol.cells_per_wavelength, 8, 0);
    h.eqTol('Learning Edition 100k cells', pol.max_cells, 1e5, 0);

    % ---- coarse grid ----
    g = EP.coarseGrid_Hz(pol);
    h.eqTol('coarse grid first/last', [g(1) g(end)], [1e9 27e9], 1e-3);
    h.eqTol('coarse grid 261 points at 100 MHz', numel(g), 261, 0);
    h.isTrue('coarse grid strictly increasing', all(diff(g) > 0));

    % ---- cell estimate (analytic) ----
    % 1 m cube at 3 GHz: lambda = c/f, pad = 0.25 lambda, h = lambda/8
    lam = rfscreen.util.Units.wavelength_m(3e9);
    expC = ((1 + 0.5 * lam) / (lam / 8))^3;
    h.eqTol('cells = prod((L+2pad)/(lambda/8))', EP.estimateCells([1;1;1], 3e9, pol), expC, 1e-6 * expC);
    h.isTrue('cells grow with frequency', EP.estimateCells([1;1;1], 6e9, pol) > EP.estimateCells([1;1;1], 3e9, pol));
    h.isTrue('cells grow with size', EP.estimateCells([2;1;1], 3e9, pol) > EP.estimateCells([1;1;1], 3e9, pol));
    fm = EP.maxFeasibleFrequency_Hz([0.05; 0.05; 0.05], pol);
    h.eqTol('tiny region feasible across the whole coarse range', fm, 27e9, 1e-3);
    h.eqTol('huge region infeasible even at 1 GHz', EP.maxFeasibleFrequency_Hz([50; 50; 50], pol), 0, 0);
    ext = [1.2; 0.5; 0.4]; fm = EP.maxFeasibleFrequency_Hz(ext, pol);
    h.isTrue('max feasible freq is a threshold', fm > 0 && fm < 27e9 && ...
        EP.estimateCells(ext, fm, pol) <= pol.max_cells && EP.estimateCells(ext, fm + 100e6, pol) > pol.max_cells);

    % ---- dense bands from the RF baseline ----
    B = EP.bands();
    ids = {B.bandId};
    h.isTrue('one band per RF template', isequal(sort(ids), sort({'S_TM_TX','S_TC_RX','GPS_L1_RX','KA_DLS_TX','ISL_X_TX','ISL_X_RX','SAR_X_TX','SAR_X_RX'})));
    ka = B(strcmp(ids, 'KA_DLS_TX'));
    h.eqTol('Ka dense band 25.50-27.00 GHz', [ka.lo_Hz ka.hi_Hz], [25.5e9 27.0e9], 1);
    h.eqTol('Ka dense step 37.5 MHz', ka.step_Hz, 37.5e6, 1);
    gp = B(strcmp(ids, 'GPS_L1_RX'));
    h.eqTol('GPS L1 dense band fc +/- 10.23 MHz', [gp.lo_Hz gp.hi_Hz], [1575.42e6 - 10.23e6, 1575.42e6 + 10.23e6], 1);
    h.eqTol('dense points per band', gp.nPoints, 41, 0);
    tc = B(strcmp(ids, 'S_TC_RX'));
    h.eqTol('S TC dense band 200 kHz wide', tc.bw_Hz, 0.2e6, 0);
    h.isTrue('SAR bands flagged deferred', B(strcmp(ids, 'SAR_X_TX')).deferred && B(strcmp(ids, 'SAR_X_RX')).deferred);
    h.isFalse('non-SAR bands not deferred', B(strcmp(ids, 'ISL_X_TX')).deferred);

    % ---- the plan ----
    plan = EP.build();
    h.eqTol('8 local models (one per mount)', numel(plan.local), 8, 0);
    h.eqTol('28 pairwise models (8 choose 2)', numel(plan.pairs), 28, 0);
    h.eqTol('feasibility rows = (28 + 8) x 8 bands', numel(plan.feasibility), (28 + 8) * 8, 0);
    h.isFalse('whole vehicle cannot be meshed at 1 GHz', plan.vehicle.maxFeasibleFrequency_Hz > 0);
    h.isTrue('vehicle cells at 27 GHz far above the limit', plan.vehicle.cellsAtCoarseMax > 1e9);

    m = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build();
    pa = m.installations('SBA_NADIR').position_m; pb = m.installations('SBA_ZENITH').position_m;
    pp = plan.pairs(strcmp({plan.pairs.modelId}, 'PAIR_SBA_NADIR__SBA_ZENITH'));
    h.eqTol('pair distance = |pa - pb|', pp.distance_m, norm(pa - pb), 1e-12);
    h.eqTol('pair extents = |dx| + 2 margin', pp.extents_m, abs(pa - pb) + 2 * pol.pair_margin_m, 1e-12);
    h.eqStr('SBA nadir <-> zenith LOS blocked by the hull', pp.losStatus, 'BLOCKED');
    pg = plan.pairs(strcmp({plan.pairs.modelId}, 'PAIR_GPSA_1__GPSA_2'));
    h.eqStr('GPSA_1 <-> GPSA_2 LOS clear', pg.losStatus, 'CLEAR');
    h.eqTol('GPSA pair distance 1.1 m', pg.distance_m, 1.1, 1e-9);
    lm = plan.local(strcmp({plan.local.modelId}, 'LOCAL_KAA_1'));
    h.eqTol('local region = 2 x 0.35 m', lm.extents_m, 0.7 * ones(3, 1), 0);
    h.eqTol('local centre = installation point', lm.center_m, m.installations('KAA_1').position_m, 0);

    % feasibility is consistent with the estimate
    k = find(strcmp({plan.feasibility.modelId}, 'LOCAL_GPSA_1') & strcmp({plan.feasibility.bandId}, 'GPS_L1_RX'), 1);
    f = plan.feasibility(k);
    h.eqTol('feasibility cells = estimate at the upper edge', f.cells, EP.estimateCells(0.7 * ones(3, 1), f.hiEdge_Hz, pol), 1e-9 * f.cells);
    h.eqTol('withinLimit consistent', f.withinLimit, double(f.cells <= pol.max_cells), 0);
    h.isTrue('local GPS L1 region is within the limit', f.withinLimit);
    kk = find(strcmp({plan.feasibility.modelId}, 'LOCAL_KAA_1') & strcmp({plan.feasibility.bandId}, 'KA_DLS_TX'), 1);
    h.isFalse('local Ka region exceeds the limit at 27 GHz', plan.feasibility(kk).withinLimit);
    allOk = true;
    for i = 1:numel(plan.feasibility)
        x = plan.feasibility(i);
        allOk = allOk && (x.withinLimit == (x.cells <= pol.max_cells));
    end
    h.isTrue('every feasibility flag follows the cell limit', allOk);
    pSmall = plan.pairs(strcmp({plan.pairs.modelId}, 'PAIR_GPSA_1__GPSA_2'));    % 1.1 m apart
    pLarge = plan.pairs(strcmp({plan.pairs.modelId}, 'PAIR_SBA_NADIR__ISL'));    % ~6.7 m apart
    h.isTrue('larger pair region -> lower (or equal) max feasible frequency', ...
        prod(pLarge.extents_m) > prod(pSmall.extents_m) && pLarge.maxFeasibleFrequency_Hz <= pSmall.maxFeasibleFrequency_Hz);

    % determinism + export
    plan2 = EP.build();
    h.isTrue('plan is deterministic', isequal(plan.feasibility, plan2.feasibility) && isequal(plan.pairs, plan2.pairs));
    tmp = tempname();
    EP.writeCsv(plan, tmp);
    T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(tmp, 'pair_models.csv'));
    h.eqTol('pair_models.csv rows', T.nRows, 28, 0);
    T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(tmp, 'band_feasibility.csv'));
    h.eqTol('band_feasibility.csv rows', T.nRows, 288, 0);
    T = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(tmp, 'sweep_grids.csv'));
    h.eqTol('sweep_grids.csv rows = coarse + 8 dense', T.nRows, 9, 0);
    delete(fullfile(tmp, '*.csv')); rmdir(tmp);

    % boundary: planning only, no solver, no coupling value
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    txt = fileread(fullfile(repoRoot, 'src', '+rfscreen', '+mission', 'EmSweepPlan.m'));
    h.isTrue('no solver call in the plan', isempty(strfind(txt, 'actxserver')) && isempty(strfind(txt, 'system(')));
    h.isTrue('no coupling model in the plan', isempty(strfind(txt, 'CstCouplingModel(')) && isempty(strfind(txt, 'CstS21Table(')));
end
