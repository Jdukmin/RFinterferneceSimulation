# User Manual — Spacecraft RF Coexistence & Antenna Interference Screening Tool

> **Read this first.** This tool is an **early-design screening** aid. It tells you *which*
> antenna pairs and installed geometries are worth a full electromagnetic (EM) study — it does
> **not** replace HFSS/CST/measurement. It computes geometry, radiation-pattern lookups, and
> textbook linear/nonlinear RF relations. It never fabricates coupling, isolation, installed
> patterns, or full-wave EM results. When it does not have the evidence to answer, it returns an
> explicit `UNKNOWN`/`UNAVAILABLE`/`MISSING_*` state instead of a made-up number — and that is a
> feature, not a defect.

**Audience:** a spacecraft/antenna/RF engineer who wants to screen on-platform RF interference
without first reading the ICD. Every code block below is copied from a script that actually runs
under GNU Octave 8.4 (and the same MATLAB/Octave-common subset under MATLAB R2019b+).

---

## Table of contents

1. [What problem this solves](#1-what-problem-this-solves)
2. [What it does NOT solve](#2-what-it-does-not-solve)
3. [Fidelity levels & reproducibility tiers](#3-fidelity-levels--reproducibility-tiers)
4. [Install & run](#4-install--run)
5. [Quick start (Input → Run → Result)](#5-quick-start-input--run--result)
6. [Inputs you provide](#6-inputs-you-provide)
7. [Coordinate conventions](#7-coordinate-conventions)
8. [Radiation-pattern format](#8-radiation-pattern-format)
9. [Spacecraft geometry & structures](#9-spacecraft-geometry--structures)
10. [RF systems: transmitters & receivers](#10-rf-systems-transmitters--receivers)
11. [Building a scenario](#11-building-a-scenario)
12. [Antenna-to-antenna screening](#12-antenna-to-antenna-screening)
13. [Structure field-of-view (FOV) & line-of-sight](#13-structure-field-of-view-fov--line-of-sight)
14. [Linear RF coexistence (I/N)](#14-linear-rf-coexistence-in)
15. [Nonlinear receiver interference (P1dB, blocking, IM3)](#15-nonlinear-receiver-interference-p1db-blocking-im3)
16. [Free-space vs installed patterns](#16-free-space-vs-installed-patterns)
17. [Interpreting results & validity states](#17-interpreting-results--validity-states)
18. [Known limitations (read before trusting a number)](#18-known-limitations-read-before-trusting-a-number)
19. [Reference-case examples (KARI reproduction)](#19-reference-case-examples-kari-reproduction)
20. [Troubleshooting](#20-troubleshooting)

---

## 1. What problem this solves

On a spacecraft, many antennas share one small structure. Before committing to an expensive
full-wave study, you want fast, deterministic answers to:

- Which **TX→RX antenna pairs** point at each other or share a frequency band (spatial + spectral
  screening)?
- Does spacecraft **structure fall inside an antenna's field of view**, or block its line of
  sight to another antenna (geometry evidence)?
- Could a strong nearby transmitter **saturate a receiver's LNA** or generate **intermodulation
  products** that land in a protected band (nonlinear RF)?
- How does an **installed** radiation pattern differ from the free-space one (comparison, when you
  supply the installed data)?

The tool answers these as a **screening matrix** so you can rank pairs and geometries for a later
high-fidelity EM analysis.

## 2. What it does NOT solve

This is the single most important section. The tool **does not**:

- Compute **full-wave EM**: no scattering, reflection, diffraction, or creeping waves.
- Derive an **installed pattern from geometry** — an installed pattern is *supplied* (measured or
  simulated), never manufactured from a structure intersection.
- Produce **absolute antenna-to-antenna coupling / isolation (S21)** from patterns alone. A
  pattern-only result is a *relative screening index*, not a dB isolation.
- Model **axial ratio / polarization mismatch** as an installed effect.
- **Fit** any published paper's numbers. If the model gives Y and a paper reports X, the difference
  is *classified*, never corrected by an additive fudge.
- Auto-apply **free-space path loss (FSPL)** at on-platform (potentially near-field) separations.

When any of these is required, the tool reports a **Tier-4 boundary** (see §3) and names the model
gap (`MODEL_GAP_FULL_WAVE`, `MODEL_GAP_AXIAL_RATIO`, …). That is the correct answer, not a failure.

## 3. Fidelity levels & reproducibility tiers

Results are labelled by how well they can be trusted against real EM evidence:

| Tier | Meaning | Example |
|------|---------|---------|
| **Tier 1** | Exact/deterministic within the tool's domain | Installation position, distance |
| **Tier 2** | Trend/mechanism reproducible (geometry, direction, in/out-of-band) | Structure enters FOV; IM3 product lands in-band |
| **Tier 3** | Workflow reproducible; magnitude depends on supplied data | Free↔installed pattern comparison deltas |
| **Tier 4** | **NOT reproducible without external EM evidence** — a declared boundary | Full-wave gain deformation, axial ratio |

**Tier 4 is not a bug.** It marks where physics leaves this tool's domain and enters a full-wave
solver's. The tool's job is to reach the boundary honestly and stop.

## 4. Install & run

No build step, no toolbox dependency for the core. You need GNU Octave 8.4+ or MATLAB R2019b+.

```
octave-cli --eval "addpath('src'); addpath('examples'); quickstart"
```

Every example script adds `src/` to the path itself, so from the repo root you can also just run
`octave-cli --eval "addpath('examples'); quickstart"`. To run the full deterministic test suite:

```
octave-cli --eval "cd tests; run_all_tests"
```

## 5. Quick start (Input → Run → Result)

The minimal path — a TX and an RX on a spacecraft body, screened for pattern/geometry coupling.
This is the exact body of [`examples/quickstart.m`](../examples/quickstart.m):

```matlab
sc = rfscreen.scenario.Scenario('QUICKSTART');

% antenna radiation patterns (synthetic, clearly marked SYNTHETIC_TEST)
fc = 2.2e9;                                   % S-band
sc.addPattern('PAT_TX', rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(12, fc, 2));
sc.addPattern('PAT_RX', rfscreen.antenna.SyntheticPatternFactory.cosineDirectional(8,  fc, 2));

Role = rfscreen.antenna.Role; Pol = rfscreen.antenna.Polarization;
sc.addAntenna(rfscreen.antenna.Antenna('ANT_TX','TX antenna', Role.TX, 1e9, 4e9, Pol.RHCP, 'PAT_TX','ANT_TX'));
sc.addAntenna(rfscreen.antenna.Antenna('ANT_RX','RX antenna', Role.RX, 1e9, 4e9, Pol.RHCP, 'PAT_RX','ANT_RX'));

% installation geometry: TX at origin facing +X; RX 1.5 m away facing back at TX
sc.addInstallation(rfscreen.antenna.AntennaInstallation('ANT_TX', [0;0;0], eye(3)));
sc.addInstallation(rfscreen.antenna.AntennaInstallation('ANT_RX', [1.5;0;0], ...
    rfscreen.geometry.Rotation.aboutZ(180)));

% RF systems
sc.addTransmitter(rfscreen.rf.RFTransmitter('TX1','ANT_TX', fc, 20e6, 33));   % 33 dBm
sc.addReceiver(rfscreen.rf.RFReceiver('RX1','ANT_RX', fc, 20e6));

% RUN: pairwise screening (pattern-only coupling)
mr = rfscreen.interference.InterferenceAnalyzer.analyze(sc);
pr = mr.getPair('TX1','RX1');
```

Result (as printed by the script):

```
=== Quick Start result: TX1 -> RX1 ===
  distance             : 1.50 m
  TX gain toward RX     : 12.00 dBi (MAIN lobe)
  RX gain toward TX     : 8.00 dBi (MAIN lobe)
  frequency relation    : CO_CHANNEL
  DirectionalCouplingIdx: 20.00 dB   (SCREENING index, NOT isolation/S21)
  risk (screening)      : HIGH
  validity              : MISSING_RECEIVER_DATA
```

**How to read it:** `DirectionalCouplingIdx` is a relative pattern+geometry screening index
(`txGain + rxGain` toward each other), **not** an S21 isolation and **not** received power. `risk`
is a screening label. `validity = MISSING_RECEIVER_DATA` correctly says you have not yet supplied a
receiver susceptibility model, so no PASS/FAIL was invented (see §17).

## 6. Inputs you provide

| Concept | Class | What it holds |
|---------|-------|---------------|
| Antenna hardware | `rfscreen.antenna.Antenna` | id, role (TX/RX), frequency range, polarization, pattern id |
| Installation | `rfscreen.antenna.AntennaInstallation` | position (m, body frame) + orientation (DCM) |
| Radiation pattern | `rfscreen.antenna.FreeSpacePattern` / `InstalledPattern` / `PatternGrid` | gain vs (freq, az, el) + provenance |
| Transmitter | `rfscreen.rf.RFTransmitter` | antenna id, centre freq, bandwidth, power (dBm) |
| Receiver | `rfscreen.rf.RFReceiver` | antenna id, centre freq, bandwidth (+ optional front end) |
| Receiver front end | `rfscreen.receiver.ReceiverFrontEnd` | P1dB_in, IIP3_in, gain, NF (input-referred) |
| Structure | `rfscreen.geometry.SpacecraftStructure` | primitive geometry, pose, type, provenance |
| Scenario | `rfscreen.scenario.Scenario` | registry that ties all of the above together |

**Hardware ≠ installation.** The same `Antenna` model can be installed at different
positions/orientations. Keep them separate.

## 7. Coordinate conventions

Getting these right is essential; the tool never guesses a convention for you.

- **Antenna-local frame.** Boresight is **`+X_A`**. Azimuth is measured about **`+Z_A`** from
  `+X_A` toward `+Y_A`, using `atan2d`, in a **circular** range `[-180°, 180°]`. Elevation is
  measured toward `+Z_A`, in a **clamped** range `[-90°, 90°]`.
- **Body frame.** Each antenna installation has a position `origin_m` (metres) and a rotation
  matrix `R_BA` whose **columns are the antenna axes expressed in body coordinates**, so a vector
  transforms as `v_B = R_BA · v_A`. The antenna boresight in the body frame is therefore column 1
  of `R_BA`.
- **Structure frame.** A structure's local geometry `S` maps to the body frame by
  `v_B = R_BS · v_S + origin_m`.
- **Rotations.** Build DCMs with `rfscreen.geometry.Rotation.aboutX/aboutY/aboutZ(deg)` — never
  hand-type a matrix unless you have verified it is orthonormal (the constructor rejects
  non-rotation matrices).

**Circular azimuth (important).** Azimuth wraps: a footprint spanning `358°, 359°, 0°, 1°, 2°` is a
small **4°** arc, not a `359°` span. The tool computes az extent relative to the footprint centroid
(wrapped to `[-180,180]`) and reports the true arc width as `azimuthSpan_deg`. See §18.

## 8. Radiation-pattern format

A pattern answers one query: `gain_dBi = pattern.evaluate(freq_Hz, az_deg, el_deg)`.

- **Grids.** `rfscreen.antenna.PatternGrid(azVec, elVec, freq, gainMatrix)` stores tabulated gain.
  Azimuth interpolation is **periodic** (wraps at `±180`); elevation is **clamped**; frequency is
  handled per the interpolation policy (a single-frequency pattern is reused, with a warning, at
  other frequencies). Multiple frequencies are supported in one grid.
- **Provenance is first-class.** `FreeSpacePattern` and `InstalledPattern` are **distinct types**
  and carry a source (`MEASURED` / `SIMULATED_3D` / `APPROX_FROM_CUTS` / `SYNTHETIC_TEST` …). The
  tool never silently treats a free-space pattern as installed reality.
- **Synthetic patterns for exploration.** `rfscreen.antenna.SyntheticPatternFactory` builds clearly
  marked `SYNTHETIC_TEST` patterns so you can exercise the workflow without real data:
  - `cosineDirectional(peakGain_dBi, freq_Hz, exponent)` — a smooth `cos^n` main lobe.
  - `mainSideBack(main_dBi, side_dBi, back_dBi, freq_Hz, mainHalfwidth_deg)` — a 3-region cut.

No real/mission pattern ships in this repository; supply your own measured or simulated data (with
provenance) for quantitative work.

## 9. Spacecraft geometry & structures

Structures are built from primitive volumes and posed in the body frame:

```matlab
bus = rfscreen.geometry.SpacecraftStructure('BUS','bus', 'BUS', ...
    rfscreen.geometry.BoxGeometry([0.75;0.75;0.75]), eye(3), [0;0;0], ...
    struct('provenance','SYNTHETIC_TEST'));

panel = rfscreen.geometry.SpacecraftStructure('SA','solar array', 'SOLAR_ARRAY', ...
    rfscreen.geometry.PanelGeometry(2.5, 1.5), rfscreen.geometry.Rotation.aboutX(20), ...
    [0.6;0;2.5], struct('provenance','SYNTHETIC_TEST','deploymentState','DEPLOYED'));
```

- `BoxGeometry([hx;hy;hz])` — a box with the given half-extents (metres), slab-method ray test.
- `PanelGeometry(width, height)` — a flat panel, ray-plane intersection with in-bounds test.
- The 4th/5th/6th args are the rotation `R_BS`, the origin `origin_m`, and a metadata struct
  (always record `provenance`).

Geometry gives **evidence** (does it enter the FOV, is the LOS blocked, how far). It never produces
a gain, loss, isolation, or scattering value — that boundary is enforced in the architecture.

## 10. RF systems: transmitters & receivers

```matlab
sc.addTransmitter(rfscreen.rf.RFTransmitter('TX1','ANT_TX', 2.2e9, 20e6, 33));   % 33 dBm
sc.addReceiver(rfscreen.rf.RFReceiver('RX1','ANT_RX', 2.2e9, 20e6));
```

Powers are in **dBm**, frequencies/bandwidths in **Hz**. A receiver may additionally own a front
end for nonlinear analysis (§15) and a filter/noise model for linear I/N (§14). Every RF power
carries an explicit **reference plane** (TX antenna input, receiver RF input, LNA input); the tool
never mixes planes implicitly.

## 11. Building a scenario

A `Scenario` is the registry that connects everything. Add patterns, antennas, installations,
transmitters, receivers, and (optionally) structures and installed patterns, then hand it to an
analyzer. See the quick start (§5) for a complete, runnable assembly. The pattern registry keys on
an explicit `patternId`, so several antennas may reuse one pattern.

## 12. Antenna-to-antenna screening

`rfscreen.interference.InterferenceAnalyzer.analyze(sc)` runs **pairwise over all TX×RX
combinations** and returns a `MatrixResult`. For each pair you get: distance, TX gain toward RX, RX
gain toward TX, lobe classes (MAIN/SIDE/BACK), frequency relation (CO_CHANNEL / ADJACENT / …), the
`DirectionalCouplingIndex` screening metric, a screening risk level, and a validity state.

Retrieve one pair with `mr.getPair('TX1','RX1')`. Remember: the coupling index is a **relative
screening** quantity, not an S21.

## 13. Structure field-of-view (FOV) & line-of-sight

Ask whether a structure sits inside an antenna's FOV and how large its angular footprint is:

```matlab
pat = rfscreen.antenna.SyntheticPatternFactory.mainSideBack(12, -8, -25, fc, 20);
fov = rfscreen.geometry.AntennaToStructureFOV.analyze('ANT_TTC', antPos, R_BA, bus, ...
    struct('pattern', pat, 'frequency_Hz', fc));
% fov.centerOffBoresight_deg, fov.azimuthSpan_deg, fov.occupiedLobes (set),
% fov.centerRayHits (LOS to centroid), fov.closestDistance_m
```

`occupiedLobes` is the **set** of pattern regions the footprint spans, so a structure whose centre
is outside the main beam but whose *edge* clips it is still detected. The footprint is
`VERTEX_SAMPLED` (centroid + primitive vertices) — see the false-negative caveat in §18.
Line-of-sight blockage between two antennas is available through `rfscreen.geometry.LineOfSight`
and is reported as `CLEAR`/`BLOCKED` — a **geometric** fact, never an attenuation value.

## 14. Linear RF coexistence (I/N)

For interference-to-noise screening in the linear regime, give the receiver a filter and a noise
model and supply a TX spectrum; the analyzer integrates the TX PSD against the filter response in
**linear** units and compares against a configurable `InterferenceCriterion` (e.g. `I/N ≤ limit`).
Absolute interference power is produced **only** when a far-field-valid coupling is supplied;
pattern-only inputs yield `ABSOLUTE_COUPLING_UNAVAILABLE`, not a fabricated dBm. (See
`docs/icd/receiver_susceptibility.md` for the full field list.)

## 15. Nonlinear receiver interference (P1dB, blocking, IM3)

When strong interferers may drive a receiver front end nonlinear, describe the front end with
**input-referred** hardware values and analyze at the `LNA_INPUT` plane. This is the exact core of
[`examples/reference_cases/rc_kari_rf_01_gnss_interference.m`](../examples/reference_cases/rc_kari_rf_01_gnss_interference.m):

```matlab
fe = rfscreen.receiver.ReceiverFrontEnd(struct('p1dB_in_dBm', -25, 'iip3_in_dBm', -15, ...
    'linearGain_dB', 28, 'provenance', 'SYNTHETIC_TEST'));
gnssBand = [1.559e9 1.591e9];                 % ~ GNSS L1
chan = rfscreen.receiver.IdealBandpassFilter(gnssBand, 0, -Inf);

f1 = 1.60e9; f2 = 1.625e9;                     % 2f1-f2 = 1.575 GHz (in GNSS L1)
inputs = struct('txId', {'S1','S2'}, 'freq_Hz', {f1, f2}, ...
    'lnaInputPower_dBm', {-8, -8}, 'isAbsolute', {true, true}, ...
    'couplingValidity', {'FAR_FIELD_VALID','FAR_FIELD_VALID'});

comp = rfscreen.nonlinear.CompressionAnalyzer.analyze(inputs, fe, []);
im   = rfscreen.nonlinear.IntermodulationAnalyzer.analyze(inputs, fe, chan, gnssBand, []);
```

- **Compression** sums all active interferers in the **linear** domain and compares the aggregate
  against `P1dB_in` (`Margin = P1dB_in − P_agg`, `>0` is safe). Here the aggregate is −4.99 dBm vs
  P1dB_in −25 dBm → margin −20 dB → **FAIL** (saturation).
- **IM3** places products at `2f1−f2` and `2f2−f1`, with input-referred power
  `P_IM3,in = 2·P_a + P_b − 2·IIP3`. Here `2f1−f2 = 1.575 GHz` lands **inside** the GNSS L1 band;
  `2f2−f1 = 1.65 GHz` does not.
- **Blocking** (via `BlockingAnalyzer`) is judged by frequency offset and is **independent of
  spectral overlap** — `NO_OVERLAP ≠ NO_BLOCKING_RISK`.

All hardware values must be real (or clearly `SYNTHETIC_TEST`); missing P1dB/IIP3 yields
`MISSING_P1DB`/`MISSING_IIP3`, never a default.

## 16. Free-space vs installed patterns

When you have an **installed** pattern (measured or simulated), compare it to the free-space
baseline:

```matlab
sel = rfscreen.installed.InstalledPatternSelector.select(free, installed, 'PREFER_INSTALLED');
cmp = rfscreen.installed.PatternComparison.compare(free, installed, struct('frequency_Hz', fc));
% cmp.peakGainDifference_dB, cmp.maxAbsDifference_dB, cmp.rmsDifference_dB
```

The comparison **workflow** is fully reproducible (Tier 2–3); the *magnitude* of the deltas depends
entirely on the installed data you supply. The tool will **not** synthesize an installed pattern
from geometry, and it does not model axial-ratio/polarization deltas (Tier 4). Provenance/fidelity
of the installed pattern is preserved, never upgraded.

## 17. Interpreting results & validity states

The tool is deliberately explicit when it lacks evidence. Common validity states and what they mean:

| State | Meaning | What to do |
|-------|---------|-----------|
| `MISSING_RECEIVER_DATA` | No susceptibility model supplied | Add a front end / criterion if you need PASS/FAIL |
| `ABSOLUTE_COUPLING_UNAVAILABLE` | Only pattern-only screening exists | Supply a far-field-valid coupling for absolute dBm |
| `MISSING_P1DB` / `MISSING_IIP3` | Front-end nonlinear data absent | Provide input-referred hardware values |
| `INSTALLATION_EFFECT_UNKNOWN` | Free-space used as fallback; no installed data | Supply an installed pattern |
| `NEAR_FIELD` / not `FAR_FIELD_VALID` | Separation may be sub-far-field | Do not apply FSPL; use measured/EM coupling |
| `MODEL_GAP_*` | A declared physics boundary (Tier 4) | Use full-wave/measured evidence — outside this tool |

**A validity state is an answer, not an error.** `UNKNOWN`/`UNAVAILABLE` means the tool refused to
invent a number it could not justify. Treat a screening index as a *ranking* signal, and only treat
a value as physical when its validity says so.

## 18. Known limitations (read before trusting a number)

- **Screening ≠ coupling.** The `DirectionalCouplingIndex` is a relative pattern/geometry index,
  not an S21 isolation or a received power.
- **VERTEX_SAMPLED LOS can miss thin occluders (false negative).** Line-of-sight and footprint
  tests sample the centroid and primitive vertices. A thin obstruction that lies *between* sampled
  rays can be missed, reporting `CLEAR`/`hit=0` where a dense mesh would find a clip. This is a
  documented sampling caveat (see `docs/icd/spacecraft_geometry.md §4`); do not treat a clear LOS as
  a guarantee of no blockage for slender structures.
- **Circular azimuth footprint.** Azimuth is periodic; the reported `azimuthSpan_deg` is the true
  arc width relative to the footprint centroid (a structure straddling the `±180°` seam does **not**
  report a spurious ~360° span). Use `azimuthSpan_deg`, not `maxAz − minAz`.
- **Geometry ≠ EM.** A structure in the FOV or a blocked LOS is geometric evidence; it does **not**
  imply a gain loss, reflection, or scattering value.
- **No auto-FSPL.** On-platform separations may be near-field; the tool never auto-applies a
  free-space path loss without an explicit far-field validity check.
- **No paper fitting / no fake physics.** Values are never corrected to match a reference; absent
  evidence yields `UNKNOWN`, not a fudge.

## 19. Reference-case examples (KARI reproduction)

Four runnable scripts under `examples/reference_cases/` reproduce (to the tier the architecture
supports) published KARI research cases. Each prints its own reproducibility tier and names its
model gaps. See `docs/reports/reference_validation/` for the full validation reports.

| Script | Reproduces | Tier reached |
|--------|------------|--------------|
| `rc_kari_01_structure_fov.m` | Structure-in-FOV geometry for an S-band antenna (Im W-G. et al., KSAS 2015) | Tier 2 geometry / Tier 4 EM deformation |
| `rc_kari_02_installed_pattern.m` | Free-space vs installed pattern comparison workflow (Lee S-I. et al., KSAS 2023) | Tier 2–3 workflow / Tier 4 axial-ratio |
| `rc_kari_03_installation_analysis.m` | Installed-location geometry & fidelity boundary (Lee S-I., Im W-G., KARI 2025) | Tier 1–2 geometry / Tier 4 full-wave |
| `rc_kari_rf_01_gnss_interference.m` | S-band → GNSS LNA saturation + IM3 into band (Kwon B-M. et al., JKSAS 2019) | Tier 2 mechanism |

Run one, e.g.:

```
octave-cli --eval "addpath('examples/reference_cases'); rc_kari_01_structure_fov"
```

The geometry values in these scripts are `ASSUMED_FOR_REPLICATION` reconstructions (the papers'
exact CAD/hardware are not public); nothing is presented as flight data. The scripts validate the
tool's *domain and boundary*, not a curve-fit to the papers.

## 20. Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `error: invalid meta.package indexing` | You wrote `G = rfscreen.geometry;`. Use fully-qualified names, e.g. `rfscreen.geometry.Rotation.aboutZ(180)`. |
| `undefined near line 1, column 1` on `rfscreen.*` | `src/` is not on the path. Run `addpath('src')` first (example scripts do this automatically). |
| A validity state instead of a number | Expected — the tool withheld an unjustified value. See §17 and supply the missing evidence. |
| A structure "should" block LOS but reports `CLEAR` | Vertex sampling may have missed a thin occluder (§18). Densify the geometry or treat slender structures conservatively. |
| Non-rotation matrix rejected | Build DCMs with `rfscreen.geometry.Rotation.*`; a hand-typed matrix must be orthonormal. |
| Headless plot errors | Use `graphics_toolkit('gnuplot')` and `set(0,'defaultfigurevisible','off')` (see `examples/reference_cases/generate_figures.m`). |

---

*This manual is validated in `docs/reports/reference_validation/RPT-P6-04-user-manual-validation.md`;
every code block is drawn from a script that executes under Octave 8.4.*
