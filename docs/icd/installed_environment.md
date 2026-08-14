# ICD — Installed Antenna Environment & Pattern Selection (Phase 5)

Normative interface for distinguishing free-space vs installed antenna behavior: installed-pattern
association, a deterministic pattern-selection policy, free-space fallback, free-space↔installed
comparison, and the per-pair installed-environment evidence result. Requirements: SR-415…SR-424,
AR-416…AR-425, DR-411…DR-420.

Builds on the Phase-2 pattern pipeline and Phase-1..4 engines **without changing** them. **Central
rule: an `InstalledPattern` is never derived from geometry (Task §24); installation effects are
"known" only when installed/EM/measured evidence exists.**

Packages: `src/+rfscreen/+installed/` (selection, comparison, policy/enums),
`src/+rfscreen/+interference/InstalledEnvironmentAnalyzer.m` (orchestration),
`src/+rfscreen/+scenario/` (installed-pattern registry).

---

## 1. FreeSpacePattern ≠ InstalledPattern (activated — Task §4)

`FreeSpacePattern` = antenna behavior without spacecraft installation effects (per its
provenance). `InstalledPattern` = radiation pattern containing installation/environment effects
from a **declared source** (`antenna.InstalledPatternSource`: HFSS/CST/MEASURED/OTHER_SOLVER/
APPROXIMATE). Both remain distinct Phase-1 classes. Phase 5 never converts one into the other from
geometry.

## 2. Installed-pattern provenance & metadata (Task §5, §41)

An `InstalledPattern` carries `provenance` (`PatternProvenance`: MEASURED_3D/SIMULATED_3D/
APPROX_FROM_CUTS/SYNTHETIC_TEST) and `installedSource`. Fidelity **propagates and never upgrades**:
`APPROX_FROM_CUTS` stays approximate; `SIMULATED_3D` and `MEASURED_3D` stay distinguishable
(Task §41). Optional installed metadata (antenna id, configuration id, frequency, analysis id,
coordinate convention, import transform, version/date) is carried in a provenance struct; unknown
values stay unknown (Task §5) — nothing is fabricated. Installed patterns are ingested through the
**existing Phase-2 `PatternImporter`** → canonical cut → `InstalledPattern` (Task §23); no separate
parser is created.

## 3. Configuration-specific association (Task §6, §29, §30)

Installed patterns are associated by **(antennaId, configId)** in the scenario registry, so
`Solar array stowed ≠ deployed` maps to different installed patterns without a kinematics
simulator. `configId = ''` means configuration-independent. `DeploymentState`
(STOWED/DEPLOYED/CUSTOM) selects a deterministic geometry/pattern state; no motion profile is
modeled (Task §30). Frequency dependence is handled by the pattern's own frequency grid.

## 4. Pattern selection — `installed.InstalledPatternSelector` (Task §39, §40, §42)

`select(freeSpacePattern, installedPattern, policy)` → struct
`{pattern, sourceUsed, installationValidity, provenance, warnings}` where:
- `policy` = `installed.InstalledPatternPolicy`: **`PREFER_INSTALLED`** or **`REQUIRE_INSTALLED`**.
- `sourceUsed` = `installed.PatternSourceUsed`: `INSTALLED` / `FREE_SPACE_FALLBACK` / `NONE`.
- Behavior:
  - installed available → `pattern=installed`, `sourceUsed=INSTALLED`,
    `installationValidity=INSTALLED_PATTERN_AVAILABLE`.
  - installed absent, `PREFER_INSTALLED` → `pattern=freeSpace`, `sourceUsed=FREE_SPACE_FALLBACK`,
    `installationValidity=INSTALLATION_EFFECT_UNKNOWN`, **explicit warning** (never a silent
    fallback, Task §39).
  - installed absent, `REQUIRE_INSTALLED` → `pattern=[]`, `sourceUsed=NONE`,
    `installationValidity=REQUIRE_INSTALLED_UNAVAILABLE`.
