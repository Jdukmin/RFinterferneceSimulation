# ICD — Scenario & Analysis Configuration

Requirements: SR-100…SR-101, AR-072, AR-090, DR-070…DR-071.

---

## 1. `scenario.Scenario`

Holds the registries and the active-system selection that drive one analysis run (SR-100).

| Field | Type | R/O | Meaning | Missing |
|-------|------|-----|---------|---------|
| `name` | char | R | scenario name | error |
| `antennas` | containers.Map (id→`Antenna`) | R | antenna registry | error |
| `installations` | containers.Map (id→`AntennaInstallation`) | R | installation registry | error |
| `patterns` | containers.Map (id→`AntennaPattern`) | R | pattern registry | error |
| `transmitters` | containers.Map (id→`RFTransmitter`) | R | TX registry | error |
| `receivers` | containers.Map (id→`RFReceiver`) | R | RX registry | error |
| `activeTxIds` | cellstr | O | active TX subset (default: all) | all |
| `activeRxIds` | cellstr | O | active RX subset (default: all) | all |
| `operatingModeId` | char | O | selected operating mode | `''` |

Integrity rules (enforced by `Scenario.validate`):
- All ids unique within their registry (SR-022, VR-064).
- Every `Antenna.patternId`/`installationId` resolves; every TX/RX `antennaId` resolves.
- A TX's antenna role ∈ {`TX`,`TXRX`}; an RX's antenna role ∈ {`RX`,`TXRX`}.

## 2. `scenario.OperatingMode`

| Field | Type | R/O | Meaning |
|-------|------|-----|---------|
| `id` | char | R | mode id (e.g. `NOMINAL`, `TTC`, `PAYLOAD_DL`, `SAFE`) |
| `name` | char | R | human name |
| `activeTxIds` | cellstr | O | TX active in this mode |
| `activeRxIds` | cellstr | O | RX active in this mode |

Phase-1 provides the mechanism only; no fixed mission modes are shipped (SR-101).

## 3. `config.AnalysisConfig` (all thresholds configurable — DR-070)

Aggregates the policy objects. Constructed with documented defaults (`AnalysisConfig.default()`).

### 3.1 `config.LobeClassificationPolicy` (AR-031, SR-061)
| Field | Unit | Default | Meaning |
|-------|------|---------|---------|
| `mainDropDb` | dB | `3` | `MAIN` if `gain ≥ peak − mainDropDb` |
| `sideDropDb` | dB | `20` | boundary for side vs deep-back by level (metadata) |
| `backAngleDeg` | deg | `90` | `BACK` if off-boresight angle `> backAngleDeg` |

Classification order: if off-boresight angle `> backAngleDeg` → `BACK`; else if
`gain ≥ peak − mainDropDb` → `MAIN`; else `SIDE`. (Thresholds never hard-coded in engine.)

### 3.2 `config.FrequencyRelationPolicy` (AR-090)
| Field | Unit | Default | Meaning |
|-------|------|---------|---------|
| `guard_Hz` | Hz | `0` | adjacent-band guard; `separation ≤ guard_Hz` ⇒ `ADJACENT_BAND` |

Default `0` means: overlap ⇒ in-band, any gap ⇒ out-of-band, exact edge-touch ⇒ adjacent.
Missions raise `guard_Hz` to widen the adjacent zone.

### 3.3 `config.PatternInterpolationPolicy` (AR-021…AR-025)
| Field | Default | Meaning |
|-------|---------|---------|
| `angular` | `'bilinear'` | angular interpolation method |
| `azWrap` | `true` | treat azimuth as periodic |
| `elClamp` | `true` | clamp elevation to grid boundary |
| `freqMethod` | `'nearest'` | `'nearest'` \| `'linear'` |
| `outOfBandFreq` | `'nan'` | `'nan'` \| `'nearest'` \| `'error'` |

### 3.4 `config.RiskPolicy` (AR-072)
Risk is derived from frequency relation + directional coupling index (screening only). Defaults:

| Field | Unit | Default | Meaning |
|-------|------|---------|---------|
| `indexHigh_dB` | dB | `0` | `DCI ≥ indexHigh_dB` counts as strong directional overlap |
| `indexWarn_dB` | dB | `-10` | `DCI ≥ indexWarn_dB` counts as moderate |
| `indexLow_dB` | dB | `-20` | below this ⇒ `OK` |

Risk mapping (canonical, screening semantics):
- `OUT_OF_BAND` and `DCI < indexWarn_dB` → `OK`.
- `IN_BAND` & `DCI ≥ indexHigh_dB` → `HIGH`.
- `IN_BAND` & `DCI ≥ indexWarn_dB` → `WARN`.
- `ADJACENT_BAND` & `DCI ≥ indexHigh_dB` → `WARN`.
- otherwise, if `DCI ≥ indexLow_dB` → `LOW`, else `OK`.
- self-pair (same antenna) → `NA`.

Risk levels are **screening indicators**, always paired with a `ResultValidity`; they never
assert a verified isolation (SR-093, rule 9). All thresholds are configurable (no hard-coding).
