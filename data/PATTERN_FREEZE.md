# Free-space pattern freeze (P7d-2)

**Effective 2026-10-04.** The free-space antenna patterns used by the RFC/RFI analysis are frozen
as they are. **No further pattern reconstruction work** (new CST candidates, re-tuning, re-export,
re-interpolation, envelope changes) is to be done for these antennas.

## What is frozen

| Group | Antenna / use | Directory | Files |
|-------|---------------|-----------|-------|
| `S_BAND_SBA1_SBA4` | SBA TC/TM, variants SBA1 and SBA4 | `data/Sband_TMTC/` | 8 CSV |
| `L_BAND_GNSS` | GPSA L1 / L2(1207 MHz proxy) / L5 | `data/Lband_GPS/` | 6 CSV |
| `X_BAND_ISL_CST` | ISL, CST `ISL_C4_CUP_R14P7`, 10.3/10.4/10.5 GHz **and** (added 2026-10-04) 10.55/10.6/10.65 GHz | `data/Xband_ISL/` | 12 CSV + 12 regions JSON |
| `KA_BAND_KAA_CST` | KAA, CST feed + reflector aperture integration, 25.5/26.25/27 GHz | `data/Kaband_KAA_CST/` | 6 CSV + 6 regions JSON + validation JSON |
| `KA_BAND_LEGACY_UNBOUND` | legacy Ka cuts, **bound to no antenna** | `data/Kaband_DLS/` | 2 CSV |

`data/pattern_freeze_manifest.csv` lists every frozen file with its SHA-256 (computed on the
content with CR removed, so it is independent of git line-ending conversion).
`tests/test_pattern_freeze.m` fails if any frozen file changes, a file is added to or removed from
a frozen directory, or a pattern bound in `pattern_bindings.csv` is not in the manifest.

## What the freeze does and does not mean

- The patterns are **free-space** patterns. Installed (on-spacecraft) effects are **not** in them.
  They enter only through **separate** datasets — tabulated S21 (`coupling.CstCouplingModel`,
  P7d-3) or separately registered installed patterns (`antenna.InstalledPattern`, e.g. the CST
  installed-pattern stage) — never by editing these files.
- Frozen ≠ validated. Known limitations stay as documented in each dataset README (datasheet
  envelopes, L2 proxy, assumed ISL template, Ka validated only to 1°, no mesh convergence).
- SAR is not covered: its antenna is analysed in the closed network and its CST example (8 GHz) is
  not a baseline pattern.

## Unfreezing (explicit procedure only)

1. Written owner approval stating the reason (e.g. measured data, a design change).
2. Change the dataset, update its README provenance, regenerate the manifest, and record the
   change in `docs/traceability.md`.
3. Re-run the full suite; re-run every case that uses the pattern.

Anything else touching these files is a defect, not a task. The CST workspace (`cst/`) is bound by
the same rule for the antennas above: see `cst/PATTERN_FREEZE.md`.

## Amendment 2026-10-04 (ISL owner operating band)

After the freeze, six ISL files for the **owner operating band 10.55–10.65 GHz** (`f10.55`, `f10.6`, `f10.65`,
XZ/YZ, CSV + regions JSON; bindings `ISL_10P55/10P6/10P65`; CST `ISL_FIXED_10G6`, fixed geometry) were added to
`data/Xband_ISL/` by the CST workstream, and the ISL transmit/receive baseline moved to 10.6 GHz. The change is
**additive** (the earlier 10.3/10.4/10.5 GHz files are byte-identical) and the manifest now lists the new files.
The owner confirmed (2026-10-04) that this change is intended; it is accepted as an approved extension of the freeze.
