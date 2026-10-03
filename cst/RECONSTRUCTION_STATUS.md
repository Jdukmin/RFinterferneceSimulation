# Free-space antenna reconstruction

Execution order: S-band, L-band, ISL, Ka-band, SAR. Later stages must not be reported as completed before their EM work exists.

The user's latest instruction supersedes broad literature/image searches: use supplied architecture and envelopes; look up only missing numeric dimensions or required CST syntax. Do not infer internal dimensions from product photos.

## Repository reference data

`specs/repository_ssot.json` records 16 complete 360-point target CSVs, their hashes, selected-angle gains and provenance. Source coordinates use +Z boresight, mapped to repository antenna +X by `[0 0 1; 1 0 0; 0 1 0]`.

- S-band TC: 2.000–2.120 GHz; TM: 2.200–2.300 GHz. SBA1 peak: TC 3.8 dBi / TM 3.2 dBi. SBA4 peak: TC 4.0 dBi / TM 2.9 dBi. These are different variant targets and must not be blended into one physical antenna.
- GNSS L5 target peak: 7.8 dBi, nominal analysis frequency 1176.45 MHz. L1 target peak: 9.1 dBi, 1575.42 MHz. The middle 1207 MHz cut is an L2 screening proxy, not certified GPS L2 at 1227.60 MHz.
- Ka: 25.5–27 GHz, 220 mm dish, target CSV peak 32.95 dBi. The 1-degree target cannot resolve all sub-degree main-beam anchors. Generic sidelobes and backlobes are assumptions.
- No numerical X-band ISL/SAR target or product-specific geometry was found in the repository text audit. Their user-supplied architecture remains an explicitly labelled assumption rather than a repository fact.

## S-band initial geometry

`generate_sband_ttc.py` creates a new project with a 65 mm diameter cylindrical conductive base. A floor beneath two annular recesses connects three concentric metal regions; initial groove intervals are 12–20 and 22–30 mm radius, depth 20 mm. Four circular-section helical conductors lie on an 18 mm diameter cylinder and rise 150 mm in three turns. They have a 1 mm conductor radius and a 2 mm feed gap. Radial end conductors connect all arms at the top. Four ideal 50 ohm discrete ports feed the arm bottoms.

The 65 mm outside diameter is source-stated (A). Internal dimensions are EM initial estimates (C), not inferred product dimensions. Quadrifilar topology is user-selected and permitted by the multifilar patent; the illustrated patent embodiment is trifilar. Ideal arm ports de-embed the undisclosed commercial polarizer/feed network. PEC omits conductor losses; dielectric substrate and radome are still unresolved.

The first polygon-cylinder version crashed CST during repeated boolean union. The revised generator uses one `Polygon3D`/`SweepCurve` solid per helical arm and separate intersecting radial terminations, avoiding hundreds of boolean operations. It successfully created and solved `projects/SBAND_TTC_INITIAL.cst` at 70,400 hexahedral cells, -40 dB energy criterion, with all four individual-port excitations calculated. Staircase PEC mesh warnings remain; mesh convergence is not established.

## Result interpretation

Active reflection uses the complete complex S matrix: `Gamma_i = (S a)_i / a_i`, with `a = [1, j, -1, -j]`. CST `CombineResults` coherently combines the four independently computed farfields; it does not average their powers.

Important CST normalization check: `GetListItem(..., "Abs")` in gain modes returns linear power gain. Raw complex field components retain a separate normalization and cannot be squared directly to obtain gain. At TM boresight, CST directivity 4.32036067 (linear), radiation efficiency 0.999906 and total efficiency 0.56728856 yield realized gain 2.45089117 (linear), verifying the power relationship. Initial erroneous field-squared comparison files were overwritten by corrected results.

The current comparison quantity is **total realized gain**; source target is co-pol screening gain. Circular components are also exported, but handedness qualification and final co-pol target comparison remain pending. Do not label the current total-gain comparison as a completed polarization validation.

Corrected initial SBA1 coverage RMS: approximately 8.2 dB TC and 7.0 dB TM. Active return loss at representative frequencies is approximately 5.10 dB TC and 3.44 dB TM. This model fails pattern/matching acceptance and is only an initial candidate.

Ordered tuning uses diameter first, height/pitch second, then turns/electrical length. It keeps feed dimensions fixed during pattern sweeps and records each candidate separately in `results/sband_tuning.json`. Matching/polarization tuning follows topology/pattern assessment.

## Current validation

| Stage | Geometry | Matching | Pattern | Polarization | Target traceability |
|---|---|---|---|---|---|
| S-band initial | CREATED; volume/port checks passed; connectivity/mesh convergence pending | FAIL | FAIL | UNVERIFIED | CSV hashes and source-guided topology recorded; internal dimensions C |
| L-band | NOT STARTED | NOT RUN | NOT RUN | NOT RUN | CSV target recorded |
| ISL | NOT STARTED | NOT RUN | NOT RUN | NOT RUN | Repository target absent; assumption needed |
| Ka-band | NOT STARTED | NOT RUN | NOT RUN | NOT RUN | CSV target recorded; sub-degree/spec discrepancy recorded |
| SAR | NOT STARTED | NOT RUN | NOT RUN | NOT RUN | User reference architecture |

Source evidence is embedded in `specs/sband_ttc.yaml`, with links tied to the particular envelope/topology statements rather than a bibliography dump.