- `installed.InstallationValidity`: `INSTALLED_PATTERN_AVAILABLE`, `FREE_SPACE_FALLBACK`,
  `INSTALLATION_EFFECT_UNKNOWN`, `REQUIRE_INSTALLED_UNAVAILABLE`, `GEOMETRY_ONLY`,
  `UNSUPPORTED_EM_PHYSICS`.

A free-space-fallback result is **never** returned as an ordinary `VALID` as though installation
effects were known (Task §42).

## 5. Free-space vs installed comparison — `installed.PatternComparison` (Task §21, §22)

`compare(freeSpacePattern, installedPattern, opts)` → `results.PatternComparisonResult`. Evidence
metrics over an **explicit comparison grid** (default az/el sampling, or a supplied cut), evaluating
each pattern on its own native grid via `evaluate` (Phase-2 principle: dataset grid is local; no
global step; **neither source is mutated**, Task §22):
- `peakGainDifference_dB` = `peak(installed) − peak(freeSpace)`.
- `maxAbsDifference_dB`, `rmsDifference_dB` over the grid.
- `directionDelta_dB(freq, az, el)` on demand (`installed − freeSpace` at one direction).
- `frequency_Hz`, `nGrid`, `validity`, `warnings`. Only metrics well-defined for the available data
  are computed; missing/out-of-domain samples are excluded and flagged, never invented.

## 6. `interference.InstalledEnvironmentAnalyzer` (Task §26, §38, §43)

Adds evidence **around** the existing engine; does not rewrite `PairwiseAnalyzer`,
`RfCoexistenceAnalyzer`, or `NonlinearSusceptibilityAnalyzer` (Task §38).

- `analyzePair(scenario, txId, rxId, config)` → `results.InstalledEnvironmentResult`:
  `txId`, `rxId`, `directLOS` (`LineOfSightResult`), `txStructureFOV` (cell of
  `AntennaStructureFOVResult`), `rxStructureFOV` (cell), `txPatternSourceUsed`,
  `rxPatternSourceUsed`, `installationValidity`, `geometryRisk` (`installed.GeometryRisk`:
  `NA`/`LOW`/`MODERATE`/`HIGH` — **screening only**, separate from physical margins, Task §25),
  `warnings`. Structure-FOV is computed **symmetrically for TX and RX** (Task §26).
- `selectedPatternFor(scenario, antennaId, configId, policy)` → the pattern the RF screening should
  use, returned as evidence. When the caller wants the enriched RF result, it re-runs the
  **existing** `PairwiseAnalyzer` with the selected pattern substituted into the pair input — the
  installed pattern flows through the unchanged engine; geometry alone never changes gain (Task §44).

`geometryRisk` heuristic (screening): main-lobe structure occupancy → higher concern; deep back-lobe
→ lower; blocked direct LOS → elevated. It never overwrites Phase-3/4 physical results (Task §25).

## 7. Validity codes (Task §42; ICD §4)

`INSTALLED_PATTERN_AVAILABLE`, `FREE_SPACE_FALLBACK`, `INSTALLATION_EFFECT_UNKNOWN`,
`REQUIRE_INSTALLED_UNAVAILABLE`, `GEOMETRY_ONLY`, `UNSUPPORTED_EM_PHYSICS`. Missing installed
evidence propagates `INSTALLATION_EFFECT_UNKNOWN` — geometry screening may still be reported, but the
installation effect is explicitly not "known".

## 8. Reserved future adapters (Task §45, §46) — Phase 6

`HFSSInstalledPatternProvider`, `CSTInstalledPatternProvider`, `MeasuredInstalledPatternProvider`,
`MeasuredS21Provider`: reserved interfaces reusing the existing pattern/coupling abstractions. Not
implemented in Phase 5; no fake implementations. Solver automation and full-wave/measured-S21
coupling belong to Phase 6.
