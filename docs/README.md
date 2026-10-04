# `docs/` — documentation (SSOT)

Normative documentation for the Spacecraft RF Coexistence & Antenna Interference Screening Tool.

| Path | Purpose |
|------|---------|
| `user_manual.md` | **Top-down user manual (start here)** — problem, non-goals, conventions, runnable workflows (Phase 6) |
| `reference.md` | Mandatory reference review + binding architecture implications (R1–R14, incl. KARI reference cases) |
| `architecture.md` | Package/dependency structure (enforced by architecture-boundary tests) |
| `traceability.md` | Requirement → code → test map; canonical decisions; reconciliation (Phases 1–6) |
| `requirements/system_requirements.md` | `SR-…` system requirements |
| `requirements/analysis_requirements.md` | `AR-…` analysis requirements (incl. §11 Phase-2 canonicalization) |
| `requirements/data_requirements.md` | `DR-…` data requirements (incl. §10 Phase-2 pattern data) |
| `requirements/verification_requirements.md` | `VR-…` verification requirements (incl. §12 Phase-2) |
| `icd/` | Interface Control Documents (normative) — see `icd/README.md` |
| `reports/reference_validation/` | Phase-6 KARI reference replication reports + case matrix |

## Phases

- **Phase 1 (complete):** requirements, ICD, deterministic core RF interference engine.
- **Phase 2 (complete):** external 2D antenna-cut ingestion & canonicalization pipeline
  (`icd/pattern_data.md`), feeding the unchanged Phase-1 core.
- **Phase 3 (complete):** linear RF coexistence & receiver susceptibility — TX spectrum, RX
  filter, kTB noise, I/N, interference margin, two analysis modes (`icd/spectrum.md`,
  `icd/receiver_susceptibility.md`).
- **Phase 4 (complete):** receiver front-end nonlinear susceptibility — P1dB compression,
  blocking, two-tone IM3, and multi-interferer aggregation at the `LNA_INPUT` plane
  (`icd/receiver_nonlinear.md`).
- **Phase 5 (complete):** spacecraft structure geometry & installed-antenna environment —
  structure primitives, ray/segment intersection, antenna-to-structure FOV, LOS blockage, and
  free-space vs installed-pattern selection/comparison (`icd/spacecraft_geometry.md`,
  `icd/installed_environment.md`). Geometry is evidence only.
- **Phase 6 (complete):** KARI reference replication, top-down validation & user manual — a
  validation/reproduction phase (no new physics). Reproduces four published KARI cases to their
  supported reproducibility tiers, fixes the AUD-01 circular-footprint defect, and delivers
  `user_manual.md`, `examples/quickstart.m`, and `examples/reference_cases/`. No paper fitting, no
  fabricated EM, no HFSS/CST introduced; full-wave/measured-S21 and TX/mixer/ADC effects remain a
  scoped, data-only future step (`reports/reference_validation/`).
- **Phase 7 (complete):** simplified mission spacecraft geometry & antenna installation baseline —
  the exact irregular-hexagon hull (`data/spacecraft/simplified_spacecraft_v1/`), an exact
  `ConvexPolygonGeometry` end-cap primitive, 8 antenna installation points with panel-normal
  boresights, and a separate KAA gimbal hemisphere steering domain, wired into the unchanged FOV/LOS
  machinery (`icd/mission_spacecraft.md`). Geometry evidence only; no pattern is loaded or created.
  Phase 7b adds the six analysis cases (SBA1/SBA4 × GPS L1/L2/L5) via `+mission`, the CST ISL
  pattern (`data/Xband_ISL`), and defers SAR RF analysis to the closed network.

Canonical units, frames, and conventions are fixed in `icd/` and must not be silently overridden.
- **Phase 7d (complete):** Ka baseline corrected to 1500 MHz (25.50–27.00 GHz) with the data-rate
  discussion moved to `notes/`; free-space pattern **freeze** (`data/PATTERN_FREEZE.md`); `CouplingModelType.CST`
  on tabulated S21(f) (`icd/coupling.md` §6–7); installed-geometry EM sweep **plan**
  (`reports/em_sweep/`); explicit `SCREENING_ALL_TX` vs provisional nominal modes; receiver
  nonlinear data search (`notes/receiver_nonlinear_data_search_2026-10-04.md`, none public).
- **Phase 8 (complete):** free-space X-band/Ka policy, per-pair received-level (S21) report, local facet export
  for L/S installed-pattern work, installed-pattern hook, configurable terminology (provisional)
  (`reports/rfc_levels/`, `reports/installed_local/`, `notes/kari_terminology_status_2026-10-04.md`).
