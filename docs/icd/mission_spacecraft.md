# ICD — Simplified Mission Spacecraft Geometry & Antenna Installation Baseline (Phase 7)

Normative interface for loading the **simplified spacecraft baseline** (hull + antenna
installation registry + gimbal steering metadata) from a repository dataset and attaching it to
the existing Phase-5 geometry/FOV/LOS machinery, and for building the per-case RFC/RFI scenarios
(§9). Requirements: SR-430…SR-456, DR-430…DR-447, VR-430…VR-461.

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
| `antenna_installations.csv` | `antenna_id,x_mm,y_mm,z_mm,panel_id,mount_type,assignment_provenance,pattern_status,pattern_dataset,note` | `mount_type` ∈ {`FIXED`,`GIMBAL`}; `pattern_status` ∈ {`CASE_DEPENDENT`,`BOUND`,`CANDIDATE_DATASET`,`DEFERRED_CLOSED_NETWORK`,`PENDING`,`UNSUPPORTED`} (installation-level summary) |
| `pattern_bindings.csv` | `pattern_key,dataset_dir,xz_file,yz_file,pattern_freq_mhz,band_min_mhz,band_max_mhz,freq_provenance,fidelity,polarization,polarization_provenance,note` | §9 |
| `antenna_functions.csv` | `function_id,installation_id,role,role_provenance,pattern_selector,binding_status,note` | §9 |
| `analysis_cases.csv` | `case_id,sba_variant,gps_band,note` | §9 |
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

## 9. Analysis cases — `mission.MissionCaseBuilder` (Phase 7b)

Orchestration package `src/+rfscreen/+mission/` (deps: `util`, `spacecraft`, `patterndata`,
`antenna`, `scenario`, `geometry`); no package depends on it. `+spacecraft` stays pattern-free.

**Cases** (`analysis_cases.csv`): SBA variant {`SBA1`,`SBA4`} × GPS band {`L1`,`L2`,`L5`} = 6
cases. The SBA variant applies to both SBA mounts (TC and TM functions); the GPS band to both GPSA
mounts. ISL and KAA are identical in every case. SAR_ANT is **not instantiated** (RF analysis is
done later in the closed network); its installation and panel geometry remain.

**Functions** (`antenna_functions.csv`): one `antenna.Antenna` per RF function, referencing the
mount by `installationId` (an installation may host several functions):

| Function | Mount | Role | Pattern selector | Binding status |
|----------|-------|------|------------------|----------------|
| SBA_NADIR_TC / SBA_ZENITH_TC | SBA_NADIR / SBA_ZENITH | RX | `<variant>_TC` | `CASE_DEPENDENT` |
| SBA_NADIR_TM / SBA_ZENITH_TM | SBA_NADIR / SBA_ZENITH | TX | `<variant>_TM` | `CASE_DEPENDENT` |
| GPSA_1 / GPSA_2 | GPSA_1 / GPSA_2 | RX | `GPS_<band>` | `CASE_DEPENDENT` |
| KAA_1 / KAA_2 | KAA_1 / KAA_2 | TX | `KAA_KA_26P25` (CST feed + reflector aperture integration, `data/Kaband_KAA_CST`) | `BOUND` |
| ISL | ISL | TXRX | `ISL_10P6` (owner band 10.55–10.65 GHz) | `BOUND` |
| SAR_ANT | SAR_ANT | — | `NONE` | `DEFERRED_CLOSED_NETWORK` |

**Patterns** (`pattern_bindings.csv`): XZ/YZ CSV cuts (`[0,360)`, boresight `+Z`) imported with
the **existing** `CsvPatternImporter` (explicit fidelity and frequency) and assembled with the
existing `CutPatternAssembler` (provenance `APPROX_FROM_CUTS`; default 2° grid). Each pattern is a
single-frequency pattern tagged at `pattern_freq_mhz` and reused across `band_min…band_max` as
frequency-independent (antenna ICD §3.4). Antenna band = the binding's band.

