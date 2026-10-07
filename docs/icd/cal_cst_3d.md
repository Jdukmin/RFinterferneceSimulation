# ICD — CAL native full-sphere CST ASCII ingestion (`rfscreen.cal`)

**Status:** normative for `src/+rfscreen/+cal/` and `main('--cal')`.
**Scope:** copy CST Studio full-sphere 3D Realized Gain exports (ASCII `.txt`) into `data/cal/` and run
`main('--cal')`: automatic recognition and validation → pattern figures → installed-on-spacecraft figures →
CAL victim-band RFI through the **existing** engine. The 2D XZ/YZ pipeline (`CsvPatternImporter`,
`CutPatternAssembler`, `APPROX_FROM_CUTS`) is untouched and is never used by this path.

## 1. Directory contract

```
data/cal/
├─ gps/  GPS_ORIGINAL_f1.2.txt  GPS_GPSA1_f1.2.txt  GPS_GPSA2_f1.2.txt
├─ isl/  RFC_ISL_f<tok>.txt
├─ kaa/  RFC_KAA_f<tok>.txt
└─ sba/  RFC_SBA_f<tok>.txt  RFC_SBA_NADIR_f<tok>.txt  RFC_SBA_ZENITH_f<tok>.txt
```

| Name | Family / installation | Type | Frequencies |
|---|---|---|---|
| `GPS_ORIGINAL_f1.2` | GPS, generic | FREE_SPACE (reference / fallback) | L5, L2, L1 (shared spatial pattern) |
| `GPS_GPSA1_f1.2` / `GPS_GPSA2_f1.2` | GPSA_1 / GPSA_2 | INSTALLED | L5, L2, L1 (shared) |
| `RFC_ISL_f<tok>` | ISL | FREE_SPACE (no installed override) | `<tok>` |
| `RFC_KAA_f<tok>` | KAA_1 / KAA_2 (reflector included) | FREE_SPACE, attacker only | `<tok>` |
| `RFC_SBA_f<tok>` | SBA_NADIR / SBA_ZENITH | FREE_SPACE (generic) | `<tok>` |
| `RFC_SBA_NADIR_f<tok>` / `RFC_SBA_ZENITH_f<tok>` | SBA_NADIR / SBA_ZENITH | INSTALLED | `<tok>` (owner: 2.06 / 2.25) |

* `f1.2` of the GPS files is **not** a frequency. `<tok>` must be listed in
  `data/cal_config/cal_frequency_aliases.csv`; canonical values come from `rf_systems.csv` (L5 1176.45, L2 1227.60,
  L1 1575.42, S 2250, SAR 9650, ISL 10600 MHz) or are literal CST monitors (2.06, 8.9, 10.4 GHz). An alias may absorb
  display precision only (≤ 0.1 MHz: `1.1764 → 1176.45 MHz`, `1.5754 → 1575.42 MHz`).
* Any other file is reported (inventory) and **not used**: `UNRECOGNIZED_NAME`, `WRONG_FOLDER`, `UNMAPPED_FREQUENCY`,
  `PARSE_ERROR`, `DUPLICATE_BINDING` (two files for the same binding → neither is chosen).

## 2. File format (`CstAscii3DImporter`)

Whitespace-delimited (runs of spaces / tabs; CRLF accepted). Leading non-numeric lines (header + `-----`) are
skipped **without reading their text**; after the first numeric row every non-empty line must be numeric with the
same column count (else `rfscreen:cal:malformedRow` with the line number). Values are read **by column position**:
col1 = θ [deg], col2 = φ [deg], col3 = Realized Gain [dBi]; cols 4..8 (|E_θ|, ∠E_θ, |E_φ|, ∠E_φ, AR) are parsed
for well-formedness only.

## 3. Grid validation (`CstSphericalPatternData`)

Row order is never assumed; the grid is rebuilt from `(θ, φ)` values.

