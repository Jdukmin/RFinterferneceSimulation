# ICD — Receiver Susceptibility & Linear RF Coexistence (Phase 3)

Normative interface for the linear RF coexistence chain: RX filter, spectral coupling, receiver
noise, interference criterion, and the receiver-susceptibility result. Requirements:
SR-200…SR-212, AR-200…AR-215, DR-200…DR-214. Linear only; nonlinear front-end deferred to Phase 4
(Task §23, §24, §46).

Packages: `src/+rfscreen/+receiver/`, spectral integration in `src/+rfscreen/+interference/`.

---

## 1. Reference planes — `receiver.ReferencePlane` (Task §4)

`TX_OUTPUT`, `TX_ANTENNA_INPUT`, `EIRP_REFERENCE`, `RX_ANTENNA_TERMINAL`, `RECEIVER_RF_INPUT`,
`POST_FILTER`. Canonical Phase-3 decisions:
- TX `power_dBm` / spectrum reference: `TX_ANTENNA_INPUT` (matches Phase-1).
- Interference power, noise power, and I/N are reported at **`RECEIVER_RF_INPUT`**, defined as the
  receiver input **after the preselector filter, before the LNA**. The filter response is applied
  to reach this plane; no unlabeled generic power is ever returned.

## 2. `receiver.ReceiverFilter` (abstract) + provenance (Task §9, §28)

Canonical response is **power gain in dB** (0 dB passband, negative = rejection), with
deterministic conversion to a linear power ratio.

| Method | Returns | Meaning |
|--------|---------|---------|
| `responseDb(f_Hz)` | double | power-gain response [dB] |
| `responseLinear(f_Hz)` | double | `10.^(responseDb/10)` (linear power ratio) |
| `nativeGrid_Hz()` | 1×N | breakpoints |
| `relevantBand_Hz()` | `[lo hi]` | band where response is non-negligible (for grid building) |
| `equivalentNoiseBandwidth_Hz()` | double | `∫ responseLinear df / max(responseLinear)` |

`provenance` (`FilterProvenance`: `IDEAL_MODEL`, `DATASHEET`, `MEASURED`, `SIMULATED`,
`SYNTHETIC_TEST`). Concrete:
- **`IdealBandpassFilter([lo hi], passbandGain_dB=0, stopbandGain_dB=-Inf)`** — piecewise-constant.
  `-Inf` stopband ⇒ linear 0 (full rejection). `nativeGrid=[lo hi]`.
- **`TabulatedFilterResponse(freq_Hz, gain_dB, opts)`** — response **interpolated in dB** across
  frequency (standard for filter masks), then converted to linear for the integration. Boundary:
  clamp to end values. This is filter-response interpolation, *not* power integration in dB.

## 3. `spectrum` × `filter` semantics (Task §12, §31)

`rf.FrequencyRelation` classification (`IN_BAND`/`ADJACENT_BAND`/`OUT_OF_BAND`) remains a **fast
screening metadata layer** and **does not** replace spectral integration when spectra + filters
exist. Adjacent-band classification ≠ adjacent-channel interference power (AR-210). The
`config.FrequencyRelationPolicy` guard and `config.RiskPolicy` thresholds are **screening**
policies, kept distinct from the physical `receiver.InterferenceCriterion` (Task §30, §31).

## 4. `receiver.ReceiverNoiseModel` (Task §17, §18)

Linear thermal-noise model, explicit terms and reference plane (`RECEIVER_RF_INPUT`).
Constructor `ReceiverNoiseModel(opts)` accepts exactly one method:
- `opts.noiseFigure_dB` (+ `opts.refTemp_K`, default 290): `N_W = k · T0 · F · B`, `F = 10^(NF/10)`.
- `opts.systemNoiseTemp_K`: `N_W = k · Tsys · B`.

`noisePower_dBm(bandwidth_Hz)` → `util.Units.w2dbm(N_W)`. `k = 1.380649e-23 J/K`
(`util.Constants.boltzmann_JperK`). Antenna vs receiver vs system temperature and NF are **not**
mixed without a documented conversion; if neither method is supplied the model cannot be
constructed and the analyzer reports `NOISE_MODEL_INCOMPLETE` (never invents defaults, Task §18).

## 5. `interference.SpectralCouplingAnalyzer` (Task §11, §35; NO geometry)

`analyze(spectrum, filter, opts)` integrates TX PSD against filter response, in linear units, over
a deterministic common grid — and computes **no geometry and no absolute power**.

Integration-grid policy (documented, deterministic):
1. Domain = spectrum `supportBand_Hz()` (PSD is 0 outside → no contribution).
2. Breakpoints = sorted-unique union of: support-band edges, spectrum `nativeGrid` within domain,
   filter `nativeGrid` within domain, filter `relevantBand` edges within domain, optionally
   refined to `opts.maxStep_Hz`.
3. Integrate by the **midpoint rule** on each subinterval: `Σ psd_W(mid)·responseLinear(mid)·Δf`.
   Exact for the piecewise-constant rectangular/ideal-bandpass analytical cases (Task §35).

Returns struct: `overlapPower_W` (= `∫ PSD·H df`, the TX power passing the filter shape, at the TX
reference plane), `overlapFraction` (`overlapPower_W / P_total_W`, dimensionless),
`spectralFactor_dB` (`10·log10(overlapFraction)`), `nGrid`, `domain_Hz`, `validity`, `warnings`.
Source grids are not mutated (Task §11).

## 6. `receiver.InterferenceCriterion` (Task §19, §21)

