function test_stc_lband_rescaling(h)
%TEST_STC_LBAND_RESCALING Task 1: S-TC TX (legacy S_TM_TX) GPS L2/L5 port-mismatch rescaled route.
    h.setGroup('stc_lband_rescaling');
    repo = fileparts(fileparts(mfilename('fullpath')));
    PM = rfscreen.psd.PortMismatchRescaledResponse; V = rfscreen.psd.VictimBandPsdPath; P = rfscreen.psd.PsdMath;
    prov = jsondecode(fileread(fullfile(repo, 'data', 'antenna_port_response_cst', 'provenance.json')));

    % ---- unreliable CST RealizedGain kept but excluded ----
    for vb = {'L2', 'L5'}
        r = rfscreen.psd.BandResponse.fromRepository(repo, 'S', vb{1}, prov);
        h.eqStr(sprintf('S/%s RealizedGain still INPUT_UNRELIABLE (kept, not deleted)', vb{1}), r.status, 'INPUT_UNRELIABLE');
        u = PM.unreliableStatus(repo, 'S', vb{1}, prov);
        h.eqStr(sprintf('S/%s CST value present but normalization unreliable', vb{1}), u.status, PM.UNRELIABLE);
        h.isFalse(sprintf('S/%s unreliable value not used', vb{1}), u.used);
    end
    u2 = PM.unreliableStatus(repo, 'S', 'L2', prov); u5 = PM.unreliableStatus(repo, 'S', 'L5', prov);
    h.eqTol('S/L2 unreliable RealizedGain peak [dBi]', u2.peak_dBi, -11.3, 0.05);
    h.eqTol('S/L5 unreliable RealizedGain peak [dBi]', u5.peak_dBi, -12.2, 0.05);
    h.eqStr('S/L1 normalization reliable', PM.unreliableStatus(repo, 'S', 'L1', prov).status, 'NORMALIZATION_RELIABLE');

    % ---- rescaled response ----
    m = PM.fromRepository(repo, 'S', {'L1', 'L2'}, -10, prov);
    h.eqTol('accepted-power Gain envelope peak [dBi]', m.peakEnvelope_dBi(), 5.98, 0.01);
    h.eqTol('envelope uses 4 reliable Gain frequencies', numel(m.envelopeSources), 4, 0);
    g1 = rfscreen.kaa.KaVictimResponse.readCut(fullfile(repo, 'data', 'antenna_port_response_cst', 'S', 'L1', 'f1.57542_Gain_XZ.csv'));
    h.isTrue('envelope >= each source Gain cut', all(m.xz >= g1 - 1e-12));
    d = [0.3; -0.4; 0.8];
    h.eqTol('effective gain = envelope - 10 dB', m.effectiveGainAt(d), m.envelopeGainAt(d) - 10, 1e-12);
    h.throws('positive rescaling refused', @() PM.fromRepository(repo, 'S', {'L1'}, 3, prov), 'rfscreen:psd:badRescaling');
    h.throws('band without Gain cuts refused (no fallback)', @() PM.fromRepository(repo, 'S', {'L5'}, -10, prov), 'rfscreen:psd:noGainCuts');
    h.eqTol('L1 accepted-power fraction reference ~ -10 dB', 10 * log10(0.0957210492547327), -10.19, 0.01);
    RS = rfscreen.spacecraft.SpacecraftDataReader.readTable(fullfile(repo, 'data', 'rfi_psd', 'tx_port_mismatch_rescaling.csv'));
    h.isTrue('rescaling rows: L2/L5, -10 dB, OWNER_ENGINEERING_BOUND', isequal(sort(RS.victim_band), {'L2', 'L5'}) && ...
        all(strcmp(RS.rescaling_db, '-10')) && all(strcmp(RS.provenance, PM.PROVENANCE)));

    % ---- ITU source and chain ----
    masks = rfscreen.psd.EmissionMaskTable.read(fullfile(repo, 'data', 'rfi_psd', 'stc_itu_spurious_source.csv'));
    s = masks(cellfun(@(x) strcmp(x.victimBand, 'L2'), masks)); s = s{1};
    h.eqTol('S-TC ITU source 5 W -> -49.0206 dBm/Hz', s.psdDbmHz(36.9897), -49.0206, 1e-3);
    h.eqTol('effective L2 source after -10 dB [dBm/Hz]', s.psdDbmHz(36.9897) - 10, -59.0206, 1e-3);
    F0 = rfscreen.psd.FilterScenario('T0', 'FLAT', [], 0, 'TEST'); F60 = rfscreen.psd.FilterScenario('T60', 'FLAT', [], 60, 'TEST');
    C = -48.53;
    R = V.evaluate(1.2276e9, C - 10, NaN, -178, {s}, 36.9897, F0, NaN, false);
    h.eqTol('victim PSD = source - 10 + coupling', R.port_psd_dBmHz, -49.0206 - 10 + C, 1e-3);
    h.eqTol('required = PSD - (-178)', R.required_add_supp_dB, R.port_psd_dBmHz + 178, 1e-9);
    R60 = V.evaluate(1.2276e9, C - 10, NaN, -178, {s}, 36.9897, F60, NaN, false);
    h.eqTol('60 dB filter raises margin by 60 dB', R60.margin_dB - R.margin_dB, 60, 1e-9);

    % ---- stored results ----
    pf = fullfile(repo, 'output', 'claude', 'results', 'stc_filter_design.csv');
    if exist(pf, 'file') == 2
        L = strsplit(strrep(fileread(pf), char(13), ''), char(10)); L = L(~cellfun(@isempty, strtrim(L)));
        hd = strsplit(L{1}, ','); Rw = cellfun(@(x) strsplit(x, ',', 'CollapseDelimiters', false), L(2:end), 'UniformOutput', false);
        col = @(n) cellfun(@(r) r{strcmp(hd, n)}, Rw, 'UniformOutput', false);
        vb = col('victim_band'); rte = col('tx_route'); req = cellfun(@str2double, col('required_additional_suppression_db'));
        tgt = cellfun(@str2double, col('design_target_db')); fp = col('first_passing_scenario');
        lr = ismember(vb, {'L2', 'L5'});
        h.isTrue('L2/L5 rows use PORT_MISMATCH_RESCALED_LBAND', all(strcmp(rte(lr), PM.ROUTE)));
        h.isTrue('L1 rows keep the CST RealizedGain route', all(strcmp(rte(strcmp(vb, 'L1')), 'CST_REALIZED_GAIN')));
        h.isTrue('L1/L2/L5 all quantified (no UNKNOWN)', all(isfinite(req(ismember(vb, {'L1', 'L2', 'L5'})))));
        h.isTrue('L2/L5 effective source -59.02 dBm/Hz', all(abs(cellfun(@str2double, col('effective_tx_source_psd_dbm_hz')(lr)) + 59.0206) < 1e-3));
        ok = true;
        for i = find(isfinite(req))
            a = sscanf(fp{i}, '%f'); sc = [0 40 60 70 80];
            if ~isempty(a); ok = ok && a >= req(i) && all(sc(sc < a) < req(i)); else; ok = ok && req(i) > 80; end
            ok = ok && tgt(i) >= req(i) + 10 && mod(tgt(i), 10) == 0;
        end
        h.isTrue('first passing scenario and design target consistent with the requirement', ok);
        h.isTrue('SAR not evaluated (victim response missing)', all(isnan(req(strcmp(vb, 'SAR')))));
    end
end
