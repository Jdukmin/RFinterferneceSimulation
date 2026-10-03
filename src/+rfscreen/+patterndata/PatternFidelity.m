classdef PatternFidelity
    %PATTERNFIDELITY Explicit pattern fidelity/source category (DR-106, §22).
    %   Stored explicitly; NEVER inferred from filename. A 3D pattern assembled
    %   from 2D cuts is APPROX_FROM_CUTS, never MEASURED_3D/SIMULATED_3D (§21).
    properties (Constant)
        MEASURED_2D_CUT  = 'MEASURED_2D_CUT'
        SIMULATED_2D_CUT = 'SIMULATED_2D_CUT'
        MEASURED_3D      = 'MEASURED_3D'
        SIMULATED_3D     = 'SIMULATED_3D'
        APPROX_FROM_CUTS = 'APPROX_FROM_CUTS'
        SYNTHETIC_TEST   = 'SYNTHETIC_TEST'
        % 2D cut derived from a published datasheet pattern ENVELOPE (digitized /
        % interpolated / mirrored): neither raw measured nor simulated (Phase 7).
        DATASHEET_ENVELOPE_2D_CUT = 'DATASHEET_ENVELOPE_2D_CUT'
    end
    methods (Static)
        function v = values()
            v = {'MEASURED_2D_CUT', 'SIMULATED_2D_CUT', 'MEASURED_3D', ...
                 'SIMULATED_3D', 'APPROX_FROM_CUTS', 'SYNTHETIC_TEST', ...
                 'DATASHEET_ENVELOPE_2D_CUT'};
        end
        function tf = isValid(x)
            tf = ischar(x) && any(strcmp(x, rfscreen.patterndata.PatternFidelity.values()));
        end
        function tf = is2DCut(x)
            tf = any(strcmp(x, {'MEASURED_2D_CUT', 'SIMULATED_2D_CUT', 'DATASHEET_ENVELOPE_2D_CUT'}));
        end
    end
end
