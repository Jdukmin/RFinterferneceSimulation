function test_los_blockage(h)
%TEST_LOS_BLOCKAGE Antenna-to-antenna segment blockage (VR-401).
    h.setGroup('los');
    SEG = @(pa, pb, sts) rfscreen.geometry.LineOfSight.segment('AT', 'AR', pa, pb, sts);

    % panel across the path (normal +X, at x=5)
    Rx = rfscreen.geometry.Rotation.aboutY(90);   % panel normal +Z -> +X
    blocker = mkStruct('PANEL', rfscreen.geometry.PanelGeometry(4,4), Rx, [5;0;0], true);

    los = SEG([0;0;0], [10;0;0], {blocker});
    h.eqStr('TX->RX blocked', los.status, 'BLOCKED');
    h.ok('one blocker id', numel(los.blockingStructureIds) == 1);
    h.eqStr('blocker id', los.blockingStructureIds{1}, 'S_PANEL');
    h.eqTol('segment length', los.segmentLength_m, 10, 1e-9);

    % clear path (RX off to the side, panel not intersected)
    losC = SEG([0;0;0], [0;10;0], {blocker});
    h.eqStr('clear segment', losC.status, 'CLEAR');
    h.ok('no blockers', isempty(losC.blockingStructureIds));

    % structure beyond RX (front face exactly at RX endpoint) -> not blocking
    beyond = mkStruct('BUS', rfscreen.geometry.BoxGeometry([0.5;0.5;0.5]), eye(3), [10.5;0;0], true);
    losB = SEG([0;0;0], [10;0;0], {beyond});
    h.eqStr('structure at/behind RX endpoint -> clear', losB.status, 'CLEAR');

    % structure behind TX -> not blocking
    behind = mkStruct('BUS', rfscreen.geometry.BoxGeometry([0.5;0.5;0.5]), eye(3), [-1;0;0], true);
    losBk = SEG([0;0;0], [10;0;0], {behind});
    h.eqStr('structure behind TX -> clear', losBk.status, 'CLEAR');

    % structure whose near face touches the TX mount point -> excluded (t=0, no self-block)
    atTx = mkStruct('BUS', rfscreen.geometry.BoxGeometry([0.5;0.5;0.5]), eye(3), [0.5;0;0], true);
    losSelf = SEG([0;0;0], [10;0;0], {atTx});
    h.eqStr('structure at TX mount -> clear (self excluded)', losSelf.status, 'CLEAR');

    % multiple structures: only the mid-path one blocks
    losM = SEG([0;0;0], [10;0;0], {behind, blocker, beyond});
    h.eqStr('multiple -> blocked', losM.status, 'BLOCKED');
    h.ok('exactly one blocker counted', losM.intersectionCount == 1);

    % inactive structure ignored
    inactive = mkStruct('PANEL', rfscreen.geometry.PanelGeometry(4,4), Rx, [5;0;0], false);
    losI = SEG([0;0;0], [10;0;0], {inactive});
    h.eqStr('inactive structure ignored', losI.status, 'CLEAR');

    % zero-length segment -> UNKNOWN
    losZ = SEG([1;1;1], [1;1;1], {blocker});
    h.eqStr('zero-length -> UNKNOWN', losZ.status, 'UNKNOWN');
end

function st = mkStruct(type, geom, R_BS, origin, active)
    st = rfscreen.geometry.SpacecraftStructure(['S_' type], 'SYNTHETIC_TEST_struct', type, ...
        geom, R_BS, origin, struct('provenance', 'SYNTHETIC_TEST', 'active', active));
end
