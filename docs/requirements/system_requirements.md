# System Requirements — Spacecraft RF Coexistence & Antenna Interference Screening Tool

**Phase:** 1 (Requirements / ICD / Core RF Interference Engine)
**Scope note:** This document states *what* the system must do and be. Interface field-level
detail (types, units, ranges, defaults, missing-data behavior) is normative in the ICD
(`docs/icd/`). Requirement IDs are stable and referenced by the ICD, code, and tests.

Requirement keywords: **SHALL** (mandatory), **SHOULD** (recommended), **MAY** (optional /
extension point). "Phase-1" marks what is implemented now; "Reserved" marks a contract that is
fixed now but implemented later.

---

## 1. Purpose & Context

- **SR-001 (SHALL)** The system shall perform *early-design RF coexistence screening* between
  multiple RF antennas installed on a spacecraft, identifying high-risk TX→RX pairs.
- **SR-002 (SHALL)** The system shall be a screening tool that *feeds* full-wave EM solvers
  (HFSS/CST) and EMC/measurement verification; it **shall not** claim to replace them.
- **SR-003 (SHALL)** Pattern/FOV-based screening results **shall not** be represented as, or
  numerically equated with, actual electromagnetic coupling (measured S21 / full-wave).
  *(reference.md R1, R5; cross-cutting rule 1)*

## 2. Separation of Concerns (Architecture)

- **SR-010 (SHALL)** The system shall separate the following concerns into distinct modules with
  no implicit ownership across them: **Geometry, Pattern, Coupling, RF System, Receiver
  Susceptibility, Interference Decision**. *(R3, R8; rule 2)*
- **SR-011 (SHALL)** Antenna *hardware* (`Antenna`) and antenna *installation*
  (`AntennaInstallation`) shall be separate entities; hardware shall not own installation
  geometry. *(R3; rule 3)*
- **SR-012 (SHALL)** Coupling computation shall sit behind a replaceable abstraction
  (`CouplingModel`) so that pattern-only, far-field, measured-S21, HFSS, and CST couplings are
  interchangeable implementations. *(R1, R2; rule 1)*
- **SR-013 (SHALL)** The core engine shall have **no dependency on any UI**, and **no
  dependency on any external EM solver** at run time. *(Task §35)*

## 3. Antenna Management

- **SR-020 (SHALL)** The system shall manage an arbitrary number of antennas.
- **SR-021 (SHALL)** Each antenna shall carry at least: unique **ID**, **Name**, **RF role**
  (TX / RX / TXRX), **supported frequency** range, **polarization**, a **pattern reference**,
  and an **installation reference**. *(Task §5.1)*
- **SR-022 (SHALL)** Antenna IDs shall be unique within a scenario; duplicate IDs shall be
  rejected. *(Task §33 invalid-input)*

## 4. Installation & Geometry

- **SR-030 (SHALL)** Each installation shall define the antenna's **position** in the
  spacecraft **body frame** and its **orientation** (antenna local frame relative to body).
- **SR-031 (SHALL)** Orientation shall be stored in a canonical representation that is **not**
  bound to a single Euler convention — a **rotation matrix (DCM)** is canonical; quaternion
  conversion **SHOULD** be supported. *(Task §6)*
- **SR-032 (SHALL)** The system shall define and fix (in the ICD) the **Spacecraft Body Frame**,
  **Antenna Local Frame**, and **Pattern Frame**, and the transformation directions between
  them. *(Task §7; rule 7)*
- **SR-033 (SHALL)** The system shall compute, for any ordered antenna pair, the relative
  geometry: **distance** and the **local azimuth/elevation** of each antenna toward the other.
  *(Task §12)*
- **SR-034 (SHALL)** Invalid rotation matrices (non-orthonormal, wrong size, NaN) shall be
  rejected with a clear error. *(Task §33)*

## 5. Field-of-View Domains

- **SR-040 (SHALL)** The system shall treat **antenna-to-antenna FOV** and
  **antenna-to-structure FOV** as *separate domains* with separate interfaces. *(R2, R7; rule 5)*
- **SR-041 (Phase-1)** Antenna-to-antenna FOV/geometry shall be implemented.
- **SR-042 (Reserved)** Antenna-to-structure FOV (bus, panel, solar array, payload, reflector,
  boom, other antenna) shall be defined as an interface; full scattering is out of Phase-1
  scope. *(Task §11.2)*

## 6. Antenna Patterns

- **SR-050 (SHALL)** Patterns shall be modeled behind a canonical `AntennaPattern` abstraction
  exposing directional gain as `gain_dBi = evaluate(frequency_Hz, az_deg, el_deg)`. *(Task §13)*
- **SR-051 (SHALL)** `FreeSpacePattern` and `InstalledPattern` shall be distinguishable types;
  `InstalledPattern` shall carry a **source** (MEASURED / HFSS / CST / OTHER_SOLVER /
  APPROXIMATE). *(R5, R6; rule 4)*
- **SR-052 (SHALL)** Every pattern shall carry a **provenance** (MEASURED_3D / SIMULATED_3D /
  APPROX_FROM_CUTS / SYNTHETIC_TEST); synthetic test data shall be unmistakably marked. *(Task §9, §32)*
- **SR-053 (SHALL)** Pattern evaluation shall follow an explicit, documented **interpolation and
  boundary policy** (azimuth wrap, elevation clamp, frequency handling, out-of-domain). *(Task §13)*
