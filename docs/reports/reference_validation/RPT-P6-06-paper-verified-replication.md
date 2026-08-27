# RPT-P6-06 — Paper-Verified Replication (full texts obtained)

Supersedes the *unverified* parts of RPT-P6-01/02/03. The three KARI full texts were obtained and
read; every number below is `PUBLIC_REPORTED` from the paper text unless marked otherwise. Findings
that contradicted the earlier Phase-6 write-up are stated plainly.

## 0. Citation corrections (the earlier write-up was wrong)

| Case | Earlier (wrong) | Verified |
|------|-----------------|----------|
| RC-KARI-01 | "한국항공우주학회 학술발표회, 2015" | 한국항공우주학회 **2015 춘계**학술발표회, **pp. 832-835** |
| RC-KARI-02 | "한국항공우주학회, 2023" | 한국항공우주학회 **2023 추계**학술대회, **pp. 1261-1263** |
| RC-KARI-03 | "**KARI research stream**, 2025" | **항공우주시스템공학회(SASE) 2025년도 춘계학술대회** — a different society entirely |
| RC-KARI-RF-01 | described in a spacecraft context | platform is a **test launch vehicle (시험발사체)** |

## 1. RC-KARI-01 — what the paper actually does

**Setup.** S-band TC/TM antenna = **quadrifilar** (4× inverted-F, 90° phasing), circular
polarization, **hemispherical** pattern (±90°), axial ratio 3 dB over ≈±55°. The blocking structure
is the **payload-antenna reflector (P-ANT)** — a dish on a boom. The **satellite body is deliberately
excluded** from the simulation model. Real scale ≈ 4 m; P-ANT height ≈ 1000 mm. Acceptance criterion
**≤ 1 dB** radiation change, evaluated near **90° off** the main beam (TC/TM link-budget experience).
Four swept variables: P-ANT **diameter**, **thickness**, **spacing**, **boom presence**.

**Reported result (Fig. 5).** 4° angular width ↔ ≈**30 cm** diameter; 12° ↔ ≈**83 cm**; at ≈12° the
1 dB margin is exhausted near 90° ⇒ **acceptable up to ≈80 cm** at ≈4 m.

**What the earlier script modelled:** a 1.5 m bus cube and a solar-array panel. **Neither appears in
the paper.** The earlier reproduction was structurally wrong, and its "BUS at 180° off-boresight,
BACK, hit=1" line was vacuous (the antenna is mounted on the bus).

**Now reproduced — numerically, against the paper:**

| P-ANT diameter | Paper angular width | Tool `2·maxAngularRadius` | Δ |
|---|---|---|---|
| 0.30 m @ 4 m | ≈ 4° | **4.30°** | +0.30° |
| 0.83 m @ 4 m | 12° | **11.85°** | −0.15° |
| 0.80 m (accept limit) | — | **11.42°** | — |

Agreement is within the paper's own rounding ("약 4도", "12도"). **Comparison class:
`EXACT_NUMERICAL`, Tier 1.** The tool's `azimuthSpan_deg` and `2·maxAngularRadius_deg` agree to
1e-6, and both match the closed form `2·atan(D/2/R)`.

**Still Tier 4:** the **dB gain deformation** the paper measures (scattering + reflection off the
P-ANT). Not computed, not fabricated.

## 2. RC-KARI-02 — what the paper actually does

**Content.** A **method-selection** study, not a single installed-pattern result. Full-wave (MoM/FEM,
HFSS) vs high-frequency (GTD/UTD) with a far-field (`*.ffe`) or spherical-wave-mode (`*.sph`) source.
**Minimum validity radius ≈ 30–40 cm** for this hemispherical S-band antenna.

| Case | Stand-off | Paper verdict | Tool verdict (geometry only) |
|---|---|---|---|
| 1 | 40 cm boom | all 3 methods agree | HF method **VALID** (≥ 40 cm) |
| 2 | 4–5 cm boom | spherical-mode source **unstable** | HF method **NOT VALID** (< 30 cm) |
| 3 | 40 cm + box | all 3 methods agree | HF method **VALID** (≥ 40 cm) |

**The tool reproduces the paper's method-selection decision from geometry alone — `EXACT_NUMERICAL`,
Tier 1.** This was not identified at all in the earlier write-up.

**GEO application.** S-band TC&R on a rod ≥ 40 cm; neighbours SBAS (L), DCS (L), fixed-comm (Ka),
solar panels. **Reported result: gain *and* axial-ratio ripple ≤ 1–3 dB over the required coverage.**

**Correction to the earlier script.** It built the installed pattern as free-space −1.5 dB with +4 dB
in the back region — **both numbers invented**, making its headline "peak Δ = −1.5 dB" a tautology
(the input echoed as output). Replaced with the paper's **reported 1–3 dB ripple envelope**, and the
result is now labelled for what it is: an **instrument read-back check** of the comparison metric,
not a reproduction of the physics.

**Also fixed:** `PatternComparison` was silently using its own 15° default grid (n=325) while the
script advertised a 5° grid. The script now passes the grid explicitly (n=2701).

**Still Tier 4:** the installed pattern itself (paper: FEKO/HFSS) and **axial ratio**, which is a
headline result of the paper and has **no channel at all** in this architecture.

## 3. RC-KARI-03 — what the paper actually does

**Content.** GEO positioning satellite with a **large orbital inclination**; the S-band TC&R antenna
shares the platform with several satellite-navigation service antennas. Verification tool: **FEKO**
with an antenna source file. **Reported result: structure and neighbouring-antenna effect on the
S-band radiation characteristics is negligible (미미); the coverage requirement is satisfied.**

