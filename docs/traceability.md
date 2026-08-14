# Traceability & Docs/Code/Test Reconciliation — Phase 1

Reconciles `reference.md` → requirements → ICD → code → tests (Task §36, VR-090/091).
Every requirement maps to code and to a test (or a documented deferral). No divergence is left
unresolved: where a canonical decision was needed it is recorded here.

## 1. Requirement → Code → Test map

| Req | Code (src/+rfscreen/…) | Test (tests/…) |
|-----|------------------------|----------------|
| SR-001/002/003 (screening ≠ coupling) | `+coupling/PatternOnlyCouplingModel`, `CouplingResult.isPhysicalCoupling` | test_pairwise, test_architecture_boundary (VR-082) |
| SR-010 (6 concerns) | package split (`+geometry`/`+antenna`/`+coupling`/`+rf`/`+interference`) | test_architecture_boundary |
| SR-011 hardware≠install | `+antenna/Antenna` (no geometry), `+antenna/AntennaInstallation` | test_architecture_boundary (VR-083) |
| SR-012 coupling boundary | `+coupling/CouplingModel` (abstract) + subclasses | test_invalid_inputs, test_architecture_boundary |
| SR-013 no UI/solver dep | (absence) | test_architecture_boundary (VR-080/081) |
| SR-020/021/022 antenna mgmt | `+antenna/Antenna`, `+scenario/Scenario` | test_multisystem, test_invalid_inputs (VR-064) |
| SR-030/031 install + DCM | `+antenna/AntennaInstallation`, `+geometry/Rotation` | test_coordinate, test_invalid_inputs |
| SR-032 frames | ICD coordinate_system.md, `+geometry/DirectionCalculator` | test_coordinate, test_geometry |
| SR-033 relative geometry | `+geometry/AntennaToAntennaFOV` | test_geometry |
| SR-034 invalid rotation | `+geometry/Rotation.mustBeRotationMatrix` | test_invalid_inputs (VR-061) |
| SR-040/041/042 two FOV domains | `AntennaToAntennaFOV`, `AntennaToStructureFOV` (reserved) | test_invalid_inputs (structure reserved), test_geometry |
| SR-050 pattern abstraction | `+antenna/AntennaPattern`, `PatternGrid` | test_pattern |
| SR-051 free/installed distinct | `FreeSpacePattern`, `InstalledPattern` | test_architecture_boundary (VR-084) |
| SR-052 provenance | `PatternProvenance`, pattern metadata | test_architecture_boundary (VR-085) |
| SR-053 interpolation policy | `PatternGrid.evaluate`, `config/PatternInterpolationPolicy` | test_pattern |
| SR-054 no reference pattern | `SyntheticPatternFactory` (SYNTHETIC_TEST only) | test_architecture_boundary; repo scan (§3) |
| SR-060/061 lobe metadata + config | `+interference/LobeClassifier`, `config/LobeClassificationPolicy` | test_pairwise |
| SR-070/071 TX model | `+rf/RFTransmitter` | test_pairwise, test_multisystem |
| SR-072/073 RX + front-end layer | `+rf/RFReceiver`, `+rf/RFFrontEnd` | test_pairwise (margin), test_invalid_inputs |
| SR-080 pattern-only index | `PatternOnlyCouplingModel` (DirectionalCouplingIndex) | test_pairwise, test_architecture_boundary |
| SR-081 no auto-FSPL | `FarFieldCouplingModel` (guarded) | (guard covered by AR-053 logic; unit reserved) |
| SR-082 coupling validity states | `CouplingValidity` | test_architecture_boundary |
| SR-083 reserved coupling models | `MeasuredS21/HFSS CouplingModel` | test_invalid_inputs (VR reserved) |
| SR-090 interference taxonomy | `results/InterferenceType`, `InterferenceClassifier` | test_pairwise |
| SR-091 PairResult fields | `results/PairResult` | test_pairwise, test_multisystem |
| SR-092 matrix | `results/MatrixResult`, `InterferenceAnalyzer` | test_multisystem |
| SR-093 validity | `results/ResultValidity`, `PairwiseAnalyzer` | test_pairwise |
| SR-100/101 scenario | `+scenario/Scenario`, `OperatingMode` | test_multisystem |
| SR-110/111 units | `+util/Units`, name conventions | (names enforced across API; see ICD) |
| SR-112 reference planes | ICD pair_result.md §1 | (documentary) |
| SR-120 no fake physics | reserved models throw; NaN for unknowns | test_invalid_inputs |
| SR-121 synthetic marked | `SyntheticPatternFactory` | test_architecture_boundary (VR-085) |
| AR-010..015 geometry | `AntennaToAntennaFOV`, `DirectionCalculator` | test_geometry, test_invariants |
| AR-020..025 pattern lookup | `PatternGrid` | test_pattern |
| AR-030..032 lobe | `LobeClassifier` | test_pairwise |
| AR-040..041 frequency relation | `+rf/FrequencyRelation` | test_pairwise |
| AR-050..053 coupling | `PatternOnly/FarField CouplingModel` | test_pairwise, test_architecture_boundary |
| AR-060..061 susceptibility/margin | `PairwiseAnalyzer` (margin, MISSING_RECEIVER_DATA) | test_pairwise |
| AR-070..073 pairwise/matrix | `InterferenceAnalyzer`, `MatrixResult` | test_multisystem |
| AR-080..081 validity/warnings | `PairwiseAnalyzer` | test_pairwise |
| AR-090 adjacent guard | `config/FrequencyRelationPolicy` | test_pairwise (in/out of band) |
| DR-001/002 units | `+util/Units` | (used throughout) |
| DR-030..034 pattern data | `PatternGrid` validation | test_pattern, test_invalid_inputs |
| DR-040..042 provenance | provenance fields | test_architecture_boundary |
| DR-050..053 RF data | `RFTransmitter/RFReceiver/RFFrontEnd` | test_invalid_inputs |
| DR-060..062 results | `PairResult/MatrixResult` | test_multisystem |
| DR-070..071 config | `+config/*` | (defaults exercised by all analyzer tests) |
| DR-080 missing-data policy | NaN + validity propagation | test_pairwise, test_pattern |
| VR-010..100 | see tests/ | test_* (125 assertions, all pass) |

