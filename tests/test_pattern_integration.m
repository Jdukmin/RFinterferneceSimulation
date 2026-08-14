function test_pattern_integration(h)
%TEST_PATTERN_INTEGRATION Imported canonical cuts -> assembled pattern -> EXISTING
%   Phase-1 PairwiseAnalyzer; CSV importer; resampler (VR-119, VR-120).
    h.setGroup('pattern_integration');

    % ---- assemble APPROX_FROM_CUTS pattern from synthetic external-style cuts ----
    xz = makeCut('XZ', 14);
    yz = makeCut('YZ', 14);
    pTx = rfscreen.patterndata.CutPatternAssembler.assembleFreeSpacePattern( ...
        'SYNTHETIC_TEST_TXCUT', xz, yz, struct('frequency_Hz', 2.2e9));
    pRx = rfscreen.patterndata.CutPatternAssembler.assembleFreeSpacePattern( ...
        'SYNTHETIC_TEST_RXCUT', xz, yz, struct('frequency_Hz', 2.2e9));

    % fidelity / provenance preserved; 2D cut never labeled true 3D (VR-119)
    h.eqStr('assembled is APPROX_FROM_CUTS', pTx.provenance, 'APPROX_FROM_CUTS');
    h.isFalse('not MEASURED_3D', strcmp(pTx.provenance, 'MEASURED_3D'));
    h.isFalse('not SIMULATED_3D', strcmp(pTx.provenance, 'SIMULATED_3D'));
    h.isTrue('cut fidelity stays 2D-capable', rfscreen.patterndata.PatternFidelity.isValid(xz.fidelity));

    % ---- feed the EXISTING Phase-1 engine unchanged (VR-120) ----
    opts = struct('rxThreshold_dBm', -70);
    sc = testutil.Fixtures.twoAntennaScenario(pTx, pRx, [12;0;0], [-1;0;0], opts);
    mr = rfscreen.interference.InterferenceAnalyzer.analyze(sc);
    pr = mr.getPair('TX1', 'RX1');
    h.isTrue('pair analyzed', ~isempty(pr.riskLevel));
    h.eqStr('result provenance = APPROX_FROM_CUTS', pr.provenance.txPatternProvenance, 'APPROX_FROM_CUTS');
    h.eqStr('coupling still pattern-only', pr.couplingModelType, 'PATTERN_ONLY');
    % main-main geometry: both boresight -> peak gains -> high directional index
    h.eqTol('tx gain ~ peak', pr.txGain_dBi, 14, 1e-4);
    h.eqStr('in-band', pr.frequencyRelation, 'IN_BAND');

    % ---- CSV importer equivalence ----
    tmp = [tempname() '.csv'];
    fid = fopen(tmp, 'w');
    fprintf(fid, 'theta_deg,gain_dBi\n');
    theta = -180:2:180;
    g = 10 + 20*log10(max(cosd(theta/2).^2, 1e-3));
    for i = 1:numel(theta); fprintf(fid, '%.6f,%.6f\n', theta(i), g(i)); end
    fclose(fid);
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane','XZ','angleRange','[-180,180]'));
    meta = struct('patternId','SYNTHETIC_TEST_CSV','fidelity','SYNTHETIC_TEST','frequency_Hz',2.2e9);
    csvCut = rfscreen.patterndata.CsvPatternImporter(tmp, conv, meta).importCut();
    tblCut = rfscreen.patterndata.TablePatternImporter(theta, g, conv, meta).importCut();
    delete(tmp);
    h.eqTol('CSV==Table theta', csvCut.theta_deg, tblCut.theta_deg, 1e-6);
    h.eqTol('CSV==Table gain', csvCut.gain_dBi, tblCut.gain_dBi, 1e-6);
    h.eqStr('CSV sourceType', csvCut.provenance.sourceType, 'CSV');

    % ---- resampler: native preservation ----
    orig = tblCut;
    origTheta = orig.theta_deg;
    rs = rfscreen.patterndata.PatternResampler.resample(orig, 0:1:359);
    h.isTrue('resampled flagged', rs.provenance.resamplingApplied);
    h.ok('resampled grid size', rs.numSamples() == 360);
    h.isFalse('source not resample-flagged', orig.provenance.resamplingApplied);
    h.eqTol('source grid unchanged', orig.theta_deg, origTheta, 0);
    % resampled values match interpolation of the source at those angles
    h.eqTol('resample value @37', rs.evaluate(37), orig.evaluate(37), 1e-9);
end

function cut = makeCut(plane, peak)
    theta = -180:1:180;
    g = peak + 20*log10(max(cosd(theta/2).^2, 1e-3));
    conv = rfscreen.patterndata.SourceCoordinateConvention(struct('plane',plane,'angleRange','[-180,180]'));
    imp = rfscreen.patterndata.TablePatternImporter(theta, g, conv, ...
        struct('patternId',['SYNTHETIC_TEST_' plane],'fidelity','SYNTHETIC_TEST','frequency_Hz',2.2e9));
    cut = imp.importCut();
end
