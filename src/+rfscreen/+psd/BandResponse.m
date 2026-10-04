classdef BandResponse
    %BANDRESPONSE CST antenna-port response of one antenna family in ONE evaluation band.
    %   Source: data/antenna_port_response_cst/provenance.json (RealizedGain, two independent 1-degree
    %   cuts, CST local frame +Z = boresight). The band tag travels with the response so that an
    %   attacker-band (TX operating band) pattern can never be used on the victim-band path.
    %   Status: AVAILABLE | INPUT_UNRELIABLE (normalization_reliable = false) | INPUT_MISSING.
    properties (SetAccess = private)
        family
        band
        status
        reason = ''
        cstCase = ''
        freqs_Hz = []
        xz = {}
        yz = {}
        files = {}
    end
    methods (Static)
        function r = fromRepository(repoRoot, family, band, prov)
            if nargin < 4 || isempty(prov)
                prov = jsondecode(fileread(fullfile(repoRoot, 'data', 'antenna_port_response_cst', 'provenance.json')));
            end
            r = rfscreen.psd.BandResponse(); r.family = family; r.band = band;
            cuts = prov.cuts; if iscell(cuts); cuts = [cuts{:}]; end
            c = cuts(strcmp({cuts.family}, family) & strcmp({cuts.band}, band) & strcmp({cuts.quantity}, 'RealizedGain'));
            if isempty(c)
                cs = prov.cases; if iscell(cs); cs = cs(:).'; else; cs = num2cell(cs(:).'); end
                bad = {};
                for i = 1:numel(cs)
                    if strcmp(cs{i}.family, family) && ~strcmp(cs{i}.status, 'SOLVED')
                        fn = fieldnames(cs{i}); cn = fn{find(~cellfun(@isempty, regexpi(fn, 'case')), 1)};   % 'case' is a keyword
                        bad{end+1} = sprintf('%s %s', cs{i}.(cn), cs{i}.status); %#ok<AGROW>
                    end
                end
                r.status = 'INPUT_MISSING';
                r.reason = sprintf('no %s-antenna RealizedGain in the %s band (CST: %s)', family, band, strjoin(bad, '; '));
                return;
            end
            r.cstCase = c(1).source_case;
            if any(~[c.normalization_reliable])
                r.status = 'INPUT_UNRELIABLE';
                r.reason = sprintf('%s/%s RealizedGain normalization_reliable = false (%s) - not used', family, band, r.cstCase);
                return;
            end
            F = unique([c.frequency_hz]); r.freqs_Hz = F;
            r.xz = cell(1, numel(F)); r.yz = r.xz; r.files = repmat({''}, 1, numel(F));
            for k = 1:numel(F)
                for pl = {'XZ', 'YZ'}
                    m = c([c.frequency_hz] == F(k) & strcmp({c.plane}, pl{1}));
                    g = rfscreen.kaa.KaVictimResponse.readCut(fullfile(repoRoot, m(1).path));
                    if strcmp(pl{1}, 'XZ'); r.xz{k} = g; else; r.yz{k} = g; end
                    r.files{k} = strtrim([r.files{k} ' ' m(1).path]);
                end
            end
            r.status = 'AVAILABLE';
        end

        function r = fromCuts(family, band, freqs_Hz, xz, yz, label)
            r = rfscreen.psd.BandResponse(); r.family = family; r.band = band; r.freqs_Hz = freqs_Hz;
            r.xz = xz; r.yz = yz; r.status = 'AVAILABLE'; r.cstCase = label; r.files = repmat({label}, 1, numel(freqs_Hz));
        end

        function r = missing(family, band, reason)
            r = rfscreen.psd.BandResponse(); r.family = family; r.band = band; r.status = 'INPUT_MISSING'; r.reason = reason;
        end
    end
    methods
        function tf = isAvailable(r)
            tf = strcmp(r.status, 'AVAILABLE');
        end

        function g = gainAt(r, band, f_Hz, dL)
            %GAINAT RealizedGain [dBi] in the requested band (must equal r.band) at f_Hz toward dL.
            %   dB interpolation only between computed monitors of that band; no extrapolation.
            if ~strcmp(band, r.band)
                error('rfscreen:psd:wrongBandResponse', ['%s-antenna response of band %s requested for band %s: ' ...
                    'a pattern of another band (e.g. the attacker operating band) is never re-used.'], r.family, r.band, band);
            end
            if ~r.isAvailable()
                error('rfscreen:psd:responseMissing', '%s/%s response %s: %s', r.family, r.band, r.status, r.reason);
            end
            F = r.freqs_Hz;
            if f_Hz < min(F) - 1 || f_Hz > max(F) + 1
                error('rfscreen:psd:outsideComputedBand', '%.6g GHz outside the computed %s monitors (%.6g-%.6g GHz).', ...
                    f_Hz / 1e9, r.band, min(F) / 1e9, max(F) / 1e9);
            end
            cg = @(k) rfscreen.kaa.KaVictimResponse.cutGain(r.xz{k}, r.yz{k}, dL);
            if numel(F) == 1; g = cg(1); return; end
            k = find(F <= f_Hz + 1, 1, 'last'); k = min(max(k, 1), numel(F) - 1);
            w = max(0, min(1, (f_Hz - F(k)) / (F(k + 1) - F(k))));
            g = (1 - w) * cg(k) + w * cg(k + 1);
        end
    end
end
