classdef RFFrontEnd
    %RFFRONTEND Reserved receiver front-end susceptibility layer (SR-072, R8).
    %   Distinct from antenna coupling (SR-073). Phase 1 STORES these values;
    %   nonlinear computations (blocking via P1dB, IM3 via IIP3) are reserved.
    %   Unknown values are NaN/empty -- NEVER invented (DR-052, SR-120).
    properties (SetAccess = private)
        filterPassband_Hz   % [lo hi] or []
        p1dB_dBm            % NaN if unknown
        iip3_dBm            % NaN if unknown
        noiseFigure_dB      % NaN if unknown
        sensitivity_dBm     % NaN if unknown
    end

    methods
        function obj = RFFrontEnd(opts)
            if nargin < 1 || isempty(opts); opts = struct(); end
            obj.filterPassband_Hz = rfscreen.rf.RFFrontEnd.getPassband(opts);
            obj.p1dB_dBm        = rfscreen.rf.RFFrontEnd.getScalarOrNaN(opts, 'p1dB_dBm');
            obj.iip3_dBm        = rfscreen.rf.RFFrontEnd.getScalarOrNaN(opts, 'iip3_dBm');
            obj.noiseFigure_dB  = rfscreen.rf.RFFrontEnd.getScalarOrNaN(opts, 'noiseFigure_dB');
            obj.sensitivity_dBm = rfscreen.rf.RFFrontEnd.getScalarOrNaN(opts, 'sensitivity_dBm');
            if ~isempty(obj.noiseFigure_dB) && ~isnan(obj.noiseFigure_dB) && obj.noiseFigure_dB < 0
                error('rfscreen:rf:badNoiseFigure', 'noiseFigure_dB must be >= 0.');
            end
        end

        function tf = hasFilter(obj)
            tf = ~isempty(obj.filterPassband_Hz);
        end
    end

    methods (Static, Access = private)
        function v = getScalarOrNaN(opts, name)
            if isfield(opts, name) && ~isempty(opts.(name))
                v = rfscreen.util.Validate.finiteScalar(opts.(name), name);
            else
                v = NaN;
            end
        end
        function pb = getPassband(opts)
            if isfield(opts, 'filterPassband_Hz') && ~isempty(opts.filterPassband_Hz)
                pb = opts.filterPassband_Hz;
                if ~(isnumeric(pb) && numel(pb) == 2 && all(isfinite(pb)) && pb(1) < pb(2) && pb(1) > 0)
                    error('rfscreen:rf:badPassband', ...
                        'filterPassband_Hz must be [lo hi] with 0 < lo < hi.');
                end
                pb = double(pb(:)).';
            else
                pb = [];
            end
        end
    end
end
