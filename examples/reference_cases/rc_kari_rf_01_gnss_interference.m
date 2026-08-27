function rc_kari_rf_01_gnss_interference()
%RC_KARI_RF_01_GNSS_INTERFERENCE Reproduction path for:
%   권병문, 신용설, 마근수, 주정갑, 지기만, "S 대역 신호에 의한 위성항법수신기의 RF
%   신호간섭", 한국항공우주학회지 (JKSAS) Vol.47 No.5, pp.388-396, 2019.
%   (NOT an Im Won-gyu paper. The platform is a TEST LAUNCH VEHICLE (시험발사체),
%    not a satellite.)
%
%   PAPER MECHANISM (from the published abstract - the full text is not available
%   here, and the abstract carries NO numeric values):
%     - S-band transmitters on the test launch vehicle radiate signals whose
%       strength at the GNSS antenna is far above the navigation-satellite signals.
%     - The LNA of the ACTIVE GNSS antenna is SATURATED by those S-band signals.
%     - Whenever TWO S-band signals are received, an intermodulation signal
%       FALLING IN THE GNSS BAND is generated in the LNA.
%     - The receiver's computed C/N0 is severely degraded.
%
%   HONEST STATUS OF THIS SCRIPT (read before using any number):
%     * No hardware value in the paper is public, so P1dB/IIP3/tone powers here are
%       ASSUMED_FOR_REPLICATION. Nothing is fitted to the paper.
%     * The paper's regime is SATURATION. The small-signal IM3 law
%       P_IM3,in = 2Pa+Pb-2*IIP3 is NOT valid there; the analyzer now says so
%       (validity OUTSIDE_MODEL_DOMAIN) instead of returning a bogus level. That
%       is the honest result: this tool cannot quantify IM in compression.
%     * S-band is 2-4 GHz. An earlier version of this script used 1.60/1.625 GHz
%       tones - which are L-band, not S-band - chosen so that 2f1-f2 would land in
%       L1. That was reverse-engineering the conclusion and has been removed.

    addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'src'));
    hr = @() fprintf('%s\n', repmat('-', 1, 78));
    fprintf('\n============= RC-KARI-RF-01: S-band -> GNSS RF interference =============\n');
    fprintf('Reference: 권병문 외, JKSAS 47(5) pp.388-396, 2019 (test launch vehicle)\n');
    hr();

    S_BAND   = [2.0e9 4.0e9];        % definition of S-band
    L1_BAND  = [1.559e9 1.591e9];    % GNSS L1
    F_L1     = 1.57542e9;

    % GNSS L1 active-antenna front end (ALL ASSUMED_FOR_REPLICATION)
    fe = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm', -25, 'iip3_in_dBm', -15, ...
        'linearGain_dB', 28, 'provenance', 'SYNTHETIC_TEST'));
    chan = rfscreen.receiver.IdealBandpassFilter(L1_BAND, 0, -Inf);

    % ---- 1. Which S-band tone PAIRS can put an IM3 product in L1? -------------
    % This is a real, transferable screening question, answered from arithmetic
    % alone: 2*f1 - f2 = f_L1  =>  f2 = 2*f1 - f_L1. Report whether the required
    % partner tone is itself inside S-band.
    fprintf('IM3-into-L1 screening for S-band tone pairs (2*f1 - f2 = %.5f GHz):\n', F_L1/1e9);
    fprintf('  %-12s %-16s %-14s %s\n', 'f1 [GHz]', 'required f2 [GHz]', 'f2 in S-band?', 'spacing [MHz]');
    feasible = [];
    for f1 = [2.00e9 2.05e9 2.20e9 2.25e9 2.30e9]
        f2 = 2*f1 - F_L1;
        inS = (f2 >= S_BAND(1)) && (f2 <= S_BAND(2));
        fprintf('  %-12.3f %-16.4f %-14s %.1f\n', f1/1e9, f2/1e9, ternary(inS,'YES','NO'), (f2-f1)/1e6);
        if inS && isempty(feasible); feasible = [f1 f2]; end
    end
    fprintf('  -> a two-tone IM3 lands in L1 only for WIDELY SPACED S-band tones;\n');
    fprintf('     closely spaced telemetry tones (e.g. 2.20 & 2.25 GHz) cannot do it.\n');

    if isempty(feasible)
        fprintf('\nNo feasible in-band S-band pair found; stopping.\n'); return;
    end
    f1 = feasible(1); f2 = feasible(2);
    fprintf('\nUsing the feasible S-band pair: f1 = %.4f GHz, f2 = %.4f GHz\n', f1/1e9, f2/1e9);

    % ---- 2. Compression: does the aggregate saturate the LNA? -----------------
    P1 = -8; P2 = -8;                            % dBm at LNA input (ASSUMED, strong)
    inputs = struct('txId', {'S1','S2'}, 'freq_Hz', {f1, f2}, ...
        'lnaInputPower_dBm', {P1, P2}, 'isAbsolute', {true, true}, ...
        'couplingValidity', {'FAR_FIELD_VALID','FAR_FIELD_VALID'});
    comp = rfscreen.nonlinear.CompressionAnalyzer.analyze(inputs, fe, []);
    fprintf('\nCompression at LNA_INPUT (ASSUMED levels):\n');
    fprintf('  aggregate = %.2f dBm   P1dB_in = %.1f dBm   margin = %.2f dB -> %s\n', ...
        comp.aggregateInputPower_dBm, comp.p1dB_in_dBm, comp.compressionMargin_dB, comp.passFail);
    fprintf('  -> reproduces the paper''s stated mechanism: the LNA IS SATURATED.\n');

    % ---- 3. IM3 in the saturated regime: the model must refuse ----------------
    im = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(inputs, fe, chan, L1_BAND, []);
    fprintf('\nIM3 analysis (same, saturated, levels):  top-level validity = %s\n', im.validity);
    for k = 1:numel(im.products)
        p = im.products{k};
        fprintf('  %-13s f = %.5f GHz  inL1 = %d  validity = %s\n', ...
            p.productType, p.productFrequency_Hz/1e9, p.inPassband, p.validity);
        for w = 1:numel(p.warnings)
            fprintf('      ! %s\n', p.warnings{w});
        end
    end
    fprintf('  -> the PRODUCT FREQUENCY (%.5f GHz, inside L1) is reproduced exactly;\n', ...
        im.products{1}.productFrequency_Hz/1e9);
    fprintf('     the product LEVEL is withheld because the device is compressing.\n');

    % ---- 4. Same pair, small-signal levels: the model applies ------------------
    Psmall = -40;                                 % ASSUMED, well below P1dB_in
    inputs2 = struct('txId', {'S1','S2'}, 'freq_Hz', {f1, f2}, ...
        'lnaInputPower_dBm', {Psmall, Psmall}, 'isAbsolute', {true, true}, ...
        'couplingValidity', {'FAR_FIELD_VALID','FAR_FIELD_VALID'});
    im2 = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(inputs2, fe, chan, L1_BAND, []);
    q = im2.products{1};
    fprintf('\nSame pair at small-signal levels (%d dBm/tone): validity = %s\n', Psmall, im2.validity);
    fprintf('  %s  f = %.5f GHz  P_IM3,in = %.1f dBm  (%.1f dB below the tone)  inL1 = %d\n', ...
        q.productType, q.productFrequency_Hz/1e9, q.equivalentInputPower_dBm, ...
        Psmall - q.equivalentInputPower_dBm, q.inPassband);

    hr();
    fprintf('Reproducibility of THIS case:\n');
    fprintf('  IM3 product FREQUENCY landing in the GNSS band  : TIER 1  EXACT_NUMERICAL\n');
    fprintf('  Required S-band tone spacing for that to happen : TIER 1  (arithmetic)\n');
    fprintf('  LNA saturation by strong S-band signals (trend)  : TIER 2  SAME_TREND\n');
    fprintf('  IM3 LEVEL in the saturated regime               : NOT SUPPORTED\n');
    fprintf('    -> OUTSIDE_MODEL_DOMAIN. A compressed-regime IM level needs a measured\n');
    fprintf('       or full-nonlinear device model; it is withheld, not fabricated.\n');
    fprintf('  C/N0 degradation (the paper''s headline result)   : TIER 4  (no C/N0 channel)\n');
    fprintf('Comparison class: EXACT_NUMERICAL (product freq) ; SAME_TREND (saturation) ;\n');
    fprintf('                  NOT_COMPARABLE (levels, C/N0). No paper fitting.\n\n');
end

function out = ternary(c, a, b)
    if c; out = a; else; out = b; end
end
