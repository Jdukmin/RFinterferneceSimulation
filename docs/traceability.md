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

---

# Phase 3 — Linear RF Coexistence & Receiver Susceptibility Reconciliation

Phase 3 adds `+spectrum`, `+receiver`, `interference.SpectralCouplingAnalyzer` /
`RfCoexistenceAnalyzer`, and optional `rf` fields — **without changing** the Phase-1 geometric core
or Phase-2 pipeline. All 245 prior assertions still pass (regression, VR-214); full suite is now
**371 assertions across 23 files, all passing**.

## P3.1 Requirement → Code → Test map

| Req | Code (src/+rfscreen/…) | Test (tests/…) |
|-----|------------------------|----------------|
| SR-200/AR-208, §0/§16 (linear RF, Mode B) | `receiver/ReceiverSusceptibilityAnalyzer` | test_rf_coexistence_integration, test_susceptibility_validity |
| SR-201/§3 (spatial≠spectral≠susceptibility) | package split (`+spectrum`, `interference/SpectralCouplingAnalyzer`, `+receiver`) | test_phase3_architecture |
| SR-202/DR-206/§4 (reference planes) | `receiver/ReferencePlane` | test_susceptibility_validity, test_rf_coexistence_integration |
| SR-203/DR-201/§5/§27 (TX spectrum + provenance) | `+spectrum/SpectrumModel`,`RectangularSpectrum`,`TabulatedSpectrum`,`SpectrumProvenance` | test_spectrum |
| SR-204/DR-202/§9/§28 (RX filter + provenance) | `receiver/ReceiverFilter`,`IdealBandpassFilter`,`TabulatedFilterResponse`,`FilterProvenance` | test_filter |
| SR-205/AR-205/§17/§18 (noise kTB) | `receiver/ReceiverNoiseModel`, `util.Constants.boltzmann_JperK` | test_noise |
| SR-206/DR-204/§19 (criterion, not hard-coded) | `receiver/InterferenceCriterion` | test_in_margin |
| SR-207/§16 (two modes) | `receiver/AnalysisMode`, analyzer mode selection | test_susceptibility_validity |
| SR-208/AR-209/§14/§15 (no absolute from pattern-only) | analyzer Mode-A guard | test_susceptibility_validity, test_phase3_architecture |
| SR-209/AR-212/§14 (validity propagates) | `receiver/SusceptibilityValidity`, analyzer precedence | test_susceptibility_validity |
| SR-210/DR-211/§30/§31 (screening ≠ physical) | distinct types (`config.RiskPolicy` vs `receiver.InterferenceCriterion`) | test_phase3_architecture |
| SR-211/AR-203/§7/§8 (linear integration) | `SpectralCouplingAnalyzer` (linear midpoint) | test_spectrum, test_spectral_coupling, test_phase3_architecture |
| SR-212/§24/§46 (nonlinear deferred) | reserved `RFFrontEnd` NaN; no nonlinear code | test_phase3_architecture |
| AR-201/§7 (normalization) | `Rectangular`/`TabulatedSpectrum` | test_spectrum |
| AR-202/§10/§11 (independent grids, union) | `SpectralCouplingAnalyzer` grid build | test_spectral_coupling |
| AR-204/§9 (filter dB→linear) | `ReceiverFilter.responseLinear` | test_filter |
| AR-206/§20 (I/N) | `InterferenceCriterion.evaluate` | test_in_margin |
| AR-207/§21 (margin sign) | `InterferenceCriterion` (Allowable−Actual) | test_in_margin |
| AR-210/§12/§31 (classification ≠ power) | classification untouched; spectral integral separate | test_phase3_architecture |
| AR-211/§17 (ENBW) | `ReceiverFilter.equivalentNoiseBandwidth_Hz` | test_noise (indirect), test_filter |
| AR-213/§13/§26 (reuse Phase-1) | `RfCoexistenceAnalyzer` reuses `InterferenceAnalyzer` | test_rf_coexistence_integration, test_phase3_architecture |
| AR-215/§25 (aggregate reserved) | linear-additive `overlapPower_W`; per-pair result | (design; pairwise-first) |
| DR-209/§32 (optional RF wiring) | `rf.RFTransmitter.spectrum`, `rf.RFReceiver.filter/…` | test_rf_coexistence_integration; Phase-1 regression |
| DR-210/§17 (Boltzmann) | `util.Constants.boltzmann_JperK` | test_noise |
| VR-200…VR-215 | see tests/ | test_spectrum … test_phase3_architecture |

## P3.2 Canonical decisions (Phase 3)

