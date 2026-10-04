classdef EmissionMaskTable
    %EMISSIONMASKTABLE Reader for TX source-emission tables (tx_emission_masks.csv, reference_scenarios.csv).
    %   Columns: rfscreen.psd.EmissionSpec.COLUMNS (extra columns are kept per row in .extra).
    %   '#' lines are comments. An empty table is valid: no source is ever defaulted or synthesised.
    methods (Static)
        function [S, extra] = read(path)
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(path);
            cols = rfscreen.psd.EmissionSpec.COLUMNS;
            for c = 1:numel(cols)
                if ~isfield(T, cols{c})
                    error('rfscreen:psd:badEmissionTable', '%s: missing column %s.', path, cols{c});
                end
            end
            S = cell(1, T.nRows); extra = cell(1, T.nRows); fn = fieldnames(T);
            for r = 1:T.nRows
                s = struct(); e = struct();
                for k = 1:numel(fn)
                    if strcmp(fn{k}, 'nRows'); continue; end
                    if any(strcmp(fn{k}, cols)); s.(fn{k}) = T.(fn{k}){r}; else; e.(fn{k}) = T.(fn{k}){r}; end
                end
                S{r} = rfscreen.psd.EmissionSpec(s); extra{r} = e;
            end
        end

        function sel = select(S, txTemplate, victimBand)
            sel = S(cellfun(@(s) strcmp(s.txSystem, txTemplate) && strcmp(s.victimBand, victimBand), S));
        end
    end
end
