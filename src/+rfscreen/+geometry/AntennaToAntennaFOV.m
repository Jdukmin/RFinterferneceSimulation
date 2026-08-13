classdef AntennaToAntennaFOV
    %ANTENNATOANTENNAFOV Direct (antenna->antenna) relative geometry (AR-010..AR-014).
    %   This is the antenna-to-antenna FOV domain. It is DISTINCT from the
    %   antenna-to-structure FOV domain (see AntennaToStructureFOV), per
    %   reference.md rule 5.
    methods (Static)
        function g = relativeGeometry(r_tx_m, R_BA_tx, r_rx_m, R_BA_rx)
            %RELATIVEGEOMETRY Compute pair geometry between a TX and an RX install.
            %   Returns a struct with:
            %     distance_m, txAz_deg, txEl_deg, rxAz_deg, rxEl_deg,
            %     dBody (3x1 TX->RX body vector), isDefined (logical), warnings
            r_tx_m = rfscreen.util.Validate.vector3(r_tx_m, 'r_tx_m');
            r_rx_m = rfscreen.util.Validate.vector3(r_rx_m, 'r_rx_m');
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA_tx, 'R_BA_tx');
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA_rx, 'R_BA_rx');

            dBody = r_rx_m - r_tx_m;                 % TX -> RX in body frame
            distance_m = norm(dBody);
            warnings = {};

            g = struct();
            g.dBody = dBody;
            g.distance_m = distance_m;

            if distance_m <= eps
                g.txAz_deg = NaN; g.txEl_deg = NaN;
                g.rxAz_deg = NaN; g.rxEl_deg = NaN;
                g.isDefined = false;
                g.warnings = {'zero separation: az/el undefined'};
                return;
            end

            uBody = dBody / distance_m;
            DC = rfscreen.geometry.DirectionCalculator;

            u_tx_A = DC.bodyToLocal(R_BA_tx,  uBody);   % TX->RX in TX frame
            u_rx_A = DC.bodyToLocal(R_BA_rx, -uBody);   % RX->TX in RX frame

            [g.txAz_deg, g.txEl_deg] = DC.directionToAzEl(u_tx_A);
            [g.rxAz_deg, g.rxEl_deg] = DC.directionToAzEl(u_rx_A);
            g.isDefined = true;
            g.warnings = warnings;
        end
    end
end
