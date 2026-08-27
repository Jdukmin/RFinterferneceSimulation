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

    % ---- RC-KARI-01: P-ANT angular subtense vs the paper's reported points ----
    % Paper (KSAS 2015 춘계 pp.832-835): 4 deg <-> ~30 cm, 12 deg <-> ~83 cm at ~4 m;
    % acceptable up to ~80 cm. Curve = tool/closed-form; markers = PUBLIC_REPORTED.
    R = 4.0;
    D = 0.05:0.01:1.20;
    ang = 2 * atand(D / 2 / R);
    figure;
    plot(D*100, ang, '-b', 'LineWidth', 1.5); hold on;
    plot([30 83], [4 12], 'ro', 'MarkerSize', 9, 'LineWidth', 2);
    plot([80 80], [0 2*atand(0.80/2/R)], '--k', 'LineWidth', 1.2);
    xlabel('P-ANT diameter [cm]  (stand-off 4 m)'); ylabel('angular width [deg]');
    legend('tool: 2*atan(D/2/R)', 'paper reported (4deg/30cm, 12deg/83cm)', ...
           'paper acceptance limit ~80 cm', 'location', 'northwest');
    title('RC-KARI-01: P-ANT angular subtense vs paper values');
    grid on; xlim([0 120]);
    print(fullfile(figDir, 'rc_kari_01_subtense.png'), '-dpng');

    % ---- RC-KARI-02: reported installed ripple envelope (1-3 dB) ----
    fc = 2.2e9;
    free = rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(6, fc, 1);
    az = -180:2:180;
    gFree = arrayfun(@(a) free.evaluate(fc, a, 0), az);
    gInst = gFree + 3 * sind(3 * az);        % PUBLIC_REPORTED envelope: <= 3 dB ripple
    figure;
    plot(az, gFree, '-b', 'LineWidth', 1.5); hold on;
    plot(az, gInst, '--r', 'LineWidth', 1.5);
    xlabel('azimuth [deg]'); ylabel('gain [dBi]');
    legend('free-space', 'installed (paper-reported 1-3 dB ripple envelope)', 'location', 'south');
    title('RC-KARI-02: reported installed ripple envelope (el=0 cut)');
    grid on; xlim([-180 180]);
    print(fullfile(figDir, 'rc_kari_02_pattern.png'), '-dpng');

    figure;
    plot(az, gInst - gFree, '-k', 'LineWidth', 1.5); hold on;
    plot([-180 180], [ 3  3], ':r'); plot([-180 180], [-3 -3], ':r');
    xlabel('azimuth [deg]'); ylabel('installed - free-space [dB]');
    title('RC-KARI-02: ripple vs the paper''s 3 dB envelope');
    grid on; xlim([-180 180]); ylim([-4 4]);
    print(fullfile(figDir, 'rc_kari_02_delta.png'), '-dpng');

    % ---- RC-KARI-RF-01: required S-band tone pairing for an IM3 in L1 ----
    % f2 = 2*f1 - f_L1 is DERIVED, not hand-picked (DEFECT-B fix).
    fL1 = 1.57542;                       % GHz
    f1 = 2.00:0.01:3.00;                 % GHz, S-band
    f2 = 2*f1 - fL1;
    figure;
    plot(f1, f2, '-b', 'LineWidth', 1.5); hold on;
    plot([2 4], [2 4], ':k');
    plot([2 3], [4 4], '--r', 'LineWidth', 1.2);
    plot([2 3], [2 2], '--r', 'LineWidth', 1.2);
    xlabel('f1 [GHz]'); ylabel('required f2 = 2*f1 - f_{L1} [GHz]');
    legend('required partner tone', 'f2 = f1', 'S-band bounds (2-4 GHz)', 'location', 'northwest');
    title('RC-KARI-RF-01: S-band tone pairs whose IM3 lands in GNSS L1');
    grid on; xlim([2 3]); ylim([2 4.2]);
    print(fullfile(figDir, 'rc_kari_rf_01_im3.png'), '-dpng');

    fprintf('figures written to %s\n', figDir);
end
