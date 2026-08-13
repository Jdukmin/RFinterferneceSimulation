function test_multisystem(h)
%TEST_MULTISYSTEM N TX x M RX pair generation, matrix dims, self-pair NA
%   (VR-050, VR-051, AR-070, AR-073).
    h.setGroup('multisystem');

    Role = rfscreen.antenna.Role; Pol = rfscreen.antenna.Polarization;
    SP = rfscreen.antenna.SyntheticPatternFactory;

    % ---- 2 TX x 3 RX, all distinct antennas ----
    sc = rfscreen.scenario.Scenario('MULTI');
    sc.addPattern('P', SP.isotropic(3, 2.2e9));
    positions = { [0;0;0], [5;0;0], [0;5;0], [0;0;5], [5;5;5] };
    ids = {'A1','A2','A3','A4','A5'};
    for i = 1:5
        sc.addAntenna(rfscreen.antenna.Antenna(ids{i}, ids{i}, Role.TXRX, 1e9, 4e9, Pol.RHCP, 'P', ids{i}));
        sc.addInstallation(rfscreen.antenna.AntennaInstallation(ids{i}, positions{i}, eye(3)));
    end
    sc.addTransmitter(rfscreen.rf.RFTransmitter('TX1', 'A1', 2.2e9, 20e6, 30));
    sc.addTransmitter(rfscreen.rf.RFTransmitter('TX2', 'A2', 2.2e9, 20e6, 30));
    sc.addReceiver(rfscreen.rf.RFReceiver('RX1', 'A3', 2.2e9, 20e6));
    sc.addReceiver(rfscreen.rf.RFReceiver('RX2', 'A4', 2.2e9, 20e6));
    sc.addReceiver(rfscreen.rf.RFReceiver('RX3', 'A5', 2.2e9, 20e6));

    mr = rfscreen.interference.InterferenceAnalyzer.analyze(sc);
    h.ok('matrix 2 tx rows', numel(mr.txIds) == 2);
    h.ok('matrix 3 rx cols', numel(mr.rxIds) == 3);

    count = 0;
    for i = 1:numel(mr.txIds)
        for j = 1:numel(mr.rxIds)
            pr = mr.pairs{i, j};
            if ~isempty(pr) && ~isempty(pr.riskLevel)
                count = count + 1;
            end
        end
    end
    h.ok('N*M = 6 pairs generated', count == 6);

    % ---- self-pair NA: TXRX antenna shared by a TX and an RX ----
    sc2 = rfscreen.scenario.Scenario('SELFPAIR');
    sc2.addPattern('P', SP.isotropic(3, 2.2e9));
    for i = 1:2
        id = sprintf('ANT%d', i);
        sc2.addAntenna(rfscreen.antenna.Antenna(id, id, Role.TXRX, 1e9, 4e9, Pol.RHCP, 'P', id));
        sc2.addInstallation(rfscreen.antenna.AntennaInstallation(id, positions{i}, eye(3)));
    end
    sc2.addTransmitter(rfscreen.rf.RFTransmitter('TA', 'ANT1', 2.2e9, 20e6, 30));
    sc2.addTransmitter(rfscreen.rf.RFTransmitter('TB', 'ANT2', 2.2e9, 20e6, 30));
    sc2.addReceiver(rfscreen.rf.RFReceiver('RA', 'ANT1', 2.2e9, 20e6));
    sc2.addReceiver(rfscreen.rf.RFReceiver('RB', 'ANT2', 2.2e9, 20e6));
    mr2 = rfscreen.interference.InterferenceAnalyzer.analyze(sc2);

    % (TA,RA) share ANT1 -> NA ; (TB,RB) share ANT2 -> NA
    h.eqStr('self-pair TA/RA is NA', mr2.riskOf('TA', 'RA'), 'NA');
    h.eqStr('self-pair TB/RB is NA', mr2.riskOf('TB', 'RB'), 'NA');
    h.isFalse('cross-pair TA/RB not NA', strcmp(mr2.riskOf('TA', 'RB'), 'NA'));
end
