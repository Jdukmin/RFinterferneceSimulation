classdef PatternImporter
    %PATTERNIMPORTER Abstract importer boundary (§23). Reads/parses/normalizes a
    %   source and emits a CanonicalPatternCut via the shared canonicalizer.
    %   Importers MUST NOT own physics (§24): no RF risk, interference, receiver
    %   thresholds, or invented gain. Concrete subclasses override readRaw().
    methods
        function out = importCutResult(obj, policy)
            %IMPORTCUTRESULT Returns struct(cut, validation); cut is [] if INVALID.
            if nargin < 2 || isempty(policy); policy = rfscreen.config.PatternImportPolicy(); end
            [theta, gain, conv, meta] = obj.readRaw();
            out = rfscreen.patterndata.PatternCanonicalizer.canonicalize(theta, gain, conv, meta, policy);
        end

        function cut = importCut(obj, policy)
            %IMPORTCUT Convenience: returns the CanonicalPatternCut; throws on INVALID.
            if nargin < 2 || isempty(policy); policy = rfscreen.config.PatternImportPolicy(); end
            out = obj.importCutResult(policy);
            if isempty(out.cut)
                error('rfscreen:patterndata:invalidImport', ...
                    'pattern import INVALID: %s', strjoin(out.validation.issues, '; '));
            end
            cut = out.cut;
        end

        function [theta, gain, conv, meta] = readRaw(obj) %#ok<STOUT,MANU>
            error('rfscreen:patterndata:abstract', ...
                'readRaw must be implemented by a concrete PatternImporter subclass.');
        end
    end
end
