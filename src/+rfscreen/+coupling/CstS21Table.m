classdef CstS21Table
    %CSTS21TABLE Tabulated port-to-port S21(f) between two antenna ports (ICD coupling.md 6).
    %   Frequency-dependent, installed (on-spacecraft) coupling from a full-wave solver
    %   export. |S21| already contains both antennas' installed patterns, mismatch and the
    %   structure, so it is used AS the absolute transfer (never combined with Gtx/Grx).
    %   Passive: |S21| must not exceed 0 dB (small numerical tolerance). No extrapolation:
    %   outside the tabulated range the value is unknown (NaN), never held constant.
    properties (SetAccess = private)
        txAntennaId
        rxAntennaId
        freq_Hz         % 1xn strictly increasing
        s21_dB          % 1xn  20*log10|S21|
        phase_deg       % 1xn or NaN(1,n) if not exported
        provenance      % e.g. CST_FULLWAVE | SYNTHETIC_TEST
        geometryId      % model/configuration the table belongs to
        sourceFile
        referenceImpedance_ohm
    end
    properties (Constant)
        PASSIVE_TOL_DB = 1e-3
    end
    methods
        function obj = CstS21Table(txAntennaId, rxAntennaId, freq_Hz, s21_dB, opts)
            if nargin < 5 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            obj.txAntennaId = V.id(txAntennaId, 'txAntennaId');
            obj.rxAntennaId = V.id(rxAntennaId, 'rxAntennaId');
            if strcmp(obj.txAntennaId, obj.rxAntennaId)
                error('rfscreen:coupling:badS21', 'S21 table needs two different antennas (self coupling is S11).');
            end
            obj.freq_Hz = V.monotonicVector(freq_Hz, 'freq_Hz');
            if obj.freq_Hz(1) <= 0
                error('rfscreen:coupling:badS21', 'freq_Hz must be > 0.');
            end
            s = double(s21_dB(:)).';
            if numel(s) ~= numel(obj.freq_Hz) || any(~isfinite(s))
                error('rfscreen:coupling:badS21', 's21_dB must be finite and match freq_Hz.');
            end
            if max(s) > rfscreen.coupling.CstS21Table.PASSIVE_TOL_DB
                error('rfscreen:coupling:activeS21', ...
                    'S21 > 0 dB (max %.4g dB): a passive antenna-to-antenna coupling cannot gain.', max(s));
            end
            obj.s21_dB = s;
            if isfield(opts, 'phase_deg') && ~isempty(opts.phase_deg)
                ph = double(opts.phase_deg(:)).';
                if numel(ph) ~= numel(s); error('rfscreen:coupling:badS21', 'phase_deg must match freq_Hz.'); end
                obj.phase_deg = ph;
            else
                obj.phase_deg = NaN(1, numel(s));
            end
            obj.provenance = rfscreen.coupling.CstS21Table.optChar(opts, 'provenance', 'UNKNOWN');
            obj.geometryId = rfscreen.coupling.CstS21Table.optChar(opts, 'geometryId', '');
            obj.sourceFile = rfscreen.coupling.CstS21Table.optChar(opts, 'sourceFile', '');
            obj.referenceImpedance_ohm = rfscreen.coupling.CstS21Table.optNum(opts, 'referenceImpedance_ohm', 50);
        end

        function r = range_Hz(obj)
            r = [obj.freq_Hz(1) obj.freq_Hz(end)];
        end
        function tf = coversBand(obj, band_Hz)
            r = obj.range_Hz();
            tf = band_Hz(1) >= r(1) && band_Hz(2) <= r(2);
        end

        function s = atFrequency_dB(obj, f_Hz)
            %ATFREQUENCY_DB Linear-in-dB interpolation; NaN outside the tabulated range.
            s = NaN;
            r = obj.range_Hz();
            if f_Hz < r(1) || f_Hz > r(2); return; end
            if numel(obj.freq_Hz) == 1; s = obj.s21_dB(1); return; end
            s = interp1(obj.freq_Hz, obj.s21_dB, f_Hz, 'linear');
        end

        function s = bandPower_dB(obj, band_Hz, reduction)
            %BANDPOWER_DB Reduce S21 over [lo hi]: 'MEAN_POWER' (flat-PSD average of |S21|^2,
            %   trapezoid on the tabulated grid + interpolated band edges) or 'MAX' (worst point).
            %   NaN unless the table covers the whole band.
            if nargin < 3 || isempty(reduction); reduction = 'MEAN_POWER'; end
            s = NaN;
            if ~obj.coversBand(band_Hz); return; end
            lo = band_Hz(1); hi = band_Hz(2);
            if hi <= lo
                s = obj.atFrequency_dB(lo); return;
            end
            inside = obj.freq_Hz(obj.freq_Hz > lo & obj.freq_Hz < hi);
            f = [lo, inside, hi];
            if numel(obj.freq_Hz) == 1
                d = obj.s21_dB(1) * ones(size(f));
            else
                d = interp1(obj.freq_Hz, obj.s21_dB, f, 'linear');
            end
            switch reduction
                case 'MAX'
                    s = max(d);
                case 'MEAN_POWER'
                    p = 10.^(d / 10);
                    s = 10 * log10(trapz(f, p) / (hi - lo));
                otherwise
                    error('rfscreen:coupling:badReduction', 'reduction must be MEAN_POWER or MAX.');
            end
        end
    end
    methods (Static, Access = private)
        function v = optChar(o, n, d)
            if isfield(o, n) && ~isempty(o.(n)); v = o.(n); else; v = d; end
        end
        function v = optNum(o, n, d)
            if isfield(o, n) && ~isempty(o.(n)); v = double(o.(n)); else; v = d; end
        end
    end
end
