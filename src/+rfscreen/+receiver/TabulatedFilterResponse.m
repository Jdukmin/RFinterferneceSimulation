classdef TabulatedFilterResponse < rfscreen.receiver.ReceiverFilter
    %TABULATEDFILTERRESPONSE Filter response tabulated as power gain [dB] vs freq
    %   (ICD receiver_susceptibility.md 2). Interpolated in dB (standard for filter
    %   masks) then converted to linear for the integration; boundary = clamp.
    properties (SetAccess = private)
        freq_Hz
        gain_dB
    end
    methods
        function obj = TabulatedFilterResponse(freq_Hz, gain_dB, opts)
            if nargin < 3 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            f = V.monotonicVector(freq_Hz, 'freq_Hz');
            if any(f <= 0); error('rfscreen:receiver:badFreq', 'freq_Hz must be > 0.'); end
            g = gain_dB(:).';
            if numel(g) ~= numel(f)
                error('rfscreen:receiver:filterShape', 'gain_dB and freq_Hz length mismatch.');
            end
            if any(~isfinite(g))
                error('rfscreen:receiver:filterFinite', 'tabulated gain_dB must be finite.');
            end
            obj.freq_Hz = f; obj.gain_dB = g;
            if isfield(opts, 'provenance') && ~isempty(opts.provenance)
                obj.provenance = V.member(opts.provenance, ...
                    rfscreen.receiver.FilterProvenance.values(), 'provenance');
            else
                obj.provenance = rfscreen.receiver.FilterProvenance.SYNTHETIC_TEST;
            end
        end

        function y = responseDb(obj, f_Hz)
            % clamp outside the tabulated range to the boundary values
            y = interp1(obj.freq_Hz, obj.gain_dB, f_Hz, 'linear');
            below = f_Hz < obj.freq_Hz(1);
            above = f_Hz > obj.freq_Hz(end);
            y(below) = obj.gain_dB(1);
            y(above) = obj.gain_dB(end);
        end
        function g = nativeGrid_Hz(obj)
            g = obj.freq_Hz;
        end
        function b = relevantBand_Hz(obj)
            b = [obj.freq_Hz(1), obj.freq_Hz(end)];
        end
    end
end
