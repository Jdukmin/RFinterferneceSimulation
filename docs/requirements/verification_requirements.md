# Verification Requirements

**Phase:** 1. Defines how the Phase-1 deliverables are verified: deterministic numeric tests,
architecture-boundary tests, and docs/code consistency. Maps tests to requirements.

---

## 1. Verification Approach

- **VR-001 (SHALL)** All Phase-1 core computations shall be covered by **deterministic** tests
  (fixed inputs, exact/tolerance-checked outputs). *(Task §33, §34)*
- **VR-002 (SHALL)** Tests shall be runnable without any external EM solver, UI, or network, and
  without proprietary MATLAB toolboxes. *(Task §35)*
- **VR-003 (SHALL)** The test suite shall run under the MATLAB-language subset shared by MATLAB
  and GNU Octave, using a self-contained assertion/runner harness (`tests/run_all_tests.m`).
  *(portability; enables execution in CI without MATLAB)*
- **VR-004 (SHALL)** A test shall be considered a *return point*: on failure — diagnose, fix,
  targeted re-test, full regression. *(Task §43)*

## 2. Geometry Tests (maps AR-010…AR-015, AR-031)

- **VR-010 (SHALL)** same-axis antennas (boresights aligned along the connecting line).
- **VR-011 (SHALL)** opposite-facing antennas.
- **VR-012 (SHALL)** 90°-rotated antenna.
- **VR-013 (SHALL)** translated antenna (pure position change).
- **VR-014 (SHALL)** arbitrary body-frame installation (compound rotation + translation).

## 3. Coordinate Tests (maps AR-014, SR-034)

- **VR-020 (SHALL)** Body → Local transform correctness.
- **VR-021 (SHALL)** Local → Body transform correctness.
- **VR-022 (SHALL)** round-trip `v ≈ R_AB·R_BA·v` within tolerance.
- **VR-023 (SHALL)** direction anti-symmetry `d_AB = −d_BA`; distance symmetry.

## 4. Pattern Tests (maps AR-020…AR-025)

- **VR-030 (SHALL)** exact grid-node lookup returns stored value.
- **VR-031 (SHALL)** interpolation between nodes (bilinear) matches hand-computed value.
- **VR-032 (SHALL)** azimuth wrap-around (e.g., −180° ≡ +180°) consistency.
- **VR-033 (SHALL)** elevation boundary clamp behavior.
- **VR-034 (SHALL)** missing/out-of-range frequency → documented behavior (no silent value).

## 5. Pairwise Analysis Tests (maps AR-050, AR-070, AR-030)

- **VR-040 (SHALL)** main-beam to main-beam pair.
- **VR-041 (SHALL)** main to side.
- **VR-042 (SHALL)** side to side.
- **VR-043 (SHALL)** back to main.

## 6. Multiple-System Tests (maps AR-070, AR-071)

- **VR-050 (SHALL)** N transmitters × M receivers → N·M ordered pairs generated.
- **VR-051 (SHALL)** matrix keys and dimensions correct; self/diagonal handled as `NA`.

## 7. Invalid-Input Tests (maps SR-022, SR-034, AR-025)

- **VR-060 (SHALL)** missing pattern → clear error/validity.
- **VR-061 (SHALL)** invalid rotation matrix → rejected.
- **VR-062 (SHALL)** frequency outside supported range → documented behavior.
- **VR-063 (SHALL)** NaN inputs → rejected/flagged, never silently propagated as valid.
- **VR-064 (SHALL)** duplicate antenna/system ID → rejected.

## 8. Numerical Invariants (maps AR-012…AR-014, AR-002)

- **VR-070 (SHALL)** `distance(A,B) == distance(B,A)`.
- **VR-071 (SHALL)** `d_AB == −d_BA`.
- **VR-072 (SHALL)** rotation round-trip within tolerance.
- **VR-073 (SHALL)** pattern lookup deterministic (repeat calls identical).

## 9. Architecture-Boundary Tests (maps SR-013, SR-003, SR-011, SR-051, DR-040)

- **VR-080 (SHALL)** Core has no dependency on UI (no UI symbols referenced by `+src` packages).
- **VR-081 (SHALL)** Core has no dependency on HFSS/CST/solver at run time.
- **VR-082 (SHALL)** `PatternOnlyCouplingModel` result advertises coupling type `PATTERN_ONLY`
  and *not* `MEASURED_S21` (it does not pretend to be measured coupling).
- **VR-083 (SHALL)** `Antenna` (hardware) does not own installation geometry (no
  position/orientation fields on `Antenna`).
- **VR-084 (SHALL)** `FreeSpacePattern` and `InstalledPattern` remain distinguishable
  (distinct classes; installed carries a source).
- **VR-085 (SHALL)** Synthetic test patterns are identifiable as such (`provenance =
  SYNTHETIC_TEST`) and cannot be mistaken for reference/mission data.

## 10. Docs/Code Consistency (maps Task §8, §36)

- **VR-090 (SHALL)** After implementation, requirements, ICD, code, tests, and `reference.md`
  shall be reconciled; any divergence resolved by an explicit canonical decision, documented in
  `docs/traceability.md`. *(Task §36)*
- **VR-091 (SHALL)** Each SR/AR/DR requirement shall map to at least one test or a documented
  deferral. *(Task §41)*

## 11. Pass Criteria

