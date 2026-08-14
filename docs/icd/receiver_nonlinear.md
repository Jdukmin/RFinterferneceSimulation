# ICD — Receiver Nonlinear Interference & Multi-Interferer Analysis (Phase 4)

Normative interface for receiver front-end nonlinear susceptibility: blocking, compression (P1dB),
and third-order intermodulation (IIP3/IM3), driven by aggregate power from multiple simultaneously
active interferers. Requirements: SR-300…SR-316, AR-300…AR-320, DR-300…DR-316.

Builds on Phase-1/2/3 **without changing** their contracts. Central invariant (Task §4, Final
Rule): **no valid absolute coupling ⇒ no authoritative nonlinear result.** No nonlinear hardware
data ⇒ unsupported, never fabricated.

Packages: `src/+rfscreen/+receiver/` (front-end model + criteria), `src/+rfscreen/+nonlinear/`
(analyzers), `src/+rfscreen/+results/` (result data).

---

## 1. Signal chain & reference planes (canonical — Task §5, §20)

```
RX antenna terminal (RX_ANTENNA_TERMINAL)     P_ant,i = txPower_i + absoluteTransfer_i   [broadband]
        |  preselector filter  H_pre(f)        (optional; default all-pass 0 dB)
LNA input (LNA_INPUT)  <-- NONLINEAR REFERENCE PLANE
        |  LNA nonlinearity (P1dB_in, IIP3_in) -> compression + IM products generated here
        |  post-LNA / channel filter H_chan(f) (the wanted receive filter; reused from Phase 3)
IM product at f_IM evaluated vs channel filter + criterion
```

- **Nonlinear reference plane = `LNA_INPUT`** (after the preselector, before the LNA). New
  `receiver.ReferencePlane.LNA_INPUT` value. All P1dB/IIP3 quantities are **input-referred** to
  this plane (Task §6, §17).
- Per-interferer power reaching the LNA:
  `P_lna,i_dBm = txPower_i + absoluteTransfer_dB(i) + H_pre_dB(f_i)`, where
  `absoluteTransfer_dB = Gtx + Grx − FSPL` comes **only** from physical (far-field-valid) coupling
  (reused Phase-1/3 evidence). Pattern-only ⇒ `P_lna,i` unavailable (`NaN`).
- The narrow **channel** filter (Phase-3 wanted filter) is applied only to IM products landing in
  the receive band (§7 below), **not** to the blocker/compression power (Task §14): a strong
  blocker outside the wanted band still reaches the LNA.

## 2. `receiver.ReceiverFrontEnd` (Task §6, §21, §29, §30)

One dominant nonlinear front-end element at `LNA_INPUT`. Input-referred; unknowns stay `NaN`.

| Field | Unit | R/O | Meaning / Missing |
|-------|------|-----|-------------------|
| `linearGain_dB` | dB | O | small-signal gain (for optional output-referred derivation); `NaN` |
| `p1dB_in_dBm` | dBm | O | input 1-dB compression point; `NaN` ⇒ `MISSING_P1DB` |
| `iip3_in_dBm` | dBm | O | input third-order intercept; `NaN` ⇒ `MISSING_IIP3` |
| `noiseFigure_dB` | dB | O | optional; `NaN` |
| `preselector` | `ReceiverFilter` | O | filter **before** the LNA; `[]` ⇒ all-pass (0 dB) |
| `channelFilter` | `ReceiverFilter` | O | wanted filter **after** the LNA (IM product screening); `[]` |
| `referencePlane` | — | — | fixed `LNA_INPUT` |
| `provenance` | `FrontEndProvenance` | R | `DATASHEET`/`MEASURED`/`SIMULATED`/`USER_INPUT`/`SYNTHETIC_TEST` |

Input↔output conversions are explicit: `OIP3 = IIP3 + G`, `P1dB_out = P1dB_in + G − 1`. Phase 4
**never** mixes IIP3/OIP3 or input/output P1dB implicitly (Task §6).

## 3. Interferer aggregation (`nonlinear.InterfererAggregator`; Task §8, §9, §10)

