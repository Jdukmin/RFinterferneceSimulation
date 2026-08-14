# RPT-P6-03 — Model Gap Analysis

Aggregates every mismatch surfaced while replicating the four KARI reference cases (RPT-P6-02) and
running the top-down validation (RPT-P6-01). Gaps are **separated by kind** (§28) — architecture /
implementation / physics / input-data / documentation — then **ranked** P0–P3. Ranking a gap is
**not** a commitment to implement it: **P2/P3 gaps are recorded, not auto-built** (§28, §56). No
HFSS/CST is introduced or recommended as an automatic remedy (§29, §56).

---

## 1. Gap taxonomy (what kind of gap is it?)

| Kind | Meaning | How it is resolved (if ever) |
|------|---------|------------------------------|
| **Architecture gap** | The tool's model, by design, does not represent this physics. | A future phase, only if scoped; never silently. |
| **Implementation defect** | The architecture *should* handle it but the code did not. | Fix now (it is a bug). |
| **Physics model gap** | A physical effect (full-wave scattering, axial ratio) outside the tool's declared domain. | External EM evidence, not this tool. |
| **Input-data gap** | The reference's numeric inputs (CAD, materials, hardware IIP3/P1dB) are not public. | Supply data with explicit provenance; never fabricate. |
| **Documentation gap** | Behaviour is correct but under-explained to the user. | Doc/manual fix now. |

---

## 2. Aggregated gaps (from RC-KARI-01/02/03/RF-01)

| ID | Kind | Source case(s) | Description | Rank |
|----|------|----------------|-------------|------|
| **G-01** | Implementation defect | RC-KARI-01 (AUD-01) | Circular azimuth footprint for a structure straddling the ±180° seam reported a ~357° naive span instead of the true small arc. | **P0 → RESOLVED** |
| **G-02** | Documentation gap | AUD-02 | `VERTEX_SAMPLED` LOS can miss a thin occluder between sampled vertices (false negative); the caveat was under-documented. | **P1 → RESOLVED (doc)** |
| **G-03** | Documentation gap | Top-down entry (§12) | No single minimal user entry path or per-reference-case runnable script existed. | **P1 → RESOLVED (quickstart + RC scripts + manual)** |
| **G-04** | Physics model gap | RC-KARI-01, -03 | Full-wave scattering / reflection / diffraction from the structure (the EM RP deformation magnitude) is not computed. | **P3 (boundary — do NOT auto-build)** |
| **G-05** | Physics model gap | RC-KARI-02 | Axial-ratio / polarization delta between free and installed is not represented. | **P3 (boundary — do NOT auto-build)** |
| **G-06** | Architecture gap | RC-KARI-02 | Installed-pattern *authority*: the tool compares an installed pattern but cannot *derive* it from geometry — it must be supplied. | **P2 (enhancement — data-supplied only)** |
| **G-07** | Input-data gap | RC-KARI-01/02/03 | Public papers do not publish CAD geometry, materials, or measured cuts; reproduction geometry is `ASSUMED_FOR_REPLICATION`. | **P1 (data, not code — supply with provenance)** |
| **G-08** | Input-data gap | RC-KARI-RF-01 | The paper's exact hardware IIP3 / P1dB / link budget are not available, so absolute dB levels are not fitted. | **P1 (data, not code)** |
| **G-09** | Documentation gap | RC-KARI-RF-01 | Users may read the reproduced IM3/compression *levels* as validated absolute values rather than mechanism-only. | **P2 → RESOLVED (manual states levels are illustrative)** |

---

## 3. Ranking rationale (§28)

- **P0 — invalidates current analysis.** Only **G-01** qualified: a wrong azimuth span misreports a
  structure's footprint, which is a core geometry output. It was a genuine implementation defect and
  is **fixed** (circular arc relative to centroid az; `azimuthSpan_deg` added; 598/598 regression).
- **P1 — materially affects reference reproduction.** G-02, G-03 (documentation/usability that
  directly gate whether a user can *run* a reference case correctly) and G-07, G-08 (the missing
  public numeric inputs that cap quantitative fidelity). The documentation P1s are **resolved**; the
  data P1s are **not code work** — they are resolved only by supplying data with provenance, never by
  fabrication.
- **P2 — useful enhancement.** G-06 (installed-pattern derivation from geometry, still data-fed) and
  G-09 (mechanism-vs-absolute clarity, resolved in the manual). **Not auto-implemented.**
- **P3 — optional high-fidelity capability.** G-04, G-05 — full-wave EM and polarization. These are
  the **declared architecture boundary** (Tier 4). They are **recorded as gaps, not defects**, and
  are **explicitly NOT auto-scheduled**; introducing a full-wave solver (HFSS/CST or otherwise) is a
  separate, deliberately-scoped decision — not a remedy this phase applies (§29, §56).

---

## 4. What is a defect vs a boundary (the important distinction §8/§53)

Only **G-01** was a true defect (code wrong within its own domain) — fixed. Everything ranked P3 is
a **physics boundary**: the software is *correct* to not compute it, and Tier 4 on those rows is the
**right** answer, not a failure. Conflating the two would either (a) hide a real bug behind "it's a
boundary", or (b) pressure the tool into fake EM to look complete. Phase 6 does neither.

---

## 5. Explicitly NOT done this phase (and why)

- **No full-wave solver added** (G-04/G-05, P3) — out of scope by design; would be fake if faked.
- **No installed-pattern-from-geometry synthesis** (G-06, P2) — would be an unvalidated EM model.
- **No absolute-level fitting** for RC-KARI-RF-01 (G-08) — prohibited (§9); levels stay illustrative.
- **No HFSS/CST recommendation as an automatic next step** (§56) — the next-phase recommendation
  (RPT-P6-05 §Next) is framed as a *scoped option requiring external EM evidence*, not a default.

---

## 6. Gap → tier consistency check

| Case | Reproduced (≤ Tier boundary) | Gap that caps it | Consistent? |
|------|------------------------------|------------------|-------------|
| RC-KARI-01 | Tier 2 geometry | G-04 (P3 boundary) | ✔ boundary, not defect |
| RC-KARI-02 | Tier 2–3 workflow | G-05 (P3), G-06 (P2), G-07 (P1 data) | ✔ |
| RC-KARI-03 | Tier 1–2 geometry | G-04 (P3 boundary) | ✔ |
| RC-KARI-RF-01 | Tier 2 mechanism | G-08 (P1 data) | ✔ data, not defect |

All caps are either a **declared physics boundary** (P3) or a **missing public input** (P1 data) —
none is an unresolved implementation defect. The one implementation defect found (G-01) is fixed.
