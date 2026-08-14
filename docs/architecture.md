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
├── +interference/ LobeClassifier, InterferenceClassifier,
│                 PairwiseAnalyzer, InterferenceAnalyzer      (deps: all above)
├── +patterndata/ SourceCoordinateConvention, PatternFidelity,   [Phase 2]
│                 SamplingType, ValidationStatus, CanonicalPatternCut,
│                 PatternCanonicalizer, PatternValidator, CutValidationResult,
│                 PatternImporter, TablePatternImporter, CsvPatternImporter,
│                 PatternResampler, CutPatternAssembler       (deps: util, geometry, antenna, config)
├── +spectrum/    SpectrumModel, RectangularSpectrum,          [Phase 3]
│                 TabulatedSpectrum, SpectrumProvenance        (deps: util)
└── +receiver/    ReferencePlane, FilterProvenance,            [Phase 3]
                  SusceptibilityValidity, AnalysisMode,
                  ReceiverFilter, IdealBandpassFilter, TabulatedFilterResponse,
                  ReceiverNoiseModel, InterferenceCriterion,
                  ReceiverSusceptibilityResult,
                  ReceiverSusceptibilityAnalyzer              (deps: util, spectrum, interference[SpectralCouplingAnalyzer])
```

Phase-3 also adds `interference.SpectralCouplingAnalyzer` (deps: spectrum, receiver types) and
`interference.RfCoexistenceAnalyzer` (orchestration), and optional fields on `rf.RFTransmitter`
(`spectrum`) and `rf.RFReceiver` (`filter`/`noiseModel`/`interferenceCriterion`).

Phase-4 adds:
```
+receiver/   (extends) ReceiverFrontEnd, FrontEndProvenance, NonlinearValidity, ProductType,
             CompressionCriterion, BlockingCriterion, IntermodulationCriterion   (deps: util, receiver filters)
+nonlinear/  InterfererAggregator, CompressionAnalyzer, BlockingAnalyzer,        [Phase 4]
             IntermodulationAnalyzer, NonlinearSusceptibilityAnalyzer            (deps: util, receiver, results, interference[PairwiseAnalyzer])
+results/    (extends) CompressionResult, BlockingResult, IntermodulationProduct,
             NonlinearSusceptibilityResult                                        (plain value data)
```
plus optional `rf.RFReceiver` fields (`receiverFrontEnd`, `compressionCriterion`,
`blockingCriterion`, `intermodulationCriterion`) and `util.Units.sumPowers_dBm` (linear power sum).

Phase-5 adds:
```
+geometry/   (extends) StructureType, GeometryFidelity, GeometryProvenance,       [Phase 5]
             DeploymentState, LineOfSightStatus, StructureGeometry, BoxGeometry,
             PanelGeometry, SpacecraftStructure, LineOfSight,
             AntennaToStructureFOV (activated)                 (deps: util, antenna, interference[LobeClassifier], results)
+installed/  InstalledPatternPolicy, PatternSourceUsed,                            [Phase 5]
             InstallationValidity, GeometryRisk,
             InstalledPatternSelector, PatternComparison       (deps: util, antenna, results)
+interference/ (adds) InstalledEnvironmentAnalyzer            (deps: geometry, installed, results, scenario)
+results/    (extends) AntennaStructureFOVResult, LineOfSightResult,
             InstalledEnvironmentResult, PatternComparisonResult
+scenario/   (extends) Scenario: structures + installedPatterns registries, activeConfigId
```

### Phase-2 pattern-data pipeline (dependency direction)

```
file/table --> PatternImporter --> PatternCanonicalizer --> PatternValidator
            --> CanonicalPatternCut --> CutPatternAssembler --> antenna.FreeSpacePattern
            --> (existing) interference.PairwiseAnalyzer
