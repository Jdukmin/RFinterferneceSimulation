function test_pattern_duplicates(h)
%TEST_PATTERN_DUPLICATES +-180 and 0/360 duplicate resolution, conflict policy
%   (VR-112, VR-113).
    h.setGroup('pattern_dup');

    % ---- VR-112 equivalent +-180 duplicate -> one 180 sample, VALID ----
    th = [-180 -90 0 90 180];
    g  = [-25.0  2  10  3 -25.0];
    out = importResult(th, g, '[-180,180]', struct());
    cut = out.cut;
    h.eqStr('equiv dup VALID', cut.validationStatus, 'VALID');
    h.ok('one 180 sample', sum(abs(cut.theta_deg - 180) < 1e-9) == 1);
    h.ok('4 canonical samples', cut.numSamples() == 4);
    h.ok('duplicate recorded', ~isempty(cut.provenance.duplicates));
    h.eqStr('merge within tol', cut.provenance.duplicates(1).resolution, 'merged_mean_within_tolerance');

    % within tolerance but not exactly equal -> merged mean, VALID
    out2 = importResult([-180 0 180], [-25.01 5 -25.00], '[-180,180]', struct());
    h.eqStr('near-equal VALID', out2.cut.validationStatus, 'VALID');
    h.eqTol('merged mean value', out2.cut.gain_dBi(abs(out2.cut.theta_deg-180)<1e-9), -25.005, 1e-6);

    % ---- VR-112 conflicting +-180 duplicate ----
    thc = [-180 0 180];
    gc  = [-30   5  -20];    % differ by 10 dB >> tolerance
    outWarn = importResult(thc, gc, '[-180,180]', struct('duplicateConflictPolicy','warn'));
    h.eqStr('conflict warn -> VALID_WITH_WARNINGS', outWarn.cut.validationStatus, 'VALID_WITH_WARNINGS');
    h.isTrue('conflict warning present', ~isempty(outWarn.cut.warnings));
    h.eqTol('conflict difference recorded', outWarn.cut.provenance.duplicates(1).difference_dB, 10, 1e-9);
    h.eqStr('conflict resolution merged_with_warning', ...
        outWarn.cut.provenance.duplicates(1).resolution, 'merged_mean_with_warning');
    % evidence: both source angles retained
    h.ok('source angles recorded', numel(outWarn.cut.provenance.duplicates(1).sourceAngles) == 2);

    outErr = importResult(thc, gc, '[-180,180]', struct('duplicateConflictPolicy','error'));
    h.isTrue('conflict error -> no cut', isempty(outErr.cut));
    h.eqStr('conflict error INVALID', outErr.validation.status, 'INVALID');
    h.isTrue('conflict error issue recorded', ~isempty(outErr.validation.issues));

    % ---- VR-113 0/360 duplicate -> single 0 sample ----
    th0 = [0 90 180 270 360];
    g0  = [10 3 -5 2 10];    % 0 and 360 equal
    out0 = importResult(th0, g0, '[0,360)', struct());
    h.eqStr('0/360 VALID', out0.cut.validationStatus, 'VALID');
    h.ok('0/360 -> 4 samples', out0.cut.numSamples() == 4);
    h.ok('single 0 sample', sum(abs(out0.cut.theta_deg - 0) < 1e-9) == 1);
    h.isFalse('no 360 retained', any(abs(out0.cut.theta_deg - 360) < 1e-9));
end

function out = importResult(theta, gain, rng, polOpts)
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane','XZ','angleRange', rng));
    imp = rfscreen.patterndata.TablePatternImporter(theta, gain, conv, ...
        struct('patternId','SYNTHETIC_TEST_dup','fidelity','SYNTHETIC_TEST','frequency_Hz',2.2e9));
    policy = rfscreen.config.PatternImportPolicy(polOpts);
    out = imp.importCutResult(policy);
end