- **SR-054 (SHALL)** Phase 1 **shall not** generate real/reference/mission antenna patterns or
  hard-code mission gain values. Synthetic fixtures for tests are allowed only when marked
  `SYNTHETIC_TEST`. *(Task §10, §31, §39; rule "forbidden")*
- **SR-055 (SHOULD)** Pattern metadata should be extensible to polarization, axial ratio, phase,
  cross-pol, and confidence. *(Task §8)*

## 7. Lobe Classification

- **SR-060 (SHALL)** Main/Side/Back lobe classification shall be treated as analysis/visualization
  **metadata**, not as a substitute for physical gain in power computations. *(Task §14)*
- **SR-061 (SHALL)** Lobe-classification thresholds shall be **configurable**, not hard-coded
  (e.g., peak−3 dB, peak−15 dB, peak−30 dB, back-hemisphere angle). *(Task §14)*

## 8. RF Transmitter & Receiver

- **SR-070 (SHALL)** The transmitter model shall support at least: ID, antenna, center
  frequency, bandwidth, TX power, operating mode, polarization. *(Task §15)*
- **SR-071 (SHOULD/Reserved)** The transmitter model should reserve extension points for
  spectrum mask, harmonics, spurious, duty cycle, waveform. *(Task §15)*
- **SR-072 (SHALL)** The receiver shall **not** be limited to a bare frequency range; it shall
  support an extensible front-end: RF band, filter, LNA, P1dB, IIP3, noise figure, sensitivity,
  interference threshold. *(Task §16; R8)*
- **SR-073 (SHALL)** Receiver susceptibility shall be a *layer distinct from* antenna coupling.
  *(R8; rule 2)*

## 9. Coupling & Near/Far-Field

- **SR-080 (SHALL)** The system shall provide a `PatternOnlyCouplingModel` as the Phase-1
  coupling implementation; its output shall be a clearly-named *directional coupling index*, not
  an isolation/S21. *(Task §18, §20; rule 1)*
- **SR-081 (SHALL)** The system **shall not** auto-apply free-space path loss (FSPL) to
  antenna-to-antenna paths without an explicit far-field validity determination. *(Task §19; rule 6)*
- **SR-082 (SHALL)** Each coupling result shall carry a coupling-validity state from at least:
  `PATTERN_ONLY`, `FAR_FIELD_VALID`, `FAR_FIELD_INVALID_OR_UNKNOWN`, `MEASURED_COUPLING`,
  `FULL_WAVE_COUPLING`. *(Task §19)*
- **SR-083 (Reserved)** `FarFieldCouplingModel`, `MeasuredS21CouplingModel`, `HFSSCouplingModel`,
  and other-solver models shall exist as reserved interfaces. A far-field model, if computed,
  **shall** verify far-field validity before applying FSPL. *(Task §18)*

## 10. Interference Classification & Results

- **SR-090 (SHALL)** The interference classification API shall be extensible to at least
  `IN_BAND`, `ADJACENT_BAND`, `BLOCKING_COMPRESSION`, `INTERMODULATION_SPURIOUS`. Phase 1
  computes spatial + spectral screening deterministically. *(Task §17; R9)*
- **SR-091 (SHALL)** For every TX→RX pair the system shall produce a `PairResult` carrying at
  least the fields enumerated in the ICD (geometry, gains, lobe classes, frequency relation,
  coupling type + metric, interference metric, margin, validity, confidence, warnings). *(Task §24)*
- **SR-092 (SHALL)** The system shall produce a **matrix-compatible** deterministic data
  structure over all TX×RX combinations. *(Task §25)*
- **SR-093 (SHALL)** Every result shall carry a **validity** state (e.g.,
  `VALID_PATTERN_SCREENING`, `APPROXIMATE`, `OUTSIDE_PATTERN_DOMAIN`, `FAR_FIELD_NOT_VERIFIED`,
  `MISSING_RECEIVER_DATA`, `REQUIRES_FULL_WAVE_VERIFICATION`), so risk is never over-committed to
  a single number. *(Task §40; rule 9)*

## 11. Scenario

- **SR-100 (SHALL)** The engine shall not be bound to one fixed operating state; a `Scenario`
  with operating modes and active TX/RX selection shall drive analysis. *(Task §23)*
- **SR-101 (Reserved)** Multiple concrete mission scenarios are out of Phase-1 scope; the
  *mechanism* is in scope.

## 12. Units, Frames, Reference Planes

- **SR-110 (SHALL)** No implicit units. Canonical internal units shall be fixed in the ICD
  (position m, frequency Hz, power dBm, gain dBi, loss dB, angle deg for public az/el). *(Task §28)*
- **SR-111 (SHALL)** Public interface names shall encode units where practical (`frequency_Hz`,
  `power_dBm`, `gain_dBi`, `az_deg`, `el_deg`, `position_m`). *(Task §28)*
- **SR-112 (SHALL)** Every RF power/interference quantity shall have a documented reference plane
  (TX input, EIRP reference, RX antenna output, receiver RF input, LNA input). *(Task §21)*

## 13. Integrity / "No Fake Physics"

- **SR-120 (SHALL)** Unimplemented physics shall be represented as explicit TODO/unsupported
  states or reserved interfaces, never as invented constants (coupling constants, isolation,
  HFSS results, receiver thresholds, spacecraft losses). *(Task §39)*
- **SR-121 (SHALL)** Synthetic test data shall be impossible to mistake for reference/mission
  data (enforced by provenance = `SYNTHETIC_TEST` and by tests). *(Task §35)*
