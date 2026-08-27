classdef IntermodulationAnalyzer
    %INTERMODULATIONANALYZER Two-tone IM3 over interferer pairs (ICD 6, Task 15-22).
    %   Input-referred IM3 power from IIP3; unordered distinct pairs i<j; product
    %   frequencies 2f1-f2 and 2f2-f1 computed exactly; passband relevance via the
    %   channel filter. Requires IIP3 and >=2 valid absolute interferers.
    %
    %   MODEL DOMAIN (Task 36): P_IM3,in = 2Pa+Pb-2*IIP3 is the SMALL-SIGNAL
    %   third-order extrapolation. It holds only while the device is essentially
    %   linear, i.e. the tones sit well below P1dB_in. Once a tone approaches or
    %   exceeds P1dB_in the device is compressing, the cubic law no longer applies,
    %   and the extrapolation can even return a product stronger than the
    %   fundamental (physically impossible). Such a result is reported with
    %   validity OUTSIDE_MODEL_DOMAIN and an explicit warning -- it is NOT silently
    %   returned as VALID, and it is NOT replaced by a fabricated saturated value
    %   (no fake physics): a compressed-regime IM level requires a measured or
    %   full-nonlinear device model this tool does not own.
    methods (Static)
        function out = analyze(inputs, frontEnd, channelFilter, rxBand_Hz, criterion, smallSignalMargin_dB)
            if nargin < 5; criterion = []; end
            % Headroom below P1dB_in required for the small-signal cubic law.
            % Explicit and overridable; never silently assumed elsewhere.
            if nargin < 6 || isempty(smallSignalMargin_dB); smallSignalMargin_dB = 10; end
            NV = rfscreen.receiver.NonlinearValidity;
            PT = rfscreen.receiver.ProductType;
            products = {}; warnings = {};

            hasFE = ~isempty(frontEnd);
            hasIIP3 = hasFE && frontEnd.hasIIP3();

            % valid absolute interferers only
            valid = [];
            for k = 1:numel(inputs)
                if inputs(k).isAbsolute && isfinite(inputs(k).lnaInputPower_dBm)
                    valid(end+1) = k; %#ok<AGROW>
                end
            end

            if ~hasFE
                out = struct('products', {products}, 'validity', NV.MISSING_FRONT_END, ...
                    'warnings', {{'no receiver front-end: IM3 withheld'}});
                return;
            end
            if ~hasIIP3
                out = struct('products', {products}, 'validity', NV.MISSING_IIP3, ...
                    'warnings', {{'no IIP3_in: IM3 withheld'}});
                return;
            end
            if numel(valid) < 2
                out = struct('products', {products}, 'validity', NV.ABSOLUTE_COUPLING_UNAVAILABLE, ...
                    'warnings', {{'fewer than 2 interferers with valid absolute coupling: no IM3 pairs'}});
                return;
            end

            iip3 = frontEnd.iip3_in_dBm;
            if frontEnd.hasP1dB(); p1dB = frontEnd.p1dB_in_dBm; else; p1dB = NaN; end
            anyOutside = false;
            for a = 1:numel(valid)-1
                for b = a+1:numel(valid)
                    i = valid(a); j = valid(b);
                    f1 = inputs(i).freq_Hz; f2 = inputs(j).freq_Hz;
                    P1 = inputs(i).lnaInputPower_dBm; P2 = inputs(j).lnaInputPower_dBm;
                    % product 2f1 - f2
                    products{end+1} = rfscreen.nonlinear.IntermodulationAnalyzer.makeProduct( ...
                        inputs(i).txId, inputs(j).txId, f1, f2, P1, P2, iip3, ...
                        PT.TWO_F1_MINUS_F2, 2*f1 - f2, 2*P1 + P2 - 2*iip3, ...
                        channelFilter, rxBand_Hz, criterion, p1dB, smallSignalMargin_dB); %#ok<AGROW>
                    anyOutside = anyOutside || strcmp(products{end}.validity, NV.OUTSIDE_MODEL_DOMAIN);
                    % product 2f2 - f1
                    products{end+1} = rfscreen.nonlinear.IntermodulationAnalyzer.makeProduct( ...
                        inputs(i).txId, inputs(j).txId, f1, f2, P1, P2, iip3, ...
                        PT.TWO_F2_MINUS_F1, 2*f2 - f1, 2*P2 + P1 - 2*iip3, ...
                        channelFilter, rxBand_Hz, criterion, p1dB, smallSignalMargin_dB); %#ok<AGROW>
                    anyOutside = anyOutside || strcmp(products{end}.validity, NV.OUTSIDE_MODEL_DOMAIN);
                end
            end

            % completeness: were any active interferers dropped for lack of evidence?
            if numel(valid) < numel(inputs)
                validity = NV.INCOMPLETE_INTERFERER_SET;
                warnings{end+1} = 'some interferers lacked absolute evidence: IM3 set incomplete';
            elseif anyOutside
                validity = NV.OUTSIDE_MODEL_DOMAIN;
                warnings{end+1} = ['one or more tones are not in the small-signal region ' ...
                    '(near/above P1dB_in): small-signal IM3 extrapolation does not apply'];
            else
                validity = NV.VALID;
            end
            out = struct('products', {products}, 'validity', validity, 'warnings', {warnings});
        end
    end

    methods (Static, Access = private)
        function pr = makeProduct(txId1, txId2, f1, f2, P1, P2, iip3, ptype, fIM, eqIn, channelFilter, rxBand, criterion, p1dB_in_dBm, smallSignalMargin_dB)
            s = struct();
            s.txId1 = txId1; s.txId2 = txId2;
            s.f1_Hz = f1; s.f2_Hz = f2; s.p1_dBm = P1; s.p2_dBm = P2;
            s.iip3_in_dBm = iip3;
            s.productType = ptype;
            s.productFrequency_Hz = fIM;
            s.equivalentInputPower_dBm = eqIn;
            if ~isempty(channelFilter) && fIM > 0
                s.channelResponse_dB = channelFilter.responseDb(fIM);
            else
                s.channelResponse_dB = 0;   % no channel filter modeled -> unfiltered
            end
            s.effectiveProductPower_dBm = eqIn + s.channelResponse_dB;
            s.inPassband = (fIM >= rxBand(1)) && (fIM <= rxBand(2));
            s.referencePlane = rfscreen.receiver.ReferencePlane.LNA_INPUT;
            s.validity = rfscreen.receiver.NonlinearValidity.VALID;
            s.warnings = {};
            if fIM <= 0
                s.warnings{end+1} = 'non-physical product frequency (<= 0)';
                s.validity = rfscreen.receiver.NonlinearValidity.OUTSIDE_MODEL_DOMAIN;
            end
            % --- small-signal domain guard (Task 36) ---
            s.p1dB_in_dBm = p1dB_in_dBm;
            s.smallSignalMargin_dB = smallSignalMargin_dB;
            toneMax = max(P1, P2);
            if isfinite(p1dB_in_dBm)
                s.toneHeadroomBelowP1dB_dB = p1dB_in_dBm - toneMax;
                if s.toneHeadroomBelowP1dB_dB < smallSignalMargin_dB
                    s.warnings{end+1} = sprintf(['tone at %.1f dBm is only %.1f dB below ' ...
                        'P1dB_in=%.1f dBm (< %.1f dB required): device is compressing, ' ...
                        'small-signal IM3 extrapolation is out of its validity domain'], ...
                        toneMax, s.toneHeadroomBelowP1dB_dB, p1dB_in_dBm, smallSignalMargin_dB);
                    s.validity = rfscreen.receiver.NonlinearValidity.OUTSIDE_MODEL_DOMAIN;
                end
            else
                s.toneHeadroomBelowP1dB_dB = NaN;
                s.warnings{end+1} = ['no P1dB_in: cannot verify the small-signal validity ' ...
                    'of the IM3 extrapolation'];
            end
            % a third-order product can never exceed the fundamental that creates it
            if eqIn > toneMax
                s.warnings{end+1} = sprintf(['IM3 product (%.1f dBm) exceeds the fundamental ' ...
                    'tone (%.1f dBm): non-physical, extrapolation invalid here'], eqIn, toneMax);
                s.validity = rfscreen.receiver.NonlinearValidity.OUTSIDE_MODEL_DOMAIN;
            end
            if ~isempty(criterion)
                ev = criterion.evaluate(s.effectiveProductPower_dBm);
                s.margin_dB = ev.margin_dB; s.passFail = ev.pass;
            else
                s.margin_dB = NaN; s.passFail = 'UNKNOWN';
            end
            pr = rfscreen.results.IntermodulationProduct(s);
        end
    end
end
