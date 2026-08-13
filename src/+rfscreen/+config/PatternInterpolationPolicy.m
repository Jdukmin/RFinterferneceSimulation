classdef PatternInterpolationPolicy
    %PATTERNINTERPOLATIONPOLICY Pattern lookup policy (ICD scenario.md 3.3).
    properties
        angular       = 'bilinear'   % angular interpolation method
        azWrap        = true         % azimuth periodic
        elClamp       = true         % clamp elevation to grid boundary
        freqMethod    = 'nearest'    % 'nearest' | 'linear'
        outOfBandFreq = 'nan'        % 'nan' | 'nearest' | 'error'
    end
    methods
        function obj = PatternInterpolationPolicy(opts)
            if nargin >= 1 && ~isempty(opts) && isstruct(opts)
                f = fieldnames(opts);
                for i = 1:numel(f)
                    if isprop(obj, f{i}) || isfield(struct(obj), f{i})
                        obj.(f{i}) = opts.(f{i});
                    end
                end
            end
            obj.validate();
        end
        function validate(obj)
            rfscreen.util.Validate.member(obj.freqMethod, {'nearest', 'linear'}, 'freqMethod');
            rfscreen.util.Validate.member(obj.outOfBandFreq, {'nan', 'nearest', 'error'}, 'outOfBandFreq');
        end
    end
end