| API | Meaning |
|-----|---------|
| `listCases(datasetDir)` | case struct array |
| `buildCase(caseId, opts)` | struct: `caseId`, `sbaVariant`, `gpsBand`, `scenario` (structures + installations + antennas + patterns), `model`, `functions` (per function: key, band, frequency, fidelity, source files, `included`), `patternCache`, `warnings`. `opts.patternCache` (shared `containers.Map`) avoids re-assembly across cases; `opts.azStep_deg`/`elStep_deg` |
| `structureFov(c, lobePolicy)` | pattern-aware `AntennaToStructureFOV` for every included function × panel at the reference orientation (rows: off-boresight, angular radius, distance, centre lobe, occupied lobes, centre-ray hit, validity) |
| `assemblePattern(binding, opts)`, `readBindings(path)` | pattern assembly / binding table |

**RF systems** (`rf_systems.csv`, owner-specified 1st baseline; per-quantity provenance tags
`PUBLIC_STANDARD` / `PUBLIC_REPORTED` / `ENGINEERING_ASSUMPTION` / `PROVISIONAL` /
`SCREENING_ASSUMPTION`): one row per RF function instance, registered through
`buildCase` → `registerRfSystems`:

| Template | Function(s) | fc | BW | TX power | RX NF / criterion |
|----------|-------------|----|----|----------|-------------------|
| `S_TM_TX` | SBA_NADIR_TM, SBA_ZENITH_TM | 2.250 GHz | 2.7 MHz | 5 W = 36.99 dBm | — |
| `S_TC_RX` | SBA_NADIR_TC, SBA_ZENITH_TC | 2.050 GHz | 0.2 MHz | — | NF 3 dB, I/N ≤ −6 dB (≈ −124 dBm) |
| `GPS_L1_RX` / `GPS_L2_RX` / `GPS_L5_RX` | GPSA_1, GPSA_2 (in the L1 / L2 / L5 case) | 1.57542 / 1.2276 / 1.17645 GHz | 20.46 MHz | — | NF 2 dB, I/N ≤ −6 dB (≈ −105 dBm) |
| `KA_DLS_TX` | KAA_1, KAA_2 | 26.25 GHz | 1.5 GHz (25.50–27.00 GHz, full EESS allocation) | 70 W = 48.45 dBm | — |
| `ISL_X_TX/RX` | ISL | 10.6 GHz (owner band 10.55–10.65 GHz) | 20 MHz (provisional) | 1 W = 30 dBm | NF 3 dB, I/N ≤ −6 dB (≈ −104 dBm) |
| `SAR_X_TX/RX` | SAR_ANT — **deferred, not registered** | 9.65 GHz | 525 MHz | 2.5 kW nominal (63.98 dBm) / 5 kW screening (66.99 dBm) | NF 5 dB (≈ −87.8 dBm) |

- TX: `RFTransmitter` (power at the antenna input port) + `RectangularSpectrum` (`IDEAL_MODEL`).
- RX: `RFReceiver` = `IdealBandpassFilter [fc − bw/2, fc + bw/2]` + `ReceiverNoiseModel` (NF, 290 K)
  + `InterferenceCriterion('I_N_MAX', −6)`; **no** `interferenceThreshold_dBm`. P1dB/IIP3 are
  unknown → no `ReceiverFrontEnd` is created (nonlinear analyzers report `MISSING_P1DB/IIP3`).
- `requires_pattern_key`: a system is registered only if its function is bound to that pattern in
  the case. The GPS receivers of the L1 / L2 / L5 baselines (same front end, band-specific centre) belong to the
  matching case; the receivers of the other bands are not registered in it.
- `opts.powerMode = 'SCREENING'` switches SAR TX to `tx_power_screen_dbm`; other TX unchanged.
- All instances (both SBA, both KAA, both GPSA) are registered; no operating mode is assumed —
  select with `activeTxIds` / `activeRxIds`.
- The GNSS I/N criterion is **temporary**; GNSS acceptance should finally use C/N0 or J/S.

KAA FOV uses the gimbal reference orientation; steering sweeps use `GimbalSteeringDomain` (§7).

## 10. Operating modes (P7d-5)

`operating_modes.csv` (`mode_id,kind,status,active_tx,active_rx,description`; `;`-separated
system ids or `ALL`). `buildCase(..., struct('modeId', id))` applies the mode through
`Scenario.activeTxIds/activeRxIds/operatingModeId`; the default is **`SCREENING_ALL_TX`**, an
explicit stress case with every registered TX active at once (warned: *not an operating mode*).
Nominal modes are **templates** (`PROVISIONAL_NEEDS_OWNER_CONFIRMATION`): `NOM_NADIR_KAA1` and
`NOM_ZENITH_KAA2` (one SBA, one KAA, ISL link up, GPS receiving). Ids that are not registered in a
case (e.g. GPS L1 receivers in L2/L5 cases) are skipped with a warning; a mode that would leave no
active TX or RX is an error (an empty list would silently mean *all*). All systems stay
registered; only the active sets change.

