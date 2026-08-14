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

## 10. Pattern Data Pipeline (Phase 2)

Normative field detail: ICD `pattern_data.md`. These requirements govern ingestion of external
2D antenna-cut data into the canonical internal representation.

- **DR-100 (SHALL)** Angular resolution and source coordinate convention shall be **per-dataset
  properties**, never global constants. No fixed step (0.25°/0.5°/1.0°) and no sample count
  (361/721) shall be hard-coded. *(Phase-2 §5, §17, Final Rule)*
- **DR-101 (SHALL)** Each imported cut shall carry its **own** `theta_deg` grid; XZ and YZ of the
  same antenna may have independent step sizes. *(§18)*
- **DR-102 (SHALL)** The internal canonical angular coordinate shall be `0 ≤ theta_deg < 360`,
  sorted ascending. Source ranges `[-180,180]` and `[0,360)` shall both be accepted. *(§8, §9)*
- **DR-103 (SHALL)** A `SourceCoordinateConvention` descriptor shall express boresight axis, cut
  plane, angle-zero axis, positive-rotation direction, angle range, angle unit, gain unit, and
  polarization component. The importer shall canonicalize **using this descriptor**; no universal
  sign convention shall be hard-coded. *(§14, §15)*
- **DR-104 (SHALL)** Sampling type shall be classified explicitly as `UNIFORM`, `NON_UNIFORM`, or
  `INVALID`, using a documented tolerance; float steps shall never be compared by exact equality.
  `nominalStep_deg` shall record the detected step for UNIFORM data. *(§6, §7)*
- **DR-105 (SHALL)** Duplicate canonical angles (including `−180/+180→180` and `0/360→0`) shall be
  detected and resolved deterministically; two independent samples shall never be silently
  retained at one canonical angle. Conflicting duplicates shall yield a warning or error per
  policy, with evidence recorded. *(§10, §11, §12)*
- **DR-106 (SHALL)** Pattern **fidelity** shall be stored explicitly (`MEASURED_2D_CUT`,
  `SIMULATED_2D_CUT`, `MEASURED_3D`, `SIMULATED_3D`, `APPROX_FROM_CUTS`, `SYNTHETIC_TEST`) and
  never inferred from filename. A 3D pattern assembled from 2D cuts shall be labeled
  `APPROX_FROM_CUTS`, never `MEASURED_3D`/`SIMULATED_3D`. *(§21, §22)*
- **DR-107 (SHALL)** The `CanonicalPatternCut` schema (ICD `pattern_data.md` §3) shall be the
  single internal representation emitted by all importers. *(§16)*
- **DR-108 (SHALL)** Provenance (ICD `pattern_data.md` §7) shall record source file/type, ids,
  plane, frequency, original range/step, and which transforms were applied (canonicalization,
  duplicate handling, resampling, gain normalization, coordinate transform). Unknown values stay
  explicitly unknown. *(§27, §41)*
- **DR-109 (SHALL)** Native-grid preservation is mandatory: resampling to a common grid shall be
  a separate, recorded operation that does not mutate source data in place. *(§19)*
- **DR-110 (SHALL)** Phase-2 test fixtures shall be synthetic and marked `SYNTHETIC_TEST`; no
  mission/reference pattern or invented mainlobe/sidelobe/gain/cross-pol/axial-ratio value shall
  be created for production/reference use. *(§28, §41)*
- **DR-111 (SHALL)** Import shall support `deg` angle unit and `dBi` gain unit in Phase 2;
  unsupported units shall be rejected by validation, not silently coerced. *(§25)*

## 11. Linear RF Coexistence Data (Phase 3)

Normative detail: ICD `spectrum.md`, `receiver_susceptibility.md`.

- **DR-200 (SHALL)** PSD shall be stored/integrated in **W/Hz** (linear); total power in dBm.
  Conversions W↔dBm, dB↔linear shall go through `util.Units` only. *(§7, §8)*
- **DR-201 (SHALL)** Spectrum provenance ∈ {`IDEAL_MODEL`,`DATASHEET`,`MEASURED`,`SIMULATED`,
  `SYNTHETIC_TEST`}, stored explicitly. *(§27)*
- **DR-202 (SHALL)** Filter response canonical unit = power gain dB; provenance as above. *(§9, §28)*
- **DR-203 (SHALL)** Noise model params: `noiseFigure_dB`(+`refTemp_K`) **or** `systemNoiseTemp_K`;
  exactly one method; unknown ⇒ `NOISE_MODEL_INCOMPLETE`. *(§18)*
- **DR-204 (SHALL)** Interference criterion: `type` + `thresholdValue` (dB or dBm). *(§19)*
- **DR-205 (SHALL)** `ReceiverSusceptibilityResult` shall carry the fields of ICD
  `receiver_susceptibility.md` §7, with unknowns explicit (`NaN`/`''`). *(§22)*
- **DR-206 (SHALL)** Every RF power value shall carry a `ReferencePlane`. *(§4)*
- **DR-207 (SHALL)** Synthetic spectrum/filter/noise fixtures shall be marked `SYNTHETIC_TEST`. *(§29)*
- **DR-208 (SHALL)** No fake RF hardware values (filter rejection, NF, Tsys, I/N limit,
  sensitivity, TX mask) shall be created for production/reference use. *(§29, §41)*
- **DR-209 (SHALL)** `RFTransmitter.spectrum` and `RFReceiver.filter`/`noiseModel`/
  `interferenceCriterion` shall be **optional** fields; absence preserves Phase-1/2 behavior. *(§32)*
