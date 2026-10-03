# Ka-band KAA antenna pattern (1 deg) — CST feed + reflector aperture-integration surrogate

Scalar RFC/RFI screening cuts for the Ka-band downlink antenna (KAA), copied **byte-identical**
from the CST workspace `cst/exports/ka/` (screening_1deg + `ka_final_validation.json`). This
**supersedes, for KAA, the legacy `data/Kaband_DLS/` cuts**, whose main-lobe/sidelobe shape beyond
the datasheet anchors was generated arbitrarily (see `cst/specs/kaband_dls.yaml`). `data/Kaband_DLS/`
is kept unchanged for history and is no longer bound to any antenna.

## Why a surrogate

No numeric reflector pattern of the actual 0.22 m all-metal Cassegrain (Beyond Gravity K-band link
antenna, datasheet 1399728/01-22) is public — only datasheet anchors (boresight, ±0.5/0.75/1.0°
EOC, XPD > 29 dB). The CST worker therefore modelled:

- **Feed:** full-wave CST open-ended circular waveguide, 4-probe RHCP (`KA_FEED_C_OEWG`);
- **Reflector:** equivalent-paraboloid **aperture integration** in Python (`cst/ka_reflector_po.py`,
  verified against the Silver closed form to 1e-3), D = 220 mm (owner estimate; datasheet < 222 mm),
  subreflector Ds = 44 mm blockage, spillover removed from the main beam (accepted-power gain).
  This stage is **not** CST (the Learning Edition has no PO/asymptotic solver); feed phase errors
  are neglected.

## Files

| File | Frequency | Role |
|------|-----------|------|
| `KA_DLS_physical_f26p25_{XZ,YZ}.csv` | 26.25 GHz | **centre — baseline** (0° = 32.63 dBi) |
| `KA_DLS_physical_f25p5_*`, `KA_DLS_physical_f27_*` | 25.5 / 27.0 GHz | band edges (sensitivity) |
| `*.regions.json` | — | per-angle region (`VALIDATED_MAIN`, `UNVALIDATED_SIDELOBE`, `BACKLOBE`), raw model gain, exported gain |
| `ka_final_validation.json` | — | anchor errors, per-frequency summary (HPBW, first null, first sidelobe, XPD) |

CSV: `theta,gain`, 360 rows `0…359`, dBi, boresight `+Z`, XZ = YZ (axisymmetric).

## Validation (datasheet anchors, per frequency)

Status `KA_DATASHEET_ANCHOR_PASS`: errors vs datasheet at 0/0.5/0.75/1.0° are −0.32…−0.43 dB at
25.5 GHz and −0.33…+0.54 dB at 27 GHz (limits 0.7 dB at boresight, 1.0 dB elsewhere). HPBW
3.23/3.14/3.06°, first null 3.65–3.8°, first sidelobe 15.5–16.0 dBi at 4.95–5.25°, XPD within 1°
34.7–36.0 dB (> 29 dB).

## Known limitations

- **Only 0–1° is model-validated.** Elsewhere the export is `max(model, legacy repository CSV
  envelope)`; far sidelobes/backlobe therefore still carry the legacy conservative assumption.
- Datasheet EOC values are likely guaranteed minima; a physical model sits up to ~1 dB above the
  27 GHz 1.0° value. This is a source characteristic, reported and not tuned away.
- Reflector dimensions other than D are assumptions (F/D, subreflector, horn: confidence C).
- Polarization RHCP is assumed (datasheet allows RHCP or LHCP); mesh convergence not run.
- No native complex reflector source exists (reflector stage is not CST).
