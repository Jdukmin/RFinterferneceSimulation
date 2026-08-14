# ICD — Antenna Pattern Data Pipeline (Phase 2)

Normative interface for ingesting external 2D antenna-cut data and canonicalizing it into a
single internal representation that feeds the **unchanged** Phase-1 screening core.

Requirements: DR-100…DR-140, AR-100…AR-125. Builds on `antenna.md`, `coordinate_system.md`.
Nothing here modifies the Phase-1 physics boundary (Task §36, §Final Rule).

```
External cut file/table -> PatternImporter -> raw data -> PatternCanonicalizer
  -> duplicate/boundary resolution -> PatternValidator -> CanonicalPatternCut
  -> CutPatternAssembler -> FreeSpacePattern(APPROX_FROM_CUTS) -> Phase-1 PairwiseAnalyzer
```

Final architectural rule (binding): **angular resolution and source coordinate convention are
properties of each individual pattern dataset, never global project constants.**

---

## 1. Coordinate conventions (three frames)

Phase 2 keeps three explicit frames and never lets the source `+Z` boresight leak into the core.

| Frame | Definition |
|-------|------------|
| **Source Pattern Frame** | As delivered by the external file. Typical: boresight `+Z`; cuts in the `XZ` / `YZ` planes; `theta` measured from `+Z`; range `[-180,180]` or `[0,360)`; unit deg; gain dBi. Described by a `SourceCoordinateConvention` descriptor — **not** hard-coded. |
| **Canonical Pattern Frame** | Same physical axes as the typical source (boresight `+Z`), but normalized: `theta ∈ [0,360)`, sorted ascending, duplicates resolved, and rotation directions fixed to the canonical set (XZ: `+Z→+X`; YZ: `+Z→+Y`). Produced by `PatternCanonicalizer`. |
| **Phase-1 Antenna Local Frame** | The existing Phase-1 frame (`coordinate_system.md`): boresight `+X_A`, az about `+Z_A`, el toward `+Z_A`. The Canonical→Antenna map is applied **only** in `CutPatternAssembler`. |

### 1.1 Theta → direction (data-driven; §14, §15)
For a cut with zero-axis unit vector `z0` (the `theta=0` direction, = boresight for these cuts)
and positive-rotation-toward unit vector `t0`:
```
d_source(theta) = cosd(theta) * z0 + sind(theta) * t0     % unit vector in source frame
```
- **Canonical XZ:** `z0 = +Z`, `t0 = +X` → `d = [sinθ; 0; cosθ]`.
- **Canonical YZ:** `z0 = +Z`, `t0 = +Y` → `d = [0; sinθ; cosθ]`.
- A source that rotates `+Z→-X` sets `t0 = -X`; canonicalization recovers the canonical `theta`
  geometrically (§2.1), so the sign convention is handled explicitly, never assumed.

### 1.2 Canonical Pattern Frame → Phase-1 Antenna Local Frame (§3, fixed)
```
v_antenna = M * v_source ,   M = [0 0 1; 1 0 0; 0 1 0]      (proper rotation, det=+1)
```
so source `+Z` (boresight) → antenna `+X_A` (boresight). Principal directions (verified by tests,
§VR):

| Source dir | Antenna (az_deg, el_deg) |
|------------|--------------------------|
| `+Z` boresight | (0, 0) |
| `+X` (XZ θ=90)  | (90, 0) |
| `-X` (XZ θ=270) | (-90, 0) |
| `+Y` (YZ θ=90)  | (0, 90) |
| `-Y` (YZ θ=270) | (0, -90) |
| `-Z` back (θ=180) | (180, 0) |

## 2. `patterndata.SourceCoordinateConvention`

| Field | Type | R/O | Range / allowed | Default | Missing |
|-------|------|-----|-----------------|---------|---------|
| `boresightAxis` | char | R | `+X/-X/+Y/-Y/+Z/-Z` | `+Z` | error |
| `plane` | char | R | `XZ` / `YZ` | — | error |
| `angleZeroAxis` | char | R | axis char | `+Z` | error |
| `positiveRotationToward` | char | R | axis char | `XZ→+X`, `YZ→+Y` | error |
| `angleRange` | char | R | `[-180,180]` / `[0,360)` | `[-180,180]` | error |
| `angleUnit` | char | R | `deg` (Phase 2) | `deg` | error |
| `gainUnit` | char | R | `dBi` (Phase 2) | `dBi` | error |
| `polarizationComponent` | char | O | `TOTAL/THETA/PHI/CO/CROSS/UNKNOWN` | `UNKNOWN` | `UNKNOWN` |

Method `directionForTheta(theta_deg)` returns the source-frame unit vector per §1.1. The zero-axis
and positive-rotation axes must be orthogonal, and neither may equal the plane's normal — else a
construction error (`rfscreen:patterndata:badConvention`).

