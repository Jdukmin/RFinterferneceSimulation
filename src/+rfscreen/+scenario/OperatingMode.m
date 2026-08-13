classdef OperatingMode
    %OPERATINGMODE An operating mode selecting active TX/RX sets (SR-100).
    %   Phase 1 provides the mechanism only; no fixed mission modes are shipped.
    properties (SetAccess = private)
        id
        name
        activeTxIds
        activeRxIds
    end
    methods
        function obj = OperatingMode(id, name, activeTxIds, activeRxIds)
            V = rfscreen.util.Validate;
            obj.id = V.id(id, 'OperatingMode.id');
            obj.name = V.id(name, 'OperatingMode.name');
            if nargin < 3 || isempty(activeTxIds); activeTxIds = {}; end
            if nargin < 4 || isempty(activeRxIds); activeRxIds = {}; end
            obj.activeTxIds = activeTxIds;
            obj.activeRxIds = activeRxIds;
        end
    end
end
