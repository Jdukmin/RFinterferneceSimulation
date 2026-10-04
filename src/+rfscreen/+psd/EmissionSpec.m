classdef EmissionSpec
    %EMISSIONSPEC One TX unwanted-emission entry (row of tx_emission_masks.csv).
    %   emission_type / unit pairs (anything else is refused):
    %     BROADBAND_PSD : dBc/Hz | dBm/Hz          (spectral mask, noise floor)
    %     DISCRETE_SPUR : dBc | dBm  (+ rbw_hz)     (tone in a stated RBW; never forced to dBm/Hz)
    %     HARMONIC      : dBc | dBm
    %   reference_plane (where the level is specified) decides which loss/gain terms still apply:
    %     PA_OUTPUT, FILTER_INPUT -> TX filter + downstream chain loss, then C_EM incl. G_tx
    %     FILTER_OUTPUT           -> downstream chain loss only (filter already included)
    %     ANTENNA_PORT            -> no chain loss; C_EM incl. G_tx (realized gain: mismatch inside)
    %     RADIATED_EIRP_PSD       -> no chain loss and NO G_tx; coupling = G_rx - FSPL; S21 refused
    properties (Constant)
        TYPES = {'BROADBAND_PSD', 'DISCRETE_SPUR', 'HARMONIC'}
        PLANES = {'PA_OUTPUT', 'FILTER_INPUT', 'FILTER_OUTPUT', 'ANTENNA_PORT', 'RADIATED_EIRP_PSD'}
    end
    properties (SetAccess = private)
        txSystem
        referencePlane
        carrier_Hz
        victimBand
        freq_Hz
        emissionType
        level
        unit
        rbw_Hz
        filterState
        provenance
    end
    methods
        function obj = EmissionSpec(txSystem, referencePlane, carrier_Hz, victimBand, freq_Hz, emissionType, level, unit, rbw_Hz, filterState, provenance)
            V = rfscreen.util.Validate;
            obj.txSystem = V.id(txSystem, 'tx_system');
            obj.referencePlane = V.member(referencePlane, rfscreen.psd.EmissionSpec.PLANES, 'reference_plane');
            obj.carrier_Hz = carrier_Hz; obj.victimBand = victimBand; obj.freq_Hz = freq_Hz;
            obj.emissionType = V.member(emissionType, rfscreen.psd.EmissionSpec.TYPES, 'emission_type');
            ok = struct('BROADBAND_PSD', {{'dBc/Hz', 'dBm/Hz'}}, 'DISCRETE_SPUR', {{'dBc', 'dBm'}}, 'HARMONIC', {{'dBc', 'dBm'}});
            if ~any(strcmp(unit, ok.(obj.emissionType)))
                error('rfscreen:psd:unitTypeMismatch', '%s cannot be given in %s (allowed: %s).', ...
                    obj.emissionType, unit, strjoin(ok.(obj.emissionType), ', '));
            end
            if strcmp(obj.emissionType, 'DISCRETE_SPUR') && ~(isfinite(rbw_Hz) && rbw_Hz > 0)
                error('rfscreen:psd:spurRbw', 'DISCRETE_SPUR needs rbw_hz.');
            end
            obj.level = V.finiteScalar(level, 'level'); obj.unit = unit; obj.rbw_Hz = rbw_Hz;
            obj.filterState = filterState; obj.provenance = provenance;
        end

        function p = psdDbmHz(obj, carrier_dBm)
            %PSDDBMHZ Broadband PSD at the reference plane [dBm/Hz].
            if ~strcmp(obj.emissionType, 'BROADBAND_PSD')
                error('rfscreen:psd:notAPsd', '%s is a discrete level (%s), not a PSD.', obj.emissionType, obj.unit);
            end
            if strcmp(obj.unit, 'dBc/Hz'); p = rfscreen.psd.PsdMath.dbcHzToDbmHz(obj.level, carrier_dBm); else; p = obj.level; end
        end

        function p = powerDbm(obj, carrier_dBm)
            %POWERDBM Discrete spur / harmonic power at the reference plane [dBm].
            if strcmp(obj.emissionType, 'BROADBAND_PSD')
                error('rfscreen:psd:notAPower', 'BROADBAND_PSD (%s) has no discrete power; integrate it in a receiver bandwidth.', obj.unit);
            end
            if strcmp(obj.unit, 'dBc'); p = carrier_dBm + obj.level; else; p = obj.level; end
        end

        function [chain_dB, includeTxGain] = chainTerms(obj, chain)
            %CHAINTERMS Loss still to apply downstream of the reference plane, and whether the
            %   TX antenna gain is still to be added. chain: struct(filter_dB, post_dB) (NaN = unknown).
            switch obj.referencePlane
                case {'PA_OUTPUT', 'FILTER_INPUT'}; chain_dB = chain.filter_dB + chain.post_dB; includeTxGain = true;
                case 'FILTER_OUTPUT'; chain_dB = chain.post_dB; includeTxGain = true;
                case 'ANTENNA_PORT'; chain_dB = 0; includeTxGain = true;
                case 'RADIATED_EIRP_PSD'; chain_dB = 0; includeTxGain = false;
            end
        end
    end
end
