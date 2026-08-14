function test_installed_pattern(h)
%TEST_INSTALLED_PATTERN Selection, comparison, fidelity/provenance (VR-405..407).
    h.setGroup('installed_pattern');
    Pol = rfscreen.installed.InstalledPatternPolicy;
    freq = 2.2e9;
    freeSpace = rfscreen.antenna.SyntheticPatternFactory.isotropic(10, freq);   % 10 dBi
    installed = mkInstalled(6, 'SIMULATED_3D', 'HFSS', freq);                    % 6 dBi installed

    % ---- selection: installed present ----
    s1 = rfscreen.installed.InstalledPatternSelector.select(freeSpace, installed, Pol.PREFER_INSTALLED);
    h.eqStr('installed used', s1.sourceUsed, 'INSTALLED');
    h.eqStr('installed validity', s1.installationValidity, 'INSTALLED_PATTERN_AVAILABLE');
    h.eqStr('provenance propagated (not upgraded)', s1.provenance, 'SIMULATED_3D');
    h.eqStr('installed source preserved', s1.installedSource, 'HFSS');
    h.isTrue('selected pattern is installed type', isa(s1.pattern, 'rfscreen.antenna.InstalledPattern'));

    % ---- PREFER_INSTALLED fallback (installed absent) is EXPLICIT ----
    s2 = rfscreen.installed.InstalledPatternSelector.select(freeSpace, [], Pol.PREFER_INSTALLED);
    h.eqStr('fallback source', s2.sourceUsed, 'FREE_SPACE_FALLBACK');
    h.eqStr('fallback validity', s2.installationValidity, 'INSTALLATION_EFFECT_UNKNOWN');
    h.isTrue('fallback warns (not silent)', ~isempty(s2.warnings));
    h.isTrue('fallback pattern is free-space', isa(s2.pattern, 'rfscreen.antenna.FreeSpacePattern'));

    % ---- REQUIRE_INSTALLED without installed -> withheld ----
    s3 = rfscreen.installed.InstalledPatternSelector.select(freeSpace, [], Pol.REQUIRE_INSTALLED);
    h.eqStr('require source NONE', s3.sourceUsed, 'NONE');
    h.eqStr('require validity', s3.installationValidity, 'REQUIRE_INSTALLED_UNAVAILABLE');
    h.isTrue('require -> no pattern', isempty(s3.pattern));

    % ---- fidelity propagation (VR-407): APPROX stays approx; SIM != MEAS ----
    approx = mkInstalled(6, 'APPROX_FROM_CUTS', 'APPROXIMATE', freq);
    sA = rfscreen.installed.InstalledPatternSelector.select(freeSpace, approx, Pol.PREFER_INSTALLED);
    h.eqStr('approx stays approx', sA.provenance, 'APPROX_FROM_CUTS');
    meas = mkInstalled(6, 'MEASURED_3D', 'MEASURED', freq);
    h.isFalse('SIMULATED_3D != MEASURED_3D', strcmp(installed.provenance, meas.provenance));

    % ---- comparison metrics (installed - freeSpace = -4 dB everywhere) ----
    cmp = rfscreen.installed.PatternComparison.compare(freeSpace, installed, ...
        struct('frequency_Hz', freq));
    h.eqTol('peak gain difference -4', cmp.peakGainDifference_dB, -4, 1e-9);
    h.eqTol('max abs difference 4', cmp.maxAbsDifference_dB, 4, 1e-9);
    h.eqTol('rms difference 4', cmp.rmsDifference_dB, 4, 1e-9);
    h.eqStr('comparison valid', cmp.validity, 'VALID');
    h.eqStr('comparison keeps installed source', cmp.installedSource, 'HFSS');
    d = rfscreen.installed.PatternComparison.directionDelta_dB(freeSpace, installed, freq, 30, 10);
    h.eqTol('direction delta -4', d, -4, 1e-9);

    % ---- comparison with different grids (coarse installed) ----
    coarse = mkInstalledGrid(6, 'SIMULATED_3D', 'HFSS', freq, -180:30:180, -90:30:90);
    cmp2 = rfscreen.installed.PatternComparison.compare(freeSpace, coarse, struct('frequency_Hz', freq));
    h.eqTol('mixed-grid delta still -4', cmp2.peakGainDifference_dB, -4, 1e-9);
    % sources not mutated
    h.eqTol('free-space gain intact after compare', freeSpace.evaluate(freq, 0, 0), 10, 1e-9);
    h.eqTol('installed gain intact after compare', installed.evaluate(freq, 0, 0), 6, 1e-9);

    % ---- config-specific association via scenario registry ----
    sc = rfscreen.scenario.Scenario('CFG');
    sc.addInstalledPattern('ANT1', 'DEPLOYED', installed);
    h.isTrue('deployed pattern present', ~isempty(sc.getInstalledPattern('ANT1', 'DEPLOYED')));
    h.isTrue('stowed pattern absent (config-specific)', isempty(sc.getInstalledPattern('ANT1', 'STOWED')));
end

function p = mkInstalled(gain, prov, src, freq)
    p = mkInstalledGrid(gain, prov, src, freq, -180:5:180, -90:5:90);
end
function p = mkInstalledGrid(gain, prov, src, freq, az, el)
    G = gain * ones(numel(el), numel(az), 1);
    grid = rfscreen.antenna.PatternGrid(az, el, freq, G);
    p = rfscreen.antenna.InstalledPattern('SYNTHETIC_TEST_installed', prov, grid, src);
end
