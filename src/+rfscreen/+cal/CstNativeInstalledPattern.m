classdef CstNativeInstalledPattern < rfscreen.antenna.InstalledPattern
    %CSTNATIVEINSTALLEDPATTERN Native full-sphere CST installed (on-spacecraft) Realized Gain at ONE frequency plane.
    %   Provenance SIMULATED_3D (never APPROX_FROM_CUTS: no 2D-cut reconstruction is involved).
    %   evaluate(f, az, el) answers only at its own CST frequency (error otherwise) and queries the native
    %   (theta, phi) grid through rfscreen.kaa.CstLocalFrameAdapter (see CstNativeSupport).
    properties (SetAccess = private)
        native              % rfscreen.cal.CstSphericalPatternData
        cstFrequency_Hz     % canonical frequency of this plane
        sourceFile = ''
        patternType = 'INSTALLED'
        family = ''
        installationId = ''
    end
    methods
        function obj = CstNativeInstalledPattern(name, native, f_Hz, meta)
            if nargin < 4; meta = struct(); end
            grid = rfscreen.cal.CstNativeSupport.antennaGrid(native, f_Hz);
            popts = struct('confidence', NaN, 'polarization', rfscreen.antenna.Polarization.UNKNOWN);
            obj@rfscreen.antenna.InstalledPattern(name, rfscreen.antenna.PatternProvenance.SIMULATED_3D, grid, rfscreen.antenna.InstalledPatternSource.CST, popts);
            obj.native = native;
            obj.cstFrequency_Hz = f_Hz;
            obj.sourceFile = native.sourceFile;
            if isfield(meta, 'family'); obj.family = meta.family; end
            if isfield(meta, 'installationId'); obj.installationId = meta.installationId; end
        end

        function gain_dBi = evaluate(obj, frequency_Hz, az_deg, el_deg, policy) %#ok<INUSD>
            rfscreen.cal.CstNativeSupport.checkFrequency(obj.name, obj.cstFrequency_Hz, frequency_Hz);
            gain_dBi = rfscreen.cal.CstNativeSupport.gainAzEl(obj.native, az_deg, el_deg);
        end

        function [gain_dBi, info] = evaluateWithInfo(obj, frequency_Hz, az_deg, el_deg, policy) %#ok<INUSD>
            gain_dBi = obj.evaluate(frequency_Hz, az_deg, el_deg);
            info = rfscreen.cal.CstNativeSupport.evalInfo();
        end

        function g = gainAntenna(obj, frequency_Hz, u_A)
            %GAINANTENNA Realized Gain toward antenna-frame unit vector(s) u_A (3xN).
            rfscreen.cal.CstNativeSupport.checkFrequency(obj.name, obj.cstFrequency_Hz, frequency_Hz);
            g = rfscreen.cal.CstNativeSupport.gainAntenna(obj.native, u_A);
        end
    end
end
