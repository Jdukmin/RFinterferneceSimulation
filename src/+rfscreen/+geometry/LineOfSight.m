classdef LineOfSight
    %LINEOFSIGHT Antenna-to-antenna segment blockage by structures (ICD 8).
    %   GEOMETRY EVIDENCE ONLY. A BLOCKED status never implies an RF attenuation
    %   value (Task 44). Endpoints are excluded so mount points do not self-block.
    methods (Static)
        function res = segment(antennaAId, antennaBId, pA_B, pB_B, structures, opts)
            %SEGMENT Blockage of the direct segment A->B by active structures.
            if nargin < 6 || isempty(opts); opts = struct(); end
            tolEps = rfscreen.geometry.LineOfSight.opt(opts, 'tolEps_m', 1e-6);
            V = rfscreen.util.Validate;
            pA = V.vector3(pA_B, 'pA_B'); pB = V.vector3(pB_B, 'pB_B');

            LS = rfscreen.geometry.LineOfSightStatus;
            seg = pB - pA; L = norm(seg);
            s = struct('antennaAId', antennaAId, 'antennaBId', antennaBId, ...
                'segmentLength_m', L, 'blockingStructureIds', {{}}, 'intersectionCount', 0, ...
                'geometryFidelity', rfscreen.geometry.GeometryFidelity.CENTER_POINT, ...
                'validity', 'GEOMETRY_ONLY', 'warnings', {{}});
            if L <= tolEps
                s.status = LS.UNKNOWN;
                s.warnings{end+1} = 'zero-length segment (co-located antennas): LOS undefined';
                res = rfscreen.results.LineOfSightResult(s);
                return;
            end
            d = seg / L;
            ids = {}; count = 0;
            for i = 1:numel(structures)
                st = structures{i};
                if ~st.active; continue; end
                [hit, tHit] = st.rayIntersectBody(pA, d);
                if hit && tHit > tolEps && tHit < (L - tolEps)
                    ids{end+1} = st.id; count = count + 1; %#ok<AGROW>
                end
            end
            s.blockingStructureIds = ids;
            s.intersectionCount = count;
            if count > 0; s.status = LS.BLOCKED; else; s.status = LS.CLEAR; end
            res = rfscreen.results.LineOfSightResult(s);
        end
    end
    methods (Static, Access = private)
        function v = opt(s, name, default)
            if isstruct(s) && isfield(s, name) && ~isempty(s.(name)); v = s.(name); else; v = default; end
        end
    end
end
