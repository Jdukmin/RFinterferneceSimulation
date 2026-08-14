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

> **Phase 1 (complete).** Requirements, ICD, and a deterministic **core RF interference engine**
> independent of any real antenna reference pattern.
>
> **Phase 2 (complete).** A deterministic **antenna-pattern data ingestion & canonicalization
> pipeline** (`+patterndata`) that accepts real external 2D antenna cut data with different angular
> resolutions and coordinate conventions, normalizes it into one internal representation, and feeds
> the **unchanged** Phase-1 screening core. See `docs/icd/pattern_data.md`.
>
> **Phase 3 (complete).** A deterministic **linear RF coexistence & receiver-susceptibility**
> engine (`+spectrum`, `+receiver`): TX spectrum × RX filter spectral coupling (linear
> integration), receiver kTB noise, I/N, and an explicit interference-margin criterion — with
> absolute RF power produced **only** when physical coupling evidence exists. See
> `docs/icd/spectrum.md`, `docs/icd/receiver_susceptibility.md`.
>
> **Phase 4 (complete).** Receiver **front-end nonlinear** susceptibility (`+nonlinear`,
> `+receiver`): multi-interferer aggregate compression (P1dB), blocking (independent of spectral
> overlap), and two-tone third-order intermodulation (IIP3 → IM3), all input-referred to the
> `LNA_INPUT` plane and produced **only** with valid absolute coupling evidence. See
> `docs/icd/receiver_nonlinear.md`.
>
> HFSS/CST/measured-S21 coupling import, true installed-pattern generation, **transmitter**
> nonlinearities (HPA/IMD/spurious/harmonics), receiver **mixer spur** tables, and **ADC
> saturation** plus any UI remain **deferred to Phase 5+** (see `docs/traceability.md` and ICD
> extension points).

## Phase 4 — receiver nonlinear at a glance

- **Central invariant.** No valid absolute coupling ⇒ no authoritative nonlinear result; no
  nonlinear hardware data ⇒ unsupported, never fabricated.
- **Reference plane.** All P1dB/IIP3 are **input-referred** to `LNA_INPUT` (after preselector,
  before LNA); the signal chain is explicit.
- **Aggregate compression.** `Margin = P1dB_in − ΣP_i` with interferer powers summed in the
  **linear** domain (dBm never added); missing interferers are not treated as zero.
- **Blocking.** Per-interferer, by frequency offset, **independent of spectral overlap**
  (`NO_OVERLAP ≠ NO_BLOCKING_RISK`); constant or tabulated allowable-blocker criterion.
- **IM3.** Two-tone products `2f1−f2`, `2f2−f1` with `P_IM3,in = 2P_a+P_b−2·IIP3` (equal-tone
  `3P−2·IIP3`), evaluated for receiver-passband relevance.
- **Reuse.** Scenario analysis gathers all active interferers to one RX and reuses the Phase-1
  pairwise engine — no geometry recompute, no duplication.

## Phase 3 — linear RF coexistence at a glance

- **Two modes.** *Relative screening* (directional + spectral overlap, no fake absolute power) and
  *absolute linear RF* (only with physical/far-field-valid coupling). The pattern-only
  DirectionalCouplingIndex is **never** promoted to an absolute link loss.
- **Separated concerns.** Spatial coupling (Phase-1) ≠ spectral coupling (`SpectralCouplingAnalyzer`)
  ≠ receiver susceptibility (`ReceiverSusceptibilityAnalyzer`).
- **Linear integration.** TX PSD (W/Hz) × RX filter (linear ratio) integrated over a deterministic
  union grid; dB is never summed. TX and RX may use independent frequency grids.
- **Noise / I/N / margin.** `N = kTB` (NF or system temperature), `I/N = P_I − N`, and
  `Margin = Allowable − Actual` (`>0` PASS), all referenced to `RECEIVER_RF_INPUT`.
- **Honest validity.** Missing noise → no I/N; missing criterion → no PASS/FAIL; pattern-only → no
  absolute power. Nothing is invented.

## Phase 2 — external pattern input at a glance

- **Source convention:** boresight `+Z`; 2D `XZ`/`YZ` gain cuts; `theta` from `+Z`; angle range
  `[-180,180]` or `[0,360)`; deg / dBi. Declared per dataset via a `SourceCoordinateConvention`
  descriptor — never hard-coded.
- **Variable step:** each pattern (and each of its XZ/YZ cuts) keeps its **own** angular step
  (0.25° / 0.5° / 1.0° …). No global step or sample count is assumed.
- **Canonicalization:** angles normalized to `0 ≤ theta < 360`, sorted; `±180→180`, `0/360→0`
  resolved deterministically (mean-merge within tolerance; conflicts warn or error per policy).
- **Periodic interpolation** across `0/360`; native resolution preserved in `CanonicalPatternCut`.
- **Bridge to core:** `CutPatternAssembler` builds a `FreeSpacePattern` labeled
  `APPROX_FROM_CUTS` (a documented two-cut approximation — never relabeled true 3D) that the
  existing `PairwiseAnalyzer` consumes unchanged. The source `+Z` boresight reaches the antenna
  frame only through the explicit map `M` in the assembler.

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
  +patterndata                 [Phase 2] external 2D-cut ingestion & canonicalization
  +spectrum +receiver          [Phase 3] TX spectrum, RX filter/noise/criterion, susceptibility
  +nonlinear                   [Phase 4] compression, blocking, IM3, multi-interferer aggregation
tests/                         Deterministic test suite + portable harness
examples/demo_screening.m      Console demo (synthetic data only, no UI)
setup_paths.m                  Adds src/ to the path
```

See `src/README.md` and `tests/README.md` for package-level detail.

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

Current status: **473 deterministic assertions across 29 test files, all passing** (131 Phase-1 +
114 Phase-2 + 126 Phase-3 + 102 Phase-4), under **GNU Octave 8.4** (MATLAB not available in this
environment, so MATLAB execution is not claimed). Covers geometry, pattern interpolation, pairwise
screening, the Phase-2 ingestion pipeline, the Phase-3 linear RF chain (spectrum/filter/noise/I-N/
margin), and the Phase-4 nonlinear chain: linear-domain aggregate power, P1dB compression margin,
blocking (in-band, out-of-band, tabulated, no-overlap), two-tone IM3 frequencies/power/third-order
scaling, multi-interferer scenario enumeration, validity honesty (no nonlinear result without
absolute evidence or hardware data), and Phase-4 architecture boundaries.

## Quick demo

```matlab
run('examples/demo_screening.m')   % prints a synthetic interference matrix
```

## Canonical units & frames (see `docs/icd/`)

Position m · frequency Hz · power dBm · gain dBi · loss dB · public az/el deg.
Frames: Spacecraft Body (B), Antenna Local (A, boresight `+X_A`), Pattern (P ≡ A in Phase 1).
Orientation is a DCM `R_BA` (antenna→body), `v_B = R_BA·v_A`.
