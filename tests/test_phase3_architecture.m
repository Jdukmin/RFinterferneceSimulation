function test_phase3_architecture(h)
%TEST_PHASE3_ARCHITECTURE Phase-3 architecture-boundary guards (VR-213, VR-211, VR-212).
    h.setGroup('phase3_arch');
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    srcDir = fullfile(repoRoot, 'src', '+rfscreen');
    specDir = fullfile(srcDir, '+spectrum');
    recvDir = fullfile(srcDir, '+receiver');

    % ---- spectrum layer has no UI ----
    uiTokens = {'uifigure','uicontrol','uipanel','uimenu','uiaxes','appdesigner','figure('};
    h.ok('spectrum has no UI', isempty(scan(specDir, uiTokens)));
    h.ok('receiver has no UI', isempty(scan(recvDir, uiTokens)));

    % ---- receiver layer does not parse antenna pattern files ----
    fileTokens = {'fileread','fopen','csvread','dlmread','textscan','patterndata'};
    h.ok('receiver does not parse files', isempty(scan(recvDir, fileTokens)));
    h.ok('spectrum does not parse files', isempty(scan(specDir, fileTokens)));

    % ---- spectral analyzer computes no geometry ----
    geomTokens = {'DirectionCalculator','azElToDirection','AntennaToAntennaFOV','R_BA','relativeGeometry'};
    scaFile = fullfile(srcDir, '+interference', 'SpectralCouplingAnalyzer.m');
    h.ok('spectral analyzer has no geometry', isempty(scan(scaFile, geomTokens)));

    % ---- dB values not integrated directly: analyzer uses linear response/PSD ----
    txt = fileread(scaFile);
    h.isTrue('spectral uses responseLinear', ~isempty(strfind(txt, 'responseLinear')));
    h.isTrue('spectral uses psd_WPerHz', ~isempty(strfind(txt, 'psd_WPerHz')));
    h.isFalse('spectral does not call responseDb', ~isempty(strfind(txt, 'responseDb')));

    % ---- FrequencyRelation classification not used as spectral power ----
    h.isFalse('spectral analyzer free of FrequencyRelation', ~isempty(strfind(txt, 'FrequencyRelation')));

    % ---- screening risk policy is NOT a physical interference criterion ----
    rp = rfscreen.config.RiskPolicy();
    crit = rfscreen.receiver.InterferenceCriterion('I_N_MAX', -6);
    h.isFalse('RiskPolicy is not InterferenceCriterion', isa(rp, 'rfscreen.receiver.InterferenceCriterion'));
    h.isFalse('InterferenceCriterion is not RiskPolicy', isa(crit, 'rfscreen.config.RiskPolicy'));
    % susceptibility analyzer does not use screening RiskPolicy/FrequencyRelation
    suscTxt = fileread(fullfile(recvDir, 'ReceiverSusceptibilityAnalyzer.m'));
    h.isFalse('susceptibility free of RiskPolicy', ~isempty(strfind(suscTxt, 'RiskPolicy')));
    h.isFalse('susceptibility free of FrequencyRelation', ~isempty(strfind(suscTxt, 'FrequencyRelation')));

    % ---- pattern-only directional index not mislabeled absolute coupling loss ----
    poSpatial = struct('txGain_dBi',0,'rxGain_dBi',0,'txPower_dBm',30, ...
        'absoluteTransfer_dB',NaN,'isAbsolute',false,'couplingValidity','PATTERN_ONLY');
    spec = rfscreen.spectrum.RectangularSpectrum(2.2e9,20e6,30,struct());
    filt = rfscreen.receiver.IdealBandpassFilter([2.18e9 2.22e9],0,-Inf);
    rpo = rfscreen.receiver.ReceiverSusceptibilityAnalyzer.analyze( ...
        struct('spatial',poSpatial,'txSpectrum',spec,'rxFilter',filt));
    h.isNaNval('pattern-only never yields absolute P_I', rpo.interferencePower_dBm);

    % ---- nonlinear receiver models remain unimplemented (reserved NaN) ----
    fe = rfscreen.rf.RFFrontEnd(struct());
    h.isNaNval('p1dB reserved NaN', fe.p1dB_dBm);
    h.isNaNval('iip3 reserved NaN', fe.iip3_dBm);
    nlTokens = {'intermod','compression','blocking','iip3Compute','P1dBCompute','mixerSpur','saturation'};
    h.ok('no nonlinear physics in receiver layer', isempty(scan(recvDir, nlTokens)));

    % ---- spectrum layer depends only downward (no interference/geometry) ----
    h.ok('spectrum free of interference/geometry deps', ...
        isempty(scan(specDir, {'+interference','geometry.','DirectionCalculator'})));

    % ---- coexistence analyzer REUSES Phase-1 InterferenceAnalyzer ----
    coexTxt = fileread(fullfile(srcDir, '+interference', 'RfCoexistenceAnalyzer.m'));
    h.isTrue('coexistence reuses InterferenceAnalyzer', ...
        ~isempty(strfind(coexTxt, 'InterferenceAnalyzer.analyze')));
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
