# `docs/` — documentation (SSOT)

Normative documentation for the Spacecraft RF Coexistence & Antenna Interference Screening Tool.

| Path | Purpose |
|------|---------|
| `reference.md` | Mandatory reference review + binding architecture implications (R1–R10) |
| `architecture.md` | Package/dependency structure (enforced by architecture-boundary tests) |
| `traceability.md` | Requirement → code → test map; canonical decisions; reconciliation (Phase 1 & 2) |
| `requirements/system_requirements.md` | `SR-…` system requirements |
| `requirements/analysis_requirements.md` | `AR-…` analysis requirements (incl. §11 Phase-2 canonicalization) |
| `requirements/data_requirements.md` | `DR-…` data requirements (incl. §10 Phase-2 pattern data) |
| `requirements/verification_requirements.md` | `VR-…` verification requirements (incl. §12 Phase-2) |
| `icd/` | Interface Control Documents (normative) — see `icd/README.md` |

## Phases

- **Phase 1 (complete):** requirements, ICD, deterministic core RF interference engine.
- **Phase 2 (complete):** external 2D antenna-cut ingestion & canonicalization pipeline
  (`icd/pattern_data.md`), feeding the unchanged Phase-1 core.

Canonical units, frames, and conventions are fixed in `icd/` and must not be silently overridden.
