function [g, info] = rfi_eval_set(set, f, dL)
%RFI_EVAL_SET Gain of a pattern set at frequency f toward local direction dL.
%   set.freqs (1xN, Hz, ascending), set.xz{k}, set.yz{k}, set.validRange [lo hi] (Hz),
%   set.mode = 'MONITORS' (interpolate in dB ONLY between bracketing computed monitors of one band)
%            | 'BAND_REUSE' (single-frequency reference pattern reused inside its declared band).
%   Outside the valid range -> NaN with reason (no extrapolation, no gap filling).
    info = struct('status', 'OK', 'f_lo', NaN, 'f_hi', NaN, 'w', NaN);
    if isempty(set) || ~isstruct(set)
        g = NaN; info.status = 'NO_SOURCE'; return;
    end
    if f < set.validRange(1) - 1 || f > set.validRange(2) + 1
        g = NaN; info.status = 'OUTSIDE_COMPUTED_RANGE'; return;
    end
    if strcmp(set.mode, 'BAND_REUSE') || numel(set.freqs) == 1
        g = rfi_cut_gain(set.xz{1}, set.yz{1}, dL);
        info.f_lo = set.freqs(1); info.f_hi = set.freqs(1); info.w = 0;
        return;
    end
    F = set.freqs;
    k = find(F <= f + 1, 1, 'last');
    if isempty(k); k = 1; end
    if k >= numel(F); k = numel(F) - 1; end
    w = (f - F(k)) / (F(k + 1) - F(k));
    w = max(0, min(1, w));
    g1 = rfi_cut_gain(set.xz{k}, set.yz{k}, dL);
    g2 = rfi_cut_gain(set.xz{k + 1}, set.yz{k + 1}, dL);
    g = (1 - w) * g1 + w * g2;
    info.f_lo = F(k); info.f_hi = F(k + 1); info.w = w;
end
