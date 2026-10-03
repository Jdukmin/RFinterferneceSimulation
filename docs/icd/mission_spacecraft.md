# ICD — Simplified Mission Spacecraft Geometry & Antenna Installation Baseline (Phase 7)

Normative interface for loading the **simplified spacecraft baseline** (hull + antenna
installation registry + gimbal steering metadata) from a repository dataset and attaching it to
the existing Phase-5 geometry/FOV/LOS machinery. Requirements: SR-430…SR-438, DR-430…DR-434,
VR-430…VR-438.

Builds on Phase-1..6 **without changing** any existing contract (`AntennaInstallation`,
`SpacecraftStructure`, `Scenario`, FOV/LOS analyzers). **Central rule (unchanged): geometry
provides installation evidence only; it never manufactures EM behavior.** No pattern is loaded or
synthesised; no gain loss / S21 / attenuation / reflection / diffraction value is produced.

Package: `src/+rfscreen/+spacecraft/` (deps: `util`, `geometry`, `antenna`, `scenario`). No core
package depends on it. Dataset: `data/spacecraft/simplified_spacecraft_v1/` (README there).

---

## 1. Frames & units

- Body frame **B** per `coordinate_system.md`; for this mission `+X_B` = direction of flight,
  `Y_B`/`Z_B` span the hull cross-section.
- Antenna frame per `coordinate_system.md` (**boresight = `+X_A`**, `R_BA` columns = antenna
  axes in B). Structure frame per `spacecraft_geometry.md` (`v_B = R_BS·v_S + origin_m`).
- Source data is **mm**; canonical internal unit is **m**. The single conversion point is
  `SpacecraftDataReader.mmToM` (`m = mm/1000`). Positions in m are bit-exact `mm/1000`.

## 2. Dataset files (source data SSOT; derived data is computed, never stored)

| File | Key columns | Notes |
|------|-------------|-------|
| `hull_cross_section.csv` | `vertex_id,y_mm,z_mm` | exactly 6 vertices, CCW in (Y,Z) |
| `hull_parameters.csv` | `key,value,unit,provenance,note` | `x_min_mm`, `x_max_mm` define geometry; `d_long_mm`, `d_short_mm`, `nominal_long_short_ratio` are **cross-checks only**; envelope rows are reference only; `consistency_tol_mm`; `geometry_provenance` |
| `panels.csv` | `panel_id,kind,size_class,vertex_from,vertex_to,face_x_ref,n_x,n_y,n_z` | `SIDE` (hull edge) or `END_CAP` (`x_min_mm`/`x_max_mm`); tabulated canonical normals cross-checked |
| `antenna_installations.csv` | `antenna_id,x_mm,y_mm,z_mm,panel_id,mount_type,assignment_provenance,pattern_status,pattern_dataset,note` | `mount_type` ∈ {`FIXED`,`GIMBAL`}; `pattern_status` ∈ {`CANDIDATE_DATASET`,`PENDING`,`UNSUPPORTED`} |
| `steering_constraints.csv` | `antenna_id,steering_model,reference_axis,max_off_axis_deg,provenance,note` | one row per `GIMBAL` antenna; `reference_axis = PANEL_OUTWARD_NORMAL` |

CSV format (`spacecraft.SpacecraftDataReader.readTable`): `#`/`%` comment and blank lines
skipped; first remaining line = header; comma separated; fields contain no commas; a row whose
field count differs from the header is an error.

## 3. `spacecraft.SpacecraftDataReader`

The **only** file-parsing class of `+spacecraft` (`+geometry` remains file-free).
`readTable(path)` → struct of cellstr columns + `nRows`; `num(T,col,r,label)` → finite double or
error; `mmToM(mm)`.

## 4. `spacecraft.PrismHull` (pure math on the exact vertices)

`PrismHull(vertexIds, yz_m, xMin_m, xMax_m)`; cross-section held as an exact
`geometry.ConvexPolygonGeometry` (convex, unique vertices, **CCW required**). Edge `k` = vertex
`k → k+1` (wrapping).

| Method | Meaning |
|--------|---------|
| `edgeLengths`, `perimeter`, `area`, `centroid` | cross-section metrics |
| `vertexRadii`, `circumradius` | distance of vertices from the centre axis |
| `length_m`, `volume`, `sideAreas` | prism metrics |
| `sideNormal_B(k)` | outward unit normal `[0; dZ; −dY]/‖·‖` |
| `supportDistance(k)` | centre-axis normal distance of the side plane |
| `sideCenter_B(k)` | panel centre `((xMin+xMax)/2, edge midpoint)` |
| `sideR_BS(k)` | `[x_S y_S z_S] = [+X_B, n×X_B, n]` (PanelGeometry frame) |
| `sideOffset(p,k)`, `endOffset(p,'MAX'/'MIN')` | signed plane offset, `>0` outside |
| `hullSignedDistance(p)` | max signed plane offset: `<0` inside, `0` on, `>0` outside |

## 5. `spacecraft.SimplifiedSpacecraftBuilder`

`model = build(datasetDir)` (default `data/spacecraft/simplified_spacecraft_v1`). Validation
(error, never repair): 6 vertices; each hull edge is exactly one SIDE panel; 3 LONG + 3 SHORT in
strict alternation; vertex-derived normals = tabulated normals (≤ `1e-6`); side support distances
= `d_long`/`d_short` (≤ `consistency_tol_mm`); LONG/SHORT width ratio = nominal (≤ `1e-6`);
end-cap normal faces outward from its face; unique antenna ids; panel references resolve; one
steering row per `GIMBAL` antenna and no orphan steering rows.

