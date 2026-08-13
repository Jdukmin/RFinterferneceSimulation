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

`MeasuredS21CouplingModel`, `HFSSCouplingModel` (and, by the same pattern, CST/other-solver) are
declared subclasses whose `computeCoupling` raises a clear
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
