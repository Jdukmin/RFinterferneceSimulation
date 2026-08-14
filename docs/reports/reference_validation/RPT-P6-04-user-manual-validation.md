# RPT-P6-04 — User Manual Validation

Confirms that `docs/user_manual.md` is a **top-down, runnable** manual (§31): it is written from
the user's point of view (objective → run → interpret), every code block executes, and every
interpretation matches what the tool actually prints. No manual example is aspirational.

---

## 1. Structure audit (§31 section coverage)

| Required manual element (§31) | Manual section | Present |
|-------------------------------|----------------|:-------:|
| What problem this solves | §1 | ✔ |
| What it does NOT solve | §2 | ✔ |
| Fidelity levels / tiers | §3 | ✔ |
| Install & run | §4 | ✔ |
| Quick start (Input→Run→Result) | §5 | ✔ |
| Inputs you provide | §6 | ✔ |
| Coordinate conventions | §7 | ✔ |
| Radiation-pattern format | §8 | ✔ |
| Spacecraft geometry / structures | §9 | ✔ |
| RF systems (TX/RX, reference planes) | §10 | ✔ |
| Scenario assembly | §11 | ✔ |
| Antenna-to-antenna screening | §12 | ✔ |
| Structure FOV & LOS | §13 | ✔ |
| Linear RF coexistence (I/N) | §14 | ✔ |
| Nonlinear (P1dB / blocking / IM3) | §15 | ✔ |
| Free-space vs installed | §16 | ✔ |
| Validity interpretation | §17 | ✔ |
| Limitations | §18 | ✔ |
| Reference-case examples | §19 | ✔ |
| Troubleshooting | §20 | ✔ |

## 2. Runnable-example audit (every code block executes)

Each manual code block was extracted and executed under Octave 8.4 (harness script
`scratchpad/manual_check.m`, plus the standalone example scripts). Results:

| Manual § | Example | Executes | Printed value matches manual text |
|----------|---------|:--------:|-----------------------------------|
| §4 | run command / test suite | ✔ | 598/598 suite passes |
| §5 | quick start scenario | ✔ | dist 1.50 m, couplingIdx 20.0 dB, risk HIGH, validity `MISSING_RECEIVER_DATA` |
| §8 | `SyntheticPatternFactory` | ✔ | patterns evaluate |
| §9 | `SpacecraftStructure` box + panel | ✔ | constructs, poses in body frame |
| §13 | `AntennaToStructureFOV.analyze` | ✔ | `azimuthSpan_deg` finite (143.1° for the bus) |
| §15 | `CompressionAnalyzer` + `IntermodulationAnalyzer` | ✔ | compression `FAIL`; 2f1−f2 = 1.575 GHz in-band |
| §16 | `InstalledPatternSelector` + `PatternComparison` | ✔ | RMS delta finite (1.50 dB for −1.5 dB shift) |
| §19 | all four RC scripts | ✔ | each prints its tier + model gaps |

**Result:** every code block in the manual runs and produces the value the surrounding prose
claims. No example is hypothetical.

## 3. Honesty audit (does the manual oversell?)

| Check | Finding |
|-------|---------|
| Does §2 state the non-goals plainly? | ✔ full-wave, installed-from-geometry, absolute S21, axial ratio, paper-fitting, auto-FSPL all listed as **not** done |
| Is Tier 4 framed as a boundary, not a failure? | ✔ §3 and §17 both say so explicitly |
| Are `UNKNOWN`/`UNAVAILABLE`/`MISSING_*` presented as legitimate answers? | ✔ §17 "a validity state is an answer, not an error" |
| Is the near-field / no-auto-FSPL caution present? | ✔ §17, §18 |
| Is Geometry ≠ EM stated? | ✔ §2, §9, §18 |
| Is the screening-index-≠-isolation caveat repeated where the number appears? | ✔ §5, §12, §18 |
| Is the VERTEX_SAMPLED false-negative documented for users? | ✔ §18 + §20 troubleshooting |
| Are synthetic patterns clearly marked, no fake mission data? | ✔ §8 |

## 4. Before / after (manual delta this phase)

- **Before Phase 6:** no user manual; the only entry points were `examples/demo_screening.m`
  (Phase-1 demo) and the ICDs. A new user had to read the ICD to assemble a scenario, and there was
  no single "Input→Run→Result" copyable path, no per-reference-case script, and no consolidated
  statement of what the tool refuses to compute.
- **After Phase 6:** `docs/user_manual.md` (20 sections, top-down), `examples/quickstart.m`
  (minimal runnable path), and `examples/reference_cases/rc_kari_0*.m` (four runnable reference
  cases). The manual states the non-goals, the fidelity tiers, the coordinate conventions, and the
  validity semantics up front, and every example is verified to run.

## 5. Cross-references verified

- Manual §13/§18 → `docs/icd/spacecraft_geometry.md §4` (VERTEX_SAMPLED caveat, AUD-02). ✔ present.
- Manual §19 → `docs/reports/reference_validation/` (RPT-P6-01…03, matrix). ✔ present.
- Manual §5/§15 → `examples/quickstart.m`, `examples/reference_cases/rc_kari_rf_01_*.m`. ✔ files
  exist and run.
- `examples/quickstart.m` footer → `docs/user_manual.md sections 15-17`. ✔ those sections exist.

**Conclusion:** the manual is complete against §31, fully runnable, and honest about the tool's
boundaries. Manual validation **PASS**.
