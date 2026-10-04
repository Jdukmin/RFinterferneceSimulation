classdef EmissionSpec
    %EMISSIONSPEC One TX source-emission entry (row of tx_emission_masks.csv / reference_scenarios.csv).
    %   A source is a COMPLIANT-EMISSION statement (regulatory limit, supplier spec, measurement or
    %   engineering assumption) at a stated reference plane and reference bandwidth.
    %
    %   emission_type / unit:
    %     BROADBAND_PSD : dBm/Hz | dBc/Hz                     (density, reference_bandwidth_hz ignored)
    %                     dBm | dBc  + reference_bandwidth_hz  (mask stated per RBW, e.g. dBc/4 kHz;
    %                                                          converted: level - 10 log10(RBW))
    %     DISCRETE_SPUR : dBm | dBc (+ reference_bandwidth_hz)  (tone: NEVER spread into dBm/Hz)
    %     HARMONIC      : dBm | dBc
    %   frequency: a point (frequency_hz) or a flat range [frequency_lo_hz, frequency_hi_hz].
    %   reference_plane:
    %     PA_OUTPUT, FILTER_INPUT  conducted, upstream of the TX output filter
    %     FILTER_OUTPUT            conducted, after the TX output filter
    %     ANTENNA_PORT             conducted at the TX antenna input
    %     RADIATED_EIRP_PSD        radiated (TX antenna gain already inside; level unit dBm/Hz or dBm+RBW)
    %   assumption_class: REGULATORY_LIMIT | SUPPLIER_SPEC | MEASURED | ENGINEERING_ASSUMPTION |
    %                     REFERENCE_CROSSCHECK
    properties (Constant)
        TYPES = {'BROADBAND_PSD', 'DISCRETE_SPUR', 'HARMONIC'}
        PLANES = {'PA_OUTPUT', 'FILTER_INPUT', 'FILTER_OUTPUT', 'ANTENNA_PORT', 'RADIATED_EIRP_PSD'}
        CLASSES = {'REGULATORY_LIMIT', 'SUPPLIER_SPEC', 'MEASURED', 'ENGINEERING_ASSUMPTION', 'REFERENCE_CROSSCHECK'}
        COLUMNS = {'tx_system', 'victim_band', 'frequency_hz', 'frequency_lo_hz', 'frequency_hi_hz', 'emission_type', ...
            'level', 'unit', 'reference_bandwidth_hz', 'reference_plane', 'carrier_frequency_hz', 'filter_state', ...
            'standard_or_source', 'provenance', 'assumption_class'}
    end
    properties (SetAccess = private)
        txSystem
        victimBand
        freq_Hz = NaN
        freqLo_Hz = NaN
        freqHi_Hz = NaN
        emissionType
        level
        unit
        refBw_Hz = NaN
        referencePlane
        carrier_Hz = NaN
        filterState = 'UNKNOWN'
        standardOrSource
        provenance
        assumptionClass
    end
    methods
        function obj = EmissionSpec(s)
            %EMISSIONSPEC s: struct with the COLUMNS fields (numeric fields may be numbers or text).
            V = rfscreen.util.Validate;
            num = @(f) rfscreen.psd.EmissionSpec.numField(s, f);
            obj.txSystem = V.id(s.tx_system, 'tx_system');
            obj.victimBand = V.id(s.victim_band, 'victim_band');
            obj.freq_Hz = num('frequency_hz'); obj.freqLo_Hz = num('frequency_lo_hz'); obj.freqHi_Hz = num('frequency_hi_hz');
            if isnan(obj.freq_Hz) && ~(isfinite(obj.freqLo_Hz) && isfinite(obj.freqHi_Hz) && obj.freqHi_Hz >= obj.freqLo_Hz)
                error('rfscreen:psd:noFrequency', 'give frequency_hz or a frequency_lo_hz..frequency_hi_hz range.');
            end
            obj.emissionType = V.member(s.emission_type, rfscreen.psd.EmissionSpec.TYPES, 'emission_type');
            obj.referencePlane = V.member(s.reference_plane, rfscreen.psd.EmissionSpec.PLANES, 'reference_plane');
            obj.assumptionClass = V.member(s.assumption_class, rfscreen.psd.EmissionSpec.CLASSES, 'assumption_class');
            obj.level = V.finiteScalar(num('level'), 'level'); obj.unit = s.unit;
            obj.refBw_Hz = num('reference_bandwidth_hz'); obj.carrier_Hz = num('carrier_frequency_hz');
            if isfield(s, 'filter_state') && ~isempty(s.filter_state); obj.filterState = s.filter_state; end
            obj.standardOrSource = s.standard_or_source; obj.provenance = s.provenance;
            hasBw = isfinite(obj.refBw_Hz) && obj.refBw_Hz > 0;
            switch obj.emissionType
                case 'BROADBAND_PSD'
                    ok = any(strcmp(obj.unit, {'dBm/Hz', 'dBc/Hz'})) || (any(strcmp(obj.unit, {'dBm', 'dBc'})) && hasBw);
                    if ~ok
                        error('rfscreen:psd:unitTypeMismatch', ['BROADBAND_PSD needs dBm/Hz | dBc/Hz, or dBm | dBc with ' ...
                            'reference_bandwidth_hz (got %s).'], obj.unit);
                    end
                otherwise
                    if ~any(strcmp(obj.unit, {'dBm', 'dBc'}))
                        error('rfscreen:psd:unitTypeMismatch', '%s cannot be given in %s (allowed: dBm, dBc).', obj.emissionType, obj.unit);
                    end
                    if strcmp(obj.emissionType, 'DISCRETE_SPUR') && ~hasBw
                        error('rfscreen:psd:spurRbw', 'DISCRETE_SPUR needs reference_bandwidth_hz.');
                    end
            end
            if strcmp(obj.referencePlane, 'RADIATED_EIRP_PSD') && any(strcmp(obj.unit, {'dBc/Hz', 'dBc'}))
                error('rfscreen:psd:eirpRelative', 'RADIATED_EIRP_PSD must be absolute (dBm/Hz or dBm per RBW).');
            end
        end

        function tf = isRadiated(obj)
            tf = strcmp(obj.referencePlane, 'RADIATED_EIRP_PSD');
        end

        function tf = covers(obj, f_Hz)
            if isfinite(obj.freqLo_Hz); tf = f_Hz >= obj.freqLo_Hz - 1 & f_Hz <= obj.freqHi_Hz + 1;
            else; tf = abs(f_Hz - obj.freq_Hz) <= 1; end
        end

        function p = psdDbmHz(obj, carrier_dBm)
            %PSDDBMHZ Broadband PSD at the reference plane [dBm/Hz] (dBc forms need the carrier [dBm]).
            if ~strcmp(obj.emissionType, 'BROADBAND_PSD')
                error('rfscreen:psd:notAPsd', '%s is a discrete level (%s), not a PSD.', obj.emissionType, obj.unit);
            end
            p = obj.level;
            if any(strcmp(obj.unit, {'dBc/Hz', 'dBc'})); p = rfscreen.psd.PsdMath.dbcHzToDbmHz(p, carrier_dBm); end
            if any(strcmp(obj.unit, {'dBm', 'dBc'})); p = p - 10 * log10(obj.refBw_Hz); end
        end

        function p = powerDbm(obj, carrier_dBm)
            %POWERDBM Discrete spur / harmonic power at the reference plane [dBm].
            if strcmp(obj.emissionType, 'BROADBAND_PSD')
                error('rfscreen:psd:notAPower', 'BROADBAND_PSD (%s) has no discrete power; integrate it in a receiver bandwidth.', obj.unit);
            end
            if strcmp(obj.unit, 'dBc'); p = carrier_dBm + obj.level; else; p = obj.level; end
        end
    end
    methods (Static)
        function v = numField(s, f)
            if ~isfield(s, f) || isempty(s.(f)); v = NaN; return; end
            v = s.(f); if ischar(v); v = str2double(v); end
            if isempty(v); v = NaN; end
        end

        function s = blank()
            %BLANK Struct with every column (fill and pass to the constructor).
            c = rfscreen.psd.EmissionSpec.COLUMNS; s = struct();
            for i = 1:numel(c); s.(c{i}) = ''; end
        end
    end
end
