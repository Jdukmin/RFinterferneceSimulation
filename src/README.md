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
| **`+spectrum`** *(Phase 3)* | `SpectrumModel`, `RectangularSpectrum`, `TabulatedSpectrum` (linear PSD W/Hz), `SpectrumProvenance` |
| **`+receiver`** *(Phase 3)* | `ReceiverFilter`/`IdealBandpassFilter`/`TabulatedFilterResponse`, `ReceiverNoiseModel`, `InterferenceCriterion`, `ReceiverSusceptibilityAnalyzer`/`…Result`, `ReferencePlane`, enums |

## `+spectrum` / `+receiver` (Phase 3 — linear RF coexistence)

`interference.SpectralCouplingAnalyzer` integrates TX PSD × RX filter in **linear** units over a
deterministic union grid (no geometry). `receiver.ReceiverSusceptibilityAnalyzer` combines that
spectral factor with the Phase-1 spatial coupling, kTB noise, and an `InterferenceCriterion` to
produce a `ReceiverSusceptibilityResult` — in **absolute** mode only when the coupling is physical
(far-field valid), otherwise **relative screening** (no fabricated absolute power).
`interference.RfCoexistenceAnalyzer` runs this over a scenario, **reusing** the Phase-1 matrix.
Contracts: `docs/icd/spectrum.md`, `docs/icd/receiver_susceptibility.md`. `+spectrum`/`+receiver`
have no UI, do not parse files, and compute no geometry.

Minimal usage:

```matlab
sp   = rfscreen.spectrum.RectangularSpectrum(2.2e9, 20e6, 30, struct());          % 30 dBm, 20 MHz
filt = rfscreen.receiver.IdealBandpassFilter([2.19e9 2.21e9], 0, -Inf);
nm   = rfscreen.receiver.ReceiverNoiseModel(struct('noiseFigure_dB', 3));
crit = rfscreen.receiver.InterferenceCriterion('I_N_MAX', -6);
% attach to TX/RX (optional) and run coexistence over a scenario:
%   RFTransmitter(..., struct('spectrum', sp))
%   RFReceiver(...,   struct('filter', filt, 'noiseModel', nm, 'interferenceCriterion', crit))
out  = rfscreen.interference.RfCoexistenceAnalyzer.analyze(scenario, ...
           rfscreen.config.AnalysisConfig(struct('couplingModel','FAR_FIELD')));
s    = rfscreen.interference.RfCoexistenceAnalyzer.susceptibilityOf(out, 'TX1', 'RX1');
```

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
