classdef KaRfiPath
    %KARFIPATH Source-model routing and path/status vocabulary for KAA-TX RFI.
    %   Two Ka paths are never mixed:
    %     KA_FUNDAMENTAL_OOB_BLOCKING : KAA 25.5-27 GHz carrier -> reflector near field -> victim antenna
    %                                   Ka out-of-band response -> victim port -> receiver front end
    %     KA_SPUR_INBAND              : Ka TX spur/harmonic falling in the victim RX band -> victim in-band
    %                                   gain; needs the KAA emission mask + KAA response at the spur
    %                                   frequency (INPUT_MISSING when absent)
    %   Routing: KAA TX onboard -> REFLECTOR_APERTURE_NEAR_FIELD; the far-field pattern path is used only
    %   for validation or at d >= FAR_FACTOR * 2D^2/lambda. Every other TX keeps its existing
    %   free-space pattern (Friis) path unchanged.
    properties (Constant)
        FUNDAMENTAL = 'KA_FUNDAMENTAL_OOB_BLOCKING'
        SPUR = 'KA_SPUR_INBAND'
        NEAR_FIELD = 'REFLECTOR_APERTURE_NEAR_FIELD'
        FAR_FIELD = 'FAR_FIELD_PATTERN_FRIIS'
        FREE_SPACE = 'FREE_SPACE_PATTERN_FRIIS'
        FAR_FACTOR = 1
        RX_UNKNOWN = 'PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN'   % same label as rfscreen.psd.OobBlockerPath
        RX_NOT_REACHED = 'PORT_COUPLING_NOT_EVALUATED'
    end
    methods (Static)
        function m = sourceModelFor(txFamily, distance_m, Rff_m, purpose)
            %SOURCEMODELFOR Coupling source model for a TX family at a given separation.
            %   purpose: 'ONBOARD' (default) | 'VALIDATION'.
            if nargin < 4 || isempty(purpose); purpose = 'ONBOARD'; end
            K = rfscreen.kaa.KaRfiPath;
            if ~strcmp(txFamily, 'KA'); m = K.FREE_SPACE; return; end
            if strcmp(purpose, 'VALIDATION') || distance_m >= K.FAR_FACTOR * Rff_m
                m = K.FAR_FIELD;
            else
                m = K.NEAR_FIELD;
            end
        end

        function s = receiverImpact(rxSystem, portEvaluated)
            %RECEIVERIMPACT Receiver-level status. No PASS/FAIL without BPF/preselector rejection,
            %   blocking, P1dB and IIP3 data at the Ka frequency.
            K = rfscreen.kaa.KaRfiPath;
            if ~portEvaluated; s = K.RX_NOT_REACHED; return; end
            have = isfield(rxSystem, 'p1db_in_dBm') && isfinite(rxSystem.p1db_in_dBm) && ...
                isfield(rxSystem, 'iip3_in_dBm') && isfinite(rxSystem.iip3_in_dBm) && ...
                isfield(rxSystem, 'kaRejection_dB') && isfinite(rxSystem.kaRejection_dB);
            if have
                s = 'RECEIVER_DATA_PRESENT_EVALUATE_SEPARATELY';
            else
                s = K.RX_UNKNOWN;
            end
        end

        function r = spurPath(victimSystemId, rxBand_Hz, emissionMask)
            %SPURPATH KA_SPUR_INBAND record. Without a KAA emission mask/spur table nothing is computed.
            K = rfscreen.kaa.KaRfiPath;
            r = struct('path', K.SPUR, 'victim', victimSystemId, 'rxBand_Hz', rxBand_Hz, ...
                'victimGainBasis', 'victim IN-BAND gain at the spur frequency (normal operating band)', ...
                'status', 'INPUT_MISSING', 'P_port_dBm', NaN, ...
                'reason', 'KAA TX emission mask / spur-harmonic table and KAA response at the spur frequency are not in the inputs');
            if nargin >= 3 && ~isempty(emissionMask)
                r.status = 'MASK_PROVIDED_EVALUATE_SEPARATELY'; r.reason = 'emission mask supplied';
            end
        end
    end
end
