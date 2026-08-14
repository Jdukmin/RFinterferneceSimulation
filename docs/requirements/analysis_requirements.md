# Analysis Requirements

**Phase:** 1. Defines the required analysis *computations* and their deterministic behavior.
Cross-references System Requirements (SR-xxx) and is made field-normative by the ICD.

---

## 1. Analysis Pipeline

- **AR-001 (SHALL)** The core analysis flow shall be, in order:
  `Scenario → active TX/RX → TX×RX pair generation → relative geometry → TX & RX local
  direction (az/el) → pattern lookup (TX gain, RX gain) → frequency relation → coupling model →
  receiver susceptibility → PairResult → interference matrix`. *(Task §22)*
- **AR-002 (SHALL)** The pipeline shall be **deterministic**: identical inputs yield identical
  outputs (no randomness, no hidden global state). *(Task §34)*

## 2. Geometry Analysis

- **AR-010 (SHALL)** For an ordered pair (TX *i*, RX *j*) with body-frame positions
  `r_tx`, `r_rx`, the engine shall compute the body-frame direction
  `d_tx→rx = r_rx − r_tx` and its negation `d_rx→tx = −d_tx→rx`. *(Task §12)*
- **AR-011 (SHALL)** The engine shall transform `d_tx→rx` into the **TX antenna local frame**
  and report `az_tx_deg, el_tx_deg`; and transform `d_rx→tx` into the **RX antenna local frame**
  and report `az_rx_deg, el_rx_deg`. *(Task §12)*
- **AR-012 (SHALL)** Distance shall be symmetric: `distance(A,B) = distance(B,A)`. *(Task §34)*
- **AR-013 (SHALL)** Direction shall be anti-symmetric: `d_AB = −d_BA`. *(Task §34)*
- **AR-014 (SHALL)** Body↔Local transforms shall round-trip: `v ≈ R_AB · (R_BA · v)` within
  numeric tolerance. *(Task §34)*
- **AR-015 (SHALL)** When TX and RX positions coincide (zero separation), az/el are undefined;
  the engine shall not divide by zero and shall flag the result. *(robustness)*

## 3. Pattern Lookup

- **AR-020 (SHALL)** Pattern lookup shall return directional gain in dBi for a given
  `(frequency_Hz, az_deg, el_deg)`. *(Task §13)*
- **AR-021 (SHALL)** Angular interpolation shall be **bilinear** in (az, el) on the pattern grid.
- **AR-022 (SHALL)** Azimuth shall be treated as **periodic** (wrap at ±180° / 360°);
  elevation shall be **clamped** to its physical range [−90°, +90°] (boundary behavior). *(Task §13)*
- **AR-023 (SHALL)** Frequency handling policy shall be explicit (Phase-1 default:
  nearest-supported-frequency within tolerance; linear across two planes when configured;
  out-of-range → out-of-domain behavior per policy). *(Task §13)*
- **AR-024 (SHALL)** Exact grid-point lookups shall return the stored value (interpolation is
  identity at nodes). *(Task §33)*
- **AR-025 (SHALL)** Missing/out-of-domain data (e.g., frequency outside support) shall yield a
  documented behavior (error or NaN gain + `OUTSIDE_PATTERN_DOMAIN` validity), never a silent
  wrong value. *(Task §13, §33)*

## 4. Lobe Classification

- **AR-030 (SHALL)** Given a pattern, a frequency, and a direction, the engine shall classify the
  lobe as `MAIN`, `SIDE`, or `BACK` using a **configurable** policy. *(Task §14)*
- **AR-031 (SHALL)** Default policy: `MAIN` if `gain ≥ peakGain − mainDropDb`; `BACK` if the
  angle from boresight exceeds `backAngleDeg`; otherwise `SIDE`. All thresholds configurable;
  none hard-coded in the engine. *(Task §14)*
- **AR-032 (SHALL)** Lobe class shall be reported as metadata alongside — never instead of — the
  actual gain value used in metrics. *(Task §14)*

