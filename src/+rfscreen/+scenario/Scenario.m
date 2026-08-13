classdef Scenario < handle
    %SCENARIO Registries + active-system selection driving one analysis (SR-100).
    %   Handle class so incremental add* calls mutate one scenario object.
    %   Enforces id uniqueness and reference integrity (SR-022, VR-064).
    properties
        name
        antennas         % containers.Map id -> Antenna
        installations    % containers.Map id -> AntennaInstallation
        patterns         % containers.Map id -> AntennaPattern
        transmitters     % containers.Map id -> RFTransmitter
        receivers        % containers.Map id -> RFReceiver
        activeTxIds      % cellstr or {} (=> all)
        activeRxIds      % cellstr or {} (=> all)
        operatingModeId
    end

    methods
        function obj = Scenario(name)
            obj.name = rfscreen.util.Validate.id(name, 'Scenario.name');
            obj.antennas      = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.installations = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.patterns      = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.transmitters  = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.receivers     = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.activeTxIds = {};
            obj.activeRxIds = {};
            obj.operatingModeId = '';
        end

        function addPattern(obj, patternId, p)
            %ADDPATTERN Register a pattern under an explicit id (the antenna's patternId).
            %   The registry key is an id, independent of the pattern's display name
            %   (ICD scenario.md 1), so two patterns may share a display name.
            rfscreen.scenario.Scenario.requireType(p, 'rfscreen.antenna.AntennaPattern', 'pattern');
            obj.putUnique(obj.patterns, patternId, p, 'pattern');
        end
        function addAntenna(obj, a)
            rfscreen.scenario.Scenario.requireType(a, 'rfscreen.antenna.Antenna', 'antenna');
            obj.putUnique(obj.antennas, a.id, a, 'antenna');
        end
        function addInstallation(obj, inst)
            rfscreen.scenario.Scenario.requireType(inst, 'rfscreen.antenna.AntennaInstallation', 'installation');
            obj.putUnique(obj.installations, inst.antennaId, inst, 'installation');
        end
        function addTransmitter(obj, tx)
            rfscreen.scenario.Scenario.requireType(tx, 'rfscreen.rf.RFTransmitter', 'transmitter');
            obj.putUnique(obj.transmitters, tx.id, tx, 'transmitter');
        end
        function addReceiver(obj, rx)
            rfscreen.scenario.Scenario.requireType(rx, 'rfscreen.rf.RFReceiver', 'receiver');
            obj.putUnique(obj.receivers, rx.id, rx, 'receiver');
        end

        function validate(obj)
            %VALIDATE Reference integrity + role consistency (ICD scenario.md 1).
            akeys = obj.antennas.keys();
            for i = 1:numel(akeys)
                a = obj.antennas(akeys{i});
                if ~obj.patterns.isKey(a.patternId)
                    error('rfscreen:scenario:badRef', ...
                        'antenna ''%s'' references missing pattern ''%s''.', a.id, a.patternId);
                end
                if ~obj.installations.isKey(a.installationId)
                    error('rfscreen:scenario:badRef', ...
                        'antenna ''%s'' references missing installation ''%s''.', a.id, a.installationId);
                end
            end
            obj.checkRfRefs(obj.transmitters, 'canTransmit', 'transmitter');
            obj.checkRfRefs(obj.receivers, 'canReceive', 'receiver');
        end

        function ids = resolveActiveTxIds(obj)
            if isempty(obj.activeTxIds); ids = obj.transmitters.keys(); else; ids = obj.activeTxIds; end
        end
        function ids = resolveActiveRxIds(obj)
            if isempty(obj.activeRxIds); ids = obj.receivers.keys(); else; ids = obj.activeRxIds; end
        end

        function in = buildPairInput(obj, txId, rxId)
            %BUILDPAIRINPUT Resolve a fully-populated pair-input struct.
            tx = obj.transmitters(txId);
            rx = obj.receivers(rxId);
            txAntenna = obj.antennas(tx.antennaId);
            rxAntenna = obj.antennas(rx.antennaId);
            in = struct();
            in.tx = tx; in.rx = rx;
            in.txAntenna = txAntenna; in.rxAntenna = rxAntenna;
            in.txInstall = obj.installations(txAntenna.installationId);
            in.rxInstall = obj.installations(rxAntenna.installationId);
            in.txPattern = obj.patterns(txAntenna.patternId);
            in.rxPattern = obj.patterns(rxAntenna.patternId);
        end
    end

    methods (Access = private)
        function putUnique(obj, map, key, val, kind) %#ok<INUSL>
            key = rfscreen.util.Validate.id(key, [kind ' id']);
            if map.isKey(key)
                error('rfscreen:scenario:duplicateId', ...
                    'duplicate %s id ''%s''.', kind, key);
            end
            map(key) = val;
        end
        function checkRfRefs(obj, map, roleFn, kind)
            keys = map.keys();
            for i = 1:numel(keys)
                r = map(keys{i});
                if ~obj.antennas.isKey(r.antennaId)
                    error('rfscreen:scenario:badRef', ...
                        '%s ''%s'' references missing antenna ''%s''.', kind, r.id, r.antennaId);
                end
                a = obj.antennas(r.antennaId);
                if ~a.(roleFn)()
                    error('rfscreen:scenario:badRole', ...
                        '%s ''%s'' uses antenna ''%s'' whose role ''%s'' cannot %s.', ...
                        kind, r.id, a.id, a.role, kind);
                end
            end
        end
    end

    methods (Static, Access = private)
        function requireType(obj, cls, kind)
            if ~isa(obj, cls)
                error('rfscreen:scenario:badType', '%s must be a %s.', kind, cls);
            end
        end
    end
end
