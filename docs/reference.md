# Reference Review — Spacecraft RF Coexistence & Antenna Interference Screening Tool

> **Status of this file.** The repository was empty at the start of Phase 1, so this
> `docs/reference.md` did not pre-exist. It is authored here as the *mandatory reference
> review* step (Task §0) from the reference topics enumerated in the Phase 1 brief. Each
> reference is summarized together with the **architecture implication** it imposes on the
> tool. These implications are treated as binding: they are *not* deleted or simplified in
> later steps, and every requirement / ICD / code decision traces back to one of them.
>
> The individual reference *documents* are not bundled in this repository. Where a concrete
> primary source is not attached, the entry records the engineering principle the reference
> stands for. No numeric antenna/RF data is imported from any of these sources in Phase 1
> (see Task §10, §31, §39).

---

## R1. Ansys HFSS (full-wave EM solver)

**What it is.** A 3D full-wave finite-element electromagnetic solver used to compute installed
antenna patterns, near-field coupling, and antenna-to-antenna isolation (S21) on a full
spacecraft CAD model.

**Architecture implication.**
- HFSS is the *verification / ground-truth* layer, **not** something this tool replaces. The
  tool is an *early-design screening* stage that flags pairs worth sending to HFSS.
- HFSS-derived coupling must enter the system through a **replaceable `CouplingModel`
  boundary** (`HFSSCouplingModel`), never hard-wired into the analyzer.
- HFSS results are one *provenance* of an installed pattern and of a coupling value; the data
  model must be able to record "this number came from HFSS" distinctly from "this number is a
  pattern-only screening index."

## R2. ESA — antenna farm scattering / inter-antenna interference

**What it is.** ESA studies of "antenna farms": many antennas co-located on one platform, where
platform structure scatters and re-radiates, and antennas couple through both direct and
structure-mediated paths.

**Architecture implication.**
- Two *distinct* coupling domains exist: **antenna→antenna** (direct) and
  **antenna→structure→antenna** (scattering/blockage). They are different physics and must be
  **separate interfaces** (`AntennaToAntennaFOV` vs `AntennaToStructureFOV`), even though
  Phase 1 only implements the direct-geometry part.
- Screening must be **pairwise over all TX×RX combinations** (the "farm" is a matrix problem),
  producing an interference matrix.

## R3. NASA / JPL — spacecraft antenna & RF analysis

**What it is.** Mission practice for RF compatibility on spacecraft: body-frame installation
geometry, boresight/FOV bookkeeping, link and interference budgets, EMC/RFC analysis.

**Architecture implication.**
- **Installation geometry is first-class**: position + orientation of each antenna in a defined
  **spacecraft body frame**, with an explicit, documented coordinate convention (ICD-fixed).
- Antenna *hardware* and antenna *installation* are separate concerns (the same antenna model
  can be installed at different places/orientations).
- Every RF quantity needs an unambiguous **reference plane** (TX input, EIRP reference, RX
  output, receiver RF input, LNA input).

## R4. MathWorks — custom radiation pattern

**What it is.** MATLAB/Antenna & Phased Array Toolbox patterns for representing and evaluating
custom radiation patterns (gain as a function of frequency and angle) on a grid, with
interpolation.

**Architecture implication.**
- The pattern is a **canonical abstraction** `AntennaPattern` with an `evaluate(freq, az, el)`
  contract returning directional gain; concrete grid storage + interpolation sit behind it.
- **Interpolation and boundary policy** (azimuth wrap, elevation clamp, frequency handling,
  out-of-domain behavior) must be *explicit and documented*, not implicit.
- Do not depend on a proprietary toolbox for the *core contract*; the abstraction must accept a
  plain tabulated grid.

## R5. 한국항공우주연구원(KARI) / 임원규 박사 관련 연구 — installed antenna & platform effects

**What it is.** Research context on installed-antenna performance and platform interaction for
spacecraft/aircraft antennas (installed pattern differs from free-space pattern; platform
alters gain, especially off-boresight and in the back hemisphere).

