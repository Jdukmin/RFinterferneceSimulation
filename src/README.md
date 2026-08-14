# `src/` — rfscreen source packages

MATLAB namespace `rfscreen` (add `src/` to the path via `setup_paths`). Written in the
MATLAB-language subset shared with GNU Octave (no `arguments`/`enumeration`/property-validation
blocks, no `import`), so the same code runs under MATLAB R2019b+ and Octave 6+.

## Packages

| Package | Responsibility |
|---------|----------------|
| `+util` | units, constants, validation helpers (leaf) |
| `+geometry` | DCM/quaternion, direction↔az/el, antenna↔antenna FOV; antenna↔structure FOV (reserved) |
| `+antenna` | `Antenna` (hardware) vs `AntennaInstallation`; `AntennaPattern`/`FreeSpacePattern`/`InstalledPattern`; `PatternGrid`; enums; `SyntheticPatternFactory` |
| `+rf` | `RFTransmitter`, `RFReceiver`, `RFFrontEnd`, `FrequencyRelation` |
| `+coupling` | `CouplingModel` boundary; `PatternOnly`/`FarField` (guarded); `MeasuredS21`/`HFSS` (reserved) |
| `+config` | `AnalysisConfig` + policies (lobe, frequency, interpolation, risk, **`PatternImportPolicy`**) |
| `+scenario` | `Scenario`, `OperatingMode` |
| `+results` | `PairResult`, `MatrixResult`, result enums |
| `+interference` | `LobeClassifier`, `InterferenceClassifier`, `PairwiseAnalyzer`, `InterferenceAnalyzer` |
| **`+patterndata`** *(Phase 2)* | external 2D-cut ingestion → canonicalization → validation → `CanonicalPatternCut` → `CutPatternAssembler` → Phase-1 `FreeSpacePattern` |

## `+patterndata` (Phase 2)

`SourceCoordinateConvention`, `PatternFidelity`, `SamplingType`, `ValidationStatus`,
`CanonicalPatternCut`, `PatternValidator` / `CutValidationResult`, `PatternCanonicalizer`,
`PatternImporter` → `TablePatternImporter` / `CsvPatternImporter`, `PatternResampler`,
`CutPatternAssembler`.

Dependency direction is downward only (`util`, `geometry`, `antenna`, `config`); `+patterndata`
has **no** dependency on `+interference`, and the core never parses files. Contract:
`docs/icd/pattern_data.md`. The source `+Z` boresight convention is confined to `+patterndata` and
reaches the Phase-1 antenna frame only via the explicit map `M` in `CutPatternAssembler`.

Minimal usage:

```matlab
setup_paths();
conv = rfscreen.patterndata.SourceCoordinateConvention( ...
    struct('plane','XZ','angleRange','[-180,180]'));
imp  = rfscreen.patterndata.TablePatternImporter(theta_deg, gain_dBi, conv, ...
    struct('patternId','MY_CUT','fidelity','SYNTHETIC_TEST','frequency_Hz',2.2e9));
cut  = imp.importCut();                       % CanonicalPatternCut (native resolution)
% ... build XZ + YZ cuts, then:
p = rfscreen.patterndata.CutPatternAssembler.assembleFreeSpacePattern( ...
    'MY_ANT', xzCut, yzCut, struct('frequency_Hz',2.2e9));   % FreeSpacePattern (APPROX_FROM_CUTS)
```
