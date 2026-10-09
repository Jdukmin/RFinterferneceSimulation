classdef CstNativeInstalledPattern < rfscreen.antenna.InstalledPattern
    %CSTNATIVEINSTALLEDPATTERN Native full-sphere CST installed (on-spacecraft) Realized Gain at ONE frequency plane.
    %   Provenance SIMULATED_3D (never APPROX_FROM_CUTS: no 2D-cut reconstruction is involved).
    %
    %   Source frame SPACECRAFT_BODY_FIXED: the installed CST model is placed in spacecraft body coordinates,
    %   so the raw far-field is G(theta_raw, phi_raw) on the CST result axes. It is NOT an antenna-local pattern
    %   and is never rotated by R_BL / R_BA / M_AL. The display uses ONLY the owner rotation angles of this dataset
    %   (data/cal_config/installed_pattern_rotation.csv, R = Rz*Ry*Rx, d_B = R d_raw; rfscreen.cal.CalPlotFrameAdapter;
    %   meta.frameCorrection, or resolved here with meta.rotationConfig / the default file):
    %     gainRaw(f, d_raw)    raw CST direction            -> raw grid (no transform)
    %     gainBody(f, d_B)     displayed Body direction     -> d_raw = C.' d_B -> raw
    %     gainLocal(f, d_L)    antenna-local direction      -> d_B = R_BL d_L -> d_raw = C.' d_B -> raw
    %     gainAntenna(f, u_A)  repository antenna frame A   -> d_B = R_BA u_A -> d_raw = C.' d_B -> raw
    %   Installed patterns are used for CAL figures only (RFI binds origin free-space patterns).
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
        sourceSimulationFrequency_Hz = NaN   % CST solve frequency (GPSA_*_f1.2: ~1.2 GHz)
        frequencyTreatment = 'NATIVE_PLANE'  % NATIVE_PLANE | SURROGATE (one CST solve reused at this frequency)
        C_raw_to_body = eye(3)               % owner rotation of this dataset (from its rot_x/y/z_deg)
        frameCorrection = struct()           % resolution / boresight-validation record of C_raw_to_body
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
            M = rfscreen.cal.CstNativeSupport;
            fc = M.metaField(meta, 'frameCorrection', []);
            if isempty(fc)
                A = rfscreen.cal.CalPlotFrameAdapter;
                [~, stem] = fileparts(native.sourceFile);
                fSrc = M.metaField(meta, 'sourceSimulationFrequency_Hz', f_Hz) / 1e9;
                inst = M.metaField(meta, 'installationId', '');
                rc = M.metaField(meta, 'rotationConfig', []);
                if isempty(rc); rc = A.loadRotationConfig(); end
                fc = A.resolve(native, R_BA(:, 1), struct('installationId', inst, 'sourceFile', stem, 'sourceFrequency_GHz', fSrc), rc);
            end
            C = fc.C;
            grid = rfscreen.cal.CstNativeSupport.antennaGrid(native, f_Hz, @(u) native.gainAtDirection(C.' * (R_BA * u)));
            popts = struct('confidence', NaN, 'polarization', rfscreen.antenna.Polarization.UNKNOWN);
            obj@rfscreen.antenna.InstalledPattern(name, rfscreen.antenna.PatternProvenance.SIMULATED_3D, grid, rfscreen.antenna.InstalledPatternSource.CST, popts);
            obj.native = native;
            obj.C_raw_to_body = C;
            obj.frameCorrection = fc;
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

        function g = gainRaw(obj, frequency_Hz, d_raw)
            %GAINRAW Realized Gain toward RAW CST direction(s) d_raw (3xN): direct raw-grid query, no transform.
            rfscreen.cal.CstNativeSupport.checkFrequency(obj.name, obj.cstFrequency_Hz, frequency_Hz);
            g = obj.native.gainAtDirection(d_raw);
        end

        function g = gainBody(obj, frequency_Hz, d_B)
            %GAINBODY Realized Gain toward displayed-Body direction(s) d_B: d_raw = C.' d_B (CalPlotFrameAdapter).
            g = obj.gainRaw(frequency_Hz, rfscreen.cal.CalPlotFrameAdapter.toRaw(obj, d_B));
        end

        function g = gainLocal(obj, frequency_Hz, d_L)
            %GAINLOCAL Realized Gain toward antenna-local direction(s) d_L (3xN): d_B = R_BL d_L, then gainBody.
            g = obj.gainBody(frequency_Hz, obj.R_BL * d_L);
        end

        function g = gainAntenna(obj, frequency_Hz, u_A)
            %GAINANTENNA Realized Gain toward repository antenna-frame direction(s) u_A (3xN): d_B = R_BA u_A.
            g = obj.gainBody(frequency_Hz, obj.R_BA * u_A);
        end

        function [theta, phi] = sourceThetaPhi(obj, u_A)
            %SOURCETHETAPHI Raw CST (theta, phi) [deg] queried for antenna-frame direction(s) u_A.
            [theta, phi] = rfscreen.kaa.CstLocalFrameAdapter.thetaPhi(rfscreen.cal.CalPlotFrameAdapter.toRaw(obj, obj.R_BA * u_A));
        end
    end
end