| Check | Error id |
|---|---|
| finite θ / φ / gain | `rfscreen:cal:nonFinite` |
| θ ∈ [0, 180], φ ∈ [0, 360] | `thetaRange`, `phiRange` |
| duplicate (θ, φ) | `duplicateSample` |
| steps identified from the unique values (not hard-coded); uniform | `nonUniformStep` |
| missing single sample / missing θ or φ plane | `missingSample` |
| full sphere: θ 0…180, φ 0…360−Δφ | `incompleteGrid` |

`φ = 360` rows are accepted only as an alias of `φ = 0`. **Poles:** θ = 0 / 180 are single directions; their φ-spread
(CST numerical noise) is reported (`poleSpread_dB`, warning above 0.5 dB) and the interpolation table uses the
linear-power mean of the pole row (raw values kept). Interpolation: bilinear in (θ, φ) in dB, φ periodic.

## 4. Frames (reuse of `rfscreen.kaa.CstLocalFrameAdapter`)

* CST pattern frame L: free-space `+Z_L` = boresight; installed `+Z_L` = mounting-face outward normal (the installed
  CST model is already aligned to it). θ from `+Z_L`, φ = atan2(y_L, x_L).
* Repository antenna frame A (ICD coordinate_system.md): `+X_A` = boresight. `v_A = M_AL v_L`,
  `M_AL = [0 0 1; 0 −1 0; 1 0 0]`; `R_BL = R_BA M_AL` (`CstLocalFrameAdapter.fromR_BA`), so `+X_L = +X_B`
  orthogonalised to the normal (same roll as `cst/closed_network/full_spacecraft_geometry.json`).
* Regression: CST θ = 0 → `+Z_L` → `+X_A` → az = 0, el = 0.
* `R_BA` / positions come only from `antenna_installations.csv` + `panels.csv` via `SimplifiedSpacecraftBuilder`
  (GPSA_1/2 → PANEL_3, SBA_NADIR → PANEL_6, SBA_ZENITH → PANEL_4, ISL → PANEL_3, KAA gimbal reference = panel normal).

Single query chain for RFI gains and every figure:
`body d_B → u_A = R_BAᵀ d_B → v_L = M_ALᵀ u_A → (θ, φ) → native 3D interpolation`.

## 5. Pattern objects and binding

`CstNativeFreeSpacePattern < FreeSpacePattern`, `CstNativeInstalledPattern < InstalledPattern`
(installedSource `CST`); provenance `SIMULATED_3D` (never `APPROX_FROM_CUTS`). `evaluate(f, az, el)` keeps the
`AntennaPattern` contract but answers **only at its own CST plane** (`rfscreen:cal:wrongFrequencyPlane` otherwise) and
queries the native grid; `obj.grid` is an az/el resampling at the native step kept for compatibility only.

`CalPatternBinder` (roles in `data/cal_config/cal_installations.csv`):

| Installation | Rule |
|---|---|
| GPSA_1 / GPSA_2 (RX) | installed `GPS_GPSA1/2` → else `GPS_ORIGINAL` with `INSTALLED_PATTERN_MISSING_FREE_SPACE_FALLBACK` |
| SBA_NADIR / SBA_ZENITH | installed file where provided (2.06 / 2.25 GHz) → else generic `RFC_SBA_f<tok>` (fallback flagged at 2.06 / 2.25) |
| ISL | `RFC_ISL_f<tok>` free-space only (TX and RX; 10.6 GHz is the victim pattern) |
| KAA_1 / KAA_2 | `RFC_KAA_f<tok>` (TX only; RX binding refused: `rfscreen:cal:kaaAttackerOnly`) |
| SAR_ANT (RX) | no CST file: existing owner engineering receive baseline (`SarOwnerPattern` + 52 dBi peak) |

A missing plane is `INPUT_MISSING`; another frequency's pattern is never substituted, nothing is extrapolated.

## 6. CAL RFI (`CalRfiAnalyzer`, plan `data/cal_config/cal_rfi_plan.csv`)

