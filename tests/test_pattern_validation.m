function test_pattern_validation(h)
%TEST_PATTERN_VALIDATION Deterministic validation of raw cut input (VR-118).
    h.setGroup('pattern_valid');
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane','XZ','angleRange','[-180,180]'));

    % empty
    h.eqStr('empty INVALID', vstatus([], [], conv), 'INVALID');
    % length mismatch
    h.eqStr('length mismatch INVALID', vstatus([0 1 2], [0 1], conv), 'INVALID');
    % NaN gain
    h.eqStr('NaN gain INVALID', vstatus([0 1 2], [0 NaN 2], conv), 'INVALID');
    % Inf angle
    h.eqStr('Inf angle INVALID', vstatus([0 Inf 2], [0 1 2], conv), 'INVALID');
    % non-numeric
    r = rfscreen.patterndata.PatternValidator.validateRaw('abc', [1 2 3], conv);
    h.eqStr('non-numeric INVALID', r.status, 'INVALID');
    % unsupported range (value beyond [-180,180])
    h.eqStr('out-of-range INVALID', vstatus([0 90 200], [1 2 3], conv), 'INVALID');
    % missing convention
    r2 = rfscreen.patterndata.PatternValidator.validateRaw([0 1], [0 1], []);
    h.eqStr('missing convention INVALID', r2.status, 'INVALID');
    % constructing importer with bad convention throws
    h.throws('bad convention throws', ...
        @() rfscreen.patterndata.TablePatternImporter([0 1], [0 1], 'notaconv', struct()), ...
        'rfscreen:patterndata:badConvention');

    % non-monotonic source -> warning (VALID_WITH_WARNINGS)
    r3 = rfscreen.patterndata.PatternValidator.validateRaw([0 5 3 10], [1 2 3 4], conv);
    h.eqStr('non-monotonic warns', r3.status, 'VALID_WITH_WARNINGS');
    h.isTrue('non-monotonic warning present', ~isempty(r3.warnings));

    % duplicate source angles -> warning
    r4 = rfscreen.patterndata.PatternValidator.validateRaw([0 90 90 180], [1 2 2 3], conv);
    h.eqStr('dup source warns', r4.status, 'VALID_WITH_WARNINGS');

    % valid clean data
    h.eqStr('clean VALID', vstatus([-90 0 90], [1 2 3], conv), 'VALID');

    % INVALID convention construction: zero and rotation axis not orthogonal
    h.throws('bad axis convention', ...
        @() rfscreen.patterndata.SourceCoordinateConvention( ...
            struct('plane','XZ','angleZeroAxis','+Z','positiveRotationToward','+Z')), ...
        'rfscreen:patterndata:badConvention');
end

function s = vstatus(theta, gain, conv)
    r = rfscreen.patterndata.PatternValidator.validateRaw(theta, gain, conv);
    s = r.status;
end
