function test_pattern_frame(h)
%TEST_PATTERN_FRAME Source-frame theta->direction and source->antenna axis
%   mapping (VR-116).
    h.setGroup('pattern_frame');
    SCC = @(o) rfscreen.patterndata.SourceCoordinateConvention(o);

    % ---- theta -> source direction (descriptor-driven) ----
    xz = SCC(struct('plane','XZ'));
    h.eqTol('XZ theta0 -> +Z', xz.directionForTheta(0),   [0;0;1], 1e-12);
    h.eqTol('XZ theta90 -> +X', xz.directionForTheta(90),  [1;0;0], 1e-12);
    h.eqTol('XZ theta180 -> -Z', xz.directionForTheta(180), [0;0;-1], 1e-12);
    h.eqTol('XZ theta270 -> -X', xz.directionForTheta(270), [-1;0;0], 1e-12);

    yz = SCC(struct('plane','YZ'));
    h.eqTol('YZ theta90 -> +Y', yz.directionForTheta(90),  [0;1;0], 1e-12);
    h.eqTol('YZ theta270 -> -Y', yz.directionForTheta(270), [0;-1;0], 1e-12);

    % negative-rotation source convention recovers canonical theta geometrically
    xzNeg = SCC(struct('plane','XZ','positiveRotationToward','-X','angleRange','[-180,180]'));
    [tc, off] = rfscreen.patterndata.PatternCanonicalizer.canonicalThetaFor('XZ', xzNeg.directionForTheta(90));
    h.eqTol('neg-rotation 90 -> canonical 270', tc, 270, 1e-9);
    h.eqTol('in-plane (off~0)', off, 0, 1e-12);

    % ---- source -> antenna map M (+Z boresight -> +X_A) ----
    M = rfscreen.patterndata.CutPatternAssembler.canonicalToAntenna();
    h.isTrue('M is a rotation', rfscreen.geometry.Rotation.isRotationMatrix(M));
    h.eqTol('M: +Z -> +X', M*[0;0;1], [1;0;0], 1e-12);
    h.eqTol('M: +X -> +Y', M*[1;0;0], [0;1;0], 1e-12);
    h.eqTol('M: +Y -> +Z', M*[0;1;0], [0;0;1], 1e-12);

    % ---- assembled pattern: known axis points (VR-116) ----
    peak = 12;
    xzc = makeCut('XZ', peak);
    yzc = makeCut('YZ', peak);
    p = rfscreen.patterndata.CutPatternAssembler.assembleFreeSpacePattern( ...
        'SYNTHETIC_TEST_AX', xzc, yzc, struct('frequency_Hz',2.2e9,'azStep_deg',2,'elStep_deg',2));
    f = 2.2e9;
    h.eqTol('boresight -> peak', p.evaluate(f, 0, 0), peak, 1e-6);
    gX = peak + 20*log10(cosd(45)^2);     % source theta=90 gain
    h.eqTol('+X at az90,el0', p.evaluate(f, 90, 0), gX, 1e-6);
    h.eqTol('-X at az-90,el0', p.evaluate(f, -90, 0), gX, 1e-6);
    h.eqTol('+Y at az0,el90', p.evaluate(f, 0, 90), gX, 1e-6);
    h.eqTol('-Y at az0,el-90', p.evaluate(f, 0, -90), gX, 1e-6);
    gBack = peak + 20*log10(1e-3);        % source theta=180 (floored)
    h.eqTol('back at az180,el0', p.evaluate(f, 180, 0), gBack, 1e-6);
end

function cut = makeCut(plane, peak)
    theta = -180:1:180;
    g = peak + 20*log10(max(cosd(theta/2).^2, 1e-3));
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane',plane,'angleRange','[-180,180]'));
    imp = rfscreen.patterndata.TablePatternImporter(theta, g, conv, ...
        struct('patternId',['SYNTHETIC_TEST_' plane],'fidelity','SYNTHETIC_TEST','frequency_Hz',2.2e9));
    cut = imp.importCut();
end
