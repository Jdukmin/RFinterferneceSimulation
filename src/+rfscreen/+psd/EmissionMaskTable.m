classdef EmissionMaskTable
    %EMISSIONMASKTABLE Reader for tx_emission_masks.csv (TX unwanted emission in victim bands).
    %   Columns: tx_system, reference_plane, carrier_frequency_hz, victim_band, frequency_hz,
    %   emission_type, level, unit, rbw_hz, filter_state, provenance. '#' lines are comments.
    %   An empty table is valid: no mask is ever defaulted or synthesised.
    methods (Static)
        function S = read(path)
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(path);
            S = {};
            for r = 1:T.nRows
                S{end+1} = rfscreen.psd.EmissionSpec(T.tx_system{r}, T.reference_plane{r}, ...
                    str2double(T.carrier_frequency_hz{r}), T.victim_band{r}, str2double(T.frequency_hz{r}), ...
                    T.emission_type{r}, str2double(T.level{r}), T.unit{r}, str2double(T.rbw_hz{r}), ...
                    T.filter_state{r}, T.provenance{r}); %#ok<AGROW>
            end
        end

        function sel = select(S, txTemplate, victimBand)
            sel = S(cellfun(@(s) strcmp(s.txSystem, txTemplate) && strcmp(s.victimBand, victimBand), S));
        end
    end
end
