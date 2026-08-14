classdef ReceiverFilter
    %RECEIVERFILTER Abstract RX filter (ICD receiver_susceptibility.md 2).
    %   Canonical response = power gain in dB (0 dB passband, negative rejection),
    %   with deterministic dB->linear conversion for the linear integration.
    properties (SetAccess = protected)
        provenance   % FilterProvenance char
    end
    methods
        function y = responseDb(obj, f_Hz) %#ok<STOUT,INUSD>
            error('rfscreen:receiver:abstract', 'responseDb must be implemented by a subclass.');
        end
        function y = responseLinear(obj, f_Hz)
            %RESPONSELINEAR Linear power ratio = 10^(dB/10).
            y = 10.^(obj.responseDb(f_Hz) / 10);
        end
        function g = nativeGrid_Hz(obj) %#ok<STOUT,MANU>
            error('rfscreen:receiver:abstract', 'nativeGrid_Hz must be implemented by a subclass.');
        end
        function b = relevantBand_Hz(obj) %#ok<STOUT,MANU>
            error('rfscreen:receiver:abstract', 'relevantBand_Hz must be implemented by a subclass.');
        end
        function enbw = equivalentNoiseBandwidth_Hz(obj)
            %EQUIVALENTNOISEBANDWIDTH_HZ ENBW = int(responseLinear) / max(responseLinear).
            b = obj.relevantBand_Hz();
            g = obj.nativeGrid_Hz();
            % integrate linear response over relevant band on a union of breakpoints
            nodes = unique([b(1), b(2), g(g >= b(1) & g <= b(2))]);
            if numel(nodes) < 2
                enbw = NaN; return;
            end
            area = 0; peak = 0;
            for i = 1:numel(nodes)-1
                a = nodes(i); c = nodes(i+1); m = 0.5*(a+c);
                lin = obj.responseLinear(m);
                area = area + lin * (c - a);
                peak = max(peak, lin);
            end
            % also consider peak at nodes (piecewise-constant safety)
            peak = max(peak, max(obj.responseLinear(nodes)));
            if peak <= 0; enbw = NaN; else; enbw = area / peak; end
        end
    end
end
