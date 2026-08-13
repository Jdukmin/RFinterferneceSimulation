classdef AntennaToStructureFOV
    %ANTENNATOSTRUCTUREFOV Reserved interface for the antenna->structure FOV domain.
    %   DISTINCT domain from AntennaToAntennaFOV (reference.md rule 5, SR-042).
    %
    %   This class fixes the INTERFACE only. Phase 1 does NOT implement structure
    %   blockage / scattering; spacecraft structure geometry (STL/mesh, primitive
    %   volumes for bus, panel, solar array, payload, reflector, boom, other
    %   antenna) is a future extension point (reference.md R7).
    %
    %   No fake physics: the query method raises NotImplementedPhase1 rather than
    %   returning an invented result (SR-120).
    methods (Static)
        function tf = isSupported()
            %ISSUPPORTED Whether structure-FOV computation is available (false in Phase 1).
            tf = false;
        end

        function result = isStructureInFieldOfView(varargin) %#ok<STOUT,INUSD>
            %ISSTRUCTUREINFIELDOFVIEW Reserved. Not implemented in Phase 1.
            error('rfscreen:geometry:NotImplementedPhase1', ...
                ['AntennaToStructureFOV is a reserved interface. Structure blockage/' ...
                 'scattering is out of Phase-1 scope; integrate STL/primitive geometry ' ...
                 'in a later phase.']);
        end
    end
end
