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
