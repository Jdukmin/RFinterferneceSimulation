classdef BlockingResult
    %BLOCKINGRESULT Per-interferer blocking assessment (ICD receiver_nonlinear.md 9).
    %   entries: struct array with fields txId, blockerPower_dBm, offset_Hz,
    %   allowable_dBm, margin_dB, passFail, validity.
    properties
        referencePlane = ''
        entries = struct('txId', {}, 'blockerPower_dBm', {}, 'offset_Hz', {}, ...
                         'allowable_dBm', {}, 'margin_dB', {}, 'passFail', {}, 'validity', {})
        worstMargin_dB = NaN
        worstTxId = ''
        validity = ''
        warnings = {}
    end
    methods
        function obj = BlockingResult(s)
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
