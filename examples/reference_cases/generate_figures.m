function generate_figures()
%GENERATE_FIGURES Produce reference-validation comparison figures (Octave/MATLAB).
%   Writes PNGs to docs/reports/reference_validation/figures/. Plots are NOT
%   hand-edited to match papers; they overlay computed/illustrative data only.
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(fullfile(root, 'src'));
    figDir = fullfile(root, 'docs', 'reports', 'reference_validation', 'figures');
    if exist(figDir, 'dir') ~= 7; mkdir(figDir); end
    set(0, 'defaultfigurevisible', 'off');
    try; graphics_toolkit('gnuplot'); catch; end

    % ---- RC-KARI-02: free-space vs installed pattern (az cut, el=0) ----
    fc = 2.25e9;
    free = rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(9, fc, 2);
    az = -180:2:180;
    gFree = arrayfun(@(a) free.evaluate(fc, a, 0), az);
    theta = abs(az);
    gInst = gFree - 1.5; gInst(theta > 120) = gInst(theta > 120) + 4;
    figure;
    plot(az, gFree, '-b', 'LineWidth', 1.5); hold on;
    plot(az, gInst, '--r', 'LineWidth', 1.5);
    xlabel('azimuth [deg]'); ylabel('gain [dBi]');
    legend('free-space', 'installed (illustrative, SYNTHETIC TEST)', 'location', 'south');
    title('RC-KARI-02: free-space vs installed S-band pattern (el=0 cut)');
    grid on; xlim([-180 180]);
    print(fullfile(figDir, 'rc_kari_02_pattern.png'), '-dpng');

    % ---- RC-KARI-02: installed - free-space delta ----
    figure;
    plot(az, gInst - gFree, '-k', 'LineWidth', 1.5);
    xlabel('azimuth [deg]'); ylabel('installed - free-space [dB]');
    title('RC-KARI-02: pattern gain delta (el=0 cut)');
    grid on; xlim([-180 180]);
    print(fullfile(figDir, 'rc_kari_02_delta.png'), '-dpng');

    % ---- RC-KARI-RF-01: IM3 product frequencies vs GNSS band ----
    f1 = 1.60e9; f2 = 1.625e9;
    prod = [2*f1 - f2, 2*f2 - f1] / 1e9;   % GHz
    figure;
    stem(prod, [1 1], 'r', 'filled'); hold on;
    plot([1.559 1.591], [0.5 0.5], '-b', 'LineWidth', 3);
    text(prod(1), 1.05, '2f1-f2'); text(prod(2), 1.05, '2f2-f1');
    text(1.575, 0.4, 'GNSS L1 band');
    xlabel('frequency [GHz]'); ylabel('presence');
    title('RC-KARI-RF-01: two-tone IM3 products vs GNSS L1 band');
    xlim([1.5 1.7]); ylim([0 1.2]); grid on;
    print(fullfile(figDir, 'rc_kari_rf_01_im3.png'), '-dpng');

    fprintf('figures written to %s\n', figDir);
end
