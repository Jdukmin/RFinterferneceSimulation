classdef CstNativeInstalledPattern < rfscreen.antenna.InstalledPattern
    %CSTNATIVEINSTALLEDPATTERN Native full-sphere CST installed (on-spacecraft) Realized Gain at ONE frequency plane.
    %   Provenance SIMULATED_3D (never APPROX_FROM_CUTS: no 2D-cut reconstruction is involved).
    %
    %   Source frame SPACECRAFT_BODY_FIXED: the installed CST model is placed in spacecraft body coordinates,
    %   so the raw far-field is G_B(theta_B, phi_B) with theta from +Z_B and phi = atan2(Y_B, X_B). It is
    %   NOT an antenna-local pattern and is never rotated by R_BL / R_BA / M_AL before a body query:
    %     gainBody(f, d_B)     body direction               -> raw grid            (no rotation)
    %     gainLocal(f, d_L)    antenna-local direction      -> d_B = R_BL d_L -> raw  (LOCAL -> BODY only)
    %     gainAntenna(f, u_A)  repository antenna frame A   -> d_B = R_BA u_A -> raw  (RFI engine contract)
    %   R_BA is the mounting orientation of the installation (SimplifiedSpacecraftBuilder SSOT), required at
    %   construction (meta.R_BA); R_BL = CstLocalFrameAdapter.fromR_BA(R_BA) (+Z_L = panel outward normal).
    %   evaluate(f, az, el) keeps the AntennaPattern contract (antenna-frame az/el) and answers only at its
    %   own CST frequency.
    properties (SetAccess = private)
        native              % rfscreen.cal.CstSphericalPatternData (raw grid in body frame B)
        cstFrequency_Hz     % canonical (evaluation) frequency of this plane
        sourceFile = ''
        patternType = 'INSTALLED'
        sourceFrame = 'SPACECRAFT_BODY_FIXED'       % raw grid frame (see CstNativeSupport)
        family = ''
        installationId = ''
        R_BA = []           % mounting DCM (antenna frame A -> body B)
        R_BL = []           % antenna-local DCM (CST local L -> body B), for local cuts only
        sourceSimulationFrequency_Hz = NaN   % CST solve frequency (GPS_*_f1.2: ~1.2 GHz)
        frequencyTreatment = 'NATIVE_PLANE'  % NATIVE_PLANE | SURROGATE (one CST solve reused at this frequency)
    end
    methods
        function obj = CstNativeInstalledPattern(name, native, f_Hz, meta)
            if nargin < 4; meta = struct(); end
            if ~isfield(meta, 'R_BA') || isempty(meta.R_BA)
                error('rfscreen:cal:installedMountRequired', ['%s: an installed CST pattern is in the spacecraft body ' ...
                    'frame; its installation mounting R_BA (meta.R_BA) is required to answer antenna-frame queries.'], name);
            end
            R_BA = meta.R_BA;
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA, 'R_BA');
            grid = rfscreen.cal.CstNativeSupport.antennaGrid(native, f_Hz, @(u) native.gainAtDirection(R_BA * u));
            popts = struct('confidence', NaN, 'polarization', rfscreen.antenna.Polarization.UNKNOWN);
            obj@rfscreen.antenna.InstalledPattern(name, rfscreen.antenna.PatternProvenance.SIMULATED_3D, grid, rfscreen.antenna.InstalledPatternSource.CST, popts);
            M = rfscreen.cal.CstNativeSupport;
            obj.native = native;
            obj.cstFrequency_Hz = f_Hz;
            obj.sourceFile = native.sourceFile;
            obj.family = M.metaField(meta, 'family', '');
            obj.installationId = M.metaField(meta, 'installationId', '');
            obj.R_BA = R_BA;
            obj.R_BL = rfscreen.kaa.CstLocalFrameAdapter.fromR_BA(R_BA);
            obj.sourceSimulationFrequency_Hz = M.metaField(meta, 'sourceSimulationFrequency_Hz', f_Hz);
            obj.frequencyTreatment = M.metaField(meta, 'frequencyTreatment', 'NATIVE_PLANE');
        end

        function gain_dBi = evaluate(obj, frequency_Hz, az_deg, el_deg, policy) %#ok<INUSD>
            g = obj.gainAntenna(frequency_Hz, rfscreen.cal.CstNativeSupport.azElToU(az_deg, el_deg));
            gain_dBi = reshape(g, size(az_deg));
        end

        function [gain_dBi, info] = evaluateWithInfo(obj, frequency_Hz, az_deg, el_deg, policy) %#ok<INUSD>
            gain_dBi = obj.evaluate(frequency_Hz, az_deg, el_deg);
            info = rfscreen.cal.CstNativeSupport.evalInfo();
        end

        function g = gainBody(obj, frequency_Hz, d_B)
            %GAINBODY Realized Gain toward body-frame direction(s) d_B (3xN): direct raw-grid query.
            rfscreen.cal.CstNativeSupport.checkFrequency(obj.name, obj.cstFrequency_Hz, frequency_Hz);
            g = obj.native.gainAtDirection(d_B);
        end

        function g = gainLocal(obj, frequency_Hz, d_L)
            %GAINLOCAL Realized Gain toward antenna-local direction(s) d_L (3xN): d_B = R_BL d_L, then raw query.
            g = obj.gainBody(frequency_Hz, obj.R_BL * d_L);
        end

        function g = gainAntenna(obj, frequency_Hz, u_A)
            %GAINANTENNA Realized Gain toward repository antenna-frame direction(s) u_A (3xN): d_B = R_BA u_A.
            g = obj.gainBody(frequency_Hz, obj.R_BA * u_A);
        end

        function [theta, phi] = sourceThetaPhi(obj, u_A)
            %SOURCETHETAPHI Raw CST (theta_B, phi_B) [deg] queried for antenna-frame direction(s) u_A.
            [theta, phi] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi(obj.R_BA * u_A);
        end
    end
end
