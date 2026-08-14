classdef AntennaToStructureFOV
    %ANTENNATOSTRUCTUREFOV Antenna-to-structure field-of-view (ACTIVATED, Phase 5).
    %   Determines whether a structure occupies directions visible from an antenna,
    %   with an angular footprint (vertex-sampled) and optional pattern/lobe relation.
    %   GEOMETRY EVIDENCE ONLY: it never returns an EM gain/loss value (ICD 6, 9).
    methods (Static)
        function tf = isSupported()
            tf = true;   % activated in Phase 5
        end

        function res = analyze(antennaId, antennaPos_B, R_BA, structure, opts)
            %ANALYZE FOV of one structure from one antenna -> AntennaStructureFOVResult.
            if nargin < 5 || isempty(opts); opts = struct(); end
            rfscreen.geometry.Rotation.mustBeRotationMatrix(R_BA, 'R_BA');
            antennaPos_B = rfscreen.util.Validate.vector3(antennaPos_B, 'antennaPos_B');
            DC = rfscreen.geometry.DirectionCalculator;

            samples = [structure.centroidBody(), structure.verticesBody()];  % 3 x (1+N)
            nS = size(samples, 2);
            az = zeros(1, nS); el = zeros(1, nS); dist = zeros(1, nS); off = zeros(1, nS);
            unitA = zeros(3, nS);
            warnings = {};
            for k = 1:nS
                dvec = samples(:, k) - antennaPos_B;
                dist(k) = norm(dvec);
                if dist(k) <= eps
                    az(k) = NaN; el(k) = NaN; off(k) = NaN; unitA(:, k) = NaN; continue;
                end
                u_B = dvec / dist(k);
                u_A = R_BA.' * u_B;
                unitA(:, k) = u_A;
                [az(k), el(k)] = DC.directionToAzEl(u_A);
                off(k) = DC.offBoresightAngle(az(k), el(k));
            end

            s = struct();
            s.antennaId = antennaId;
            s.structureId = structure.id;
            s.structureType = structure.structureType;
            s.closestDistance_m = min(dist);
            s.centerAz_deg = az(1); s.centerEl_deg = el(1); s.centerOffBoresight_deg = off(1);
            valid = ~isnan(az);
            % Azimuth is CIRCULAR: compute the extent relative to the centroid azimuth
            % and wrap to [-180,180] so a footprint straddling the +-180 seam stays a
            % small arc instead of exploding to ~360 deg via naive min/max (AUD-01).
            cAz = s.centerAz_deg;
            if isnan(cAz)
                s.minAz_deg = NaN; s.maxAz_deg = NaN; s.azimuthSpan_deg = NaN;
            else
                azRel = mod(az(valid) - cAz + 180, 360) - 180;   % relative, wrapped
                azRelMin = min(azRel); azRelMax = max(azRel);
                wrap180 = @(x) mod(x + 180, 360) - 180;
                s.minAz_deg = wrap180(cAz + azRelMin);
                s.maxAz_deg = wrap180(cAz + azRelMax);
                s.azimuthSpan_deg = azRelMax - azRelMin;          % always the small arc
            end
            s.minEl_deg = min(el(valid)); s.maxEl_deg = max(el(valid));
            % max angular radius: separation between centroid direction and each sample
            uc = unitA(:, 1); maxrad = 0;
            for k = 2:nS
                if any(isnan(unitA(:, k))); continue; end
                c = max(min(dot(uc, unitA(:, k)), 1), -1);
                maxrad = max(maxrad, acosd(c));
            end
            s.maxAngularRadius_deg = maxrad;
            s.geometryFidelity = rfscreen.geometry.GeometryFidelity.VERTEX_SAMPLED;

            % center ray intersects the structure?
            if dist(1) > eps
                s.centerRayHits = structure.rayIntersectBody(antennaPos_B, samples(:, 1) - antennaPos_B);
            else
                s.centerRayHits = false;
            end

            % pattern/lobe relation (optional)
            pattern = rfscreen.geometry.AntennaToStructureFOV.opt(opts, 'pattern', []);
            freq = rfscreen.geometry.AntennaToStructureFOV.opt(opts, 'frequency_Hz', NaN);
            lobePolicy = rfscreen.geometry.AntennaToStructureFOV.opt(opts, 'lobePolicy', []);
            if ~isempty(pattern) && isfinite(freq)
                lobes = {};
                for k = 1:nS
                    if isnan(az(k)); continue; end
                    lc = rfscreen.interference.LobeClassifier.classify(pattern, freq, az(k), el(k), lobePolicy);
                    if ~any(strcmp(lobes, lc)); lobes{end+1} = lc; end %#ok<AGROW>
                end
                s.occupiedLobes = lobes;
                s.centerLobe = rfscreen.interference.LobeClassifier.classify(pattern, freq, az(1), el(1), lobePolicy);
                s.validity = 'FOV_WITH_PATTERN';
            else
                s.occupiedLobes = {};
                s.centerLobe = '';
                s.validity = 'GEOMETRY_ONLY';
                warnings{end+1} = 'no pattern supplied: FOV lobe classification unavailable (geometry evidence only)';
            end
            s.warnings = warnings;
            res = rfscreen.results.AntennaStructureFOVResult(s);
        end
    end
    methods (Static, Access = private)
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
    end
end