## 5. Frequency Relation

- **AR-040 (SHALL)** Given TX occupied band `[fc_tx ± bw_tx/2]` and RX band `[fc_rx ± bw_rx/2]`
  (or RX filter passband when present), the engine shall classify the relation as at least
  `IN_BAND` (overlap), `ADJACENT_BAND` (within a configurable guard), or `OUT_OF_BAND`, and
  report the spectral overlap bandwidth in Hz. *(Task §17; AR-090)*
- **AR-041 (Reserved)** The classification enum shall be extensible to `BLOCKING_COMPRESSION`
  and `INTERMODULATION_SPURIOUS`, which depend on receiver front-end data not required in Phase 1.

## 6. Coupling (Pattern-Only, Phase-1)

- **AR-050 (SHALL)** `PatternOnlyCouplingModel` shall compute a **DirectionalCouplingIndex** in
  dB defined as `DCI_dB = G_tx(dir_tx) + G_rx(dir_rx)`, explicitly a *screening index*, not
  isolation/S21. *(Task §20)*
- **AR-051 (SHALL)** The pattern-only coupling result shall carry coupling-validity
  `PATTERN_ONLY` and shall **not** include any path-loss term. *(Task §19, §20)*
- **AR-052 (SHALL)** A pattern-only *interference screening metric* MAY combine TX power and the
  directional index (e.g., `P_tx_dBm + G_tx + G_rx`, referenced to the RX antenna port as an
  *upper-bound screening index with no path loss*), and if produced it shall be labeled as such
  with validity `FAR_FIELD_NOT_VERIFIED`. It shall never be presented as received power. *(Task §20, §21)*
- **AR-053 (Reserved)** `FarFieldCouplingModel` may compute a Friis-based coupling **only** when
  far-field validity is established from both antennas' largest aperture dimension and the
  separation (Fraunhofer distance `2D²/λ`); otherwise it shall return
  `FAR_FIELD_INVALID_OR_UNKNOWN` without a coupling number. *(Task §18, §19)*

## 7. Receiver Susceptibility

- **AR-060 (SHALL)** When a receiver interference threshold is present, the engine shall compute
  a **margin** (`threshold − screeningMetric`, at a documented reference plane) and report it.
- **AR-061 (SHALL)** When required receiver data is absent, the engine shall report the margin as
  `NaN` and set validity `MISSING_RECEIVER_DATA`, never invent a threshold. *(Task §39, §40)*

## 8. Pairwise & Matrix Results

- **AR-070 (SHALL)** The engine shall analyze every ordered TX→RX pair among active systems
  (N transmitters × M receivers), skipping the self-pair only when TX and RX share the same
  antenna/system. *(Task §12, §25)*
- **AR-071 (SHALL)** The engine shall assemble results into a matrix keyed by TX-id (rows) and
  RX-id (columns), each cell holding a `PairResult` and a derived **risk level**. *(Task §25)*
- **AR-072 (SHALL)** Risk-level thresholds (OK/LOW/WARN/HIGH) shall be configurable. *(Task §14, §25)*
- **AR-073 (SHALL)** The diagonal / self-pairs shall be represented as a distinct non-analyzed
  state (e.g., `NA`). *(Task §25)*

## 9. Result Validity & Confidence

- **AR-080 (SHALL)** Every `PairResult` shall carry a validity state and a confidence value; a
  high-risk pair shall not be reduced to a single over-confident number. *(Task §40)*
- **AR-081 (SHALL)** Warnings (out-of-domain lookups, zero separation, missing data,
  far-field-not-verified) shall be accumulated on the result, not discarded. *(Task §24, §40)*

## 10. Frequency-Relation Guard (parameterization)

- **AR-090 (SHALL)** The adjacent-band guard bandwidth shall be a configurable parameter with a
  documented default; `IN_BAND`/`ADJACENT_BAND`/`OUT_OF_BAND` boundaries shall be reproducible.