### 5.1 Panel structures (`model.structures`, 8 × `geometry.SpacecraftStructure`)

| Panel | Primitive | `R_BS` | `origin_m` |
|-------|-----------|--------|------------|
| #1–#6 (SIDE) | **existing** `PanelGeometry(length = xMax−xMin, width = edge length)` | `sideR_BS(k)` (local +X = +X_B, local +Z = outward normal) | panel centre |
| #7/#8 (END_CAP) | `ConvexPolygonGeometry` of the **same six vertices** (exact; no regular hexagon / rectangle / disk / triangulation) | `z_S = ±X_B`, `x_S = +Y_B`, `y_S = z_S×x_S` | `(x_face, 0, 0)` |

`structureType = PANEL`, `provenance = geometry_provenance` (`USER_DEFINED`), `configId = ''`,
`active = true`.

### 5.2 Installations (`model.installations`, id → `antenna.AntennaInstallation`)

`position_m = mmToM(x,y,z)` — **as given, never snapped** onto the hull.
`R_BA = sideMountR_BA(n_panel)`: `x_A = n`, `z_A = +X_B` (component ⊥ n; `+Z_B` fallback if
`n ∥ X_B`), `y_A = z_A × x_A`. Boresight in B = `R_BA(:,1)` = panel outward normal. For `GIMBAL`
antennas this `R_BA` is the gimbal **reference (zero)** orientation.

### 5.3 Installation records (`model.installationRecords`, struct array)

`antennaId`, `position_mm` (source), `position_m`, `panelId`, `mountType`,
`assignmentProvenance` (`SOURCE_EXPLICIT` / `INFERRED_FROM_SIMPLIFIED_GEOMETRY`),
`nominalBoresight_B` (`[]` for `GIMBAL` — no single fixed boresight), `panelNormalOffset_m`
(signed offset from the assigned panel plane), `hullSignedDistance_m`, `patternStatus`,
`patternDataset`, `note`. No gain/loss/S21/attenuation/reflection/diffraction field exists.

### 5.4 Other outputs

`model.hull` (`PrismHull`), `model.panels` (id, kind, sizeClass, edgeIndex, normal_B, center_B,
supportDistance_m, width_m), `model.steering` (id → `GimbalSteeringDomain`),
`model.geometryProvenance`, `model.parameters`, `model.name`, `model.datasetDir`.

### 5.5 `attachToScenario(scenario, model)`

Registers the 8 structures (`Scenario.addStructure`) and the 8 reference installations
(`Scenario.addInstallation`). Adds **no** antenna hardware, pattern, installed pattern, or RF
system — the caller binds those once pattern linkage is resolved. FOV/LOS then run through the
**unchanged** `geometry.AntennaToStructureFOV`, `geometry.LineOfSight`, and
`interference.InstalledEnvironmentAnalyzer`.

## 6. `geometry.ConvexPolygonGeometry`

See `spacecraft_geometry.md` §2 (new Phase-7 primitive).

## 7. `spacecraft.GimbalSteeringDomain` (mission-level steering metadata)

Kept **separate** from `AntennaInstallation` (whose contract is unchanged).

| Field | Meaning |
|-------|---------|
| `antennaId` | steered antenna |
| `referenceAxis_B` | unit gimbal reference axis = assigned panel outward normal |
| `steeringModel` | `HEMISPHERE` (requires `maxOffAxis_deg = 90`) or `CONE` (`0 < max ≤ 180`) |
| `maxOffAxis_deg` | allowed off-axis angle |
| `provenance` | e.g. `SIMPLIFIED_ASSUMPTION` |

Allowed commanded boresight: `‖u_B‖ = 1` (tolerance `UNIT_TOL = 1e-9`, else
`rfscreen:spacecraft:notUnitVector`) and `angle(u_B, n_ref) ≤ maxOffAxis_deg + 1e-9°`, the angle
computed as `atan2d(‖n×u‖, n·u)`. HEMISPHERE ⇔ `u_B·n_ref ≥ 0`: 0°, 89.999°, 90° pass; > 90° fails.

| Method | Meaning |
|--------|---------|
| `offAxisAngle_deg(u)`, `isAllowed(u)` | domain test |
| `steeredR_BA(u)` | proper DCM with `+X_A = u`; roll `z_A` = `+X_B` ⊥ u (fallback `n_ref`); equals the reference `R_BA` at `u = n_ref`; outside domain ⇒ `rfscreen:spacecraft:outsideSteeringDomain` |
| `steeredInstallation(base, u)` | new `AntennaInstallation` (same id/position/configId) for sweep evaluation |
| `sampleDirections(step_deg)` | deterministic 3×N unit boresights: polar `0:step:max` (boundary included), azimuth `0:step:<360` from the `+X_B` projection — the worst-case-scan extension point |

The hemisphere is a **simplified RFC/RFI screening assumption**, not a hardware hard-stop,
keep-out or slew envelope. Narrowing it is a data change (`CONE`, smaller `max_off_axis_deg`).

## 8. No-fake-physics guarantees

- `+spacecraft` constructs no `FreeSpacePattern`/`InstalledPattern`/`PatternGrid`, calls no
  pattern importer, and contains no loss/S21/attenuation/reflection/diffraction identifiers.
- Panel assignment, normal offsets and hull distance are **geometry evidence**; they never alter
  gain or coupling.
- Pending pattern data stays `PENDING`; a candidate dataset is never promoted to the mission
  pattern by this layer.
