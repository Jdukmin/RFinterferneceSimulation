# Reference Case Matrix — Phase 6

Maps each KARI reference case to its research question, tool component, reproduction script, and
observed reproducibility tier. **Reproducibility tiers are assigned *after* running the cases**
(§7). No paper fitting; no fake EM (§9, §29).

## Reference cases  (full texts obtained and read — see RPT-P6-06)

| Case | Citation (verified) | Research question | Primary tool component | Script |
|------|---------------------|-------------------|------------------------|--------|
| **RC-KARI-01** | 임원규 외, KSAS **2015 춘계**, **pp.832-835** — 위성 구조체 FOV 간섭에 의한 S대역 안테나 방사특성 영향 | How large may a payload-antenna reflector (P-ANT) in the S-band antenna's FOV be before the 1 dB allowance is exhausted? | `geometry.AntennaToStructureFOV` + `geometry.DiskGeometry` (angular subtense) | `rc_kari_01_structure_fov.m` |
| **RC-KARI-02** | 이선익·임원규·김중표, KSAS **2023 추계**, **pp.1261-1263** — S대역 안테나 위성 설치상태 성능 | Which installed-performance analysis method is valid at a given antenna stand-off, and how large is the installed ripple? | stand-off validity screening + `installed.PatternComparison` | `rc_kari_02_installed_pattern.m` |
| **RC-KARI-03** | 이선익·임원규, **항공우주시스템공학회(SASE) 2025 춘계** — 정지궤도위성 TT&C S대역 안테나 설치위치 전자장 해석 | Is the chosen placement (derived from inter-antenna RF interference analysis) acceptable? | `geometry.AntennaToAntennaFOV` screening + `AntennaToStructureFOV` | `rc_kari_03_installation_analysis.m` |
| **RC-KARI-RF-01** | 권병문 외, JKSAS **47(5) pp.388-396**, 2019 — S대역 신호에 의한 위성항법수신기 RF 간섭 (**not** an Im Won-gyu paper; platform is a **test launch vehicle**) | Can two S-band tones saturate a GNSS LNA and put an IM product in the GNSS band? | `nonlinear.CompressionAnalyzer` / `IntermodulationAnalyzer` | `rc_kari_rf_01_gnss_interference.m` |

## Per-case reproduction summary (verified against the full texts)

| Case | Paper's reported number | Tool's computed number | Class | **Tier** | Paper's headline result (Tier 4) |
|------|-------------------------|------------------------|-------|----------|----------------------------------|
| RC-KARI-01 | 4° ↔ ≈30 cm; 12° ↔ ≈83 cm @ ≈4 m; accept ≤ ≈80 cm | **4.30°** / **11.85°** / 11.42° | `EXACT_NUMERICAL` | **Tier 1** | ≤ 1 dB gain deformation (`MODEL_GAP_FULL_WAVE`) |
| RC-KARI-02 | min validity radius **30–40 cm**; Case 1 (40 cm) valid, Case 2 (4–5 cm) unstable | VALID / NOT VALID / VALID — matches all three cases | `EXACT_NUMERICAL` | **Tier 1** | 1–3 dB gain **and axial-ratio** ripple (`MODEL_GAP_AXIAL_RATIO`) |
| RC-KARI-03 | placement based on inter-antenna RF interference analysis; FEKO verdict "negligible" | inter-antenna screening matrix (dist / off-boresight / lobe) reproduced | `SAME_TREND` | **Tier 2** | "effect is negligible" + axial ratio (`MODEL_GAP_SCATTERING`) |
| RC-KARI-RF-01 | LNA saturated; two S-band tones → IM product in GNSS band | `2f1−f2 = 1.57542 GHz` exactly; required spacing ≥ ≈425 MHz; compression FAIL | `EXACT_NUMERICAL` + `SAME_TREND` | **Tier 1/2** | C/N0 degradation (**no C/N0 channel**) |

> **Two defects were found and fixed during verification** (RPT-P6-06 §4): the small-signal IM3 law
> was being applied in saturation and reported `VALID`; and the RC-RF-01 "S-band" tones were actually
> L-band, reverse-engineered so the product would land in L1.

## Reference case ↔ architecture matrix (observed, §45)

```
                          RC01  RC02  RC03  RF01
Pattern import / data      -     X     -     -
Antenna installation geom  X     X     X     -
Structure FOV              X     -     X     -
LOS / blockage             X     -     X     -
Angular footprint          X     -     X     -
FreeSpace/Installed        -     X     X     -
Pattern comparison         -     X     -     -
Linear RF (P_I/I-N)        -     -     -     X
Compression (P1dB)         -     -     -     X
Blocking                   -     -     -     (X)
IM3 (IIP3)                 -     -     -     X
--- declared boundaries (Tier 4, NOT implemented) ---
Scattering / reflection /  X     X     X     -
diffraction (full-wave)
Axial ratio / polarization -     X     -     -
```
`X` = exercised & reproduced within the declared physics domain; `(X)` = supported, illustrative in
the script; boundary rows are **reported gaps**, not failures (§8 Tier 4, §53 physics-boundary RP).

## Data provenance classes used (`data/reference_cases/`)

`PUBLIC_REPORTED`, `PUBLIC_DIGITIZED` (`DIGITIZED_FROM_PUBLIC_FIGURE`), `SYNTHETIC_SUPPORT`,
`ASSUMED_FOR_REPLICATION`. These are now expressible **in code** via
`geometry.GeometryProvenance` (extended in Phase 6). After the full texts were obtained the scripts
use **`PUBLIC_REPORTED`** for every value taken from a paper (P-ANT diameters, stand-off distances,
validity radii, ripple envelope, acceptance criteria) and `ASSUMED_FOR_REPLICATION` only where the
paper is silent (exact frequency, platform coordinates, front-end hardware). No proprietary or
mission data; no digitized figure was needed since the required values appear in the paper text.
