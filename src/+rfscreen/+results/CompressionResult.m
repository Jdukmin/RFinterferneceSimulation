classdef CompressionResult
    %COMPRESSIONRESULT Aggregate compression screening (ICD receiver_nonlinear.md 9).
    %   Plain value object; unknowns explicit (NaN). Separate from Phase-3 results.
    properties
        referencePlane = ''
        aggregateInputPower_dBm = NaN
        p1dB_in_dBm = NaN
        compressionMargin_dB = NaN
        passFail = 'UNKNOWN'
        nInterferers = 0
        nValidInterferers = 0
        validity = ''
        warnings = {}
    end
    methods
        function obj = CompressionResult(s)
            if nargin >= 1 && ~isempty(s) && isstruct(s)
                f = fieldnames(s);
                for i = 1:numel(f)
                    if isprop(obj, f{i}); obj.(f{i}) = s.(f{i}); end
                end
            end
        end
        function t = toStruct(obj)
            p = properties(obj); t = struct();
            for i = 1:numel(p); t.(p{i}) = obj.(p{i}); end
        end
    end
end
