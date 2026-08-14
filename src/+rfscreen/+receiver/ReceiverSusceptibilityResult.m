classdef ReceiverSusceptibilityResult
    %RECEIVERSUSCEPTIBILITYRESULT Structured susceptibility result (ICD 7, Task 22).
    %   Unknown fields stay explicit (NaN/''); nothing invented.
    properties
        mode = ''                       % AnalysisMode
        referencePlane = ''             % ReferencePlane
        spectralOverlapFraction = NaN
        spectralFactor_dB = NaN
        interferencePower_dBm = NaN     % absolute; NaN unless Mode B
        noisePower_dBm = NaN
        noiseBandwidth_Hz = NaN
        iOverN_dB = NaN
        thresholdType = ''
        thresholdValue = NaN
        margin_dB = NaN
        passFail = 'UNKNOWN'
        couplingValidity = ''
        validity = ''                   % SusceptibilityValidity
        confidence = NaN
        warnings = {}
    end
    methods
        function obj = ReceiverSusceptibilityResult(s)
            if nargin >= 1 && ~isempty(s) && isstruct(s)
                f = fieldnames(s);
                for i = 1:numel(f)
                    if isprop(obj, f{i}); obj.(f{i}) = s.(f{i}); end
                end
            end
        end
        function tf = isAbsolute(obj)
            tf = strcmp(obj.mode, rfscreen.receiver.AnalysisMode.ABSOLUTE_LINEAR);
        end
        function s = toStruct(obj)
            p = properties(obj); s = struct();
            for i = 1:numel(p); s.(p{i}) = obj.(p{i}); end
        end
    end
end