## 2.1 Canonical theta (geometric; handles range + rotation + zero-axis)
For each source sample `theta_s`: `d = source.directionForTheta(theta_s)`; then in the canonical
plane, the off-plane component must be `≈0` (else `PLANE_MISMATCH`), and:
- Canonical XZ: `theta_c = mod(atan2d(d_x, d_z), 360)`
- Canonical YZ: `theta_c = mod(atan2d(d_y, d_z), 360)`

This maps `[-180,180]`→`[0,360)`, absorbs rotation-direction/zero-axis differences, and makes
`±180`→`180`, `0/360`→`0` fall out naturally.

## 3. `patterndata.CanonicalPatternCut` (the internal SSOT for one cut)

| Field | Type | Unit | Meaning / Missing |
|-------|------|------|-------------------|
| `patternId` | char | — | dataset id (required) |
| `antennaId` | char | — | `''` if unknown (never fabricated) |
| `plane` | char | — | `XZ` / `YZ` |
| `theta_deg` | 1×N double | deg | canonical, sorted, `0 ≤ θ < 360`, **native resolution preserved** |
| `gain_dBi` | 1×N double | dBi | aligned with `theta_deg` |
| `samplingType` | char | — | `UNIFORM` / `NON_UNIFORM` / `INVALID` |
| `nominalStep_deg` | double | deg | median step (UNIFORM); `NaN` otherwise |
| `frequency_Hz` | double | Hz | `NaN` if unknown |
| `fidelity` | char (PatternFidelity) | — | explicit; never inferred from filename |
| `sourceConvention` | SourceCoordinateConvention | — | as imported |
| `canonicalConvention` | struct | — | fixed canonical descriptor |
| `provenance` | struct | — | see §7 |
| `validationStatus` | char | — | `VALID`/`VALID_WITH_WARNINGS`/`INVALID` |
| `warnings` | cellstr | — | never discarded |

Method `gain_dBi = evaluate(theta_query_deg)` — **periodic** linear interpolation on the native
`theta_deg` vector (wraps across `0/360`, §13, §20). No index/step arithmetic: interpolation is
against the actual coordinate vector.

## 4. `patterndata.PatternFidelity` (explicit; §22)

`MEASURED_2D_CUT`, `SIMULATED_2D_CUT`, `MEASURED_3D`, `SIMULATED_3D`, `APPROX_FROM_CUTS`,
`SYNTHETIC_TEST`. Stored explicitly on each cut; **never** inferred from filename (§22). When a
3D antenna pattern is assembled from 2D cuts, the resulting Phase-1 `AntennaPattern` provenance is
`APPROX_FROM_CUTS` regardless of the cuts' fidelity (§21) — a 2D cut is never relabeled as true 3D.

## 5. Sampling detection (§5, §6, §7)

`median_step = median(diff(sort(unique(theta))))`. With `stepTolerance_deg` (policy):
- **UNIFORM** iff every `|diff − median_step| ≤ stepTolerance_deg`.
- **NON_UNIFORM** otherwise (explicitly flagged, never silently treated as fixed-step).
- **INVALID** if `< 2` distinct samples, or data otherwise unusable.

Floating-point steps are compared with tolerance (never exact equality). The `nominalStep_deg`
records the detected step for UNIFORM. Different patterns may have different steps (0.25°, 0.5°,
1.0°); XZ and YZ of the same antenna may differ (§18). No sample count (361/721) is hard-coded.

## 6. Duplicate / boundary resolution (§10–§12; deterministic)

After canonicalization, samples at the **same** canonical `theta` (within `angleTolerance_deg`)
are duplicates — including `−180/+180 → 180` and `0/360 → 0`. Per duplicate group with gain
spread `Δ = max−min`:

| Condition | Resolution | Status |
|-----------|-----------|--------|
| `Δ ≤ gainMergeTolerance_dB` | collapse to one sample = **mean** (deterministic) | `VALID` (+ note) |
| `Δ > gainMergeTolerance_dB`, policy `warn` | keep merged mean, record conflict evidence | `VALID_WITH_WARNINGS` |
| `Δ > gainMergeTolerance_dB`, policy `error` | reject | `INVALID` (`INVALID_DUPLICATE_CONFLICT`) |

Every duplicate resolution records, in `provenance.duplicates`, the **source angles**, **source
gains**, **canonical angle**, **difference**, and **resolution applied** (§11). Two independent
samples are **never** silently retained at one canonical angle.

## 7. Provenance (§27; unknown stays unknown)

