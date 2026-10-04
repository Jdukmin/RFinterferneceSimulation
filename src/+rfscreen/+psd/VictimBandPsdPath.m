classdef VictimBandPsdPath
    %VICTIMBANDPSDPATH PRIMARY RFI path: victim-band unwanted-emission PSD over the victim tuning band.
    %   TX compliant source emission -> optional filter -> victim-band EM coupling -> victim-port PSD
    %   -> allowable victim PSD -> margin / required additional suppression:
    %     PSD_victim_port(f)       = PSD_TX_spec(f) - L_filter(f) - L_post(f) + C(f)      [dBm/Hz]
    %     margin(f)                = PSD_allowable(f) - PSD_victim_port(f)                 [dB]
    %     required_add_supp(f)     = max(0, PSD_victim_port(f) - PSD_allowable(f))         [dB]
    %     max_allowable_TX_PSD(f)  = PSD_allowable(f) - C(f) + L_filter(f) + L_post(f)     [dBm/Hz at the source plane]
    %   Coupling C by source reference plane (never applied twice):
    %     conducted (PA_OUTPUT .. ANTENNA_PORT): C = C_EM = G_tx(f_v) + G_rx(f_v) - FSPL(f_v)  (or S21)
    %       -> needs the TX antenna response IN THE VICTIM BAND (Ka: KAA_VICTIM_BAND_RADIATION_RESPONSE_MISSING)
    %     RADIATED_EIRP_PSD: C = G_rx(f_v) - FSPL(f_v)  (TX gain already inside the EIRP; no L_post)
    %   L_post: cable/waveguide loss downstream of a PA_OUTPUT / FILTER_INPUT / FILTER_OUTPUT source;
    %   unknown -> 0 dB (conservative, flagged). Without a source: coupling and the allowable TX PSD
    %   only; no PASS/FAIL (EMISSION_SPEC_MISSING).
    %   Independent of the attacker carrier: the victim antenna response at the TX carrier frequency
    %   (blocker band) is never needed here.
    properties (Constant)
        PATH = 'VICTIM_BAND_EMISSION_PSD'
        ST_SPEC = 'EMISSION_SPEC_MISSING'
        ST_COUPLING = 'COUPLING_INPUT_MISSING'
        ST_KAA = 'KAA_VICTIM_BAND_RADIATION_RESPONSE_MISSING'
        ST_NODEF = 'MASK_NOT_DEFINED_AT_FREQUENCY'
        ST_FILTER = 'FILTER_NOT_DEFINED_AT_FREQUENCY'
    end
    methods (Static)
        function R = evaluate(f_Hz, cConducted_dB, cRadiated_dB, allowable_dBmHz, specs, carrier_dBm, filt, post_dB, txIsKaa)
            %EVALUATE Per-frequency result for one pair, one source set (one plane) and one filter scenario.
            %   cConducted_dB: G_tx+G_rx-FSPL (NaN where the TX victim-band response is missing)
            %   cRadiated_dB : G_rx-FSPL      (NaN where the victim response is missing)
            %   specs: cell of BROADBAND_PSD EmissionSpec (may be empty); filt: FilterScenario
            if nargin < 8 || isempty(post_dB); post_dB = NaN; end
            if nargin < 9; txIsKaa = false; end
            P = rfscreen.psd.PsdMath; K = rfscreen.psd.VictimBandPsdPath;
            n = numel(f_Hz); Lf = filt.attenuationAt(f_Hz);
            R = struct('f_Hz', f_Hz, 'filter_id', filt.id, 'filter_dB', Lf, 'filter_provenance', filt.provenance, ...
                'post_dB', zeros(1, n), 'post_flag', '', 'plane', '', 'source_psd_dBmHz', NaN(1, n), ...
                'coupling_dB', NaN(1, n), 'coupling_route', '', 'allowable_dBmHz', allowable_dBmHz * ones(1, n), ...
                'port_psd_dBmHz', NaN(1, n), 'margin_dB', NaN(1, n), 'required_add_supp_dB', NaN(1, n), ...
                'max_tx_psd_conducted_dBmHz', allowable_dBmHz - cConducted_dB + Lf, ...
                'max_tx_eirp_psd_dBmHz', allowable_dBmHz - cRadiated_dB + Lf, 'status', {repmat({''}, 1, n)});
            if isempty(specs)
                st = K.ST_SPEC;
                if all(isnan(cRadiated_dB)); st = K.ST_COUPLING; end
                R.status(:) = {st};
                return;
            end
            planes = unique(cellfun(@(s) s.referencePlane, specs, 'UniformOutput', false));
            if numel(planes) ~= 1
                error('rfscreen:psd:mixedPlanes', 'one TX/band source set must use one reference plane (got %s).', strjoin(planes, ', '));
            end
            if any(cellfun(@(s) ~strcmp(s.emissionType, 'BROADBAND_PSD'), specs))
                error('rfscreen:psd:notAPsd', 'discrete spurs/harmonics are evaluated by spurPortPower, not on the PSD mask.');
            end
            R.plane = planes{1}; radiated = specs{1}.isRadiated();
            if radiated
                C = cRadiated_dB; R.coupling_route = 'RADIATED_EIRP: G_rx - FSPL (TX gain inside EIRP)';
                R.max_tx_psd_conducted_dBmHz(:) = NaN;
            else
                C = cConducted_dB; R.coupling_route = 'CONDUCTED: G_tx + G_rx - FSPL at f_victim';
                R.max_tx_eirp_psd_dBmHz(:) = NaN;
                if any(strcmp(R.plane, {'PA_OUTPUT', 'FILTER_INPUT', 'FILTER_OUTPUT'}))
                    if isnan(post_dB); R.post_flag = 'POST_FILTER_LOSS_UNKNOWN_0DB_CONSERVATIVE'; else; R.post_dB(:) = post_dB; end
                end
            end
            R.coupling_dB = C;
            R.max_tx_psd_conducted_dBmHz = R.max_tx_psd_conducted_dBmHz + R.post_dB;
            for i = 1:n
                hit = find(cellfun(@(s) s.covers(f_Hz(i)), specs));
                if isempty(hit)
                    pts = cellfun(@(s) isnan(s.freqLo_Hz), specs);
                    fm = cellfun(@(s) s.freq_Hz, specs(pts));
                    if numel(fm) >= 2 && f_Hz(i) >= min(fm) && f_Hz(i) <= max(fm)
                        pm = cellfun(@(s) s.psdDbmHz(carrier_dBm), specs(pts)); [fm, o] = sort(fm);
                        R.source_psd_dBmHz(i) = interp1(fm, pm(o), f_Hz(i), 'linear');
                    else
                        R.status{i} = K.ST_NODEF; continue;
                    end
                else
                    R.source_psd_dBmHz(i) = max(cellfun(@(s) s.psdDbmHz(carrier_dBm), specs(hit)));
                end
                if isnan(Lf(i)); R.status{i} = K.ST_FILTER; continue; end
                if isnan(C(i))
                    if txIsKaa && ~radiated; R.status{i} = K.ST_KAA; else; R.status{i} = K.ST_COUPLING; end
                    continue;
                end
                R.port_psd_dBmHz(i) = P.applyAttenuation(R.source_psd_dBmHz(i), Lf(i) + R.post_dB(i)) + C(i);
                R.margin_dB(i) = P.margin(R.allowable_dBmHz(i), R.port_psd_dBmHz(i));
                R.required_add_supp_dB(i) = max(0, P.requiredSuppression(R.port_psd_dBmHz(i), R.allowable_dBmHz(i)));
                R.status(i) = P.maskStatus(R.margin_dB(i));
            end
        end

        function p = spurPortPower(spec, carrier_dBm, filter_dB, coupling_dB)
            %SPURPORTPOWER Discrete spur / harmonic at the victim port [dBm] (not a PSD; 2nd stage only).
            %   coupling: conducted C_EM, or G_rx - FSPL for a RADIATED_EIRP source.
            p = rfscreen.psd.PsdMath.applyAttenuation(spec.powerDbm(carrier_dBm), filter_dB) + coupling_dB;
        end
    end
end
