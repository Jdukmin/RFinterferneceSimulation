classdef IntermodulationAnalyzer
    %INTERMODULATIONANALYZER Two-tone IM3 over interferer pairs (ICD 6, Task 15-22).
    %   Input-referred IM3 power from IIP3; unordered distinct pairs i<j; product
    %   frequencies 2f1-f2 and 2f2-f1 computed exactly; passband relevance via the
    %   channel filter. Requires IIP3 and >=2 valid absolute interferers.
    methods (Static)
        function out = analyze(inputs, frontEnd, channelFilter, rxBand_Hz, criterion)
            if nargin < 5; criterion = []; end
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
            for a = 1:numel(valid)-1
                for b = a+1:numel(valid)
                    i = valid(a); j = valid(b);
                    f1 = inputs(i).freq_Hz; f2 = inputs(j).freq_Hz;
                    P1 = inputs(i).lnaInputPower_dBm; P2 = inputs(j).lnaInputPower_dBm;
                    % product 2f1 - f2
                    products{end+1} = rfscreen.nonlinear.IntermodulationAnalyzer.makeProduct( ...
                        inputs(i).txId, inputs(j).txId, f1, f2, P1, P2, iip3, ...
                        PT.TWO_F1_MINUS_F2, 2*f1 - f2, 2*P1 + P2 - 2*iip3, ...
                        channelFilter, rxBand_Hz, criterion); %#ok<AGROW>
                    % product 2f2 - f1
                    products{end+1} = rfscreen.nonlinear.IntermodulationAnalyzer.makeProduct( ...
                        inputs(i).txId, inputs(j).txId, f1, f2, P1, P2, iip3, ...
                        PT.TWO_F2_MINUS_F1, 2*f2 - f1, 2*P2 + P1 - 2*iip3, ...
                        channelFilter, rxBand_Hz, criterion); %#ok<AGROW>
                end
            end

            % completeness: were any active interferers dropped for lack of evidence?
            if numel(valid) < numel(inputs)
                validity = NV.INCOMPLETE_INTERFERER_SET;
                warnings{end+1} = 'some interferers lacked absolute evidence: IM3 set incomplete';
            else
                validity = NV.VALID;
            end
            out = struct('products', {products}, 'validity', validity, 'warnings', {warnings});
        end
    end

    methods (Static, Access = private)
        function pr = makeProduct(txId1, txId2, f1, f2, P1, P2, iip3, ptype, fIM, eqIn, channelFilter, rxBand, criterion)
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
