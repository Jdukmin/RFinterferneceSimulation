classdef InstalledEnvironmentResult
    %INSTALLEDENVIRONMENTRESULT Per-pair installed-environment evidence (ICD installed_environment.md 6).
    %   Separate from physical coupling evidence; geometry never changes gain.
    properties
        txId = ''
        rxId = ''
        directLOS = []              % results.LineOfSightResult
        txStructureFOV = {}         % cell of results.AntennaStructureFOVResult
        rxStructureFOV = {}         % cell of results.AntennaStructureFOVResult
        txPatternSourceUsed = ''
        rxPatternSourceUsed = ''
        installationValidity = ''
        geometryRisk = ''
        warnings = {}
    end
    methods
        function obj = InstalledEnvironmentResult(s)
            if nargin >= 1 && ~isempty(s) && isstruct(s)
                f = fieldnames(s);
                for i = 1:numel(f); if isprop(obj, f{i}); obj.(f{i}) = s.(f{i}); end; end
            end
        end
    end
end
