function test_ray_intersection(h)
%TEST_RAY_INTERSECTION Deterministic ray/primitive intersection (VR-400).
%   Tolerance policy: box/panel accept boundary hits within ~1e-12 local units.
    h.setGroup('ray');
    box = rfscreen.geometry.BoxGeometry([0.5;0.5;0.5]);      % 1 m cube (local, centered)
    st = mkStruct('BUS', box, eye(3), [10;0;0]);

    % ray hits box (front face at x=9.5)
    [hit, t] = st.rayIntersectBody([0;0;0], [1;0;0]);
    h.isTrue('ray hits box', hit);
    h.eqTol('hit distance = 9.5', t, 9.5, 1e-9);

    % ray misses box
    [hit2, ~] = st.rayIntersectBody([0;0;0], [0;1;0]);
    h.isFalse('ray +Y misses box', hit2);

    % tangent / boundary: graze the +Y face edge (y = 0.5 exactly)
    [hitB, ~] = st.rayIntersectBody([0;0.5;0], [1;0;0]);
    h.isTrue('boundary graze (y=0.5) hits', hitB);
    [hitM, ~] = st.rayIntersectBody([0;0.5001;0], [1;0;0]);
    h.isFalse('just outside (y=0.5001) misses', hitM);

    % origin inside box -> hits, returns the EXIT distance (per ICD)
    [hitIn, tIn] = st.rayIntersectBody([10;0;0], [1;0;0]);
    h.isTrue('origin inside box hits', hitIn);
    h.eqTol('inside -> exit distance 0.5', tIn, 0.5, 1e-9);

    % origin exactly on the near surface -> t = 0 (ray starts on surface)
    [hitS, tS] = st.rayIntersectBody([9.5;0;0], [1;0;0]);
    h.isTrue('origin on surface hits', hitS);
    h.eqTol('on-surface -> t=0', tS, 0, 1e-9);

    % box entirely behind origin -> miss (ray points away)
    [hitBack, ~] = st.rayIntersectBody([0;0;0], [-1;0;0]);
    h.isFalse('box behind origin misses', hitBack);

    % ---- panel (rectangle in local XY, normal +Z) ----
    panel = rfscreen.geometry.PanelGeometry(4, 4);           % 4x4 m -> half-extent 2
    sp = mkStruct('PANEL', panel, eye(3), [0;0;0]);
    [hp, tp] = sp.rayIntersectBody([0;0;5], [0;0;-1]);
    h.isTrue('ray hits panel center', hp);
    h.eqTol('panel hit distance = 5', tp, 5, 1e-9);
    [hp2, ~] = sp.rayIntersectBody([10;0;5], [0;0;-1]);      % out of the 2 m half-extent
    h.isFalse('ray misses panel (out of bounds)', hp2);
    [hp3, ~] = sp.rayIntersectBody([1;0;5], [0;0;-1]);       % within bounds
    h.isTrue('ray hits panel within bounds', hp3);
    [hp4, ~] = sp.rayIntersectBody([0;0;5], [1;0;0]);        % parallel to plane
    h.isFalse('ray parallel to panel misses', hp4);

    % rotated box: rotate 90 deg about Z, ray still hits (rotation-invariant volume)
    stR = mkStruct('BUS', rfscreen.geometry.BoxGeometry([0.5;1;0.5]), ...
        rfscreen.geometry.Rotation.aboutZ(90), [10;0;0]);
    [hitR, ~] = stR.rayIntersectBody([0;0;0], [1;0;0]);
    h.isTrue('rotated box hit', hitR);
end

function st = mkStruct(type, geom, R_BS, origin)
    st = rfscreen.geometry.SpacecraftStructure('S1', 'SYNTHETIC_TEST_struct', type, ...
        geom, R_BS, origin, struct('provenance', 'SYNTHETIC_TEST'));
end
