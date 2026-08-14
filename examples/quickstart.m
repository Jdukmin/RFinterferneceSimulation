function quickstart()
%QUICKSTART Minimal top-down user path: Input -> Run -> Result.
%   Antenna-to-antenna pattern/geometry screening between a TX and an RX on a
%   spacecraft body, using only public top-level APIs. No ICD reading required.
%
%   Run:  addpath('src'); quickstart
%   (or from the repo root:  octave-cli --eval "addpath('.'); setup_paths(); quickstart")

    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(here), 'src'));   % make rfscreen.* visible

    % ---- 1. INPUT: build a scenario ----
    sc = rfscreen.scenario.Scenario('QUICKSTART');

    % antenna radiation patterns (synthetic, clearly marked SYNTHETIC_TEST)
    fc = 2.2e9;                                   % S-band
    sc.addPattern('PAT_TX', rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(12, fc, 2));
    sc.addPattern('PAT_RX', rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(8,  fc, 2));

    Role = rfscreen.antenna.Role; Pol = rfscreen.antenna.Polarization;
    sc.addAntenna(rfscreen.antenna.Antenna('ANT_TX','TX antenna', Role.TX, 1e9, 4e9, Pol.RHCP, 'PAT_TX','ANT_TX'));
    sc.addAntenna(rfscreen.antenna.Antenna('ANT_RX','RX antenna', Role.RX, 1e9, 4e9, Pol.RHCP, 'PAT_RX','ANT_RX'));

    % installation geometry: TX at origin facing +X; RX 1.5 m away facing back at TX
    sc.addInstallation(rfscreen.antenna.AntennaInstallation('ANT_TX', [0;0;0], eye(3)));
    sc.addInstallation(rfscreen.antenna.AntennaInstallation('ANT_RX', [1.5;0;0], ...
        rfscreen.geometry.Rotation.aboutZ(180)));

    % RF systems
    sc.addTransmitter(rfscreen.rf.RFTransmitter('TX1','ANT_TX', fc, 20e6, 33));   % 33 dBm
    sc.addReceiver(rfscreen.rf.RFReceiver('RX1','ANT_RX', fc, 20e6));

    % ---- 2. RUN: pairwise screening (pattern-only coupling) ----
    mr = rfscreen.interference.InterferenceAnalyzer.analyze(sc);
    pr = mr.getPair('TX1','RX1');

    % ---- 3. RESULT ----
    fprintf('\n=== Quick Start result: TX1 -> RX1 ===\n');
    fprintf('  distance             : %.2f m\n', pr.distance_m);
    fprintf('  TX gain toward RX     : %.2f dBi (%s lobe)\n', pr.txGain_dBi, pr.txLobeClass);
    fprintf('  RX gain toward TX     : %.2f dBi (%s lobe)\n', pr.rxGain_dBi, pr.rxLobeClass);
    fprintf('  frequency relation    : %s\n', pr.frequencyRelation);
    fprintf('  DirectionalCouplingIdx: %.2f dB   (SCREENING index, NOT isolation/S21)\n', pr.couplingMetric_dB);
    fprintf('  risk (screening)      : %s\n', pr.riskLevel);
    fprintf('  validity              : %s\n', pr.validity);
    fprintf('\nInterpretation: this is a relative pattern/geometry SCREENING result.\n');
    fprintf('It is NOT an absolute coupling in dB. See docs/user_manual.md sections 15-17.\n\n');
end
