# RPT-P6-02 — KARI Reference Replication

Per-paper replication record. **No paper fitting** (§9): where the model gives Y and the paper
reports X, the discrepancy is *classified* (§10), never corrected by an additive fudge. Comparison
classes (§21): `EXACT_NUMERICAL`, `WITHIN_TOLERANCE`, `SAME_TREND`, `SAME_ORDER_OF_MAGNITUDE`,
`QUALITATIVE_ONLY`, `NOT_COMPARABLE`.

---

## RC-KARI-01 — Structure FOV effect on S-band radiation (KSAS 2015)

- **Citation:** 임원규, 권기호, 김중표, 이선익, 김상구, 원영진, 문홍열, 이상곤, "위성 구조체의
  FOV 간섭에 의한 S 대역 안테나의 방사 특성 영향성 분석", 한국항공우주학회 학술발표회, 2015.
- **Research objective:** quantify how spacecraft structure within an antenna's field of view
  alters S-band radiation characteristics.
- **Published method:** full-wave / installed antenna analysis of an S-band antenna with spacecraft
  structure in the FOV.
- **Published inputs (public):** structure presence in the FOV; S-band antenna. Exact CAD/material
  not available here.
- **Published outputs:** radiation-characteristic changes due to structure FOV interaction.
- **Tool mapping:** `AntennaToStructureFOV`, `LineOfSight`, angular footprint, lobe relation.
- **Reproduction inputs:** `ASSUMED_FOR_REPLICATION` bus (1.5 m box), deployed solar-array panel,
  S-band antenna on +Z face, synthetic `mainSideBack` pattern (`SYNTHETIC_TEST`).
- **Assumptions & why:** geometry dimensions/positions are needed to run the FOV engine but are not
  public → reconstructed as representative; the pattern is synthetic because the paper's measured
  cut is not published here.
- **Current result:** BUS `off-boresight 180°, azSpan≈143°, {BACK}`, centre-ray hit; SOLAR_ARRAY
  `off-boresight≈22°, {SIDE}`, centre-ray hit, 1.57 m. Geometry FOV/LOS deterministic.
- **Reference result:** measured/simulated radiation-pattern deformation (dB-level gain change).
- **Comparison class:** `SAME_TREND` for FOV geometry (structure does enter the FOV in the
  reported region); `NOT_COMPARABLE` for the EM RP deformation (no installed pattern supplied).
- **Difference / classification:** `MODEL_GAP_FULL_WAVE` (scattering/diffraction), `EXPECTED`.
- **Reproducibility tier:** **Tier 2** (FOV geometry) / **Tier 4** (EM RP change).
- **Conclusion:** the geometric cause (structure FOV occupancy) is reproduced and traceable; the
  electromagnetic *effect* magnitude requires full-wave/measured evidence the tool intentionally
  does not own.

---

## RC-KARI-02 — Installed S-band antenna performance (KSAS 2023)

- **Citation:** 이선익, 임원규, 김중표, "S대역 안테나의 위성 설치상태에서의 성능 연구",
  한국항공우주학회, 2023.
- **Research objective:** compare free/baseline vs spacecraft-installed antenna performance.
- **Published method:** installed-antenna simulation/measurement vs baseline.
- **Published inputs:** free-space and installed antenna configurations.
- **Published outputs:** installed pattern/gain changes (and, in such studies, axial-ratio trends).
- **Tool mapping:** `FreeSpacePattern`, `InstalledPattern`, `InstalledPatternSelector`,
  `PatternComparison`.
- **Reproduction inputs:** synthetic free-space S-band pattern; installed pattern built by
  **perturbing the free-space pattern's own gains** (−1.5 dB boresight, +4 dB back), marked
  `SYNTHETIC_TEST`. A real digitized figure would enter as `DIGITIZED_FROM_PUBLIC_FIGURE`.
- **Current result:** peak Δ = **−1.5 dB**, max |Δ| = **2.5 dB**, RMS = **1.71 dB**, boresight Δ =
  **−1.5 dB**; selection `INSTALLED`, provenance preserved (`SIMULATED_3D`, not upgraded).
