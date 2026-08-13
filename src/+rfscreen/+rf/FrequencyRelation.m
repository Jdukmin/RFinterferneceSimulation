classdef FrequencyRelation
    %FREQUENCYRELATION Classify spectral relation between two bands (AR-040).
    %   classify([txLo txHi],[rxLo rxHi], policy) -> struct(type, overlap_Hz, separation_Hz).
    methods (Static)
        function r = classify(txBand_Hz, rxBand_Hz, policy)
            if nargin < 3 || isempty(policy)
                policy = rfscreen.config.FrequencyRelationPolicy();
            end
            tx = rfscreen.rf.FrequencyRelation.checkBand(txBand_Hz, 'txBand_Hz');
            rx = rfscreen.rf.FrequencyRelation.checkBand(rxBand_Hz, 'rxBand_Hz');

            overlap = min(tx(2), rx(2)) - max(tx(1), rx(1));   % >0 if overlapping
            r = struct();
            T = rfscreen.rf.FrequencyRelationType;
            if overlap > 0
                r.type = T.IN_BAND;
                r.overlap_Hz = overlap;
                r.separation_Hz = 0;
            else
                separation = max(tx(1), rx(1)) - min(tx(2), rx(2));  % >=0 gap
                separation = max(separation, 0);
                r.overlap_Hz = 0;
                r.separation_Hz = separation;
                if separation <= policy.guard_Hz
                    r.type = T.ADJACENT_BAND;
                else
                    r.type = T.OUT_OF_BAND;
                end
            end
        end
    end

    methods (Static, Access = private)
        function b = checkBand(band, name)
            if ~(isnumeric(band) && numel(band) == 2 && all(isfinite(band)))
                error('rfscreen:rf:badBand', '%s must be a finite [lo hi] pair.', name);
            end
            b = double(band(:)).';
            if b(2) < b(1)
                error('rfscreen:rf:badBand', '%s must have hi >= lo.', name);
            end
        end
    end
end
