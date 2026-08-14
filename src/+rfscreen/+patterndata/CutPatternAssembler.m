classdef CutPatternAssembler
    %CUTPATTERNASSEMBLER Bridge cuts -> Phase-1 FreeSpacePattern (ICD pattern_data.md 11).
    %   Builds a FreeSpacePattern with provenance APPROX_FROM_CUTS via a documented
    %   two-cut azimuthal-interpolation approximation (§21). The Canonical->Antenna
    %   frame map M is applied HERE ONLY (AR-106) so the source +Z boresight never
    %   leaks into the Phase-1 core. A 2D cut is never relabeled true 3D.
    methods (Static)
        function M = canonicalToAntenna()
            %CANONICALTOANTENNA Fixed map: v_antenna = M * v_source (source +Z -> antenna +X).
            M = [0 0 1; 1 0 0; 0 1 0];
        end

        function p = assembleFreeSpacePattern(patternId, xzCut, yzCut, opts)
            if nargin < 4 || isempty(opts); opts = struct(); end
            CA = rfscreen.patterndata.CutPatternAssembler;
            CA.requireCut(xzCut, 'XZ');
            CA.requireCut(yzCut, 'YZ');

            azStep = CA.opt(opts, 'azStep_deg', 2);
            elStep = CA.opt(opts, 'elStep_deg', 2);
            conf   = CA.opt(opts, 'confidence', 0.5);
            name   = CA.opt(opts, 'name', ['APPROX_FROM_CUTS_' patternId]);

            freq = CA.pickFrequency(xzCut, yzCut, opts);

            az = -180:azStep:180;
            el = -90:elStep:90;
            M = CA.canonicalToAntenna();
            Minv = M.';                      % antenna -> source
            DC = rfscreen.geometry.DirectionCalculator;

            G = zeros(numel(el), numel(az), 1);
            for ei = 1:numel(el)
                for ai = 1:numel(az)
                    d_ant = DC.azElToDirection(az(ai), el(ei));
                    d_src = Minv * d_ant;
                    theta = acosd(max(min(d_src(3), 1), -1));       % polar from +Z boresight
                    phi = mod(atan2d(d_src(2), d_src(1)), 360);     % azimuth around boresight
                    G(ei, ai, 1) = CA.reconstructGain(xzCut, yzCut, theta, phi);
                end
            end

            grid = rfscreen.antenna.PatternGrid(az, el, freq, G);
            popts = struct('confidence', conf, ...
                'polarization', CA.opt(opts, 'polarization', rfscreen.antenna.Polarization.UNKNOWN));
            p = rfscreen.antenna.FreeSpacePattern(name, ...
                rfscreen.antenna.PatternProvenance.APPROX_FROM_CUTS, grid, popts);
        end

        function g = reconstructGain(xzCut, yzCut, theta, phi)
            %RECONSTRUCTGAIN Two-cut azimuthal interpolation (documented approximation).
            gPhi0   = xzCut.evaluate(theta);              % +X half
            gPhi180 = xzCut.evaluate(mod(360 - theta, 360)); % -X half
            gPhi90  = yzCut.evaluate(theta);              % +Y half
            gPhi270 = yzCut.evaluate(mod(360 - theta, 360)); % -Y half
            phiNodes = [0 90 180 270 360];
            vals = [gPhi0 gPhi90 gPhi180 gPhi270 gPhi0];
            g = interp1(phiNodes, vals, phi, 'linear');
        end
    end

    methods (Static, Access = private)
        function requireCut(cut, plane)
            if ~isa(cut, 'rfscreen.patterndata.CanonicalPatternCut')
                error('rfscreen:patterndata:badCut', '%s cut must be a CanonicalPatternCut.', plane);
            end
            if ~strcmp(cut.plane, plane)
                error('rfscreen:patterndata:planeMismatch', ...
                    'expected a %s cut, got %s.', plane, cut.plane);
            end
        end
        function freq = pickFrequency(xzCut, yzCut, opts)
            if isfield(opts, 'frequency_Hz') && ~isempty(opts.frequency_Hz)
                freq = opts.frequency_Hz; return;
            end
            if isfinite(xzCut.frequency_Hz); freq = xzCut.frequency_Hz; return; end
            if isfinite(yzCut.frequency_Hz); freq = yzCut.frequency_Hz; return; end
            error('rfscreen:patterndata:noFrequency', ...
                ['no frequency available to assemble a pattern: provide opts.frequency_Hz or ' ...
                 'a cut with frequency_Hz (unknown is not fabricated).']);
        end
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
    end
end
