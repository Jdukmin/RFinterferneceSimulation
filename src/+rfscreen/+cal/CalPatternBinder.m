classdef CalPatternBinder
    %CALPATTERNBINDER Owner binding rules: (installation, role, canonical frequency) -> CAL pattern.
    %   GPSA_1 / GPSA_2 (RX)  installed GPS_GPSA1 / GPS_GPSA2 preferred; GPS_ORIGINAL (free-space) is the
    %                         explicit fallback (warning INSTALLED_PATTERN_MISSING_FREE_SPACE_FALLBACK).
    %   SBA_NADIR / ZENITH    installed RFC_SBA_<NADIR|ZENITH>_f<tok> where provided (2.06 / 2.25 GHz);
    %                         generic free-space RFC_SBA_f<tok> at every other frequency. If an installed file
    %                         of an installed-provided frequency is absent, the free-space fallback is flagged.
    %   ISL (TX / RX)         free-space RFC_ISL_f<tok> only (no installed override).
    %   KAA_1 / KAA_2 (TX)    free-space RFC_KAA_f<tok> (reflector included); KAA as a victim is refused.
    %   Frequencies are matched exactly (canonical alias); a missing plane is INPUT_MISSING, never another band.
    properties (Constant)
        INSTALLED_PROVIDED = struct('SBA_NADIR', [2.06e9 2.25e9], 'SBA_ZENITH', [2.06e9 2.25e9], ...
            'GPSA_1', [], 'GPSA_2', [])   % [] = every frequency (GPS installed pattern is band-common)
    end
    properties (SetAccess = private)
        catalog
        roles               % containers.Map installation -> struct(family, roles, txSystem)
    end
    methods
        function b = CalPatternBinder(catalog, installationsFile)
            b.catalog = catalog;
            b.roles = containers.Map('KeyType', 'char', 'ValueType', 'any');
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(installationsFile);
            for r = 1:T.nRows
                b.roles(T.installation_id{r}) = struct('family', T.family{r}, ...
                    'roles', {strsplit(T.cal_roles{r}, ';')}, 'txSystem', T.tx_system{r});
            end
        end

        function r = roleInfo(b, installationId)
            if ~b.roles.isKey(installationId)
                error('rfscreen:cal:unknownInstallation', '%s is not in cal_installations.csv.', installationId);
            end
            r = b.roles(installationId);
        end

        function s = bind(b, installationId, role, f_Hz)
            %BIND struct: status (BOUND | INPUT_MISSING), pattern, patternType, file, fallback, warnings, reason.
            info = b.roleInfo(installationId);
            role = upper(role);
            if ~any(strcmp(info.roles, role))
                if strcmp(info.family, 'KAA') && strcmp(role, 'RX')
                    error('rfscreen:cal:kaaAttackerOnly', '%s: KAA is attacker only (owner definition); no victim binding.', installationId);
                end
                error('rfscreen:cal:roleNotAllowed', '%s has no CAL role %s.', installationId, role);
            end
            s = struct('status', 'INPUT_MISSING', 'pattern', [], 'patternType', '', 'file', '', 'fallback', false, ...
                'warnings', {{}}, 'reason', '');
            C = b.catalog;
            switch info.family
                case 'GPS'
                    p = C.find('GPS', installationId, 'INSTALLED', f_Hz);
                    if isempty(p)
                        p = C.find('GPS', '', 'FREE_SPACE', f_Hz);
                        if ~isempty(p)
                            s.fallback = true;
                            s.warnings{end+1} = sprintf(['INSTALLED_PATTERN_MISSING_FREE_SPACE_FALLBACK: %s installed pattern ' ...
                                'absent - GPS_ORIGINAL used (installation effect unknown)'], installationId);
                        end
                    end
                case 'SBA'
                    prov = b.INSTALLED_PROVIDED.(installationId);
                    p = C.find('SBA', installationId, 'INSTALLED', f_Hz);
                    if isempty(p)
                        p = C.find('SBA', '', 'FREE_SPACE', f_Hz);
                        if ~isempty(p) && any(abs(prov - f_Hz) < 1e6)
                            s.fallback = true;
                            s.warnings{end+1} = sprintf(['INSTALLED_PATTERN_MISSING_FREE_SPACE_FALLBACK: %s installed pattern ' ...
                                'at %.6g GHz absent - generic RFC_SBA used (installation effect unknown)'], installationId, f_Hz / 1e9);
                        end
                    end
                case {'ISL', 'KAA'}
                    p = C.find(info.family, '', 'FREE_SPACE', f_Hz);
                case 'SAR'
                    s.reason = 'SAR has no CST CAL pattern (owner engineering receive baseline is used by the RFI analyzer)';
                    return;
                otherwise
                    error('rfscreen:cal:unknownFamily', 'unknown family %s.', info.family);
            end
            if isempty(p)
                s.reason = sprintf('no CAL %s pattern for %s at %.6g GHz (no other frequency plane is substituted)', ...
                    info.family, installationId, f_Hz / 1e9);
                return;
            end
            s.status = 'BOUND'; s.pattern = p; s.patternType = p.patternType; s.file = p.sourceFile;
        end
    end
end
