classdef LobeClassificationPolicy
    %LOBECLASSIFICATIONPOLICY Configurable lobe thresholds (SR-061, AR-031).
    %   Thresholds are NEVER hard-coded in the engine.
    properties
        mainDropDb   = 3     % MAIN if gain >= peak - mainDropDb
        sideDropDb   = 20    % level boundary for side vs deep-back (metadata)
        backAngleDeg = 90    % BACK if off-boresight angle > backAngleDeg
    end
    methods
        function obj = LobeClassificationPolicy(opts)
            if nargin >= 1 && ~isempty(opts) && isstruct(opts)
                f = fieldnames(opts);
                for i = 1:numel(f)
                    if isprop(obj, f{i})
                        obj.(f{i}) = opts.(f{i});
                    end
                end
            end
            V = rfscreen.util.Validate;
            obj.mainDropDb   = V.nonnegativeScalar(obj.mainDropDb, 'mainDropDb');
            obj.sideDropDb   = V.nonnegativeScalar(obj.sideDropDb, 'sideDropDb');
            obj.backAngleDeg = V.finiteScalar(obj.backAngleDeg, 'backAngleDeg');
        end
    end
end
