classdef AntennaPattern
    %ANTENNAPATTERN Canonical antenna-pattern abstraction (SR-050, ICD antenna.md 3).
    %   Base contract: gain_dBi = evaluate(frequency_Hz, az_deg, el_deg[, policy]).
    %   Concrete subclasses: FreeSpacePattern, InstalledPattern. The two remain
    %   distinct classes (VR-084). This base holds shared metadata + the tabulated
    %   grid and implements the evaluation contract by delegating to PatternGrid.
    %
    %   Do not instantiate AntennaPattern directly for analysis; use a subclass so
    %   free-space vs installed provenance is always explicit.
    properties (SetAccess = private)
        name
        provenance          % PatternProvenance char
        confidence          % [0,1]
        polarization        % Polarization char
        grid                % rfscreen.antenna.PatternGrid
        % Reserved optional channels (empty in Phase 1 unless supplied):
        axialRatio_dB
        phase_deg
        crossPolGain_dBi
    end

    methods
        function obj = AntennaPattern(name, provenance, grid, opts)
            if nargin < 4 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            obj.name = V.id(name, 'pattern.name');
            obj.provenance = V.member(provenance, ...
                rfscreen.antenna.PatternProvenance.values(), 'pattern.provenance');
            if ~isa(grid, 'rfscreen.antenna.PatternGrid')
                error('rfscreen:pattern:badGrid', 'grid must be a rfscreen.antenna.PatternGrid.');
            end
            obj.grid = grid;

            obj.confidence      = rfscreen.antenna.AntennaPattern.optField(opts, 'confidence', 1.0);
            obj.polarization    = rfscreen.antenna.AntennaPattern.optField(opts, 'polarization', ...
                                    rfscreen.antenna.Polarization.UNKNOWN);
            obj.axialRatio_dB   = rfscreen.antenna.AntennaPattern.optField(opts, 'axialRatio_dB', []);
            obj.phase_deg       = rfscreen.antenna.AntennaPattern.optField(opts, 'phase_deg', []);
            obj.crossPolGain_dBi= rfscreen.antenna.AntennaPattern.optField(opts, 'crossPolGain_dBi', []);

            if ~rfscreen.antenna.Polarization.isValid(obj.polarization)
                error('rfscreen:pattern:badPolarization', 'invalid polarization.');
            end
            if ~(isscalar(obj.confidence) && obj.confidence >= 0 && obj.confidence <= 1) ...
                    && ~isnan(obj.confidence)
                error('rfscreen:pattern:badConfidence', 'confidence must be in [0,1] or NaN.');
            end
        end

        function gain_dBi = evaluate(obj, frequency_Hz, az_deg, el_deg, policy)
            %EVALUATE Directional gain [dBi] (delegates to the tabulated grid).
            if nargin < 5; policy = []; end
            gain_dBi = obj.grid.evaluate(frequency_Hz, az_deg, el_deg, policy);
        end

        function [gain_dBi, info] = evaluateWithInfo(obj, frequency_Hz, az_deg, el_deg, policy)
            %EVALUATEWITHINFO Gain plus domain/boundary info struct (AR-081).
            if nargin < 5; policy = []; end
            [gain_dBi, info] = obj.grid.evaluate(frequency_Hz, az_deg, el_deg, policy);
        end

        function tf = isSyntheticTest(obj)
            tf = rfscreen.antenna.PatternProvenance.isSyntheticTest(obj.provenance);
        end

        function tf = isInstalled(obj) %#ok<MANU>
            %ISINSTALLED False for the base/free-space; overridden by InstalledPattern.
            tf = false;
        end

        function s = patternClass(obj) %#ok<MANU>
            s = 'AntennaPattern';
        end
    end

    methods (Static, Access = protected)
        function v = optField(opts, name, default)
            if isstruct(opts) && isfield(opts, name) && ~isempty(opts.(name))
                v = opts.(name);
            else
                v = default;
            end
        end
    end
end
