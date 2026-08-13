# Architecture — Phase 1

Validates the dependency structure before implementation (Task STEP 4). Enforced by
architecture-boundary tests (VR-080…VR-085).

## Package layout (MATLAB namespace `rfscreen`, under `src/`)

```
src/+rfscreen/
├── +util/        Units, Validate, Constants                 (leaf; no rfscreen deps)
├── +geometry/    Rotation, DirectionCalculator,
│                 AntennaToAntennaFOV, AntennaToStructureFOV  (deps: util)
├── +antenna/     Role, Polarization, PatternProvenance,
│                 InstalledPatternSource, PatternGrid,
│                 AntennaPattern (abstract), FreeSpacePattern,
│                 InstalledPattern, SyntheticPatternFactory,
│                 Antenna, AntennaInstallation                (deps: util, geometry)
├── +rf/          RFTransmitter, RFReceiver, RFFrontEnd,
│                 FrequencyRelation, FrequencyRelationType    (deps: util)
├── +coupling/    CouplingModelType, CouplingValidity,
│                 CouplingResult, CouplingModel (abstract),
│                 PatternOnlyCouplingModel, FarFieldCouplingModel,
│                 MeasuredS21CouplingModel, HFSSCouplingModel (deps: util)
├── +config/      LobeClassificationPolicy, FrequencyRelationPolicy,
│                 PatternInterpolationPolicy, RiskPolicy,
│                 AnalysisConfig                              (deps: —)
├── +scenario/    Scenario, OperatingMode                    (deps: antenna, rf)
├── +results/     LobeClass, InterferenceType, ResultValidity,
│                 RiskLevel, PairResult, MatrixResult         (deps: —, value structs)
└── +interference/ LobeClassifier, InterferenceClassifier,
                  PairwiseAnalyzer, InterferenceAnalyzer      (deps: all above)
```

## Dependency rules (acyclic, one-directional)

```
util  ◄── geometry ◄── antenna ◄─┐
util  ◄── rf ◄───────────────────┤
util  ◄── coupling ◄─────────────┤
config ───────────────────────── ┤
results ───────────────────────── ┤
scenario ◄── antenna, rf          │
interference ◄── (geometry, antenna, rf, coupling, config, results, scenario)
```

- `interference` is the only orchestration layer and may depend on everything below it.
- **No package depends on `interference`** (no back-edges).
- **No package references any UI** (App Designer / figure / uicontrol) — VR-080.
- **No package calls any external EM solver** — HFSS/CST/measured are *interfaces only*, and
  their `computeCoupling` raises `NotImplementedPhase1` — VR-081.
- `coupling` never imports `antenna`/`geometry`: it consumes a plain `ctx` struct, keeping the
  coupling boundary replaceable (rule 1).

## Concern separation (SR-010) — realized by

| Concern | Package/Class |
|---------|---------------|
| Geometry | `+geometry` |
| Pattern | `+antenna` (`AntennaPattern` + `PatternGrid`) |
| Coupling | `+coupling` (`CouplingModel` boundary) |
| RF System | `+rf` (`RFTransmitter`/`RFReceiver`) |
| Receiver Susceptibility | `+rf.RFFrontEnd` (+ reserved margins in `PairResult`) |
| Interference Decision | `+interference` + `+results` |

## Key boundary guarantees

1. `Antenna` holds *no* `position_m`/`R_BA` — geometry lives in `AntennaInstallation` (VR-083).
2. `FreeSpacePattern` and `InstalledPattern` are distinct classes; installed adds
   `installedSource` (VR-084).
3. `PatternOnlyCouplingModel` sets `isPhysicalCoupling=false`, `modelType=PATTERN_ONLY`; it can
   never masquerade as `MEASURED_S21` (VR-082).
4. Synthetic patterns carry `provenance=SYNTHETIC_TEST` (VR-085).
5. `interference` orchestrates; core math (`geometry`, `antenna`, `coupling`) is UI/solver-free.
