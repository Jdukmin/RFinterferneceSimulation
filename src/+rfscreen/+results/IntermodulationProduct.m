classdef IntermodulationProduct
    %INTERMODULATIONPRODUCT One IM3 product (ICD receiver_nonlinear.md 9, Task 22).
    properties
        txId1 = ''
        txId2 = ''
        f1_Hz = NaN
        f2_Hz = NaN
        p1_dBm = NaN
        p2_dBm = NaN
        productType = ''
        productFrequency_Hz = NaN
        iip3_in_dBm = NaN
        equivalentInputPower_dBm = NaN   % input-referred IM3 (LNA_INPUT)
        channelResponse_dB = NaN
        effectiveProductPower_dBm = NaN
        inPassband = false
        referencePlane = ''
        margin_dB = NaN
        passFail = 'UNKNOWN'
        validity = ''
        warnings = {}
    end
    methods
        function obj = IntermodulationProduct(s)
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
