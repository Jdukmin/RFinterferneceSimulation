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

## Status

**473 assertions across 29 files, all passing** (131 Phase-1 + 114 Phase-2 + 126 Phase-3 + 102
Phase-4) under GNU Octave 8.4. MATLAB is not available in this environment; MATLAB execution is not
claimed.