**Architecture implication.**
- **Free-space pattern ≠ installed pattern.** The two must remain *distinguishable types*
  (`FreeSpacePattern` vs `InstalledPattern`) with recorded **provenance**, so a screening run
  never silently treats an idealized free-space pattern as if it were the installed reality.
- Installed patterns carry a **source** (MEASURED / HFSS / CST / OTHER_SOLVER / APPROXIMATE).

## R6. Installed antenna pattern

**What it is.** The realized pattern of an antenna *after* mounting on the platform, including
structure scattering, blockage, and mismatch effects.

**Architecture implication.**
- `InstalledPattern` is a distinct concrete type; its numbers must be traceable to a source and
  confidence.
- Phase 1 **does not generate** installed patterns (Task §10) — it only fixes the *contract* so
  measured/simulated installed patterns can be imported later without changing the engine.

## R7. Spacecraft structure & FOV interference (blockage / obstruction)

**What it is.** Field-of-view analysis: whether bus panels, solar arrays, booms, reflectors, or
other antennas fall inside an antenna's FOV, causing blockage or scattering.

**Architecture implication.**
- A dedicated **antenna-to-structure FOV** domain is required as an *interface now,
  implementation later*. Structure geometry (STL/mesh, primitive volumes) is an extension
  point, explicitly out of scope for Phase 1 computation but reserved in the ICD.
- FOV/pattern overlap is a **screening** signal, not a coupling value.

## R8. RF receiver front-end interference

**What it is.** Interference enters a receiver through its front end: antenna → filter → LNA →
downstream. Susceptibility depends on filter selectivity, LNA linearity, noise figure, and
sensitivity — not just on the tuned frequency.

**Architecture implication.**
- The receiver is **not** a bare frequency range. `RFReceiver` owns an optional `RFFrontEnd`
  (filter, LNA P1dB, IIP3, NF, sensitivity, interference threshold) as an extension layer.
- **Receiver susceptibility is a separate layer from antenna coupling.** Coupling delivers
  power to the RX antenna port; susceptibility decides whether that power is harmful. The two
  are never merged.

## R9. Blocking / compression / intermodulation

**What it is.** Front-end nonlinear interference mechanisms: strong out-of-band signals cause
gain compression (blocking) past P1dB; multiple tones generate intermodulation/spurious
products (governed by IIP3); adjacent-band and in-band overlap cause direct interference.

**Architecture implication.**
- The interference **classification taxonomy** must span at least: `IN_BAND`, `ADJACENT_BAND`,
  `BLOCKING_COMPRESSION`, `INTERMODULATION_SPURIOUS`.
- Phase 1 computes **spatial + spectral screening** deterministically and leaves the nonlinear
  mechanisms as *typed, reserved* extension points (P1dB/IIP3 margins in `PairResult`), rather
  than inventing nonlinear numbers ("no fake physics", Task §39).

---

## R10. MathWorks — custom/tabulated 2D radiation-pattern cuts & interpolation (Phase 2)

**What it is.** MATLAB practice for representing an antenna pattern from tabulated angle/gain data
(principal-plane cuts), including angular interpolation and periodic (azimuthal) wrap. Source cut
data commonly uses a `+Z`-boresight convention with `theta` measured from boresight, arbitrary
fixed angular step, and either `[-180,180]` or `[0,360)` angle ranges.

**Architecture implication (Phase 2).**
- Angular resolution and coordinate convention are **per-dataset**, not global constants; the
  importer must detect/validate each cut's own step and range (no hard-coded 0.25°/1°/361/721).
- Interpolation must run against the **actual angle vector** with **periodic** wrap across
  `0°/360°`, never `index = theta/step`.
- Source `+Z` boresight is an *external* convention; it must be transformed explicitly into the
  Phase-1 antenna-local frame and never leak into the core.
- 2D cuts are not a measured 3D pattern; any 3D assembled from cuts is `APPROX_FROM_CUTS`.

*(Realized by the `+patterndata` pipeline; see `docs/icd/pattern_data.md`.)*

## R11. Receiver noise, I/N, and spectral coexistence (Phase 3)

