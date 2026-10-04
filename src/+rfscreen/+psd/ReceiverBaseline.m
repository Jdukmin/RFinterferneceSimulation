classdef ReceiverBaseline
    %RECEIVERBASELINE Victim receiver PSD criterion and (separate) integration bandwidth.
    %   data/rfi_psd/receiver_baseline.csv. The tuning / allocated band is where the PSD mask
    %   PSD_victim_port(f) <= PSD_allowable(f) is checked (1st-stage EMC/RFI criterion); the
    %   integration bandwidth is only used for the 2nd-stage receiver evaluation
    %   I_rx = int PSD |H|^2 df around the selected channel. The two are never interchanged.
    %   desired_signal_reference_dbm is a signal level, NOT an interference threshold.
    methods (Static)
        function B = read(path)
            T = rfscreen.spacecraft.SpacecraftDataReader.readTable(path);
            B = struct([]);
            num = @(c, r) str2double(T.(c){r});
            for r = 1:T.nRows
                b = struct('receiver', T.receiver{r}, 'victim_band', T.victim_band{r}, ...
                    'tuning_lo_Hz', num('tuning_lo_mhz', r) * 1e6, 'tuning_hi_Hz', num('tuning_hi_mhz', r) * 1e6, ...
                    'tuning_prov', T.tuning_prov{r}, 'channel_fc_Hz', num('channel_fc_mhz', r) * 1e6, ...
                    'integration_bw_Hz', num('integration_bw_hz', r), 'integration_bw_prov', T.integration_bw_prov{r}, ...
                    'rx_filter_model', T.rx_filter_model{r}, 'nf_dB', num('nf_db', r), 'nf_prov', T.nf_prov{r}, ...
                    'i_n_max_dB', num('i_n_max_db', r), 'desired_signal_reference_dbm', num('desired_signal_reference_dbm', r), ...
                    'desired_prov', T.desired_prov{r}, 'note', T.note{r});
                b.noise_psd_dBmHz = rfscreen.psd.PsdMath.noisePsd(b.nf_dB);
                b.allowable_psd_dBmHz = rfscreen.psd.PsdMath.allowablePsd(b.nf_dB, b.i_n_max_dB);
                b.allowable_integrated_dBm = b.allowable_psd_dBmHz + 10 * log10(b.integration_bw_Hz);
                if isempty(B); B = b; else; B(end+1) = b; end %#ok<AGROW>
            end
        end

        function b = lookup(B, receiver)
            b = B(strcmp({B.receiver}, receiver));
            if numel(b) ~= 1
                error('rfscreen:psd:unknownReceiver', 'receiver %s not in receiver_baseline.csv.', receiver);
            end
        end

        function f = tuningSweep(b, n)
            %TUNINGSWEEP n frequencies across the whole tuning / allocated band (PSD-mask domain).
            f = linspace(b.tuning_lo_Hz, b.tuning_hi_Hz, n);
        end

        function [f, H2] = channelSamples(b, n)
            %CHANNELSAMPLES Integration grid of the selected channel (2nd stage), ideal rectangular |H|^2.
            if ~strcmp(b.rx_filter_model, 'IDEAL_RECT')
                error('rfscreen:psd:filterModel', 'only IDEAL_RECT receiver filters are implemented.');
            end
            f = b.channel_fc_Hz + linspace(-0.5, 0.5, n) * b.integration_bw_Hz; H2 = zeros(1, n);
        end
    end
end
