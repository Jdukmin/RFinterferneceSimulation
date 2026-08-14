function test_spectral_coupling(h)
%TEST_SPECTRAL_COUPLING Linear spectral overlap integration (VR-203, VR-205).
    h.setGroup('spectral_coupling');
    SCA = @(sp, fl) rfscreen.interference.SpectralCouplingAnalyzer.analyze(sp, fl);

    tx = rfscreen.spectrum.RectangularSpectrum(2.2e9, 20e6, 30, struct());  % band [2.190,2.210] GHz

    % full overlap: filter wider than TX
    r = SCA(tx, rfscreen.receiver.IdealBandpassFilter([2.18e9 2.22e9], 0, -Inf));
    h.eqTol('full overlap fraction', r.overlapFraction, 1.0, 1e-9);
    h.eqTol('full overlap factor dB', r.spectralFactor_dB, 0, 1e-9);

    % partial overlap: filter covers upper half of TX band
    rp = SCA(tx, rfscreen.receiver.IdealBandpassFilter([2.2e9 2.25e9], 0, -Inf));
    h.eqTol('partial overlap 0.5', rp.overlapFraction, 0.5, 1e-9);
    h.eqTol('partial factor -3.01 dB', rp.spectralFactor_dB, 10*log10(0.5), 1e-9);

    % no overlap
    rn = SCA(tx, rfscreen.receiver.IdealBandpassFilter([2.3e9 2.31e9], 0, -Inf));
    h.eqTol('no overlap fraction 0', rn.overlapFraction, 0, 0);

    % edge-touching (measure-zero overlap)
    re = SCA(tx, rfscreen.receiver.IdealBandpassFilter([2.21e9 2.22e9], 0, -Inf));
    h.eqTol('edge-touch fraction 0', re.overlapFraction, 0, 1e-12);

    % narrow TX inside wide RX -> fraction 1
    txN = rfscreen.spectrum.RectangularSpectrum(2.2e9, 2e6, 30, struct());
    rN = SCA(txN, rfscreen.receiver.IdealBandpassFilter([2.18e9 2.22e9], 0, -Inf));
    h.eqTol('narrow-TX wide-RX fraction 1', rN.overlapFraction, 1.0, 1e-9);

    % wide TX, narrow RX -> fraction = rxbw/txbw = 5/20 = 0.25
    rW = SCA(tx, rfscreen.receiver.IdealBandpassFilter([2.1975e9 2.2025e9], 0, -Inf));
    h.eqTol('wide-TX narrow-RX 0.25', rW.overlapFraction, 0.25, 1e-9);

    % -3 dB passband halves the passed power
    r3 = SCA(tx, rfscreen.receiver.IdealBandpassFilter([2.18e9 2.22e9], -3, -Inf));
    h.eqTol('-3dB filter halves fraction', r3.overlapFraction, 10^(-0.3), 1e-9);

    % different sample steps: tabulated filter (fine grid) vs rectangular TX (2 breakpoints)
    fg = linspace(2.19e9, 2.21e9, 41);
    ftab = rfscreen.receiver.TabulatedFilterResponse(fg, zeros(1,41), struct()); % flat 0 dB
    rd = SCA(tx, ftab);
    h.eqTol('mixed-grid flat filter fraction ~1', rd.overlapFraction, 1.0, 1e-6);

    % source grids not mutated
    h.eqTol('TX support unchanged', tx.supportBand_Hz(), [2.19e9 2.21e9], 1e-3);
end
