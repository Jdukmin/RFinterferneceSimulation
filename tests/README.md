# `tests/` — deterministic test suite

Portable harness (`+testutil/Harness.m`) that runs under both MATLAB and GNU Octave. All fixtures
are synthetic and marked `SYNTHETIC_TEST`; no mission/reference pattern data exists.

## Run

```bash
octave-cli --eval "cd('tests'); ok = run_all_tests(); exit(double(~ok))"
```
```matlab
cd tests; ok = run_all_tests();
```

## Files

**Phase 1 (core engine):**
`test_coordinate`, `test_geometry`, `test_pattern`, `test_pairwise`, `test_multisystem`,
`test_invalid_inputs`, `test_invariants`, `test_architecture_boundary`.

**Phase 2 (pattern-data pipeline):**
| File | Covers |
|------|--------|
| `test_pattern_import` | variable step (0.25°/0.5°/1.0°), step detection, `[-180,180]→[0,360)`, ordering, sampling type |
| `test_pattern_duplicates` | `±180` and `0/360` duplicates; equivalent vs conflicting (warn/error) |
| `test_pattern_periodic` | periodic interpolation across `0/360`; independent XZ/YZ steps |
| `test_pattern_frame` | `theta→direction`; source `+Z`→antenna `+X` axis mapping |
| `test_pattern_validation` | empty/NaN/Inf/non-numeric/range/convention/monotonicity checks |
| `test_pattern_integration` | importer→canonical→assembler→**existing** `PairwiseAnalyzer`; CSV; resampler |
| `test_pattern_architecture` | Phase-2 boundary guards (no engine/file-format leakage; 2D≠3D; no global step) |

**Phase 3 (linear RF coexistence):**
| File | Covers |
|------|--------|
| `test_spectrum` | rectangular/tabulated PSD normalization; linear integration (dB linearized) |
| `test_filter` | ideal bandpass, rejection, tabulated dB interpolation, ENBW, boundary clamp |
| `test_spectral_coupling` | overlap full/partial/none/edge; narrow/wide; mixed grids; −3 dB |
| `test_noise` | kTB, bandwidth/temperature scaling, NF, dBm↔W, incomplete/ambiguous refusal |
| `test_in_margin` | I/N cases; margin sign convention (Allowable−Actual) for both criteria |
| `test_susceptibility_validity` | no absolute power without evidence (pattern-only/noise/criterion/filter) |
| `test_rf_coexistence_integration` | scenario → Phase-1 pairwise → Phase-3 susceptibility (absolute + relative) |
| `test_phase3_architecture` | boundaries: no UI/file-parse/geometry; linear-only; screening ≠ criterion |

**Phase 4 (receiver nonlinear):**
| File | Covers |
|------|--------|
| `test_compression` | linear aggregate power; P1dB margin below/at/above; aggregate-above-from-individually-below |
| `test_blocking` | constant/tabulated threshold; below/at/above; in-band + **out-of-band no-overlap** |
| `test_im3` | product frequencies `2f1−f2`/`2f2−f1`; equal/unequal tone power; IIP3↓IM3; third-order scaling; passband |
| `test_nonlinear_validity` | pattern-only/missing-P1dB/IIP3/criterion/front-end withheld; incomplete set |
| `test_nonlinear_scenario` | 2/3 TX→1 RX, multiple RX, inactive/wanted excluded, no self/duplicate IM3 pairs |
| `test_phase4_architecture` | no file-parse/geometry/UI; reuses PairwiseAnalyzer; no dBm sum; no TX-spurious; Phase-3 unchanged |

**Phase 5 (spacecraft structure & installed environment):**
| File | Covers |
|------|--------|
| `test_ray_intersection` | box/panel hit/miss/tangent/boundary/on-surface/inside; rotated structure |
| `test_structure_fov` | boresight/90°/behind, translated/rotated; angular footprint (center-outside-edge-inside) |
| `test_los_blockage` | TX→RX clear/blocked; endpoints excluded; beyond/behind; inactive ignored; zero-length |
| `test_installed_pattern` | selection (prefer/require), explicit fallback, provenance/fidelity, comparison, config association |
| `test_installed_environment_integration` | LOS+FOV+source evidence; installed pattern via existing PairwiseAnalyzer; geometry ≠ gain change |
| `test_phase5_architecture` | no file-parse/receiver-physics/EM-loss/solver; no InstalledPattern from geometry; geometry risk ≠ margin |

**Phase 6:** `test_phase6_audits` (AUD-01..03, promoted reference-case invariants).

**Phase 7 (simplified mission spacecraft baseline):**
| File | Covers |
|------|--------|
| `test_convex_polygon` | exact convex polygon metrics, ray hit/edge/miss/parallel/behind, CW input, invalid polygons |
| `test_simplified_spacecraft` | 6-vertex irregular section + SSOT numbers, panel structures, end-cap ray equivalence, exact antenna positions, assignments/offsets, fixed boresights, KAA hemisphere boundary (0/89.999/90 PASS, >90 FAIL), scenario/LOS/FOV, geometry-only invariants, corrupted-dataset rejection |

| `test_mission_cases` | 6-case catalogue, ISL dataset rows/boresight, per-case functions/patterns/bands/roles, SAR excluded, no RF systems invented, pattern cache, boresight = source CSV, variants/bands differ, pattern-aware FOV leaves gain unchanged, `+mission` boundaries |

**Phase 7d:**
| File | Covers |
|------|--------|
| `test_pattern_freeze` | 41 frozen pattern files byte-stable (CR-stripped SHA-256), no unlisted file, bound patterns frozen, legacy Ka unbound |
| `test_cst_coupling` | S21 table/interpolation/band reduction, CSV + Touchstone import, `CstCouplingModel`, end-to-end through the existing analyzers, architecture guards (`SYNTHETIC_TEST` tables) |
| `test_em_sweep_plan` | grids, analytic cell estimate, feasibility threshold, 8 local + 28 pair models, determinism, CSV export, planning-only guard |
| `test_mission_cases` (extended) | operating modes, receiver front-end data path |

**Phase 8:**
| File | Covers |
|------|--------|
| `test_local_facets` | clipping, finite-facet / edge / plane distances, CST local frame, unsnapped point, radius monotonicity, export |
| `test_rfc_levels` | free-space assumption, preferred coupling, per-pair level table identities and flags, installed-pattern hook (incl. end to end), provisional terminology, CSV |

Note: these files use the real repository datasets `data/spacecraft/simplified_spacecraft_v1/`
(analysis baseline, `USER_DEFINED` provenance), not `SYNTHETIC_TEST` fixtures.

## Status

**1425 assertions across 46 files, all passing** under GNU Octave 9.2.0 (Phase 8b; Phase 8 = 1413; Phase 7d = 1321): the 628
assertions of Phases 1–6 unchanged, plus 25 (`test_convex_polygon`), 264
(`test_simplified_spacecraft`) and 225 (`test_mission_cases`). Earlier: 579 assertions / 35 files (Phases 1–5) and 628 / 36 files
(Phase 6) under Octave 8.4. MATLAB is not available in this environment; MATLAB execution is not
claimed.
