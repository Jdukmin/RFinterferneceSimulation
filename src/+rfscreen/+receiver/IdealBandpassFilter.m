classdef IdealBandpassFilter < rfscreen.receiver.ReceiverFilter
    %IDEALBANDPASSFILTER Piecewise-constant bandpass (ICD receiver_susceptibility.md 2).
    %   passbandGain_dB in [lo,hi]; stopbandGain_dB elsewhere (-Inf => full reject).
    properties (SetAccess = private)
        band_Hz             % [lo hi]
        passbandGain_dB
        stopbandGain_dB
    end
    methods
        function obj = IdealBandpassFilter(band_Hz, passbandGain_dB, stopbandGain_dB, opts)
            if nargin < 2 || isempty(passbandGain_dB); passbandGain_dB = 0; end
            if nargin < 3 || isempty(stopbandGain_dB); stopbandGain_dB = -Inf; end
            if nargin < 4 || isempty(opts); opts = struct(); end
            if ~(isnumeric(band_Hz) && numel(band_Hz) == 2 && all(isfinite(band_Hz)) ...
                    && band_Hz(1) < band_Hz(2) && band_Hz(1) > 0)
                error('rfscreen:receiver:badBand', 'band_Hz must be [lo hi] with 0 < lo < hi.');
            end
            obj.band_Hz = double(band_Hz(:)).';
            obj.passbandGain_dB = rfscreen.util.Validate.finiteScalar(passbandGain_dB, 'passbandGain_dB');
            if ~(isscalar(stopbandGain_dB) && isreal(stopbandGain_dB) && stopbandGain_dB <= obj.passbandGain_dB)
                error('rfscreen:receiver:badStopband', ...
                    'stopbandGain_dB must be a real scalar <= passbandGain_dB (may be -Inf).');
            end
            obj.stopbandGain_dB = double(stopbandGain_dB);
            if isfield(opts, 'provenance') && ~isempty(opts.provenance)
                obj.provenance = rfscreen.util.Validate.member(opts.provenance, ...
                    rfscreen.receiver.FilterProvenance.values(), 'provenance');
            else
                obj.provenance = rfscreen.receiver.FilterProvenance.IDEAL_MODEL;
            end
        end

        function y = responseDb(obj, f_Hz)
            inBand = (f_Hz >= obj.band_Hz(1)) & (f_Hz <= obj.band_Hz(2));
            y = obj.stopbandGain_dB * ones(size(f_Hz));
            y(inBand) = obj.passbandGain_dB;
        end
        function g = nativeGrid_Hz(obj)
            g = obj.band_Hz;
        end
        function b = relevantBand_Hz(obj)
            b = obj.band_Hz;
        end
    end
end
