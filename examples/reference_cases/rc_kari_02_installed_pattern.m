function rc_kari_02_installed_pattern()
%RC_KARI_02_INSTALLED_PATTERN Reproduction path for:
%   이선익, 임원규, 김중표, "S대역 안테나의 위성 설치상태에서의 성능 연구", 2023.
%
%   SCOPE: demonstrates the free-space vs installed pattern comparison workflow
%   (Phase-2 pattern data + Phase-5 FreeSpacePattern/InstalledPattern +
%   PatternComparison). The installed pattern here is a SYNTHETIC_TEST stand-in
%   for a digitized/measured installed cut; with a real digitized figure the same
%   workflow applies (mark provenance DIGITIZED_FROM_PUBLIC_FIGURE, never as raw
%   measured data). The tool reproduces the COMPARISON, not the installation
%   physics that produced the installed pattern.

    addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'src'));
    hr = @() fprintf('%s\n', repmat('-', 1, 72));
    fprintf('\n============== RC-KARI-02: Installed vs Free-space Pattern ==============\n');
    fprintf('Reference: Lee S-I., Im W-G., Kim J-P., KSAS 2023 (installed S-band perf.)\n');
    hr();

    fc = 2.25e9;
    % free-space baseline (synthetic S-band pattern)
    free = rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(9, fc, 2);   % ~9 dBi peak

    % installed pattern (SYNTHETIC_TEST stand-in for a digitized installed cut):
    % built by PERTURBING the SAME free-space pattern's own gains (so the delta is
    % meaningful, not an artifact of two different base formulas): boresight region
    % reduced ~1.5 dB and the back region raised, as an installed antenna typically
    % shows. Illustrative reconstruction, NOT measured data.
    az = -180:5:180; el = -90:5:90;
    [AZ, EL] = meshgrid(az, el);
    theta = acosd(max(min(cosd(EL).*cosd(AZ), 1), -1));
    Ginst = zeros(numel(el), numel(az));
    for ie = 1:numel(el)
        for ia = 1:numel(az)
            g = free.evaluate(fc, az(ia), el(ie));        % free-space gain at this node
            g = g - 1.5;                                  % installed peak reduction (illustrative)
            if theta(ie, ia) > 120; g = g + 4; end        % raised back region (illustrative)
            Ginst(ie, ia) = g;
        end
    end
    grid = rfscreen.antenna.PatternGrid(az, el, fc, Ginst);
    installed = rfscreen.antenna.InstalledPattern('SYNTHETIC_TEST_installed_S', ...
        'SIMULATED_3D', grid, 'OTHER_SOLVER');

    % ---- selection (installed available) ----
    sel = rfscreen.installed.InstalledPatternSelector.select(free, installed, 'PREFER_INSTALLED');
    fprintf('Pattern selection: source=%s  validity=%s  provenance=%s (preserved)\n', ...
        sel.sourceUsed, sel.installationValidity, sel.provenance);

    % ---- comparison ----
    cmp = rfscreen.installed.PatternComparison.compare(free, installed, struct('frequency_Hz', fc));
    fprintf('\nPattern comparison (installed - free-space), n=%d grid pts:\n', cmp.nGrid);
    fprintf('  peak gain difference : %+6.2f dB\n', cmp.peakGainDifference_dB);
    fprintf('  max abs difference   : %6.2f dB\n', cmp.maxAbsDifference_dB);
    fprintf('  RMS difference       : %6.2f dB\n', cmp.rmsDifference_dB);
    fprintf('  boresight delta      : %+6.2f dB\n', ...
        rfscreen.installed.PatternComparison.directionDelta_dB(free, installed, fc, 0, 0));

    hr();
    fprintf('Reproducibility (workflow): TIER 2-3 (comparison reproducible; the installed\n');
    fprintf('  pattern itself requires measured/full-wave evidence to be authoritative).\n');
    fprintf('Axial ratio / polarization delta: UNSUPPORTED (architecture owns no such channel)\n');
    fprintf('  -> MODEL_GAP_AXIAL_RATIO / MODEL_GAP_POLARIZATION (reported, not fabricated).\n');
    fprintf('Comparison class: SAME_TREND (gain delta) ; NOT_COMPARABLE (axial ratio)\n\n');
end
