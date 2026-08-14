function test_phase4_architecture(h)
%TEST_PHASE4_ARCHITECTURE Nonlinear architecture-boundary guards (VR-308).
    h.setGroup('phase4_arch');
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    srcDir = fullfile(repoRoot, 'src', '+rfscreen');
    nlDir = fullfile(srcDir, '+nonlinear');

    % ---- nonlinear layer parses no antenna-pattern files ----
    fileTokens = {'fileread','fopen','csvread','dlmread','textscan','patterndata','PatternGrid'};
    h.ok('nonlinear parses no files', isempty(scan(nlDir, fileTokens)));

    % ---- nonlinear layer computes no geometry (consumes pair evidence instead) ----
    geomTokens = {'DirectionCalculator','azElToDirection','AntennaToAntennaFOV','relativeGeometry','R_BA'};
    h.ok('nonlinear computes no geometry', isempty(scan(nlDir, geomTokens)));

    % ---- nonlinear consumes existing absolute pair evidence (reuses PairwiseAnalyzer) ----
    nsaTxt = fileread(fullfile(nlDir, 'NonlinearSusceptibilityAnalyzer.m'));
    h.isTrue('nonlinear reuses PairwiseAnalyzer', ~isempty(strfind(nsaTxt, 'PairwiseAnalyzer.analyze')));

    % ---- dBm not summed directly (aggregation uses linear helper) ----
    aggTxt = fileread(fullfile(nlDir, 'InterfererAggregator.m'));
    h.isTrue('aggregator uses sumPowers_dBm', ~isempty(strfind(aggTxt, 'sumPowers_dBm')));
    % sumPowers_dBm converts through watts
    unitsTxt = fileread(fullfile(srcDir, '+util', 'Units.m'));
    h.isTrue('sumPowers_dBm goes through watts', ~isempty(strfind(unitsTxt, 'dbm2w')));

    % ---- IIP3 model generates no TX spurious products ----
    txSpurTokens = {'harmonic','spectralRegrowth','regrowth','HPA','txSpur','phaseNoise','DACimage','LOleak'};
    h.ok('no TX-spurious generation in nonlinear', isempty(scan(nlDir, txSpurTokens)));

    % ---- mixer spur / ADC saturation remain deferred (not implemented) ----
    deferredTokens = {'mixerSpur','spurTable','adcSaturation','ADCclip'};
    h.ok('mixer spur / ADC deferred', isempty(scan(nlDir, deferredTokens)));

    % ---- pattern-only cannot drive P1dB/IIP3 physics (numeric guard) ----
    po = struct('txId',{'A','B'}, 'freq_Hz',{2.4e9,2.41e9}, ...
                'lnaInputPower_dBm',{NaN,NaN}, 'isAbsolute',{false,false}, ...
                'couplingValidity',{'PATTERN_ONLY','PATTERN_ONLY'});
    fe = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm',-5,'iip3_in_dBm',0,'provenance','SYNTHETIC_TEST'));
    cpo = rfscreen.nonlinear.CompressionAnalyzer.analyze(po, fe, []);
    h.isNaNval('pattern-only -> no compression margin', cpo.compressionMargin_dB);
    chan = rfscreen.receiver.IdealBandpassFilter([2.395e9 2.405e9],0,-Inf);
    ipo = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(po, fe, chan, [2.395e9 2.405e9], []);
    h.isTrue('pattern-only -> no IM3 products', isempty(ipo.products));

    % ---- blocking needs no spectral overlap ----
    oob = struct('txId',{'OOB'}, 'freq_Hz',{2.5e9}, 'lnaInputPower_dBm',{-10}, ...
                 'isAbsolute',{true}, 'couplingValidity',{'FAR_FIELD_VALID'});
    blk = rfscreen.nonlinear.BlockingAnalyzer.analyze(oob, 2.4e9, rfscreen.receiver.BlockingCriterion(-20));
    h.isTrue('out-of-band blocker still scored', isfinite(blk.worstMargin_dB));

    % ---- missing hardware never defaulted ----
    feEmpty = rfscreen.receiver.ReceiverFrontEnd(struct('provenance','SYNTHETIC_TEST'));
    h.isNaNval('no default P1dB', feEmpty.p1dB_in_dBm);
    h.isNaNval('no default IIP3', feEmpty.iip3_in_dBm);
    h.isFalse('no default P1dB present', feEmpty.hasP1dB());

    % ---- explicit reference plane on results ----
    h.eqStr('front-end plane LNA_INPUT', fe.referencePlane, 'LNA_INPUT');
    h.eqStr('compression plane LNA_INPUT', cpo.referencePlane, 'LNA_INPUT');

    % ---- Phase-3 linear result semantics unchanged (spot check) ----
    spec = rfscreen.spectrum.RectangularSpectrum(2.4e9,20e6,30,struct());
    filt = rfscreen.receiver.IdealBandpassFilter([2.39e9 2.41e9],0,-Inf);
    poSpatial = struct('txGain_dBi',0,'rxGain_dBi',0,'txPower_dBm',30,'absoluteTransfer_dB',NaN, ...
        'isAbsolute',false,'couplingValidity','PATTERN_ONLY');
    lin = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.analyze( ...
        struct('spatial',poSpatial,'txSpectrum',spec,'rxFilter',filt));
    h.eqStr('Phase-3 pattern-only still RELATIVE', lin.mode, 'RELATIVE_SCREENING');
    h.isNaNval('Phase-3 pattern-only still no P_I', lin.interferencePower_dBm);

    % ---- nonlinear layer has no UI ----
    uiTokens = {'uifigure','uicontrol','uipanel','uimenu','figure('};
    h.ok('nonlinear has no UI', isempty(scan(nlDir, uiTokens)));
end

function hits = scan(pathIn, tokens)
    hits = {};
    if exist(pathIn, 'dir') == 7
        files = listM(pathIn);
    else
        files = {pathIn};
    end
    for i = 1:numel(files)
        if exist(files{i}, 'file') ~= 2; continue; end
        t = fileread(files{i});
        for k = 1:numel(tokens)
            if ~isempty(strfind(t, tokens{k}))
                hits{end+1} = sprintf('%s in %s', tokens{k}, files{i}); %#ok<AGROW>
            end
        end
    end
end
function files = listM(d)
    files = {};
    items = dir(d);
    for i = 1:numel(items)
        it = items(i);
        if strcmp(it.name,'.') || strcmp(it.name,'..'); continue; end
        p = fullfile(d, it.name);
        if it.isdir
            files = [files, listM(p)]; %#ok<AGROW>
        elseif numel(it.name) > 2 && strcmp(it.name(end-1:end), '.m')
            files{end+1} = p; %#ok<AGROW>
        end
    end
end
