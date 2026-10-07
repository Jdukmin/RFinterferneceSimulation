classdef CalBandResponse
    %CALBANDRESPONSE Victim-band response adapter so CAL patterns feed the EXISTING
    %   rfscreen.psd.VictimBandCoupling.patternRoute unchanged (gainAt(band, f, d) contract).
    %   The band tag travels with the response (a response of another band is refused) and the
    %   pattern itself refuses any frequency other than its CST plane. Directions are antenna-frame
    %   unit vectors u_A (+X_A = boresight).
    %   kind CST_PATTERN : rfscreen.cal.CstNative*Pattern
    %   kind SAR_OWNER   : rfscreen.psd.SarOwnerPattern (normalised) + absolute peak [dBi]; off-axis
    %                      angle from +X_A (rotational envelope, existing Task-2 convention).
    properties (SetAccess = private)
        band
        kind
        pattern = []
        sar = []
        sarPeak_dBi = NaN
    end
    methods (Static)
        function r = fromPattern(band, pattern)
            r = rfscreen.cal.CalBandResponse(); r.band = band; r.kind = 'CST_PATTERN'; r.pattern = pattern;
        end
        function r = fromSar(band, sarPattern, peak_dBi)
            r = rfscreen.cal.CalBandResponse(); r.band = band; r.kind = 'SAR_OWNER';
            r.sar = sarPattern; r.sarPeak_dBi = peak_dBi;
        end
    end
    methods
        function g = gainAt(r, band, f_Hz, u_A)
            if ~strcmp(band, r.band)
                error('rfscreen:psd:wrongBandResponse', 'CAL response of band %s requested for band %s.', r.band, band);
            end
            switch r.kind
                case 'CST_PATTERN'
                    g = r.pattern.gainAntenna(f_Hz, u_A(:) / norm(u_A));
                case 'SAR_OWNER'
                    th = acosd(max(-1, min(1, u_A(1) / norm(u_A))));
                    g = r.sarPeak_dBi + r.sar.directionGain(th);
            end
        end
    end
end