## 11. Pattern-Data Canonicalization Analysis (Phase 2)

Deterministic behavior of the import/canonicalization pipeline. Normative detail: ICD
`pattern_data.md`.

- **AR-100 (SHALL)** Canonicalization shall be deterministic: identical source data + convention +
  policy yield identical `CanonicalPatternCut`. *(§42)*
- **AR-101 (SHALL)** `theta → source direction` shall follow the data-driven descriptor mapping
  `d = cosd(θ)·z0 + sind(θ)·t0` (ICD `pattern_data.md` §1.1). *(§14)*
- **AR-102 (SHALL)** Canonical `theta` shall be recovered geometrically from the physical
  direction (`atan2d` of in-plane components), giving `[-180,180]→[0,360)`, `±180→180`,
  `0/360→0`, and absorbing rotation-direction/zero-axis differences. *(§9, §2.1)*
- **AR-103 (SHALL)** Uniform-step detection shall use `median(diff(theta))` with a documented
  tolerance; the pipeline shall report `UNIFORM`/`NON_UNIFORM`/`INVALID`. *(§6, §7)*
- **AR-104 (SHALL)** Interpolation on a cut shall be **periodic** over 360° and operate against
  the actual `theta_deg` vector (no `index = theta/step`). Wrap continuity across `0/360` shall
  hold. *(§13, §20)*
- **AR-105 (SHALL)** Duplicate resolution shall follow the deterministic policy of ICD
  `pattern_data.md` §6 (mean-merge within tolerance; warn/error on conflict), recording evidence.
  *(§10, §11)*
- **AR-106 (SHALL)** The Canonical→Antenna frame map `M` (ICD `pattern_data.md` §1.2) shall be
  applied only in `CutPatternAssembler`; the source `+Z` boresight shall never enter the Phase-1
  core implicitly. *(§3, §37)*
- **AR-107 (SHALL)** A 3D antenna pattern assembled from 2D cuts shall use the documented two-cut
  azimuthal-interpolation approximation and be labeled `APPROX_FROM_CUTS`. *(§21, §11 assembler)*
- **AR-108 (SHALL)** The assembled `FreeSpacePattern` shall feed the **existing** Phase-1
  `PairwiseAnalyzer` unchanged; Phase 2 shall not introduce a separate interference engine.
  *(§36)*

## 12. Linear RF Coexistence Analysis (Phase 3)

Normative detail: ICD `spectrum.md`, `receiver_susceptibility.md`.

- **AR-200 (SHALL)** The spectral/noise/criterion pipeline shall be deterministic. *(§47)*
- **AR-201 (SHALL)** Spectrum normalization: `∫ PSD_W(f) df = P_total_W` over support. *(§7)*
- **AR-202 (SHALL)** TX and RX may have independent frequency grids; a deterministic **union**
  integration grid shall be built without mutating source grids. *(§10, §11)*
- **AR-203 (SHALL)** The spectral overlap integral shall be computed in **linear** units by the
  midpoint rule on the union grid, exact for piecewise-constant rectangular/ideal cases. *(§8, §35)*
- **AR-204 (SHALL)** Filter response shall be power gain in dB with deterministic dB→linear
  conversion applied **before** the linear integration. *(§9)*
- **AR-205 (SHALL)** Noise power shall be `N_W = k·T·F·B` (NF method, `T=T0`) or `k·Tsys·B`. *(§17)*
- **AR-206 (SHALL)** `I/N_dB = P_I_dBm − N_dBm`, computed only when both are physically valid. *(§20)*
- **AR-207 (SHALL)** `Margin_dB = Allowable − Actual` (single fixed sign convention; `>0` PASS). *(§21)*
- **AR-208 (SHALL)** Mode-B absolute interference: `P_I_dBm = txPower_dBm + absoluteTransfer_dB +
  spectralFactor_dB`, referenced to `RECEIVER_RF_INPUT`. *(§16)*
