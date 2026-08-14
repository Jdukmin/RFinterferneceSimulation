classdef SpectralCouplingAnalyzer
    %SPECTRALCOUPLINGANALYZER Integrate TX PSD against RX filter, in LINEAR units,
    %   over a deterministic union grid (ICD receiver_susceptibility.md 5).
    %   NO geometry, NO absolute power. dB values are never integrated directly.
    methods (Static)
        function r = analyze(spectrum, filter, opts)
            if nargin < 3 || isempty(opts); opts = struct(); end
            if ~isa(spectrum, 'rfscreen.spectrum.SpectrumModel')
                error('rfscreen:interference:badSpectrum', 'spectrum must be a SpectrumModel.');
            end
            if ~isa(filter, 'rfscreen.receiver.ReceiverFilter')
                error('rfscreen:interference:badFilter', 'filter must be a ReceiverFilter.');
            end
            warnings = {};

            domain = spectrum.supportBand_Hz();      % PSD is 0 outside -> no contribution
            lo = domain(1); hi = domain(2);

            % union of breakpoints within the domain
            fb = filter.nativeGrid_Hz();
            rb = filter.relevantBand_Hz();
            sg = spectrum.nativeGrid_Hz();
            nodes = [lo, hi, fb, rb, sg];
            nodes = nodes(nodes >= lo & nodes <= hi);
            if isfield(opts, 'maxStep_Hz') && ~isempty(opts.maxStep_Hz) && opts.maxStep_Hz > 0
                nodes = [nodes, lo:opts.maxStep_Hz:hi];
            end
            nodes = unique(nodes);
            if numel(nodes) < 2
                r = rfscreen.interference.SpectralCouplingAnalyzer.emptyResult(spectrum, ...
                    'degenerate integration domain');
                return;
            end

            % midpoint-rule linear integration: sum psd_W(mid) * H_lin(mid) * df
            overlapPower_W = 0;
            for i = 1:numel(nodes)-1
                a = nodes(i); c = nodes(i+1); m = 0.5*(a+c); df = c - a;
                psd = spectrum.psd_WPerHz(m);          % W/Hz (linear)
                hlin = filter.responseLinear(m);       % linear power ratio
                overlapPower_W = overlapPower_W + psd * hlin * df;
            end

            Ptot_W = spectrum.totalPower_W();
            fraction = overlapPower_W / Ptot_W;
            if fraction <= 0
                warnings{end+1} = 'no spectral overlap (fraction = 0)';
                spectralFactor_dB = -Inf;
            else
                spectralFactor_dB = 10 * log10(fraction);
            end

            r = struct();
            r.overlapPower_W = overlapPower_W;
            r.overlapFraction = fraction;
            r.spectralFactor_dB = spectralFactor_dB;
            r.nGrid = numel(nodes);
            r.domain_Hz = [lo hi];
            r.txReferencePlane = spectrum.referencePlane;
            r.validity = 'VALID';
            r.warnings = warnings;
        end
    end

    methods (Static, Access = private)
        function r = emptyResult(spectrum, why)
            r = struct('overlapPower_W', 0, 'overlapFraction', 0, 'spectralFactor_dB', -Inf, ...
                'nGrid', 0, 'domain_Hz', spectrum.supportBand_Hz(), ...
                'txReferencePlane', spectrum.referencePlane, 'validity', 'DEGENERATE', ...
                'warnings', {{why}});
        end
    end
end
