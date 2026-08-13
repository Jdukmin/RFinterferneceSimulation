classdef InterferenceClassifier
    %INTERFERENCECLASSIFIER Map a frequency relation to a Phase-1 interference type.
    %   Phase 1: NONE / IN_BAND / ADJACENT_BAND. BLOCKING_COMPRESSION and
    %   INTERMODULATION_SPURIOUS are reserved (require RFFrontEnd data, AR-041)
    %   and are never asserted from pattern/spectral screening alone.
    methods (Static)
        function itype = fromFrequencyRelation(freqRelType)
            T  = rfscreen.rf.FrequencyRelationType;
            IT = rfscreen.results.InterferenceType;
            switch freqRelType
                case T.IN_BAND
                    itype = IT.IN_BAND;
                case T.ADJACENT_BAND
                    itype = IT.ADJACENT_BAND;
                otherwise
                    itype = IT.NONE;
            end
        end
    end
end
