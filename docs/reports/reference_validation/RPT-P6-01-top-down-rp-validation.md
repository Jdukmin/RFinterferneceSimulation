# RPT-P6-01 — Top-down RP Validation

Executes each reference case from the **user's** point of view (choose objective → read manual →
build scenario → geometry → antennas → pattern → installation → RF → run → interpret validity →
compare). Every Return Point (RP) found during the top-down runs is listed, classified, resolved
(if justified), regression-tested, and the reference case restarted from the top (§13, §26).

RP classes (§52): `RP-ARCH`, `RP-IMPLEMENTATION`, `RP-DATA`, `RP-DOCUMENTATION`, `RP-VALIDATION`,
`RP-PHYSICS_BOUNDARY`.

## Pre-execution Phase-5 audit (§14)

| Audit | Finding | RP | Resolution | Test |
|-------|---------|----|-----------|------|
| **AUD-01** circular azimuth footprint | A structure straddling the `±180` seam (e.g. behind the antenna) reported a naive az span of ~357° for a true ~6° footprint | **RP-IMPLEMENTATION** | Compute footprint relative to centroid az, wrapped to `[-180,180]`; added `azimuthSpan_deg` (the true small arc); `maxAngularRadius_deg` was already wrap-safe | `test_phase6_audits` (AUD-01) |
| **AUD-02** VERTEX_SAMPLED fidelity | No `EXACT_SURFACE_INTERSECTION` fidelity exists (good); but the sampling false-negative caveat was under-documented | **RP-DOCUMENTATION** | Added the sampling caveat to `spacecraft_geometry.md §4` and the manual (limitations) | `test_phase6_audits` (AUD-02) |
| **AUD-03** installed multi-frequency | `InstalledPattern` (via `PatternGrid`) already supports multiple frequencies; verified the scenario registry preserves them | none (verified) | Added a regression test proving 2 frequencies coexist under one `(antennaId, configId)` | `test_phase6_audits` (AUD-03) |

## Top-down user entry point audit (§12)

| Observation | RP | Resolution |
|-------------|----|-----------|
| Phase-1 `examples/demo_screening.m` existed but there was no single minimal "Input→Run→Result" path a new user could copy, and no per-reference-case runnable script | **RP-DOCUMENTATION / RP-VALIDATION** | Added `examples/quickstart.m` (minimal TX→RX screening) and `examples/reference_cases/rc_kari_0*.m` using only public top-level APIs; documented both in `docs/user_manual.md §10` and §17 | `examples/quickstart.m` executes; all four RC scripts execute |

## Reference-case top-down runs

### RC-KARI-01 (structure FOV)
- **User entry point:** `examples/reference_cases/rc_kari_01_structure_fov.m`.
- **Flow:** build structures (bus box, solar-array panel), antenna install (+Z face), synthetic
  S-band pattern → `AntennaToStructureFOV.analyze` per structure.
- **RP found:** AUD-01 (above) surfaced here first (the bus behind the +Z-boresight antenna). After
  the fix, restarted RC-KARI-01: BUS reports `off-boresight=180°, azSpan≈143°, lobes={BACK}`; solar
  array reports `off-boresight≈22°, lobes={SIDE}`. Deterministic and stable.
- **Final status:** geometry FOV/LOS reproduced (Tier 2); EM RP deformation is `Tier 4`
  (`RP-PHYSICS_BOUNDARY`, expected).

### RC-KARI-02 (installed vs free-space)
- **User entry point:** `rc_kari_02_installed_pattern.m`.
- **RP found (RP-VALIDATION):** the first draft built the installed grid from a *different* base
  formula than the free-space `cosineDirectional`, producing a meaningless 232 dB max-difference.
  **Fix:** derive the installed pattern by **perturbing the free-space pattern's own evaluated
  gains** (−1.5 dB boresight, +4 dB back). Restarted: peak Δ = −1.5 dB, max |Δ| = 2.5 dB, RMS =
  1.71 dB — physically sensible. (This was a reference-script defect, not an engine defect.)
- **Final status:** comparison workflow reproduced (Tier 2–3); axial-ratio/polarization `Tier 4`.

### RC-KARI-03 (installed-location boundary)
- **User entry point:** `rc_kari_03_installation_analysis.m`.
- **RP found:** none new. The case is a deliberate **fidelity-boundary** validation: position (Tier
  1), FOV/LOS (Tier 2) reproduced per candidate location; scattering/reflection/diffraction are
  `Tier 4` (`RP-PHYSICS_BOUNDARY`, expected).

### RC-KARI-RF-01 (S-band → GNSS)
- **User entry point:** `rc_kari_rf_01_gnss_interference.m`.
- **Flow:** GNSS front-end (`ReceiverFrontEnd`), two S-band interferers at the LNA input →
  `CompressionAnalyzer` + `IntermodulationAnalyzer`.
- **RP found:** none. Aggregate drives the LNA past P1dB (margin −20 dB → FAIL); IM3 `2f1−f2 =
  1.575 GHz` lands in the GNSS L1 band, `2f2−f1 = 1.65 GHz` does not. Trend/mechanism reproduced
  (Tier 2); exact dB not fitted (paper hardware values unavailable).

## RP ledger (all found, none hidden — §26)

| RP | Class | Case/audit | Status | Regression after fix |
|----|-------|-----------|--------|----------------------|
| RP-001 | RP-IMPLEMENTATION | AUD-01 circular footprint | **RESOLVED** | 598/598 pass |
| RP-002 | RP-DOCUMENTATION | AUD-02 sampling caveat | **RESOLVED** (doc) | 598/598 pass |
| RP-003 | RP-VALIDATION | AUD-03 multi-freq confirm | **RESOLVED** (test added) | 598/598 pass |
| RP-004 | RP-DOCUMENTATION | no top-level user path | **RESOLVED** (quickstart + RC scripts + manual) | scripts execute |
| RP-005 | RP-VALIDATION | RC-KARI-02 script base-formula mismatch | **RESOLVED** (script) | script output sane |
| RP-006 | RP-PHYSICS_BOUNDARY | RC-01/02/03 full-wave / axial-ratio | **EXPECTED** — documented gap | n/a |

**Final:** all implementation/documentation/validation RPs resolved; all physics-boundary RPs
classified `EXPECTED`. Full regression **598/598 pass** after every fix.
