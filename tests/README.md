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

## Status

**245 assertions across 15 files, all passing** (131 Phase-1 regression + 114 Phase-2).
