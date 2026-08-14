classdef ReceiverFrontEnd
    %RECEIVERFRONTEND Single dominant nonlinear front-end element (ICD receiver_nonlinear.md 2).
    %   Input-referred quantities at the LNA_INPUT reference plane. Unknowns are
    %   NaN/[] and NEVER defaulted (Task 30). Input/output P1dB and IIP3/OIP3 are
    %   never mixed implicitly; conversions are explicit helper methods.
    properties (SetAccess = private)
        linearGain_dB       % NaN if unknown
        p1dB_in_dBm         % NaN if unknown -> MISSING_P1DB
        iip3_in_dBm         % NaN if unknown -> MISSING_IIP3
        noiseFigure_dB      % NaN if unknown
        preselector         % receiver.ReceiverFilter before the LNA, or []
        channelFilter       % receiver.ReceiverFilter after the LNA, or []
        referencePlane      % fixed LNA_INPUT
        provenance          % FrontEndProvenance char
    end
    methods
        function obj = ReceiverFrontEnd(opts)
            if nargin < 1 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            F = @(nm) rfscreen.receiver.ReceiverFrontEnd.optScalar(opts, nm);
            obj.linearGain_dB  = F('linearGain_dB');
            obj.p1dB_in_dBm    = F('p1dB_in_dBm');
            obj.iip3_in_dBm    = F('iip3_in_dBm');
            obj.noiseFigure_dB = F('noiseFigure_dB');
            if isfinite(obj.noiseFigure_dB) && obj.noiseFigure_dB < 0
                error('rfscreen:receiver:badNF', 'noiseFigure_dB must be >= 0.');
            end
            obj.preselector   = rfscreen.receiver.ReceiverFrontEnd.optFilter(opts, 'preselector');
            obj.channelFilter = rfscreen.receiver.ReceiverFrontEnd.optFilter(opts, 'channelFilter');
            obj.referencePlane = rfscreen.receiver.ReferencePlane.LNA_INPUT;
            if isfield(opts, 'provenance') && ~isempty(opts.provenance)
                obj.provenance = V.member(opts.provenance, ...
                    rfscreen.receiver.FrontEndProvenance.values(), 'provenance');
            else
                obj.provenance = rfscreen.receiver.FrontEndProvenance.SYNTHETIC_TEST;
            end
        end

        function tf = hasP1dB(obj);  tf = isfinite(obj.p1dB_in_dBm);  end
        function tf = hasIIP3(obj);  tf = isfinite(obj.iip3_in_dBm);  end
        function tf = hasPreselector(obj); tf = ~isempty(obj.preselector); end

        function g = preselectorResponse_dB(obj, f_Hz)
            %PRESELECTORRESPONSE_DB Preselector power gain [dB] at f; 0 dB if none.
            if isempty(obj.preselector)
                g = 0;
            else
                g = obj.preselector.responseDb(f_Hz);
            end
        end

        function oip3 = oip3_dBm(obj)
            %OIP3_DBM Explicit output-referred IP3 = IIP3 + G (NaN if unknown).
            if isfinite(obj.iip3_in_dBm) && isfinite(obj.linearGain_dB)
                oip3 = obj.iip3_in_dBm + obj.linearGain_dB;
            else
                oip3 = NaN;
            end
        end

        function p = p1dB_out_dBm(obj)
            %P1DB_OUT_DBM Explicit output P1dB = P1dB_in + G - 1 (NaN if unknown).
            if isfinite(obj.p1dB_in_dBm) && isfinite(obj.linearGain_dB)
                p = obj.p1dB_in_dBm + obj.linearGain_dB - 1;
            else
                p = NaN;
            end
        end
    end

    methods (Static, Access = private)
        function v = optScalar(opts, name)
            if isfield(opts, name) && ~isempty(opts.(name))
                v = rfscreen.util.Validate.finiteScalar(opts.(name), name);
            else
                v = NaN;
            end
        end
        function v = optFilter(opts, name)
            if isfield(opts, name) && ~isempty(opts.(name))
                if ~isa(opts.(name), 'rfscreen.receiver.ReceiverFilter')
                    error('rfscreen:receiver:badFilter', '%s must be a ReceiverFilter.', name);
                end
                v = opts.(name);
            else
                v = [];
            end
        end
    end
end