`provenance` struct fields (missing → `''`/`NaN`, never fabricated):
`sourceFile`, `sourceType`, `patternId`, `antennaId`, `plane`, `frequency_Hz`,
`originalAngleRange`, `originalStep_deg`, `canonicalizationApplied` (logical),
`duplicateHandlingApplied` (logical), `duplicates` (struct array of the evidence above),
`resamplingApplied` (logical), `gainNormalizationApplied` (logical),
`coordinateTransformApplied` (char, e.g. `source->canonical` and `canonical->antenna(M)`).

## 8. Importers (§23, §24)

`patterndata.PatternImporter` (abstract) → `importCut(spec) : CanonicalPatternCut`.
Concrete (only what current needs justify):
- `TablePatternImporter` — from in-memory `theta`/`gain` arrays + a `SourceCoordinateConvention`.
- `CsvPatternImporter` — from a 2-column CSV (`theta,gain`) + convention + metadata.

Importer responsibilities: read, parse, unit-normalize, map coordinates (via canonicalizer),
validate schema, emit canonical data. Importers **must not**: classify RF risk, compute
interference, apply receiver thresholds, or invent gain/sidelobes (§24). They contain no
interference-engine dependency (VR boundary test).

## 9. `patterndata.PatternValidator` (§25, §26)

Deterministic checks returning `patterndata.CutValidationResult{status, issues, warnings}` with
`status ∈ {VALID, VALID_WITH_WARNINGS, INVALID}`. Detects at least: empty data; `NaN`/`Inf`;
non-numeric angle/gain; duplicate source angles; duplicate canonical angles; inconsistent fixed
step; non-monotonic **source** sequence (metadata/warning); unsupported angle range; unsupported
unit; missing plane; ambiguous/again convention; missing provenance; conflicting periodic
endpoints. Warnings are retained on the `CanonicalPatternCut` (never discarded).

## 10. `patterndata.PatternResampler` (§19; native-grid preservation mandatory)

Separate from importer/validator/pattern. `resample(cut, thetaGrid_deg)` returns a new
`CanonicalPatternCut` on the requested grid using periodic interpolation, with
`provenance.resamplingApplied = true` and the original recorded. Source data is **never mutated
in place**; the native-grid cut remains the SSOT.

## 11. `patterndata.CutPatternAssembler` (bridge to Phase-1)

`assembleFreeSpacePattern(patternId, xzCut, yzCut, opts)` builds a Phase-1
`antenna.FreeSpacePattern` with provenance `APPROX_FROM_CUTS` and reduced `confidence`:

1. Choose an antenna-frame `az/el` grid (`opts.azStep_deg`, `opts.elStep_deg`; defaults 2°/2°),
   recorded in provenance (`resamplingApplied=true`).
2. For each grid `(az,el)`: `d_ant = azElToDirection(az,el)`; `d_src = M' * d_ant`;
   polar `Θ = acosd(d_src_z)`, azimuth `Φ = atan2d(d_src_y, d_src_x)`.
3. **Two-cut azimuthal interpolation** (explicit approximation): principal half-plane gains
   `g(Φ=0)=XZ(Θ)`, `g(Φ=180)=XZ(360−Θ)`, `g(Φ=90)=YZ(Θ)`, `g(Φ=270)=YZ(360−Θ)`; the value at
   `Φ` is linearly interpolated between the two bracketing principal half-planes (each cut
   sampled by periodic interpolation on its native grid).
4. Store into a Phase-1 `PatternGrid`; wrap in `FreeSpacePattern` (`provenance=APPROX_FROM_CUTS`,
   `coordinateTransformApplied='canonical->antenna(M)'`).

This is a documented screening approximation, **not** measured 3D truth (§21, §41). The native
cut resolution is preserved in the `CanonicalPatternCut`; the assembled grid is a separate,
labeled derived product. Single-cut assembly is out of Phase-2 scope (both cuts required).

## 12. Configuration — `config.PatternImportPolicy` (all tolerances documented; §6)

| Field | Unit | Default | Meaning |
|-------|------|---------|---------|
| `stepTolerance_deg` | deg | `1e-3` | uniform-step detection tolerance |
| `angleTolerance_deg` | deg | `1e-6` | duplicate canonical-angle tolerance |
| `gainMergeTolerance_dB` | dB | `0.1` | duplicate collapse threshold |
| `duplicateConflictPolicy` | — | `warn` | `warn` → VALID_WITH_WARNINGS; `error` → INVALID |
| `mergeMethod` | — | `mean` | deterministic duplicate merge |

## 13. Extension points (reserved)

`MatPatternImporter` and solver-specific importers; additional `polarizationComponent` handling
(axial ratio / cross-pol cuts); frequency-swept multi-cut sets; single-cut rotational-symmetry
assembly. None fabricate data; all would emit `CanonicalPatternCut` and reuse the same core.
