# X-band ISL antenna pattern (1 deg) — CST surrogate `ISL_C4_CUP_R14P7`

Current active binding (owner update 2026-10-04): **10.55–10.65 GHz**, center
**10.6 GHz**, files `f10.55_*`, `f10.6_*`, `f10.65_*`. The antenna geometry is
unchanged. Actual `ISL_FIXED_10G6` calculation used 29,988 cells, four successful
excitations and 50 s. At 10.6 GHz the accepted-power RHCP peak is 10.142 dBi,
XZ HPBW 58.527 degrees and minimum active return loss 7.157 dB. The earlier
10.3/10.4/10.5 files and their history below are preserved. New-band evidence
is in `cst/results/ISL_FIXED_10G6/`; no manufacturer or mesh-convergence claim
is added.

Scalar RFC/RFI screening cuts for the inter-satellite-link (ISL) antenna, copied **byte-identical**
from the CST reconstruction workspace `cst/exports/isl/screening_1deg/` (2026-10-04). The `cst/`
workspace (projects, raw results, native far-field source) is maintained separately and is **not**
part of this commit; the paths below refer to it.

## What this is

- An **RFC/RFI screening free-space radiation model** of a cup-backed circular patch with a
  four-probe quadrature (RHCP) feed, built in CST to an **owner requirement** — not a reconstruction
  of a specific product and not measured data.
- Owner requirement (2026-10-03): centre **10.4 GHz**, 3 dB beamwidth ≈ **60°**, overall coverage
  width ≈ 120°.
- Selected candidate: **`ISL_C4_CUP_R14P7`** (isl-v08). Validation status
  `ISL_ASSUMED_TEMPLATE_PASS`: 0–60° MAE 0.84–0.87 dB (limit 1.5 dB) and HPBW 59.0–60.0°
  (60° ± 10 %) at 10.3/10.4/10.5 GHz, both cuts.

## Files

| File | Frequency | Role |
|------|-----------|------|
| `f10.4_XZ.csv`, `f10.4_YZ.csv` | 10.4 GHz | **centre — baseline RFC pattern** (0° = 10.02 dBi) |
| `f10.3_XZ.csv`, `f10.3_YZ.csv` | 10.3 GHz | band edge (ASSUMED ±1 % monitor) |
| `f10.5_XZ.csv`, `f10.5_YZ.csv` | 10.5 GHz | band edge (ASSUMED ±1 % monitor) |
| `f10.55_*`, `f10.6_*`, `f10.65_*` (XZ/YZ + regions) | 10.55 / **10.6** / 10.65 GHz | **owner operating band** (added 2026-10-04 by the CST workstream, `ISL_FIXED_10G6`; see `data/PATTERN_FREEZE.md` amendment); the ISL baseline uses the 10.6 GHz cut |
| `*.regions.json` | — | per-angle region (`VALIDATED_MAIN`, `UNVALIDATED_SIDELOBE`, `BACKLOBE`), raw CST gain, conservative reference, exported gain |

CSV schema `theta,gain`: theta in degrees, 360 rows `0…359` (`[0,360)`), gain in dBi; source
convention boresight `+Z`, compatible with `rfscreen.patterndata.CsvPatternImporter`.

## How the values were formed

- **0–60°** (`VALIDATED_MAIN`): CST accepted-power **RHCP** gain, unchanged.
- **Elsewhere**: `max(CST, conservative assumed envelope)`; envelope = `max(template for θ < 90°,
  −10 dBi floor)` (assumption ISL-A4). This is conservative for interference screening, not physics.
- Reference template (ASSUMED, no hard anchors): `G0 + 10·q·log10(cos θ)`, `q = 4.819`,
  `G0 = 9.54 dBi`. The CST main beam sits ≈ +0.4 to +0.5 dB above it at boresight.

## Known limitations

- Gain basis is **accepted power** (not realized gain); active return loss 5.0–6.4 dB is a
  diagnostic only. Absolute conducted-power transfer would need separate matching acceptance.
- Axial ratio < 3 dB only within about ±30°; ≈ 8–9 dB at 60° (documented polarization limitation).
- Mesh convergence was not run (disabled by owner instruction); no convergence claim.
- XZ and YZ are near-identical (rotationally symmetric design).
- Band edges 10.3/10.5 GHz and RHCP handedness are assumptions (ISL-A1, ISL-A2).

## Related CST artefacts (in the `cst/` workspace, not committed here)

- Native complex far-field source (installed-antenna analysis input; unclipped; 10.3/10.4/10.5 GHz
  in one file): `cst/exports/isl/isl_rhcp_broadband.ffs`.
- Raw CST cuts before conservative processing (RHCP/LHCP gain, axial ratio, complex Eθ/Eφ, total
  gain): `cst/results/ISL_C4_CUP_R14P7/accepted_power_f10.{3,4,5}_{XZ,YZ}.csv`.
- Validation summary: `cst/results/ISL_C4_CUP_R14P7/validation.json`; project
  `cst/projects/ISL_C4_CUP_R14P7.cst`; spec `cst/specs/xband_isl.yaml`; history `cst/WORKLOG.md`.

The `.ffs` complex source is **not** consumed by this tool (no installed-pattern/complex-field
importer exists); it is listed for a future full-wave installed analysis.
