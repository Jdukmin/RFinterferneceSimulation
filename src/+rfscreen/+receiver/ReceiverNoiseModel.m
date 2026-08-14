classdef ReceiverNoiseModel
    %RECEIVERNOISEMODEL Linear thermal noise (ICD receiver_susceptibility.md 4).
    %   Exactly one method: noiseFigure_dB (+refTemp_K, default 290) OR
    %   systemNoiseTemp_K. Terms/plane explicit; nothing invented (Task 18).
    %     NF method : N_W = k * T0 * F * B , F = 10^(NF/10)
    %     Tsys      : N_W = k * Tsys * B
    properties (SetAccess = private)
        method          % 'NOISE_FIGURE' | 'SYSTEM_TEMP'
        noiseFigure_dB  % NaN if not used
        refTemp_K       % NaN if not used
        systemNoiseTemp_K % NaN if not used
        referencePlane
        provenance
    end
    methods
        function obj = ReceiverNoiseModel(opts)
            if nargin < 1 || isempty(opts); opts = struct(); end
            V = rfscreen.util.Validate;
            hasNF = isfield(opts, 'noiseFigure_dB') && ~isempty(opts.noiseFigure_dB);
            hasTs = isfield(opts, 'systemNoiseTemp_K') && ~isempty(opts.systemNoiseTemp_K);
            if hasNF && hasTs
                error('rfscreen:receiver:noiseAmbiguous', ...
                    'provide exactly one of noiseFigure_dB or systemNoiseTemp_K.');
            elseif ~hasNF && ~hasTs
                error('rfscreen:receiver:noiseIncomplete', ...
                    'provide noiseFigure_dB or systemNoiseTemp_K (nothing is invented).');
            end
            obj.noiseFigure_dB = NaN; obj.refTemp_K = NaN; obj.systemNoiseTemp_K = NaN;
            if hasNF
                obj.method = 'NOISE_FIGURE';
                obj.noiseFigure_dB = V.finiteScalar(opts.noiseFigure_dB, 'noiseFigure_dB');
                if obj.noiseFigure_dB < 0
                    error('rfscreen:receiver:badNF', 'noiseFigure_dB must be >= 0.');
                end
                if isfield(opts, 'refTemp_K') && ~isempty(opts.refTemp_K)
                    obj.refTemp_K = V.positiveScalar(opts.refTemp_K, 'refTemp_K');
                else
                    obj.refTemp_K = rfscreen.util.Constants.standardNoiseTemp_K();
                end
            else
                obj.method = 'SYSTEM_TEMP';
                obj.systemNoiseTemp_K = V.positiveScalar(opts.systemNoiseTemp_K, 'systemNoiseTemp_K');
            end
            obj.referencePlane = rfscreen.receiver.ReferencePlane.RECEIVER_RF_INPUT;
            if isfield(opts, 'provenance') && ~isempty(opts.provenance)
                obj.provenance = opts.provenance;
            else
                obj.provenance = 'SYNTHETIC_TEST';
            end
        end

        function w = noisePower_W(obj, bandwidth_Hz)
            B = rfscreen.util.Validate.positiveScalar(bandwidth_Hz, 'bandwidth_Hz');
            k = rfscreen.util.Constants.boltzmann_JperK();
            if strcmp(obj.method, 'NOISE_FIGURE')
                F = 10.^(obj.noiseFigure_dB/10);
                w = k * obj.refTemp_K * F * B;
            else
                w = k * obj.systemNoiseTemp_K * B;
            end
        end

        function dBm = noisePower_dBm(obj, bandwidth_Hz)
            dBm = rfscreen.util.Units.w2dbm(obj.noisePower_W(bandwidth_Hz));
        end
    end
end
