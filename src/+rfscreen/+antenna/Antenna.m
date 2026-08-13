classdef Antenna
    %ANTENNA Antenna hardware record (SR-021). Holds NO installation geometry
    %   (no position/orientation) -- geometry lives in AntennaInstallation
    %   (SR-011, VR-083). References a pattern and an installation by id.
    properties (SetAccess = private)
        id
        name
        role                % Role char (TX/RX/TXRX)
        freqMin_Hz
        freqMax_Hz
        polarization        % Polarization char
        patternId
        installationId
        maxDimension_m      % optional; NaN if unknown (far-field checks)
    end

    methods
        function obj = Antenna(id, name, role, freqMin_Hz, freqMax_Hz, ...
                               polarization, patternId, installationId, maxDimension_m)
            V = rfscreen.util.Validate;
            obj.id   = V.id(id, 'Antenna.id');
            obj.name = V.id(name, 'Antenna.name');
            obj.role = V.member(role, rfscreen.antenna.Role.values(), 'Antenna.role');
            obj.freqMin_Hz = V.positiveScalar(freqMin_Hz, 'Antenna.freqMin_Hz');
            obj.freqMax_Hz = V.positiveScalar(freqMax_Hz, 'Antenna.freqMax_Hz');
            if obj.freqMax_Hz < obj.freqMin_Hz
                error('rfscreen:antenna:freqOrder', ...
                    'Antenna.freqMax_Hz (%g) must be >= freqMin_Hz (%g).', ...
                    obj.freqMax_Hz, obj.freqMin_Hz);
            end
            if nargin < 6 || isempty(polarization)
                polarization = rfscreen.antenna.Polarization.UNKNOWN;
            end
            obj.polarization = V.member(polarization, ...
                rfscreen.antenna.Polarization.values(), 'Antenna.polarization');
            obj.patternId = V.id(patternId, 'Antenna.patternId');
            obj.installationId = V.id(installationId, 'Antenna.installationId');
            if nargin < 9 || isempty(maxDimension_m)
                obj.maxDimension_m = NaN;
            else
                obj.maxDimension_m = V.positiveScalar(maxDimension_m, 'Antenna.maxDimension_m');
            end
        end

        function tf = supportsFrequency(obj, frequency_Hz)
            tf = frequency_Hz >= obj.freqMin_Hz && frequency_Hz <= obj.freqMax_Hz;
        end

        function tf = canTransmit(obj)
            tf = rfscreen.antenna.Role.canTransmit(obj.role);
        end

        function tf = canReceive(obj)
            tf = rfscreen.antenna.Role.canReceive(obj.role);
        end
    end
end
