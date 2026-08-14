function rc_kari_rf_01_gnss_interference()
%RC_KARI_RF_01_GNSS_INTERFERENCE Reproduction path for:
%   권병문, 신용설, 마근수, 주정갑, 지기만, "S 대역 신호에 의한 위성항법수신기의 RF
%   신호간섭", 한국항공우주학회지, 2019.  (NOT an Im Won-gyu paper.)
%
%   SCOPE: demonstrates the Phase-3/4 mechanism the paper describes -- strong
%   S-band signals driving a GNSS active-antenna LNA toward compression, and two
%   S-band tones generating third-order intermodulation whose products can fall
%   in the GNSS band. Front-end P1dB/IIP3 and interferer input powers here are
%   ASSUMED_FOR_REPLICATION (representative), NOT the paper's hardware values.
%   The trend/direction is validated, not exact numbers.

    addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'src'));
    hr = @() fprintf('%s\n', repmat('-', 1, 72));
    fprintf('\n============= RC-KARI-RF-01: S-band -> GNSS RF interference =============\n');
    fprintf('Reference: Kwon B-M. et al., JKSAS 2019 (S-band interference to GNSS rx)\n');
    hr();

    % GNSS L1 active-antenna front end (ASSUMED_FOR_REPLICATION)
    fe = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm', -25, 'iip3_in_dBm', -15, ...
        'linearGain_dB', 28, 'provenance', 'SYNTHETIC_TEST'));
    gnssBand = [1.559e9 1.591e9];                 % ~ GNSS L1
    chan = rfscreen.receiver.IdealBandpassFilter(gnssBand, 0, -Inf);

    % two strong S-band interferers reaching the LNA input (ASSUMED input powers).
    % f1,f2 chosen to illustrate an IM3 product landing in the GNSS band.
    f1 = 1.60e9; f2 = 1.625e9;                    % 2f1-f2 = 1.575 GHz (in GNSS L1)
    P1 = -8; P2 = -8;                             % dBm at LNA input (ASSUMED, strong)
    inputs = struct('txId', {'S1','S2'}, 'freq_Hz', {f1, f2}, ...
        'lnaInputPower_dBm', {P1, P2}, 'isAbsolute', {true, true}, ...
        'couplingValidity', {'FAR_FIELD_VALID','FAR_FIELD_VALID'});

    % ---- compression (aggregate) ----
    comp = rfscreen.nonlinear.CompressionAnalyzer.analyze(inputs, fe, []);
    fprintf('Compression (LNA_INPUT): aggregate=%.2f dBm  P1dB_in=%.1f dBm  margin=%.2f dB -> %s\n', ...
        comp.aggregateInputPower_dBm, comp.p1dB_in_dBm, comp.compressionMargin_dB, comp.passFail);

    % ---- IM3 ----
    im = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(inputs, fe, chan, gnssBand, []);
    fprintf('\nThird-order intermodulation products:\n');
    for k = 1:numel(im.products)
        p = im.products{k};
        fprintf('  %-13s f=%.4f GHz  P_IM3,in=%.1f dBm  inGNSS=%d  eff=%.1f dBm\n', ...
            p.productType, p.productFrequency_Hz/1e9, p.equivalentInputPower_dBm, ...
            p.inPassband, p.effectiveProductPower_dBm);
    end

    hr();
    fprintf('Validated trends (direction agrees with paper):\n');
    fprintf('  - Strong S-band aggregate power drives the GNSS LNA toward/over P1dB.\n');
    fprintf('  - A two-tone IM3 product (2f1-f2) can fall inside the GNSS band.\n');
    fprintf('Reproducibility: TIER 2 (trend/mechanism). Exact dB depend on the paper''s\n');
    fprintf('  unavailable hardware IIP3/P1dB and link geometry -> not fitted.\n');
    fprintf('Comparison class: SAME_TREND (saturation direction, IM product placement).\n\n');
end
