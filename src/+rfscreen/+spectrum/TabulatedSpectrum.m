classdef TabulatedSpectrum < rfscreen.spectrum.SpectrumModel
    %TABULATEDSPECTRUM Piecewise-linear PSD from a grid + shape (ICD spectrum.md 6).
    %   Shape (LINEAR relative density, or DB linearized) is normalized so that
    %   trapz(PSD_W) = P_total_W. dB shapes are linearized BEFORE integration.
    properties (SetAccess = private)
        freq_Hz
        psd_stored_WPerHz   % normalized absolute PSD on freq grid
        power_dBm
    end
    methods
        function obj = TabulatedSpectrum(freq_Hz, shape, totalPower_dBm, opts)
            if nargin < 4 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            f = V.monotonicVector(freq_Hz, 'freq_Hz');
            if any(f <= 0)
                error('rfscreen:spectrum:badFreq', 'freq_Hz must be > 0.');
            end
            shape = shape(:).';
            if numel(shape) ~= numel(f)
                error('rfscreen:spectrum:shapeShape', 'shape and freq_Hz length mismatch.');
            end
            if any(~isfinite(shape))
                error('rfscreen:spectrum:shapeFinite', 'shape must be finite.');
            end
            obj.power_dBm = V.finiteScalar(totalPower_dBm, 'totalPower_dBm');

            shapeUnit = rfscreen.spectrum.TabulatedSpectrum.opt(opts, 'shapeUnit', 'LINEAR');
            V.member(shapeUnit, {'LINEAR', 'DB'}, 'shapeUnit');
            if strcmp(shapeUnit, 'DB')
                shapeLin = 10.^(shape/10);        % linearize BEFORE integrating
            else
                if any(shape < 0)
                    error('rfscreen:spectrum:negShape', 'LINEAR shape must be >= 0.');
                end
                shapeLin = shape;
            end
            if numel(f) < 2
                error('rfscreen:spectrum:tooFewPoints', 'need >= 2 frequency points.');
            end
            area = trapz(f, shapeLin);
            if area <= 0
                error('rfscreen:spectrum:zeroArea', 'shape integrates to zero area.');
            end
            scale = obj.totalPower_W() / area;
            obj.freq_Hz = f;
            obj.psd_stored_WPerHz = shapeLin * scale;

            obj.provenance = V.member( ...
                rfscreen.spectrum.TabulatedSpectrum.opt(opts, 'provenance', ...
                    rfscreen.spectrum.SpectrumProvenance.SYNTHETIC_TEST), ...
                rfscreen.spectrum.SpectrumProvenance.values(), 'provenance');
            obj.referencePlane = rfscreen.spectrum.TabulatedSpectrum.opt(opts, ...
                'referencePlane', 'TX_ANTENNA_INPUT');
            obj.psdKind = 'ABSOLUTE_PSD';
        end

        function y = psd_WPerHz(obj, f_Hz)
            y = interp1(obj.freq_Hz, obj.psd_stored_WPerHz, f_Hz, 'linear', 0);
        end
        function b = supportBand_Hz(obj)
            b = [obj.freq_Hz(1), obj.freq_Hz(end)];
        end
        function g = nativeGrid_Hz(obj)
            g = obj.freq_Hz;
        end
        function p = totalPower_dBm(obj)
            p = obj.power_dBm;
        end
        function b = occupiedBandwidth_Hz(obj)
            b = obj.freq_Hz(end) - obj.freq_Hz(1);
        end
        function f = fc_Hz(obj)
            f = 0.5 * (obj.freq_Hz(1) + obj.freq_Hz(end));
        end
    end
    methods (Static, Access = private)
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
    end
end
