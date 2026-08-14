classdef CutValidationResult
    %CUTVALIDATIONRESULT Structured validation outcome (§26). Warnings never discarded.
    properties (SetAccess = private)
        status      % ValidationStatus char
        issues      % cellstr (INVALID-causing)
        warnings    % cellstr
    end
    methods
        function obj = CutValidationResult(status, issues, warnings)
            if nargin < 1 || isempty(status); status = rfscreen.patterndata.ValidationStatus.VALID; end
            if nargin < 2 || isempty(issues); issues = {}; end
            if nargin < 3 || isempty(warnings); warnings = {}; end
            obj.status = status; obj.issues = issues; obj.warnings = warnings;
        end
        function tf = isValid(obj)
            tf = ~strcmp(obj.status, rfscreen.patterndata.ValidationStatus.INVALID);
        end
    end
end
