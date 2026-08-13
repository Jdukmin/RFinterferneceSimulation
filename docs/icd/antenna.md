# ICD — Antenna, Installation, Pattern

Requirements: SR-020…SR-055, DR-010…DR-042. Frames per `coordinate_system.md`.

---

## 1. `antenna.Antenna` (hardware)

Antenna *hardware* record. **Does not** own installation geometry (SR-011, VR-083).

| Field | Type | Unit | Frame | R/O | Range | Default | Missing | Ext |
|-------|------|------|-------|-----|-------|---------|---------|-----|
| `id` | char | — | — | R | non-empty, unique in scenario | — | error | — |
| `name` | char | — | — | R | non-empty | — | error | — |
| `role` | char (Role) | — | — | R | `TX`/`RX`/`TXRX` | — | error | — |
| `freqMin_Hz` | double | Hz | — | R | `>0`, `≤ freqMax_Hz` | — | error | — |
| `freqMax_Hz` | double | Hz | — | R | `≥ freqMin_Hz`, finite | — | error | — |
| `polarization` | char (Polarization) | — | — | R | see enum set | `UNKNOWN` | `UNKNOWN` | axial ratio/cross-pol later |
| `patternId` | char | — | — | R | references a pattern | — | error | — |
| `installationId` | char | — | — | R | references an installation | — | error | — |
| `maxDimension_m` | double | m | — | O | `>0` | `NaN` | `NaN` (far-field unknown) | far-field checks |

Notes:
- `Antenna` links to a pattern and an installation **by id** (loose coupling); it never embeds a
  position or DCM.
- `role` gates pair generation: `TX`/`TXRX` can transmit, `RX`/`TXRX` can receive.

## 2. `antenna.AntennaInstallation` (placement/orientation)

Installation of one antenna on the spacecraft body (SR-030, DR-020).

| Field | Type | Unit | Frame | R/O | Range | Default | Missing | Ext |
|-------|------|------|-------|-----|-------|---------|---------|-----|
| `antennaId` | char | — | — | R | references an `Antenna` | — | error | — |
| `position_m` | 3×1 double | m | Body (B) | R | finite | — | error | — |
| `R_BA` | 3×3 double | — | A→B (DCM) | R | proper rotation (§3 coord ICD) | — | error | — |
| `configId` | char | — | — | O | — | `''` | `''` | multi-config installs |

- `R_BA` validated at construction (SR-034). Boresight in body = `R_BA(:,1)`.
- **Extension point:** alternate installation configurations (deployed vs stowed) via `configId`.

## 3. `antenna.AntennaPattern` (abstract contract)

Canonical pattern abstraction (SR-050). Concrete: `FreeSpacePattern`, `InstalledPattern`.

### 3.1 Contract method
```
gain_dBi = evaluate(frequency_Hz, az_deg, el_deg)
```
- Inputs scalar (Phase 1). `az_deg`, `el_deg` in the pattern frame (≡ antenna frame, Phase 1).
- Returns directional gain in dBi.
- Applies the interpolation/boundary policy (§3.4). Out-of-domain per policy (SR-053, AR-025).

Also exposed: `[gain_dBi, info] = evaluateWithInfo(...)` returning a struct with fields
`inDomain` (logical), `clampedEl` (logical), `wrappedAz` (logical), `freqHandling` (char),
`warnings` (cellstr) — so the analyzer can record domain warnings (AR-081).

### 3.2 Common metadata (all patterns)

