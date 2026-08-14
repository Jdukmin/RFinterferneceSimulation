# ICD — Spacecraft Structure Geometry & Antenna-to-Structure FOV (Phase 5)

Normative interface for deterministic spacecraft structure geometry, ray/segment intersection,
antenna-to-structure field-of-view, and antenna-to-antenna line-of-sight blockage. Requirements:
SR-400…SR-414, AR-400…AR-415, DR-400…DR-410.

Builds on Phase-1..4 **without changing** their contracts. **Central rule (Task §3, §37, Final
Rule): geometry provides installation-risk evidence; it never manufactures electromagnetic
behavior.** Structure intersection ≠ gain loss; blocked LOS ≠ infinite attenuation.

Package: `src/+rfscreen/+geometry/` (structures, primitives, FOV/LOS analyzers). No full-wave
solver, no HFSS/CST dependency, no pattern-file parsing.

---

## 1. Coordinate frames (canonical — Task §10)

| Frame | Definition |
|-------|------------|
| **Spacecraft Body B** | existing Phase-1 body frame (`coordinate_system.md`) |
| **Structure Local S** | frame in which a structure's primitive geometry is defined |
| **Antenna Local A** | existing (boresight `+X_A`, az about `+Z_A`) |

**Structure→body transform (fixed):** `v_B = R_BS · v_S + origin_B`, where `R_BS` is a proper
3×3 rotation (structure→body) and `origin_B` the structure origin in B. Inverse (body→local):
`v_S = R_BS' · (v_B − origin_B)`. `R_BS` validated by `geometry.Rotation.mustBeRotationMatrix`.
No conflicting rotation convention is introduced.

## 2. `geometry.StructureGeometry` (abstract primitive)

Primitive geometry defined in the **structure local frame**. Methods:

| Method | Returns | Meaning |
|--------|---------|---------|
| `verticesLocal()` | 3×N | corner/sample vertices in S |
| `rayIntersectLocal(o_S, d_S)` | `[hit, tHit]` | nearest intersection distance `tHit ≥ 0` along unit `d_S`; `hit=false` if none |
| `boundingRadius()` | scalar | radius of a bounding sphere about the local origin |
| `describe()` | char | short type description |

Concrete (deterministic, math-based; no CAD kernel — Task §8, §9):
- **`BoxGeometry(halfSizes_m)`** — axis-aligned box `[-hx,hx]×[-hy,hy]×[-hz,hz]` in S; slab-method
  ray intersection; 8 vertices.
- **`PanelGeometry(width_m, height_m)`** — flat rectangle in the S `XY` plane (`z=0`), normal
  `+Z_S`, spanning `[-w/2,w/2]×[-h/2,h/2]`; ray-plane + in-bounds test; 4 vertices.

Ray tolerance: intersections with `tHit ≤ tolEps` (default `1e-9 · max(1, |o|)`) or grazing hits
within tolerance are reported per the documented policy (§5). A `MESH`/`EXTERNAL_GEOMETRY` adapter
is a reserved extension (Task §9) — not implemented in Phase 5.

## 3. `geometry.SpacecraftStructure` (Task §7)

| Field | Type | R/O | Meaning / Missing |
|-------|------|-----|-------------------|
| `id` | char | R | unique structure id |
| `name` | char | R | display name |
| `structureType` | char (`StructureType`) | R | BUS/PANEL/SOLAR_ARRAY/PAYLOAD/BOOM/REFLECTOR/ANTENNA_BODY/OTHER |
| `geometry` | `StructureGeometry` | R | primitive in S |
| `R_BS` | 3×3 | R | structure→body rotation |
| `origin_m` | 3×1 | R | structure origin in B |
| `configId` | char | O | configuration this geometry belongs to; `''` = always active |
| `deploymentState` | char (`DeploymentState`) | O | STOWED/DEPLOYED/CUSTOM; default `DEPLOYED` |
| `active` | logical | O | active in the current configuration; default `true` |
| `provenance` | char (`GeometryProvenance`) | R | USER_DEFINED/CAD_DERIVED/MEASURED/MISSION_CONFIG/SYNTHETIC_TEST |

Methods: `verticesBody()`, `centroidBody()`, `rayIntersectBody(o_B, d_B)` → `[hit, tHit]`
(transforms the ray into S, delegates, returns body-frame distance since rotations preserve norm).
The analysis does **not** depend strongly on `structureType` values (Task §7); type is metadata.

