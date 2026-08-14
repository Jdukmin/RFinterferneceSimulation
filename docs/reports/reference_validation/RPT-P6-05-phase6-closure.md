# RPT-P6-05 — Phase 6 Closure

Phase 6 is a **validation / reproduction** phase, not a feature phase. It measures how far the
existing Phase 1–5 tool reproduces published KARI research cases, runs each case **top-down from a
user's point of view**, resolves every implementation-level Return Point (RP) found, and produces a
top-down user manual — **without** paper fitting, fake EM, or introducing HFSS/CST (§9, §29, §53,
§56).

---

## 1. Architecture validity verdict

The Phase 1–5 architecture is **validated** as an early-design screening tool with an **honest
physics boundary**. Across four reference cases the tool reproduced exactly the domain it claims
(geometry, pattern lookup, linear/nonlinear RF relations, free↔installed comparison) and **stopped
cleanly** at the full-wave / axial-ratio / absolute-coupling boundary, reporting Tier 4 rather than
inventing values. No reference case required a change to a Phase 1–5 physics contract.

## 2. Reference-case results

| Case | Reference | Reproduced domain | Tier reached | Boundary (Tier 4) |
|------|-----------|-------------------|--------------|-------------------|
| RC-KARI-01 | Im W-G. et al., KSAS 2015 | Structure-in-FOV geometry, footprint, LOS | **Tier 2** | EM RP deformation (`MODEL_GAP_FULL_WAVE`) |
| RC-KARI-02 | Lee S-I. et al., KSAS 2023 | Free↔installed comparison workflow | **Tier 2–3** | axial-ratio / polarization |
| RC-KARI-03 | Lee S-I., Im W-G., KARI 2025 | Installed-location geometry, fidelity boundary | **Tier 1–2** | scattering/reflection/diffraction |
| RC-KARI-RF-01 | Kwon B-M. et al., JKSAS 2019 (**not** Im W-G.) | LNA saturation + IM3 into GNSS band | **Tier 2** | absolute dB (paper hardware unavailable) |

Every case is reproducible **to the tier the architecture supports**, and each Tier-4 cap is either
a declared physics boundary or a missing public input — never an unresolved defect. Details in
RPT-P6-02; per-case tiering in `reference_case_matrix.md`.

## 3. RP summary (top-down validation)

