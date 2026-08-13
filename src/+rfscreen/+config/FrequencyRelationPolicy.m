classdef FrequencyRelationPolicy
    %FREQUENCYRELATIONPOLICY Adjacent-band guard policy (AR-090).
    properties
        guard_Hz = 0   % separation <= guard_Hz => ADJACENT_BAND
    end
    methods
        function obj = FrequencyRelationPolicy(opts)
            if nargin >= 1 && ~isempty(opts) && isstruct(opts) && isfield(opts, 'guard_Hz')
                obj.guard_Hz = opts.guard_Hz;
            end
            obj.guard_Hz = rfscreen.util.Validate.nonnegativeScalar(obj.guard_Hz, 'guard_Hz');
        end
    end
end
