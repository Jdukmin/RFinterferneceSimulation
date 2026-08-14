classdef PatternValidator
    %PATTERNVALIDATOR Deterministic validation of raw pattern-cut input (§25, §26).
    %   Detects structural problems BEFORE canonicalization. Duplicate-canonical and
    %   step-consistency checks are performed by PatternCanonicalizer after mapping.
    methods (Static)
        function res = validateRaw(theta, gain, conv)
            VS = rfscreen.patterndata.ValidationStatus;
            issues = {}; warnings = {};

            % missing convention / plane
            if isempty(conv) || ~isa(conv, 'rfscreen.patterndata.SourceCoordinateConvention')
                issues{end+1} = 'missing or invalid source coordinate convention (plane undefined)';
                res = rfscreen.patterndata.CutValidationResult(VS.INVALID, issues, warnings);
                return;
            end

            % non-numeric
            if ~isnumeric(theta) || ~isnumeric(gain)
                issues{end+1} = 'non-numeric angle or gain data';
                res = rfscreen.patterndata.CutValidationResult(VS.INVALID, issues, warnings);
                return;
            end
            theta = theta(:).'; gain = gain(:).';

            % empty
            if isempty(theta) || isempty(gain)
                issues{end+1} = 'empty pattern data';
                res = rfscreen.patterndata.CutValidationResult(VS.INVALID, issues, warnings);
                return;
            end
            % length match
            if numel(theta) ~= numel(gain)
                issues{end+1} = sprintf('theta/gain length mismatch (%d vs %d)', numel(theta), numel(gain));
                res = rfscreen.patterndata.CutValidationResult(VS.INVALID, issues, warnings);
                return;
            end
            % NaN / Inf
            if any(~isfinite(theta))
                issues{end+1} = 'non-finite (NaN/Inf) angle value(s)';
            end
            if any(~isfinite(gain))
                issues{end+1} = 'non-finite (NaN/Inf) gain value(s)';
            end
            % unsupported unit (defensive; convention constructor already restricts)
            if ~strcmp(conv.angleUnit, 'deg')
                issues{end+1} = sprintf('unsupported angle unit ''%s''', conv.angleUnit);
            end
            if ~strcmp(conv.gainUnit, 'dBi')
                issues{end+1} = sprintf('unsupported gain unit ''%s''', conv.gainUnit);
            end

            if ~isempty(issues)
                res = rfscreen.patterndata.CutValidationResult(VS.INVALID, issues, warnings);
                return;
            end

            % unsupported angle range (values must fall in the declared source range)
            if strcmp(conv.angleRange, '[-180,180]')
                if any(theta < -180 - 1e-6) || any(theta > 180 + 1e-6)
                    issues{end+1} = 'angle value(s) outside declared range [-180,180]';
                end
            else % '[0,360)'  (a trailing 360 endpoint is accepted; it canonicalizes to 0)
                if any(theta < -1e-6) || any(theta > 360 + 1e-6)
                    issues{end+1} = 'angle value(s) outside declared range [0,360]';
                end
            end

            % non-monotonic source sequence (warning; canonicalization sorts anyway)
            if numel(theta) >= 2 && any(diff(theta) <= 0)
                warnings{end+1} = 'source angle sequence is non-monotonic (will be sorted)';
            end
            % duplicate source angles (warning; resolved during canonicalization)
            if numel(unique(theta)) < numel(theta)
                warnings{end+1} = 'duplicate source angle(s) present (will be resolved)';
            end

            if ~isempty(issues)
                status = VS.INVALID;
            elseif ~isempty(warnings)
                status = VS.VALID_WITH_WARNINGS;
            else
                status = VS.VALID;
            end
            res = rfscreen.patterndata.CutValidationResult(status, issues, warnings);
        end
    end
end
