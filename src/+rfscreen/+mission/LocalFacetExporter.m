classdef LocalFacetExporter
    %LOCALFACETEXPORTER Cropped actual spacecraft facets around ONE antenna, in the antenna-local CST frame.
    %   Input for a local installed-pattern EM model (NOT the whole 6 m bus): the SSOT panels
    %   (side panels #1-#6, end caps #7/#8 incl. the rear panel #8) are clipped to a box of half-size R
    %   around the unchanged installation reference point. Pure geometry; no EM value.
    %
    %   Local frame (CST local-scattering convention used by the CST workspace):
    %       +X_L = +X_B (spacecraft forward),  +Z_L = antenna boresight (panel outward normal),
    %       +Y_L = +Z_L x +X_L,   origin = installation reference point.   v_L = R_BL' * (v_B - p_B)
    %   (This differs from the repository antenna frame, where +X_A is boresight; R_BA is unchanged.)
    %   Distances are reported separately (owner requirement): supporting-plane distance of the
    %   assigned panel vs minimum distance to the FINITE facet and to its edges.
    methods (Static)
        function ex = export(model, antennaId, radius_m)
            V = rfscreen.util.Validate;
            R = V.positiveScalar(radius_m, 'radius_m');
            if ~model.installations.isKey(antennaId)
                error('rfscreen:mission:badRef', 'unknown antenna %s.', antennaId);
            end
            inst = model.installations(antennaId);
            rec = model.installationRecords(strcmp({model.installationRecords.antennaId}, antennaId));
            pnl = model.panels(strcmp({model.panels.id}, rec.panelId));
            p = inst.position_m;
            zL = pnl.normal_B; xL = [1; 0; 0];
            if abs(dot(zL, xL)) > 1e-9
                error('rfscreen:mission:badFrame', '%s: boresight is not perpendicular to +X_B.', antennaId);
            end
            yL = cross(zL, xL);
            R_BL = [xL, yL, zL];
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BL, 'R_BL');
            lo = -R * ones(3, 1); hi = R * ones(3, 1);
            facets = struct('structureId', {}, 'panelKind', {}, 'isAssignedPanel', {}, 'verticesLocal_m', {}, ...
                'croppedArea_m2', {}, 'fullArea_m2', {}, 'isCropped', {}, 'outwardNormalLocal', {}, ...
                'supportPlaneSignedDistance_m', {}, 'minDistanceToFacet_m', {}, 'minDistanceToEdge_m', {});
            LF = rfscreen.mission.LocalFacetExporter;
            for i = 1:numel(model.structures)
                st = model.structures{i};
                pi_ = find(strcmp({model.panels.id}, st.id));
                nB = model.panels(pi_).normal_B;
                vB = st.verticesBody();
                vL = R_BL.' * (vB - repmat(p, 1, size(vB, 2)));
                nL = R_BL.' * nB;
                full = LF.polygonArea(vL);
                % signed distance of the antenna (local origin) from the supporting plane; > 0 = outside
                sgn = -(nL.' * vL(:, 1));
                dFacet = LF.pointPolygonDistance(vL, nL);
                dEdge = LF.pointEdgeDistance(vL);
                c = LF.clipToBox(vL, lo, hi);
                if isempty(c); continue; end
                a = LF.polygonArea(c);
                facets(end+1) = struct('structureId', st.id, 'panelKind', model.panels(pi_).kind, ...
                    'isAssignedPanel', strcmp(st.id, rec.panelId), 'verticesLocal_m', c, ...
                    'croppedArea_m2', a, 'fullArea_m2', full, 'isCropped', a < full * (1 - 1e-9), ...
                    'outwardNormalLocal', nL, 'supportPlaneSignedDistance_m', sgn, ...
                    'minDistanceToFacet_m', dFacet, 'minDistanceToEdge_m', dEdge); %#ok<AGROW>
            end
            ex = struct('antennaId', antennaId, 'assignedPanel', rec.panelId, 'position_B_m', p, 'R_BL', R_BL, ...
                'R_BA_repo', inst.R_BA, 'radius_m', R, 'box_local_m', [lo hi], 'facets', facets, ...
                'note', ['antenna reference point NOT snapped to the hull; +Z_L = boresight; ' ...
                         'no brackets/cables/radomes are modelled']);
        end

        function writeCsv(ex, filePath)
            fid = fopen(filePath, 'w');
            fprintf(fid, '# local facets of %s (panel %s), half-size %.3f m, antenna-local CST frame (+X_L=+X_B, +Z_L=boresight)\n', ...
                ex.antennaId, ex.assignedPanel, ex.radius_m);
            fprintf(fid, 'structure_id,vertex_index,x_m,y_m,z_m,cropped,assigned_panel\n');
            for i = 1:numel(ex.facets)
                f = ex.facets(i);
                for k = 1:size(f.verticesLocal_m, 2)
                    fprintf(fid, '%s,%d,%.9f,%.9f,%.9f,%d,%d\n', f.structureId, k, f.verticesLocal_m(:, k), ...
                        f.isCropped, f.isAssignedPanel);
                end
            end
            fclose(fid);
        end

        function writeSummaryCsv(exList, filePath)
            %WRITESUMMARYCSV One row per antenna x radius x facet: areas and the two distances.
            fid = fopen(filePath, 'w');
            fprintf(fid, 'antenna_id,radius_m,structure_id,assigned_panel,cropped,full_area_m2,cropped_area_m2,support_plane_signed_distance_m,min_distance_to_facet_m,min_distance_to_edge_m\n');
            for e = 1:numel(exList)
                ex = exList{e};
                for i = 1:numel(ex.facets)
                    f = ex.facets(i);
                    fprintf(fid, '%s,%.3f,%s,%d,%d,%.6f,%.6f,%.6f,%.6f,%.6f\n', ex.antennaId, ex.radius_m, f.structureId, ...
                        f.isAssignedPanel, f.isCropped, f.fullArea_m2, f.croppedArea_m2, f.supportPlaneSignedDistance_m, ...
                        f.minDistanceToFacet_m, f.minDistanceToEdge_m);
                end
            end
            fclose(fid);
        end

        function c = clipToBox(v, lo, hi)
            %CLIPTOBOX Sutherland-Hodgman clip of a planar CONVEX polygon (3xN) against an axis-aligned box.
            c = v;
            for ax = 1:3
                for sgn = [1 -1]
                    if isempty(c); return; end
                    if sgn > 0; lim = hi(ax); else; lim = lo(ax); end
                    inside = @(q) sgn * (q(ax) - lim) <= 1e-12;
                    out = zeros(3, 0); n = size(c, 2);
                    for i = 1:n
                        a = c(:, i); b = c(:, mod(i, n) + 1);
                        ia = inside(a); ib = inside(b);
                        if ia
                            out(:, end+1) = a; %#ok<AGROW>
                        end
                        if ia ~= ib
                            t = (lim - a(ax)) / (b(ax) - a(ax));
                            out(:, end+1) = a + t * (b - a); %#ok<AGROW>
                        end
                    end
                    c = out;
                    if size(c, 2) < 3; c = zeros(3, 0); end
                end
            end
            if size(c, 2) >= 3 && LocalFacetExporter_area(c) <= 1e-15; c = zeros(3, 0); end
        end

        function a = polygonArea(v)
            %POLYGONAREA Area of a planar 3D polygon (3xN, ordered).
            a = LocalFacetExporter_area(v);
        end

        function d = pointPolygonDistance(v, nUnit)
            %POINTPOLYGONDISTANCE Distance from the origin to the FINITE planar convex polygon.
            n = nUnit / norm(nUnit);
            h = n.' * v(:, 1);                    % plane offset along n
            foot = h * n;                          % origin projected onto the plane
            if rfscreen.mission.LocalFacetExporter.insideConvex(v, n, foot)
                d = abs(h);
            else
                d = sqrt(abs(h)^2 + rfscreen.mission.LocalFacetExporter.pointEdgeDistanceFrom(v, foot)^2);
            end
        end

        function d = pointEdgeDistance(v)
            %POINTEDGEDISTANCE Distance from the origin to the nearest polygon EDGE (segment).
            d = rfscreen.mission.LocalFacetExporter.pointEdgeDistanceFrom(v, [0; 0; 0]);
        end

        function d = pointEdgeDistanceFrom(v, q)
            n = size(v, 2); d = Inf;
            for i = 1:n
                a = v(:, i); b = v(:, mod(i, n) + 1); e = b - a;
                t = max(0, min(1, dot(q - a, e) / dot(e, e)));
                d = min(d, norm(q - (a + t * e)));
            end
        end

        function tf = insideConvex(v, n, q)
            %INSIDECONVEX True if q (in the polygon plane) lies inside / on the convex polygon v.
            m = size(v, 2); s = 0; tf = true;
            for i = 1:m
                a = v(:, i); b = v(:, mod(i, m) + 1);
                c = dot(cross(b - a, q - a), n);
                if abs(c) <= 1e-12; continue; end
                if s == 0; s = sign(c); elseif sign(c) ~= s; tf = false; return; end
            end
        end
    end
end

function a = LocalFacetExporter_area(v)
    a = 0; n = size(v, 2);
    if n < 3; return; end
    s = [0; 0; 0];
    for i = 2:n - 1
        s = s + cross(v(:, i) - v(:, 1), v(:, i + 1) - v(:, 1));
    end
    a = 0.5 * norm(s);
end
