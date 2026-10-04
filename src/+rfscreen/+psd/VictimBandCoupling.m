classdef VictimBandCoupling
    %VICTIMBANDCOUPLING EM coupling C_EM(f_victim) for the victim-band unwanted-emission path.
    %   Always evaluated AT THE VICTIM FREQUENCY (never with the TX operating-band gain):
    %     C_EM(f) = G_tx,realized(f) + G_rx,realized(f) - FSPL(f)        (pattern route)
    %     C_EM(f) = S21(f)                                                (direct port-to-port route;
    %                                                                      G_tx/G_rx/FSPL not added)
    %   RADIATED_EIRP_PSD emission: G_tx is already inside the EIRP -> C = G_rx(f) - FSPL(f);
    %   combining an EIRP spec with S21 (which contains the TX antenna) is refused.
    %   RealizedGain already contains the antenna mismatch: no separate S11 loss is applied.
    methods (Static)
        function c = patternRoute(txResp, rxResp, victimBand, f_Hz, dT, dR, d_m, includeTxGain)
            if nargin < 8; includeTxGain = true; end
            P = rfscreen.psd.PsdMath;
            c = struct('gtx_dBi', NaN, 'grx_dBi', NaN, 'fspl_dB', P.fspl(f_Hz, d_m), 'coupling_dB', NaN, ...
                'route', 'PATTERN_GTX_GRX_FSPL');
            c.grx_dBi = rxResp.gainAt(victimBand, f_Hz, dR);
            if includeTxGain
                c.gtx_dBi = txResp.gainAt(victimBand, f_Hz, dT);
                c.coupling_dB = c.gtx_dBi + c.grx_dBi - c.fspl_dB;
            else
                c.route = 'EIRP_GRX_FSPL (TX gain inside EIRP)';
                c.coupling_dB = c.grx_dBi - c.fspl_dB;
            end
        end

        function c = s21Route(s21_dB, includeTxGain)
            if ~includeTxGain
                error('rfscreen:psd:eirpWithS21', ['an EIRP-referenced emission cannot use S21 (S21 already contains ' ...
                    'the TX antenna); use G_rx - FSPL instead.']);
            end
            c = struct('gtx_dBi', NaN, 'grx_dBi', NaN, 'fspl_dB', NaN, 'coupling_dB', s21_dB, 'route', 'S21_DIRECT');
        end
    end
end
