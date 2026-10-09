classdef CalPatternBinder
    %CALPATTERNBINDER Owner binding rules for CAL RFI: (installation, role, canonical frequency) -> CAL pattern.
    %   Owner rule: EVERY attacker and victim uses its ORIGIN (free-space) CST pattern. Installed CST patterns
    %   (GPSA_GPSA1/2, RFC_SBA_NADIR/ZENITH) are NOT used for RFI (owner rationale: a far-field -> near-field 10 dB
    %   margin is held, so the installed pattern adds nothing); they are ingested for the installed figures only.
    %   GPSA_1 / GPSA_2 (RX)  GPSA_ORIGINAL_f1.2 (one CST solve, surrogate at L5 / L2 / L1)
    %   SBA_NADIR / ZENITH    RFC_SBA_f<tok> at every frequency (2.06 / 2.25 GHz included)
    %   ISL (TX / RX)         RFC_ISL_f<tok>
    %   KAA_1 / KAA_2 (TX)    RFC_KAA_f<tok> (reflector included); KAA as a victim is refused.
    %   Frequencies are matched exactly (canonical alias); a missing plane is INPUT_MISSING, never another band
    %   and never an installed pattern.
    properties (Constant)
        RFI_PATTERN_TYPE = 'FREE_SPACE'
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
                case {'GPS', 'SBA', 'ISL', 'KAA'}
                    p = C.find(info.family, '', b.RFI_PATTERN_TYPE, f_Hz);
                case 'SAR'
                    s.reason = 'SAR has no CST CAL pattern (owner engineering receive baseline is used by the RFI analyzer)';
                    return;
                otherwise
                    error('rfscreen:cal:unknownFamily', 'unknown family %s.', info.family);
            end
            if isempty(p)
                [~, want] = C.find(info.family, '', b.RFI_PATTERN_TYPE, f_Hz);
                have = C.patterns.keys();
                have = have(strncmp(have, [info.family '|'], numel(info.family) + 1));
                if isempty(have); have = {'<none>'}; end
                s.reason = sprintf(['no CAL %s origin (free-space) pattern for %s at %.6g GHz (no other frequency plane ' ...
                    'and no installed pattern is substituted); requested key %s; catalog %s keys: %s'], info.family, ...
                    installationId, f_Hz / 1e9, want, info.family, strjoin(have, ' '));
                return;
            end
            s.status = 'BOUND'; s.pattern = p; s.patternType = p.patternType; s.file = p.sourceFile;
        end
    end
end
