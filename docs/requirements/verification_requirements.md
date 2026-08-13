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