| Field | Type | Unit | R/O | Range | Default | Missing | Ext |
|-------|------|------|-----|-------|---------|---------|-----|
| `name` | char | — | R | non-empty | — | error | — |
| `provenance` | char (PatternProvenance) | — | R | enum set | — | error | — |
| `confidence` | double | — | O | [0,1] | `1.0` | `NaN` | — |
| `polarization` | char (Polarization) | — | O | enum set | `UNKNOWN` | `UNKNOWN` | — |
| `frequency_Hz` | 1×nF double | Hz | R | monotonic, `>0` | — | error | — |
| `az_deg` | 1×nA double | deg | R | monotonic in [−180,180] | — | error | — |
| `el_deg` | 1×nE double | deg | R | monotonic in [−90,90] | — | error | — |
| `gain_dBi` | nE×nA×nF double | dBi | R | finite where defined; `NaN`=missing | — | error | policy |
| `axialRatio_dB` | array | dB | O | — | `[]` | `[]` | reserved |
| `phase_deg` | array | deg | O | — | `[]` | `[]` | reserved |
| `crossPolGain_dBi` | array | dBi | O | — | `[]` | `[]` | reserved |

### 3.3 `FreeSpacePattern` vs `InstalledPattern` (SR-051, VR-084)

- **`FreeSpacePattern`**: isolated (free-space) pattern. No `installedSource`.
- **`InstalledPattern`**: adds:

  | Field | Type | R/O | Range | Default | Missing | Ext |
  |-------|------|-----|-------|---------|---------|-----|
  | `installedSource` | char (InstalledPatternSource) | R | `MEASURED`/`HFSS`/`CST`/`OTHER_SOLVER`/`APPROXIMATE` | — | error | — |

  The two are **distinct classes** and never interchangeable by type; a `FreeSpacePattern` can
  never be mistaken for an installed one.

### 3.4 Interpolation & boundary policy (canonical; parameterized by `PatternInterpolationPolicy`)

- **Angular:** bilinear interpolation in `(az_deg, el_deg)` (AR-021).
- **Azimuth:** periodic. Lookups wrap into `[−180,180]`; if the az grid does not include a
  wrap-partner node, the grid is treated as circular for interpolation across the seam
  (AR-022, VR-032).
- **Elevation:** clamped to `[el_deg(1), el_deg(end)]` ⊆ `[−90,90]`; requests beyond are clamped
  to the boundary and flagged `clampedEl = true` (AR-022, VR-033).
- **Frequency (default `nearest`):** nearest supported frequency within
  `freqToleranceFactor` (default 0). Options: `nearest` | `linear`. `linear` interpolates gain
  between the two bracketing frequency planes. Requests outside `[min,max]` frequency:
  behavior set by `outOfBandFreq` = `nearest` (clamp to nearest plane, warn) | `nan` (return
  `NaN`, `inDomain=false`) | `error`. **Default `nan`** → `OUTSIDE_PATTERN_DOMAIN` at result
  level (AR-025, VR-034).
- **Single-frequency patterns (`nF==1`):** treated as **frequency-independent** — the single
  plane is reused at any query frequency. If the query differs from the stored frequency beyond a
  small tolerance, a warning is added but `inDomain` stays `true` (this is a documented reuse of a
  single-frequency pattern, not an out-of-domain condition). Out-of-range behavior (`nan` /
  `nearest` / `error`) applies only to **multi-frequency** grids.
- **Missing gain nodes (`NaN`):** if any bilinear contributor is `NaN`, the result is `NaN` and
  `inDomain=false` (never silently interpolated over missing data, DR-034).
- Determinism: repeated identical calls return identical values (VR-073).

## 4. Synthetic test patterns (`antenna.SyntheticPatternFactory`) — SR-054, DR-040

Factory of **clearly-marked** synthetic patterns for tests only. Every product has
`provenance = SYNTHETIC_TEST` and a `name` containing `SYNTHETIC_TEST`.

| Factory method | Description |
|----------------|-------------|
| `isotropic(gain_dBi, freq_Hz)` | constant gain over all angles |
| `cosineDirectional(peak_dBi, freq_Hz, exponent)` | `peak + 20*log10(max(cos(offAngle),eps)^n)` boresight beam |
| `mainSideBack(peak_dBi, side_dBi, back_dBi, freq_Hz)` | discrete main/side/back synthetic lobes for lobe-class tests |

These return `FreeSpacePattern` objects. **No mission/reference data** is produced (SR-054).
