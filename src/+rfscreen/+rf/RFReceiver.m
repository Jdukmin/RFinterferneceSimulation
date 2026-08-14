classdef RFReceiver
    %RFRECEIVER Receiver model (SR-072). NOT a bare frequency range: owns an
    %   optional RFFrontEnd (susceptibility layer, distinct from coupling, SR-073).
    %   interferenceThreshold_dBm referenced to the receiver RF input (before LNA);
    %   NaN if unknown -> MISSING_RECEIVER_DATA (never invented, SR-120).
    properties (SetAccess = private)
        id
        antennaId
        fc_Hz
        bw_Hz
        polarization
        interferenceThreshold_dBm   % NaN if unknown
        frontEnd                    % rfscreen.rf.RFFrontEnd or []
        filter                      % optional receiver.ReceiverFilter (Phase 3); [] if absent
        noiseModel                  % optional receiver.ReceiverNoiseModel (Phase 3); [] if absent
        interferenceCriterion       % optional receiver.InterferenceCriterion (Phase 3); [] if absent
    end

    methods
        function obj = RFReceiver(id, antennaId, fc_Hz, bw_Hz, opts)
            if nargin < 5 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            obj.id = V.id(id, 'RFReceiver.id');
            obj.antennaId = V.id(antennaId, 'RFReceiver.antennaId');
            obj.fc_Hz = V.positiveScalar(fc_Hz, 'RFReceiver.fc_Hz');
            obj.bw_Hz = V.nonnegativeScalar(bw_Hz, 'RFReceiver.bw_Hz');

            if isfield(opts, 'polarization') && ~isempty(opts.polarization)
                obj.polarization = opts.polarization;
            else
                obj.polarization = rfscreen.antenna.Polarization.UNKNOWN;
            end
            if ~rfscreen.antenna.Polarization.isValid(obj.polarization)
                error('rfscreen:rf:badPolarization', 'invalid RX polarization.');
            end

            if isfield(opts, 'interferenceThreshold_dBm') && ~isempty(opts.interferenceThreshold_dBm)
                obj.interferenceThreshold_dBm = V.finiteScalar( ...
                    opts.interferenceThreshold_dBm, 'interferenceThreshold_dBm');
            else
                obj.interferenceThreshold_dBm = NaN;
            end

            if isfield(opts, 'frontEnd') && ~isempty(opts.frontEnd)
                if ~isa(opts.frontEnd, 'rfscreen.rf.RFFrontEnd')
                    error('rfscreen:rf:badFrontEnd', 'frontEnd must be a rfscreen.rf.RFFrontEnd.');
                end
                obj.frontEnd = opts.frontEnd;
            else
                obj.frontEnd = [];
            end

            obj.filter = rfscreen.rf.RFReceiver.optType(opts, 'filter', ...
                'rfscreen.receiver.ReceiverFilter', 'filter');
            obj.noiseModel = rfscreen.rf.RFReceiver.optType(opts, 'noiseModel', ...
                'rfscreen.receiver.ReceiverNoiseModel', 'noiseModel');
            obj.interferenceCriterion = rfscreen.rf.RFReceiver.optType(opts, 'interferenceCriterion', ...
                'rfscreen.receiver.InterferenceCriterion', 'interferenceCriterion');
        end

        function tf = hasFilterModel(obj)
            tf = ~isempty(obj.filter);
        end

        function band = band_Hz(obj)
            %BAND_HZ RX band = filter passband if present, else fc +/- bw/2.
            if ~isempty(obj.frontEnd) && obj.frontEnd.hasFilter()
                band = obj.frontEnd.filterPassband_Hz;
            else
                band = [obj.fc_Hz - obj.bw_Hz/2, obj.fc_Hz + obj.bw_Hz/2];
            end
        end

        function tf = hasThreshold(obj)
            tf = ~isnan(obj.interferenceThreshold_dBm);
        end
    end

    methods (Static, Access = private)
        function v = optType(opts, name, cls, label)
            if isfield(opts, name) && ~isempty(opts.(name))
                if ~isa(opts.(name), cls)
                    error('rfscreen:rf:badType', '%s must be a %s.', label, cls);
                end
                v = opts.(name);
            else
                v = [];
            end
        end
    end
end