**The decisive sentence** (missed entirely in the earlier write-up): the placement was arrived at
**"이들 안테나간 RF 간섭 분석을 기초로"** — *on the basis of RF interference analysis between the
antennas*. That upstream step **is exactly what this tool computes**; FEKO then verified it.

The script now performs that inter-antenna screening (S-band TC&R ↔ three navigation antennas:
distance, off-boresight at both ends, lobe region) plus the platform-body FOV check and the stand-off
validity check. **This case is the clearest confirmation of the architecture's intended role**:
screening chooses the placement, a full-wave solver proves it. Tier 4 here is the correct boundary.

## 4. RC-KARI-RF-01 — two real defects found and fixed

Full text unavailable (abstract only, and the abstract carries **no numeric values**). Two genuine
defects were nevertheless exposed:

**DEFECT-A — small-signal IM3 law applied in saturation, reported `VALID`.** With tones 17 dB
*above* P1dB_in, the analyzer returned `P_IM3,in = +6 dBm` — **14 dB above the fundamental tone**,
physically impossible — with `validity = VALID` and zero warnings. `OUTSIDE_MODEL_DOMAIN` existed but
was wired only to `f_IM ≤ 0`. **This is precisely the paper's regime** (its subject *is* LNA
saturation). Fixed: `IntermodulationAnalyzer` now requires the tones to sit a configurable margin
(default 10 dB) below `P1dB_in`, and additionally rejects any product exceeding its own fundamental.
Both conditions set `OUTSIDE_MODEL_DOMAIN` with an explicit warning; the level is **withheld, not
fabricated**. New result fields: `p1dB_in_dBm`, `smallSignalMargin_dB`, `toneHeadroomBelowP1dB_dB`.

**DEFECT-B — the "S-band" interferers were L-band, reverse-engineered to force the conclusion.** The
script used f1 = 1.600 GHz, f2 = 1.625 GHz. **S-band is 2–4 GHz**; both tones were L-band, sitting
essentially *inside* L1's neighbourhood so that `2f1−f2 = 1.575 GHz` landed in L1 almost by
construction. That is fitting the input to the desired answer. Fixed: f2 is now **derived** from
`f2 = 2·f1 − f_L1` and both tones are checked against the S-band definition. The script now reports
the **required tone spacing** — a genuinely transferable screening result:

| f1 [GHz] | required f2 [GHz] | f2 in S-band? | spacing [MHz] |
|---|---|---|---|
| 2.00 | 2.4246 | yes | 424.6 |
| 2.20 | 2.8246 | yes | 624.6 |
| 2.25 | 2.9246 | yes | 674.6 |

⇒ a two-tone S-band IM3 reaches L1 only for **widely spaced** tones (≳ 425 MHz); closely spaced
telemetry tones (2.20 & 2.25 GHz) **cannot** do it. The product frequency itself is reproduced
exactly (1.57542 GHz, `EXACT_NUMERICAL`, Tier 1).

**Still Tier 4:** the **C/N0 degradation** — the paper's headline result — has no channel in this
tool.

## 5. Code changes made

| Change | Kind | Why |
|---|---|---|
| `nonlinear/IntermodulationAnalyzer`: small-signal domain guard | **defect fix** | DEFECT-A |
| `results/IntermodulationProduct`: 3 new domain fields | supporting | DEFECT-A |
| `geometry/DiskGeometry` (new primitive, rim-sampled) | gap fix | the paper's P-ANT **is** a dish; a square panel's corner sampling overestimates its subtense by √2 |
| `geometry/GeometryProvenance`: `PUBLIC_REPORTED`, `PUBLIC_DIGITIZED`, `ASSUMED_FOR_REPLICATION` | consistency fix | Phase 6 documented these classes in `data/reference_cases/README.md` but the code could not express them |
| all four `rc_kari_*.m` rewritten on verified paper data | correction | the earlier scripts modelled structures the papers do not contain |
| `PatternComparison` grid passed explicitly in RC-02 | correction | silent 15° default masked the stated resolution |

## 6. Regression

**628 assertions across 36 files, all passing** under GNU Octave 8.4 (baseline 579 → 598 → **628**).
New assertions cover: the IM3 domain guard in both regimes, the paper's 4°/12° subtense values,
disk-vs-square-panel sampling, RC-02 validity thresholds, explicit-grid comparison, `DiskGeometry`
ray behaviour, and the new provenance classes. MATLAB: **NOT RUN** (unavailable here; not claimed).

## 7. Honest scorecard after verification

| Case | Reproduced quantity | Class | Tier | Paper's headline result |
|---|---|---|---|---|
| RC-KARI-01 | P-ANT angular subtense (4.30° / 11.85°) | `EXACT_NUMERICAL` | 1 | dB gain change → **Tier 4** |
| RC-KARI-02 | method-validity decision (30–40 cm) | `EXACT_NUMERICAL` | 1 | 1–3 dB gain+AR ripple → **Tier 4** |
| RC-KARI-03 | inter-antenna placement screening | `SAME_TREND` | 2 | "negligible", AR → **Tier 4** |
| RC-KARI-RF-01 | IM3 product frequency + required spacing | `EXACT_NUMERICAL` | 1 | C/N0 degradation → **Tier 4** |

**Every paper's headline result is Tier 4** — all four are dB-level EM or C/N0 outcomes. What the
tool now reproduces exactly is the **geometric / arithmetic precondition** each paper's sweep is
parameterized by. That is a real and useful result, and it is the honest ceiling without external EM
evidence.
