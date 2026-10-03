function test_convex_polygon(h)
%TEST_CONVEX_POLYGON Exact convex planar polygon primitive (VR-430).
%   Deterministic; synthetic shapes only.
    h.setGroup('convex_polygon');
    G = @rfscreen.geometry.ConvexPolygonGeometry;

    % ---- unit square (CCW): metrics + ray hits ----
    sq = G([0 1 1 0; 0 0 1 1]);
    h.isTrue('square CCW', sq.isCCW);
    h.eqTol('square area', sq.area(), 1, 1e-15);
    h.eqTol('square perimeter', sq.perimeter(), 4, 1e-15);
    h.eqTol('square centroid', sq.centroid(), [0.5; 0.5], 1e-15);
    h.eqTol('square vertices kept exactly', sq.verticesLocal(), [0 1 1 0; 0 0 1 1; 0 0 0 0], 0);
    st = rfscreen.geometry.SpacecraftStructure('SQ', 'SYNTHETIC_TEST', 'PANEL', sq, eye(3), [0;0;0], ...
        struct('provenance', 'SYNTHETIC_TEST'));
    [hit, t] = st.rayIntersectBody([0.5;0.5;3], [0;0;-1]);
    h.isTrue('ray hits square interior', hit);
    h.eqTol('ray hit distance', t, 3, 1e-12);
    [hitE, ~] = st.rayIntersectBody([1;0.5;3], [0;0;-1]);
    h.isTrue('ray on edge hits (boundary inclusive)', hitE);
    [hitO, ~] = st.rayIntersectBody([1.0001;0.5;3], [0;0;-1]);
    h.isFalse('ray just outside misses', hitO);
    [hitP, ~] = st.rayIntersectBody([0.5;0.5;3], [1;0;0]);
    h.isFalse('ray parallel to plane misses', hitP);
    [hitB, ~] = st.rayIntersectBody([0.5;0.5;3], [0;0;1]);
    h.isFalse('plane behind ray origin misses', hitB);

    % ---- clockwise order is accepted, metrics identical ----
    sqCW = G([0 0 1 1; 0 1 1 0]);
    h.isFalse('CW detected', sqCW.isCCW);
    h.eqTol('CW area positive', sqCW.area(), 1, 1e-15);
    h.isTrue('CW contains interior', sqCW.containsPoint([0.5; 0.5]));
    h.isFalse('CW excludes exterior', sqCW.containsPoint([1.5; 0.5]));

    % ---- irregular triangle: point just outside the hypotenuse ----
    tri = G([0 2 0; 0 0 1]);
    h.isTrue('triangle contains (0.5,0.5)', tri.containsPoint([0.5; 0.5]));
    h.isFalse('triangle excludes (1.2,0.5)', tri.containsPoint([1.2; 0.5]));
    h.eqTol('triangle bounding radius', tri.boundingRadius(), 2, 1e-15);

    % ---- invalid polygons rejected ----
    id = 'rfscreen:geometry:badPolygon';
    h.throws('fewer than 3 vertices', @() G([0 1; 0 0]), id);
    h.throws('non-finite vertex', @() G([0 1 NaN; 0 0 1]), id);
    h.throws('3xN rejected', @() G(zeros(3, 4)), id);
    h.throws('duplicate vertex', @() G([0 1 1 1 0; 0 0 1 1 1]), id);
    h.throws('collinear vertex', @() G([0 1 2 2 0; 0 0 0 1 1]), id);
    h.throws('non-convex (reflex)', @() G([0 2 1 2 0; 0 0 1 2 2]), id);
    star = [cosd(90 + (0:4)*144); sind(90 + (0:4)*144)];      % pentagram: same-sign turns, 720 deg
    h.throws('self-intersecting pentagram', @() G(star), id);
end