No new physics: `C_EM(f_v) = G_tx,realized(f_v) + G_rx,realized(f_v) − FSPL(f_v)` via
`rfscreen.psd.VictimBandCoupling.patternRoute`, `PsdMath.victimPortPsd / margin / requiredSuppression`, allowable PSD
`kT0 + NF + (I/N)max` from `ReceiverBaseline` (`data/rfi_psd/receiver_baseline.csv`), sources = ITU spurious rows
(`EmissionSpec`) of `kaa_itu_spurious_source.csv`, `stc_itu_spurious_source.csv` and the CAL supplement
`cal_emission_sources.csv` (same derivation; combinations absent from the existing files). No S11 loss is applied
(Realized Gain). One CST plane per victim band (single-frequency evaluation).

| Victim band | CST plane | Victims | Attackers | Criterion |
|---|---|---|---|---|
| L5 / L2 / L1 | 1.17645 / 1.2276 / 1.57542 GHz | GPSA_1, GPSA_2 | KAA_1/2, SBA_NADIR/ZENITH, ISL | GPS_Lx_RX (−178 dBm/Hz) |
| S_TC | 2.06 GHz | SBA_NADIR, SBA_ZENITH | KAA_1/2, ISL, opposite SBA | S_TC_RX (−177) |
| STM | 2.25 GHz | SBA_NADIR, SBA_ZENITH | KAA_1/2, ISL (SBA: own TX band, excluded) | S_TC_RX NF/I-N (−177) |
| SAR / SAR_FULLBAND | 9.65 / 8.9, 10.4 GHz | SAR_ANT | KAA_1/2, ISL, SBA_NADIR/ZENITH | SAR_X_RX (−175) |
| ISL | 10.6 GHz | ISL | KAA_1/2, SBA_NADIR/ZENITH | ISL_X_RX (−177) |

Row status: `EVALUATED` (PASS = 해당 기준 충족 / FAIL = 해당 기준 초과), `COUPLING_EVALUATED_SOURCE_MISSING`,
`INPUT_MISSING_PATTERN` (verdict UNKNOWN = 최종 판정 보류). LOS blockage is reported as geometry evidence only (no
attenuation). Every row records TX/RX file, type (FREE_SPACE / INSTALLED / OWNER_ENGINEERING_BASELINE), class,
provenance, directional gains, CST θ/φ and az/el, distance, FSPL, route, source PSD and provenance, victim PSD,
criterion, margin, required suppression, validity and warnings.

## 7. Figures (`CalPlotter`; values = Realized Gain, radius = visualization only)

* `pattern_plots/<family>/<stem>_XZ.png | _YZ.png`: CST-frame full cuts; XZ = φ 0 (+X, angle +θ) ∪ φ 180 (−X, −θ),
  YZ = φ 90 ∪ φ 270; 0 = boresight +Z.
* `installed_plots/3d/<NAME>_INSTALLED_3D.png`: hull (SSOT panels, mounting panel highlighted), body axes, mount point,
  boresight / mount normal, pattern translated to the mount. Radius `r = R_vis · max(0, G − (G_max − 30 dB)) / 30 dB`.
* `installed_plots/body_cuts/<NAME>_BODY_XZ|YZ|XY.png`: body-plane directions queried through the chain of §4 (never a
  rotated 2D cut), with hull projection, mount point and boresight projection.
* `<NAME>` = `GPSA1_L1L2L5` / `GPSA2_L1L2L5` (one spatial pattern shared by the three GNSS bands) or
  `SBA_NADIR_2p06`, `SBA_NADIR_2p25`, `SBA_ZENITH_2p06`, `SBA_ZENITH_2p25`.

## 8. Outputs (`output/cal/`)

`validation/pattern_inventory.csv`, `validation/pattern_binding.csv`, `pattern_plots/`, `installed_plots/{3d,body_cuts}/`,
`rfi/pair_results.csv`, `rfi/summary.csv`, `rfi/run_summary.txt` (results first, REPORTING_GUIDE wording). The runner
removes its own stale `png/csv/txt` in these sub-folders before writing.

## 9. Execution

```matlab
main('--cal')                                        % MATLAB / Octave, repository root
main('--cal', 'calDir', d, 'outDir', o, 'plots', false)
```
```bash
octave-cli --no-gui --eval "main('--cal')"
```
Octave without a display uses the gnuplot toolkit (PNG via `-dpngcairo`); with no graphics toolkit the figures are
skipped and reported, the numeric outputs are still produced.
