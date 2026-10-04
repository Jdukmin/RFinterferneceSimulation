# CST installed-pattern work status

Updated: 2026-10-04 (Asia/Seoul).

**Latest execution scope:** see `cst_rfc_frequency_execution.md`. The owner has
since requested fixed-geometry port calculations at each interferer band, not
only each antenna's operating band. Installed calculations apply only to S/L
within the mesh budget; ISL/Ka stay free-space and SAR has no bound source
pattern. ISL band is now 10.55–10.65 GHz and SAR is 8.9–10.4 GHz. ISL's new
band calculation is completed; the attempted S/L R3 installed meshes exceed
100k cells. The initial plan/audit below records earlier context, not current
execution completion.

## Owner requirements and current numbering

1. **Original pattern**: the previously generated isolated/free-space antenna patterns. Preserve these as the baseline; do not overwrite them with installed results.
2. **Installed pattern**: the same antenna with nearby actual spacecraft structure, for RFC/RFI analysis. This stage is pending; no installed solver results or convergence PASS are claimed.

The owner clarified that **1–27 GHz is the overall RFC analysis envelope; installed calculations are required in each antenna's operating bands**, not for every antenna across that entire interval. S-band is the first validation stage. Gaps between operating bands are not simulated or claimed as continuous installed coverage. Use existing port excitations and frequency monitors for installed radiation patterns; no separate EM scan is required for this deliverable. Out-of-band interference, if later requested, requires appropriate receiving response and radio filtering/blocking data.

## Operating-band audit (repository definitions)

| Installations / function | Band GHz | Initial monitors GHz | Evidence / limitation |
|---|---|---|---|
| SBA_NADIR and SBA_ZENITH TC | 2.000–2.120 | 2.000 / 2.060 / 2.120 | Datasheet-derived band; SBA1/SBA4 remain separate reference variants |
| SBA_NADIR and SBA_ZENITH TM | 2.200–2.300 | 2.200 / 2.250 / 2.300 | Datasheet-derived band; TM first |
| GPSA_1 and GPSA_2 L1/E1 | 1.563–1.588 | 1.563 / 1.575 / 1.588 | Repository monitor window is ASSUMED; not a verified receiver passband |
| GPSA_1 and GPSA_2 L5/E5a | 1.164–1.189 | 1.164 / 1.176 / 1.189 | Repository monitor window is ASSUMED; not a verified receiver passband |
| GPSA_1 and GPSA_2 middle GNSS proxy | Point 1.207 | 1.207 | Source graph label only; NOT genuine GPS L2 1.22760 GHz numeric pattern data; operating bandwidth unconfirmed |
| ISL | 10.300–10.500 | 10.300 / 10.400 / 10.500 | Owner center 10.4; edges ASSUMED sensitivity window |
| KAA_1 and KAA_2 | 25.500–27.000 | 25.500 / 26.250 / 27.000 | Datasheet band; CST feed plus non-CST reflector model, not a full reflector port model |
| SAR_ANT example | 7.850–8.150 | 7.850 / 8.000 / 8.150 | Owner center 8; edges ASSUMED; repository RFC binding remains DEFERRED_CLOSED_NETWORK |

Audit sources: `data/spacecraft/simplified_spacecraft_v1/pattern_bindings.csv`, `antenna_functions.csv`, band dataset READMEs and `cst/specs/xband_sar.yaml`. These are the current model definitions, not a new manufacturer-band certification. Band-edge/center sampling starts the calculation; add monitors when frequency dependence is insufficiently resolved.

Preserve port phase/amplitude and termination conditions per antenna. For passive reciprocal antenna models, transmitting port-driven patterns also describe receiving directionality with consistent polarization conventions. Installed far fields do not by themselves establish direct near-field port-to-port coupling; an S21 deliverable would require both antennas and their terminations in a suitable joint model. Ka feed-only and SAR leaf-only ports do not establish installed response of their complete reflector/array.

## Verified existing baseline

