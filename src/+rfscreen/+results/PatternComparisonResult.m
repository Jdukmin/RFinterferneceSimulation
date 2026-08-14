classdef PatternComparisonResult
    %PATTERNCOMPARISONRESULT Free-space vs installed pattern comparison (ICD installed_environment.md 5).
    %   Evidence metrics only; neither source pattern is mutated.
    properties
        frequency_Hz = NaN
        peakGainDifference_dB = NaN     % peak(installed) - peak(freeSpace)
        maxAbsDifference_dB = NaN
        rmsDifference_dB = NaN
        nGrid = 0
        freeSpaceProvenance = ''
        installedProvenance = ''
        installedSource = ''
        validity = ''
        warnings = {}
    end
    methods
        function obj = PatternComparisonResult(s)
            if nargin >= 1 && ~isempty(s) && isstruct(s)
                f = fieldnames(s);
                for i = 1:numel(f); if isprop(obj, f{i}); obj.(f{i}) = s.(f{i}); end; end
            end
        end
    end
end