1. **Linear/log boundary.** PSD and filter response are combined in **linear W / linear ratio**;
   `∫ PSD_W·H_lin df` by midpoint rule on a union grid; dB appears only at interfaces via
   `util.Units`. (SR-211, AR-203.)
2. **Reference planes.** TX power/spectrum at `TX_ANTENNA_INPUT`; interference, noise, I/N at
   `RECEIVER_RF_INPUT` (post-preselector, pre-LNA). Every power carries a plane.
3. **Absolute vs relative.** Mode B (absolute) requires physical (far-field-valid) coupling giving
   `absoluteTransfer_dB = Gtx + Grx − FSPL`; pattern-only ⇒ Mode A, `interferencePower_dBm = NaN`,
   validity `ABSOLUTE_COUPLING_UNAVAILABLE`. The central rule (SR-208).
4. **Margin sign (fixed once).** `Margin_dB = Allowable − Actual`; `>0` PASS. Used identically by
   both criterion types.
5. **Noise honesty.** Exactly one of NF(+T0) or Tsys; neither present ⇒ constructor refuses and the
   analyzer reports `NOISE_MODEL_INCOMPLETE` — no invented defaults.
6. **Screening ≠ physical.** `config.RiskPolicy`/`FrequencyRelationPolicy` remain screening; the
   physical acceptance test is `receiver.InterferenceCriterion` (distinct type). `FrequencyRelation`
   classification is metadata and never replaces the spectral integral.
7. **Reuse, not fork.** `RfCoexistenceAnalyzer` layers on the existing Phase-1 matrix; no geometry
   or directional gain is recomputed (AR-213).

## P3.3 Validity-honesty audit (Task §39)

Absolute metrics are withheld, not fabricated, when evidence is insufficient: pattern-only ⇒ no
`P_I`; no noise model ⇒ no I/N (`NOISE_MODEL_INCOMPLETE`); no criterion ⇒ no PASS/FAIL
(`MISSING_CRITERION`); no filter/spectrum ⇒ `MISSING_FILTER`/`MISSING_SPECTRUM`. All verified in
test_susceptibility_validity and test_phase3_architecture. No fake RF hardware values exist; all
fixtures are `SYNTHETIC_TEST`.

## P3.4 Verification result

Octave 8.4: **PASS** — **371 assertions, 23 files** (`tests/run_all_tests.m`), the exact `src/`
code executed. MATLAB: **NOT RUN** (no MATLAB available in this environment); the code stays within
the MATLAB/Octave-common subset used since Phase 1, but MATLAB execution is not claimed.

---

# Phase 4 — Receiver Nonlinear Interference & Multi-Interferer Reconciliation

Phase 4 adds `+nonlinear`, extends `+receiver` (front-end + criteria) and `+results` (nonlinear
result objects), and adds `util.Units.sumPowers_dBm` + optional `rf.RFReceiver` fields — **without
changing** Phase-1/2/3 contracts. All 371 prior assertions still pass (regression, VR-309); full
suite is now **473 assertions across 29 files, all passing**.

> One Phase-3 architecture assertion was *narrowed* during reconciliation: `test_phase3_architecture`
> previously scanned the whole `+receiver` folder for "no nonlinear physics" (true in Phase 3).
> Phase 4 intentionally adds nonlinear **criteria** to `+receiver` and physics to `+nonlinear`, so
> that guard is now scoped to the Phase-3 **linear** analyzer file, where the guarantee still holds.
> This is a documented intentional evolution, not a defect.

## P4.1 Requirement → Code → Test map

