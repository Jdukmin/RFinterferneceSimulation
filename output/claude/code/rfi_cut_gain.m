function [g, theta, phi] = rfi_cut_gain(xz, yz, dL)
%RFI_CUT_GAIN Directional gain from two independent 1-degree cuts (APPROX_FROM_CUTS).
%   dL : unit direction in the antenna-local CST frame
%        (+X_L = +X_B, +Z_L = boresight, +Y_L = +Z_L x +X_L).
%   Cut convention: XZ cut angle t -> (sin t, 0, cos t); YZ cut angle t -> (0, sin t, cos t).
%   theta = polar angle from +Z_L, phi = atan2(y,x). Same two-cut azimuthal interpolation as
%   rfscreen.patterndata.CutPatternAssembler.reconstructGain (phi nodes 0/90/180/270/360), but in
%   the CST local frame, so the XZ cut is the plane that contains +X_B (no plane swap).
    d = dL(:) / norm(dL);
    theta = acosd(max(-1, min(1, d(3))));
    phi = mod(atan2d(d(2), d(1)), 360);
    p = @(c, t) rfi_periodic(c, t);
    g0   = p(xz, theta);            % phi = 0   (+X_L half of the XZ plane)
    g180 = p(xz, 360 - theta);      % phi = 180
    g90  = p(yz, theta);            % phi = 90  (+Y_L half of the YZ plane)
    g270 = p(yz, 360 - theta);      % phi = 270
    g = interp1([0 90 180 270 360], [g0 g90 g180 g270 g0], phi, 'linear');
end

function v = rfi_periodic(c, t)
    t = mod(t, 360);
    i0 = floor(t); w = t - i0;
    a = c(mod(i0, 360) + 1); b = c(mod(i0 + 1, 360) + 1);
    v = (1 - w) * a + w * b;
end
