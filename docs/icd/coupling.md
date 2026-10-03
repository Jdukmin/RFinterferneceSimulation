# ICD — Coupling Model

Requirements: SR-080…SR-083, AR-050…AR-053. This is the **critical abstraction boundary**
between pattern-only screening and real electromagnetic coupling (reference.md rule 1).

---

## 1. `coupling.CouplingModel` (abstract)

Contract:
```
result = model.computeCoupling(ctx)
```
`ctx` is a struct of already-computed pair quantities (so the coupling model is independent of
geometry/pattern internals):

| ctx field | Type | Unit | Meaning |
|-----------|------|------|---------|
| `distance_m` | double | m | TX↔RX separation |
| `txGain_dBi` | double | dBi | TX gain toward RX (`G_tx(dir_tx)`) |
| `rxGain_dBi` | double | dBi | RX gain toward TX (`G_rx(dir_rx)`) |
| `frequency_Hz` | double | Hz | analysis frequency (TX `fc` in Phase 1) |
| `txPower_dBm` | double | dBm | TX input power |
| `txMaxDim_m` | double | m | TX largest aperture dim (`NaN` if unknown) |
| `rxMaxDim_m` | double | m | RX largest aperture dim (`NaN` if unknown) |

Returns `coupling.CouplingResult`:

| Field | Type | Unit | Meaning |
|-------|------|------|---------|
| `modelType` | char (CouplingModelType) | — | which model produced this |
| `validity` | char (CouplingValidity) | — | `PATTERN_ONLY` / `FAR_FIELD_VALID` / `FAR_FIELD_INVALID_OR_UNKNOWN` / `MEASURED_COUPLING` / `FULL_WAVE_COUPLING` |
| `metric_dB` | double | dB | the coupling metric (**semantics depend on `modelType`** — see below) |
| `metricName` | char | — | human name of the metric (prevents misreading) |
| `isPhysicalCoupling` | logical | — | `false` for pattern-only screening index; `true` for S21/full-wave |
| `warnings` | cellstr | — | e.g. far-field-not-verified |

**Invariant (VR-082):** a pattern-only model sets `modelType=PATTERN_ONLY`,
`isPhysicalCoupling=false`, and `metricName='DirectionalCouplingIndex_dB'`. It must **never** set
`modelType=MEASURED_S21` or claim `isPhysicalCoupling=true`.

## 2. `coupling.PatternOnlyCouplingModel` (Phase-1 implementation, SR-080, AR-050)

- `metric_dB = txGain_dBi + rxGain_dBi` → the **DirectionalCouplingIndex** (AR-050).
- `metricName = 'DirectionalCouplingIndex_dB'`; `modelType = PATTERN_ONLY`;
  `validity = PATTERN_ONLY`; `isPhysicalCoupling = false`.
- **No path-loss term** is applied (AR-051). This index is a *relative screening quantity*
  (higher ⇒ more directional overlap ⇒ more worth verifying), **not** isolation and **not** S21.
- It contains no distance dependence by itself; distance is retained on the `PairResult` for
  context and for later models.

## 3. `coupling.FarFieldCouplingModel` (reserved, guarded — SR-083, AR-053)

Optional. Computes a Friis-based coupling **only when far-field validity is established**:
- Far-field (Fraunhofer) distance for an aperture of largest dimension `D` at wavelength `λ`:
  `R_ff = 2·D²/λ`. Far-field is considered valid for the link **only if**
  `distance_m ≥ max(R_ff_tx, R_ff_rx)` **and** both `txMaxDim_m`, `rxMaxDim_m` are known and
  `distance_m` ≥ a few wavelengths.
- If valid: `metric_dB = FSPL(distance, f)` where
  `FSPL_dB = 20·log10(4π·distance/λ)`; `validity = FAR_FIELD_VALID`;
  `isPhysicalCoupling = true`; `metricName='FreeSpacePathLoss_dB'`. Received power screening then
  = `txPower + txGain + rxGain − FSPL` (computed by analyzer, referenced to RX input).
- If aperture dims unknown or `distance_m < R_ff`: **no FSPL is applied**; returns
  `validity = FAR_FIELD_INVALID_OR_UNKNOWN`, `metric_dB = NaN`, warning
  `'far-field not verified; FSPL not applied'` (SR-081). This enforces the near-field caution
  (rule 6): a link-budget FSPL is never auto-applied to short on-platform separations.

## 4. Reserved coupling models (interfaces only — SR-083)

