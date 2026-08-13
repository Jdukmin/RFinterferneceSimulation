# Spacecraft RF Coexistence & Antenna Interference Screening Tool

MATLAB-based **early-design screening** tool that identifies risky RF system pairs among
multiple antennas installed on a spacecraft, using installation geometry, radiation patterns,
and TX/RX RF characteristics. It **feeds** full-wave EM solvers (HFSS/CST) and EMC/measurement
verification — it does **not** replace them.

```
Antenna installation geometry + radiation pattern + TX/RX RF characteristics
        -> spatial / pattern coupling  (screening)
        -> pairwise interference matrix
        -> high-risk pair identification
        -> HFSS / measurement verification
```

> **Phase 1 scope.** Requirements, ICD, and a deterministic **core RF interference engine** that
> is independent of any real antenna reference pattern. Actual reference/installed pattern
> generation, HFSS/CST/measured-S21 coupling import, detailed nonlinear receiver interference,
> and any UI are **deferred** to later phases (see `docs/traceability.md` §3 and the ICD
> extension points).

## Repository layout

```
docs/
  reference.md                 Mandatory reference review + architecture implications
  architecture.md              Package/dependency structure (validated by boundary tests)
  traceability.md              Requirement -> code -> test map; canonical decisions
  requirements/                system / analysis / data / verification requirements
  icd/                         Interface Control Documents (normative)
src/+rfscreen/                 Core engine (MATLAB packages)
  +util +geometry +antenna +rf +coupling +config +scenario +results +interference
tests/                         Deterministic test suite + portable harness
examples/demo_screening.m      Console demo (synthetic data only, no UI)
setup_paths.m                  Adds src/ to the path
```

## Core principles (from `docs/reference.md`)

1. **Screening ≠ coupling.** Pattern/FOV screening is an early indicator; real coupling is
   S21/HFSS/CST/measurement, integrated later behind the `CouplingModel` boundary.
2. **Six separated concerns:** Geometry · Pattern · Coupling · RF System · Receiver
   Susceptibility · Interference Decision.
3. **Hardware ≠ installation**; **free-space pattern ≠ installed pattern** (both carry provenance).
4. **Near-field caution:** FSPL is never auto-applied to short on-platform separations.
5. **No fake physics:** unknowns are `NaN`/reserved interfaces, never invented numbers.
6. **Explicit units, frames, reference planes** (fixed in the ICD).

## Running the tests

The core is written in the MATLAB-language subset shared with **GNU Octave**, so the exact
`src/` code runs unmodified under both.

```bash
# GNU Octave (CI / no MATLAB license needed)
octave-cli --eval "cd('tests'); ok = run_all_tests(); exit(double(~ok))"
```

```matlab
% MATLAB
cd tests
ok = run_all_tests();
```

Current status: **125 deterministic assertions across 8 test files, all passing**, including
geometry, coordinate transforms, pattern interpolation, pairwise lobe analysis, N×M matrix
generation, invalid-input rejection, numerical invariants, and **architecture-boundary** tests
(no UI/solver dependency, pattern-only coupling ≠ measured S21, hardware owns no installation
geometry, free/installed distinguishable, synthetic data unmistakable).

## Quick demo

```matlab
run('examples/demo_screening.m')   % prints a synthetic interference matrix
```

## Canonical units & frames (see `docs/icd/`)

Position m · frequency Hz · power dBm · gain dBi · loss dB · public az/el deg.
Frames: Spacecraft Body (B), Antenna Local (A, boresight `+X_A`), Pattern (P ≡ A in Phase 1).
Orientation is a DCM `R_BA` (antenna→body), `v_B = R_BA·v_A`.
