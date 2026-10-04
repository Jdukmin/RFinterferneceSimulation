classdef FilterScenario
    %FILTERSCENARIO Optional TX output / external filter attenuation L_filter(f) [dB] for the
    %   victim-band PSD path. Two kinds:
    %     FLAT  : one attenuation for every frequency (screening)
    %     TABLE : frequency-dependent table, dB-linear interpolation, no extrapolation (NaN outside)
    %   Default set FILTER_0DB / 40 / 60 / 70 / 80 dB is a SCREENING_FILTER_SCENARIO sweep, NOT a
    %   design value. Meaning per source reference plane: for PA_OUTPUT / FILTER_INPUT sources it is
    %   the TX output filter; for FILTER_OUTPUT / ANTENNA_PORT / RADIATED_EIRP_PSD sources it is an
    %   additional external filter beyond what the source statement already includes (0 dB = as stated).
    properties (Constant)
        SCREENING = 'SCREENING_FILTER_SCENARIO'
        DEFAULT_DB = [0 40 60 70 80]
    end
    properties (SetAccess = private)
        id
        kind
        freqs_Hz = []
        atten_dB
        provenance
    end
    methods
        function obj = FilterScenario(id, kind, freqs_Hz, atten_dB, provenance)
            obj.id = rfscreen.util.Validate.id(id, 'filter_scenario_id');
            obj.kind = rfscreen.util.Validate.member(kind, {'FLAT', 'TABLE'}, 'kind');
            if any(atten_dB(:) < 0)
                error('rfscreen:psd:negativeAttenuation', 'filter attenuation must be >= 0 dB.');
            end
            if strcmp(obj.kind, 'FLAT')
                if numel(atten_dB) ~= 1; error('rfscreen:psd:badFilter', 'FLAT needs one attenuation.'); end
            else
                if numel(freqs_Hz) ~= numel(atten_dB) || numel(freqs_Hz) < 2 || any(diff(freqs_Hz) <= 0)
                    error('rfscreen:psd:badFilter', 'TABLE needs >= 2 strictly increasing frequencies with one attenuation each.');
                end
            end
            obj.freqs_Hz = freqs_Hz(:).'; obj.atten_dB = atten_dB(:).'; obj.provenance = provenance;
        end

        function a = attenuationAt(obj, f_Hz)
            if strcmp(obj.kind, 'FLAT'); a = obj.atten_dB * ones(size(f_Hz)); return; end
            a = interp1(obj.freqs_Hz, obj.atten_dB, f_Hz, 'linear', NaN);
        end

        function s = label(obj)
            if strcmp(obj.kind, 'FLAT'); s = sprintf('%g', obj.atten_dB); else; s = 'TABLE'; end
        end
    end
    methods (Static)
        function S = defaults()
            S = {};
            for a = rfscreen.psd.FilterScenario.DEFAULT_DB
                S{end+1} = rfscreen.psd.FilterScenario(sprintf('FILTER_%dDB', a), 'FLAT', [], a, ...
                    rfscreen.psd.FilterScenario.SCREENING); %#ok<AGROW>
            end
        end

        function S = read(path)
            %READ filter_scenarios.csv: filter_scenario_id, kind, frequency_hz, attenuation_db, provenance
            %   (FLAT: one row, frequency_hz empty; TABLE: one row per frequency point).
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(path);
            ids = unique(T.filter_scenario_id, 'stable'); S = {};
            for i = 1:numel(ids)
                r = find(strcmp(T.filter_scenario_id, ids{i}));
                k = unique(T.kind(r));
                if numel(k) ~= 1; error('rfscreen:psd:badFilter', '%s mixes kinds.', ids{i}); end
                f = str2double(T.frequency_hz(r)); a = str2double(T.attenuation_db(r));
                [f, o] = sort(f); a = a(o);
                S{end+1} = rfscreen.psd.FilterScenario(ids{i}, k{1}, f, a, T.provenance{r(1)}); %#ok<AGROW>
            end
        end
    end
end