| RP | Class | Origin | Status |
|----|-------|--------|--------|
| RP-001 | RP-IMPLEMENTATION | AUD-01 circular azimuth footprint | **RESOLVED** (code fix + `azimuthSpan_deg`) |
| RP-002 | RP-DOCUMENTATION | AUD-02 VERTEX_SAMPLED false-negative caveat | **RESOLVED** (ICD + manual) |
| RP-003 | RP-VALIDATION | AUD-03 installed multi-frequency | **RESOLVED** (regression test added) |
| RP-004 | RP-DOCUMENTATION | No top-level user entry path | **RESOLVED** (quickstart + RC scripts + manual) |
| RP-005 | RP-VALIDATION | RC-KARI-02 base-formula mismatch (script) | **RESOLVED** (perturb free-space's own gains) |
| RP-006 | RP-PHYSICS_BOUNDARY | Full-wave / axial-ratio across RC-01/02/03 | **EXPECTED** (declared boundary) |

All implementation / documentation / validation RPs are **resolved**; the only remaining RP is a
physics-boundary RP, classified **EXPECTED** (§53). Full RP ledger in RPT-P6-01.

## 4. Phase-5 audits (mandatory)

| Audit | Result |
|-------|--------|
| **AUD-01** circular azimuth footprint (358/359/0/1/2 must not become 0→359) | **FIXED** — one real implementation defect; now reports true small arc via `azimuthSpan_deg` |
| **AUD-02** VERTEX_SAMPLED ≠ EXACT_SURFACE_INTERSECTION; false negatives documented | **CONFIRMED + DOCUMENTED** — no exact-surface claim exists; caveat added to ICD §4 and manual §18/§20 |
| **AUD-03** InstalledPattern multi-frequency support | **CONFIRMED** — `PatternGrid`/`InstalledPattern` carry multiple frequencies; regression test proves two coexist |

## 5. Model gap ranking (do NOT auto-implement P2/P3)

| Rank | Gaps | Disposition |
|------|------|-------------|
| **P0** invalidates analysis | G-01 circular footprint | **FIXED** |
| **P1** materially affects reproduction | G-02, G-03 (docs) / G-07, G-08 (public data) | docs **RESOLVED**; data gaps closed only by supplying provenance-tagged data |
| **P2** useful enhancement | G-06 installed-from-geometry, G-09 level clarity | G-09 **RESOLVED** (manual); G-06 **NOT built** |
| **P3** optional high-fidelity | G-04 full-wave, G-05 axial ratio/pol | **NOT built** — declared boundary |

Full analysis in RPT-P6-03. No P2/P3 gap was auto-implemented; no HFSS/CST was introduced.

## 6. User manual (before → after)

- **Before:** no user manual; entry was a Phase-1 demo + the ICDs; no minimal runnable path, no
  per-reference-case script, no consolidated non-goals statement.
- **After:** `docs/user_manual.md` (20 top-down sections), `examples/quickstart.m`, and four
  `examples/reference_cases/rc_kari_0*.m` scripts. Every manual code block is verified to execute
  (RPT-P6-04). The manual leads with what the tool does **not** do and treats
  `UNKNOWN`/`UNAVAILABLE` as legitimate answers.

## 7. Regression & verification

- **Full suite:** **598 assertions across 36 test files, all passing** (`tests/run_all_tests.m`),
  the exact `src/` code executed under **GNU Octave 8.4**. Baseline before Phase 6 was 579/35; the
  +19 assertions / +1 file are `tests/test_phase6_audits.m` (AUD-01/02/03 + RC invariants). All 579
  prior assertions still pass (regression preserved).
- **MATLAB:** **NOT RUN** (no MATLAB in this environment). The code remains within the
  MATLAB/Octave-common subset used since Phase 1, but MATLAB execution is **not claimed**.
- **Reference scripts + manual examples:** all execute (quickstart, four RC scripts, figure
  generation, and the extracted manual snippets).
- **No paper fitting, no fabricated EM, no HFSS/CST introduced** — verified by the Phase-5
  architecture guard (`test_phase5_architecture`) plus manual inspection of the Phase-6 scripts.

## 8. Deliverables

| Deliverable | Path |
|-------------|------|
| Reference case matrix | `docs/reports/reference_validation/reference_case_matrix.md` |
| Top-down RP validation | `RPT-P6-01-top-down-rp-validation.md` |
| KARI reference replication | `RPT-P6-02-kari-reference-replication.md` |
| Model gap analysis | `RPT-P6-03-model-gap-analysis.md` |
| User manual validation | `RPT-P6-04-user-manual-validation.md` |
| Phase-6 closure (this) | `RPT-P6-05-phase6-closure.md` |
| User manual | `docs/user_manual.md` |
| Quick start | `examples/quickstart.m` |
| Reference-case scripts | `examples/reference_cases/rc_kari_0*.m` |
| Reference-case figures | `examples/reference_cases/generate_figures.m` |
| Data provenance guide | `data/reference_cases/README.md` |
| Audit tests | `tests/test_phase6_audits.m` |
| Reference review update | `docs/reference.md` (RC citations) |
| Traceability update | `docs/traceability.md` (Phase-6 section) |

## 9. Next-phase recommendation (NOT an automatic HFSS/CST mandate)

The single defect found (circular footprint) is fixed; everything else that caps reproduction is a
**declared physics boundary** (P3) or a **missing public input** (P1 data). Therefore:

- **Recommended next, if and only if scoped by the user:** define a **replaceable installed-pattern
  / coupling ingestion boundary** so that measured or externally-simulated EM evidence (from
  *whatever* solver or measurement the project already trusts) can enter the tool **with explicit
  provenance**, closing G-06/G-07 on the **data** side without the tool computing EM itself.
- **Explicitly NOT recommended as an automatic step:** embedding a full-wave solver (HFSS/CST or
  otherwise) into this tool (§56). That is a separate, deliberate decision requiring external EM
  evidence and its own validation phase — it is *not* the default remedy for Tier-4 boundaries.

**Phase 6 status: COMPLETE.** Architecture validated; one implementation defect fixed; four
reference cases reproduced to their supported tiers with honest Tier-4 boundaries; top-down manual
delivered and verified; 598/598 regression green; no paper fitting, no fake EM, no HFSS/CST added.
