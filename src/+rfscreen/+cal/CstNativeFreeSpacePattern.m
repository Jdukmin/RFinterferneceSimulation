classdef CstNativeFreeSpacePattern < rfscreen.antenna.FreeSpacePattern
    %CSTNATIVEFREESPACEPATTERN Native full-sphere CST free-space Realized Gain at ONE frequency plane.
    %   Provenance SIMULATED_3D (never APPROX_FROM_CUTS: no 2D-cut reconstruction is involved).
    %   Source frame CST_LOCAL: the raw (theta, phi) grid is the antenna local frame L (+Z_L = boresight).
    %   evaluate(f, az, el) answers only at its own CST frequency (error otherwise) and queries the native
    %   grid through rfscreen.kaa.CstLocalFrameAdapter (u_A -> v_L = M_AL.' u_A; see CstNativeSupport).
    %   Body directions reach L only through the installation R_BL (rfscreen.kaa.CstLocalFrameAdapter).
    properties (SetAccess = private)
        native              % rfscreen.cal.CstSphericalPatternData
        cstFrequency_Hz     % canonical (evaluation) frequency of this plane
        sourceFile = ''
        patternType = 'FREE_SPACE'
        sourceFrame = 'CST_LOCAL'                   % raw grid frame (see CstNativeSupport)
        family = ''
        installationId = ''
        sourceSimulationFrequency_Hz = NaN   % CST solve frequency (GPS_*_f1.2: ~1.2 GHz)
        frequencyTreatment = 'NATIVE_PLANE'  % NATIVE_PLANE | SURROGATE (one CST solve reused at this frequency)
    end
    methods
        function obj = CstNativeFreeSpacePattern(name, native, f_Hz, meta)
            if nargin < 4; meta = struct(); end
            grid = rfscreen.cal.CstNativeSupport.antennaGrid(native, f_Hz);
            popts = struct('confidence', NaN, 'polarization', rfscreen.antenna.Polarization.UNKNOWN);
            obj@rfscreen.antenna.FreeSpacePattern(name, rfscreen.antenna.PatternProvenance.SIMULATED_3D, grid, popts);
            M = rfscreen.cal.CstNativeSupport;
            obj.native = native;
            obj.cstFrequency_Hz = f_Hz;
            obj.sourceFile = native.sourceFile;
            obj.family = M.metaField(meta, 'family', '');
            obj.installationId = M.metaField(meta, 'installationId', '');
            obj.sourceSimulationFrequency_Hz = M.metaField(meta, 'sourceSimulationFrequency_Hz', f_Hz);
            obj.frequencyTreatment = M.metaField(meta, 'frequencyTreatment', 'NATIVE_PLANE');
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

        function [theta, phi] = sourceThetaPhi(obj, u_A) %#ok<INUSL>
            %SOURCETHETAPHI Raw CST (theta, phi) [deg] queried for antenna-frame direction(s) u_A.
            [theta, phi] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi( ...
                rfscreen.kaa.CstLocalFrameAdapter.localToAntenna().' * u_A);
        end
    end
end