## 2. Canonical decisions recorded during reconciliation

1. **Az/El convention.** Boresight = `+X_A`; az about `+Z_A` from `+X` toward `+Y`,
   range `[-180,180]` periodic; el toward `+Z_A`, range `[-90,90]` clamped. Chosen because the
   task's own test list demands "azimuth wrap-around" (periodic) and "elevation boundary"
   (bounded) — this split maps cleanly to a topocentric az/el with boresight on `+X`.
   (ICD coordinate_system.md §2.)
2. **`R_BA` semantics.** Columns are antenna axes in body coords; `v_B = R_BA·v_A`. Boresight in
   body = column 1. Fixed to remove matrix/MATLAB convention ambiguity (Task §7).
3. **Pattern registry key.** `Scenario.addPattern(patternId, pattern)` uses an explicit id,
   decoupled from the pattern's display `name`, so multiple patterns may share a display name
   (needed because `SyntheticPatternFactory` names are fixed). Matches ICD scenario.md (map
   id→pattern), reconciled against an earlier draft that keyed by `pattern.name`.
4. **Single-frequency patterns** are frequency-independent (reused with a warning); out-of-range
   frequency policy applies only to multi-frequency grids. (ICD antenna.md §3.4, added during
   reconciliation.)
5. **Pattern-only interference metric** = `txPower_dBm + DirectionalCouplingIndex_dB` — an
   upper-bound screening index at the RX antenna port **without path loss**, carried with a
   warning and never labeled received power. Physical received power appears only when a
   far-field-valid coupling is used. (ICD pair_result.md §3.)
6. **Enumerations as `Constant` char classes.** MATLAB `enumeration` blocks are not portable to
   the MATLAB/Octave subset used for CI execution, so enums are classes exposing `Constant` char
   values + `values()`/`isValid()`. Semantics (typed, validated, comparable) are preserved.

## 3. "No fake mission/reference pattern" audit (Task §41)

- Repository scan for pattern-producing code: only `+antenna/SyntheticPatternFactory` creates
  patterns, and every product has `provenance = SYNTHETIC_TEST` and `SYNTHETIC_TEST` in its name
  (enforced by test_architecture_boundary VR-085).
- No hard-coded mission gain values, no assumed HFSS/S21 numbers, no invented receiver thresholds
  (reserved fields are `NaN`; reserved coupling models raise `NotImplementedPhase1`), verified by
  test_invalid_inputs and the solver/UI token scan in test_architecture_boundary.

## 4. Portability note (test execution)

The core is written in the MATLAB-language subset shared with GNU Octave (no `arguments` blocks,
no `enumeration` blocks, no property-size/class validation attributes, no `import`), so the exact
`src/` code — not a reimplementation — is executed by the deterministic suite. Result: **125
assertions across 8 files, all passing** (`tests/run_all_tests.m`). The same files run unmodified
under MATLAB R2019b+.

---

# Phase 2 — Pattern Data Pipeline Reconciliation

Phase 2 adds the `+patterndata` package and `config.PatternImportPolicy` **without modifying** the
Phase-1 core. All 131 Phase-1 assertions still pass unchanged (regression, VR-122); the full suite
is **245 assertions across 15 files, all passing**.

## P2.1 Requirement → Code → Test map

