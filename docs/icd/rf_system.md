# ICD — RF Transmitter / Receiver / Front-End / Frequency Relation

Requirements: SR-070…SR-073, DR-050…DR-053, AR-040…AR-041.

---

## 1. `rf.RFTransmitter`

Reference plane of `power_dBm`: **TX antenna input port** (see `pair_result.md` §Reference planes).

| Field | Type | Unit | R/O | Range | Default | Missing | Ext |
|-------|------|------|-----|-------|---------|---------|-----|
| `id` | char | — | R | non-empty, unique | — | error | — |
| `antennaId` | char | — | R | references a TX/TXRX antenna | — | error | — |
| `fc_Hz` | double | Hz | R | `>0` | — | error | — |
| `bw_Hz` | double | Hz | R | `≥0` | — | error | — |
| `power_dBm` | double | dBm | R | finite | — | error | — |
| `mode` | char | — | O | — | `'NOMINAL'` | `'NOMINAL'` | — |
| `polarization` | char (Polarization) | — | O | enum | `UNKNOWN` | `UNKNOWN` | pol mismatch later |
| `spectrumMask` | (reserved) | — | O | — | `[]` | `[]` | **Ext:** mask/harmonics/spurious |
| `dutyCycle` | double | — | O | (0,1] | `1.0` | `1.0` | **Ext:** time sharing |

Occupied band (Phase-1): `[fc_Hz − bw_Hz/2, fc_Hz + bw_Hz/2]`.
**Extension points (reserved, not implemented):** spectrum mask, harmonics, spurious, waveform.

## 2. `rf.RFReceiver`

Reference plane of `interferenceThreshold_dBm`: **receiver RF input** (RX antenna output port,
before LNA) unless a front-end explicitly relocates it. Receiver is **not** a bare frequency
range (SR-072).

| Field | Type | Unit | R/O | Range | Default | Missing | Ext |
|-------|------|------|-----|-------|---------|---------|-----|
| `id` | char | — | R | non-empty, unique | — | error | — |
| `antennaId` | char | — | R | references an RX/TXRX antenna | — | error | — |
| `fc_Hz` | double | Hz | R | `>0` | — | error | — |
| `bw_Hz` | double | Hz | R | `≥0` | — | error | — |
| `polarization` | char (Polarization) | — | O | enum | `UNKNOWN` | `UNKNOWN` | pol mismatch |
| `interferenceThreshold_dBm` | double | dBm | O | finite | `NaN` | `NaN` → `MISSING_RECEIVER_DATA` | — |
| `frontEnd` | `rf.RFFrontEnd` | — | O | — | `[]` (empty) | `[]` | susceptibility layer |

RX band (Phase-1): filter passband if a front-end filter is present, else
`[fc_Hz − bw_Hz/2, fc_Hz + bw_Hz/2]`.

## 3. `rf.RFFrontEnd` (reserved susceptibility layer, SR-072, R8)

Optional. Represents the front-end chain. **Unknown values are `NaN`/empty — never invented**
(DR-052, SR-120). Phase 1 stores these; nonlinear computations (blocking/IM3) are reserved.

| Field | Type | Unit | R/O | Range | Default | Missing | Ext |
|-------|------|------|-----|-------|---------|---------|-----|
| `filterPassband_Hz` | 1×2 double `[lo hi]` | Hz | O | `lo<hi`, `>0` | `[]` | `[]` | filter selectivity |
| `p1dB_dBm` | double | dBm | O | finite | `NaN` | `NaN` | **Ext:** blocking margin |
| `iip3_dBm` | double | dBm | O | finite | `NaN` | `NaN` | **Ext:** IM3 margin |
| `noiseFigure_dB` | double | dB | O | `≥0` | `NaN` | `NaN` | **Ext:** I/N, C/(N+I) |
| `sensitivity_dBm` | double | dBm | O | finite | `NaN` | `NaN` | — |

## 4. `rf.FrequencyRelation` (static analysis, AR-040)

`result = rf.FrequencyRelation.classify(txBand_Hz, rxBand_Hz, policy)` where each band is
`[lo hi]` in Hz and `policy` is `config.FrequencyRelationPolicy`.

Returns a struct:

| Field | Type | Unit | Meaning |
|-------|------|------|---------|
| `type` | char (FrequencyRelationType) | — | `IN_BAND` / `ADJACENT_BAND` / `OUT_OF_BAND` |
| `overlap_Hz` | double | Hz | overlap bandwidth (0 if none) |
| `separation_Hz` | double | Hz | gap between nearest band edges (0 if overlapping) |

Rules (canonical, parameterized by `guard_Hz`):
- `overlap_Hz > 0` → `IN_BAND`.
- else if `separation_Hz ≤ guard_Hz` → `ADJACENT_BAND`.
- else → `OUT_OF_BAND`.

`guard_Hz` default: see `scenario.md` (`FrequencyRelationPolicy`). **Extension:** the
`InterferenceType` taxonomy adds `BLOCKING_COMPRESSION` / `INTERMODULATION_SPURIOUS`, which
require `RFFrontEnd` data and are out of Phase-1 computation (AR-041).
