function test_pattern(h)
%TEST_PATTERN Pattern lookup: exact node, interpolation, az wrap, el clamp,
%   frequency handling, missing data, determinism (VR-030..034, VR-073).
    h.setGroup('pattern');
    PG = @rfscreen.antenna.PatternGrid;
    Prov = rfscreen.antenna.PatternProvenance;

    az = [-180 -90 0 90 135];
    el = [-90 0 90];
    f  = [1e9 2e9];
    A  = [0 3 6 3 1];                 % az profile (periodic-ish across the seam)
    G  = zeros(numel(el), numel(az), numel(f));
    for k = 1:numel(f)
        for e = 1:numel(el)
            G(e, :, k) = A + (k - 1) * 10;   % f2 plane = f1 + 10
        end
    end
    grid = rfscreen.antenna.PatternGrid(az, el, f, G);
    p = rfscreen.antenna.FreeSpacePattern('SYNTHETIC_TEST_grid', Prov.SYNTHETIC_TEST, grid);

    pol = rfscreen.config.PatternInterpolationPolicy();

    % --- VR-030 exact node lookup ---
    h.eqTol('exact node az0', p.evaluate(1e9, 0, 0, pol), 6, 1e-12);
    h.eqTol('exact node az90', p.evaluate(1e9, 90, 0, pol), 3, 1e-12);
    h.eqTol('exact node f2', p.evaluate(2e9, 0, 0, pol), 16, 1e-12);

    % --- VR-031 bilinear interpolation ---
    h.eqTol('interp az45', p.evaluate(1e9, 45, 0, pol), 4.5, 1e-12);

    % --- VR-032 azimuth wrap-around ---
    h.eqTol('wrap -315==45', p.evaluate(1e9, -315, 0, pol), 4.5, 1e-12);
    % seam interpolation between 135 (A=1) and 180==-180 (A=0)
    seamExpect = 1 + (0 - 1) * ((160 - 135) / 45);
    h.eqTol('seam az160', p.evaluate(1e9, 160, 0, pol), seamExpect, 1e-12);
    h.eqTol('seam wrap -200==160', p.evaluate(1e9, -200, 0, pol), seamExpect, 1e-12);

    % --- VR-033 elevation boundary clamp ---
    [gClamp, infoClamp] = p.evaluateWithInfo(1e9, 0, 100, pol);
    h.eqTol('el clamp value', gClamp, 6, 1e-12);
    h.isTrue('el clamp flagged', infoClamp.clampedEl);

    % --- frequency nearest (default) ---
    h.eqTol('freq nearest low', p.evaluate(1.4e9, 0, 0, pol), 6, 1e-12);
    h.eqTol('freq nearest high', p.evaluate(1.6e9, 0, 0, pol), 16, 1e-12);

    % --- frequency linear ---
    polLin = rfscreen.config.PatternInterpolationPolicy(struct('freqMethod', 'linear'));
    h.eqTol('freq linear mid', p.evaluate(1.5e9, 0, 0, polLin), 11, 1e-12);

    % --- VR-034 out-of-range frequency: default 'nan' ---
    [gNan, infoNan] = p.evaluateWithInfo(3e9, 0, 0, pol);
    h.isNaNval('freq oob nan value', gNan);
    h.isFalse('freq oob not in domain', infoNan.inDomain);

    % 'error' policy
    polErr = rfscreen.config.PatternInterpolationPolicy(struct('outOfBandFreq', 'error'));
    h.throws('freq oob error', @() p.evaluate(3e9, 0, 0, polErr), 'rfscreen:pattern:freqOutOfRange');

    % 'nearest' clamp policy
    polClampF = rfscreen.config.PatternInterpolationPolicy(struct('outOfBandFreq', 'nearest'));
    h.eqTol('freq oob nearest-clamp', p.evaluate(3e9, 0, 0, polClampF), 16, 1e-12);

    % --- VR-073 determinism ---
    v1 = p.evaluate(1.23e9, 37, -11, pol);
    v2 = p.evaluate(1.23e9, 37, -11, pol);
    h.eqTol('deterministic lookup', v1, v2, 0);

    % --- missing gain (NaN) never interpolated over ---
    Gm = G; Gm(2, 3, 1) = NaN;       % el=0, az=0, f1
    gridM = rfscreen.antenna.PatternGrid(az, el, f, Gm);
    pm = rfscreen.antenna.FreeSpacePattern('SYNTHETIC_TEST_missing', Prov.SYNTHETIC_TEST, gridM);
    [gMiss, infoMiss] = pm.evaluateWithInfo(1e9, 0, 0, pol);
    h.isNaNval('missing node -> NaN', gMiss);
    h.isFalse('missing node not in domain', infoMiss.inDomain);

    % --- single-frequency pattern reused across frequency (with warning) ---
    iso = rfscreen.antenna.SyntheticPatternFactory.isotropic(5, 1e9);
    [gIso, infoIso] = iso.evaluateWithInfo(2.5e9, 10, 10, pol);
    h.eqTol('single-freq reused value', gIso, 5, 1e-12);
    h.isTrue('single-freq in domain', infoIso.inDomain);
    h.isTrue('single-freq warns', ~isempty(infoIso.warnings));
end