- **AR-209 (SHALL)** `absoluteTransfer_dB` shall be available only for physical (far-field-valid)
  coupling (`= Gtx + Grx − FSPL`); pattern-only ⇒ absolute unavailable. *(§14, §15)*
- **AR-210 (SHALL)** `FrequencyRelation` classification shall be metadata only and shall not
  replace spectral integration when spectra/filters exist. *(§12, §31)*
- **AR-211 (SHALL)** Noise bandwidth shall be the filter equivalent noise bandwidth (ENBW). *(§17)*
- **AR-212 (SHALL)** Result validity shall map from coupling validity and missing-data
  (`ABSOLUTE_COUPLING_UNAVAILABLE`, `NOISE_MODEL_INCOMPLETE`, `MISSING_CRITERION`, `MISSING_FILTER`).
  *(§14, §39)*
- **AR-213 (SHALL)** Phase-3 shall reuse the Phase-1 pairwise/coupling results; it shall not
  recompute geometry or directional gain. *(§13)*
- **AR-214 (SHALL)** Confidence shall derive from coupling validity and spectrum/filter
  provenance, not be invented. *(§14)*
- **AR-215 (SHALL)** Result/data structures shall keep future aggregate multi-TX interference
  possible (linear-additive); full aggregation may be deferred. *(§25, §26)*

## 13. Receiver Nonlinear Analysis (Phase 4)

Normative detail: ICD `receiver_nonlinear.md`.

- **AR-300 (SHALL)** Per-interferer LNA-input power: `P_lna,i = txPower_i + absoluteTransfer_dB(i)
  + H_pre_dB(f_i)`, with `absoluteTransfer_dB = Gtx+Grx−FSPL` from physical (far-field-valid)
  coupling only; pattern-only ⇒ `P_lna,i = NaN`. *(§4, §5)*
- **AR-301 (SHALL)** Aggregate power `P_agg = w2dbm(Σ dbm2w(P_lna,i))` over valid interferers;
  determinism preserved. *(§8)*
- **AR-302 (SHALL)** `CompressionMargin_dB = p1dB_in − P_agg`. *(§7)*
- **AR-303 (SHALL)** `offset_Hz = f_i − f_rx_center`; `BlockingMargin = allowable(offset) −
  P_lna,i`; evaluated even with no spectral overlap. *(§13, §14)*
- **AR-304 (SHALL)** IM3 product frequencies `2f1−f2`, `2f2−f1` computed exactly. *(§15)*
- **AR-305 (SHALL)** `P_IM3_in(2f1−f2) = 2P1 + P2 − 2·IIP3`; `P_IM3_in(2f2−f1) = 2P2 + P1 −
  2·IIP3` (dBm); equal-tone reduces to `3P − 2·IIP3`. *(§16, §18)*
- **AR-306 (SHALL)** Third-order scaling: `+Δ` on both tones ⇒ `+3Δ` IM3; `+Δ` on IIP3 ⇒ `−2Δ`
  IM3. *(§36)*
- **AR-307 (SHALL)** `effectiveProductPower = P_IM3_in + H_chan(f_IM)`; `inPassband = f_IM ∈ RX
  band`. *(§19)*
- **AR-308 (SHALL)** IM3 enumerated over unordered distinct pairs `i<j`; no self/duplicate. *(§26)*
- **AR-309 (SHALL)** Aggregate/nonlinear validity: `ABSOLUTE_COUPLING_UNAVAILABLE` if none valid;
  `INCOMPLETE_INTERFERER_SET` if some invalid; `MISSING_P1DB`/`MISSING_IIP3`/
  `MISSING_BLOCKING_CRITERION` when hardware/criterion absent. *(§10, §31)*
- **AR-310 (SHALL)** Scenario nonlinear analysis reuses Phase-1 pairwise; interferers = active TX
  excluding self and optional wanted. *(§24, §25, §27)*
- **AR-311 (SHALL)** Nonlinear analysis shall compute no geometry and parse no files. *(§47)*
