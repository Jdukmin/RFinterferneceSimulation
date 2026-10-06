classdef PortMismatchRescaledResponse
    %PORTMISMATCHRESCALEDRESPONSE TX-side L-band response when the CST accepted-power normalization of
    %   the RealizedGain is unreliable (S-TC TX, legacy id S_TM_TX, at GPS L2/L5).
    %   The unreliable RealizedGain cuts are kept as CST_VALUE_PRESENT_BUT_NORMALIZATION_UNRELIABLE and
    %   are NOT used. Instead (route PORT_MISMATCH_RESCALED_LBAND):
    %     G_tx,eff(f, dir) = G_acc,env(dir) + R_mismatch
    %       G_acc,env : direction-wise maximum of the accepted-power Gain cuts (mismatch excluded) whose
    %                   normalization is reliable in the L band (S antenna: L1 1.563/1.57542/1.588 GHz and
    %                   L2 1.2276 GHz) -> one conservative L-band radiation envelope for L2 and L5
    %       R_mismatch: port-mismatch rescaling [dB, <= 0], OWNER_ENGINEERING_BOUND (-10 dB, referenced to
    %                   the L1 accepted-power fraction 10log10(0.0957) = -10.19 dB)
    %   Equivalent split used in reports: effective TX source = ITU source + R_mismatch, then G_acc,env.
    %   The rescaling is neither a CST value nor an ITU value.
    properties (Constant)
        ROUTE = 'PORT_MISMATCH_RESCALED_LBAND'
        UNRELIABLE = 'CST_VALUE_PRESENT_BUT_NORMALIZATION_UNRELIABLE'
        PROVENANCE = 'OWNER_ENGINEERING_BOUND'
        CONFIDENCE = 'ENGINEERING_BOUND - L1-referenced 10 dB port-mismatch rescaling'
    end
    properties (SetAccess = private)
        family
        envelopeSources = {}     % 'band@GHz' of the Gain cuts in the envelope
        xz = []
        yz = []
        rescale_dB
    end
    methods (Static)
        function r = fromRepository(repoRoot, family, envelopeBands, rescale_dB, prov)
            if nargin < 5 || isempty(prov)
                prov = jsondecode(fileread(fullfile(repoRoot, 'data', 'antenna_port_response_cst', 'provenance.json')));
            end
            if ~(isscalar(rescale_dB) && isfinite(rescale_dB) && rescale_dB <= 0)
                error('rfscreen:psd:badRescaling', 'port-mismatch rescaling must be a finite value <= 0 dB.');
            end
            cuts = prov.cuts; if iscell(cuts); cuts = [cuts{:}]; end
            sel = strcmp({cuts.family}, family) & ismember({cuts.band}, envelopeBands) & strcmp({cuts.quantity}, 'Gain');
            c = cuts(sel);
            if isempty(c); error('rfscreen:psd:noGainCuts', 'no accepted-power Gain cuts for %s in %s.', family, strjoin(envelopeBands, '/')); end
            if any(~[c.normalization_reliable])
                error('rfscreen:psd:unreliableEnvelope', 'envelope Gain cuts must have normalization_reliable = true.');
            end
            r = rfscreen.psd.PortMismatchRescaledResponse(); r.family = family; r.rescale_dB = rescale_dB;
            r.xz = -Inf(1, 360); r.yz = -Inf(1, 360);
            for i = 1:numel(c)
                g = rfscreen.kaa.KaVictimResponse.readCut(fullfile(repoRoot, c(i).path));
                if strcmp(c(i).plane, 'XZ'); r.xz = max(r.xz, g); else; r.yz = max(r.yz, g); end
                tag = sprintf('%s@%.6g', c(i).band, c(i).frequency_hz / 1e9);
                if ~any(strcmp(r.envelopeSources, tag)); r.envelopeSources{end+1} = tag; end
            end
            if any(isinf(r.xz)) || any(isinf(r.yz)); error('rfscreen:psd:badEnvelope', 'envelope needs both XZ and YZ cuts.'); end
        end

        function s = unreliableStatus(repoRoot, family, band, prov)
            %UNRELIABLESTATUS Peak of the kept-but-unused RealizedGain cuts (reporting only).
            if nargin < 4 || isempty(prov)
                prov = jsondecode(fileread(fullfile(repoRoot, 'data', 'antenna_port_response_cst', 'provenance.json')));
            end
            cuts = prov.cuts; if iscell(cuts); cuts = [cuts{:}]; end
            c = cuts(strcmp({cuts.family}, family) & strcmp({cuts.band}, band) & strcmp({cuts.quantity}, 'RealizedGain'));
            pk = -Inf; fr = [];
            for i = 1:numel(c)
                pk = max(pk, max(rfscreen.kaa.KaVictimResponse.readCut(fullfile(repoRoot, c(i).path))));
                fr(end+1) = c(i).accepted_power_fraction; %#ok<AGROW>
            end
            st = rfscreen.psd.PortMismatchRescaledResponse.UNRELIABLE;
            if isempty(c) || all([c.normalization_reliable]); st = 'NORMALIZATION_RELIABLE'; end
            s = struct('status', st, 'peak_dBi', pk, 'acceptedFractions', fr, 'used', false);
        end
    end
    methods
        function g = envelopeGainAt(r, dL)
            %ENVELOPEGAINAT Accepted-power Gain envelope [dBi] toward CST-local direction dL (no rescaling).
            g = rfscreen.kaa.KaVictimResponse.cutGain(r.xz, r.yz, dL);
        end

        function g = effectiveGainAt(r, dL)
            %EFFECTIVEGAINAT Envelope + port-mismatch rescaling [dBi] (realised-gain equivalent).
            g = r.envelopeGainAt(dL) + r.rescale_dB;
        end

        function p = peakEnvelope_dBi(r)
            p = max([r.xz r.yz]);
        end
    end
end
