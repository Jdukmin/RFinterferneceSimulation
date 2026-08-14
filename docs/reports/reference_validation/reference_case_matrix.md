# Reference Case Matrix — Phase 6

Maps each KARI reference case to its research question, tool component, reproduction script, and
observed reproducibility tier. **Reproducibility tiers are assigned *after* running the cases**
(§7). No paper fitting; no fake EM (§9, §29).

## Reference cases

| Case | Citation (short) | Research question | Primary tool component | Script |
|------|------------------|-------------------|------------------------|--------|
| **RC-KARI-01** | 임원규 외, KSAS 2015 — 위성 구조체 FOV 간섭에 의한 S대역 안테나 방사특성 영향 | Does spacecraft structure in the antenna FOV change S-band radiation characteristics? | Phase-5 `AntennaToStructureFOV`, `LineOfSight`, angular footprint | `examples/reference_cases/rc_kari_01_structure_fov.m` |
| **RC-KARI-02** | 이선익·임원규·김중표, KSAS 2023 — S대역 안테나 위성 설치상태 성능 | Free-space vs spacecraft-installed antenna performance | Phase-2 pattern data + Phase-5 `FreeSpacePattern`/`InstalledPattern` + `PatternComparison` | `examples/reference_cases/rc_kari_02_installed_pattern.m` |
| **RC-KARI-03** | 이선익·임원규, KARI 2025 — 정지궤도위성 TT&C S대역 안테나 설치위치 전자장 해석 | Installed-location electromagnetic behavior at a chosen mount | Phase-5 installed environment (position/FOV/LOS) + **fidelity boundary** | `examples/reference_cases/rc_kari_03_installation_analysis.m` |
| **RC-KARI-RF-01** | 권병문·신용설·마근수·주정갑·지기만, JKSAS 2019 — S대역 신호에 의한 위성항법수신기 RF 간섭 (**not** an Im Won-gyu paper) | Strong S-band signals → GNSS active-antenna LNA saturation / IM3 into GNSS band | Phase-3 linear + Phase-4 `CompressionAnalyzer`/`BlockingAnalyzer`/`IntermodulationAnalyzer` | `examples/reference_cases/rc_kari_rf_01_gnss_interference.m` |

## Per-case reproduction summary (post-run)

| Case | Paper input (public) | Paper output | Reproduction inputs | Expected fidelity | **Observed tier** | Validation metric |
|------|----------------------|--------------|---------------------|-------------------|-------------------|-------------------|
| RC-KARI-01 | Structure geometry, S-band antenna, FOV interaction | RP characteristic change from structure FOV | `ASSUMED_FOR_REPLICATION` bus + solar array + boom geometry; synthetic S-band pattern | High (geometry) / None (EM RP) | **Tier 2** geometry FOV/LOS; **Tier 4** EM RP deformation (`MODEL_GAP_FULL_WAVE`) | FOV occupancy, angular footprint, off-boresight, LOS status |
| RC-KARI-02 | Free/installed antenna configs | Installed pattern/gain change | Synthetic free-space pattern; installed = free perturbed (illustrative); a real digitized cut would slot in as `DIGITIZED_FROM_PUBLIC_FIGURE` | Medium-High | **Tier 2–3** (comparison workflow); axial-ratio/pol **Tier 4** (`MODEL_GAP_AXIAL_RATIO/POLARIZATION`) | peak/max/RMS gain delta, boresight delta |
| RC-KARI-03 | Installation location, spacecraft EM environment | Installed EM behavior | `ASSUMED_FOR_REPLICATION` two mount locations + boom | Partial (boundary) | **Tier 1** position; **Tier 2** FOV/LOS; **Tier 4** scattering/reflection/diffraction | off-boresight, occupied lobes, centre-ray hit per location |
| RC-KARI-RF-01 | S-band interferers, GNSS receiver | LNA saturation / IM degradation of GNSS | `ASSUMED_FOR_REPLICATION` front-end P1dB/IIP3, interferer powers; f1/f2 chosen so 2f1−f2∈L1 | Medium | **Tier 2** (trend/mechanism) | compression margin sign, IM3 product frequency + in-band flag |

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
`ASSUMED_FOR_REPLICATION`. Phase-6 scripts use `ASSUMED_FOR_REPLICATION` + `SYNTHETIC_SUPPORT`
only — no proprietary/mission data, no digitized figure was available to include here; the
workflow supports digitized data with explicit provenance when provided.
