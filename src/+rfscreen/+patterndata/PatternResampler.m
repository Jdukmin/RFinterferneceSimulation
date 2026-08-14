classdef PatternResampler
    %PATTERNRESAMPLER Resample a canonical cut onto a requested theta grid (§19).
    %   Separate from importer/validator/pattern. Native-grid preservation is
    %   mandatory: the source cut is NOT mutated; a NEW cut is returned with
    %   provenance.resamplingApplied = true (DR-109).
    methods (Static)
        function newCut = resample(cut, thetaGrid_deg, policy)
            if nargin < 3 || isempty(policy); policy = rfscreen.config.PatternImportPolicy(); end
            if ~isa(cut, 'rfscreen.patterndata.CanonicalPatternCut')
                error('rfscreen:patterndata:badCut', 'cut must be a CanonicalPatternCut.');
            end
            grid = sort(unique(mod(thetaGrid_deg(:).', 360)));
            if numel(grid) < 1
                error('rfscreen:patterndata:badGrid', 'thetaGrid_deg is empty.');
            end
            g = zeros(1, numel(grid));
            for i = 1:numel(grid)
                g(i) = cut.evaluate(grid(i));   % periodic interpolation on native grid
            end

            s = cut.toStruct();
            s.theta_deg = grid;
            s.gain_dBi = g;
            [s.samplingType, s.nominalStep_deg] = ...
                rfscreen.patterndata.PatternCanonicalizer.classifySampling(grid, policy);

            prov = s.provenance;
            prov.resamplingApplied = true;
            prov.resampleFrom = struct('theta_deg', cut.theta_deg, 'nSource', cut.numSamples());
            s.provenance = prov;

            s.warnings = [s.warnings, {'resampled to a requested grid (native cut preserved separately)'}];
            newCut = rfscreen.patterndata.CanonicalPatternCut(s);
        end
    end
end
