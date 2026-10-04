classdef ReflectorApertureModel
    %REFLECTORAPERTUREMODEL KAA equivalent-paraboloid aperture field (source of the Ka near-field solver).
    %   Re-uses the validated KAA reflector model unchanged (no regeneration):
    %     cst/ka_reflector_po.py            aperture_gain(): Ea(rho) = sqrt(Gf(psi)) / r'
    %     cst/ka_reflector_eval.py          feed_interp(): mean of the four CST half-cuts (RHCP, linear)
    %     cst/results/KA_FEED_C_OEWG/feed_pattern.json              CST full-wave feed (RHCP dBi)
    %     cst/results/KA_REFLECTOR_KA_FEED_C_OEWG/reflector_validation.json   D, Fe, Ds, anchor PASS
    %   with psi = 2 atan(rho / 2Fe), r' = Fe / cos^2(psi/2), rho in [Ds/2, D/2] (subreflector
    %   blockage), spillover lost (accepted-power gain basis), aperture phase = equal-path GO
    %   (feed phase-centre focused; feed phase errors neglected, exactly as in the validated model).
    %
    %   Absolute scaling: for TX accepted power P [W] the tangential aperture field is
    %     Ea(rho,phi) = sqrt(2 eta P / (4 pi)) * a(rho,phi),   a = sqrt(Gf)/r' * exp(j Phi)   [1/m]
    %   so that  int |Ea|^2/(2 eta) dA = P * int Gf sin(psi) dpsi dphi / (4 pi)  (power intercepted
    %   by the unblocked aperture). Synthetic models (tests only) supply a(rho,phi,f) directly.
    properties (Constant)
        C0 = 299792458
    end
    properties (SetAccess = private)
        label
        provenance          % struct: kind, files, status, notes
        D_m
        Ds_m
        Fe_m
        freqs_Hz            % 1xF monitors with a feed pattern
        feedPsi_rad         % 1xN
        feedGainLin         % FxN (linear, accepted-power normalised, axisymmetric average)
        nRho = 400
        nPhi = 720
        apertureFcn = []    % synthetic: @(rho, phi, f) complex a [1/m]
    end
    methods (Static)
        function m = fromRepository(repoRoot, opts)
            %FROMREPOSITORY Load the validated KAA model (KA_FEED_C_OEWG + reflector_validation.json).
            if nargin < 2; opts = struct(); end
            refl = fullfile(repoRoot, 'cst', 'results', 'KA_REFLECTOR_KA_FEED_C_OEWG', 'reflector_validation.json');
            feed = fullfile(repoRoot, 'cst', 'results', 'KA_FEED_C_OEWG', 'feed_pattern.json');
            R = jsondecode(fileread(refl));
            if ~strcmp(R.status, 'KA_DATASHEET_ANCHOR_PASS')
                error('rfscreen:kaa:notValidated', 'reflector model status is %s (expected KA_DATASHEET_ANCHOR_PASS).', R.status);
            end
            if ~strcmp(R.feed_project, 'KA_FEED_C_OEWG')
                error('rfscreen:kaa:feedMismatch', 'reflector validation refers to feed %s.', R.feed_project);
            end
            F = jsondecode(fileread(feed));
            fn = fieldnames(F);
            fr = zeros(1, numel(fn)); G = [];
            psi = (0:180) * pi / 180;
            for i = 1:numel(fn)
                fr(i) = str2double(strrep(regexprep(fn{i}, '^x', ''), '_', '.')) * 1e9;
                c = F.(fn{i}).cuts; g = zeros(4, 181); k = 0;
                for pl = {'XZ', 'YZ'}
                    t = c.(pl{1}).theta(:).'; v = c.(pl{1}).rhcp_dbi(:).';
                    if numel(t) ~= 360 || any(abs(t - (0:359)) > 1e-9)
                        error('rfscreen:kaa:badFeedCut', '%s %s: theta must be 0..359.', fn{i}, pl{1});
                    end
                    k = k + 1; g(k, :) = 10 .^ (v(1:181) / 10);                 % psi = 0..180, +half
                    k = k + 1; g(k, :) = 10 .^ (v([1, 360:-1:181]) / 10);       % psi = 0..180, -half
                end
                G(i, :) = mean(g, 1); %#ok<AGROW>
            end
            [fr, o] = sort(fr); G = G(o, :);
            m = rfscreen.kaa.ReflectorApertureModel();
            m.label = 'KAA_KA_FEED_C_OEWG_EQUIV_PARABOLOID';
            m.D_m = R.reflector.D_mm / 1000; m.Ds_m = R.reflector.Ds_mm / 1000; m.Fe_m = R.reflector.Fe_mm / 1000;
            m.freqs_Hz = fr; m.feedPsi_rad = psi; m.feedGainLin = G;
            m.provenance = struct('kind', 'CST_FEED_PLUS_PYTHON_EQUIVALENT_PARABOLOID (re-used, not regenerated)', ...
                'files', {{'cst/results/KA_REFLECTOR_KA_FEED_C_OEWG/reflector_validation.json', ...
                'cst/results/KA_FEED_C_OEWG/feed_pattern.json', 'cst/ka_reflector_po.py', 'cst/ka_reflector_eval.py'}}, ...
                'status', R.status, ...
                'gainBasis', R.gain_basis, 'method', R.reflector.method, ...
                'notes', 'aperture phase = equal-path GO (feed phase errors neglected as in the validated model)');
            m = m.withSampling(opts);
        end

        function m = synthetic(label, D_m, Ds_m, freqs_Hz, apertureFcn, opts)
            %SYNTHETIC Test-only aperture a(rho,phi,f) [1/m] on the annulus [Ds/2, D/2].
            if nargin < 6; opts = struct(); end
            if isempty(strfind(label, 'SYNTHETIC_TEST'))
                error('rfscreen:kaa:syntheticLabel', 'synthetic aperture labels must contain SYNTHETIC_TEST.');
            end
            m = rfscreen.kaa.ReflectorApertureModel();
            m.label = label; m.D_m = D_m; m.Ds_m = Ds_m; m.Fe_m = NaN; m.freqs_Hz = freqs_Hz;
            m.apertureFcn = apertureFcn;
            m.provenance = struct('kind', 'SYNTHETIC_TEST', 'files', {{}}, 'status', 'SYNTHETIC_TEST', ...
                'gainBasis', 'SYNTHETIC_TEST', 'method', 'synthetic aperture', 'notes', '');
            m = m.withSampling(opts);
        end
    end
    methods
        function m = withSampling(m, opts)
            if isfield(opts, 'nRho'); m.nRho = opts.nRho; end
            if isfield(opts, 'nPhi'); m.nPhi = opts.nPhi; end
        end

        function tf = isSynthetic(m)
            tf = ~isempty(m.apertureFcn);
        end

        function g = feedGain(m, f_Hz, psi)
            %FEEDGAIN Linear feed co-pol gain at a monitor frequency (no extrapolation).
            k = find(abs(m.freqs_Hz - f_Hz) < 1, 1);
            if isempty(k)
                error('rfscreen:kaa:notAMonitor', ['%.6g GHz is not a computed feed monitor (%s GHz); ' ...
                    'the near-field source is evaluated only at CST feed monitors.'], f_Hz / 1e9, ...
                    sprintf('%.6g ', m.freqs_Hz / 1e9));
            end
            g = interp1(m.feedPsi_rad, m.feedGainLin(k, :), psi, 'linear');
        end

        function s = samples(m, f_Hz)
            %SAMPLES Aperture quadrature: points (x,y) in the aperture plane z_L = 0 and weights
            %   w = a(rho,phi) dA [m] (trapezoid in rho on linspace(Ds/2, D/2), periodic rule in phi).
            rho = linspace(m.Ds_m / 2, m.D_m / 2, m.nRho);
            wr = [0.5, ones(1, m.nRho - 2), 0.5] * (rho(2) - rho(1));
            phi = (0:m.nPhi - 1) * 2 * pi / m.nPhi;
            [P, Rr] = meshgrid(phi, rho);
            W = (wr(:) .* rho(:)) * ones(1, m.nPhi) * (2 * pi / m.nPhi);
            if m.isSynthetic()
                a = m.apertureFcn(Rr, P, f_Hz);
            else
                psi = 2 * atan(Rr / (2 * m.Fe_m)); r = m.Fe_m ./ cos(psi / 2) .^ 2;
                a = sqrt(max(m.feedGain(f_Hz, psi), 0)) ./ r;              % equal-path GO phase = 0
            end
            s = struct('x', Rr(:) .* cos(P(:)), 'y', Rr(:) .* sin(P(:)), 'w', a(:) .* W(:), ...
                'absA2dA', abs(a(:)) .^ 2 .* W(:), 'k', 2 * pi * f_Hz / m.C0, 'f_Hz', f_Hz);
        end

        function fr = interceptedPowerFraction(m, f_Hz)
            %INTERCEPTEDPOWERFRACTION Aperture power / TX accepted power = sum |a|^2 dA / (4 pi).
            s = m.samples(f_Hz); fr = sum(s.absA2dA) / (4 * pi);
        end

        function fr = feedAnnulusFraction(m, f_Hz)
            %FEEDANNULUSFRACTION Independent check: int_{psi1}^{psi2} Gf sin(psi) dpsi 2pi / (4 pi).
            if m.isSynthetic(); fr = NaN; return; end
            p1 = 2 * atan(m.Ds_m / 4 / m.Fe_m); p2 = 2 * atan(m.D_m / 4 / m.Fe_m);
            p = linspace(p1, p2, 20001);
            fr = trapz(p, m.feedGain(f_Hz, p) .* sin(p)) * 2 * pi / (4 * pi);
        end

        function d = farFieldDistance(m, f_Hz)
            d = 2 * m.D_m ^ 2 ./ (m.C0 ./ f_Hz);
        end
    end
end
