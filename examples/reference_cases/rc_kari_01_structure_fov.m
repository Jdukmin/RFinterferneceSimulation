function rc_kari_01_structure_fov()
%RC_KARI_01_STRUCTURE_FOV Reproduction of the FOV-geometry portion of:
%   임원규 외, "위성 구조체의 FOV 간섭에 의한 S 대역 안테나의 방사 특성 영향성 분석",
%   한국항공우주학회 학술발표회, 2015.
%
%   SCOPE: this script reproduces the GEOMETRIC field-of-view evidence (which
%   structures enter the antenna FOV, angular footprint, LOS blockage). It does
%   NOT reproduce the electromagnetic radiation-pattern change reported in the
%   paper -- that requires full-wave/measured installed-pattern evidence and is a
%   declared model boundary (MODEL_GAP_FULL_WAVE, Tier 4).
%
%   All geometry values below are ASSUMED_FOR_REPLICATION (a representative
%   reconstruction) -- the paper's exact CAD is not public here. Nothing is
%   presented as flight data (provenance = SYNTHETIC_TEST).

    addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'src'));
    hr = @() fprintf('%s\n', repmat('-', 1, 72));
    fprintf('\n==================== RC-KARI-01: Structure FOV ====================\n');
    fprintf('Reference: Im W-G. et al., KSAS 2015 (structure FOV effect on S-band RP)\n');
    fprintf('Reproduced domain: Phase-5 antenna-to-structure FOV + LOS (geometry only)\n');
    hr();

    % ---- Inputs (all ASSUMED_FOR_REPLICATION) ----
    fc = 2.2e9;                                   % ASSUMED_FOR_REPLICATION (S-band TT&C)
    antPos = [0;0;1.0];                           % ASSUMED: antenna on +Z bus face
    R_BA   = rfscreen.geometry.Rotation.aboutY(-90);  % ASSUMED: boresight along +Z body
    fprintf('Inputs (provenance = ASSUMED_FOR_REPLICATION):\n');
    fprintf('  frequency          : %.3f GHz\n', fc/1e9);
    fprintf('  antenna position   : [%.2f %.2f %.2f] m (on +Z bus face)\n', antPos);
    fprintf('  antenna boresight  : +Z body (via R_BA)\n');

    % antenna pattern (synthetic directional S-band cut, SYNTHETIC_TEST)
    pat = rfscreen.antenna.SyntheticPatternFactory.mainSideBack(12, -8, -25, fc, 20);

    % spacecraft structures (representative): bus box + a deployed solar array panel
    bus = rfscreen.geometry.SpacecraftStructure('BUS','bus', 'BUS', ...
        rfscreen.geometry.BoxGeometry([0.75;0.75;0.75]), eye(3), [0;0;0], ...
        struct('provenance','SYNTHETIC_TEST'));
    % solar array: large panel offset in +Z, tilted so an edge enters the antenna FOV
    panel = rfscreen.geometry.SpacecraftStructure('SA','solar array', 'SOLAR_ARRAY', ...
        rfscreen.geometry.PanelGeometry(2.5, 1.5), rfscreen.geometry.Rotation.aboutX(20), ...
        [0.6;0;2.5], struct('provenance','SYNTHETIC_TEST','deploymentState','DEPLOYED'));

    % ---- Run FOV for each structure + a boresight reference direction ----
    fprintf('\nAntenna-to-structure FOV (VERTEX_SAMPLED, geometry evidence only):\n');
    for st = {bus, panel}
        fov = rfscreen.geometry.AntennaToStructureFOV.analyze('ANT_TTC', antPos, R_BA, st{1}, ...
            struct('pattern', pat, 'frequency_Hz', fc));
        fprintf('  %-12s type=%-11s off-boresight=%6.1f deg  azSpan=%5.1f deg  lobes={%s}  hit=%d  dist=%.2f m\n', ...
            st{1}.id, fov.structureType, fov.centerOffBoresight_deg, fov.azimuthSpan_deg, ...
            strjoin(fov.occupiedLobes, ','), fov.centerRayHits, fov.closestDistance_m);
    end

    % ---- Reproducibility & model gaps ----
    hr();
    fprintf('Reproducibility (this script):\n');
    fprintf('  Structure relative direction / FOV occupancy : TIER 2 (trend reproducible)\n');
    fprintf('  Main/side/back interaction (occupied lobes)  : TIER 2\n');
    fprintf('  Angular footprint (beyond centre point)      : TIER 2\n');
    fprintf('  Radiation-pattern (gain) DEFORMATION from     \n');
    fprintf('    structure scattering/diffraction           : TIER 4  MODEL_GAP_FULL_WAVE\n');
    fprintf('Comparison class: SAME_TREND (geometry) ; NOT_COMPARABLE (EM RP change)\n');
    fprintf('No paper fitting; no fabricated EM loss. See RPT-P6-02 / RPT-P6-03.\n\n');
end
