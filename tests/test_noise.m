function test_noise(h)
%TEST_NOISE Linear receiver noise kTB (VR-206).
    h.setGroup('noise');
    U = rfscreen.util.Units;
    k = rfscreen.util.Constants.boltzmann_JperK();

    % dBm <-> W sanity
    h.eqTol('dbm2w(30)=1W', U.dbm2w(30), 1.0, 1e-12);
    h.eqTol('w2dbm(1)=30', U.w2dbm(1.0), 30, 1e-12);
    h.eqTol('dbm2w(0)=1mW', U.dbm2w(0), 1e-3, 1e-15);

    % kTB via system temperature: Tsys=290, B=1 Hz -> ~ -174 dBm
    nmT = rfscreen.receiver.ReceiverNoiseModel(struct('systemNoiseTemp_K', 290));
    h.eqTol('kT0 (1 Hz) W', nmT.noisePower_W(1), k*290, 1e-30);
    h.eqTol('kT0 (1 Hz) ~ -174 dBm', nmT.noisePower_dBm(1), U.w2dbm(k*290), 1e-9);
    h.ok('kT0 ~ -174 dBm', abs(nmT.noisePower_dBm(1) - (-174)) < 0.05);

    % bandwidth scaling: +60 dB per 1e6x
    h.eqTol('bandwidth +60dB', nmT.noisePower_dBm(1e6) - nmT.noisePower_dBm(1), 60, 1e-9);

    % temperature scaling: doubling T -> +3.0103 dB
    nm2T = rfscreen.receiver.ReceiverNoiseModel(struct('systemNoiseTemp_K', 580));
    h.eqTol('temp doubling +3dB', nm2T.noisePower_dBm(1e6) - nmT.noisePower_dBm(1e6), 10*log10(2), 1e-9);

    % noise figure: NF=0 equals kT0B; NF=3 adds 3 dB
    nf0 = rfscreen.receiver.ReceiverNoiseModel(struct('noiseFigure_dB', 0));
    nf3 = rfscreen.receiver.ReceiverNoiseModel(struct('noiseFigure_dB', 3));
    h.eqTol('NF=0 == kT0B', nf0.noisePower_dBm(1e6), nmT.noisePower_dBm(1e6), 1e-9);
    h.eqTol('NF=3 adds 3 dB', nf3.noisePower_dBm(1e6) - nf0.noisePower_dBm(1e6), 3, 1e-9);

    % analytical: NF=3, B=20 MHz -> -174 + 73.01 + 3
    Nexp = U.w2dbm(k*290) + 10*log10(20e6) + 3;
    h.eqTol('NF=3 B=20MHz analytical', nf3.noisePower_dBm(20e6), Nexp, 1e-9);

    % incomplete / ambiguous models refuse (no invented defaults)
    h.throws('no method -> incomplete', ...
        @() rfscreen.receiver.ReceiverNoiseModel(struct()), 'rfscreen:receiver:noiseIncomplete');
    h.throws('two methods -> ambiguous', ...
        @() rfscreen.receiver.ReceiverNoiseModel(struct('noiseFigure_dB',3,'systemNoiseTemp_K',290)), ...
        'rfscreen:receiver:noiseAmbiguous');
end
