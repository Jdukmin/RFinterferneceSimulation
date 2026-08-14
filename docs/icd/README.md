# Interface Control Documents (ICD) — Index

These ICDs are **normative**. Code (`src/+rfscreen/…`) and tests (`tests/`) conform to them.
Where a value is a *canonical decision*, it is fixed here and must not be silently overridden.

## Documents

| ICD | Covers |
|-----|--------|
| [`coordinate_system.md`](coordinate_system.md) | Frames (Body, Antenna Local, Pattern), rotation & az/el convention |
| [`antenna.md`](antenna.md) | `Antenna`, `AntennaInstallation`, `AntennaPattern` / `FreeSpacePattern` / `InstalledPattern` |
| [`rf_system.md`](rf_system.md) | `RFTransmitter`, `RFReceiver`, `RFFrontEnd`, `FrequencyRelation` |
| [`coupling.md`](coupling.md) | `CouplingModel` family, coupling validity, near/far-field |
| [`scenario.md`](scenario.md) | `Scenario`, `OperatingMode`, `AnalysisConfig` (policies/defaults) |
| [`pair_result.md`](pair_result.md) | `PairResult`, `MatrixResult`, enums, validity |
| [`pattern_data.md`](pattern_data.md) | **[Phase 2]** external 2D-cut ingestion, canonicalization, validation, `CutPatternAssembler` |

## Canonical Units (fixed — see `data_requirements.md` DR-001)

| Quantity | Unit | Public name form |
|----------|------|------------------|
| Position / distance | meter (m) | `position_m`, `distance_m` |
| Frequency / bandwidth | hertz (Hz) | `frequency_Hz`, `fc_Hz`, `bw_Hz` |
| TX power | dBm | `power_dBm` |
| Gain | dBi | `gain_dBi` |
| Loss / isolation / index | dB | `*_dB` |
| Azimuth / elevation (public) | degree (deg) | `az_deg`, `el_deg` |
| Angle (internal trig) | radian | (internal only) |
| Orientation | 3×3 DCM (unitless) | `R_BA`, `R_AB` |

Internal trig uses radians but **all public interfaces use degrees for az/el**. Unit-bearing
names are mandatory on public interfaces.

## ICD field-table legend

Every interface table uses these columns:

- **Field** — field / property name.
- **Type** — MATLAB type.
- **Unit** — canonical unit (or `—`).
- **Frame** — coordinate frame / convention (or `—`).
- **R/O** — Required or Optional.
- **Range** — valid range / allowed set.
- **Default** — default behavior/value.
- **Missing** — behavior when absent/NaN.
- **Ext** — extension-point note (reserved for later phases).

## Enumerated types (represented as validated `char` constants; see each ICD)

Phase-1 code represents enumerations as classes exposing `Constant` `char` values plus
`values()`/`isValid()` (MATLAB+Octave portable). Canonical value sets:

- **Role**: `TX`, `RX`, `TXRX`
- **Polarization**: `LINEAR_H`, `LINEAR_V`, `RHCP`, `LHCP`, `DUAL`, `UNKNOWN`
- **PatternProvenance**: `MEASURED_3D`, `SIMULATED_3D`, `APPROX_FROM_CUTS`, `SYNTHETIC_TEST`
- **InstalledPatternSource**: `MEASURED`, `HFSS`, `CST`, `OTHER_SOLVER`, `APPROXIMATE`
- **CouplingModelType**: `PATTERN_ONLY`, `FAR_FIELD`, `MEASURED_S21`, `HFSS`, `CST`, `OTHER_SOLVER`
- **CouplingValidity**: `PATTERN_ONLY`, `FAR_FIELD_VALID`, `FAR_FIELD_INVALID_OR_UNKNOWN`, `MEASURED_COUPLING`, `FULL_WAVE_COUPLING`
- **FrequencyRelationType**: `IN_BAND`, `ADJACENT_BAND`, `OUT_OF_BAND`
- **InterferenceType**: `NONE`, `IN_BAND`, `ADJACENT_BAND`, `BLOCKING_COMPRESSION`, `INTERMODULATION_SPURIOUS`
- **LobeClass**: `MAIN`, `SIDE`, `BACK`
- **ResultValidity**: `VALID_PATTERN_SCREENING`, `APPROXIMATE`, `OUTSIDE_PATTERN_DOMAIN`, `FAR_FIELD_NOT_VERIFIED`, `MISSING_RECEIVER_DATA`, `REQUIRES_FULL_WAVE_VERIFICATION`
- **RiskLevel**: `NA`, `OK`, `LOW`, `WARN`, `HIGH`
- **PatternFidelity** *(Phase 2)*: `MEASURED_2D_CUT`, `SIMULATED_2D_CUT`, `MEASURED_3D`, `SIMULATED_3D`, `APPROX_FROM_CUTS`, `SYNTHETIC_TEST`
- **SamplingType** *(Phase 2)*: `UNIFORM`, `NON_UNIFORM`, `INVALID`
- **ValidationStatus** *(Phase 2)*: `VALID`, `VALID_WITH_WARNINGS`, `INVALID`