## 4. Geometry fidelity — `geometry.GeometryFidelity` (Task §14)

`CENTER_POINT`, `BOUNDING_VOLUME`, `VERTEX_SAMPLED`, `SURFACE_SAMPLED`, `MESH_INTERSECTION`.
Phase 5 implements exact-primitive **ray intersection** plus **`VERTEX_SAMPLED`** angular
footprints (and `CENTER_POINT` where only the centroid direction is used). Levels are reported
explicitly and never treated as equivalent.

## 5. Ray / segment intersection (Task §15, §34)

- **Ray:** `structure.rayIntersectBody(o_B, unit_d_B)` → `[hit, tHit]`, `tHit` in meters.
- **Segment (antenna→antenna, Task §16):** blocked iff some active structure is hit with
  `tolEps < tHit < segLength − tolEps` (endpoints excluded so the mount points themselves do not
  self-block). `tolEps` documented (default `1e-6 m`). This is **pure geometry**; it never yields
  an attenuation value.
- Boundary/tangent cases resolve deterministically by the `≤ tolEps` rule and are covered by tests.

## 6. `geometry.AntennaToStructureFOV` (activated — Task §11, §12, §13)

`analyze(antennaId, antennaPos_B, R_BA, structure, opts)` → `results.AntennaStructureFOVResult`.
Steps:
1. Sample the structure: centroid + `verticesBody()` (fidelity `VERTEX_SAMPLED`).
2. For each sample `p_B`: `dir_B = (p_B − antennaPos_B)/‖·‖`; `dir_A = R_BA'·dir_B`;
   `[az,el] = DirectionCalculator.directionToAzEl(dir_A)`; off-boresight angle.
3. `centerAz/El` from the centroid direction; `closestDistance_m = min sample distance`;
   angular footprint = `min/max az`, `min/max el`, and `maxAngularRadius_deg` (max angular
   separation from the centroid direction). This captures a structure whose **center** is outside a
   region while an **edge** enters it (Task §13, §35) — center-point-only false negatives are
   avoided.
4. `centerRayHits` = `structure.rayIntersectBody(antennaPos, centerDir)` hit flag.
5. **Lobe/pattern relation (Task §12, §19, §20):** if `opts.pattern` and `opts.frequency_Hz`
   given, classify each sample direction with the existing `interference.LobeClassifier` +
   `config.LobeClassificationPolicy`; `occupiedLobes` = the **set** of regions spanned (a large
   structure may occupy MAIN+SIDE), `centerLobe` = the centroid's region. If no pattern,
   `occupiedLobes = {}` and validity records pattern-unavailable — geometry evidence is still valid
   (Task §20). No beamwidth is invented.

Fixed cone (`main = ±10°`) is **not** hard-coded as universal physics; the pattern is the primary
evidence, the lobe policy is configurable (Task §12).

## 7. `results.AntennaStructureFOVResult` (Task §18)

`antennaId`, `structureId`, `structureType`, `closestDistance_m`, `centerAz_deg`, `centerEl_deg`,
`centerOffBoresight_deg`, `minAz_deg`, `maxAz_deg`, `minEl_deg`, `maxEl_deg`,
`maxAngularRadius_deg`, `occupiedLobes` (cellstr), `centerLobe`, `centerRayHits` (logical),
`geometryFidelity`, `validity` (`GEOMETRY_ONLY` or `FOV_WITH_PATTERN`), `warnings`. Uses the
repository's existing az/el convention.

## 8. `results.LineOfSightResult` (Task §16, §17, §43)

`antennaAId`, `antennaBId`, `status` (`geometry.LineOfSightStatus`:
`CLEAR`/`BLOCKED`/`PARTIALLY_OCCLUDED`/`UNKNOWN`), `blockingStructureIds` (cellstr),
`intersectionCount`, `segmentLength_m`, `geometryFidelity`, `validity`, `warnings`. A `BLOCKED`
status is **geometry evidence only**; it does **not** modify `Gtx`/`Grx`/`FSPL`/`S21` (Task §44).

## 9. No-fake-physics guarantees (Task §37, §50)

- Geometry blockage/intersection never changes antenna gain or coupling numbers.
- Structure intersection never creates an `InstalledPattern`.
- Blocked LOS never becomes infinite (or any) attenuation.
- No HFSS/CST scattering value, reflection coefficient, or diffraction loss is generated.
These are enforced by architecture-boundary tests (VR-4xx).