- **Reference result:** paper-specific installed gain deltas (values not reproduced here — no
  digitized data included).
- **Comparison class:** `SAME_TREND` (installed boresight gain reduction, altered back region),
  `NOT_COMPARABLE` for axial ratio / polarization.
- **Difference / classification:** `MODEL_GAP_AXIAL_RATIO`, `MODEL_GAP_POLARIZATION` (channels not
  owned), `EXPECTED`; installed-pattern authority itself is `MODEL_GAP_INSTALLED_PATTERN` unless
  real data is supplied.
- **Reproducibility tier:** **Tier 2–3** (comparison workflow) / **Tier 4** (axial ratio, pol).
- **Conclusion:** the free-space↔installed comparison workflow is fully reproducible and
  provenance-safe; magnitude fidelity depends entirely on supplying real installed-pattern data.

---

## RC-KARI-03 — Installed-location EM analysis (KARI 2025)

- **Citation:** 이선익, 임원규, "위성항법 정지궤도위성 원격측정명령계 S대역 안테나 설치위치에서의
  전자장 해석", KARI research stream, 2025.
- **Research objective:** installed-location electromagnetic behavior of a TT&C S-band antenna.
- **Tool mapping:** installed environment (position + FOV + LOS) + explicit fidelity boundary.
- **Reproduction inputs:** `ASSUMED_FOR_REPLICATION` two candidate mount locations (+Z, +X faces),
  a boom appendage.
- **Current result:** per-location geometry evidence is deterministic (LOC_A boom off-boresight
  ≈51°, spans {SIDE,BACK,MAIN}, centre-ray hit, 0.64 m; LOC_B ≈110°, {BACK}, 0.46 m).
- **Comparison class:** `QUALITATIVE_ONLY` / `NOT_COMPARABLE` for the EM field solution.
- **Difference / classification:** `MODEL_GAP_SCATTERING`, `MODEL_GAP_REFLECTION`,
  `MODEL_GAP_DIFFRACTION`, all `EXPECTED`.
- **Reproducibility tier:** **Tier 1** position / **Tier 2** FOV-LOS / **Tier 4** full-wave field.
- **Conclusion:** this case validates the *architecture boundary* — the tool cleanly separates the
  reproducible installed-geometry evidence from the full-wave EM field it does not compute.

---

## RC-KARI-RF-01 — S-band → GNSS receiver RF interference (JKSAS 2019)

- **Citation:** 권병문, 신용설, 마근수, 주정갑, 지기만, "S 대역 신호에 의한 위성항법수신기의 RF
  신호간섭", 한국항공우주학회지, 2019. **(Not an Im Won-gyu paper — do not misattribute.)**
- **Research objective:** strong S-band signals degrading a GNSS receiver via active-antenna LNA
  saturation and intermodulation.
- **Tool mapping:** Phase-3 linear + Phase-4 `CompressionAnalyzer` / `BlockingAnalyzer` /
  `IntermodulationAnalyzer`.
- **Reproduction inputs:** `ASSUMED_FOR_REPLICATION` GNSS front end (P1dB_in −25 dBm, IIP3_in
  −15 dBm, gain 28 dB), two S-band interferers at −8 dBm LNA input, f1 = 1.60 GHz, f2 = 1.625 GHz.
- **Current result:** aggregate LNA input −4.99 dBm vs P1dB_in −25 dBm → **compression margin −20
  dB (FAIL)** (saturation); IM3 `2f1−f2 = 1.575 GHz` **inside** the GNSS L1 band, `2f2−f1 = 1.65
  GHz` outside.
- **Comparison class:** `SAME_TREND` (saturation direction; IM3 product falls in GNSS band).
- **Difference / classification:** exact levels not comparable (`REFERENCE_DATA_INCOMPLETE` —
  paper hardware IIP3/P1dB and link budget not available); **not fitted**.
- **Reproducibility tier:** **Tier 2** (trend/mechanism).
- **Conclusion:** the causal chain the paper describes (strong S-band → LNA saturation + IM3 into
  the GNSS band) is reproduced qualitatively with the correct mechanism and product frequencies;
  quantitative agreement needs the paper's hardware data.
