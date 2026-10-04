classdef FarFieldCouplingModel < rfscreen.coupling.CouplingModel
    %FARFIELDCOUPLINGMODEL Guarded far-field (Friis) coupling (SR-083, AR-053).
    %   FSPL is applied ONLY when far-field validity is established from both
    %   apertures' largest dimension and the separation (Fraunhofer 2*D^2/lambda).
    %   Otherwise NO FSPL is applied (near-field caution, SR-081, rule 6): the
    %   result is FAR_FIELD_INVALID_OR_UNKNOWN with metric_dB = NaN.
    properties (SetAccess = private)
        minWavelengths   % require distance >= this many wavelengths as well
        assumeFreeSpace  % true: apply Friis even when far-field is NOT verified (flagged FREE_SPACE_ASSUMED)
    end
    methods
        function obj = FarFieldCouplingModel(minWavelengths, opts)
            %FARFIELDCOUPLINGMODEL opts.assumeFreeSpace (default false = guarded, unchanged behaviour):
            %   an explicit owner decision to use free-space propagation where the far-field
            %   condition cannot be verified (e.g. X-band / Ka on a 6 m vehicle). The result is
            %   then validity = FREE_SPACE_ASSUMED with an explicit warning -- never FAR_FIELD_VALID.
            if nargin < 1 || isempty(minWavelengths); minWavelengths = 5; end
            if nargin < 2 || isempty(opts); opts = struct(); end
            obj.minWavelengths = rfscreen.util.Validate.nonnegativeScalar( ...
                minWavelengths, 'minWavelengths');
            obj.assumeFreeSpace = isfield(opts, 'assumeFreeSpace') && logical(opts.assumeFreeSpace);
        end

        function result = computeCoupling(obj, ctx)
            T  = rfscreen.coupling.CouplingModelType;
            Vv = rfscreen.coupling.CouplingValidity;
            warnings = {};

            lambda = rfscreen.util.Units.wavelength_m(ctx.frequency_Hz);
            knownDims = isfinite(ctx.txMaxDim_m) && isfinite(ctx.rxMaxDim_m);
            valid = false;
            if knownDims && isfinite(ctx.distance_m) && ctx.distance_m > 0
                Rff_tx = 2 * ctx.txMaxDim_m^2 / lambda;
                Rff_rx = 2 * ctx.rxMaxDim_m^2 / lambda;
                valid = (ctx.distance_m >= max(Rff_tx, Rff_rx)) && ...
                        (ctx.distance_m >= obj.minWavelengths * lambda);
            end

            if ~valid && obj.assumeFreeSpace && isfinite(ctx.distance_m) && ctx.distance_m > 0 ...
                    && isfinite(ctx.frequency_Hz) && ctx.frequency_Hz > 0
                if ~knownDims
                    why = 'aperture dimensions unknown';
                else
                    why = 'separation below far-field (Fraunhofer) distance';
                end
                warnings{end+1} = sprintf(['%s: free-space (Friis) propagation applied by explicit ' ...
                    'assumption; far-field NOT verified, level is an estimate'], why);
                fspl_dB = 20 * log10(4 * pi * ctx.distance_m / lambda);
                result = rfscreen.coupling.CouplingResult( ...
                    T.FAR_FIELD, Vv.FREE_SPACE_ASSUMED, fspl_dB, ...
                    'FreeSpacePathLoss_dB', true, warnings);
                return;
            end

            if ~valid
                if ~knownDims
                    warnings{end+1} = 'aperture dimensions unknown; far-field not verified; FSPL not applied';
                else
                    warnings{end+1} = 'separation below far-field (Fraunhofer) distance; FSPL not applied';
                end
                result = rfscreen.coupling.CouplingResult( ...
                    T.FAR_FIELD, Vv.FAR_FIELD_INVALID_OR_UNKNOWN, NaN, ...
                    'FreeSpacePathLoss_dB', false, warnings);
                return;
            end

            fspl_dB = 20 * log10(4 * pi * ctx.distance_m / lambda);
            result = rfscreen.coupling.CouplingResult( ...
                T.FAR_FIELD, Vv.FAR_FIELD_VALID, fspl_dB, ...
                'FreeSpacePathLoss_dB', true, warnings);
        end
    end
end
