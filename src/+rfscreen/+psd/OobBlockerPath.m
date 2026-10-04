classdef OobBlockerPath
    %OOBBLOCKERPATH Fundamental out-of-band blocker path (separate from the victim-band PSD path).
    %   TX carrier (fundamental band) -> TX antenna @ f_TX -> coupling -> victim antenna @ f_TX
    %   -> victim port blocker power [dBm]. Final judgement needs receiver preselector/BPF rejection
    %   at f_TX and a blocking limit (or P1dB / desensitisation / IIP3 models):
    %     post_filter = blocker_port - rejection;  margin = blocking_limit - post_filter.
    %   Missing receiver data -> PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN (no PASS/FAIL).
    %   'blocker_port - in-band allowable' is NOT a rejection requirement; it is kept only as the
    %   historical diagnostic screening_suppression_to_inband_limit_db.
    properties (Constant)
        PATH = 'FUNDAMENTAL_OOB_BLOCKER'
        CLASS = 'SECONDARY_OOB_BLOCKER_ANALYSIS'   % not the primary RFI requirement (victim-band PSD is)
        ST_UNKNOWN = 'PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN'
        ST_MISSING = 'INPUT_MISSING'
        DIAGNOSTIC = 'screening_suppression_to_inband_limit_db'
    end
    methods (Static)
        function r = evaluate(blockerPort_dBm, rxRejection_dB, blockingLimit_dBm)
            K = rfscreen.psd.OobBlockerPath;
            r = struct('blocker_port_dBm', blockerPort_dBm, 'rejection_dB', rxRejection_dB, ...
                'post_filter_dBm', NaN, 'blocking_limit_dBm', blockingLimit_dBm, 'margin_dB', NaN, 'status', '');
            if isnan(blockerPort_dBm); r.status = K.ST_MISSING; return; end
            if isnan(rxRejection_dB) || isnan(blockingLimit_dBm); r.status = K.ST_UNKNOWN; return; end
            r.post_filter_dBm = rfscreen.psd.PsdMath.applyAttenuation(blockerPort_dBm, rxRejection_dB);
            r.margin_dB = blockingLimit_dBm - r.post_filter_dBm;
            if r.margin_dB >= 0; r.status = 'PASS'; else; r.status = 'FAIL'; end
        end

        function d = screeningSuppression(blockerPort_dBm, inbandAllowable_dBm)
            %SCREENINGSUPPRESSION Historical diagnostic only (not an OOB rejection requirement).
            d = blockerPort_dBm - inbandAllowable_dBm;
        end
    end
end