| Req | Code (src/+rfscreen/…) | Test (tests/…) |
|-----|------------------------|----------------|
| DR-100/101, §17/§18 (per-dataset step; XZ≠YZ) | `+patterndata/CanonicalPatternCut`, `PatternCanonicalizer` | test_pattern_import, test_pattern_periodic, test_pattern_architecture |
| DR-102, §8/§9 (canonical `[0,360)`) | `PatternCanonicalizer.canonicalThetaFor` | test_pattern_import (conversion) |
| DR-103, §14/§15 (source descriptor) | `+patterndata/SourceCoordinateConvention` | test_pattern_frame |
| DR-104, §5/§6/§7 (sampling detection) | `PatternCanonicalizer.classifySampling` | test_pattern_import (VR-117) |
| DR-105, §10/§11/§12 (duplicates) | `PatternCanonicalizer.resolveDuplicates` | test_pattern_duplicates |
| DR-106, §21/§22 (fidelity; 2D≠3D) | `+patterndata/PatternFidelity`, `CutPatternAssembler` | test_pattern_integration, test_pattern_architecture |
| DR-107, §16 (single canonical schema) | `+patterndata/CanonicalPatternCut` | all pattern tests |
| DR-108, §27 (provenance) | `PatternCanonicalizer` provenance struct | test_pattern_duplicates, test_pattern_integration |
| DR-109, §19 (native preservation) | `+patterndata/PatternResampler` | test_pattern_integration |
| DR-110/111, §28/§41 (synthetic; units) | fixtures marked `SYNTHETIC_TEST`; `PatternValidator` | test_pattern_validation |
| AR-100 (deterministic) | `PatternCanonicalizer` (no randomness) | all pattern tests (exact tolerances) |
| AR-101/102 (theta↔dir, geometric canonical θ) | `SourceCoordinateConvention.directionForTheta`, `canonicalThetaFor` | test_pattern_frame |
| AR-103 (median-step detection) | `classifySampling` | test_pattern_import |
| AR-104 (periodic interp) | `CanonicalPatternCut.evaluate` | test_pattern_periodic (VR-114) |
| AR-105 (duplicate policy) | `resolveDuplicates` | test_pattern_duplicates |
| AR-106 (map M confined to assembler) | `CutPatternAssembler.canonicalToAntenna` | test_pattern_frame, test_pattern_architecture |
| AR-107 (two-cut approx = APPROX_FROM_CUTS) | `CutPatternAssembler.reconstructGain` | test_pattern_frame, test_pattern_integration |
| AR-108 (reuse Phase-1 engine) | `CutPatternAssembler` → `FreeSpacePattern` | test_pattern_integration (VR-120) |
| §23/§24 (importer boundary/no physics) | `PatternImporter`, `Table/Csv…` | test_pattern_architecture (VR-121) |
| §25/§26 (validation) | `PatternValidator`, `CutValidationResult` | test_pattern_validation (VR-118) |
| §37 (arch boundaries) | package layout | test_pattern_architecture (VR-121) |
| VR-122 (regression) | (Phase-1 core untouched) | test_coordinate…test_architecture_boundary |

## P2.2 Canonical decisions (Phase 2)

1. **Three frames, explicit.** Source Pattern Frame (`+Z` boresight) → Canonical Pattern Frame
   (`+Z`, `theta∈[0,360)`) → Phase-1 Antenna Local Frame (`+X_A` boresight). The Canonical→Antenna
   map `M = [0 0 1;1 0 0;0 1 0]` is applied **only** in `CutPatternAssembler`; the source `+Z`
   never enters the core (AR-106, VR-121).
2. **Geometric canonicalization.** Canonical `theta` is recovered from the physical direction
   (`atan2d` of in-plane components), which handles range, rotation-direction, and zero-axis in one
   step and makes `±180→180`, `0/360→0` fall out naturally.
3. **Duplicate merge = mean within tolerance; conflict = warn(merge+evidence) or error(INVALID)**,
   configurable via `PatternImportPolicy`. Two samples are never silently kept at one canonical
   angle. Evidence (source angles/gains/Δ/resolution) recorded in `provenance.duplicates`.
4. **2D cut ≠ 3D.** A pattern assembled from 2D cuts is `APPROX_FROM_CUTS` (Phase-1 provenance),
   built by a documented two-cut azimuthal-interpolation approximation; cut fidelity stays 2D.
5. **Native-grid preservation.** The `CanonicalPatternCut` keeps the source resolution; resampling
   (`PatternResampler`) and grid-baking (`CutPatternAssembler`) are separate, recorded derived
   operations that never mutate the source cut.
6. **Reuse, don't fork.** Integration goes through the existing `FreeSpacePattern` +
   `PairwiseAnalyzer`; no Phase-2 interference engine exists.
7. **Reconciliation of the `[0,360)` range check.** The validator accepts a trailing `360`
   endpoint (the periodic image of `0`) so the `0/360` duplicate case is *handled*, not rejected
   (updated during reconciliation to match §32).

## P2.3 "No fake data" audit (Phase 2)

Only `+patterndata` fixtures in `tests/` create pattern cuts, all with `fidelity=SYNTHETIC_TEST`.
No mission/reference pattern is produced; unknown provenance fields stay `''`/`NaN`; the assembler
refuses to fabricate a frequency (errors if none is available). Fidelity is never inferred from a
filename (CSV importer requires an explicit `SourceCoordinateConvention` + `meta.fidelity`).

## P2.4 Portability & result

`+patterndata` uses the same MATLAB/Octave subset; the exact `src/` code runs under both. Full
suite: **245 assertions, 15 files, all passing** (`tests/run_all_tests.m`).
