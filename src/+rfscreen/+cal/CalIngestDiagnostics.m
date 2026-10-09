classdef CalIngestDiagnostics
    %CALINGESTDIAGNOSTICS Per-file observability of the CAL CST ingestion pipeline (main('--cal')).
    %   Reports WHY a file is not used; it never relaxes, repairs or re-interprets a file. Acceptance stays
    %   exactly CstAscii3DImporter + CstSphericalPatternData (the same calls that read() makes).
    %
    %   Stages (failure_stage = first stage that failed; '' when VALID):
    %     file_discovery, filename_classification, frequency_binding, ascii_read, numeric_parsing,
    %     column_extraction, spherical_grid_construction, spherical_grid_validation, pattern_construction,
    %     catalog_binding
    %   Status (inventory 'status'): VALID | UNRECOGNIZED_NAME | WRONG_FOLDER | UNMAPPED_FREQUENCY |
    %     READ_ERROR | PARSE_ERROR | GRID_VALIDATION_ERROR | DUPLICATE_BINDING | PATTERN_CONSTRUCTION_ERROR
    %
    %   Grid statistics are computed from the parsed columns 1..3 BEFORE validation (also from the rows
    %   parsed before a malformed row), on the observed values; nothing is snapped beyond the validator's
    %   1e-6 deg node tolerance. Definitions:
    %     theta/phi step     smallest spacing between unique observed values ("estimated")
    %     expected_samples   n_theta_lattice x n_phi_lattice over the observed min..max at that step
    %     expected_full_sphere_samples  (180/dtheta + 1) x (360/dphi) - what the validator requires
    %     actual_samples     distinct finite (theta, phi) nodes;  duplicate_samples = finite rows - actual
    %     missing_samples    lattice nodes not present (single samples + whole planes)
    %     missing_theta/phi_planes  lattice values with no row at all
    properties (Constant)
        STAGES = {'file_discovery', 'filename_classification', 'frequency_binding', 'ascii_read', ...
            'numeric_parsing', 'column_extraction', 'spherical_grid_construction', 'spherical_grid_validation', ...
            'pattern_construction', 'catalog_binding'}
        CONSTRUCTION_IDS = {'rfscreen:cal:thetaRange', 'rfscreen:cal:phiRange', 'rfscreen:cal:nonUniformStep'}
        ANGLE_TOL = 1e-6        % deg, same node tolerance as CstSphericalPatternData
        STEP_TOL = 1e-4         % relative lattice tolerance, same as CstSphericalPatternData.identifyStep
        MAX_LATTICE = 5e7       % lattice nodes above which the missing-sample map is not built
    end

    methods (Static)
        function d = blank()
            n = NaN;
            d = struct('status', '', 'failure_stage', '', 'last_stage_completed', '', ...
                'error_identifier', '', 'error_message', '', 'line_number', n, ...
                'file_bytes', n, 'preamble_lines', n, 'n_columns', n, 'n_rows', n, ...
                'n_nonfinite_theta', n, 'n_nonfinite_phi', n, 'n_nonfinite_gain', n, 'first_nonfinite_line', n, ...
                'theta_min_deg', n, 'theta_max_deg', n, 'n_theta', n, 'theta_step_deg', n, 'n_theta_off_step', n, ...
                'phi_min_deg', n, 'phi_max_deg', n, 'n_phi', n, 'phi_step_deg', n, 'n_phi_off_step', n, ...
                'phi_convention', '', 'n_phi360_rows', n, 'gain_min_dbi', n, 'gain_max_dbi', n, ...
                'expected_samples', n, 'expected_full_sphere_samples', n, 'actual_samples', n, ...
                'duplicate_samples', n, 'first_duplicate_line', n, 'missing_samples', n, ...
                'missing_theta_planes', n, 'missing_phi_planes', n, 'example_missing_theta_deg', n, ...
                'example_missing_phi_deg', n, 'n_rows_theta0', n, 'n_rows_theta180', n, ...
                'n_phi_at_theta0', n, 'n_phi_at_theta180', n);
        end

        function [p, d] = readFile(filePath)
            %READFILE Stages ascii_read .. spherical_grid_validation without throwing.
            %   p = CstSphericalPatternData or [] ; d = diagnostics struct (status '' = passed these stages).
            D = rfscreen.cal.CalIngestDiagnostics;
            I = rfscreen.cal.CstAscii3DImporter;
            p = []; d = D.blank();
            % ascii_read
            try
                if exist(filePath, 'file') ~= 2
                    error('rfscreen:cal:fileNotFound', 'CST ASCII file not found: %s', filePath);
                end
                L = dir(filePath); d.file_bytes = L(1).bytes;
                txt = fileread(filePath);
            catch err
                d = D.fail(d, 'READ_ERROR', 'ascii_read', err.identifier, err.message, NaN);
                return;
            end
            d.last_stage_completed = 'ascii_read';
            % numeric_parsing (partial rows kept for the statistics)
            [data, info, perr, lineNo] = I.parseTextDiag(txt, filePath);
            d.preamble_lines = info.preambleLines; d.n_columns = info.nColumns; d.n_rows = info.nRows;
            if size(data, 2) >= 3 && size(data, 1) > 0
                d = D.gridStats(d, data(:, 1), data(:, 2), data(:, 3), lineNo);
            end
            if ~isempty(perr)
                d = D.fail(d, 'PARSE_ERROR', 'numeric_parsing', perr.identifier, perr.message, perr.line);
                return;
            end
            d.last_stage_completed = 'numeric_parsing';
            % column_extraction (by position: 1 theta, 2 phi, 3 Realized Gain)
            if size(data, 2) < 3
                d = D.fail(d, 'PARSE_ERROR', 'column_extraction', 'rfscreen:cal:tooFewColumns', ...
                    sprintf('%s: %d numeric columns, theta/phi/gain need >= 3.', filePath, size(data, 2)), NaN);
                return;
            end
            d.last_stage_completed = 'column_extraction';
            % spherical grid construction + validation (the importer's own validator, unchanged)
            info.sourceFile = filePath; info.fileBytes = numel(txt);
            try
                p = rfscreen.cal.CstSphericalPatternData.fromColumns(data(:, 1), data(:, 2), data(:, 3), info, struct());
            catch err
                stage = D.gridStage(err.identifier);
                ln = NaN;
                if strcmp(err.identifier, 'rfscreen:cal:nonFinite'); ln = d.first_nonfinite_line; end
                if strcmp(err.identifier, 'rfscreen:cal:duplicateSample'); ln = d.first_duplicate_line; end
                d = D.fail(d, 'GRID_VALIDATION_ERROR', stage, err.identifier, err.message, ln);
                p = [];
                return;
            end
            d.last_stage_completed = 'spherical_grid_validation';
        end

        function stage = gridStage(identifier)
            if any(strcmp(identifier, rfscreen.cal.CalIngestDiagnostics.CONSTRUCTION_IDS))
                stage = 'spherical_grid_construction';
            else
                stage = 'spherical_grid_validation';
            end
        end

        function d = fail(d, status, stage, identifier, message, line)
            d.status = status; d.failure_stage = stage;
            d.error_identifier = identifier; d.error_message = message; d.line_number = line;
        end

        function d = gridStats(d, theta, phi, gain, lineNo)
            %GRIDSTATS theta/phi/gain/sample statistics of raw parsed columns (never throws).
            D = rfscreen.cal.CalIngestDiagnostics;
            theta = double(theta(:)); phi = double(phi(:)); gain = double(gain(:));
            if nargin < 5 || numel(lineNo) ~= numel(theta); lineNo = (1:numel(theta)).'; end
            lineNo = lineNo(:);
            ft = isfinite(theta); fp = isfinite(phi); fg = isfinite(gain);
            d.n_nonfinite_theta = nnz(~ft); d.n_nonfinite_phi = nnz(~fp); d.n_nonfinite_gain = nnz(~fg);
            k = find(~(ft & fp & fg), 1);
            if ~isempty(k); d.first_nonfinite_line = lineNo(k); end
            if any(fg); d.gain_min_dbi = min(gain(fg)); d.gain_max_dbi = max(gain(fg)); end
            ok = ft & fp;
            if ~any(ok); return; end
            q = @(x) round(x / D.ANGLE_TOL) * D.ANGLE_TOL;
            th = q(theta(ok)); ph = q(phi(ok)); ln = lineNo(ok);
            T = unique(th); P = unique(ph);
            d.theta_min_deg = T(1); d.theta_max_deg = T(end); d.n_theta = numel(T);
            d.phi_min_deg = P(1); d.phi_max_deg = P(end); d.n_phi = numel(P);
            if P(1) < -D.ANGLE_TOL; d.phi_convention = '-180..180 (negative phi present)'; else; d.phi_convention = '0..360'; end
            d.n_phi360_rows = nnz(abs(ph - 360) <= D.ANGLE_TOL);
            [d.theta_step_deg, d.n_theta_off_step, nTl] = D.lattice(T);
            [d.phi_step_deg, d.n_phi_off_step, nPl] = D.lattice(P);
            % poles
            n0 = abs(th) <= D.ANGLE_TOL; n180 = abs(th - 180) <= D.ANGLE_TOL;
            d.n_rows_theta0 = nnz(n0); d.n_rows_theta180 = nnz(n180);
            d.n_phi_at_theta0 = numel(unique(ph(n0))); d.n_phi_at_theta180 = numel(unique(ph(n180)));
            % distinct nodes / duplicates
            [u, ~, j] = unique([th ph], 'rows');
            d.actual_samples = size(u, 1);
            d.duplicate_samples = numel(th) - size(u, 1);
            if d.duplicate_samples > 0
                [js, ord] = sort(j);
                rep = ord([false; diff(js) == 0]);
                d.first_duplicate_line = min(ln(rep));
            end
            % full-sphere requirement at the observed steps (what the validator demands)
            if isfinite(d.theta_step_deg) && isfinite(d.phi_step_deg)
                nTf = 180 / d.theta_step_deg; nPf = 360 / d.phi_step_deg;
                if abs(nTf - round(nTf)) < D.STEP_TOL && abs(nPf - round(nPf)) < D.STEP_TOL
                    d.expected_full_sphere_samples = (round(nTf) + 1) * round(nPf);
                end
            end
            % lattice over the observed range: missing single samples / planes
            if isfinite(nTl) && isfinite(nPl)
                d.expected_samples = nTl * nPl;
                it = (u(:, 1) - T(1)) / d.theta_step_deg; ip = (u(:, 2) - P(1)) / d.phi_step_deg;
                on = abs(it - round(it)) < D.STEP_TOL & abs(ip - round(ip)) < D.STEP_TOL;
                it = round(it(on)) + 1; ip = round(ip(on)) + 1;
                d.missing_samples = d.expected_samples - numel(it);
                hasT = false(nTl, 1); hasT(it) = true; hasP = false(nPl, 1); hasP(ip) = true;
                d.missing_theta_planes = nnz(~hasT); d.missing_phi_planes = nnz(~hasP);
                if d.missing_samples > 0 && d.expected_samples <= D.MAX_LATTICE
                    have = false(nTl, nPl); have(sub2ind([nTl nPl], it, ip)) = true;
                    [mi, mj] = find(~have, 1);
                    d.example_missing_theta_deg = T(1) + (mi - 1) * d.theta_step_deg;
                    d.example_missing_phi_deg = P(1) + (mj - 1) * d.phi_step_deg;
                end
            end
        end

        function [step, nOff, nLattice] = lattice(U)
            D = rfscreen.cal.CalIngestDiagnostics;
            step = NaN; nOff = NaN; nLattice = NaN;
            if numel(U) < 2; nOff = 0; nLattice = numel(U); return; end
            step = min(diff(U));
            m = (U - U(1)) / step;
            nOff = nnz(abs(m - round(m)) > D.STEP_TOL);
            nLattice = round((U(end) - U(1)) / step) + 1;
        end

        function L = consoleLines(e)
            %CONSOLELINES Human-readable block of one catalog entry (main('--cal') console / run summary).
            d = e.diag;
            f = @rfscreen.cal.CalIngestDiagnostics.fmt;
            L = {sprintf('[CAL] %s', e.relPath)};
            L{end+1} = sprintf('      status: %s', e.status);
            if ~strcmp(e.status, 'VALID')
                L{end+1} = sprintf('      stage : %s', d.failure_stage);
            end
            inst = e.installationId; if isempty(inst); inst = '-'; end
            L{end+1} = sprintf('      family: %s   installation: %s   pattern type: %s   source frame: %s', ...
                f(e.family), inst, f(e.patternType), f(e.sourceFrame));
            L{end+1} = sprintf('      filename frequency token: f%s', f(e.token));
            if ~isempty(e.freqs_Hz)
                mhz = strjoin(arrayfun(@(x) sprintf('%.2f', x / 1e6), e.freqs_Hz, 'UniformOutput', false), ' / ');
                if strcmp(e.frequencyTreatment, 'SURROGATE')
                    L{end+1} = sprintf('      source simulation frequency: %s GHz (one CST solve)', f(e.sourceSimulationFrequency_Hz / 1e9));
                    L{end+1} = sprintf('      bound as surrogate for: %s (%s MHz)', strjoin(e.freqLabels, ' / '), mhz);
                else
                    L{end+1} = sprintf('      bound evaluation frequency: %s (%s MHz, native CST plane)', strjoin(e.freqLabels, ' / '), mhz);
                end
            end
            if isfinite(d.file_bytes)
                L{end+1} = sprintf('      file  : %d bytes, preamble lines %s', d.file_bytes, f(d.preamble_lines));
            end
            if isfinite(d.n_rows)
                L{end+1} = sprintf('      rows  : %s   cols : %s', f(d.n_rows), f(d.n_columns));
            end
            if isfinite(d.n_theta)
                L{end+1} = sprintf('      theta : %s .. %s deg, unique=%s, step=%s (off-step values %s)', f(d.theta_min_deg), ...
                    f(d.theta_max_deg), f(d.n_theta), f(d.theta_step_deg), f(d.n_theta_off_step));
                L{end+1} = sprintf('      phi   : %s .. %s deg, unique=%s, step=%s (convention %s, phi=360 rows %s, off-step values %s)', ...
                    f(d.phi_min_deg), f(d.phi_max_deg), f(d.n_phi), f(d.phi_step_deg), d.phi_convention, f(d.n_phi360_rows), ...
                    f(d.n_phi_off_step));
                L{end+1} = sprintf('      gain  : %s .. %s dBi   non-finite theta/phi/gain rows: %s/%s/%s', f(d.gain_min_dbi), ...
                    f(d.gain_max_dbi), f(d.n_nonfinite_theta), f(d.n_nonfinite_phi), f(d.n_nonfinite_gain));
                L{end+1} = sprintf('      poles : theta=0 rows %s (unique phi %s), theta=180 rows %s (unique phi %s)', ...
                    f(d.n_rows_theta0), f(d.n_phi_at_theta0), f(d.n_rows_theta180), f(d.n_phi_at_theta180));
                L{end+1} = sprintf('      expected samples: %s (observed range lattice); full sphere at these steps: %s', ...
                    f(d.expected_samples), f(d.expected_full_sphere_samples));
                L{end+1} = sprintf('      actual samples  : %s   duplicate samples: %s', f(d.actual_samples), f(d.duplicate_samples));
                ms = sprintf('      missing samples : %s (missing theta planes %s, phi planes %s)', f(d.missing_samples), ...
                    f(d.missing_theta_planes), f(d.missing_phi_planes));
                if isfinite(d.example_missing_theta_deg)
                    ms = sprintf('%s, e.g. theta %s phi %s', ms, f(d.example_missing_theta_deg), f(d.example_missing_phi_deg));
                end
                L{end+1} = ms;
            end
            if ~strcmp(e.status, 'VALID')
                if ~isempty(d.error_identifier); L{end+1} = sprintf('      error id: %s', d.error_identifier); end
                L{end+1} = sprintf('      message : %s', d.error_message);
                if isfinite(d.line_number); L{end+1} = sprintf('      line    : %d', d.line_number); end
            elseif ~isempty(e.message)
                L{end+1} = sprintf('      note  : %s', e.message);
            end
        end

        function s = fmt(x)
            if ischar(x); s = x; if isempty(s); s = '-'; end; return; end
            if isempty(x) || ~isfinite(x); s = '-'; return; end
            s = sprintf('%.6g', x);
        end

        function writeJson(path, E, discovery)
            %WRITEJSON validation/pattern_diagnostics.json: full per-file diagnostics (no truncation).
            items = cell(1, numel(E));
            for a = 1:numel(E)
                r = struct('rel_path', E(a).relPath, 'family', E(a).family, 'installation_id', E(a).installationId, ...
                    'pattern_type', E(a).patternType, 'source_frame', E(a).sourceFrame, 'filename_frequency_token', E(a).token, ...
                    'source_simulation_frequency_ghz', E(a).sourceSimulationFrequency_Hz / 1e9, ...
                    'evaluation_frequencies_ghz', E(a).freqs_Hz / 1e9, 'evaluation_labels', {E(a).freqLabels}, ...
                    'frequency_treatment', E(a).frequencyTreatment, 'status', E(a).status, 'note', E(a).message);
                fn = fieldnames(E(a).diag);
                for k = 1:numel(fn)
                    if ~strcmp(fn{k}, 'status'); r.(fn{k}) = E(a).diag.(fn{k}); end
                end
                items{a} = r;
            end
            doc = struct('schema', 'rfscreen.cal.pattern_diagnostics/1', 'stages', {rfscreen.cal.CalIngestDiagnostics.STAGES}, ...
                'files', {items}, 'discovery_notes', {discovery});
            txt = rfscreen.cal.CalIngestDiagnostics.toJson(doc, '');
            d = fileparts(path); if exist(d, 'dir') ~= 7; mkdir(d); end
            fid = fopen(path, 'w');
            if fid < 0; error('rfscreen:cal:writeFailed', 'cannot write %s', path); end
            fprintf(fid, '%s\n', txt); fclose(fid);
        end

        function s = toJson(v, ind)
            %TOJSON Minimal portable JSON encoder (struct, cell, char, numeric/logical; NaN/Inf -> null).
            J = @rfscreen.cal.CalIngestDiagnostics.toJson;
            in2 = [ind '  '];
            if ischar(v)
                s = ['"' rfscreen.cal.CalIngestDiagnostics.esc(v) '"'];
            elseif iscell(v)
                if isempty(v); s = '[]'; return; end
                parts = cellfun(@(x) [in2 J(x, in2)], v(:).', 'UniformOutput', false);
                s = sprintf('[\n%s\n%s]', strjoin(parts, sprintf(',\n')), ind);
            elseif isstruct(v)
                if numel(v) ~= 1; s = J(num2cell(v), ind); return; end
                fn = fieldnames(v);
                parts = cellfun(@(k) sprintf('%s"%s": %s', in2, k, J(v.(k), in2)), fn(:).', 'UniformOutput', false);
                s = sprintf('{\n%s\n%s}', strjoin(parts, sprintf(',\n')), ind);
            elseif isnumeric(v) || islogical(v)
                v = double(v);
                if isscalar(v)
                    if isfinite(v); s = sprintf('%.12g', v); else; s = 'null'; end
                else
                    p = arrayfun(@(x) J(x, ''), v(:).', 'UniformOutput', false);
                    s = ['[' strjoin(p, ', ') ']'];
                end
            else
                s = 'null';
            end
        end

        function s = esc(s)
            s = strrep(s, '\', '\\'); s = strrep(s, '"', '\"');
            s = strrep(s, sprintf('\n'), '\n'); s = strrep(s, sprintf('\r'), '\r'); s = strrep(s, sprintf('\t'), '\t');
        end
    end
end
