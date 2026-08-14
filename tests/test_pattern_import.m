function test_pattern_import(h)
%TEST_PATTERN_IMPORT Variable angular step, step detection, sample counts,
%   -180..180 -> 0..360 conversion + ordering, sampling classification
%   (VR-110, VR-111, VR-117).
    h.setGroup('pattern_import');
    PD = @patterndataNS;

    % ---- VR-110 different steps handled independently ----
    cutA = importXZ(-180:0.25:180, 'SYNTHETIC_TEST_A');   % 0.25 deg
    cutB = importYZ(0:1:359,      'SYNTHETIC_TEST_B');    % 1.0 deg, [0,360) input
    cutC = importXZ(-180:0.5:180, 'SYNTHETIC_TEST_C');    % 0.5 deg

    h.eqStr('A UNIFORM', cutA.samplingType, 'UNIFORM');
    h.eqTol('A step 0.25', cutA.nominalStep_deg, 0.25, 1e-9);
    h.ok('A count 1440', cutA.numSamples() == 1440);      % -180 & 180 merge -> 1440

    h.eqStr('B UNIFORM', cutB.samplingType, 'UNIFORM');
    h.eqTol('B step 1.0', cutB.nominalStep_deg, 1.0, 1e-9);
    h.ok('B count 360', cutB.numSamples() == 360);

    h.eqStr('C UNIFORM', cutC.samplingType, 'UNIFORM');
    h.eqTol('C step 0.5', cutC.nominalStep_deg, 0.5, 1e-9);
    h.ok('C count 720', cutC.numSamples() == 720);

    % steps are per-dataset, not a global constant
    h.isFalse('A and B differ in step', cutA.nominalStep_deg == cutB.nominalStep_deg);

    % ---- VR-111 -180..180 -> 0..360 conversion + ordering ----
    th = [-180 -90 0 90 179 180];
    g  = [ -5    2  10  3   1  -5];   % -180 and 180 equal so they merge cleanly
    cut = importXZraw(th, g, 'SYNTHETIC_TEST_conv');
    h.eqTol('canonical theta vector', cut.theta_deg, [0 90 179 180 270], 1e-9);
    h.isTrue('theta ascending', all(diff(cut.theta_deg) > 0));
    h.isTrue('theta in [0,360)', all(cut.theta_deg >= 0) && all(cut.theta_deg < 360));
    % -90 -> 270 (gain 2), 180 present once (gain -5), 0 -> 10
    h.eqTol('-90 -> 270 gain', cut.gain_dBi(cut.theta_deg == 270), 2, 1e-9);
    h.eqTol('180 gain (merged)', cut.gain_dBi(abs(cut.theta_deg - 180) < 1e-9), -5, 1e-9);
    h.eqTol('0 gain', cut.gain_dBi(cut.theta_deg == 0), 10, 1e-9);

    % ---- VR-117 sampling classification ----
    nonU = importXZraw([0 1 5 6 20], [0 0 0 0 0], 'SYNTHETIC_TEST_nonU');
    h.eqStr('non-uniform detected', nonU.samplingType, 'NON_UNIFORM');
    h.isTrue('non-uniform nominalStep NaN', isnan(nonU.nominalStep_deg));

    % single-sample -> INVALID sampling (but structurally importable)
    one = importXZraw([30], [3], 'SYNTHETIC_TEST_one');
    h.eqStr('single-sample INVALID sampling', one.samplingType, 'INVALID');
end

% ---- local helpers (SYNTHETIC_TEST fixtures only) ----
function cut = importXZ(theta, id)
    g = 10 + 20*log10(max(cosd(theta/2).^2, 1e-3));
    cut = importXZraw(theta, g, id);
end
function cut = importYZ(theta, id)
    g = 8 + 20*log10(max(cosd(theta/2).^2, 1e-3));
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane','YZ','angleRange','[0,360)'));
    imp = rfscreen.patterndata.TablePatternImporter(theta, g, conv, ...
        struct('patternId', id, 'fidelity', 'SYNTHETIC_TEST', 'frequency_Hz', 2.2e9));
    cut = imp.importCut();
end
function cut = importXZraw(theta, gain, id)
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane','XZ','angleRange','[-180,180]'));
    imp = rfscreen.patterndata.TablePatternImporter(theta, gain, conv, ...
        struct('patternId', id, 'fidelity', 'SYNTHETIC_TEST', 'frequency_Hz', 2.2e9));
    cut = imp.importCut();
end
function n = patterndataNS(); n = 1; end