- Aggregate **only** interferers with a valid absolute `P_lna,i` reaching the same plane
  (`LNA_INPUT`). `P_agg_dBm = util.Units.sumPowers_dBm([P_lna,i])` — **linear** sum, never dBm
  addition (Task §8).
- Invalid/absent absolute powers are **not** treated as zero; if any active interferer lacks valid
  absolute evidence, the aggregate is flagged `INCOMPLETE_INTERFERER_SET` (Task §10). If **none**
  are valid ⇒ `ABSOLUTE_COUPLING_UNAVAILABLE` and no aggregate power.

## 4. Compression (`nonlinear.CompressionAnalyzer` + `receiver.CompressionCriterion`; Task §7)

`CompressionMargin_dB = p1dB_in_dBm − P_agg_dBm` (Task §7 convention: `>0` below P1dB, `=0`
boundary, `<0` exceeds). P1dB is a compression-risk **criterion**, not an AM/AM curve.
`CompressionCriterion(requiredBackoff_dB=0)` ⇒ `pass = (p1dB_in − requiredBackoff − P_agg) ≥ 0`.
Validity: `MISSING_P1DB` if no `p1dB_in`; `ABSOLUTE_COUPLING_UNAVAILABLE`/
`INCOMPLETE_INTERFERER_SET` propagated from aggregation.

## 5. Blocking (`nonlinear.BlockingAnalyzer` + `receiver.BlockingCriterion`; Task §11–§14)

Modeled **separately** from P1dB and **independent of spectral overlap** (Task §14). Per
interferer: `offset_Hz = f_i − f_rx_center`; `actualBlocker_dBm = P_lna,i`;
`allowable_dBm = criterion(offset_Hz)`; `BlockingMargin_dB = allowable − actual` (Task §13 sign,
consistent with Phase 3). `BlockingCriterion`:
- **constant**: single `maxBlockerPower_dBm`.
- **tabulated**: `(offset_Hz → maxBlockerPower_dBm)`, interpolated in dB, clamped at boundaries.

A `NO_OVERLAP` interferer is still evaluated for blocking (mandatory). Validity:
`MISSING_BLOCKING_CRITERION` if none; per-entry `ABSOLUTE_COUPLING_UNAVAILABLE` when `P_lna,i`
invalid (that blocker is skipped from the worst-margin, and flagged).

## 6. Intermodulation IM3 (`nonlinear.IntermodulationAnalyzer` + `receiver.IntermodulationCriterion`; Task §15–§22)

Two-tone third order over **unordered distinct** interferer pairs `(i,j), i<j` with valid absolute
`P_lna`. For tones `f1=f_i, f2=f_j`, `P1=P_lna,i, P2=P_lna,j`:

- **Product frequencies (exact):** `2f1 − f2` and `2f2 − f1` (Task §15). Self-pairs and duplicate
  orderings are excluded (Task §26).
- **Input-referred IM3 power (documented convention, Task §16–§18):**
  `P_IM3_in(2f1−f2) = 2·P1 + P2 − 2·IIP3_in`, `P_IM3_in(2f2−f1) = 2·P2 + P1 − 2·IIP3_in`
  (all dBm). Reduces to the classic equal-tone `3·P − 2·IIP3`. Supports unequal tones.
  Output-referred (if reported): `P_IM3_out = P_IM3_in + linearGain_dB` (derived explicitly).
- **Third-order scaling invariant (Task §36):** raising both tones by `Δ` raises `P_IM3_in` by
  `3·Δ`; raising `IIP3` by `Δ` lowers it by `2·Δ`.
- **Passband relevance (Task §19, §20):** the product at `f_IM` passes the **channel** filter
  (reused Phase-3 filter, or the RX band as an ideal bandpass if none):
  `effectiveProductPower_dBm = P_IM3_in + H_chan_dB(f_IM)`; `inPassband` = `f_IM ∈ RX band`.
- **Criterion:** `IntermodulationCriterion('MAX_IM3_INPUT_POWER', maxDbm)` ⇒
  `Margin_dB = maxDbm − effectiveProductPower_dBm`.

