function test_spectrum(h)
%TEST_SPECTRUM TX spectrum normalization + linear integration (VR-200, VR-201, VR-202).
    h.setGroup('spectrum');
    U = rfscreen.util.Units;

    % ---- rectangular normalization: integral(PSD) = P_total ----
    sp = rfscreen.spectrum.RectangularSpectrum(2.2e9, 20e6, 30, struct('provenance','SYNTHETIC_TEST'));
    h.eqTol('rect totalPower_W', sp.totalPower_W(), 1.0, 1e-12);          % 30 dBm = 1 W
    h.eqTol('rect PSD density', sp.psd_WPerHz(2.2e9), 1.0/20e6, 1e-18);
    h.eqTol('rect PSD out-of-band', sp.psd_WPerHz(2.3e9), 0, 0);
    f = linspace(2.2e9-15e6, 2.2e9+15e6, 200001);
    h.eqTol('rect integral = P_total', trapz(f, sp.psd_WPerHz(f)), 1.0, 1e-4);
    h.eqStr('rect provenance', sp.provenance, 'SYNTHETIC_TEST');
    h.eqStr('rect reference plane', sp.referencePlane, 'TX_ANTENNA_INPUT');
    h.eqTol('rect occupiedBW', sp.occupiedBandwidth_Hz(), 20e6, 0);

    % ---- tabulated normalization (triangular, LINEAR shape) ----
    fg = [2.19e9 2.20e9 2.21e9];
    tri = rfscreen.spectrum.TabulatedSpectrum(fg, [0 1 0], 20, struct('provenance','SYNTHETIC_TEST'));
    h.eqTol('tab totalPower_W', tri.totalPower_W(), U.dbm2w(20), 1e-12);
    ff = linspace(2.19e9, 2.21e9, 200001);
    h.eqTol('tab integral = P_total', trapz(ff, tri.psd_WPerHz(ff)), U.dbm2w(20), 1e-6);
    h.eqTol('tab PSD outside = 0', tri.psd_WPerHz(2.0e9), 0, 0);

    % ---- LINEAR integration evidence: dB shape is linearized, not summed ----
    % shape_dB = [-10 0 -10] -> linear [0.1 1 0.1]; peak/edge ratio must be 10 (linear),
    % which is impossible if dB values were integrated/averaged directly.
    tdb = rfscreen.spectrum.TabulatedSpectrum(fg, [-10 0 -10], 20, ...
        struct('shapeUnit','DB','provenance','SYNTHETIC_TEST'));
    ratio = tdb.psd_WPerHz(2.20e9) / tdb.psd_WPerHz(2.19e9);
    h.eqTol('dB shape linearized (ratio=10)', ratio, 10, 1e-9);
    h.eqTol('tab dB integral = P_total', trapz(ff, tdb.psd_WPerHz(ff)), U.dbm2w(20), 1e-6);

    % ---- different grid resolutions -> same total power ----
    coarse = rfscreen.spectrum.TabulatedSpectrum([2.19e9 2.20e9 2.21e9], [1 1 1], 20, struct());
    fine = rfscreen.spectrum.TabulatedSpectrum(linspace(2.19e9,2.21e9,51), ones(1,51), 20, struct());
    h.eqTol('coarse/fine same total power', coarse.totalPower_W(), fine.totalPower_W(), 1e-15);
    h.eqTol('coarse/fine same PSD mid', coarse.psd_WPerHz(2.20e9), fine.psd_WPerHz(2.20e9), 1e-18);

    % ---- invalid inputs ----
    h.throws('negative LINEAR shape rejected', ...
        @() rfscreen.spectrum.TabulatedSpectrum(fg, [0 -1 0], 20, struct()), ...
        'rfscreen:spectrum:negShape');
end
