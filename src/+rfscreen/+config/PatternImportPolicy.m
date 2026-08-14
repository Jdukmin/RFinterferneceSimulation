classdef PatternImportPolicy
    %PATTERNIMPORTPOLICY Pattern-data import/canonicalization policy (ICD pattern_data.md 12).
    %   All tolerances documented; float steps never compared by exact equality (DR-104).
    properties
        stepTolerance_deg       = 1e-3    % uniform-step detection tolerance
        angleTolerance_deg      = 1e-6    % duplicate canonical-angle tolerance
        gainMergeTolerance_dB   = 0.1     % duplicate collapse threshold
        duplicateConflictPolicy = 'warn'  % 'warn' -> VALID_WITH_WARNINGS ; 'error' -> INVALID
        mergeMethod             = 'mean'  % deterministic duplicate merge
    end
    methods
        function obj = PatternImportPolicy(opts)
            if nargin >= 1 && ~isempty(opts) && isstruct(opts)
                f = fieldnames(opts);
                for i = 1:numel(f)
                    if isprop(obj, f{i})
                        obj.(f{i}) = opts.(f{i});
                    end
                end
            end
            V = rfscreen.util.Validate;
            obj.stepTolerance_deg     = V.nonnegativeScalar(obj.stepTolerance_deg, 'stepTolerance_deg');
            obj.angleTolerance_deg    = V.nonnegativeScalar(obj.angleTolerance_deg, 'angleTolerance_deg');
            obj.gainMergeTolerance_dB = V.nonnegativeScalar(obj.gainMergeTolerance_dB, 'gainMergeTolerance_dB');
            V.member(obj.duplicateConflictPolicy, {'warn', 'error'}, 'duplicateConflictPolicy');
            V.member(obj.mergeMethod, {'mean'}, 'mergeMethod');
        end
    end
end