## 11. Receiver front-end data path (P7d-6)

`rf_systems.csv` columns `p1db_in_dbm`, `iip3_in_dbm` (empty = unknown = NaN) and `frontend_prov`
(mandatory when either is given). A `ReceiverFrontEnd` is created only then; no compression,
blocking or IM3 criterion is derived from them. No public values were found for the S-band
transponder, the GNSS receiver or an ISL receiver
(`docs/notes/receiver_nonlinear_data_search_2026-10-04.md`).

## 12. Installed-geometry EM sweep plan (P7d-4)

`mission.EmSweepPlan` + `em_sweep_policy.csv` + `examples/em_sweep_plan.m` → `docs/reports/em_sweep/`:
coarse 1–27 GHz grid, dense grids across each actual band, LOCAL (per antenna) and PAIRWISE
(antenna pair) partition with lower-bound hex-cell feasibility for the Learning Edition. Planning
only — no solver run, no coupling value.

## 13. Level report, coupling policy, terminology, installed hook, local facets (Phase 8)

**Coupling policy (owner, 2026-10-04).** X-band (ISL), Ka and SAR: free space. L- and S-band: installed
pattern / S21 where available (none accepted yet) else free space, flagged
`FREE_SPACE_INSTALLATION_EFFECT_UNKNOWN`. The policy band is decided by the interferer (coupling)
frequency (< 3 GHz = L/S).

**`mission.RfcLevelReport`.** `couplingModel([s21Tables])` = free-space-assumed far-field model
(preferred-composed with `CstCouplingModel` when tables are given); `build(case, model)` → one row per
active interferer → victim pair (same-mount pairs omitted): geometry (distance, LOS, blocking panels),
`txGain/rxGain`, `coupling`, `couplingValidity`, `farFieldVerified`, `fspl_dB`, `s21_dB` (= Gtx + Grx −
FSPL or the tabulated S21), `txPower_dBm`, **`receivedLevel_dBm`** (= P_tx + S21 at the victim antenna
port), `spectralFactor_dB`, `inBandInterference_dBm`, `noise_dBm`, `allowable_dBm` (kTB + NF + I/N_max),
`iOverN_dB`, `margin_dB`, **`requiredRejection_dB`** (= received level − allowable level), `installedEffect`
(`INSTALLED_S21` | `INSTALLED_PATTERN` | `FREE_SPACE_BY_DECISION` | `FREE_SPACE_INSTALLATION_EFFECT_UNKNOWN`).
`writeCsv` adds a terminology comment line.

**`rfc_terms.csv`.** Report labels (`term_key, ko, en, status, source`). Status `PROVISIONAL_STANDARD_EMC`
until confirmed against the KARI papers; `KARI_PAPER_ATTESTED` only for quoted phrases
(`docs/notes/kari_terminology_status_2026-10-04.md`).

**Antenna dimensions.** `antenna_functions.csv: max_dimension_m, max_dimension_prov` feed the far-field
check (GPSA 0.200 m datasheet; KAA 0.22 m; SBA 0.065 m and ISL 0.030 m are CST **surrogate** sizes).

**`installed_patterns.csv`** (empty): ACCEPTED rows → `antenna.InstalledPattern` registered as
`INSTALLED_<function>` (2D cuts → `APPROX_FROM_CUTS`, source from `installed_source`); the free-space files
stay untouched; `c.functions(k).patternSource` = `FREE_SPACE` | `INSTALLED`. Paths are repo-relative or absolute.

**`mission.LocalFacetExporter`.** `export(model, antennaId, R)` → the SSOT panels clipped (Sutherland–Hodgman)
to a box of half-size R around the **unsnapped** reference point, in the CST local frame (`+X_L = +X_B`,
`+Z_L` = boresight, `+Y_L = Z×X`); per facet: cropped/full area, outward normal, **support-plane signed
distance** and **minimum distance to the finite facet / its edges** reported separately. Geometry only.
