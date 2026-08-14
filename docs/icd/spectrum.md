# ICD — TX Spectrum Model (Phase 3)

Normative interface for representing a transmitter's spectral power distribution and integrating
it, in **linear units**, against a receiver filter. Requirements: DR-200…DR-206, AR-200…AR-206.
Builds on Phase-1/2 without changing the core (Task §3, §5–§8).

Package: `src/+rfscreen/+spectrum/`.

---

## 1. Units & the linear/log boundary (canonical — Task §8)

- Power spectral density (PSD) is stored and integrated in **linear** units: **W/Hz**.
- Total power is declared in **dBm**; converted to **W** via `util.Units` before integration.
- **dB values are never summed/integrated directly.** Integration is `∫ PSD_W(f) df` in W/Hz·Hz
  = W. Conversions W↔dBm and dB↔linear go through `util.Units` only (DR-002).
- Normalization contract: `∫ PSD_W(f) df = P_total_W` over the spectrum support band (AR-201).

## 2. Reference plane (Task §4)

Each spectrum declares the reference plane its `totalPower_dBm` refers to
(`receiver.ReferencePlane`, default `TX_ANTENNA_INPUT`, matching Phase-1 `power_dBm`). Downstream
power keeps that plane explicit; a spectrum never returns an unlabeled generic power.

## 3. `spectrum.SpectrumModel` (abstract)

| Method | Returns | Meaning |
|--------|---------|---------|
| `psd_WPerHz(f_Hz)` | double (elementwise) | absolute PSD [W/Hz] at `f_Hz`; 0 outside support |
| `supportBand_Hz()` | `[lo hi]` | frequency interval where PSD may be nonzero |
| `nativeGrid_Hz()` | 1×N | breakpoints of the model (band edges / tab nodes) |
| `totalPower_dBm()` | double | declared total power |
| `occupiedBandwidth_Hz()` | double | occupied/analysis bandwidth |
| `fc_Hz()` | double | center frequency |

Metadata (properties): `provenance` (`SpectrumProvenance`), `referencePlane`, `psdKind`
(`ABSOLUTE_PSD`). Deterministic: identical construction → identical PSD (AR-200).

## 4. `spectrum.SpectrumProvenance` (Task §27)

`IDEAL_MODEL`, `DATASHEET`, `MEASURED`, `SIMULATED`, `SYNTHETIC_TEST`. Stored explicitly; never
inferred. Test fixtures use `SYNTHETIC_TEST`. No mission spectral mask is fabricated (Task §29).

## 5. `spectrum.RectangularSpectrum`

Flat PSD over `[fc − bw/2, fc + bw/2]`, zero elsewhere.
`PSD_W = P_total_W / bw_Hz` in band. `∫ PSD df = P_total_W` exactly (AR-201).
Constructor: `RectangularSpectrum(fc_Hz, bw_Hz, totalPower_dBm, opts)` with
`opts.provenance` (default `IDEAL_MODEL`), `opts.referencePlane`. `nativeGrid = [fc−bw/2, fc+bw/2]`.

## 6. `spectrum.TabulatedSpectrum`

Piecewise-linear PSD from a frequency grid + shape. Constructor:
`TabulatedSpectrum(freq_Hz, shape, totalPower_dBm, opts)`.
- `opts.shapeUnit`: `LINEAR` (relative linear density, default) or `DB` (relative dB → linearized
  as `10.^(shape/10)` before normalization). **dB shapes are linearized before any integration.**
- The shape is normalized so that `∫ PSD_W df = P_total_W` (trapezoidal area over the grid), i.e.
  `PSD_W(f) = shapeLin(f) · P_total_W / area(shapeLin)`.
- `opts.provenance` default `SYNTHETIC_TEST` for fixtures; `nativeGrid = freq_Hz`.
- Outside `[freq(1), freq(end)]`, PSD = 0 (support band = grid extent).

## 7. Frequency-grid independence (Task §10, §11)

TX spectrum and RX filter may have different native grids. The **integration grid** is built by
`interference.SpectralCouplingAnalyzer` (see `receiver_susceptibility.md` §5) as the sorted union
of relevant breakpoints; source grids are **never mutated**. `SpectrumModel` only guarantees a
correct `psd_WPerHz(f)` at arbitrary `f` and exposes its `nativeGrid_Hz()` breakpoints.

## 8. Non-goals (Task §6, §46)

No PA nonlinear regrowth, harmonics, spurious, phase noise, or waveform simulation. Those are
later-phase RF impairments; this ICD covers only a static linear spectral distribution.