- **VR-100 (SHALL)** Phase 1 verification passes when: all VR-0xx tests pass, all
  architecture-boundary tests pass, no fake mission/reference pattern exists in the repo, and the
  traceability matrix shows no unreconciled divergence. *(Task §41)*

## 12. Pattern-Data Pipeline Verification (Phase 2)

Maps DR-100…DR-111, AR-100…AR-108. Deterministic, synthetic (`SYNTHETIC_TEST`) fixtures only.

- **VR-110 (SHALL)** Variable angular step: independent fixtures at 0.25°, 0.5°, 1.0° each detect
  their own step, sample count, and interpolate correctly — no global-step assumption. *(§29)*
- **VR-111 (SHALL)** `[-180,180] → [0,360)` conversion + ordering; explicitly `−90→270`,
  `−180→180`, `180→180`. *(§30)*
- **VR-112 (SHALL)** `±180` duplicate: equivalent values collapse to one `180°` sample (VALID);
  conflicting values yield warning/INVALID per policy, with evidence — never silent. *(§31)*
- **VR-113 (SHALL)** `0/360` duplicate resolves deterministically to a single `0°` sample. *(§32)*
- **VR-114 (SHALL)** Periodic interpolation across `359.x° / 0° / 0.x°` is continuous. *(§34)*
- **VR-115 (SHALL)** One antenna with XZ step 0.25° and YZ step 1.0° coexists without forced
  global resampling. *(§33)*
- **VR-116 (SHALL)** Source-frame axis mapping: boresight, `±X`, `±Y`, back map to the documented
  antenna `(az,el)` (ICD `pattern_data.md` §1.2). *(§35)*
- **VR-117 (SHALL)** Sampling classification: `UNIFORM` vs `NON_UNIFORM` vs `INVALID` detected
  explicitly. *(§7)*
- **VR-118 (SHALL)** Validation detects empty/NaN/Inf/non-numeric/duplicate/inconsistent-step/
  non-monotonic/unsupported-range/unsupported-unit/missing-plane/missing-provenance. *(§25)*
- **VR-119 (SHALL)** Provenance + fidelity preserved end-to-end; a 2D cut is never labeled true
  3D; assembled 3D is `APPROX_FROM_CUTS`. *(§21, §27)*
- **VR-120 (SHALL)** Integration: synthetic external-style cuts → importer → canonical →
  `FreeSpacePattern` → **existing** `PairwiseAnalyzer` → `PairResult`. *(§36)*
- **VR-121 (SHALL)** Architecture-boundary (Phase 2): importer has no interference-engine
  dependency; canonical pattern has no file-format dependency; core does not parse files; pattern
  object assumes no global fixed step; duplicate periodic endpoints never silently retained;
  source `+Z` convention does not overwrite internal frame contracts. *(§37)*
- **VR-122 (SHALL)** All Phase-1 regression tests (131 assertions) still pass unchanged. *(§43)*

## 13. Linear RF Coexistence Verification (Phase 3)

Synthetic (`SYNTHETIC_TEST`), analytically predictable fixtures.

- **VR-200 (SHALL)** Rectangular PSD normalization: `∫ PSD df = P_total` (linear). *(§33)*
- **VR-201 (SHALL)** Linear-domain integration evidence (dB values not summed). *(§8)*
- **VR-202 (SHALL)** Different TX/RX grid resolutions integrate consistently. *(§33, §35)*
- **VR-203 (SHALL)** Spectral overlap: full, partial, none, edge-touching. *(§33, §35)*
- **VR-204 (SHALL)** Filter: 0 dB passband, finite rejection, tabulated interpolation, TX/RX grid
  mismatch, boundary interpolation. *(§34)*
- **VR-205 (SHALL)** Spectral coupling: TX inside / partially inside / outside RX passband;
  narrow-TX/wide-RX; wide-TX/narrow-RX; different sample steps. *(§35)*
- **VR-206 (SHALL)** Noise: kTB, bandwidth scaling, temperature scaling, NF handling, dBm↔W. *(§36)*
- **VR-207 (SHALL)** I/N cases (e.g. `I=-120, N=-110 ⇒ -10 dB`). *(§37)*
- **VR-208 (SHALL)** Margin sign: with `I/N ≤ -6`, actual `-10→+4`, `-6→0`, `-3→-3`. *(§38)*
- **VR-209 (SHALL)** Validity: pattern-only ⇒ no absolute `P_I`; missing noise ⇒ no I/N; missing
  criterion ⇒ no PASS/FAIL; missing filter ⇒ degraded. *(§39)*
- **VR-210 (SHALL)** Phase-3 reuses Phase-1 coupling; no geometry recompute. *(§13, §42)*
- **VR-211 (SHALL)** Screening policy (`RiskPolicy`) ≠ physical `InterferenceCriterion`. *(§30, §42)*
- **VR-212 (SHALL)** `FrequencyRelation` classification ≠ spectral power. *(§31, §42)*
- **VR-213 (SHALL)** Architecture boundaries: spectrum has no UI; receiver does not parse antenna
  pattern files; spectral analyzer computes no geometry; dB values are not integrated directly;
  pattern-only index is not mislabeled absolute coupling loss; nonlinear receiver models remain
  unimplemented. *(§42)*
- **VR-214 (SHALL)** All 245 existing Phase-1/2 assertions still pass unchanged. *(§40)*
- **VR-215 (SHALL)** End-to-end coexistence: scenario → Phase-1 pairwise → Phase-3 susceptibility
  → absolute result (far-field) and relative result (pattern-only). *(§16, §26)*
