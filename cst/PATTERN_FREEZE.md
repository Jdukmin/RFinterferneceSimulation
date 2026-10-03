# Pattern freeze notice (2026-10-04)

The S-band (SBA1/SBA4), L-band GNSS, X-band ISL and Ka-band KAA free-space patterns are **frozen**
in the repository (`data/PATTERN_FREEZE.md`, `data/pattern_freeze_manifest.csv`).

**No further pattern reconstruction work in this workspace** for those antennas: no new candidates,
re-tuning, re-export or envelope changes. Remaining CST work is installed-geometry EM (installed
patterns as separate datasets, and/or S21 between antenna ports on the spacecraft model), planned
in `docs/reports/em_sweep/` and consumed by `rfscreen.coupling.CstCouplingModel` or registered as
`InstalledPattern`; the free-space originals stay untouched.

Unfreezing requires written owner approval; see `data/PATTERN_FREEZE.md`.