```

- `+patterndata` depends **downward only** (util, geometry, antenna, config). It has **no**
  dependency on `+interference` (VR-121): importers never classify RF risk.
- `CanonicalPatternCut` depends on **no file format** (importers translate files into it).
- The core (`+interference`, `+coupling`, `+rf`) never parses files and is unchanged by Phase 2.
- The source `+Z` boresight convention is confined to `+patterndata`; it reaches the Phase-1
  antenna frame only through the explicit map `M` in `CutPatternAssembler` (VR-121).

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
- **No package depends on `interference`** except `receiver` uses `interference.SpectralCouplingAnalyzer`
  (a pure spectral function with no geometry); this is an acyclic downward edge, not a back-edge to
  the geometric engine.

### Phase-3 linear RF coexistence flow (separated concerns — SR-201)

```
Geometry/Pattern --> (Phase-1) PairwiseAnalyzer --> spatial coupling result
TX SpectrumModel + RX ReceiverFilter --> SpectralCouplingAnalyzer --> spectral factor (linear)
ReceiverNoiseModel --> kTB noise ;  InterferenceCriterion --> allowable
        (spatial x spectral x receiver-criterion)
        --> ReceiverSusceptibilityAnalyzer --> ReceiverSusceptibilityResult
        --> RfCoexistenceAnalyzer (reuses Phase-1 matrix; no geometry recompute)
```

- **Spatial ≠ Spectral ≠ Receiver-susceptibility**: three separate modules; never one block.
- Absolute RF power is produced only in Mode B (physical/far-field-valid coupling). Pattern-only
  stays Mode A (relative); the DirectionalCouplingIndex is never promoted to an absolute loss.
- `spectrum`/`receiver` have **no UI**, do **not** parse pattern files, and compute **no geometry**;
  power integration is in **linear** units (dB never summed).

### Phase-4 nonlinear flow (front-end susceptibility — SR-300)

```
Active TX_i --> (reused) PairwiseAnalyzer --> absolute spatial coupling (far-field valid only)
        + preselector H_pre(f_i)  -->  per-interferer LNA-input power (LNA_INPUT plane)
        --> InterfererAggregator (linear sum)  --> CompressionAnalyzer (P1dB margin)
        --> per interferer/offset            --> BlockingAnalyzer   (blocking margin; no overlap needed)
        --> i<j pairs                        --> IntermodulationAnalyzer (2f1-f2, 2f2-f1; IIP3->IM3)
        --> NonlinearSusceptibilityAnalyzer  --> NonlinearSusceptibilityResult
```

- `+nonlinear` parses no files, computes no geometry, and **consumes existing** Phase-1 pair
  evidence (reuses `PairwiseAnalyzer`); it holds the only edge into `+interference`, an acyclic
  downward reuse.
- Pattern-only coupling ⇒ no absolute LNA-input power ⇒ compression/blocking/IM3 withheld (the
  central invariant). Missing P1dB/IIP3/criteria ⇒ `MISSING_*`, never defaulted. dBm are summed
  only through `util.Units.sumPowers_dBm` (linear domain). Phase-3 linear results are unchanged.

### Phase-5 spacecraft-geometry / installed-environment flow

```
Spacecraft geometry (structures) + antenna installation
   -> LineOfSight (segment blockage)        [geometry evidence only]
   -> AntennaToStructureFOV (footprint + lobe relation, TX & RX)
   -> InstalledPatternSelector (INSTALLED / FREE_SPACE_FALLBACK, explicit)
   -> InstalledEnvironmentAnalyzer -> InstalledEnvironmentResult
The selected pattern flows through the UNCHANGED PairwiseAnalyzer (pattern substituted
into the pair input); geometry alone never changes gain/coupling.
```

- **`geometry`/`installed` compute no EM loss**: blockage/intersection is geometry evidence; a
  `BLOCKED` LOS never becomes an attenuation, an `InstalledPattern` is never derived from geometry,
  and no scattering/reflection/diffraction/HFSS value is generated (central rule, VR-408).
- `geometry` depends on `interference.LobeClassifier` (pattern lobe classification, not receiver
  physics) — an acyclic downward reuse. `InstalledEnvironmentAnalyzer` adds evidence **around** the
  engine and rewrites none of `PairwiseAnalyzer`/`RfCoexistenceAnalyzer`/`NonlinearSusceptibilityAnalyzer`.
- Geometry risk is a **screening** label, distinct from Phase-3/4 physical margins.
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
