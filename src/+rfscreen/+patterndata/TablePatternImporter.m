classdef TablePatternImporter < rfscreen.patterndata.PatternImporter
    %TABLEPATTERNIMPORTER Import a cut from in-memory theta/gain arrays (§23).
    properties (SetAccess = private)
        theta
        gain
        conv
        meta
    end
    methods
        function obj = TablePatternImporter(theta, gain, conv, meta)
            if nargin < 4 || isempty(meta); meta = struct(); end
            obj.theta = theta;
            obj.gain = gain;
            if ~isa(conv, 'rfscreen.patterndata.SourceCoordinateConvention')
                error('rfscreen:patterndata:badConvention', ...
                    'conv must be a rfscreen.patterndata.SourceCoordinateConvention.');
            end
            obj.conv = conv;
            if ~isfield(meta, 'sourceType') || isempty(meta.sourceType)
                meta.sourceType = 'TABLE';
            end
            obj.meta = meta;
        end

        function [theta, gain, conv, meta] = readRaw(obj)
            theta = obj.theta; gain = obj.gain; conv = obj.conv; meta = obj.meta;
        end
    end
end
