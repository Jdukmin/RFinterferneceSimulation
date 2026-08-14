classdef RFTransmitter
    %RFTRANSMITTER Transmitter model (SR-070). power_dBm referenced to the TX
    %   antenna INPUT port (ICD pair_result.md). Reserved extension points:
    %   spectrum mask, harmonics, spurious, duty cycle, waveform (SR-071).
    properties (SetAccess = private)
        id
        antennaId
        fc_Hz
        bw_Hz
        power_dBm
        mode
        polarization
        dutyCycle           % reserved; default 1.0
        spectrum            % optional spectrum.SpectrumModel (Phase 3); [] if absent
    end

    methods
        function obj = RFTransmitter(id, antennaId, fc_Hz, bw_Hz, power_dBm, opts)
            if nargin < 6 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            obj.id = V.id(id, 'RFTransmitter.id');
            obj.antennaId = V.id(antennaId, 'RFTransmitter.antennaId');
            obj.fc_Hz = V.positiveScalar(fc_Hz, 'RFTransmitter.fc_Hz');
            obj.bw_Hz = V.nonnegativeScalar(bw_Hz, 'RFTransmitter.bw_Hz');
            obj.power_dBm = V.finiteScalar(power_dBm, 'RFTransmitter.power_dBm');
            obj.mode = rfscreen.rf.RFTransmitter.optChar(opts, 'mode', 'NOMINAL');
            obj.polarization = rfscreen.rf.RFTransmitter.optChar(opts, 'polarization', ...
                rfscreen.antenna.Polarization.UNKNOWN);
            if ~rfscreen.antenna.Polarization.isValid(obj.polarization)
                error('rfscreen:rf:badPolarization', 'invalid TX polarization.');
            end
            if isfield(opts, 'dutyCycle') && ~isempty(opts.dutyCycle)
                dc = V.finiteScalar(opts.dutyCycle, 'dutyCycle');
                if dc <= 0 || dc > 1
                    error('rfscreen:rf:badDutyCycle', 'dutyCycle must be in (0,1].');
                end
                obj.dutyCycle = dc;
            else
                obj.dutyCycle = 1.0;
            end
            if isfield(opts, 'spectrum') && ~isempty(opts.spectrum)
                if ~isa(opts.spectrum, 'rfscreen.spectrum.SpectrumModel')
                    error('rfscreen:rf:badSpectrum', 'spectrum must be a rfscreen.spectrum.SpectrumModel.');
                end
                obj.spectrum = opts.spectrum;
            else
                obj.spectrum = [];
            end
        end

        function tf = hasSpectrum(obj)
            tf = ~isempty(obj.spectrum);
        end

        function band = occupiedBand_Hz(obj)
            %OCCUPIEDBAND_HZ [lo hi] occupied band = fc +/- bw/2.
            band = [obj.fc_Hz - obj.bw_Hz/2, obj.fc_Hz + obj.bw_Hz/2];
        end
    end

    methods (Static, Access = private)
        function v = optChar(opts, name, default)
            if isfield(opts, name) && ~isempty(opts.(name))
                v = opts.(name);
            else
                v = default;
            end
        end
    end
end
