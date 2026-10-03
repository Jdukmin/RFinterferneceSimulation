classdef EmSweepPlan
    %EMSWEEPPLAN Plan of the installed-geometry EM sweep for the simplified spacecraft (P7d-4).
    %   PLANNING ONLY: no solver is run and no coupling value is produced. Output feeds the
    %   CST work that fills coupling.CstS21Table / CstCouplingModel.
    %     * coarse grid 1-27 GHz (owner request) + dense grids across every actual TX/RX band;
    %     * partition of the vehicle into LOCAL (one antenna) and PAIRWISE (two antennas)
    %       regions, because the whole 6 m vehicle cannot be meshed by the CST Learning
    %       Edition (hex-cell limit);
    %     * a LOWER-BOUND cell estimate per region and frequency:
    %         cells >= prod_i (extent_i + 2*pad) / (lambda / cellsPerWavelength) ,  pad = padWl*lambda
    %       so "exceeds the limit" is certain, while "within the limit" is only possible (fine
    %       features such as probe gaps add cells; the accepted ISL model needed ~15x the bound).
    %   Region boxes are axis-aligned boxes around the antenna positions (straight-line
    %   extents), a lower bound for a surface path that wraps the hull.
    methods (Static)
        function pol = readPolicy(datasetDir)
            if nargin < 1 || isempty(datasetDir)
                datasetDir = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
            end
            R = rfscreen.spacecraft.SpacecraftDataReader;
            T = R.readTable(fullfile(datasetDir, 'em_sweep_policy.csv'));
            pol = struct();
            for r = 1:T.nRows
                pol.(T.key{r}) = R.num(T, 'value', r, T.key{r});
            end
            need = {'coarse_start_ghz', 'coarse_stop_ghz', 'coarse_step_mhz', 'dense_points_per_band', ...
                'cells_per_wavelength', 'max_cells', 'boundary_pad_wavelengths', 'pair_margin_m', 'local_radius_m'};
            for k = 1:numel(need)
                if ~isfield(pol, need{k}); error('rfscreen:mission:badPolicy', 'em_sweep_policy.csv missing %s.', need{k}); end
            end
            if pol.coarse_stop_ghz <= pol.coarse_start_ghz || pol.coarse_step_mhz <= 0 || pol.dense_points_per_band < 2
                error('rfscreen:mission:badPolicy', 'invalid sweep policy values.');
            end
        end

        function g = coarseGrid_Hz(pol)
            g = (pol.coarse_start_ghz * 1e9) : (pol.coarse_step_mhz * 1e6) : (pol.coarse_stop_ghz * 1e9 + 1);
            g = g(g <= pol.coarse_stop_ghz * 1e9 * (1 + 1e-12));
        end

        function cells = estimateCells(extents_m, f_Hz, pol)
            %ESTIMATECELLS Lower-bound hex-cell count of a box region at frequency f.
            lambda = rfscreen.util.Units.wavelength_m(f_Hz);
            pad = pol.boundary_pad_wavelengths * lambda;
            h = lambda / pol.cells_per_wavelength;
            cells = prod((extents_m(:) + 2 * pad) / h);
        end

        function fmax = maxFeasibleFrequency_Hz(extents_m, pol)
            %MAXFEASIBLEFREQUENCY_HZ Largest coarse-grid frequency with cells <= max_cells (0 if none).
            %   cells grow monotonically with frequency, so the answer is a threshold.
            g = rfscreen.mission.EmSweepPlan.coarseGrid_Hz(pol);
            ok = false(size(g));
            for i = 1:numel(g)
                ok(i) = rfscreen.mission.EmSweepPlan.estimateCells(extents_m, g(i), pol) <= pol.max_cells;
            end
            if any(ok); fmax = g(find(ok, 1, 'last')); else; fmax = 0; end
        end

        function bands = bands(datasetDir, pol)
            %BANDS Dense-sweep bands: one per distinct RF template band in rf_systems.csv.
            if nargin < 1 || isempty(datasetDir)
                datasetDir = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
            end
            if nargin < 2 || isempty(pol); pol = rfscreen.mission.EmSweepPlan.readPolicy(datasetDir); end
            R = rfscreen.spacecraft.SpacecraftDataReader;
            T = R.readTable(fullfile(datasetDir, 'rf_systems.csv'));
            bands = struct('bandId', {}, 'kind', {}, 'lo_Hz', {}, 'hi_Hz', {}, 'center_Hz', {}, 'bw_Hz', {}, ...
                'step_Hz', {}, 'nPoints', {}, 'deferred', {});
            seen = {};
            for r = 1:T.nRows
                tid = T.template_id{r};
                if any(strcmp(seen, tid)); continue; end
                seen{end+1} = tid; %#ok<AGROW>
                fc = 1e6 * R.num(T, 'fc_mhz', r, tid); bw = 1e6 * R.num(T, 'bw_mhz', r, tid);
                n = pol.dense_points_per_band;
                bands(end+1) = struct('bandId', tid, 'kind', T.kind{r}, 'lo_Hz', fc - bw/2, 'hi_Hz', fc + bw/2, ...
                    'center_Hz', fc, 'bw_Hz', bw, 'step_Hz', bw / (n - 1), 'nPoints', n, ...
                    'deferred', strcmp(T.binding_status{r}, 'DEFERRED_CLOSED_NETWORK')); %#ok<AGROW>
            end
        end

        function plan = build(datasetDir)
            %BUILD Full plan struct: policy, coarse grid, dense bands, local models, pair models,
            %   pair x band feasibility.
            if nargin < 1 || isempty(datasetDir)
                datasetDir = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.defaultDatasetDir();
            end
            EP = rfscreen.mission.EmSweepPlan;
            pol = EP.readPolicy(datasetDir);
            model = rfscreen.spacecraft.SimplifiedSpacecraftBuilder.build(datasetDir);
            bands = EP.bands(datasetDir, pol);
            cg = EP.coarseGrid_Hz(pol);

            recs = model.installationRecords;
            ids = {recs.antennaId};
            structs = model.structures;

            % ---- whole vehicle (shows why partitioning is needed) ----
            allPos = [recs.position_m];
            lo = min([allPos, model.hull.xMin_m * [1;0;0] + [0; min(model.hull.yz_m(1,:)); min(model.hull.yz_m(2,:))]], [], 2);
            hi = max([allPos, model.hull.xMax_m * [1;0;0] + [0; max(model.hull.yz_m(1,:)); max(model.hull.yz_m(2,:))]], [], 2);
            vehExt = hi - lo;
            vehicle = struct('extents_m', vehExt, ...
                'maxFeasibleFrequency_Hz', EP.maxFeasibleFrequency_Hz(vehExt, pol), ...
                'cellsAtCoarseMax', EP.estimateCells(vehExt, cg(end), pol), ...
                'cellsAtCoarseMin', EP.estimateCells(vehExt, cg(1), pol));

            % ---- local models (one per mount) ----
            localExt = 2 * pol.local_radius_m * ones(3, 1);
            local = struct('modelId', {}, 'antennaId', {}, 'panelId', {}, 'center_m', {}, 'extents_m', {}, ...
                'maxFeasibleFrequency_Hz', {}, 'cellsAtCoarseMax', {});
            for i = 1:numel(recs)
                local(end+1) = struct('modelId', ['LOCAL_' recs(i).antennaId], 'antennaId', recs(i).antennaId, ...
                    'panelId', recs(i).panelId, 'center_m', recs(i).position_m, 'extents_m', localExt, ...
                    'maxFeasibleFrequency_Hz', EP.maxFeasibleFrequency_Hz(localExt, pol), ...
                    'cellsAtCoarseMax', EP.estimateCells(localExt, cg(end), pol)); %#ok<AGROW>
            end

            % ---- pairwise models (unordered mount pairs) ----
            pairs = struct('modelId', {}, 'antennaA', {}, 'antennaB', {}, 'distance_m', {}, 'extents_m', {}, ...
                'losStatus', {}, 'blockingPanels', {}, 'maxFeasibleFrequency_Hz', {}, 'cellsAtCoarseMax', {});
            for i = 1:numel(recs)
                for j = i+1:numel(recs)
                    pa = recs(i).position_m; pb = recs(j).position_m;
                    ext = abs(pa - pb) + 2 * pol.pair_margin_m;
                    los = rfscreen.geometry.LineOfSight.segment(recs(i).antennaId, recs(j).antennaId, pa, pb, structs);
                    pairs(end+1) = struct('modelId', ['PAIR_' recs(i).antennaId '__' recs(j).antennaId], ...
                        'antennaA', recs(i).antennaId, 'antennaB', recs(j).antennaId, 'distance_m', norm(pa - pb), ...
                        'extents_m', ext, 'losStatus', los.status, 'blockingPanels', {los.blockingStructureIds}, ...
                        'maxFeasibleFrequency_Hz', EP.maxFeasibleFrequency_Hz(ext, pol), ...
                        'cellsAtCoarseMax', EP.estimateCells(ext, cg(end), pol)); %#ok<AGROW>
                end
            end

            % ---- pair x dense-band feasibility (cells at the band's upper edge) ----
            feas = struct('modelId', {}, 'bandId', {}, 'hiEdge_Hz', {}, 'cells', {}, 'withinLimit', {}, 'deferred', {});
            for p = 1:numel(pairs)
                for b = 1:numel(bands)
                    c = EP.estimateCells(pairs(p).extents_m, bands(b).hi_Hz, pol);
                    feas(end+1) = struct('modelId', pairs(p).modelId, 'bandId', bands(b).bandId, ...
                        'hiEdge_Hz', bands(b).hi_Hz, 'cells', c, 'withinLimit', c <= pol.max_cells, ...
                        'deferred', bands(b).deferred); %#ok<AGROW>
                end
            end
            for l = 1:numel(local)
                for b = 1:numel(bands)
                    c = EP.estimateCells(local(l).extents_m, bands(b).hi_Hz, pol);
                    feas(end+1) = struct('modelId', local(l).modelId, 'bandId', bands(b).bandId, ...
                        'hiEdge_Hz', bands(b).hi_Hz, 'cells', c, 'withinLimit', c <= pol.max_cells, ...
                        'deferred', bands(b).deferred); %#ok<AGROW>
                end
            end

            plan = struct('policy', pol, 'coarseGrid_Hz', cg, 'bands', bands, 'vehicle', vehicle, ...
                'local', local, 'pairs', pairs, 'feasibility', feas);
        end

        function writeCsv(plan, outDir)
            %WRITECSV Deterministic CSV export (grids, local models, pair models, feasibility).
            if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
            pol = plan.policy;
            fid = fopen(fullfile(outDir, 'sweep_grids.csv'), 'w');
            fprintf(fid, '# derived by mission.EmSweepPlan (planning only; no solver run)\n');
            fprintf(fid, 'grid_id,kind,start_ghz,stop_ghz,step_mhz,n_points,deferred\n');
            fprintf(fid, 'COARSE_1_27,COARSE,%.6f,%.6f,%.6f,%d,0\n', plan.coarseGrid_Hz(1)/1e9, plan.coarseGrid_Hz(end)/1e9, ...
                pol.coarse_step_mhz, numel(plan.coarseGrid_Hz));
            for b = 1:numel(plan.bands)
                x = plan.bands(b);
                fprintf(fid, 'DENSE_%s,DENSE_%s,%.9f,%.9f,%.9f,%d,%d\n', x.bandId, x.kind, x.lo_Hz/1e9, x.hi_Hz/1e9, ...
                    x.step_Hz/1e6, x.nPoints, x.deferred);
            end
            fclose(fid);
            fid = fopen(fullfile(outDir, 'local_models.csv'), 'w');
            fprintf(fid, 'model_id,antenna_id,panel_id,center_x_m,center_y_m,center_z_m,extent_m,cells_at_27ghz_lower_bound,max_feasible_ghz\n');
            for l = 1:numel(plan.local)
                x = plan.local(l);
                fprintf(fid, '%s,%s,%s,%.4f,%.4f,%.4f,%.4f,%.0f,%.3f\n', x.modelId, x.antennaId, x.panelId, x.center_m, ...
                    x.extents_m(1), x.cellsAtCoarseMax, x.maxFeasibleFrequency_Hz/1e9);
            end
            fclose(fid);
            fid = fopen(fullfile(outDir, 'pair_models.csv'), 'w');
            fprintf(fid, 'model_id,antenna_a,antenna_b,distance_m,extent_x_m,extent_y_m,extent_z_m,los,blocking_panels,cells_at_27ghz_lower_bound,max_feasible_ghz\n');
            for p = 1:numel(plan.pairs)
                x = plan.pairs(p);
                fprintf(fid, '%s,%s,%s,%.4f,%.4f,%.4f,%.4f,%s,%s,%.0f,%.3f\n', x.modelId, x.antennaA, x.antennaB, x.distance_m, ...
                    x.extents_m, x.losStatus, strjoin(x.blockingPanels, ';'), x.cellsAtCoarseMax, x.maxFeasibleFrequency_Hz/1e9);
            end
            fclose(fid);
            fid = fopen(fullfile(outDir, 'band_feasibility.csv'), 'w');
            fprintf(fid, 'model_id,band_id,band_upper_edge_ghz,cells_lower_bound,within_limit,deferred\n');
            for k = 1:numel(plan.feasibility)
                x = plan.feasibility(k);
                fprintf(fid, '%s,%s,%.6f,%.0f,%d,%d\n', x.modelId, x.bandId, x.hiEdge_Hz/1e9, x.cells, x.withinLimit, x.deferred);
            end
            fclose(fid);
        end
    end
end