- **DR-210 (SHALL)** Boltzmann constant `k = 1.380649e-23 J/K` shall be centralized in
  `util.Constants`. *(§17)*
- **DR-211 (SHALL)** `config.RiskPolicy`/`FrequencyRelationPolicy` (screening) and
  `receiver.InterferenceCriterion` (physical) shall be distinct types. *(§30, §31)*
- **DR-212 (SHALL)** Integration-grid construction policy shall be documented and deterministic. *(§11)*

## 12. Receiver Nonlinear Data (Phase 4)

Normative detail: ICD `receiver_nonlinear.md`.

- **DR-300 (SHALL)** `ReceiverFrontEnd` fields: `linearGain_dB`, `p1dB_in_dBm`, `iip3_in_dBm`,
  `noiseFigure_dB`, `preselector`, `channelFilter`, `referencePlane=LNA_INPUT`, `provenance`.
  Input-referred; unknowns `NaN`/`[]`, never defaulted. *(§6, §30)*
- **DR-301 (SHALL)** `FrontEndProvenance` ∈ {`DATASHEET`,`MEASURED`,`SIMULATED`,`USER_INPUT`,
  `SYNTHETIC_TEST`}. *(§29)*
- **DR-302 (SHALL)** Nonlinear power sums shall use `util.Units.sumPowers_dBm` (linear domain). *(§8)*
- **DR-303 (SHALL)** `CompressionCriterion(requiredBackoff_dB)`, `BlockingCriterion` (constant or
  tabulated offset→dBm), `IntermodulationCriterion('MAX_IM3_INPUT_POWER', dBm)`; distinct types. *(§28)*
- **DR-304 (SHALL)** Result objects (`CompressionResult`, `BlockingResult`, `IntermodulationProduct`,
  `NonlinearSusceptibilityResult`) shall carry the ICD `receiver_nonlinear.md` §9 fields, with
  unknowns explicit and a reference plane. *(§22, §38)*
- **DR-305 (SHALL)** `receiver.NonlinearValidity` codes per ICD §8; `ProductType` ∈
  {`2F1_MINUS_F2`,`2F2_MINUS_F1`}. *(§31)*
- **DR-306 (SHALL)** `RFReceiver.receiverFrontEnd`/`compressionCriterion`/`blockingCriterion`/
  `intermodulationCriterion` shall be optional; absence preserves Phase-1/2/3 behavior. *(§39)*
- **DR-307 (SHALL)** No fake nonlinear hardware values (P1dB, IIP3, blocking threshold, gain, IM3
  criterion) for production/reference use; test fixtures marked `SYNTHETIC_TEST`. *(§29, §30)*

## 13. Spacecraft Structure & Installed Environment Data (Phase 5)

Normative detail: ICD `spacecraft_geometry.md`, `installed_environment.md`.

- **DR-400 (SHALL)** `SpacecraftStructure` fields: `id`, `name`, `structureType`, `geometry`,
  `R_BS`, `origin_m`, `configId`, `deploymentState`, `active`, `provenance`. *(§7)*
- **DR-401 (SHALL)** `StructureType` ∈ {BUS,PANEL,SOLAR_ARRAY,PAYLOAD,BOOM,REFLECTOR,ANTENNA_BODY,
  OTHER}; `GeometryFidelity` ∈ {CENTER_POINT,BOUNDING_VOLUME,VERTEX_SAMPLED,SURFACE_SAMPLED,
  MESH_INTERSECTION}; `GeometryProvenance` ∈ {USER_DEFINED,CAD_DERIVED,MEASURED,MISSION_CONFIG,
  SYNTHETIC_TEST}; `DeploymentState` ∈ {STOWED,DEPLOYED,CUSTOM}; `LineOfSightStatus` ∈
  {CLEAR,BLOCKED,PARTIALLY_OCCLUDED,UNKNOWN}. *(§7, §14, §16, §31)*
- **DR-402 (SHALL)** Primitive geometry: `BoxGeometry(halfSizes_m)`, `PanelGeometry(width_m,
  height_m)` in the structure local frame. *(§8)*
- **DR-403 (SHALL)** `results.AntennaStructureFOVResult`, `results.LineOfSightResult`,
  `results.InstalledEnvironmentResult`, `results.PatternComparisonResult` per the ICDs; unknowns
  explicit; existing az/el convention. *(§17, §18)*
- **DR-404 (SHALL)** Installed-pattern registry keyed by `(antennaId, configId)`;
  `configId=''` = configuration-independent. *(§6)*
- **DR-405 (SHALL)** `installed.InstalledPatternPolicy` ∈ {PREFER_INSTALLED,REQUIRE_INSTALLED};
  `PatternSourceUsed` ∈ {INSTALLED,FREE_SPACE_FALLBACK,NONE}; `InstallationValidity` ∈
  {INSTALLED_PATTERN_AVAILABLE,FREE_SPACE_FALLBACK,INSTALLATION_EFFECT_UNKNOWN,
  REQUIRE_INSTALLED_UNAVAILABLE,GEOMETRY_ONLY,UNSUPPORTED_EM_PHYSICS}; `GeometryRisk` ∈
  {NA,LOW,MODERATE,HIGH}. *(§39, §40, §42, §25)*
- **DR-406 (SHALL)** Installed-pattern fidelity/provenance propagate unchanged; no upgrade. *(§41)*
- **DR-407 (SHALL)** Synthetic geometry/pattern fixtures marked `SYNTHETIC_TEST`; not presented as
  flight data. *(§31, §32)*
- **DR-408 (SHALL)** `Scenario` gains optional structure and installed-pattern registries; absence
  preserves Phase-1..4 behavior. *(§29)*
