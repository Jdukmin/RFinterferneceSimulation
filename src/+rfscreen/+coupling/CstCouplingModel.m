classdef CstCouplingModel < rfscreen.coupling.CouplingModel
    %CSTCOUPLINGMODEL Installed antenna-to-antenna coupling from tabulated CST S21(f) (ICD coupling.md 6).
    %   modelType = CST, validity = FULL_WAVE_COUPLING, isPhysicalCoupling = true.
    %   metric_dB = S21 (a transfer GAIN, <= 0 dB) between the two antenna ports:
    %     * ctx.band_Hz finite & wider than 0 -> reduced over that band (MEAN_POWER default, or MAX);
    %     * otherwise S21 at ctx.frequency_Hz.
    %   The absolute transfer used by the susceptibility analyzers is this S21 directly -- it
    %   already includes both antennas' installed patterns, so Gtx/Grx are NOT added again.
    %   No table / frequency outside the table => S21_UNAVAILABLE and NaN (never extrapolated,
    %   never replaced by a free-space number).
    properties (SetAccess = private)
        tables              % containers.Map 'tx|rx' -> CstS21Table
        bandReduction       % 'MEAN_POWER' | 'MAX'
        assumeReciprocal    % use the rx->tx table for tx->rx if only that exists (flagged)
    end
    methods
        function obj = CstCouplingModel(tables, opts)
            if nargin < 2 || isempty(opts); opts = struct(); end
            if isa(tables, 'rfscreen.coupling.CstS21Table'); tables = {tables}; end
            if ~iscell(tables) || isempty(tables)
                error('rfscreen:coupling:badS21', 'CstCouplingModel needs a non-empty cell array of CstS21Table.');
            end
            obj.tables = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for i = 1:numel(tables)
                t = tables{i};
                if ~isa(t, 'rfscreen.coupling.CstS21Table')
                    error('rfscreen:coupling:badS21', 'tables{%d} is not a CstS21Table.', i);
                end
                k = [t.txAntennaId '|' t.rxAntennaId];
                if obj.tables.isKey(k)
                    error('rfscreen:coupling:duplicateId', 'duplicate S21 table for %s -> %s.', t.txAntennaId, t.rxAntennaId);
                end
                obj.tables(k) = t;
            end
            obj.bandReduction = rfscreen.util.Validate.member( ...
                rfscreen.coupling.CstCouplingModel.optv(opts, 'bandReduction', 'MEAN_POWER'), {'MEAN_POWER', 'MAX'}, 'bandReduction');
            obj.assumeReciprocal = logical(rfscreen.coupling.CstCouplingModel.optv(opts, 'assumeReciprocal', true));
        end

        function result = computeCoupling(obj, ctx)
            T = rfscreen.coupling.CouplingModelType;
            Vv = rfscreen.coupling.CouplingValidity;
            name = 'S21_PortToPort_dB';
            warnings = {};
            [tbl, recip] = obj.lookup(ctx.txAntennaId, ctx.rxAntennaId);
            if isempty(tbl)
                warnings{end+1} = sprintf('no CST S21 table for %s -> %s; coupling not available', ...
                    ctx.txAntennaId, ctx.rxAntennaId);
                result = rfscreen.coupling.CouplingResult(T.CST, Vv.S21_UNAVAILABLE, NaN, name, false, warnings);
                return;
            end
            band = ctx.band_Hz;
            useBand = isnumeric(band) && numel(band) == 2 && all(isfinite(band)) && band(2) > band(1);
            if useBand
                s = tbl.bandPower_dB(band, obj.bandReduction);
                what = sprintf('%s over %.6g-%.6g GHz', obj.bandReduction, band(1)/1e9, band(2)/1e9);
            else
                s = tbl.atFrequency_dB(ctx.frequency_Hz);
                what = sprintf('at %.6g GHz', ctx.frequency_Hz/1e9);
            end
            if ~isfinite(s)
                r = tbl.range_Hz();
                warnings{end+1} = sprintf(['CST S21 table %s -> %s covers %.6g-%.6g GHz only; ' ...
                    'request %s is outside it (no extrapolation)'], ctx.txAntennaId, ctx.rxAntennaId, ...
                    r(1)/1e9, r(2)/1e9, what);
                result = rfscreen.coupling.CouplingResult(T.CST, Vv.S21_UNAVAILABLE, NaN, name, false, warnings);
                return;
            end
            warnings{end+1} = sprintf('CST S21 (%s; geometry %s; %s): %s', tbl.provenance, ...
                rfscreen.coupling.CstCouplingModel.orUnknown(tbl.geometryId), what, 'installed transfer incl. both antennas');
            if recip
                warnings{end+1} = 'reciprocity assumed: table for the reverse direction used';
            end
            result = rfscreen.coupling.CouplingResult(T.CST, Vv.FULL_WAVE_COUPLING, s, name, true, warnings);
        end

        function tf = hasPair(obj, txId, rxId)
            tf = ~isempty(obj.lookup(txId, rxId));
        end
    end
    methods (Access = private)
        function [tbl, recip] = lookup(obj, txId, rxId)
            tbl = []; recip = false;
            if isempty(txId) || isempty(rxId); return; end
            k = [txId '|' rxId];
            if obj.tables.isKey(k)
                tbl = obj.tables(k); return;
            end
            kr = [rxId '|' txId];
            if obj.assumeReciprocal && obj.tables.isKey(kr)
                tbl = obj.tables(kr); recip = true;
            end
        end
    end
    methods (Static, Access = private)
        function v = optv(o, n, d)
            if isfield(o, n) && ~isempty(o.(n)); v = o.(n); else; v = d; end
        end
        function s = orUnknown(x)
            if isempty(x); s = 'unspecified'; else; s = x; end
        end
    end
end
