# Data Requirements

**Phase:** 1. Defines the data the system consumes/produces, canonical units, provenance, and
validation. Field-level normative detail lives in the ICD (`docs/icd/`).

---

## 1. Canonical Units (fixed)

- **DR-001 (SHALL)** The system shall use these canonical internal units on all public
  interfaces:

  | Quantity   | Canonical unit | Name convention        |
  |------------|----------------|------------------------|
  | Position   | meter (m)      | `position_m`           |
  | Distance   | meter (m)      | `distance_m`           |
  | Frequency  | hertz (Hz)     | `frequency_Hz`, `fc_Hz`, `bw_Hz` |
  | TX power   | dBm            | `power_dBm`            |
  | Gain       | dBi            | `gain_dBi`             |
  | Loss/iso   | dB             | `*_dB`                 |
  | Angle (public az/el) | degree (deg) | `az_deg`, `el_deg` |
  | Angle (internal trig)| radian (rad) | internal only    |
  | Rotation   | DCM 3×3 (unitless) | `R_BA`, `R_AB`     |

- **DR-002 (SHALL)** Conversions (W↔dBm, dB↔linear, deg↔rad) shall be centralized in a units
  utility; ad-hoc inline conversions are disallowed. *(Task §28)*

## 2. Antenna Data

- **DR-010 (SHALL)** Antenna record fields (see ICD `antenna.md`): `id` (unique char),
  `name` (char), `role` (TX/RX/TXRX), `freqMin_Hz`, `freqMax_Hz`, `polarization`,
  `patternRef`, `installationRef`. Optional: `maxDimension_m` (largest aperture dimension,
  reserved for far-field checks).
- **DR-011 (SHALL)** `freqMin_Hz ≤ freqMax_Hz`, both finite and positive. Violations rejected.

## 3. Installation Data

- **DR-020 (SHALL)** Installation fields: `antennaId`, `position_m` (3×1, body frame),
  `R_BA` (3×3 DCM, antenna→body), optional `configId`.
- **DR-021 (SHALL)** `R_BA` shall be validated as a proper rotation (orthonormal,
  `det ≈ +1`, no NaN) at construction. *(Task §33)*

## 4. Pattern Data

- **DR-030 (SHALL)** A tabulated pattern shall store: `az_deg` grid (monotonic), `el_deg` grid
  (monotonic, within [−90,90]), `frequency_Hz` grid (monotonic), and a `gain_dBi` array
  dimensioned `[nEl × nAz × nFreq]`.
- **DR-031 (SHALL)** Every pattern shall store `provenance` (MEASURED_3D / SIMULATED_3D /
  APPROX_FROM_CUTS / SYNTHETIC_TEST) and `confidence` in [0,1].
- **DR-032 (SHALL)** `InstalledPattern` shall additionally store `installedSource`
  (MEASURED / HFSS / CST / OTHER_SOLVER / APPROXIMATE).
- **DR-033 (SHALL)** Optional pattern channels (reserved extension): polarization, axial ratio,
  phase, cross-pol. Absence shall be explicit (empty), not fabricated. *(Task §8, §39)*
- **DR-034 (SHALL)** Pattern gain arrays shall be finite where defined; `NaN` entries denote
  *missing data* and shall be handled by the documented boundary policy, not silently used.

## 5. Provenance & Synthetic-Data Integrity

- **DR-040 (SHALL)** Any pattern generated within Phase 1 for testing shall have
  `provenance = SYNTHETIC_TEST` and a name containing `SYNTHETIC_TEST`. *(Task §32)*
- **DR-041 (SHALL)** No real/mission/reference pattern data shall be created or hard-coded in
  Phase 1. *(Task §10, §31)*
- **DR-042 (SHALL)** Provenance shall be preserved end-to-end into `PairResult` (a result derived
  from synthetic data shall be traceable as such). *(Task §35)*

## 6. RF System Data

- **DR-050 (SHALL)** Transmitter fields: `id`, `antennaId`, `fc_Hz`, `bw_Hz`, `power_dBm`,
  `mode` (char), `polarization`. Reserved: spectrum mask, harmonics, spurious, duty cycle,
  waveform. *(Task §15)*
- **DR-051 (SHALL)** Receiver fields: `id`, `antennaId`, `fc_Hz`, `bw_Hz`, `polarization`,
  optional `frontEnd` (`RFFrontEnd`), optional `interferenceThreshold_dBm`. *(Task §16)*
- **DR-052 (SHALL)** `RFFrontEnd` reserved fields: `filterPassband_Hz` `[lo hi]`, `p1dB_dBm`,
  `iip3_dBm`, `noiseFigure_dB`, `sensitivity_dBm`. Unknown values shall be `NaN`/empty, never
  invented. *(Task §16, §39)*
- **DR-053 (SHALL)** `bw_Hz ≥ 0`, `fc_Hz > 0`, `power_dBm` finite. Violations rejected.

## 7. Result Data

- **DR-060 (SHALL)** `PairResult` shall carry the fields in ICD `pair_result.md`, including
  validity, confidence, coupling type/metric, and accumulated warnings. *(Task §24)*
- **DR-061 (SHALL)** `MatrixResult` shall carry ordered TX-id row keys, RX-id column keys, a cell
  array of `PairResult`, and a derived risk-level matrix. *(Task §25)*
- **DR-062 (SHALL)** Results shall be plain, serializable value structures (no handles to live
  UI or solver state), enabling later export. *(Task §35, §37)*

## 8. Configuration Data

- **DR-070 (SHALL)** Analysis configuration (`AnalysisConfig`) shall parameterize: lobe
  thresholds, adjacent-band guard, pattern interpolation/frequency policy, and risk thresholds.
  No such threshold shall be hard-coded in the engine. *(Task §14, §25)*
- **DR-071 (SHALL)** Configuration shall have documented defaults; defaults shall be reproducible
  and stated in the ICD. *(Task §27)*

## 9. Missing-Data Policy (global)

- **DR-080 (SHALL)** Missing data shall be represented explicitly (`NaN`, empty, or a validity
  enum), and shall propagate a corresponding validity/warning to the result. The system shall
  never substitute an invented default value for missing physics. *(Task §39, §40)*
