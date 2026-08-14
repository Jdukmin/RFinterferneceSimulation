classdef InstalledEnvironmentAnalyzer
    %INSTALLEDENVIRONMENTANALYZER Per-pair installed-environment evidence (ICD installed_environment.md 6).
    %   Adds evidence AROUND the existing engine; it does NOT rewrite PairwiseAnalyzer /
    %   RfCoexistenceAnalyzer / NonlinearSusceptibilityAnalyzer, and geometry NEVER
    %   changes gain/coupling (Task 38, 44). Structure-FOV is computed for TX and RX.
    methods (Static)
        function res = analyzePair(scenario, txId, rxId, opts)
            if nargin < 4 || isempty(opts); opts = struct(); end
            scenario.validate();
            IEA = rfscreen.interference.InstalledEnvironmentAnalyzer;
            policy = IEA.opt(opts, 'patternPolicy', ...
                rfscreen.installed.InstalledPatternPolicy.PREFER_INSTALLED);
            lobePolicy = IEA.opt(opts, 'lobePolicy', []);

            tx = scenario.transmitters(txId);
            rx = scenario.receivers(rxId);
            txAnt = scenario.antennas(tx.antennaId);
            rxAnt = scenario.antennas(rx.antennaId);
            txInst = scenario.installations(txAnt.installationId);
            rxInst = scenario.installations(rxAnt.installationId);
            txFree = scenario.patterns(txAnt.patternId);
            rxFree = scenario.patterns(rxAnt.patternId);

            structures = scenario.activeStructures();

            % ---- direct LOS (geometry evidence only) ----
            directLOS = rfscreen.geometry.LineOfSight.segment(txAnt.id, rxAnt.id, ...
                txInst.position_m, rxInst.position_m, structures);

            % ---- structure FOV for TX and RX (symmetric, Task 26) ----
            txFOV = IEA.structureFov(txAnt.id, txInst, structures, txFree, tx.fc_Hz, lobePolicy);
            rxFOV = IEA.structureFov(rxAnt.id, rxInst, structures, rxFree, rx.fc_Hz, lobePolicy);

            % ---- pattern selection (installed vs free-space) ----
            txInstalled = scenario.getInstalledPattern(txAnt.id, scenario.activeConfigId);
            rxInstalled = scenario.getInstalledPattern(rxAnt.id, scenario.activeConfigId);
            selTx = rfscreen.installed.InstalledPatternSelector.select(txFree, txInstalled, policy);
            selRx = rfscreen.installed.InstalledPatternSelector.select(rxFree, rxInstalled, policy);

            s = struct();
            s.txId = txId; s.rxId = rxId;
            s.directLOS = directLOS;
            s.txStructureFOV = txFOV; s.rxStructureFOV = rxFOV;
            s.txPatternSourceUsed = selTx.sourceUsed;
            s.rxPatternSourceUsed = selRx.sourceUsed;
            s.installationValidity = IEA.combineValidity(selTx.installationValidity, selRx.installationValidity);
            s.geometryRisk = IEA.geometryRisk(structures, directLOS, txFOV, rxFOV);
            s.warnings = [selTx.warnings, selRx.warnings];
            res = rfscreen.results.InstalledEnvironmentResult(s);
        end

        function sel = selectedPatternFor(scenario, antennaId, freeSpacePattern, policy)
            %SELECTEDPATTERNFOR Pattern the RF screening should use (evidence).
            if nargin < 4 || isempty(policy)
                policy = rfscreen.installed.InstalledPatternPolicy.PREFER_INSTALLED;
            end
            installed = scenario.getInstalledPattern(antennaId, scenario.activeConfigId);
            sel = rfscreen.installed.InstalledPatternSelector.select(freeSpacePattern, installed, policy);
        end
    end

    methods (Static, Access = private)
        function fovList = structureFov(antId, inst, structures, pattern, freq, lobePolicy)
            fovList = {};
            for i = 1:numel(structures)
                fovList{end+1} = rfscreen.geometry.AntennaToStructureFOV.analyze( ...
                    antId, inst.position_m, inst.R_BA, structures{i}, ...
                    struct('pattern', pattern, 'frequency_Hz', freq, 'lobePolicy', lobePolicy)); %#ok<AGROW>
            end
        end

        function v = combineValidity(a, b)
            IV = rfscreen.installed.InstallationValidity;
            if strcmp(a, IV.REQUIRE_INSTALLED_UNAVAILABLE) || strcmp(b, IV.REQUIRE_INSTALLED_UNAVAILABLE)
                v = IV.REQUIRE_INSTALLED_UNAVAILABLE;
            elseif strcmp(a, IV.INSTALLATION_EFFECT_UNKNOWN) || strcmp(b, IV.INSTALLATION_EFFECT_UNKNOWN)
                v = IV.INSTALLATION_EFFECT_UNKNOWN;
            else
                v = IV.INSTALLED_PATTERN_AVAILABLE;
            end
        end

        function r = geometryRisk(structures, directLOS, txFOV, rxFOV)
            GR = rfscreen.installed.GeometryRisk;
            if isempty(structures)
                r = GR.NA; return;
            end
            L = rfscreen.results.AntennaStructureFOVResult;  %#ok<NASGU>
            occMain = rfscreen.interference.InstalledEnvironmentAnalyzer.anyOccupies([txFOV, rxFOV], 'MAIN');
            occSide = rfscreen.interference.InstalledEnvironmentAnalyzer.anyOccupies([txFOV, rxFOV], 'SIDE');
            if occMain || directLOS.isBlocked()
                r = GR.HIGH;
            elseif occSide
                r = GR.MODERATE;
            else
                r = GR.LOW;
            end
        end

        function tf = anyOccupies(fovCell, lobe)
            tf = false;
            for i = 1:numel(fovCell)
                if fovCell{i}.occupies(lobe); tf = true; return; end
            end
        end

        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
    end
end
