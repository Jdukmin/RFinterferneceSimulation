classdef VictimBandPsdPath
    %VICTIMBANDPSDPATH Victim-band unwanted-emission path (1st stage: PSD mask over the tuning band).
    %   PSD_TX(f)          = P_carrier + mask(f)                     [dBm/Hz] (or dBm/Hz as given)
    %   PSD_after_chain(f) = PSD_TX(f) - L_TXchain(f)                [dB attenuation, per reference plane]
    %   PSD_port(f)        = PSD_after_chain(f) + C_EM(f)            [C_EM at the victim frequency]
    %   margin(f)          = PSD_allowable(f) - PSD_port(f)
    %   Independent of the fundamental OOB blocker path (blocker port power in dBm at the TX carrier).
    %   Without a mask the coupling is still reported together with the emission limit it implies
    %   at the TX antenna port: PSD_TX,max(f) = PSD_allowable - C_EM(f) (a derived requirement, not a result).
    properties (Constant)
        PATH = 'VICTIM_BAND_EMISSION_PSD'
        ST_MISSING = 'EMISSION_MASK_MISSING_COUPLING_EVALUATED'
        ST_CHAIN = 'TX_CHAIN_LOSS_MISSING'
        ST_NODEF = 'MASK_NOT_DEFINED_AT_FREQUENCY'
    end
    methods (Static)
        function R = evaluate(f_Hz, coupling_dB, allowable_dBmHz, specs, carrier_dBm, chain)
            %EVALUATE Per-frequency rows. specs: cell of BROADBAND_PSD EmissionSpec of one TX/band
            %   (one reference plane); chain: struct(filter_dB, post_dB) per frequency or scalar (NaN unknown).
            P = rfscreen.psd.PsdMath; K = rfscreen.psd.VictimBandPsdPath;
            n = numel(f_Hz);
            R = struct('f_Hz', f_Hz, 'tx_psd_dBmHz', NaN(1, n), 'chain_dB', NaN(1, n), 'coupling_dB', coupling_dB, ...
                'port_psd_dBmHz', NaN(1, n), 'allowable_dBmHz', allowable_dBmHz * ones(1, n), 'margin_dB', NaN(1, n), ...
                'required_psd_suppression_dB', NaN(1, n), 'max_tx_psd_at_antenna_port_dBmHz', allowable_dBmHz - coupling_dB, ...
                'status', {repmat({K.ST_MISSING}, 1, n)}, 'plane', '', 'emission_type', 'BROADBAND_PSD');
            if isempty(specs); return; end
            planes = unique(cellfun(@(s) s.referencePlane, specs, 'UniformOutput', false));
            if numel(planes) ~= 1
                error('rfscreen:psd:mixedPlanes', 'one TX/band mask must use one reference plane (got %s).', strjoin(planes, ', '));
            end
            if any(cellfun(@(s) ~strcmp(s.emissionType, 'BROADBAND_PSD'), specs))
                error('rfscreen:psd:notAPsd', 'discrete spurs/harmonics are evaluated by spurPortPower, not on the PSD mask.');
            end
            R.plane = planes{1};
            fm = cellfun(@(s) s.freq_Hz, specs); pm = cellfun(@(s) s.psdDbmHz(carrier_dBm), specs);
            [fm, o] = sort(fm); pm = pm(o);
            [chainLoss, withTx] = specs{1}.chainTerms(chain);
            if ~withTx
                error('rfscreen:psd:eirpNeedsRxOnlyCoupling', ['RADIATED_EIRP_PSD: pass the G_rx - FSPL coupling ' ...
                    '(VictimBandCoupling.patternRoute(..., false)) and call evaluateEirp.']);
            end
            R = K.fill(R, fm, pm, chainLoss);
        end

        function R = evaluateEirp(f_Hz, couplingRxOnly_dB, allowable_dBmHz, specs)
            %EVALUATEEIRP Radiated EIRP PSD [dBm/Hz]: no chain loss, no TX gain (coupling = G_rx - FSPL).
            K = rfscreen.psd.VictimBandPsdPath;
            if any(cellfun(@(s) ~strcmp(s.referencePlane, 'RADIATED_EIRP_PSD') || ~strcmp(s.unit, 'dBm/Hz'), specs))
                error('rfscreen:psd:notEirp', 'evaluateEirp needs RADIATED_EIRP_PSD specs in dBm/Hz.');
            end
            R = K.evaluate(f_Hz, couplingRxOnly_dB, allowable_dBmHz, {}, NaN, struct());
            R.plane = 'RADIATED_EIRP_PSD';
            fm = cellfun(@(s) s.freq_Hz, specs); pm = cellfun(@(s) s.level, specs);
            [fm, o] = sort(fm); pm = pm(o);
            R = K.fill(R, fm, pm, 0);
            R.max_tx_psd_at_antenna_port_dBmHz(:) = NaN;      % EIRP form: limit is EIRP PSD, not port PSD
        end

        function p = spurPortPower(spec, carrier_dBm, chain, coupling_dB)
            %SPURPORTPOWER Discrete spur / harmonic at the victim port [dBm] (not a PSD; 2nd-stage only).
            [chainLoss, withTx] = spec.chainTerms(chain);
            if ~withTx
                p = spec.powerDbm(carrier_dBm) + coupling_dB;      % EIRP-referenced: coupling = G_rx - FSPL
            else
                p = rfscreen.psd.PsdMath.applyAttenuation(spec.powerDbm(carrier_dBm), chainLoss) + coupling_dB;
            end
        end
    end
    methods (Static, Access = private)
        function R = fill(R, fm, pm, chainLoss)
            P = rfscreen.psd.PsdMath; K = rfscreen.psd.VictimBandPsdPath;
            for i = 1:numel(R.f_Hz)
                f = R.f_Hz(i);
                if f < fm(1) - 1 || f > fm(end) + 1
                    R.status{i} = K.ST_NODEF; continue;
                end
                if numel(fm) == 1; R.tx_psd_dBmHz(i) = pm(1); else; R.tx_psd_dBmHz(i) = interp1(fm, pm, f, 'linear'); end
                cl = chainLoss; if numel(cl) > 1; cl = cl(i); end
                if isnan(cl); R.status{i} = K.ST_CHAIN; continue; end
                R.chain_dB(i) = cl;
                R.port_psd_dBmHz(i) = P.victimPortPsd(R.tx_psd_dBmHz(i), cl, R.coupling_dB(i));
                R.margin_dB(i) = P.margin(R.allowable_dBmHz(i), R.port_psd_dBmHz(i));
                R.required_psd_suppression_dB(i) = max(0, P.requiredSuppression(R.port_psd_dBmHz(i), R.allowable_dBmHz(i)));
                R.status(i) = P.maskStatus(R.margin_dB(i));
            end
        end
    end
end
