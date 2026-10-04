classdef SarOwnerPattern
    %SAROWNERPATTERN Normalised SAR receive pattern rebuilt from owner-extracted K8_SAR_Pattern.mat values.
    %   Inputs (data/Xband_SAR_K8_owner/owner_cut_values.csv): per cut (AZIMUTH / ELEVATION) the exact 3-dB
    %   half angle, first null, maximum sidelobe, and the sampled Co-pol levels [dB re Co peak]; symmetric.
    %   The full 1601-point vectors are NOT exported (NOT_FULL_1601_POINT_EXPORT).
    %   Upper-envelope reconstruction per cut, G(theta) [dB, <= 0]:
    %     0 <= theta <= theta3        : -3 (theta / theta3)^2           (exact at the HPBW point)
    %     theta3 < theta <= theta_null: -3 dB hold                      (no dip into the null; conservative)
    %     theta_null < theta          : knots (theta_null: G_sl), (theta_sl: G_sl), samples beyond the null;
    %                                   between adjacent knots the HIGHER value (never below a sample)
    %     beyond the last sample      : OUTER HOLD = max of the samples at |theta| >= 10 deg (ASSUMPTION; the
    %                                   owner data end at +/-80 deg, back hemisphere unknown)
    %   Direction gain: rotational upper envelope max(G_az(theta), G_el(theta)) of the total off-axis angle
    %   (conservative; independent of the az/el axis assignment). Co-pol is primary; Cx (~-120 dB re Co peak)
    %   kept in provenance as CROSS_POL_NEGLIGIBLE_FOR_CURRENT_SCREENING and never self-normalised.
    %   Absolute peak gain: SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN (248.7072 is a complex-field magnitude, not dBi).
    properties (Constant)
        PROVENANCE = 'OWNER_EXTRACTED_FROM_K8_SAR_PATTERN_MAT;ENGINEERING_RECONSTRUCTION;NOT_FULL_1601_POINT_EXPORT'
        PEAK_STATUS = 'SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN'
        XPOL = 'CROSS_POL_NEGLIGIBLE_FOR_CURRENT_SCREENING'
        OUTER_HOLD_FROM_DEG = 10
        DATA_RANGE_DEG = 80
    end
    properties (SetAccess = private)
        cuts        % struct array: name, theta3, thetaNull, gNull, thetaSl, gSl, sampleDeg, sampleDb, outerHold
    end
    methods (Static)
        function p = fromFile(path)
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(path);
            p = rfscreen.psd.SarOwnerPattern(); names = unique(T.cut, 'stable'); C = struct([]);
            for i = 1:numel(names)
                s = strcmp(T.cut, names{i}); k = T.kind(s); a = str2double(T.angle_deg(s)); g = str2double(T.co_db(s));
                one = @(kind) a(strcmp(k, kind)); val = @(kind) g(strcmp(k, kind));
                c = struct('name', names{i}, 'theta3', one('HALF_POWER'), 'thetaNull', one('FIRST_NULL'), 'gNull', val('FIRST_NULL'), ...
                    'thetaSl', one('MAX_SIDELOBE'), 'gSl', val('MAX_SIDELOBE'), 'sampleDeg', reshape(a(strcmp(k, 'SAMPLE')), 1, []), ...
                    'sampleDb', reshape(g(strcmp(k, 'SAMPLE')), 1, []), 'outerHold', NaN);
                if any(cellfun(@numel, {c.theta3, c.thetaNull, c.thetaSl}) ~= 1)
                    error('rfscreen:psd:badSarCut', '%s: need exactly one HALF_POWER, FIRST_NULL and MAX_SIDELOBE row.', names{i});
                end
                o = c.sampleDeg >= rfscreen.psd.SarOwnerPattern.OUTER_HOLD_FROM_DEG; c.outerHold = max(c.sampleDb(o));
                if isempty(C); C = c; else; C(end+1) = c; end %#ok<AGROW>
            end
            p.cuts = C;
        end
    end
    methods
        function g = cutGain(p, name, theta_deg)
            %CUTGAIN Upper-envelope normalised Co-pol gain [dB] of one cut at |theta| [deg] (0..180).
            c = p.cuts(strcmp({p.cuts.name}, name));
            if numel(c) ~= 1; error('rfscreen:psd:unknownSarCut', 'unknown SAR cut %s.', name); end
            th = abs(theta_deg); g = zeros(size(th));
            kA = [c.thetaNull, c.thetaSl, c.sampleDeg(c.sampleDeg > c.thetaNull)];
            kV = [c.gSl, c.gSl, c.sampleDb(c.sampleDeg > c.thetaNull)];
            [kA, o] = sort(kA); kV = kV(o);
            for i = 1:numel(th)
                t = th(i);
                if t <= c.theta3; g(i) = -3 * (t / c.theta3) ^ 2;
                elseif t <= c.thetaNull; g(i) = -3;
                elseif t > kA(end); g(i) = c.outerHold;
                else
                    j = find(kA < t, 1, 'last'); g(i) = max(kV(j), kV(j + 1));
                end
            end
        end

        function g = directionGain(p, theta_deg)
            %DIRECTIONGAIN Rotational upper envelope over both principal cuts [dB re Co peak].
            g = max(p.cutGain('AZIMUTH', theta_deg), p.cutGain('ELEVATION', theta_deg));
        end
    end
end
