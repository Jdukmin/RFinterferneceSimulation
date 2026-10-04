# Simplified spacecraft geometry + antenna installation baseline — v1

Analysis-baseline spacecraft hull and antenna installation registry for **RFC/RFI geometry
screening** (structure FOV, LOS blockage, installation evidence). Consumed by
`rfscreen.spacecraft.SimplifiedSpacecraftBuilder` (ICD [`docs/icd/mission_spacecraft.md`](../../../docs/icd/mission_spacecraft.md)).

> **What this is not.** This is **not** the original CAD and claims **no mechanical CAD fidelity**.
> It claims **no full-wave / installed-EM fidelity**: the geometry produces geometric evidence only
> (FOV occupancy, LOS `CLEAR`/`BLOCKED`, distances, angles) and **never** a gain loss, S21,
> attenuation, reflection, diffraction or scattering value. Dimensions and positions are the
> current **analysis baseline**, not a released mechanical configuration.

## Files (source data — SSOT)

| File | Content | Provenance |
|------|---------|------------|
| `hull_cross_section.csv` | the **six** (Y,Z) cross-section vertices, mm, CCW | `SOURCE_EXPLICIT` |
| `hull_parameters.csv` | X extrusion range (0..6000 mm) + design parameters used only for cross-checks + reference envelopes | per row |
| `panels.csv` | Panel #1–#8: side edge / end-cap reference, LONG/SHORT class, canonical outward normals | `SOURCE_EXPLICIT` |
| `antenna_installations.csv` | 8 antenna installation reference points (mm), panel assignment, mount type, pattern linkage status | per row |
| `steering_constraints.csv` | KAA gimbal steering domains (hemisphere) | `SIMPLIFIED_ASSUMPTION` |
| `analysis_cases.csv`, `antenna_functions.csv`, `pattern_bindings.csv` | the 6 RFC/RFI analysis cases and their pattern bindings (see below) | per row |
| `rf_systems.csv` | RF baseline: TX power/BW/fc, RX NF/filter/I-N criterion, per-quantity provenance (see below) | per column |

CSV rules: `#` lines are comments, first remaining line is the header, fields contain no commas.

**Units.** Source values are kept in **mm** exactly as supplied. The repository's canonical unit is
the metre; the conversion `m = mm / 1000` is applied in exactly one place
(`SpacecraftDataReader.mmToM`). Nothing is stored twice in two units.

**Derived data is not stored.** Edge lengths, normals, panel centres/frames, area, volume,
circumradius, and antenna→panel offsets are computed from the vertices by
`rfscreen.spacecraft.PrismHull`. Design parameters (`d_long_mm`, `d_short_mm`,
`nominal_long_short_ratio`) and the tabulated normals are **cross-checked** against the vertices
at build time (mismatch ⇒ error); they never regenerate or adjust the vertices.

## Body frame B

- `+X_B` = direction of flight; `Y_B`, `Z_B` span the cross-section.
- Panel #8 (aft) at `X = 0`; Panel #7 (forward) at `X = 6000 mm`; side-panel length 6000 mm.
- The hull is the **irregular hexagonal cross-section extruded from X = 0 to X = 6000 mm**.

## Cross-section (equiangular irregular hexagon — NOT regular)

