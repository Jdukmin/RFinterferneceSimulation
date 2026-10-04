classdef KaVictimResponse
    %KAVICTIMRESPONSE Victim antenna receiving response at the Ka fundamental (25.5-27 GHz).
    %   For the KA_FUNDAMENTAL_OOB_BLOCKING path the victim gain MUST be the out-of-band response of
    %   the victim antenna at the KAA frequencies. The victim's own operating-band (in-band) gain is
    %   refused (error rfscreen:kaa:inBandGainForbidden) and a missing response is never replaced by
    %   an isotropic 0 dBi or an assumed rejection (status INPUT_MISSING, gain evaluation refused).
    %
    %   Source: data/antenna_port_response_cst/provenance.json (CST fixed-geometry free-space port
    %   response, RealizedGain, two independent 1-degree cuts in the CST local frame) and the CST case
    %   status.json under cst/results/rfc_frequency_cases/ (MESH_LIMIT evidence).
    properties (Constant)
        KA_BAND_HZ = [25.5e9 27.0e9]
        FAMILIES = {'S', 'L', 'ISL', 'SAR'}
    end
    properties (SetAccess = private)
        family          % S | L | ISL | SAR
        band            % evaluation band key of the cuts (must be KA for the fundamental path)
        status          % AVAILABLE | INPUT_MISSING
        reason
        evidence        % file(s) backing the status
        cstCase
        quantity = 'RealizedGain'
        freqs_Hz = []
        xz = {}
        yz = {}
        files = {}
    end
    methods (Static)
        function r = fromRepository(repoRoot, family)
            %FROMREPOSITORY Ka-band response of a victim antenna family (no substitution).
            V = rfscreen.kaa.KaVictimResponse;
            family = rfscreen.util.Validate.member(family, V.FAMILIES, 'family');
            r = rfscreen.kaa.KaVictimResponse();
            r.family = family; r.band = 'KA';
            if strcmp(family, 'SAR')
                r.status = 'INPUT_MISSING';
                r.reason = ['NO_PATTERN_BOUND: no SAR antenna response at any frequency (SAR_ANT pattern_status ' ...
                    'DEFERRED_CLOSED_NETWORK); no CST case exists for SAR at 25.5-27 GHz'];
                r.evidence = 'data/spacecraft/simplified_spacecraft_v1/antenna_installations.csv; data/antenna_port_response_cst/provenance.json (no SAR family)';
                r.cstCase = '';
                return;
            end
            provPath = fullfile(repoRoot, 'data', 'antenna_port_response_cst', 'provenance.json');
            P = jsondecode(fileread(provPath));
            cuts = P.cuts; if iscell(cuts); cuts = [cuts{:}]; end
            sel = strcmp({cuts.family}, family) & strcmp({cuts.band}, 'KA') & strcmp({cuts.quantity}, 'RealizedGain');
            c = cuts(sel);
            caseName = sprintf('RFC_%s_KA_FREE', family);
            stPath = fullfile('cst', 'results', 'rfc_frequency_cases', caseName, 'status.json');
            r.cstCase = caseName;
            if isempty(c)
                r.status = 'INPUT_MISSING';
                r.reason = sprintf('no %s-antenna RealizedGain at 25.5-27 GHz in provenance.json', family);
                r.evidence = 'data/antenna_port_response_cst/provenance.json';
                if exist(fullfile(repoRoot, stPath), 'file') == 2
                    S = jsondecode(fileread(fullfile(repoRoot, stPath)));
                    cells = [];
                    if isfield(S, 'mesh_attempts')
                        ma = S.mesh_attempts; if ~iscell(ma); ma = num2cell(ma); end
                        cells = cellfun(@(a) a.mesh_cells, ma);
                    end
                    r.reason = sprintf('%s: CST %s status %s (%s); smallest attempted mesh %d cells > Learning Edition limit', ...
                        r.reason, caseName, S.status, S.edition, min(cells));
                    r.evidence = [r.evidence '; ' strrep(stPath, '\', '/')];
                end
                return;
            end
            if any(~[c.normalization_reliable])
                r.status = 'INPUT_MISSING';
                r.reason = sprintf('%s KA RealizedGain normalization_reliable = false', family);
                r.evidence = 'data/antenna_port_response_cst/provenance.json';
                return;
            end
            F = unique([c.frequency_hz]);
            r.freqs_Hz = F; r.xz = cell(1, numel(F)); r.yz = r.xz; r.files = repmat({''}, 1, numel(F));
            for k = 1:numel(F)
                for pl = {'XZ', 'YZ'}
                    m = c([c.frequency_hz] == F(k) & strcmp({c.plane}, pl{1}));
                    if numel(m) ~= 1
                        error('rfscreen:kaa:badResponse', '%s KA %g GHz %s: expected one cut.', family, F(k) / 1e9, pl{1});
                    end
                    g = rfscreen.kaa.KaVictimResponse.readCut(fullfile(repoRoot, m.path));
                    if strcmp(pl{1}, 'XZ'); r.xz{k} = g; else; r.yz{k} = g; end
                    r.files{k} = strtrim([r.files{k} ' ' m.path]);
                end
            end
            r.status = 'AVAILABLE';
            r.reason = '';
            r.evidence = sprintf('data/antenna_port_response_cst/provenance.json (%s, normalization_reliable)', c(1).source_case);
            r.cstCase = c(1).source_case;
        end

        function r = fromCuts(family, band, freqs_Hz, xz, yz, label)
            %FROMCUTS Explicit response (tests / other sources). band must name the cut band.
            r = rfscreen.kaa.KaVictimResponse();
            r.family = family; r.band = band; r.freqs_Hz = freqs_Hz; r.xz = xz; r.yz = yz;
            r.status = 'AVAILABLE'; r.reason = ''; r.evidence = label; r.cstCase = label;
            r.files = repmat({label}, 1, numel(freqs_Hz));
        end

        function g = readCut(path)
            txt = fileread(path);
            L = regexp(txt, '\r\n|\r|\n', 'split'); L = L(~cellfun(@isempty, strtrim(L)));
            hdr = strtrim(regexp(L{1}, ',', 'split'));
            it = find(strcmp(hdr, 'theta'), 1); ig = find(strcmp(hdr, 'gain'), 1);
            v = zeros(numel(L) - 1, numel(hdr));
            for i = 2:numel(L); v(i - 1, :) = str2double(regexp(L{i}, ',', 'split')); end
            [t, o] = sort(mod(v(:, it), 360)); g = v(o, ig).';
            if numel(t) ~= 360 || any(abs(t(:).' - (0:359)) > 1e-9)
                error('rfscreen:kaa:badCut', '%s: expected theta 0..359 at 1 degree.', path);
            end
        end

        function g = cutGain(xz, yz, dL)
            %CUTGAIN Two-cut azimuthal interpolation in the CST local frame (APPROX_FROM_CUTS):
            %   phi = 0/90/180/270 <- XZ(theta), YZ(theta), XZ(360-theta), YZ(360-theta).
            d = dL(:) / norm(dL);
            th = acosd(max(-1, min(1, d(3)))); ph = mod(atan2d(d(2), d(1)), 360);
            p = @(c, t) interp1(0:360, [c c(1)], mod(t, 360), 'linear');
            g = interp1([0 90 180 270 360], [p(xz, th) p(yz, th) p(xz, 360 - th) p(yz, 360 - th) p(xz, th)], ph, 'linear');
        end
    end
    methods
        function tf = isAvailable(r)
            tf = strcmp(r.status, 'AVAILABLE');
        end

        function g = gainAt(r, f_Hz, dL)
            %GAINAT Victim RealizedGain [dBi] at Ka frequency f_Hz toward CST-local direction dL.
            %   dB interpolation only between computed monitors; refuses in-band/missing responses.
            V = rfscreen.kaa.KaVictimResponse;
            if ~strcmp(r.band, 'KA')
                error('rfscreen:kaa:inBandGainForbidden', ['Ka fundamental path needs the victim response at ' ...
                    '25.5-27 GHz; got the %s-band response of the %s antenna (in-band/own-band gain is not ' ...
                    'a substitute).'], r.band, r.family);
            end
            if ~r.isAvailable()
                error('rfscreen:kaa:victimResponseMissing', '%s Ka response is %s: %s', r.family, r.status, r.reason);
            end
            if f_Hz < V.KA_BAND_HZ(1) - 1 || f_Hz > V.KA_BAND_HZ(2) + 1 || f_Hz < min(r.freqs_Hz) - 1 || f_Hz > max(r.freqs_Hz) + 1
                error('rfscreen:kaa:outsideKaBand', '%.6g GHz outside the computed Ka monitors.', f_Hz / 1e9);
            end
            F = r.freqs_Hz; k = find(F <= f_Hz + 1, 1, 'last'); k = min(max(k, 1), max(numel(F) - 1, 1));
            if numel(F) == 1; g = V.cutGain(r.xz{1}, r.yz{1}, dL); return; end
            w = max(0, min(1, (f_Hz - F(k)) / (F(k + 1) - F(k))));
            g = (1 - w) * V.cutGain(r.xz{k}, r.yz{k}, dL) + w * V.cutGain(r.xz{k + 1}, r.yz{k + 1}, dL);
        end
    end
end
