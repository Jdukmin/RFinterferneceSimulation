classdef PatternComparison
    %PATTERNCOMPARISON Free-space vs installed pattern comparison (ICD installed_environment.md 5).
    %   Evidence metrics over an explicit comparison grid; each pattern evaluated on
    %   its OWN native grid (Phase-2 principle); NEITHER source is mutated (Task 22).
    methods (Static)
        function res = compare(freeSpacePattern, installedPattern, opts)
            if nargin < 3 || isempty(opts); opts = struct(); end
            if isempty(freeSpacePattern) || isempty(installedPattern)
                error('rfscreen:installed:badCompare', 'both patterns are required.');
            end
            P = rfscreen.installed.PatternComparison;
            az = P.opt(opts, 'az_deg', -180:15:180);
            el = P.opt(opts, 'el_deg', -90:15:90);
            freq = P.opt(opts, 'frequency_Hz', freeSpacePattern.grid.frequency_Hz(1));

            diffs = []; gFreeAll = []; gInstAll = []; warnings = {}; nSkipped = 0;
            for ie = 1:numel(el)
                for ia = 1:numel(az)
                    gF = freeSpacePattern.evaluate(freq, az(ia), el(ie));
                    gI = installedPattern.evaluate(freq, az(ia), el(ie));
                    if isfinite(gF) && isfinite(gI)
                        diffs(end+1) = gI - gF; %#ok<AGROW>
                        gFreeAll(end+1) = gF;   %#ok<AGROW>
                        gInstAll(end+1) = gI;   %#ok<AGROW>
                    else
                        nSkipped = nSkipped + 1;   % out-of-domain sample excluded, never invented
                    end
                end
            end

            s = struct();
            s.frequency_Hz = freq;
            if isempty(diffs)
                s.peakGainDifference_dB = NaN;
                s.maxAbsDifference_dB = NaN;
                s.rmsDifference_dB = NaN;
                s.nGrid = 0;
                warnings{end+1} = 'no overlapping in-domain samples: comparison metrics undefined';
                s.validity = 'INSUFFICIENT_OVERLAP';
            else
                s.peakGainDifference_dB = max(gInstAll) - max(gFreeAll);
                s.maxAbsDifference_dB = max(abs(diffs));
                s.rmsDifference_dB = sqrt(mean(diffs .^ 2));
                s.nGrid = numel(diffs);
                s.validity = 'VALID';
            end
            if nSkipped > 0
                warnings{end+1} = sprintf('%d grid sample(s) excluded (out of pattern domain)', nSkipped);
            end
            s.freeSpaceProvenance = freeSpacePattern.provenance;
            s.installedProvenance = installedPattern.provenance;
            s.installedSource = installedPattern.installedSource;
            s.warnings = warnings;
            res = rfscreen.results.PatternComparisonResult(s);
        end

        function delta = directionDelta_dB(freeSpacePattern, installedPattern, frequency_Hz, az_deg, el_deg)
            %DIRECTIONDELTA_DB installed - freeSpace at one direction (NaN if either out of domain).
            gF = freeSpacePattern.evaluate(frequency_Hz, az_deg, el_deg);
            gI = installedPattern.evaluate(frequency_Hz, az_deg, el_deg);
            if isfinite(gF) && isfinite(gI); delta = gI - gF; else; delta = NaN; end
        end
    end
    methods (Static, Access = private)
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
    end
end
