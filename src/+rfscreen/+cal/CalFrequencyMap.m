classdef CalFrequencyMap
    %CALFREQUENCYMAP Explicit filename-token -> canonical frequency aliases (data/cal_config/cal_frequency_aliases.csv).
    %   Canonical values come from the repository frequency SSOT (rf_systems.csv) where a row exists; the
    %   filename token may differ only by display precision (ALIAS_TOL_MHZ). Unknown tokens are NOT
    %   resolved (no extrapolation, no nearest plane).
    properties (Constant)
        ALIAS_TOL_MHZ = 0.1
        GPS_COMMON_LABELS = {'L5', 'L2', 'L1'}   % owner: GPS_*_f1.2 = one CST solve (~1.2 GHz) used as a surrogate at L5/L2/L1
    end
    properties (SetAccess = private)
        tokens = {}          % cellstr, as written in the alias file
        tokenValue = []      % numeric token [GHz]
        freq_Hz = []         % canonical [Hz]
        labels = {}          % short label (L1, 2p06, ...)
        sources = {}         % canonical source tag
        notes = {}
    end
    methods (Static)
        function m = load(aliasFile, rfSystemsFile)
            R = rfscreen.spacecraft.SpacecraftDataReader;
            A = R.readTable(aliasFile);
            S = R.readTable(rfSystemsFile);
            m = rfscreen.cal.CalFrequencyMap();
            for r = 1:A.nRows
                tok = A.token{r}; tv = str2double(tok);
                if ~isfinite(tv) || tv <= 0
                    error('rfscreen:cal:badAlias', '%s: bad token "%s".', aliasFile, tok);
                end
                src = A.canonical_source{r};
                if strncmp(src, 'RF_SYSTEM:', 10)
                    tid = src(11:end);
                    k = find(strcmp(S.template_id, tid), 1);
                    if isempty(k)
                        error('rfscreen:cal:badAlias', '%s: template %s not in rf_systems.csv.', aliasFile, tid);
                    end
                    fmhz = str2double(S.fc_mhz{k});
                elseif strcmp(src, 'LITERAL')
                    fmhz = str2double(A.canonical_mhz{r});
                else
                    error('rfscreen:cal:badAlias', '%s: unknown canonical_source %s.', aliasFile, src);
                end
                if abs(fmhz - tv * 1e3) > rfscreen.cal.CalFrequencyMap.ALIAS_TOL_MHZ
                    error('rfscreen:cal:aliasTooFar', ['%s: token %s GHz vs canonical %.6g MHz differ by more than ' ...
                        '%.3g MHz: an alias may only absorb display precision.'], aliasFile, tok, fmhz, ...
                        rfscreen.cal.CalFrequencyMap.ALIAS_TOL_MHZ);
                end
                if any(abs(m.tokenValue - tv) < 1e-9)
                    error('rfscreen:cal:badAlias', '%s: duplicate token %s.', aliasFile, tok);
                end
                m.tokens{end+1} = tok; m.tokenValue(end+1) = tv; m.freq_Hz(end+1) = fmhz * 1e6;
                m.labels{end+1} = A.label{r}; m.sources{end+1} = src; m.notes{end+1} = A.note{r};
            end
        end
    end
    methods
        function [ok, f_Hz, label, src] = resolve(m, token)
            %RESOLVE Canonical frequency of a filename token (char, GHz). ok = false if unmapped.
            tv = str2double(token);
            k = find(abs(m.tokenValue - tv) < 1e-9, 1);
            ok = ~isempty(k) && isfinite(tv);
            if ~ok; f_Hz = NaN; label = ''; src = ''; return; end
            f_Hz = m.freq_Hz(k); label = m.labels{k}; src = m.sources{k};
        end

        function [ok, f_Hz, label] = byLabel(m, label)
            k = find(strcmp(m.labels, label), 1);
            ok = ~isempty(k);
            if ok; f_Hz = m.freq_Hz(k); else; f_Hz = NaN; end
        end

        function label = labelOf(m, f_Hz)
            k = find(abs(m.freq_Hz - f_Hz) <= 1, 1);
            if isempty(k); label = sprintf('%.6gGHz', f_Hz / 1e9); else; label = m.labels{k}; end
        end

        function [f_Hz, labels] = gpsCommon(m)
            %GPSCOMMON Canonical L5/L2/L1 frequencies shared by the GPS_*_f1.2 patterns.
            labels = rfscreen.cal.CalFrequencyMap.GPS_COMMON_LABELS;
            f_Hz = zeros(1, numel(labels));
            for i = 1:numel(labels)
                [ok, f_Hz(i)] = m.byLabel(labels{i});
                if ~ok
                    error('rfscreen:cal:badAlias', 'GPS common band %s missing from the alias table.', labels{i});
                end
            end
        end
    end
end
