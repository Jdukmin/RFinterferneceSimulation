classdef PatternCanonicalizer
    %PATTERNCANONICALIZER Raw cut -> CanonicalPatternCut (AR-100..AR-105).
    %   Maps source angles to canonical theta in [0,360) GEOMETRICALLY (AR-102),
    %   sorts, resolves duplicates deterministically (§6/§11), detects sampling
    %   type (§5/§7), and records provenance (§7). Deterministic (AR-100).
    methods (Static)
        function out = canonicalize(theta, gain, conv, meta, policy)
            %CANONICALIZE Returns struct(out.cut, out.validation).
            if nargin < 5 || isempty(policy); policy = rfscreen.config.PatternImportPolicy(); end
            if nargin < 4 || isempty(meta); meta = struct(); end
            VS = rfscreen.patterndata.ValidationStatus;
            PC = rfscreen.patterndata.PatternCanonicalizer;

            % ---- structural validation ----
            vraw = rfscreen.patterndata.PatternValidator.validateRaw(theta, gain, conv);
            if strcmp(vraw.status, VS.INVALID)
                out = struct('cut', [], 'validation', vraw);
                return;
            end
            theta = theta(:).'; gain = gain(:).';
            issues = {}; warnings = vraw.warnings;

            % ---- geometric mapping to canonical theta ----
            canonConv = rfscreen.patterndata.SourceCoordinateConvention.canonicalFor(conv.plane);
            n = numel(theta);
            thetaC = zeros(1, n);
            for i = 1:n
                d = conv.directionForTheta(theta(i));
                [thetaC(i), off] = PC.canonicalThetaFor(conv.plane, d);
                if abs(off) > 1e-6
                    issues{end+1} = sprintf('sample %d leaves the %s plane (off=%.3g)', i, conv.plane, off); %#ok<AGROW>
                end
            end
            if ~isempty(issues)
                out = struct('cut', [], 'validation', ...
                    rfscreen.patterndata.CutValidationResult(VS.INVALID, issues, warnings));
                return;
            end

            % original step (raw) for provenance
            rawSorted = sort(unique(theta));
            if numel(rawSorted) >= 2; originalStep = median(diff(rawSorted)); else; originalStep = NaN; end

            % ---- sort + duplicate resolution ----
            [thetaC, order] = sort(thetaC);
            gainS = gain(order);
            srcS  = theta(order);
            [thC, gC, dupInfo, dupStatus, dupWarn, dupIssue] = ...
                PC.resolveDuplicates(thetaC, gainS, srcS, policy);
            warnings = [warnings, dupWarn];
            if strcmp(dupStatus, VS.INVALID)
                out = struct('cut', [], 'validation', ...
                    rfscreen.patterndata.CutValidationResult(VS.INVALID, dupIssue, warnings));
                return;
            end

            % ---- sampling detection ----
            [sampType, nominalStep, sampWarn] = PC.detectSampling(thC, policy);
            warnings = [warnings, sampWarn];

            % ---- provenance ----
            prov = struct();
            prov.sourceFile = PC.optChar(meta, 'sourceFile', '');
            prov.sourceType = PC.optChar(meta, 'sourceType', '');
            prov.patternId  = PC.optChar(meta, 'patternId', '');
            prov.antennaId  = PC.optChar(meta, 'antennaId', '');
            prov.plane = conv.plane;
            prov.frequency_Hz = PC.optNum(meta, 'frequency_Hz', NaN);
            prov.originalAngleRange = conv.angleRange;
            prov.originalStep_deg = originalStep;
            prov.canonicalizationApplied = true;
            prov.duplicateHandlingApplied = ~isempty(dupInfo);
            prov.duplicates = dupInfo;
            prov.resamplingApplied = false;
            prov.gainNormalizationApplied = false;
            prov.coordinateTransformApplied = 'source->canonical';

            % ---- final status ----
            status = rfscreen.patterndata.ValidationStatus.worst(vraw.status, dupStatus);
            if ~isempty(sampWarn)
                status = rfscreen.patterndata.ValidationStatus.worst(status, VS.VALID_WITH_WARNINGS);
            end

            s = struct();
            s.patternId = PC.optChar(meta, 'patternId', 'SYNTHETIC_TEST_pattern');
            s.antennaId = PC.optChar(meta, 'antennaId', '');
            s.plane = conv.plane;
            s.theta_deg = thC;
            s.gain_dBi = gC;
            s.samplingType = sampType;
            s.nominalStep_deg = nominalStep;
            s.frequency_Hz = PC.optNum(meta, 'frequency_Hz', NaN);
            s.fidelity = PC.optChar(meta, 'fidelity', rfscreen.patterndata.PatternFidelity.SYNTHETIC_TEST);
            s.sourceConvention = conv;
            s.canonicalConvention = canonConv;
            s.provenance = prov;
            s.validationStatus = status;
            s.warnings = warnings;

            cut = rfscreen.patterndata.CanonicalPatternCut(s);
            out = struct('cut', cut, ...
                'validation', rfscreen.patterndata.CutValidationResult(status, {}, warnings));
        end

        function [sampType, nominalStep, warns] = classifySampling(theta, policy)
            %CLASSIFYSAMPLING Public sampling classifier (UNIFORM/NON_UNIFORM/INVALID).
            if nargin < 2 || isempty(policy); policy = rfscreen.config.PatternImportPolicy(); end
            ST = rfscreen.patterndata.SamplingType;
            warns = {};
            theta = theta(:).';
            if numel(theta) < 2
                sampType = ST.INVALID; nominalStep = NaN;
                warns{end+1} = 'fewer than 2 canonical samples: sampling undefined';
                return;
            end
            d = diff(theta);
            med = median(d);
            if all(abs(d - med) <= policy.stepTolerance_deg)
                sampType = ST.UNIFORM; nominalStep = med;
            else
                sampType = ST.NON_UNIFORM; nominalStep = NaN;
                warns{end+1} = 'non-uniform angular sampling detected';
            end
        end

        function [thetaC, off] = canonicalThetaFor(plane, d)
            %CANONICALTHETAFOR Canonical theta [0,360) + off-plane component for a direction.
            switch plane
                case 'XZ'   % in-plane sin=d_x, cos=d_z ; off = d_y
                    thetaC = mod(atan2d(d(1), d(3)), 360);
                    off = d(2);
                case 'YZ'   % in-plane sin=d_y, cos=d_z ; off = d_x
                    thetaC = mod(atan2d(d(2), d(3)), 360);
                    off = d(1);
                otherwise
                    error('rfscreen:patterndata:badPlane', 'unknown plane ''%s''.', plane);
            end
        end
    end

    methods (Static, Access = private)
        function [thC, gC, dupInfo, status, warns, issues] = resolveDuplicates(thetaC, gainS, srcS, policy)
            VS = rfscreen.patterndata.ValidationStatus;
            tol = policy.angleTolerance_deg;
            n = numel(thetaC);
            % cluster consecutive within tol
            groups = {}; gi = 1; groups{1} = 1;
            for i = 2:n
                if thetaC(i) - thetaC(groups{gi}(end)) <= tol
                    groups{gi}(end+1) = i;
                else
                    gi = gi + 1; groups{gi} = i;
                end
            end
            % seam merge: first and last groups equivalent across 0/360
            if numel(groups) >= 2
                firstAng = thetaC(groups{1}(1));
                lastAng  = thetaC(groups{end}(end));
                if (firstAng + 360) - lastAng <= tol
                    groups{1} = [groups{end}, groups{1}];
                    groups(end) = [];
                end
            end

            thC = zeros(1, numel(groups));
            gC  = zeros(1, numel(groups));
            dupInfo = struct('sourceAngles', {}, 'sourceGains', {}, 'canonicalAngle', {}, ...
                             'difference_dB', {}, 'resolution', {});
            warns = {}; issues = {}; status = VS.VALID;
            for k = 1:numel(groups)
                idx = groups{k};
                gains = gainS(idx);
                thisAng = thetaC(idx(1));
                if thisAng > 300 && any(thetaC(idx) < 60); thisAng = 0; end  % seam group -> 0
                if numel(idx) == 1
                    thC(k) = thetaC(idx); gC(k) = gains;
                    continue;
                end
                spread = max(gains) - min(gains);
                di = numel(dupInfo) + 1;
                dupInfo(di).sourceAngles = srcS(idx);
                dupInfo(di).sourceGains = gains;
                dupInfo(di).canonicalAngle = thisAng;
                dupInfo(di).difference_dB = spread;
                if spread <= policy.gainMergeTolerance_dB
                    gC(k) = mean(gains); thC(k) = thisAng;
                    dupInfo(di).resolution = 'merged_mean_within_tolerance';
                else
                    if strcmp(policy.duplicateConflictPolicy, 'error')
                        issues{end+1} = sprintf( ...
                            'INVALID_DUPLICATE_CONFLICT at canonical %.4f deg: gains differ by %.3f dB', ...
                            thisAng, spread); %#ok<AGROW>
                        dupInfo(di).resolution = 'rejected_conflict';
                        status = VS.INVALID;
                        gC(k) = mean(gains); thC(k) = thisAng;   % placeholder (cut discarded)
                    else
                        warns{end+1} = sprintf( ...
                            'conflicting duplicate at canonical %.4f deg: gains [%s] differ by %.3f dB; merged by mean', ...
                            thisAng, rfscreen.patterndata.PatternCanonicalizer.numlist(gains), spread); %#ok<AGROW>
                        dupInfo(di).resolution = 'merged_mean_with_warning';
                        gC(k) = mean(gains); thC(k) = thisAng;
                        status = rfscreen.patterndata.ValidationStatus.worst(status, VS.VALID_WITH_WARNINGS);
                    end
                end
            end
            % ensure strictly increasing after seam handling
            [thC, ord] = sort(thC); gC = gC(ord);
        end

        function [sampType, nominalStep, warns] = detectSampling(theta, policy)
            [sampType, nominalStep, warns] = ...
                rfscreen.patterndata.PatternCanonicalizer.classifySampling(theta, policy);
        end

        function s = numlist(v)
            parts = arrayfun(@(x) sprintf('%.3f', x), v, 'UniformOutput', false);
            s = strjoin(parts, ', ');
        end
        function v = optChar(s, name, default)
            if isfield(s, name) && ~isempty(s.(name)) && ischar(s.(name)); v = s.(name); else; v = default; end
        end
        function v = optNum(s, name, default)
            if isfield(s, name) && ~isempty(s.(name)); v = double(s.(name)); else; v = default; end
        end
    end
end