- S-band selected frozen surrogate: `cst/projects/SBAND_MATCHING_WIRE15.cst`.
- Definition: `cst/specs/sband_matching_wire15.json`; four-arm helix, base diameter 65 mm, helix diameter 18 mm, height 52 mm, half turn, wire radius 1.5 mm, feed gap 1.2 mm, groove depth 20 mm. Reuse this accepted geometry rather than replacing it with the illustrative starting helix in the attached prompt.
- Its `Result/Model.log` records **79,376 hexahedral cells**, four successful excitations, and completed Time Domain S-ParameterSolver. This is the existing original run, not an installed run.
- Original acceptance uses accepted-power gain. Matching remains diagnostic. Prior original-pattern acceptance does not establish installed-pattern extent or mesh convergence.
- `data/Sband_TMTC/README.md` defines `theta,gain` CSVs in degrees/dBi. These are interpolated datasheet-envelope screening sources, not measured complex fields or certified manufacturer numeric patterns.
- Existing stages also have L-band, ISL, Ka and SAR dispositions in `cst/WORKLOG.md`. Their isolated results do not establish 1–27 GHz installed coverage. Ka reflector and SAR array stages include calculations outside CST and need their own installation method assessment.

## First installed stage

Follow the attached 2026-10-04 local-scattering prompt, subject to the expanded final frequency range:

1. Audit actual geometry, source patterns and automation.
2. Reuse the frozen S-band antenna for a consistent TM 2.25 GHz free baseline.
3. SBA_NADIR: installed R3, R4, R5; then SBA_ZENITH with the same sequence.
4. Use the same physical geometry for TC 2.06 GHz and matched free/installed comparisons.
5. Export angular results, integrate with InstalledPattern and report actual comparisons and convergence.
6. Extend the validated workflow to each antenna's operating bands within the 1–27 GHz RFC envelope. S-band completion gates expansion. Preserve SAR's deferred binding unless the owner changes that scope.

Preserve installation reference points exactly: NADIR (255,870,1030) mm, panel 6, boresight (0,sqrt(3)/2,1/2); ZENITH (255,-530,-1240) mm, panel 4, boresight (0,0,-1). Local +X is spacecraft +X; local +Z is boresight; local +Y is +Z cross +X. Use the supplied six-vertex spacecraft cross-section as geometry SSOT.

Include the actual rear panel 8 at X=0 in both cases. Report supporting-plane distances separately from minimum distances to finite facets and actual edges. Do not project antenna references onto the hull or invent unprovided brackets, cables or radomes. Crop actual nearby facets; do not create the whole 6 m bus.

Use CST 2026 Learning Edition Time Domain through Python 3.12 / win32com / CSTStudio.Application / Active3D / AddToHistory. Verify actual mesh count below 100,000 before each solve, together with bounding box and mesh-step extrema. PEC sheets and antenna-local refinement are the starting strategy. The new installed task requires extent and mesh convergence; earlier original-stage decisions to skip mesh verification do not satisfy this requirement.

## Frequency-dependent correction and provenance

For matching geometry, excitation, polarization and accepted-power normalization at frequency f:

`DeltaG(f,theta,phi) = G_installed_surrogate(f,theta,phi) - G_free_surrogate(f,theta,phi)`

`G_inst_est(f,theta,phi) = G_reference_free(f,theta,phi) + DeltaG(f,theta,phi)`

Use provenance `CST_LEARNING_LOCAL_SCATTERING_APPROX`. Do not copy the S-band correction to other frequencies or imply that a band's isolated template is validated outside its source range. Unsupported frequencies remain explicitly unsupported until a physically defensible source and installed calculation are available. Frequency interpolation needs validation; an arbitrary sample list alone does not demonstrate full-range coverage.

For fixed physical structures, electrical size and mesh burden change with frequency. For example, the 255 mm rear-plane separation is approximately 0.85 wavelengths at 1 GHz, 1.91 at 2.25 GHz and 22.97 at 27 GHz. Keep the mandated rear structure while assessing feasibility; do not silently remove it to fit a smaller high-frequency local radius. A single broadband 1–27 GHz full-wave project is not an established solution under the Learning Edition limit.

Primary export is gain with independent XZ/YZ 1-degree cuts, preferably a full theta/phi grid. No axisymmetry assumption for installed results. Record angular interpolation, source limitations, included/excluded facets, mesh counts, runtime and failed convergence honestly.

## Completion status

Installed CST projects, installed pattern exports, RFC import verification and numerical R3/R4/R5 convergence are **not completed**. This document records the verified starting state and updated scope, not a simulation completion report.