`MeasuredS21CouplingModel` and `HFSSCouplingModel` are declared subclasses whose `computeCoupling` raises a clear
`rfscreen:coupling:NotImplementedPhase1` error (or returns
`validity=REQUIRES_FULL_WAVE_VERIFICATION` when constructed in a "declare-only" mode). They exist
to prove the extension boundary; they do **not** fabricate coupling numbers (SR-120, "no fake
physics").

## 5. Near/Far-Field state → result validity mapping

| CouplingValidity | Contributes ResultValidity |
|------------------|----------------------------|
| `PATTERN_ONLY` | `VALID_PATTERN_SCREENING` (+ `FAR_FIELD_NOT_VERIFIED` if a distance-based number were requested) |
| `FAR_FIELD_VALID` | `APPROXIMATE` |
| `FAR_FIELD_INVALID_OR_UNKNOWN` | `FAR_FIELD_NOT_VERIFIED` |
| `MEASURED_COUPLING` | `APPROXIMATE`→(measured) |
| `FULL_WAVE_COUPLING` | `APPROXIMATE`→(full-wave) |

A pattern-only, in-band, high-index pair that lacks receiver data or far-field verification is
reported as high-risk **screening** with `REQUIRES_FULL_WAVE_VERIFICATION` — never as a settled
isolation number (rule 9, SR-093).

## 6. `coupling.CstCouplingModel` — tabulated installed S21(f) (Phase 7, P7d-3)

`CouplingModelType.CST` is implemented. It consumes **tabulated port-to-port S21(f)** from a CST
export and never computes electromagnetics itself.

**Data.**
- `coupling.CstS21Table(txAntennaId, rxAntennaId, freq_Hz, s21_dB, opts)` — one ordered pair;
  `freq_Hz` strictly increasing and > 0; `s21_dB = 20·log10|S21|` finite and **≤ 0 dB** (passive;
  `rfscreen:coupling:activeS21` otherwise); optional `phase_deg`, `provenance`
  (`CST_FULLWAVE`, `SYNTHETIC_TEST`, …), `geometryId`, `sourceFile`, `referenceImpedance_ohm`.
  `atFrequency_dB(f)` — linear-in-dB interpolation; **NaN outside the range (no extrapolation)**.
  `bandPower_dB(band, 'MEAN_POWER'|'MAX')` — flat-PSD average of |S21|² (trapezoid on the table
  grid + interpolated edges) or worst point; NaN unless the table covers the whole band.
- `couplingdata.CstS21Importer` (the only file parser; `+coupling` parses no files, VR-121/VR-081):
  `fromCsv(file, txId, rxId, opts)` — header `frequency_hz|mhz|ghz`, `s21_db` [, `phase_deg`];
  `fromTouchstone(file, portAntennaIds, opts)` — `.sNp`, formats DB/MA/RI, units Hz…GHz, S-parameters
  only; returns a cell array of tables for every ordered pair, where the table for
  `portAntennaIds{i} → portAntennaIds{j}` holds **S(j,i)** (2-port file order S11 S21 S12 S22;
  N ≥ 3 row-major). Port ↔ antenna mapping is explicit, never guessed.

**Model.** `CstCouplingModel(tables, opts)`; `opts.bandReduction` = `MEAN_POWER` (default) | `MAX`;
`opts.assumeReciprocal` (default true: the reverse-direction table is used if only it exists, flagged
in `warnings`). `computeCoupling(ctx)` uses the new additive ctx fields (§1): `txAntennaId`,
`rxAntennaId`, `band_Hz` (TX/RX overlap band if overlapping, else the TX occupied band). Result:
- table found and covering the request: `modelType = CST`, `validity = FULL_WAVE_COUPLING`,
  `isPhysicalCoupling = true`, `metric_dB = S21` (a transfer **gain**), `metricName =
  'S21_PortToPort_dB'`, warnings carry provenance + geometry id;
- otherwise: `validity = S21_UNAVAILABLE` (new `CouplingValidity`), `metric_dB = NaN`,
  `isPhysicalCoupling = false`, with an explicit warning — never a free-space substitute.
`CST` cannot be selected by name in `InterferenceAnalyzer.makeCouplingModel` (it needs data): pass
the instance (`RfCoexistenceAnalyzer.analyze(scenario, cfg, model)`,
`NonlinearSusceptibilityAnalyzer.analyze(scenario, rxId, cfg, struct('couplingModel', model))`).
`HFSSCouplingModel` / `MeasuredS21CouplingModel` stay reserved.

## 7. `coupling.AbsoluteTransfer` — meaning of `absoluteTransfer_dB`

`AbsoluteTransfer.fromPair(pairResult)` is the single place that derives the absolute transfer used
by `ReceiverSusceptibilityAnalyzer.analyzeFromPair` and `NonlinearSusceptibilityAnalyzer`:

| `couplingModelType` | `absoluteTransfer_dB` | `couplingValidity` |
|---------------------|-----------------------|--------------------|
| `FAR_FIELD` (physical) | `Gtx + Grx − FSPL` | `FAR_FIELD_VALID` |
| `CST` (and other solver/measured S21 types) (physical) | **the S21 itself** (installed; both antennas' patterns are already in it, so `Gtx`/`Grx` are **not** added) | `FULL_WAVE_COUPLING` |
| `PATTERN_ONLY` | not absolute (NaN) | `PATTERN_ONLY` |
| unavailable | not absolute (NaN) | `FAR_FIELD_INVALID_OR_UNKNOWN` / `S21_UNAVAILABLE` |

`PairwiseAnalyzer` for a port-to-port model sets `receiverInputPower_dBm = txPower + S21`; pair
validity is `APPROXIMATE` (S21 present) or `REQUIRES_FULL_WAVE_VERIFICATION` (no table). Phase-3
confidence for `FULL_WAVE_COUPLING` is 0.95 (unchanged table). Interference power =
`txPower + absoluteTransfer + spectralFactor` with the S21 averaged over the same overlap band the
spectral factor refers to. Free-space patterns are never edited to include installation effects.
