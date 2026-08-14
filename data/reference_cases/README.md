# Reference-case data — provenance

This directory holds any input data used to reproduce published KARI reference cases. **Every
datum must declare a provenance class.** No proprietary, mission, or export-controlled data is
stored here, and **no value is ever fabricated to match a paper** (§9 no paper fitting; §29 no fake
EM).

## Provenance classes

| Class | Meaning | May be presented as… |
|-------|---------|----------------------|
| `PUBLIC_REPORTED` | A number stated explicitly in a public paper/report | the paper's reported value (cite it) |
| `PUBLIC_DIGITIZED` / `DIGITIZED_FROM_PUBLIC_FIGURE` | Read off a published figure by digitization | approximate, digitized (never as raw measured data) |
| `SYNTHETIC_SUPPORT` / `SYNTHETIC_TEST` | Tool-generated illustrative data (e.g. a synthetic pattern) | illustrative only, clearly marked |
| `ASSUMED_FOR_REPLICATION` | A representative value chosen to run a case whose real input is not public | an assumption, not the paper's value |
| `SOURCE_EXPLICIT` | Supplied directly by the data owner with explicit provenance | as provided, with its stated source |
| `SOURCE_DERIVED` | Computed from a `SOURCE_EXPLICIT` input by a documented operation | derived, with the operation recorded |
| `UNKNOWN` | Provenance not established | withheld — must not be used quantitatively |

## What is (and is not) in this directory

The Phase-6 reference scripts under `examples/reference_cases/` use **only**
`ASSUMED_FOR_REPLICATION` geometry/hardware and `SYNTHETIC_SUPPORT` patterns — the source papers do
not publish their CAD, materials, measured cuts, or exact hardware IIP3/P1dB, so no
`PUBLIC_REPORTED` or `DIGITIZED_FROM_PUBLIC_FIGURE` dataset was available to include. As a result
**this directory currently contains no data files** — only this provenance guide.

The workflow fully supports real data when you have it: drop the file here, tag it with the correct
provenance class above, and reference it from a reproduction script. A digitized figure enters as
`DIGITIZED_FROM_PUBLIC_FIGURE` (approximate), never as measured truth; a measured/simulated
installed pattern enters as `SOURCE_EXPLICIT` with its solver/measurement recorded.

## Rules

1. **Declare provenance on every datum** — no untagged numbers.
2. **Never fabricate** a value to force agreement with a reference (§9). Absent data → `UNKNOWN`,
   and the analysis reports the corresponding `MISSING_*` / `UNAVAILABLE` validity state.
3. **Assumptions are labelled** `ASSUMED_FOR_REPLICATION` and are never presented as flight or
   measured data.
4. **No proprietary / export-controlled / mission data** is committed here.

See `docs/reports/reference_validation/reference_case_matrix.md` (§ data provenance) and RPT-P6-02
for how each reference case's inputs are classified.
