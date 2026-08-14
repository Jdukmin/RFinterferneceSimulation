classdef ValidationStatus
    %VALIDATIONSTATUS Severity of a pattern-data validation result (§26).
    properties (Constant)
        VALID               = 'VALID'
        VALID_WITH_WARNINGS = 'VALID_WITH_WARNINGS'
        INVALID             = 'INVALID'
    end
    methods (Static)
        function v = values()
            v = {'VALID', 'VALID_WITH_WARNINGS', 'INVALID'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.patterndata.ValidationStatus.values()));
        end
        function s = worst(a, b)
            %WORST Return the more severe of two statuses (INVALID > WITH_WARN > VALID).
            rank = @(x) find(strcmp(x, {'VALID', 'VALID_WITH_WARNINGS', 'INVALID'}), 1);
            if rank(b) > rank(a); s = b; else; s = a; end
        end
    end
end
