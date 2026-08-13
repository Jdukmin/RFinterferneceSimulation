function demo_screening()
%DEMO_SCREENING Minimal end-to-end demo (SYNTHETIC_TEST data only; NO UI).
%   Builds a small synthetic scenario, runs the pattern-only screening engine,
%   and prints the interference matrix to the console. This uses ONLY synthetic
%   test patterns (provenance = SYNTHETIC_TEST); it contains no mission/reference
%   antenna data. Run `setup_paths` first (this demo does it for you).
    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here), 'src'));

    SP = rfscreen.antenna.SyntheticPatternFactory;
    Role = rfscreen.antenna.Role;
    Pol  = rfscreen.antenna.Polarization;

    sc = rfscreen.scenario.Scenario('DEMO_SYNTHETIC_TEST');
    sc.addPattern('DIR', SP.cosineDirectional(15, 2.2e9, 2));
    sc.addPattern('WIDE', SP.cosineDirectional(6, 2.2e9, 1));

    % Three antennas on a small bus, various boresights.
    F = @(b) rbaFromBoresight(b);
    defs = { 'A1', 'DIR',  [0;0;0],   [1;0;0];
             'A2', 'WIDE', [0.8;0;0], [-1;0;0];
             'A3', 'DIR',  [0;0.6;0], [0;1;0] };
    for i = 1:size(defs, 1)
        id = defs{i,1};
        sc.addAntenna(rfscreen.antenna.Antenna(id, id, Role.TXRX, 1e9, 4e9, ...
            Pol.RHCP, defs{i,2}, id));
        sc.addInstallation(rfscreen.antenna.AntennaInstallation(id, defs{i,3}, F(defs{i,4})));
    end

    % Two transmitters and two receivers (in-band pair + adjacent pair).
    sc.addTransmitter(rfscreen.rf.RFTransmitter('TX_A1', 'A1', 2.2e9, 20e6, 33));
    sc.addTransmitter(rfscreen.rf.RFTransmitter('TX_A3', 'A3', 2.21e9, 20e6, 30));
    sc.addReceiver(rfscreen.rf.RFReceiver('RX_A2', 'A2', 2.2e9, 20e6, ...
        struct('interferenceThreshold_dBm', -70)));
    sc.addReceiver(rfscreen.rf.RFReceiver('RX_A3', 'A3', 2.5e9, 20e6));

    mr = rfscreen.interference.InterferenceAnalyzer.analyze(sc);
    printMatrix(mr);
end

function printMatrix(mr)
    fprintf('\nInterference screening matrix — scenario "%s" (coupling: %s)\n', ...
        mr.scenarioName, mr.couplingModelType);
    header = sprintf('%-10s', 'TX \\ RX');
    for j = 1:numel(mr.rxIds); header = [header, sprintf('%-10s', mr.rxIds{j})]; end
    fprintf('%s\n', header);
    for i = 1:numel(mr.txIds)
        row = sprintf('%-10s', mr.txIds{i});
        for j = 1:numel(mr.rxIds)
            row = [row, sprintf('%-10s', mr.risk{i, j})];
        end
        fprintf('%s\n', row);
    end
    hi = mr.highRiskPairs();
    fprintf('\nHigh-risk pairs: %d\n', numel(hi));
    for k = 1:numel(hi)
        pr = mr.getPair(hi{k}{1}, hi{k}{2});
        fprintf('  %s -> %s : DCI=%.1f dB, %s, validity=%s\n', ...
            hi{k}{1}, hi{k}{2}, pr.couplingMetric_dB, pr.frequencyRelation, pr.validity);
    end
end

function R = rbaFromBoresight(b)
    b = b(:) / norm(b);
    up = [0;0;1];
    if abs(dot(b, up)) > 0.99; up = [0;1;0]; end
    y = cross(up, b); y = y / norm(y);
    z = cross(b, y);
    R = [b, y, z];
end
