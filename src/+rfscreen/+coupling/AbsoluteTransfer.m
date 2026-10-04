classdef AbsoluteTransfer
    %ABSOLUTETRANSFER Antenna-port-to-port absolute transfer from a Phase-1 PairResult (ICD coupling.md 7).
    %   Single place that decides what `absoluteTransfer_dB` means for each coupling model:
    %     FAR_FIELD  : Gtx + Grx - FSPL            (physical only when far-field valid)
    %     CST / other full-wave or measured S21 : the tabulated S21 itself (installed, includes
    %                  both antennas' patterns -- Gtx/Grx are NOT added)
    %     PATTERN_ONLY / invalid : not absolute (isAbsolute = false, NaN)
    methods (Static)
        function a = fromPair(pr)
            a = struct('isAbsolute', false, 'absoluteTransfer_dB', NaN, 'couplingValidity', '');
            type = pr.couplingModelType;
            phys = pr.isPhysicalCoupling && isfinite(pr.couplingMetric_dB);
            if strcmp(type, 'FAR_FIELD')
                if phys && isfinite(pr.txGain_dBi) && isfinite(pr.rxGain_dBi)
                    a.isAbsolute = true;
                    a.absoluteTransfer_dB = pr.txGain_dBi + pr.rxGain_dBi - pr.couplingMetric_dB;
                    a.couplingValidity = 'FAR_FIELD_VALID';
                    if isprop(pr, 'couplingValidity') && strcmp(pr.couplingValidity, 'FREE_SPACE_ASSUMED')
                        a.couplingValidity = 'FREE_SPACE_ASSUMED';
                    end
                else
                    a.couplingValidity = 'FAR_FIELD_INVALID_OR_UNKNOWN';
                end
            elseif rfscreen.coupling.AbsoluteTransfer.isPortToPort(type)
                if phys
                    a.isAbsolute = true;
                    a.absoluteTransfer_dB = pr.couplingMetric_dB;
                    a.couplingValidity = 'FULL_WAVE_COUPLING';
                else
                    a.couplingValidity = 'S21_UNAVAILABLE';
                end
            elseif strcmp(type, 'PATTERN_ONLY')
                a.couplingValidity = 'PATTERN_ONLY';
            end
        end
        function tf = isPortToPort(modelType)
            %ISPORTTOPORT Models whose metric is a port-to-port S21 (gain), not a path loss.
            tf = any(strcmp(modelType, {'CST', 'MEASURED_S21', 'HFSS', 'OTHER_SOLVER'}));
        end
    end
end
