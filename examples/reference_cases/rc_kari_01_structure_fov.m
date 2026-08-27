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
%     - Real satellite size ~4 m; P-ANT height ~1000 mm in reality.
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
    offAxis_deg  = 90;       % PUBLIC_REPORTED: evaluated near 90 deg off main beam

    fc = 2.2e9;              % ASSUMED_FOR_REPLICATION (paper says "S band", no exact f)

    fprintf('Paper inputs (PUBLIC_REPORTED unless noted):\n');
    fprintf('  S-band antenna     : Quadrifilar, CP, hemispherical (+/-90 deg)\n');
    fprintf('  blocking structure : payload-antenna reflector (P-ANT), dish on boom\n');
    fprintf('  satellite body     : EXCLUDED from the model (as in the paper)\n');
    fprintf('  stand-off distance : %.1f m\n', standoff_m);
    fprintf('  criterion          : <= %.1f dB change near %d deg off main beam\n', ...
        criterion_dB, offAxis_deg);
    fprintf('  frequency          : %.2f GHz  (ASSUMED_FOR_REPLICATION)\n', fc/1e9);

    % ---- S-band antenna: hemispherical pattern, boresight +X_A at origin ----
    % Hemispherical => main region out to +/-90 deg. SYNTHETIC_TEST stand-in for
    % the paper's designed quadrifilar (its measured cut is not published).
    pat = rfscreen.antenna.SyntheticPatternFactory.mainSideBack(4, 0, -20, fc, 90);
    antPos = [0;0;0];
    R_BA   = eye(3);                       % boresight = +X body

    % ---- P-ANT placed near 90 deg off the S-band main beam, at the stand-off ----
    % The paper's concern is a structure in the +/-90 deg hemisphere; the margin is
    % exhausted NEAR 90 deg, so the P-ANT centre is put at 90 deg off-boresight.
    pantCentre = [0; standoff_m; 0];        % 90 deg off +X, at 4 m
    % dish plane faces the S-band antenna (disk normal +Z_S -> point it along -Y_B)
    R_BS = rfscreen.geometry.Rotation.aboutX(90);

    fprintf('\nAngular subtense of P-ANT vs the paper''s reported values:\n');
    fprintf('  %-10s %-12s %-14s %-14s %-10s\n', 'D [m]', 'paper [deg]', 'tool azSpan', 'tool 2*radius', 'delta');
    diams = [D_small_m, D_large_m];
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
    fprintf('\nAt the paper''s acceptance limit (D=%.2f m):\n', D_limit_m);
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
