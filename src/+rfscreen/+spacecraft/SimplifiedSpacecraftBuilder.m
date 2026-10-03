classdef SimplifiedSpacecraftBuilder
    %SIMPLIFIEDSPACECRAFTBUILDER Build the simplified spacecraft baseline from its dataset
    %   (ICD mission_spacecraft.md 5-8):
    %     dataset CSVs -> PrismHull -> Panel #1..#8 SpacecraftStructure
    %     -> AntennaInstallation (position as given; R_BA from the assigned panel)
    %     -> GimbalSteeringDomain for GIMBAL antennas -> Scenario registries.
    %   Uses only existing Phase-5 primitives (PanelGeometry for side panels) plus the
    %   exact ConvexPolygonGeometry for the irregular hexagonal end caps.
    %   GEOMETRY EVIDENCE ONLY: no pattern is loaded or synthesised, and no
    %   gain/loss/S21/attenuation/reflection/diffraction value is produced.
    properties (Constant)
        DEFAULT_DATASET = 'simplified_spacecraft_v1'
        NORMAL_CHECK_TOL = 1e-6   % derived vs tabulated canonical normal (rounded to 9 digits)
    end
    methods (Static)
        function d = defaultDatasetDir()
            %DEFAULTDATASETDIR <repo>/data/spacecraft/simplified_spacecraft_v1
            here = fileparts(mfilename('fullpath'));          % src/+rfscreen/+spacecraft
            repo = fileparts(fileparts(fileparts(here)));
            d = fullfile(repo, 'data', 'spacecraft', ...
                rfscreen.spacecraft.SimplifiedSpacecraftBuilder.DEFAULT_DATASET);
        end

        function model = build(datasetDir)
            %BUILD Load + validate the dataset and construct the spacecraft model struct.
            B = rfscreen.spacecraft.SimplifiedSpacecraftBuilder;
            R = rfscreen.spacecraft.SpacecraftDataReader;
            if nargin < 1 || isempty(datasetDir); datasetDir = B.defaultDatasetDir(); end

            % ---- hull (SSOT vertices + extrusion range) ----
            P = B.readParams(fullfile(datasetDir, 'hull_parameters.csv'));
            X = R.readTable(fullfile(datasetDir, 'hull_cross_section.csv'));
            yz = zeros(2, X.nRows);
            for r = 1:X.nRows
                yz(:, r) = R.mmToM([R.num(X, 'y_mm', r, 'y_mm'); R.num(X, 'z_mm', r, 'z_mm')]);
            end
            hull = rfscreen.spacecraft.PrismHull(X.vertex_id, yz, ...
                R.mmToM(B.pnum(P, 'x_min_mm')), R.mmToM(B.pnum(P, 'x_max_mm')));
            if hull.nVertices() ~= 6
                error('rfscreen:spacecraft:badHull', 'cross-section must have exactly 6 vertices (got %d).', hull.nVertices());
            end
            tol_m = R.mmToM(B.pnum(P, 'consistency_tol_mm'));
            geomProv = B.pstr(P, 'geometry_provenance');

            % ---- panels ----
            T = R.readTable(fullfile(datasetDir, 'panels.csv'));
            structures = cell(1, T.nRows);
            panels = struct('id', {}, 'kind', {}, 'sizeClass', {}, 'edgeIndex', {}, ...
                'normal_B', {}, 'center_B', {}, 'supportDistance_m', {}, 'width_m', {});
            longW = []; shortW = []; sideClasses = cell(1, hull.nVertices());
            for r = 1:T.nRows
                pid = T.panel_id{r};
                nTab = [R.num(T, 'n_x', r, [pid ' n_x']); R.num(T, 'n_y', r, [pid ' n_y']); R.num(T, 'n_z', r, [pid ' n_z'])];
                pr = struct('id', pid, 'kind', T.kind{r}, 'sizeClass', T.size_class{r}, ...
                    'edgeIndex', NaN, 'normal_B', [], 'center_B', [], 'supportDistance_m', NaN, 'width_m', NaN);
                switch T.kind{r}
                    case 'SIDE'
                        k = hull.edgeIndex(T.vertex_from{r}, T.vertex_to{r});
                        nB = hull.sideNormal_B(k);
                        B.checkNormal(pid, nB, nTab);
                        w = hull.edgeLengths(); w = w(k);
                        geom = rfscreen.geometry.PanelGeometry(hull.length_m(), w);
                        R_BS = hull.sideR_BS(k);
                        origin = hull.sideCenter_B(k);
                        pr.edgeIndex = k; pr.supportDistance_m = hull.supportDistance(k); pr.width_m = w;
                        sideClasses{k} = T.size_class{r};
                        if strcmp(T.size_class{r}, 'LONG'); longW(end+1) = w; else; shortW(end+1) = w; end %#ok<AGROW>
                    case 'END_CAP'
                        nB = nTab / norm(nTab);
                        if abs(abs(nB(1)) - 1) > B.NORMAL_CHECK_TOL
                            error('rfscreen:spacecraft:badPanel', '%s: end-cap normal must be +-X_B.', pid);
                        end
                        nB = [sign(nB(1)); 0; 0];
                        xFace = R.mmToM(B.pnum(P, T.face_x_ref{r}));
                        if (nB(1) > 0) ~= (abs(xFace - hull.xMax_m) < tol_m)
                            error('rfscreen:spacecraft:badPanel', '%s: normal does not face outward from x=%g.', pid, xFace);
                        end
                        zS = nB; xS = [0; 1; 0]; yS = cross(zS, xS);
                        R_BS = [xS, yS, zS];
                        origin = [xFace; 0; 0];
                        v3 = R_BS.' * ([repmat(xFace, 1, hull.nVertices()); hull.yz_m] - repmat(origin, 1, hull.nVertices()));
                        geom = rfscreen.geometry.ConvexPolygonGeometry(v3(1:2, :));   % exact 6 vertices
                        pr.supportDistance_m = abs(xFace);
                    otherwise
                        error('rfscreen:spacecraft:badPanel', '%s: unknown panel kind "%s".', pid, T.kind{r});
                end
                pr.normal_B = nB; pr.center_B = origin;
                panels(end+1) = pr; %#ok<AGROW>
                structures{r} = rfscreen.geometry.SpacecraftStructure(pid, pid, ...
                    rfscreen.geometry.StructureType.PANEL, geom, R_BS, origin, ...
                    struct('provenance', geomProv));
            end
            B.checkHullDesign(hull, P, sideClasses, longW, shortW, tol_m);

            % ---- antenna installations (positions as given; never snapped) ----
            A = R.readTable(fullfile(datasetDir, 'antenna_installations.csv'));
            S = R.readTable(fullfile(datasetDir, 'steering_constraints.csv'));
            installations = containers.Map('KeyType', 'char', 'ValueType', 'any');
            steering = containers.Map('KeyType', 'char', 'ValueType', 'any');
            records = struct('antennaId', {}, 'position_mm', {}, 'position_m', {}, 'panelId', {}, ...
                'mountType', {}, 'assignmentProvenance', {}, 'nominalBoresight_B', {}, ...
                'panelNormalOffset_m', {}, 'hullSignedDistance_m', {}, ...
                'patternStatus', {}, 'patternDataset', {}, 'note', {});
            for r = 1:A.nRows
                aid = A.antenna_id{r};
                if installations.isKey(aid)
                    error('rfscreen:spacecraft:duplicateId', 'duplicate antenna id %s.', aid);
                end
                pmm = [R.num(A, 'x_mm', r, [aid ' x_mm']); R.num(A, 'y_mm', r, [aid ' y_mm']); R.num(A, 'z_mm', r, [aid ' z_mm'])];
                pos = R.mmToM(pmm);
                ip = find(strcmp({panels.id}, A.panel_id{r}));
                if isempty(ip)
                    error('rfscreen:spacecraft:badRef', '%s references unknown panel %s.', aid, A.panel_id{r});
                end
                pnl = panels(ip);
                R_BA = B.sideMountR_BA(pnl.normal_B);
                installations(aid) = rfscreen.antenna.AntennaInstallation(aid, pos, R_BA);
                if strcmp(pnl.kind, 'SIDE'); off = hull.sideOffset(pos, pnl.edgeIndex);
                elseif pnl.normal_B(1) > 0;  off = hull.endOffset(pos, 'MAX');
                else;                        off = hull.endOffset(pos, 'MIN'); end
                mount = rfscreen.util.Validate.member(A.mount_type{r}, {'FIXED', 'GIMBAL'}, [aid ' mount_type']);
                rec = struct('antennaId', aid, 'position_mm', pmm, 'position_m', pos, ...
                    'panelId', pnl.id, 'mountType', mount, ...
                    'assignmentProvenance', A.assignment_provenance{r}, ...
                    'nominalBoresight_B', pnl.normal_B, 'panelNormalOffset_m', off, ...
                    'hullSignedDistance_m', hull.hullSignedDistance(pos), ...
                    'patternStatus', rfscreen.util.Validate.member(A.pattern_status{r}, ...
                        {'CASE_DEPENDENT', 'BOUND', 'CANDIDATE_DATASET', 'DEFERRED_CLOSED_NETWORK', ...
                         'PENDING', 'UNSUPPORTED'}, [aid ' pattern_status']), ...
                    'patternDataset', A.pattern_dataset{r}, 'note', A.note{r});
                if strcmp(mount, 'GIMBAL')
                    si = find(strcmp(S.antenna_id, aid));
                    if numel(si) ~= 1
                        error('rfscreen:spacecraft:missingSteering', 'GIMBAL antenna %s needs exactly one steering row.', aid);
                    end
                    if ~strcmp(S.reference_axis{si}, 'PANEL_OUTWARD_NORMAL')
                        error('rfscreen:spacecraft:badSteering', '%s: unsupported reference_axis %s.', aid, S.reference_axis{si});
                    end
                    steering(aid) = rfscreen.spacecraft.GimbalSteeringDomain(aid, pnl.normal_B, ...
                        S.steering_model{si}, R.num(S, 'max_off_axis_deg', si, [aid ' max_off_axis_deg']), ...
                        S.provenance{si});
                    rec.nominalBoresight_B = [];   % steered: no single fixed boresight
                end
                records(end+1) = rec; %#ok<AGROW>
            end
            for r = 1:S.nRows
                if ~steering.isKey(S.antenna_id{r})
                    error('rfscreen:spacecraft:badRef', 'steering row %s has no GIMBAL installation.', S.antenna_id{r});
                end
            end

            model = struct();
            [~, model.name] = fileparts(datasetDir);
            model.datasetDir = datasetDir;
            model.hull = hull;
            model.panels = panels;
            model.structures = structures;
            model.installations = installations;
            model.installationRecords = records;
            model.steering = steering;
            model.geometryProvenance = geomProv;
            model.parameters = P;
        end

        function R_BA = sideMountR_BA(n_B)
            %SIDEMOUNTR_BA Reference antenna orientation on a panel with outward normal n_B:
            %   x_A = n_B (boresight), z_A = +X_B (or +Z_B if n_B is along X_B),
            %   y_A = z_A x x_A.  R_BA = [x_A, y_A, z_A] (proper DCM).
            x = rfscreen.util.Validate.vector3(n_B, 'n_B'); x = x / norm(x);
            z = [1; 0; 0] - x(1) * x;
            if norm(z) < 1e-9; z = [0; 0; 1] - x(3) * x; end
            z = z / norm(z);
            R_BA = [x, cross(z, x), z];
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA, 'sideMountR_BA');
        end

        function attachToScenario(scenario, model)
            %ATTACHTOSCENARIO Register panels (structures) and reference installations.
            %   Antennas/patterns/RF systems are added by the caller; GIMBAL antennas are
            %   registered at their gimbal reference orientation (sweep via model.steering).
            for i = 1:numel(model.structures)
                scenario.addStructure(model.structures{i});
            end
            ids = model.installations.keys();
            for i = 1:numel(ids)
                scenario.addInstallation(model.installations(ids{i}));
            end
        end
    end

    methods (Static, Access = private)
        function P = readParams(filePath)
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(filePath);
            P = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for r = 1:T.nRows; P(T.key{r}) = T.value{r}; end
        end
        function v = pnum(P, key)
            if ~P.isKey(key)
                error('rfscreen:spacecraft:missingParam', 'hull parameter %s missing.', key);
            end
            v = str2double(P(key));
            if ~isfinite(v)
                error('rfscreen:spacecraft:badNumber', 'hull parameter %s is not numeric.', key);
            end
        end
        function s = pstr(P, key)
            if ~P.isKey(key)
                error('rfscreen:spacecraft:missingParam', 'hull parameter %s missing.', key);
            end
            s = P(key);
        end
        function checkNormal(pid, nDerived, nTab)
            if abs(norm(nTab) - 1) > rfscreen.spacecraft.SimplifiedSpacecraftBuilder.NORMAL_CHECK_TOL ...
                    || norm(nDerived - nTab) > rfscreen.spacecraft.SimplifiedSpacecraftBuilder.NORMAL_CHECK_TOL
                error('rfscreen:spacecraft:normalMismatch', ...
                    '%s: vertex-derived normal [%g %g %g] != tabulated [%g %g %g].', pid, nDerived, nTab);
            end
        end
        function checkHullDesign(hull, P, sideClasses, longW, shortW, tol_m)
            %CHECKHULLDESIGN Cross-check SSOT vertices against the stated design parameters.
            B = rfscreen.spacecraft.SimplifiedSpacecraftBuilder;
            dLong = rfscreen.spacecraft.SpacecraftDataReader.mmToM(B.pnum(P, 'd_long_mm'));
            dShort = rfscreen.spacecraft.SpacecraftDataReader.mmToM(B.pnum(P, 'd_short_mm'));
            if any(cellfun(@isempty, sideClasses)) || numel(longW) ~= 3 || numel(shortW) ~= 3
                error('rfscreen:spacecraft:badHull', 'every hull edge must be exactly one SIDE panel (3 LONG + 3 SHORT).');
            end
            for k = 1:numel(sideClasses)    % strict LONG-SHORT alternation around the section
                if strcmp(sideClasses{k}, sideClasses{mod(k, numel(sideClasses)) + 1})
                    error('rfscreen:spacecraft:badHull', 'side panels must alternate LONG/SHORT.');
                end
            end
            for k = 1:hull.nVertices()
                if strcmp(sideClasses{k}, 'LONG'); d = dLong; else; d = dShort; end
                if abs(hull.supportDistance(k) - d) > tol_m
                    error('rfscreen:spacecraft:designMismatch', ...
                        'edge %d support distance %.9g m != design %.9g m.', k, hull.supportDistance(k), d);
                end
            end
            if max(longW) - min(longW) > tol_m || max(shortW) - min(shortW) > tol_m
                error('rfscreen:spacecraft:designMismatch', 'LONG (or SHORT) panel widths differ.');
            end
            ratio = mean(longW) / mean(shortW);
            if abs(ratio - B.pnum(P, 'nominal_long_short_ratio')) > 1e-6
                error('rfscreen:spacecraft:designMismatch', 'Long/Short ratio %.9g != nominal.', ratio);
            end
        end
    end
end
