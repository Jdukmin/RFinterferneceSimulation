function rc_kari_01_structure_fov()
%RC_KARI_01_STRUCTURE_FOV Reproduction of the FOV-geometry result of:
%   임원규, 권기호, 김중표, 이선익, 김상구, 원영진, 문홍열, 이상곤,
%   "위성 구조체의 FOV 간섭에 의한 S 대역 안테나의 방사 특성 영향성 분석",
%   한국항공우주학회 2015 춘계학술발표회, pp. 832-835.
%
%   PAPER SETUP (all values below are PUBLIC_REPORTED from the paper text):
%     - S-band TC/TM antenna: Quadrifilar (4x inverted-F, 90 deg phasing),
%       circular polarization, HEMI-SPHERICAL pattern (+/-90 deg from main beam);
%       axial ratio 3 dB over about +/-55 deg.
%     - Blocking structure = the PAYLOAD antenna reflector (P-ANT), a dish on a
%       boom. The satellite BODY is deliberately EXCLUDED from the paper's model
%       (only S-band antenna + P-ANT are simulated).
%     - Real satellite size ~4 m; P-ANT height ~1000 mm in reality, i.e. the P-ANT
%       sits at x ~= 15 deg ELEVATION above the S-band antenna's mounting plane
%       (Fig. 1/Fig. 2). With a zenith-pointing hemispherical antenna that is
%       theta ~= 75 deg off boresight. The 1 dB margin is then evaluated NEAR
%       theta = 90 deg, where the shadow/reflection lobes appear (Fig. 5).
%     - Fig. 5 sweeps the P-ANT ANGULAR WIDTH: 4, 8, 12 deg.
%     - Fig. 6 sweeps the separation d = 350/425/500/575/650 mm (model scale),
%       with the diameter co-varied so the angular width stays fixed.
%     - Acceptance criterion: <= 1 dB radiation-characteristic change, evaluated
%       near 90 deg off the S-band main beam (TC/TM link-budget experience).
%     - REPORTED RESULT (Fig. 5, angular size sweep at the ~4 m stand-off):
%           4 deg angular width  <-> ~30 cm P-ANT diameter
%          12 deg angular width  <-> ~83 cm P-ANT diameter
%          at ~12 deg the 1 dB margin is exhausted near 90 deg off-boresight
%          => acceptable up to ~80 cm diameter at ~4 m.
%
%   WHAT THIS TOOL REPRODUCES: the ANGULAR SUBTENSE of the P-ANT seen from the
%   S-band antenna -- the geometric quantity the paper's sweep is parameterized
%   by. That is a direct numerical comparison (Tier 1/2).
%   WHAT IT DOES NOT: the dB gain deformation itself, which is the paper's EM
%   output and requires full-wave evidence (MODEL_GAP_FULL_WAVE, Tier 4).

    addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'src'));
    hr = @() fprintf('%s\n', repmat('-', 1, 78));
    fprintf('\n==================== RC-KARI-01: Structure FOV ====================\n');
    fprintf('Reference: 임원규 외, KSAS 2015 춘계, pp.832-835 (S-band RP vs structural FOV)\n');
    hr();

    % ---- Paper inputs (PUBLIC_REPORTED) ----
    standoff_m   = 4.0;      % PUBLIC_REPORTED: real satellite scale (~4 m)
    D_small_m    = 0.30;     % PUBLIC_REPORTED: "4 deg <-> about 30 cm"
    D_large_m    = 0.83;     % PUBLIC_REPORTED: "12 deg <-> about 83 cm"
    D_limit_m    = 0.80;     % PUBLIC_REPORTED: acceptable up to ~80 cm
    paperAng     = [4 12];   % PUBLIC_REPORTED angular widths [deg]
    criterion_dB = 1.0;      % PUBLIC_REPORTED: 1 dB allowance
    offAxis_deg  = 90;       % PUBLIC_REPORTED: margin evaluated near 90 deg off main beam
    pantElev_deg = 15;       % PUBLIC_REPORTED: x ~= 15 deg elevation (Fig. 1, Fig. 2)
    paperSweep   = [4 8 12]; % PUBLIC_REPORTED: Fig. 5 angular-width sweep [deg]

    fc = 2.2e9;              % ASSUMED_FOR_REPLICATION (paper says "S band", no exact f)

    fprintf('Paper inputs (PUBLIC_REPORTED unless noted):\n');
    fprintf('  S-band antenna     : Quadrifilar, CP, hemispherical (+/-90 deg)\n');
    fprintf('  blocking structure : payload-antenna reflector (P-ANT), dish on boom\n');
    fprintf('  satellite body     : EXCLUDED from the model (as in the paper)\n');
    fprintf('  stand-off distance : %.1f m\n', standoff_m);
    fprintf('  P-ANT elevation    : %d deg above the S-band mounting plane\n', pantElev_deg);
    fprintf('  criterion          : <= %.1f dB change near %d deg off main beam\n', ...
        criterion_dB, offAxis_deg);
    fprintf('  Fig.5 sweep        : angular width %s deg\n', mat2str(paperSweep));
    fprintf('  frequency          : %.2f GHz  (ASSUMED_FOR_REPLICATION)\n', fc/1e9);

    % ---- S-band antenna: hemispherical pattern, boresight +X_A at origin ----
    % Hemispherical => main region out to +/-90 deg. SYNTHETIC_TEST stand-in for
    % the paper's designed quadrifilar (its measured cut is not published).
    pat = rfscreen.antenna.SyntheticPatternFactory.mainSideBack(4, 0, -20, fc, 90);
    antPos = [0;0;0];
    R_BA   = eye(3);                       % boresight = +X body

    % ---- P-ANT at 15 deg elevation, at the ~4 m stand-off (Fig. 1 / Fig. 2) ----
    % Boresight (+X_A) is the antenna zenith; the mounting plane is the X=0 plane.
    % An elevation of 15 deg above that plane is theta = 75 deg off boresight.
    theta_deg  = 90 - pantElev_deg;                       % = 75 deg off-boresight
    pantCentre = standoff_m * [cosd(theta_deg); sind(theta_deg); 0];
    % Orient the dish FACE-ON to the S-band antenna: aboutY(90) sends the disk
    % normal (local +Z) onto +X, then aboutZ(theta) swings it onto the line of
    % sight. (Leaving it edge-on would collapse the azimuth footprint to zero.)
    R_BS = rfscreen.geometry.Rotation.aboutZ(theta_deg) * rfscreen.geometry.Rotation.aboutY(90);

    fprintf('\nAngular subtense of P-ANT vs the paper''s reported values:\n');
    fprintf('  %-10s %-12s %-14s %-14s %-10s\n', 'D [m]', 'paper [deg]', 'tool azSpan', 'tool 2*radius', 'delta');
    diams = [D_small_m, D_large_m];   % the two the paper translates to diameters
    for k = 1:numel(diams)
        D = diams(k);
        pant = rfscreen.geometry.SpacecraftStructure( ...
            sprintf('P_ANT_%dcm', round(D*100)), 'payload antenna reflector', 'REFLECTOR', ...
            rfscreen.geometry.DiskGeometry(D, 32), R_BS, pantCentre, ...
            struct('provenance', 'PUBLIC_REPORTED'));
        fov = rfscreen.geometry.AntennaToStructureFOV.analyze('ANT_S_TCTM', antPos, R_BA, pant, ...
            struct('pattern', pat, 'frequency_Hz', fc));
        tool = 2 * fov.maxAngularRadius_deg;
        fprintf('  %-10.2f %-12d %-14.2f %-14.2f %+.2f deg\n', ...
            D, paperAng(k), fov.azimuthSpan_deg, tool, tool - paperAng(k));
    end

    % ---- full Fig.5 sweep: angular width -> equivalent real diameter at 4 m ----
    fprintf('\nFig.5 sweep (angular width -> equivalent P-ANT diameter at %.1f m):\n', standoff_m);
    for a = paperSweep
        fprintf('  %2d deg -> D = %.3f m (%.0f cm)\n', a, 2*standoff_m*tand(a/2), 100*2*standoff_m*tand(a/2));
    end

    % ---- closed-form cross-check (independent of the FOV engine) ----
    fprintf('\nClosed-form check  2*atan(D/2/R):\n');
    for k = 1:numel(diams)
        fprintf('  D=%.2f m @ %.1f m -> %.2f deg   (paper: %d deg)\n', ...
            diams(k), standoff_m, 2*atand(diams(k)/2/standoff_m), paperAng(k));
    end
    fprintf('  acceptance limit D=%.2f m -> %.2f deg (paper: "up to ~80 cm acceptable")\n', ...
        D_limit_m, 2*atand(D_limit_m/2/standoff_m));

    % ---- what the geometry evidence says vs the paper's EM criterion ----
    pantLimit = rfscreen.geometry.SpacecraftStructure('P_ANT_LIMIT', 'P-ANT at accept limit', ...
        'REFLECTOR', rfscreen.geometry.DiskGeometry(D_limit_m, 32), R_BS, pantCentre, ...
        struct('provenance', 'PUBLIC_REPORTED'));
    fovL = rfscreen.geometry.AntennaToStructureFOV.analyze('ANT_S_TCTM', antPos, R_BA, pantLimit, ...
        struct('pattern', pat, 'frequency_Hz', fc));
    fprintf('\nAt the paper''s acceptance limit (D=%.2f m, %d deg elevation):\n', D_limit_m, pantElev_deg);
    fprintf('  centre off-boresight = %.1f deg   occupied lobes = {%s}\n', ...
        fovL.centerOffBoresight_deg, strjoin(fovL.occupiedLobes, ','));
    fprintf('  angular width        = %.2f deg   centre-ray hit = %d   distance = %.2f m\n', ...
        2*fovL.maxAngularRadius_deg, fovL.centerRayHits, fovL.closestDistance_m);

    hr();
    fprintf('Reproducibility of THIS case:\n');
    fprintf('  P-ANT angular subtense (the paper''s sweep parameter) : TIER 1  EXACT_NUMERICAL\n');
    fprintf('  Structure-in-FOV occupancy / lobe region             : TIER 2\n');
    fprintf('  Centre-ray blockage / distance                       : TIER 2\n');
    fprintf('  1 dB gain change from P-ANT scattering + reflection   : TIER 4  MODEL_GAP_FULL_WAVE\n');
    fprintf('    -> the paper obtained this by EM simulation; this tool does NOT\n');
    fprintf('       compute it and does NOT fabricate it.\n');
    fprintf('Comparison class: EXACT_NUMERICAL (angular subtense) ; NOT_COMPARABLE (dB change)\n');
    fprintf('No paper fitting. See RPT-P6-02 / RPT-P6-03.\n\n');
end
