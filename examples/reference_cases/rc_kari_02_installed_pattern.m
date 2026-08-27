function rc_kari_02_installed_pattern()
%RC_KARI_02_INSTALLED_PATTERN Reproduction path for:
%   이선익, 임원규, 김중표, "S대역 안테나의 위성 설치상태에서의 성능 연구",
%   한국항공우주학회 2023 추계학술대회 논문집, pp. 1261-1263.
%
%   PAPER CONTENT (PUBLIC_REPORTED):
%     Installed-performance (scattering) analysis methods:
%       (a) full-wave simulation  - MoM/FEM on the structure (e.g. HFSS)
%       (b) high-frequency method - GTD/UTD with a radiation SOURCE placed at the
%           antenna location; the source may be a far-field pattern (*.ffe) or a
%           spherical-wave-mode expansion (*.sph).
%     Validity rule: the high-frequency method needs the source to be sufficiently
%     separated from the platform. For this hemispherical S-band antenna the
%     reported MINIMUM VALIDITY RADIUS is about 30-40 cm.
%     Method-comparison campaign (with the manufacturer):
%       Case 1  40 cm boom      -> far-field src, spherical-mode src, HFSS all agree
%       Case 2  4-5 cm boom     -> far-field src ~ HFSS, but spherical-mode UNSTABLE
%       Case 3  box near antenna-> all three methods agree
%     GEO application: S-band TC&R antenna on a rod >= 40 cm from the platform,
%     surrounded by SBAS (L-band), DCS (L-band), fixed-comm (Ka-band) antennas and
%     solar panels; analysed with the high-frequency method + far-field source.
%     REPORTED RESULT: over the required coverage the platform/neighbour effect on
%     BOTH gain and axial ratio is a small ripple of 1-3 dB or less.
%
%   WHAT THIS TOOL REPRODUCES: the method-validity decision (is the stand-off above
%   the minimum validity radius?) and the free-space vs installed COMPARISON metric.
%   WHAT IT DOES NOT: it cannot PRODUCE the installed pattern - that is the paper's
%   EM output (FEKO/HFSS). Axial ratio is not represented at all.

    addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'src'));
    hr = @() fprintf('%s\n', repmat('-', 1, 78));
    fprintf('\n============== RC-KARI-02: Installed S-band Antenna Performance ==============\n');
    fprintf('Reference: 이선익·임원규·김중표, KSAS 2023 추계, pp.1261-1263\n');
    hr();

    % ---- Paper numbers (PUBLIC_REPORTED) ----
    minValidityRadius_m = [0.30 0.40];   % reported minimum validity radius 30-40 cm
    reportedRipple_dB   = [1 3];         % reported gain / axial-ratio ripple 1-3 dB
    cases = { 'Case 1  40 cm boom',   0.40; ...
              'Case 2  4-5 cm boom',  0.045; ...
              'Case 3  40 cm + box',  0.40 };

    fprintf('Method-validity screening vs the reported minimum validity radius (%.2f-%.2f m):\n', ...
        minValidityRadius_m(1), minValidityRadius_m(2));
    fprintf('  %-22s %-12s %-28s %s\n', 'case', 'stand-off', 'tool verdict', 'paper');
    paperVerdict = { 'all 3 methods agree', ...
                     'spherical-mode source UNSTABLE', ...
                     'all 3 methods agree' };
    for k = 1:size(cases,1)
        d = cases{k,2};
        if d >= minValidityRadius_m(2)
            verdict = 'HF method VALID (>= 40 cm)';
        elseif d >= minValidityRadius_m(1)
            verdict = 'HF method MARGINAL (30-40 cm)';
        else
            verdict = 'HF method NOT VALID (< 30 cm)';
        end
        fprintf('  %-22s %6.3f m     %-28s %s\n', cases{k,1}, d, verdict, paperVerdict{k});
    end
    fprintf('  -> the tool reproduces the paper''s method-selection decision from geometry alone.\n');

    % ---- GEO platform stand-off check (the paper''s application case) ----
    fc = 2.2e9;                         % ASSUMED_FOR_REPLICATION (paper: "S-band")
    geoStandoff_m = 0.40;               % PUBLIC_REPORTED: rod >= 40 cm
    fprintf('\nGEO application: S-band TC&R on a %.2f m rod -> %s\n', geoStandoff_m, ...
        'HF method with far-field source is applicable (as the paper chose)');
    fprintf('  neighbours reported: SBAS (L), DCS (L), fixed-comm (Ka), solar panels\n');

    % ---- Comparison-metric round trip against the paper''s reported ripple ----
    % IMPORTANT: this is NOT a reproduction of the paper's EM result. The tool cannot
    % compute an installed pattern. Here the paper's REPORTED 1-3 dB ripple envelope
    % is fed in as the installed pattern so we can verify that the comparison metric
    % READS BACK what the paper reports. It is an instrument check, not physics.
    free = rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(6, fc, 1);
    az = -180:5:180; el = -90:5:90;
    Ginst = zeros(numel(el), numel(az));
    for ie = 1:numel(el)
        for ia = 1:numel(az)
            g = free.evaluate(fc, az(ia), el(ie));
            % PUBLIC_REPORTED envelope: +-3 dB peak ripple, smooth in angle.
            ripple = reportedRipple_dB(2) * sind(3*az(ia)) * cosd(el(ie));
            Ginst(ie, ia) = g + ripple;
        end
    end
    grid = rfscreen.antenna.PatternGrid(az, el, fc, Ginst);
    installed = rfscreen.antenna.InstalledPattern('PAPER_REPORTED_RIPPLE_ENVELOPE_S', ...
        'SIMULATED_3D', grid, 'OTHER_SOLVER');

    sel = rfscreen.installed.InstalledPatternSelector.select(free, installed, 'PREFER_INSTALLED');
    fprintf('\nPattern selection: source=%s  validity=%s  provenance=%s (preserved)\n', ...
        sel.sourceUsed, sel.installationValidity, sel.provenance);

    % pass the SCRIPT's grid explicitly - otherwise PatternComparison silently uses
    % its own 15 deg default grid and the stated resolution is not what is measured.
    cmp = rfscreen.installed.PatternComparison.compare(free, installed, ...
        struct('frequency_Hz', fc, 'az_deg', az, 'el_deg', el));
    fprintf('\nComparison metric read-back (installed - free-space), n=%d grid pts:\n', cmp.nGrid);
    fprintf('  max abs difference   : %6.2f dB   (paper reports ripple <= %d dB)\n', ...
        cmp.maxAbsDifference_dB, reportedRipple_dB(2));
    fprintf('  RMS difference       : %6.2f dB\n', cmp.rmsDifference_dB);
    fprintf('  peak gain difference : %+6.2f dB\n', cmp.peakGainDifference_dB);
    if cmp.maxAbsDifference_dB <= reportedRipple_dB(2) + 1e-6
        fprintf('  -> metric reads back within the reported envelope (instrument OK).\n');
    else
        fprintf('  -> WARNING: metric exceeds the reported envelope.\n');
    end

    hr();
    fprintf('Reproducibility of THIS case:\n');
    fprintf('  Method-validity decision from stand-off distance : TIER 1  EXACT_NUMERICAL\n');
    fprintf('  Free-space vs installed comparison metric        : TIER 2  (instrument verified)\n');
    fprintf('  The installed pattern itself (1-3 dB ripple)     : TIER 4  MODEL_GAP_FULL_WAVE\n');
    fprintf('    -> paper used FEKO/HFSS; this tool consumes such data, never derives it.\n');
    fprintf('  Axial-ratio degradation (a headline result)      : TIER 4  MODEL_GAP_AXIAL_RATIO\n');
    fprintf('    -> the architecture owns NO polarization/axial-ratio channel at all.\n');
    fprintf('Comparison class: EXACT_NUMERICAL (method validity) ; NOT_COMPARABLE (EM ripple, AR)\n\n');
end