| Req | Code (src/+rfscreen/…) | Test (tests/…) |
|-----|------------------------|----------------|
| SR-300/AR-300, §0/§4 (nonlinear from valid absolute) | `nonlinear/NonlinearSusceptibilityAnalyzer`, `receiver/ReceiverFrontEnd` | test_nonlinear_scenario, test_nonlinear_validity |
| SR-301/§3 (linear≠nonlinear; single≠multi; TX≠RX) | package split `+nonlinear` vs `+receiver`/Phase-3 | test_phase4_architecture |
| SR-302/§5 (LNA_INPUT plane) | `receiver/ReferencePlane.LNA_INPUT` | test_compression, test_im3, test_phase4_architecture |
| SR-303/§6 (front-end input-referred) | `receiver/ReceiverFrontEnd`, `FrontEndProvenance` | test_phase4_architecture, test_nonlinear_validity |
| SR-304/AR-302/§7 (P1dB margin) | `nonlinear/CompressionAnalyzer`, `receiver/CompressionCriterion` | test_compression |
| SR-305/AR-301/§8 (linear aggregate) | `util.Units.sumPowers_dBm`, `nonlinear/InterfererAggregator` | test_compression, test_phase4_architecture |
| SR-306/§9/§10 (aggregate scope + completeness) | `InterfererAggregator`, analyzer validity | test_nonlinear_validity |
| SR-307/AR-303/§11/§14 (blocking ≠ overlap) | `nonlinear/BlockingAnalyzer`, `receiver/BlockingCriterion` | test_blocking, test_phase4_architecture |
| SR-308/§12/§13 (blocking criterion + margin) | `receiver/BlockingCriterion` | test_blocking |
| SR-309/AR-304/AR-305/§15-§18 (IM3 freq + power) | `nonlinear/IntermodulationAnalyzer`, `receiver/ProductType` | test_im3 |
| SR-310/AR-307/§19/§20 (passband relevance) | `IntermodulationAnalyzer` (channel filter reuse) | test_im3 |
| SR-311/§23 (IM2 not fabricated) | `NonlinearSusceptibilityResult.im2='NOT_IMPLEMENTED'` | test_nonlinear_scenario |
| SR-312/AR-308/AR-310/§24-§27 (scenario multi-interferer; reuse; no self/dup) | `NonlinearSusceptibilityAnalyzer` | test_nonlinear_scenario |
| SR-313/§28/§40 (distinct criteria; screening≠physics) | 3 criterion classes; Phase-3 policies untouched | test_phase4_architecture |
| SR-314/DR-300/§29/§30 (provenance; no defaults) | `ReceiverFrontEnd` (NaN unknowns), `FrontEndProvenance` | test_nonlinear_validity, test_phase4_architecture |
| SR-315/DR-305/§31 (validity codes) | `receiver/NonlinearValidity` | test_nonlinear_validity |
| SR-316/§38/§41-§43 (Phase-3 unchanged; TX/mixer/ADC deferred) | separate result objects; no TX/mixer/ADC code | test_phase4_architecture, regression |
| AR-306/§36 (third-order scaling) | `IntermodulationAnalyzer` formula | test_im3 |
| VR-300…VR-309 | see tests/ | test_compression … test_phase4_architecture |

## P4.2 Canonical decisions (Phase 4)

1. **Signal chain / reference plane.** `RX_ANTENNA_TERMINAL → preselector → LNA_INPUT (nonlinear
   plane) → LNA → channel filter`. All P1dB/IIP3 are **input-referred** to `LNA_INPUT`;
   `OIP3=IIP3+G`, `P1dB_out=P1dB_in+G−1` are explicit conversions.
2. **Per-interferer power.** `P_lna,i = txPower_i + (Gtx+Grx−FSPL)_i + H_pre_dB(f_i)`, absolute
   only for far-field-valid coupling; pattern-only ⇒ `NaN`.
3. **Aggregate.** Linear sum over valid interferers via `sumPowers_dBm`; missing ≠ zero; any
   invalid active interferer ⇒ `INCOMPLETE_INTERFERER_SET`; none valid ⇒
   `ABSOLUTE_COUPLING_UNAVAILABLE`.
4. **Compression.** `Margin = P1dB_in − P_agg` (`>0` below P1dB).
5. **Blocking.** Per interferer by frequency offset, **independent of spectral overlap**;
   `Margin = allowable(offset) − P_lna,i`; constant or tabulated criterion.
6. **IM3.** Products `2f1−f2`, `2f2−f1` exact; `P_IM3,in = 2P_a+P_b−2·IIP3` (unequal-tone general,
   equal `3P−2·IIP3`); effective power via channel filter at `f_IM`; unordered `i<j` pairs, no
   self/duplicate.
7. **Reuse.** Scenario analysis reuses `PairwiseAnalyzer`; no geometry/gain recompute.
8. **Sign convention** everywhere `Margin = Allowable − Actual` (consistent with Phase 3).

## P4.3 Validity-honesty audit (Task §4, §10, §30)

Withheld, never fabricated: pattern-only ⇒ no compression/blocking/IM3; missing P1dB ⇒
`MISSING_P1DB`; missing IIP3 ⇒ `MISSING_IIP3` (no products); missing blocking criterion ⇒
`MISSING_BLOCKING_CRITERION`; missing front end ⇒ `MISSING_FRONT_END`; partial evidence ⇒
`INCOMPLETE_INTERFERER_SET`. Verified in test_nonlinear_validity and test_phase4_architecture. No
fake P1dB/IIP3/blocking/gain/IM3 values; all fixtures `SYNTHETIC_TEST`. IM2, TX spurious, mixer
spurs, and ADC saturation are not generated.

## P4.4 Verification result

Octave 8.4: **PASS** — **473 assertions, 29 files** (`tests/run_all_tests.m`), the exact `src/`
code executed. MATLAB: **NOT RUN** (unavailable in this environment; not claimed).
