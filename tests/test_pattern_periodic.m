function test_pattern_periodic(h)
%TEST_PATTERN_PERIODIC Periodic interpolation across 0/360; independent XZ/YZ
%   steps coexist (VR-114, VR-115).
    h.setGroup('pattern_periodic');

    % ---- VR-114 periodic interpolation ----
    theta = 0:10:350;                 % 36 samples, native [0,360)
    gain  = cosd(theta);              % periodic values
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane','XZ','angleRange','[0,360)'));
    imp = rfscreen.patterndata.TablePatternImporter(theta, gain, conv, ...
        struct('patternId','SYNTHETIC_TEST_per','fidelity','SYNTHETIC_TEST','frequency_Hz',2.2e9));
    cut = imp.importCut();

    % exact nodes
    h.eqTol('node 0', cut.evaluate(0), 1, 1e-12);
    h.eqTol('node 90', cut.evaluate(90), cosd(90), 1e-12);
    % wrap continuity: 360 == 0
    h.eqTol('360 == 0', cut.evaluate(360), cut.evaluate(0), 1e-12);
    % seam interpolation between node 350 and node 0(=360): linear
    seam = 0.5 * cosd(350) + 0.5 * cosd(0);
    h.eqTol('seam 355 linear', cut.evaluate(355), seam, 1e-12);
    h.eqTol('wrap -5 == 355', cut.evaluate(-5), cut.evaluate(355), 1e-12);
    % just inside 0
    interior = 0.5 * cosd(0) + 0.5 * cosd(10);
    h.eqTol('interior 5', cut.evaluate(5), interior, 1e-12);
    % continuity near seam: values close on both sides of 0
    h.isTrue('continuity across 0', abs(cut.evaluate(359.9) - cut.evaluate(0.1)) < 0.05);

    % ---- VR-115 independent XZ (0.25) and YZ (1.0) steps coexist ----
    xz = makeCut('XZ', -180:0.25:180, 'SYNTHETIC_TEST_XZ');
    yz = makeCut('YZ', -180:1:180,   'SYNTHETIC_TEST_YZ');
    h.eqTol('XZ step 0.25', xz.nominalStep_deg, 0.25, 1e-9);
    h.eqTol('YZ step 1.0', yz.nominalStep_deg, 1.0, 1e-9);
    h.isFalse('XZ/YZ counts differ', xz.numSamples() == yz.numSamples());
    % they coexist in one assembled pattern without forcing a shared cut grid
    p = rfscreen.patterndata.CutPatternAssembler.assembleFreeSpacePattern( ...
        'SYNTHETIC_TEST_MIX', xz, yz, struct('frequency_Hz', 2.2e9));
    h.eqStr('assembled from mixed steps', p.provenance, 'APPROX_FROM_CUTS');
    % native cut grids are unchanged by assembly
    h.eqTol('XZ still 0.25 after assembly', xz.nominalStep_deg, 0.25, 1e-9);
    h.eqTol('YZ still 1.0 after assembly', yz.nominalStep_deg, 1.0, 1e-9);
end

function cut = makeCut(plane, theta, id)
    g = 10 + 20*log10(max(cosd(theta/2).^2, 1e-3));
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane',plane,'angleRange','[-180,180]'));
    imp = rfscreen.patterndata.TablePatternImporter(theta, g, conv, ...
        struct('patternId', id, 'fidelity', 'SYNTHETIC_TEST', 'frequency_Hz', 2.2e9));
    cut = imp.importCut();
end
