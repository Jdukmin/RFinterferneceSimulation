classdef AntennaInstallation
    %ANTENNAINSTALLATION Placement/orientation of one antenna on the body (SR-030).
    %   Separate from Antenna hardware (SR-011). Canonical orientation = DCM R_BA
    %   (antenna->body). position_m in the spacecraft body frame.
    properties (SetAccess = private)
        antennaId
        position_m          % 3x1 in body frame [m]
        R_BA                % 3x3 DCM antenna->body
        configId            % optional installation configuration id
    end

    methods
        function obj = AntennaInstallation(antennaId, position_m, R_BA, configId)
            V = rfscreen.util.Validate;
            obj.antennaId = V.id(antennaId, 'AntennaInstallation.antennaId');
            obj.position_m = V.vector3(position_m, 'AntennaInstallation.position_m');
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA, 'AntennaInstallation.R_BA');
            obj.R_BA = double(R_BA);
            if nargin < 4 || isempty(configId)
                obj.configId = '';
            else
                obj.configId = configId;
            end
        end

        function b_B = boresightInBody(obj)
            %BORESIGHTINBODY Boresight (+X_A) expressed in the body frame.
            b_B = obj.R_BA(:, 1);
        end
    end
end
