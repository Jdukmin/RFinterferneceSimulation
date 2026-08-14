classdef RectangularSpectrum < rfscreen.spectrum.SpectrumModel
    %RECTANGULARSPECTRUM Flat PSD over [fc-bw/2, fc+bw/2] (ICD spectrum.md 5).
    %   PSD_W = P_total_W / bw in band, 0 outside. Integrates exactly to P_total.
    properties (SetAccess = private)
        centerFrequency_Hz
        bandwidth_Hz
        power_dBm
    end
    methods
        function obj = RectangularSpectrum(fc_Hz, bw_Hz, totalPower_dBm, opts)
            if nargin < 4 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            obj.centerFrequency_Hz = V.positiveScalar(fc_Hz, 'fc_Hz');
            obj.bandwidth_Hz = V.positiveScalar(bw_Hz, 'bw_Hz');
            obj.power_dBm = V.finiteScalar(totalPower_dBm, 'totalPower_dBm');
            obj.provenance = V.member( ...
                rfscreen.spectrum.RectangularSpectrum.opt(opts, 'provenance', ...
                    rfscreen.spectrum.SpectrumProvenance.IDEAL_MODEL), ...
                rfscreen.spectrum.SpectrumProvenance.values(), 'provenance');
            obj.referencePlane = rfscreen.spectrum.RectangularSpectrum.opt(opts, ...
                'referencePlane', 'TX_ANTENNA_INPUT');
            obj.psdKind = 'ABSOLUTE_PSD';
        end

        function y = psd_WPerHz(obj, f_Hz)
            lo = obj.centerFrequency_Hz - obj.bandwidth_Hz/2;
            hi = obj.centerFrequency_Hz + obj.bandwidth_Hz/2;
            dens = obj.totalPower_W() / obj.bandwidth_Hz;   % W/Hz
            y = zeros(size(f_Hz));
            inBand = (f_Hz >= lo) & (f_Hz <= hi);
            y(inBand) = dens;
        end

        function b = supportBand_Hz(obj)
            b = [obj.centerFrequency_Hz - obj.bandwidth_Hz/2, ...
                 obj.centerFrequency_Hz + obj.bandwidth_Hz/2];
        end
        function g = nativeGrid_Hz(obj)
            g = obj.supportBand_Hz();
        end
        function p = totalPower_dBm(obj)
            p = obj.power_dBm;
        end
        function b = occupiedBandwidth_Hz(obj)
            b = obj.bandwidth_Hz;
        end
        function f = fc_Hz(obj)
            f = obj.centerFrequency_Hz;
        end
    end
    methods (Static, Access = private)
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
    end
end