**What it stands for.** Standard linear RF interference analysis: thermal noise `N = kTB`
(Boltzmann `k`, temperature `T`, bandwidth `B`), noise figure referred to a `T0 = 290 K`
reference, interference-to-noise ratio `I/N`, and spectral overlap computed by integrating a TX
power spectral density against a receiver filter response in **linear** power units. These are the
textbook relations behind ITU-R-style protection criteria (e.g. `I/N` limits) and receiver
sensitivity/blocking budgets.

**Architecture implication (Phase 3).**
- Power integration is performed in **linear** units (W, W/Hz); dB is an interface unit only,
  never summed/integrated.
- Every RF power has an explicit **reference plane**; noise and interference are compared at the
  same plane (`RECEIVER_RF_INPUT`).
- The physical acceptance test (`I/N ≤ limit`, or max interference power) is a configurable
  **`InterferenceCriterion`**, kept distinct from screening heuristics.
- Absolute interference power requires a physical propagation/coupling model; pattern-only
  screening evidence must never be presented as absolute RF power.

*(Realized by `+spectrum`, `+receiver`, and `interference.SpectralCouplingAnalyzer`; see
`docs/icd/spectrum.md`, `docs/icd/receiver_susceptibility.md`.)*

## R12. Receiver front-end nonlinearity: P1dB, IIP3, two-tone IM3, blocking (Phase 4)

**What it stands for.** Standard RF receiver front-end nonlinear behavior. A weakly nonlinear
device (LNA) driven by strong signals exhibits: gain compression characterized by the input
1-dB compression point (`P1dB_in`); third-order intermodulation characterized by the input
third-order intercept (`IIP3_in`), where two tones `f1,f2` generate products at `2f1−f2` and
`2f2−f1` whose input-referred power follows the classic `P_IM3,in = 2·P_a + P_b − 2·IIP3`
(equal-tone `3P − 2·IIP3`, third-order slope 3); and blocking/desensitization, where a strong
undesired signal — possibly out of the wanted band — degrades the receiver, bounded by an
allowable blocker power that generally varies with frequency offset.

**Architecture implication (Phase 4).**
- Nonlinear analysis is referenced to one explicit plane (`LNA_INPUT`) with **input-referred**
  hardware quantities; input/output P1dB and IIP3/OIP3 are never mixed implicitly.
- Compression depends on **aggregate** power from all simultaneously active interferers, summed in
  the **linear** domain.
- Blocking is independent of spectral overlap: `NO_OVERLAP ≠ NO_BLOCKING_RISK`.
- These are **receiver-generated** effects; transmitter spurious/IMD and mixer spurs are separate
  and out of scope. No result is produced without valid absolute coupling and real hardware data.

*(Realized by `+receiver` (front-end + criteria) and `+nonlinear` (analyzers); see
`docs/icd/receiver_nonlinear.md`.)*

## R13. Spacecraft structure FOV & installed-antenna environment (Phase 5)

**What it stands for.** The spacecraft-structure FOV / installed-antenna research themes (R7, and
the KARI / Im Won-gyu installed S-band-antenna studies in R5): an antenna's realized behavior
depends on its spacecraft-installed environment — nearby structure in the field of view, blockage,
and installed-vs-free-space pattern differences (gain, and — where measured — axial-ratio /
polarization). These are established by **installed pattern / full-wave / measurement** evidence,
not by geometry alone.

**Architecture implication (Phase 5).**
- **Geometry provides installation-risk evidence; it never manufactures EM behavior.** A structure
  in an antenna's FOV, or a blocked line-of-sight, is deterministic *geometric* evidence — it does
  **not** imply a specific gain loss, isolation, reflection, or diffraction value.
- Free-space and installed patterns stay distinct; an installed pattern is used only when supplied
  (with its provenance/fidelity preserved), never derived from a structure intersection.
- The screening chain becomes *free-space behavior → spacecraft installation/environment → installed
  behavior*, but **MATLAB geometry screening ≠ full-wave EM solution** — full-wave/measured evidence
  and solver integration are Phase 6.