Three LONG faces (Panel #1/#3/#5, supporting-plane distance `d_long = 800.000 mm`) alternate with
three SHORT faces (Panel #2/#4/#6, `d_short = 1078.260870 mm`, from the nominal Long/Short ratio
**2.6**; plausible design range ≈ 2.5–2.7, not modelled).

| Vertex | Y [mm] | Z [mm] |
|--------|--------|--------|
| V12 | −783.188191 | +800.000000 |
| V23 | −1084.414419 | +278.260870 |
| V34 | −301.226227 | −1078.260870 |
| V45 | +301.226227 | −1078.260870 |
| V56 | +1084.414419 | +278.260870 |
| V61 | +783.188191 | +800.000000 |

| Panel | Edge | Class | Width [mm] | Outward normal (B) | Centre (X,Y,Z) [mm] |
|-------|------|-------|-----------:|--------------------|---------------------|
| #1 | V61→V12 | LONG | 1566.376383 | (0, 0, +1) | (3000, 0, +800) |
| #2 | V12→V23 | SHORT | 602.452455 | (0, −0.866025404, +0.5) | (3000, −933.801305, +539.130435) |
| #3 | V23→V34 | LONG | 1566.376383 | (0, −0.866025404, −0.5) | (3000, −692.820323, −400) |
| #4 | V34→V45 | SHORT | 602.452455 | (0, 0, −1) | (3000, 0, −1078.260870) |
| #5 | V45→V56 | LONG | 1566.376383 | (0, +0.866025404, −0.5) | (3000, +692.820323, −400) |
| #6 | V56→V61 | SHORT | 602.452455 | (0, +0.866025404, +0.5) | (3000, +933.801305, +539.130435) |
| #7 | all six vertices at X = 6000 | END | — | (+1, 0, 0) | — |
| #8 | all six vertices at X = 0 | END | — | (−1, 0, 0) | — |

Derived regression values (verified by `tests/test_simplified_spacecraft.m`):

| Quantity | Value |
|----------|-------|
| cross-section area | 2.854053021 m² |
| cross-section perimeter | 6.506486512 m |
| prism volume | 17.124318124 m³ |
| total side-panel area | 39.038919071 m² (LONG 9.398258295, SHORT 3.614714729 each) |
| circumradius / circumdiameter | 1119.546222 mm / **2.239092444 m** |
| centroid | (Y,Z) = (0, 0) |
| extents | X 0..6000, Y ±1084.414419, Z −1078.260870..+800 mm |

### Envelopes (reference only — the hull is **not** scaled to them)

- Simplified panel geometry (this dataset): **Ø ≈ 2.239 m** circumscribed.
- Actual panel envelope: up to ≈ Ø 2.5 m.
- Component-inclusive spacecraft envelope (protrusions): ≈ Ø 2.7 m class.

## Antenna installation reference points

Positions are **installation reference points** supplied as the baseline; they are used **as
given** and are never snapped/projected onto the simplified hull (ISL at X = 6375 mm, beyond the
X = 6000 mm end cap, is an intentional protrusion).

| Antenna | (X,Y,Z) [mm] | Panel | Mount | Outward offset from panel plane | Assignment provenance |
|---------|--------------|-------|-------|--------------------------------:|-----------------------|
| SBA_NADIR | (255, 870, 1030) | #6 | FIXED | ≈ +190.2 mm | `INFERRED_FROM_SIMPLIFIED_GEOMETRY` (corner) |
| SBA_ZENITH | (255, −530, −1240) | #4 | FIXED | ≈ +161.7 mm | `INFERRED_FROM_SIMPLIFIED_GEOMETRY` (corner) |
| GPSA_1 | (2045, −265, −1295) | #3 | FIXED | ≈ +77.0 mm | `SOURCE_EXPLICIT` |
| GPSA_2 | (3145, −265, −1295) | #3 | FIXED | ≈ +77.0 mm | `SOURCE_EXPLICIT` |
| KAA_1 | (5965, −1100, 850) | #1 | GIMBAL | +50.0 mm (exact) | `SOURCE_EXPLICIT` |
| KAA_2 | (5965, +1285, 530) | #5 | GIMBAL | ≈ +47.8 mm | `SOURCE_EXPLICIT` |
| ISL | (6375, −595, −805) | #3 | FIXED | ≈ +117.8 mm | `SOURCE_EXPLICIT` |
| SAR_ANT | (3250, 0, 800) | #1 | FIXED | 0.0 mm (on the plane) | `SOURCE_EXPLICIT` |

**Fixed boresight** = assigned panel's outward normal, with the repository antenna frame
(`+X_A` = boresight). Deterministic roll: `x_A = n`, `z_A = +X_B`, `y_A = z_A × x_A`,
`R_BA = [x_A y_A z_A]` (proper DCM).

## KAA gimbal steering (simplified assumption)

KAA_1 / KAA_2 are **not** fixed-boresight antennas. The `AntennaInstallation` holds the gimbal
**reference (zero)** orientation (base normal = Panel #1 resp. Panel #5 outward normal). The
allowed commanded boresight set is the outward **hemisphere** `|u_B| = 1, u_B·n_base ≥ 0`
(off-axis ≤ 90°). This is a simplified RFC/RFI screening domain — **not** a hardware gimbal
hard-stop, keep-out zone or slew envelope. When real limits are available, change the row in
`steering_constraints.csv` to `CONE` with a smaller `max_off_axis_deg`; no code change is needed.

## Pattern linkage and analysis cases

The geometry builder loads **no** pattern. Patterns are bound per analysis case by
`rfscreen.mission.MissionCaseBuilder` from three tables:

| File | Content |
|------|---------|
| `analysis_cases.csv` | 6 cases = SBA variant {SBA1, SBA4} × GPS band {L1, L2, L5} |
| `antenna_functions.csv` | one RF function per row (S-band mounts host a TC receive and a TM transmit function), role, pattern selector, binding status |
| `pattern_bindings.csv` | pattern key → dataset files, tag frequency, operating band, cut fidelity, polarization (each with provenance) |

| Antenna | Status | Dataset | Note |
|---------|--------|---------|------|
| SBA_NADIR / SBA_ZENITH | `CASE_DEPENDENT` | `data/Sband_TMTC` | SBA1 and SBA4 analysed as separate cases; TC (2000–2120 MHz, RX) and TM (2200–2300 MHz, TX) |
| GPSA_1 / GPSA_2 | `CASE_DEPENDENT` | `data/Lband_GPS` | L1 (1575 MHz plot, 1563–1588), L2 (**CST pattern at 1227.6 MHz**, `data/Lband_GPS_CST_L2`; the 1207 MHz proxy is `GPS_L2_PROXY_1207`, comparison only), L5 (1176 MHz plot, 1164–1189) as separate cases |
| ISL | `BOUND` | `data/Xband_ISL` | CST ISL geometry, 10.6 GHz cut of the owner band 10.55–10.65 GHz (10.3/10.4/10.5 GHz cuts remain available) |
| KAA_1 / KAA_2 | `BOUND` | `data/Kaband_KAA_CST` | CST feed + Python reflector aperture integration (D 220 mm), datasheet anchors pass; replaces the legacy `data/Kaband_DLS` cuts |
| SAR_ANT | `DEFERRED_CLOSED_NETWORK` | — | RF analysis later in the closed network; geometry only here |

GNSS band windows follow the CST worker's monitor windows (`cst/specs/lband_gnss.yaml`) and are
tagged `ASSUMED`; the 1207 MHz entry `GPS_L2_PROXY_1207` is a single-frequency **proxy** kept for comparison; the active L2 pattern is simulated at 1227.6 MHz.
No synthetic pattern is substituted for a missing one, and no dataset is relabelled as mission data.

## Assumptions / TBD

1. Hull = simplified prism; no protrusions, appendages, solar arrays or payload bodies modelled.
2. Long/Short ratio fixed at the nominal 2.6 (range 2.5–2.7 not swept).
3. SBA assignments near corners are inferred from the simplified geometry.
4. KAA steering domain = full outward hemisphere (placeholder for real gimbal limits).
5. KAA uses a reflector-approximation surrogate (no public numeric reflector pattern exists); only
   0-1 deg is model-validated. SAR RF analysis is deferred to the closed network.
6. RF baseline (`rf_systems.csv`) is mostly **engineering assumption** (NF, bandwidths, powers,
   I/N = -6 dB); only the GPS L1 centre/bandwidth are published-standard values. ISL frequency and
   bandwidth are provisional (owner band 10.55-10.65 GHz, centre 10.6 GHz). P1dB/IIP3 unknown (NaN). The GPS L1 / L2 / L5
   receivers share one front-end baseline (NF 2 dB; 20.46 MHz; I/N <= -6 dB) on the unchanged GPSA antennas; only the
   centre frequency and the frozen pattern differ per case band (L2 = 1227.6 MHz carrier with the CST pattern simulated at 1227.6 MHz, `data/Lband_GPS_CST_L2`).
7. SAR power is not published: 2.5 kW nominal / 5 kW screening are inferred from comparable X-band
   SARs; the CST SAR example (8 GHz) does not match the 9.65 GHz reference.

## RF baseline (`rf_systems.csv`)

Vendor/standard-published values are kept apart from our engineering assumptions via per-quantity
provenance tags. Receivers use filter + NF + `I_N_MAX` (−6 dB) — the form the engine supports —
not a bare `interferenceThreshold_dBm`. Allowable in-band interference = kTB + NF + I/N:
S TC ≈ −124 dBm, GPS L1 ≈ −105 dBm, ISL ≈ −104 dBm, SAR ≈ −87.8 dBm. The S-band receiver NF (3 dB)
is a simulation baseline, **not** a vendor spec; GPS (Beyond Gravity PODRIX class) final acceptance
should use C/N0 / J/S rather than total-power I/N. Replace table values when qualification data
exist; no code change is needed.

## Phase 7d additions

- **Ka:** baseline bandwidth is the full 1500 MHz allocation (25.50–27.00 GHz); the modulation /
  data-rate discussion is **not** an RFC input (`docs/notes/ka_downlink_datarate_open_issue.md`).
- **Pattern freeze:** all bound free-space patterns are frozen (`data/PATTERN_FREEZE.md`).
- **Operating modes:** `operating_modes.csv` — `SCREENING_ALL_TX` (explicit stress case, default) and
  two provisional nominal templates.
- **EM sweep plan:** `em_sweep_policy.csv` → `docs/reports/em_sweep/`.
- **Front end:** `rf_systems.csv` has `frontend_prov`; P1dB/IIP3 remain unknown (none public).
