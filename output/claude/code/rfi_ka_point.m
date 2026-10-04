function r = rfi_ka_point(kaM, F, P_dBm, pK, R_BLk, pV, R_BLv, resp)
%RFI_KA_POINT KAA -> victim direct reflector near field and victim-port power at one KAA pointing.
%   kaM   : rfscreen.kaa.ReflectorApertureModel (validated KAA aperture)
%   F     : Ka monitor frequencies [Hz]; P_dBm: KAA TX accepted power
%   pK/pV : KAA aperture centre / victim reference point (body, m)
%   R_BLk : KAA aperture (CST-local) DCM for this pointing; R_BLv: victim CST-local DCM
%   resp  : rfscreen.kaa.KaVictimResponse (Ka out-of-band response; may be INPUT_MISSING)
%   Victim gain toward the KAA aperture centre (geometric direction); port power =
%   S * lambda^2/(4 pi) * G_rx (local plane-wave incidence). No victim gain -> P_port = NaN.
    A = rfscreen.kaa.CstLocalFrameAdapter; S = rfscreen.kaa.ApertureNearFieldSolver;
    rL = A.pointToLocal(R_BLk, pK, pV);
    [th, ph] = A.thetaPhi(rL);
    dV = A.bodyToLocal(R_BLv, (pK(:) - pV(:)) / norm(pK(:) - pV(:)));
    [thv, phv] = A.thetaPhi(dV);
    n = numel(F);
    r = struct('r_L', rL, 'theta_ap', th, 'phi_ap', ph, 'theta_v', thv, 'phi_v', phv, 'd', norm(rL), ...
        'E_dBuVpm', NaN(1, n), 'S_Wpm2', NaN(1, n), 'S_dBmpm2', NaN(1, n), 'Geq_dBi', NaN(1, n), ...
        'Grx_dBi', NaN(1, n), 'P_port_dBm', NaN(1, n), 'P_port_band_dBm', NaN, ...
        'S_band_dBmpm2', NaN, 'Pref0_dBm', NaN(1, n));
    for k = 1:n
        e = S.evaluate(kaM, F(k), P_dBm, rL);
        r.E_dBuVpm(k) = e.E_dBuVpm; r.S_Wpm2(k) = e.S_Wpm2; r.S_dBmpm2(k) = e.S_dBmpm2; r.Geq_dBi(k) = e.Geq_dBi;
        r.Pref0_dBm(k) = S.portPower_dBm(e.S_Wpm2, 0, F(k));      % ASSUMPTION_ONLY reference (0 dBi), never a result
        if resp.isAvailable()
            r.Grx_dBi(k) = resp.gainAt(F(k), dV);
            r.P_port_dBm(k) = S.portPower_dBm(e.S_Wpm2, r.Grx_dBi(k), F(k));
        end
    end
    r.S_band_dBmpm2 = 10 * log10(mean(r.S_Wpm2)) + 30;
    if resp.isAvailable(); r.P_port_band_dBm = 10 * log10(mean(10 .^ (r.P_port_dBm / 10))); end
end
