function rc_kari_03_installation_analysis()
%RC_KARI_03_INSTALLATION_ANALYSIS Architecture-boundary validation for:
%   이선익, 임원규, "위성항법 정지궤도위성 원격측정명령계 S대역 안테나 설치위치에서의
%   전자장 해석", KARI research stream, 2025.
%
%   This case is primarily a FIDELITY-BOUNDARY validation: it shows what the
%   current geometry/pattern tool CAN reproduce about an installed-location
%   analysis and what requires full-wave EM evidence (which this tool does not
%   own). Producing a Tier-4 boundary here is a CORRECT architectural result,
%   not a software failure.

    addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'src'));
    hr = @() fprintf('%s\n', repmat('-', 1, 72));
    fprintf('\n========== RC-KARI-03: Installed-location analysis (boundary) ==========\n');
    fprintf('Reference: Lee S-I., Im W-G., KARI 2025 (TT&C S-band installed-location EM)\n');
    hr();

    fc = 2.2e9;
    % candidate installation locations on the bus (ASSUMED_FOR_REPLICATION)
    locs = { {'LOC_A', [0;0;1.0], rfscreen.geometry.Rotation.aboutY(-90)}, ...   % +Z face
             {'LOC_B', [1.0;0;0], eye(3)} };                                     % +X face
    pat = rfscreen.antenna.SyntheticPatternFactory.mainSideBack(11, -9, -25, fc, 20);

    % a nearby appendage that may obstruct depending on location
    boom = rfscreen.geometry.SpacecraftStructure('BOOM','boom', 'BOOM', ...
        rfscreen.geometry.BoxGeometry([0.1;0.1;1.2]), eye(3), [0.5;0;1.4], ...
        struct('provenance','SYNTHETIC_TEST'));

    fprintf('Per-location geometry evidence (reproducible):\n');
    for i = 1:numel(locs)
        L = locs{i};
        fov = rfscreen.geometry.AntennaToStructureFOV.analyze(L{1}, L{2}, L{3}, boom, ...
            struct('pattern', pat, 'frequency_Hz', fc));
        fprintf('  %-6s: boom off-boresight=%6.1f deg  lobes={%s}  centreRayHit=%d  dist=%.2f m\n', ...
            L{1}, fov.centerOffBoresight_deg, strjoin(fov.occupiedLobes, ','), ...
            fov.centerRayHits, fov.closestDistance_m);
    end

    hr();
    fprintf('Fidelity boundary for this case:\n');
    fprintf('  Installation position            : reproducible        (TIER 1)\n');
    fprintf('  Structure FOV / obstruction       : reproducible        (TIER 2)\n');
    fprintf('  LOS / blockage                    : reproducible        (TIER 2)\n');
    fprintf('  Installed pattern (if data given) : reproducible        (TIER 2-3)\n');
    fprintf('  Scattering-generated RP change    : NOT reproducible    (TIER 4 MODEL_GAP_SCATTERING)\n');
    fprintf('  Reflection                        : NOT reproducible    (TIER 4 MODEL_GAP_REFLECTION)\n');
    fprintf('  Diffraction                       : NOT reproducible    (TIER 4 MODEL_GAP_DIFFRACTION)\n');
    fprintf('These Tier-4 items are the CORRECT architecture boundary (no HFSS/CST here).\n\n');
end