## 7. `IM2` (Task §23)

IM2 taxonomy (`f1+f2`, `|f1−f2|`, `2f1`, `2f2`) is documented but **not implemented**; IIP3 is
never used to fabricate IM2. Result carries `im2 = 'NOT_IMPLEMENTED'` (`NONLINEAR_MODEL_NOT_SUPPORTED`).

## 8. Nonlinear validity — `receiver.NonlinearValidity` (Task §31)

`VALID`, `VALID_WITH_WARNINGS`, `ABSOLUTE_COUPLING_UNAVAILABLE`, `MISSING_FRONT_END`,
`MISSING_P1DB`, `MISSING_IIP3`, `MISSING_BLOCKING_CRITERION`, `INCOMPLETE_INTERFERER_SET`,
`NONLINEAR_MODEL_NOT_SUPPORTED`, `OUTSIDE_MODEL_DOMAIN`. Warnings propagate to the final result.

## 9. Result data (`+results`; Task §22, §38)

Separate result objects (Phase-3 `PairResult`/`ReceiverSusceptibilityResult` semantics are
**unchanged**):
- **`results.CompressionResult`**: `referencePlane`, `aggregateInputPower_dBm`, `p1dB_in_dBm`,
  `compressionMargin_dB`, `passFail`, `nInterferers`, `nValidInterferers`, `validity`, `warnings`.
- **`results.BlockingResult`**: `referencePlane`, `entries` (struct array: `txId`, `blockerPower_dBm`,
  `offset_Hz`, `allowable_dBm`, `margin_dB`, `passFail`, `validity`), `worstMargin_dB`, `worstTxId`,
  `validity`, `warnings`.
- **`results.IntermodulationProduct`**: `txId1`, `txId2`, `f1_Hz`, `f2_Hz`, `p1_dBm`, `p2_dBm`,
  `productType` (`2F1_MINUS_F2`/`2F2_MINUS_F1`), `productFrequency_Hz`, `iip3_in_dBm`,
  `equivalentInputPower_dBm`, `channelResponse_dB`, `effectiveProductPower_dBm`, `inPassband`,
  `margin_dB`, `passFail`, `validity`, `warnings`.
- **`results.NonlinearSusceptibilityResult`**: `rxId`, `referencePlane`, `interfererIds`,
  `compression` (`CompressionResult`), `blocking` (`BlockingResult`), `im3` (cell of
  `IntermodulationProduct`), `im2` (`'NOT_IMPLEMENTED'`), `validity`, `warnings`.

## 10. Scenario nonlinear analysis (`nonlinear.NonlinearSusceptibilityAnalyzer`; Task §24–§27)

`analyze(scenario, rxId, config, opts)`:
1. Reuse Phase-1 `PairwiseAnalyzer` (via the scenario, with `config.couplingModel`) for each active
   TX → the selected RX. **No geometry/gain recompute** (Task §25).
2. Build per-interferer `LNA_INPUT` power from the pair evidence + `frontEnd.preselector`.
3. Interferers = active TX excluding any sharing the RX antenna (self) and an optional
   `opts.wantedTxId` (Task §27). Deterministic enumeration; IM3 over `i<j` pairs (Task §26).
4. Run compression, blocking, IM3; assemble `NonlinearSusceptibilityResult`.

`RFReceiver` gains optional `opts.receiverFrontEnd`, `opts.compressionCriterion`,
`opts.blockingCriterion`, `opts.intermodulationCriterion` (all default empty; Phase-1/2/3
construction unchanged).

## 11. Screening vs physics (Task §40) and deferrals (Task §41–§44)

Heuristic screening (`config.RiskPolicy`, `FrequencyRelation`) stays distinct from nonlinear
physical margins. **Deferred (not implemented):** TX nonlinearities (HPA compression, spectral
regrowth, harmonics, TX IMD, LO leakage, phase noise, DAC images, TX spurious), receiver mixer spur
tables, ADC saturation, and all Phase-5 EM/installation physics. Interfaces may be reserved; Phase 4
generates none of these.
