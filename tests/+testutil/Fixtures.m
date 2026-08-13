classdef Fixtures
    %FIXTURES Deterministic test fixtures (SYNTHETIC_TEST data only, DR-040).
    %   No mission/reference data. All patterns are synthetic and clearly marked.
    methods (Static)
        function R = rbaBoresight(boresight_B)
            %RBABORESIGHT Build a proper DCM R_BA whose boresight (+X_A) points
            %   along boresight_B (body). A stable up-vector completes the frame.
            b = boresight_B(:) / norm(boresight_B);
            up = [0; 0; 1];
            if abs(dot(b, up)) > 0.99
                up = [0; 1; 0];
            end
            y = cross(up, b); y = y / norm(y);   % +Y_A
            z = cross(b, y);                     % +Z_A
            R = [b, y, z];                       % columns = antenna axes in body
        end

        function sc = twoAntennaScenario(txPattern, rxPattern, rxPosition_m, rxBoresight_B, opts)
            %TWOANTENNASCENARIO TX at origin facing +X; RX placed/oriented as given.
            if nargin < 5; opts = struct(); end
            R = rfscreen.geometry.Rotation;
            sc = rfscreen.scenario.Scenario('SYNTHETIC_TEST_SCENARIO');

            sc.addPattern('PAT_TX', txPattern);
            sc.addPattern('PAT_RX', rxPattern);

            sc.addAntenna(rfscreen.antenna.Antenna('ANT_TX', 'TX antenna', ...
                rfscreen.antenna.Role.TX, 1e9, 4e9, ...
                rfscreen.antenna.Polarization.RHCP, 'PAT_TX', 'ANT_TX'));
            sc.addAntenna(rfscreen.antenna.Antenna('ANT_RX', 'RX antenna', ...
                rfscreen.antenna.Role.RX, 1e9, 4e9, ...
                rfscreen.antenna.Polarization.RHCP, 'PAT_RX', 'ANT_RX'));

            if isfield(opts, 'txBoresight_B') && ~isempty(opts.txBoresight_B)
                R_BA_tx = testutil.Fixtures.rbaBoresight(opts.txBoresight_B);
            else
                R_BA_tx = eye(3);
            end
            sc.addInstallation(rfscreen.antenna.AntennaInstallation('ANT_TX', ...
                [0; 0; 0], R_BA_tx));
            sc.addInstallation(rfscreen.antenna.AntennaInstallation('ANT_RX', ...
                rxPosition_m(:), testutil.Fixtures.rbaBoresight(rxBoresight_B)));

            txFc = testutil.Fixtures.opt(opts, 'txFc_Hz', 2.2e9);
            txBw = testutil.Fixtures.opt(opts, 'txBw_Hz', 20e6);
            txPow = testutil.Fixtures.opt(opts, 'txPower_dBm', 30);
            rxFc = testutil.Fixtures.opt(opts, 'rxFc_Hz', txFc);
            rxBw = testutil.Fixtures.opt(opts, 'rxBw_Hz', 20e6);

            sc.addTransmitter(rfscreen.rf.RFTransmitter('TX1', 'ANT_TX', txFc, txBw, txPow));
            rxOpts = struct();
            if isfield(opts, 'rxThreshold_dBm'); rxOpts.interferenceThreshold_dBm = opts.rxThreshold_dBm; end
            sc.addReceiver(rfscreen.rf.RFReceiver('RX1', 'ANT_RX', rxFc, rxBw, rxOpts));
        end

        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
                v = s.(name);
            else
                v = default;
            end
        end
    end
end