*(Realized by `+geometry` (structures, FOV, LOS), `+installed` (selection, comparison), and
`interference.InstalledEnvironmentAnalyzer`; see `docs/icd/spacecraft_geometry.md`,
`docs/icd/installed_environment.md`. Consistent with the KARI installed-antenna themes in R5.)*

---

## R14. KARI reference cases — reproduction targets (Phase 6)

**What this section is.** Phase 6 is a validation/reproduction phase: it measures how far the
Phase 1–5 tool reproduces specific published KARI (한국항공우주연구원) research cases, run top-down
from a user's point of view. Each case below records its citation, the phase/component that
addresses it, what the tool *can* validate, and its known reproduction limitation. **No paper
fitting** and **no fabricated EM** (§9, §29): where the model differs from a paper the difference is
*classified*, never corrected. Reproducibility tiers are assigned **after** running the cases (see
`docs/reports/reference_validation/`). The primary documents are not bundled here; where a source is
public but not attached, the entry records the engineering case it stands for.

### RC-KARI-01 — Structure FOV effect on S-band radiation (KSAS 2015)

- **Citation.** 임원규, 권기호, 김중표, 이선익, 김상구, 원영진, 문홍열, 이상곤, "위성 구조체의 FOV
  간섭에 의한 S 대역 안테나의 방사 특성 영향성 분석", 한국항공우주학회 학술발표회, 2015.
  Search: [한국항공우주학회 논문검색](https://www.koreascience.kr/) ·
  [Google Scholar](https://scholar.google.com/scholar?q=위성+구조체+FOV+S대역+안테나+방사+특성+임원규).
- **Phase / component.** Phase 5 — `geometry.AntennaToStructureFOV`, `geometry.LineOfSight`,
  angular footprint. Script: `examples/reference_cases/rc_kari_01_structure_fov.m`.
- **What the tool can validate.** That spacecraft structure enters the antenna FOV in the reported
  region; angular footprint; occupied lobes (main/side/back); LOS blockage — **geometry evidence**
  (Tier 2).
- **Known reproduction limitation.** The electromagnetic radiation-pattern *deformation magnitude*
  (scattering/diffraction) is `MODEL_GAP_FULL_WAVE`, **Tier 4** — requires full-wave/measured
  evidence the tool does not own.

### RC-KARI-02 — Installed S-band antenna performance (KSAS 2023)

- **Citation.** 이선익, 임원규, 김중표, "S대역 안테나의 위성 설치상태에서의 성능 연구",
  한국항공우주학회, 2023. Search:
  [한국항공우주학회](https://www.koreascience.kr/) ·
  [Google Scholar](https://scholar.google.com/scholar?q=S대역+안테나+위성+설치상태+성능+이선익+임원규).
- **Phase / component.** Phase 2 pattern data + Phase 5 `FreeSpacePattern`/`InstalledPattern`,
  `InstalledPatternSelector`, `PatternComparison`. Script:
  `examples/reference_cases/rc_kari_02_installed_pattern.m`.
- **What the tool can validate.** The **free-space ↔ installed comparison workflow** (peak/max/RMS
  gain delta, boresight delta), with provenance preserved (Tier 2–3), when installed data is
  supplied.
- **Known reproduction limitation.** The installed pattern must be **supplied** (measured/simulated)
  — it is never derived from geometry (`MODEL_GAP_INSTALLED_PATTERN`); axial-ratio/polarization
  deltas are unsupported (`MODEL_GAP_AXIAL_RATIO/POLARIZATION`, Tier 4).

### RC-KARI-03 — Installed-location electromagnetic analysis (KARI 2025)

- **Citation.** 이선익, 임원규, "위성항법 정지궤도위성 원격측정명령계 S대역 안테나 설치위치에서의
  전자장 해석", KARI research stream, 2025. Search:
  [KARI](https://www.kari.re.kr/) ·
  [Google Scholar](https://scholar.google.com/scholar?q=정지궤도위성+S대역+안테나+설치위치+전자장+해석+이선익).
- **Phase / component.** Phase 5 installed environment (position + FOV + LOS) + explicit fidelity
  boundary. Script: `examples/reference_cases/rc_kari_03_installation_analysis.m`.
- **What the tool can validate.** Per-candidate-location installation position (Tier 1) and FOV/LOS
  geometry (Tier 2) at each mount.
- **Known reproduction limitation.** The full-wave EM field solution
  (scattering/reflection/diffraction) is **Tier 4** by design — this case validates the
  *architecture boundary*, cleanly separating reproducible installed-geometry evidence from the
  full-wave field the tool does not compute.

### RC-KARI-RF-01 — S-band signals interfering with a GNSS receiver (JKSAS 2019)

- **Citation.** 권병문, 신용설, 마근수, 주정갑, 지기만, "S 대역 신호에 의한 위성항법수신기의 RF
  신호간섭", 한국항공우주학회지 (JKSAS), 2019. **This is NOT an Im Won-gyu paper — do not
  misattribute authorship.** Search:
  [한국항공우주학회지](https://www.koreascience.kr/) ·
  [Google Scholar](https://scholar.google.com/scholar?q=S대역+신호+위성항법수신기+RF+신호간섭+권병문).
- **Phase / component.** Phase 3 linear + Phase 4 `CompressionAnalyzer` / `BlockingAnalyzer` /
  `IntermodulationAnalyzer`. Script: `examples/reference_cases/rc_kari_rf_01_gnss_interference.m`.
- **What the tool can validate.** The **mechanism/trend**: strong S-band signals driving a GNSS
  active-antenna LNA toward/over P1dB (compression margin sign), and a two-tone IM3 product
  (`2f1−f2`) landing inside the GNSS L1 band (Tier 2).
- **Known reproduction limitation.** Absolute dB levels are **not fitted** — the paper's exact
  hardware IIP3/P1dB and link budget are not public (`REFERENCE_DATA_INCOMPLETE`).

*(Realized by the Phase-3/4/5 packages above; validated in
`docs/reports/reference_validation/RPT-P6-01…05` and `reference_case_matrix.md`. Consistent with the
KARI installed-antenna themes in R5 — this section names the specific cases R5 refers to.)*

## Cross-cutting architecture implications (binding for Phase 1)

The references above converge on a small set of non-negotiable structural rules. These are the
"architecture implications" that must not be simplified away:

1. **Screening ≠ coupling.** Pattern/FOV-based screening is an early indicator; real coupling is
   S21 / HFSS / CST / measurement. Coupling lives behind a `CouplingModel` abstraction boundary
   (R1, R2, R6).
2. **Six separated concerns:** Geometry · Pattern · Coupling · RF System · Receiver
   Susceptibility · Interference Decision. No concern owns another's data implicitly (R3, R8).
3. **Hardware ≠ installation.** `Antenna` (hardware) is separate from `AntennaInstallation`
   (placement/orientation) (R3).
4. **Free-space pattern ≠ installed pattern**, and both carry **provenance** (R5, R6).
5. **Two FOV domains:** antenna→antenna and antenna→structure are different physics and
   different interfaces (R2, R7).
6. **Near-field caution.** On-platform antenna separations may be sub-far-field; a link-budget
   FSPL must **never** be auto-applied without a far-field validity check (R1, R2).
7. **Explicit units, frames, and reference planes**; nothing implicit (R3, R4).
8. **Interference taxonomy** reserved from the start: in-band / adjacent / blocking /
   intermodulation (R9).
9. **Results carry validity/provenance**, so a screening index is never mistaken for a measured
   isolation (R1, R5).
10. **HFSS/CST/measurement are the verification layer**, integrated later via the coupling and
    pattern-provenance boundaries — this tool feeds them, it does not replace them (R1, R2).

## What these references explicitly *forbid* in Phase 1

- Generating real/mission antenna reference patterns or gain values (R5, R6 — deferred).
- Applying FSPL/link-budget coupling by default (R1, R2, near-field caution).
- Treating a pattern-only directional index as a measured S21 / isolation (R1, R5).
- Implementing structure scattering / full-wave coupling (R2, R7 — interface only).
- Inventing receiver thresholds, isolation constants, or HFSS results (R8, R9 — "no fake physics").