Physical acceptance criterion — **distinct** from screening risk. Types + `thresholdValue`:
- `I_N_MAX` (dB): actual = I/N; used when noise is available.
- `MAX_INTERFERENCE_POWER` (dBm): actual = interference power.

**Sign convention (fixed once, Task §21):** `Margin_dB = Allowable − Actual`.
`Margin > 0 → PASS`, `= 0 → boundary`, `< 0 → FAIL`. `evaluate(P_I_dBm, N_dBm)` returns
`struct(actual, margin_dB, pass, thresholdType, thresholdValue)`. Mission values live in
configuration/input, never hard-coded (Task §19, §29).

## 7. `receiver.ReceiverSusceptibilityResult` (Task §22)

| Field | Unit | Meaning / Missing |
|-------|------|-------------------|
| `mode` | — | `RELATIVE_SCREENING` or `ABSOLUTE_LINEAR` |
| `referencePlane` | — | `RECEIVER_RF_INPUT` |
| `spectralOverlapFraction` | — | dimensionless (always if spectrum+filter present) |
| `spectralFactor_dB` | dB | `10log10(fraction)` |
| `interferencePower_dBm` | dBm | absolute; `NaN` unless Mode B |
| `noisePower_dBm` | dBm | `NaN` if no noise model |
| `iOverN_dB` | dB | `NaN` unless both I and N valid |
| `thresholdType` | — | from criterion; `''` if none |
| `thresholdValue` | dB/dBm | criterion value; `NaN` if none |
| `margin_dB` | dB | `Allowable − Actual`; `NaN` if not computable |
| `passFail` | — | `PASS`/`FAIL`/`UNKNOWN` |
| `validity` | — | `receiver.SusceptibilityValidity` |
| `confidence` | — | [0,1] |
| `warnings` | — | never discarded |

`SusceptibilityValidity`: `VALID_ABSOLUTE`, `RELATIVE_SCREENING_ONLY`,
`ABSOLUTE_COUPLING_UNAVAILABLE`, `NOISE_MODEL_INCOMPLETE`, `MISSING_CRITERION`, `MISSING_FILTER`,
`MISSING_SPECTRUM`, `OUTSIDE_ANALYSIS_BAND`, `FAR_FIELD_NOT_VERIFIED`.

## 8. `receiver.ReceiverSusceptibilityAnalyzer` — the two modes (Task §16, §14, §15, §39)

`analyze(request)` where `request` carries `spatial` (struct: `txGain_dBi`, `rxGain_dBi`,
`txPower_dBm`, `absoluteTransfer_dB`, `isAbsolute`, `couplingValidity`), `txSpectrum`, `rxFilter`,
`noiseModel`, `criterion`, `config`.

1. **Spectral** (always, if spectrum+filter): `overlapFraction`, `spectralFactor_dB` via
   `SpectralCouplingAnalyzer`.
2. **Mode selection:** `ABSOLUTE_LINEAR` iff `spatial.isAbsolute` **and** `absoluteTransfer_dB`
   finite; else `RELATIVE_SCREENING`.
3. **Mode B (absolute):**
   `interferencePower_dBm = txPower_dBm + absoluteTransfer_dB + spectralFactor_dB` at
   `RECEIVER_RF_INPUT`. Noise via `noiseModel` at filter ENBW; `I/N = P_I − N`;
   criterion → margin/pass.
4. **Mode A (relative):** `interferencePower_dBm = NaN`, `iOverN_dB = NaN`, `margin_dB = NaN`,
   validity `ABSOLUTE_COUPLING_UNAVAILABLE`/`RELATIVE_SCREENING_ONLY`. The pattern-only
   DirectionalCouplingIndex is **never** promoted to an absolute link loss (Task §15, §42 — the
   central rule).

`absoluteTransfer_dB` is provided by the caller only when the coupling model is physical
(far-field valid): `= txGain_dBi + rxGain_dBi − FSPL_dB`. Pattern-only ⇒ `isAbsolute=false`.

## 9. `interference.RfCoexistenceAnalyzer` (Task §13, §26 — pairwise, reuse Phase-1)

`analyze(scenario, config)` reuses the **existing** Phase-1 `InterferenceAnalyzer` for the
geometric/pattern matrix, then, for each pair whose TX carries a `spectrum` and RX carries a
`filter`, builds the `spatial` evidence from the Phase-1 `PairResult` + `RFTransmitter` and runs
`ReceiverSusceptibilityAnalyzer`. Returns `struct(matrix, susceptibility, txIds, rxIds)` where
`susceptibility{i,j}` is a `ReceiverSusceptibilityResult` or `[]`. Geometry/directional-gain are
**not** recomputed (Task §13). Aggregate multi-TX is reserved (Task §25): results are additive in
linear W and do not preclude future summation.

## 10. RF wiring (optional, backward-compatible)

`RFTransmitter` gains optional `opts.spectrum` (a `SpectrumModel`); `RFReceiver` gains optional
`opts.filter` / `opts.noiseModel` / `opts.interferenceCriterion`. All default empty; Phase-1/2
construction and behavior are unchanged when they are absent.

## 11. Deferred to Phase 4 (Task §24, §46)

P1dB, compression/blocking, IIP3, IM2/IM3, mixer spurs, ADC saturation, harmonic/spurious TX
generation. Interfaces may be reserved (`RFFrontEnd` already holds `p1dB_dBm`/`iip3_dBm` as `NaN`);
**no nonlinear physics is implemented in Phase 3.**
