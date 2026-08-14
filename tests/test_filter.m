function test_filter(h)
%TEST_FILTER RX filter response (VR-204).
    h.setGroup('filter');

    % ---- ideal bandpass, 0 dB passband, full rejection ----
    f = rfscreen.receiver.IdealBandpassFilter([2.0e9 2.1e9], 0, -Inf, struct('provenance','SYNTHETIC_TEST'));
    h.eqTol('passband dB', f.responseDb(2.05e9), 0, 0);
    h.eqTol('passband linear', f.responseLinear(2.05e9), 1, 0);
    h.eqTol('stopband linear (-Inf->0)', f.responseLinear(2.2e9), 0, 0);
    h.eqTol('ENBW = bandwidth', f.equivalentNoiseBandwidth_Hz(), 0.1e9, 1e-3);
    h.eqStr('filter provenance', f.provenance, 'SYNTHETIC_TEST');

    % ---- passband gain -3 dB ----
    f3 = rfscreen.receiver.IdealBandpassFilter([2.0e9 2.1e9], -3, -Inf);
    h.eqTol('-3 dB linear ~0.5', f3.responseLinear(2.05e9), 10^(-0.3), 1e-9);

    % ---- finite rejection stopband ----
    fr = rfscreen.receiver.IdealBandpassFilter([2.0e9 2.1e9], 0, -40);
    h.eqTol('stopband -40 dB linear', fr.responseLinear(2.2e9), 1e-4, 1e-12);

    % ---- tabulated response interpolation (in dB) ----
    ft = rfscreen.receiver.TabulatedFilterResponse([1e9 2e9 3e9], [-40 0 -40], ...
        struct('provenance','SYNTHETIC_TEST'));
    h.eqTol('tab node 0 dB', ft.responseDb(2e9), 0, 1e-9);
    h.eqTol('tab interp -20 dB', ft.responseDb(1.5e9), -20, 1e-9);
    h.eqTol('tab interp linear', ft.responseLinear(1.5e9), 1e-2, 1e-9);
    % boundary clamp
    h.eqTol('tab clamp below', ft.responseDb(0.5e9), -40, 1e-9);
    h.eqTol('tab clamp above', ft.responseDb(3.5e9), -40, 1e-9);

    % ---- invalid ----
    h.throws('bad band rejected', ...
        @() rfscreen.receiver.IdealBandpassFilter([2.1e9 2.0e9]), 'rfscreen:receiver:badBand');
end
