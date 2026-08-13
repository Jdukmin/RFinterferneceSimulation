classdef LobeClassifier
    %LOBECLASSIFIER Main/Side/Back classification (AR-030, AR-031). Metadata only;
    %   NEVER a substitute for the actual gain value used in metrics (SR-060).
    %   Thresholds come from config.LobeClassificationPolicy (never hard-coded).
    methods (Static)
        function lobe = classify(pattern, frequency_Hz, az_deg, el_deg, policy, gain_dBi)
            %CLASSIFY Return a LobeClass char for a direction on a pattern.
            if nargin < 5 || isempty(policy)
                policy = rfscreen.config.LobeClassificationPolicy();
            end
            L = rfscreen.results.LobeClass;

            % Off-boresight angle decides BACK first (geometry-based).
            ang = rfscreen.geometry.DirectionCalculator.offBoresightAngle(az_deg, el_deg);
            if ang > policy.backAngleDeg
                lobe = L.BACK;
                return;
            end

            if nargin < 6 || isempty(gain_dBi)
                gain_dBi = pattern.evaluate(frequency_Hz, az_deg, el_deg);
            end
            peak = rfscreen.interference.LobeClassifier.peakGain(pattern, frequency_Hz);

            if ~isfinite(gain_dBi) || ~isfinite(peak)
                lobe = L.SIDE;   % undefined gain -> conservative non-main
                return;
            end
            if gain_dBi >= peak - policy.mainDropDb
                lobe = L.MAIN;
            else
                lobe = L.SIDE;
            end
        end

        function peak = peakGain(pattern, frequency_Hz)
            %PEAKGAIN Peak gain [dBi] of a pattern at the nearest frequency plane.
            g = pattern.grid;
            f = g.frequency_Hz;
            [~, idx] = min(abs(f - frequency_Hz));
            plane = g.gain_dBi(:, :, idx);
            plane = plane(isfinite(plane));
            if isempty(plane)
                peak = NaN;
            else
                peak = max(plane(:));
            end
        end
    end
end
