# CST reconstruction work log

## Current policy

- Sequence: S-band → L-band → ISL → Ka-band → SAR.
- S-band was accepted by the user for RFC screening. Its geometry is frozen.
- Main coverage MAE ≤1.5 dB; source-based anchors ≤2 dB; stricter boresight/EOC limits. Interpolated points contribute to MAE only. Assumed sidelobe/backlobe points are never hard anchors. Missing min-envelope data are not invented.
- Accepted-power gain/farfield is the model basis. Active return loss is diagnostic, not a hard gate. Realized gain/absolute conducted-power transfer would require separate matching acceptance.
- Mesh verification/refinement is disabled by user instruction. No numerical convergence claim is made.
- Project candidates have separate names and deterministic generators refuse overwrite. `versions/lband/` stores immutable checkpoint manifests and source/evidence snapshots; current source snapshots do not retroactively prove the exact source used by old runs.

## L-band L5 candidate history

| Version | CST project label | Controlled change | Outcome |
|---|---|---|---|
| L5-v01 | LBAND_GNSS_BUDGET | Initial 140/135 mm stacked patches, 60 mm chokes; Learning Edition resource settings | Actual 4-port solve; center MAE 0.529 dB, low MAE 2.382 dB. NOT PASS. |
| L5-v02 | LBAND_GNSS_UPPER120 | Upper patch 135→120 mm only | Initial run aborted; same-model retry completed all four solves. MAE 0.36–0.52 dB; high peak error 1.052 dB. NOT PASS. |
| L5-v03 | LBAND_GNSS_UPPER123 | Upper patch 120→123 mm only | Four successful solves. MAE 0.41–0.66 dB; low EOC error about 1.97 dB. NOT PASS. |
| L5-v04 | LBAND_GNSS_CHOKE637 | Choke depth 60→63.7 mm only | Four successful solves. MAE 0.59–0.60 dB; peak error 0.60–0.97 dB; EOC error −0.28 to +0.47 dB; all recorded source-derived screening anchors pass. Core L5 radiation gates met; freeze geometry. |
| L-v05 | LBAND_GNSS_V05_BANDCHECK | Same v04 geometry, additional 1207/L1 monitors and wider solve range | Four successful solves; 1207 center MAE 0.44 dB. L1 MAE 1.52–1.60 dB and horizon error about 5 dB: FAIL. Broadband L5 endpoints differ from v04; v04 acceptance is confined to its recorded solver configuration. |
| L1-v06 | LBAND_GNSS_V06_L1_CHOKE476 | Separate L1 surrogate: 47.6 mm quarter-wave choke, otherwise v04 dimensions | MAE 0.96–1.08 dB and peak error 0.71–0.78 dB; HPBW about 61 degrees vs target 73 and EOC underestimation 2.6–3.0 dB: FAIL. |
| L1-v07 | LBAND_GNSS_V07_L1_CUP336 | Cup depth 45→33.6 mm only, matching the L5-to-L1 wavelength ratio | Completed; MAE 1.54-1.76 dB and narrower coverage. Rejected. |

L5-v04 HPBW is 72/70/70 degrees (low/center/high), target approximately 72 degrees. RHCP AR at 60 degrees is 2.52/1.30/1.07 dB. Worst hemisphere AR at low frequency is about 7.93 dB near horizon; this remains a documented polarization limitation, not concealed as a full-hemisphere AR<5 dB result. Fixed RHCP excitation is 0/−90/−180/−270 degrees.

The 200 mm outer diameter and 87 mm maximum envelope are datasheet values. Internal geometry is confidence C. Target CSVs are approximate upper-envelope screening cuts with confidence B original 10-degree samples. They are not manufacturer numeric EM fields or complete min/max envelopes.

## Final L-band disposition

- L-v08 arithmetic choke midpoint 55.65 mm was tested once and rejected: 1207 MHz MAE about 3.31 dB. No further tuning.
- Selected common geometry: v05/v04 dimensions, upper patch 123 mm, choke depth 63.7 mm, cup depth 45 mm. Saved as LBAND_GNSS_FINAL_COMPROMISE.cst.
- User-directed common-band compromise; nominal pooled XZ/YZ coverage MAE 0.832 dB. This does not imply every band passes strict guards. L1 nominal MAE about 1.52 dB and horizon deficit about 5 dB remain explicit.
- Six nominal canonical 1-degree scalar exports and native CST complex far-field sources are in exports/lband/. Unvalidated scalar regions use max(CST, reference); physical complex fields are unchanged.
- Separate narrow L5-v04 radiation PASS remains configuration-specific. Active matching is diagnostic. Mesh verification is disabled; convergence is not claimed.
- Actual geometry screenshot remains unavailable; no illustrative Python plot is substituted.
- L-band design rationale and final spec are saved. Proceed to X-band ISL, then Ka-band, then SAR.

## Automation bridge (2026-10-03)

`tools/invoke-cst.ps1`: PowerShell -> COM `CSTStudio.Application` -> `AddToHistory`. Located under `cst/tools/` (repository changes restricted to `cst/`). Verified: attach/status read-only, frozen-project refusal, NewMWS + History templates, StoreParameter + `Rebuild()` (brick 1200 -> 2000 mm3), SaveAs no-overwrite, `Solver.Start` + Model.log parsing, S-parameter export. Details: `tools/README.md`, log `tools/logs/invoke-cst.jsonl`. Candidate History is rendered by `generate_isl.py` into `tools/commands/<LABEL>/history.vba` and executed by job JSON.

## X-band ISL

No repository numeric target. ASSUMPTIONS (specs/xband_isl.yaml): 8.0/8.2/8.4 GHz, RHCP, cos^1 power template (6.02 dBi peak, -3 dB at 60 deg, HPBW 120 deg). All template points ASSUMED: no hard anchors. Gates: 0-60 deg MAE <=1.5 dB, HPBW 120 +/-10 %. Accepted-power RHCP gain; active RL and AR diagnostic. Mesh validation disabled. Phases 0/-90/-180/-270 deg; RHCP discrimination at boresight 80-108 dB for all candidates.

| Version | Project | Change | Result (8.0/8.2/8.4 GHz, XZ=YZ) |
|---|---|---|---|
| isl-v01 | ISL_A_QHELIX_SCALED | Accepted S-band 4-arm helix x(2.25/8.2), mirrored winding; CST default mesh, 79,376 cells | MAE 2.51/2.67/2.83, shape-only MAE 0.9, peak 2.4-2.6 dBi, HPBW 183-191 deg: too broad. NOT PASS |
| isl-v02 | ISL_B_CUPPATCH | Air patch D16.6 h2.5, 4 probes r3, ground R15 + 4 mm rim; Hex 8, 34,848 cells | MAE 1.76/1.87/1.98, peak 9.0-9.3 dBi, HPBW 66-68 deg: too narrow. NOT PASS |
| isl-v03 | ISL_B2_FLAT_RG11 | rim removed, ground R15 -> 11 | MAE 1.76-2.01, HPBW 66-69 deg; coverage AR 9-12 dB. NOT PASS |
| isl-v04 | ISL_B3_FLAT_RG9P5 | rim removed, ground R 9.5 | MAE 1.63-1.88, HPBW 67-70 deg; coverage AR 8-11 dB. NOT PASS |

Finding (8.2 GHz assumption set): ground/rim size did not broaden the air patch; scaled helix far too broad. Superseded by the owner requirement below.

### Owner requirement (2026-10-03): 10.4 GHz, 3 dB beamwidth about 60 deg, overall beamwidth about 120 deg

Template (ASSUMED, no hard anchors): G0 + 10 q log10(cos theta), q = 4.819 (-3 dB at 30 deg, -14.5 dB at 60 deg); G0 = 10 log10(32400/60^2) = 9.54 dBi. Monitors 10.3/10.4/10.5 GHz (band edges ASSUMED). Gates: 0-60 deg MAE <=1.5 dB, HPBW 60 +/-10 %.

| Version | Project | Controlled change | Result (10.3/10.4/10.5 GHz, XZ=YZ) |
|---|---|---|---|
| isl-v05 | ISL_C_CUPPATCH_10G4 | isl-v02 cup patch scaled by 8.2/10.4 | MAE 1.13/1.10/1.06 PASS; HPBW 67.7/67.1/66.6 deg FAIL (limit 66) |
| isl-v06 | ISL_C2_CUP_RIM7P2 | rim 3.154 -> 7.2 mm | HPBW 69-70 deg (broader); coverage AR 0.4-0.65 dB. Rejected |
| isl-v07 | ISL_C3_CUP_R17 | ground/cup radius 11.83 -> 17 mm | MAE 0.57-0.66; HPBW 53.6-54.7 deg (just below 54); coverage AR 14-17 dB. Rejected |
| isl-v08 | ISL_C4_CUP_R14P7 | radius 14.7 mm (linear interpolation of v05/v07) | MAE 0.87/0.85/0.84, shape-only 0.37-0.47; HPBW 60.0/59.5/59.0 deg; peak 10.0 dBi; boresight error +0.4 to +0.5 dB. PASS - SELECTED, frozen |

Selected ISL geometry (all confidence C, air/PEC): cup floor radius 14.7 mm, floor 0.789 mm, rim height 3.154 mm, rim thickness 0.789 mm; circular patch D13.089 mm at h 1.971 mm, thickness 0.394 mm; four probes r 0.315 mm at radius 2.365 mm; 0.394 mm discrete-port gap; phases 0/-90/-180/-270 deg (RHCP, boresight discrimination >100 dB). Hex 8 cells/wavelength resource mesh, 29,988 cells; no convergence claim.

Diagnostics, not gates: active RL 5.0-6.4 dB (accepted-power basis; realized gain/absolute transfer would need separate matching). Coverage AR rises off-axis to 8-9 dB at 60 deg (AR <3 dB inside about +/-30 deg) - documented polarization limitation. Template at 60 deg is ASSUMED; CST is about +3 dB above it there, which is conservative for interference screening.

Exports: `exports/isl/screening_1deg/` (6 cuts, 1-degree; 0-60 deg = CST accepted-power RHCP, elsewhere max(CST, conservative assumed envelope)); `exports/isl/isl_rhcp_broadband.ffs` native complex CST source, 3 frequencies in one file, unclipped. ISL complete under owner requirement + recorded assumptions. Next: Ka-band DLS.

## Ka-band DLS (2026-10-03)

Reference audit: specs/kaband_dls.yaml. Repository CSV hash matches SSOT; README band-average anchors equal the Beyond Gravity K-band datasheet (1399728/01-22 p.3, 0.22 m MetOp-SG all-metal Cassegrain) 25.5/27 GHz means. SSOT "32.2 dBi" conflict has no source; datasheet 31.2 dBi retained. Owner (2026-10-03): CSV beamwidth beyond the datasheet anchors was generated arbitrarily, not physically; datasheet reference has priority and passing it is acceptance; produce a physically consistent pattern. Reflector diameter 220 mm (owner estimate, datasheet < 222 mm).

Method (Learning Edition: no PO/asymptotic, 100k cells): CST full-wave CP feed -> Python equivalent-paraboloid aperture integration (ka_reflector_po.py, verified against Silver closed form 0.8288 to 1e-3) with subreflector blockage; spillover lost from main beam (accepted-power). Feed phase errors neglected (focused).

| Version | Project | Change | Result |
|---|---|---|---|
| ka-v01 | KA_FEED_A_STEPHORN | 5-step circular horn, aperture D15.8, Hex 10 | Mesh > 100k cells; solver refused. Not solved |
| ka-v02 | KA_FEED_B_STEPHORN_M8 | Hex 8, probe/gap 0.3 -> 0.5 mm | Still > 100k (many concentric fixpoints). Not solved |
| ka-v03 | KA_FEED_C_OEWG | Open-ended circular waveguide r4.4 (TE11 cut-off 20.0 GHz), back short, 4 radial probes 0/-90/-180/-270 | 25,872 cells, 4/4 solved. Feed 8.8-9.2 dBi, HPBW 64-68 deg, RHCP, XPD >100 dB, active RL 9-11.7 dB (diagnostic) |

Reflector sweep (theta_f 14-44 deg, Ds 30-55 mm) with the actual CST feed. Selected: D 220 mm, subreflector edge half-angle theta_f 40 deg (Fe 151 mm; with assumed F 60 mm, M 2.5, dish depth 50.4 mm within 92.2 mm height), Ds 44 mm. Datasheet anchor errors: 25.5 GHz 0/0.5/0.75/1.0 deg -0.32/-0.29/-0.33/-0.43 dB; 27 GHz -0.32/-0.33/-0.31/+0.54 dB. All within 0.7/1.0 dB: KA_DATASHEET_ANCHOR_PASS. XPD within 1 deg 34.7-36.0 dB (> 29 dB). HPBW 3.23/3.14/3.06 deg; first null 3.65-3.8 deg; first sidelobe 4.95-5.25 deg at 15.5-16.0 dBi.

Exports `exports/ka/`: screening_1deg (25.5/26.25/27 GHz, XZ=YZ; 0-1 deg model, elsewhere max(model, existing CSV)), raw_model 1 deg and 0.05 deg cuts. Proposed replacement for the arbitrary CSV main-lobe/near-sidelobe region (e.g. 3 deg 15.0 -> 18.7 dBi, 5 deg 10.5 -> 15.7 dBi at 26.25 GHz); data/ untouched. No native complex reflector source (reflector stage is not CST). Mesh validation disabled. Next: X-band SAR.

## X-band SAR example (2026-10-03)

Owner: SAR is an example; 8 GHz, about 1 deg beam; array, but design at leaf (element) level only; beamwidth is an array property and not a leaf gate. Assumptions SAR-A1..A8 in specs/xband_sar.yaml (7.85/8.0/8.15 GHz, single linear pol, 80 x 13 Taylor -25 dB at 28.106 mm = 0.75 lambda, 2.248 x 0.365 m; az 1 deg / el ~6 deg).

Leaf: air-loaded rectangular patch on a 28.106 mm PEC cell, h 2.5 mm, W 17 mm. Leaf gates: broadside peak, resonance inside band; RL diagnostic.

| Version | Project | Change | Result |
|---|---|---|---|
| sar-v01 | SAR_LEAF_A_PATCH | L 15.5, single probe 2.5 mm off-centre | 23,976 cells. S11 min -5.8 dB at 7.65 GHz (below band). NOT PASS |
| sar-v02 | SAR_LEAF_B_L14P8 | L 15.5 -> 14.8 (resonance ratio) | S11 min at 7.95 GHz; E-plane peak at 9 deg, +/-30 deg asymmetry 3.8 dB (probe radiation). NOT PASS |
| sar-v03 | SAR_LEAF_C_DUALFEED | two symmetric probes +/-2.5 mm, 0/180 deg | 25,272 cells, 2/2 solved. Peak at 0 deg, symmetric; 9.28/9.38/9.46 dBi; E/H HPBW 58-60/65-67 deg; F/B 15 dB (leaf ground only); active RL 7.4/9.4/9.8 dB (diagnostic). SAR_LEAF_PASS - SELECTED, frozen |

Principal-plane cross-pol is a symmetry null (numerically ~300 dB) and is not a meaningful XPD figure. Array example (NON-CST, coupling neglected): HPBW az 1.026/1.007/0.988 deg, el 6.30/6.18/6.07 deg, first sidelobes about -15 dB (Taylor + leaf), aperture gain 37.6-38.0 dBi (isolated-leaf cross-check 38.6-38.8). Exports `exports/sar/`: leaf native broadband .ffs (LEAF_DIFF, unclipped); array_example 1-degree cuts (front max(model, -10 dBi floor), back peak-40 dB ASSUMED - isolated-leaf F/B x coherent AF would give an artificial 22 dBi backlobe) and raw 0.01-degree 0-20 deg main-beam cuts. Mesh validation disabled.

All five stages (S, L, ISL, Ka, SAR) have a disposition.

## Installed-pattern scope update (2026-10-04)

Owner labels the existing original/free-space pattern as **1**. The next stage, **2**, is installed pattern with actual nearby spacecraft structure for RFC/RFI. The final required frequency span is **1–27 GHz**; S-band TM/TC local scattering is the first validation stage, not the final scope limit. Clarification is pending on every antenna across the full interval versus all antenna operating bands within it. Preserve existing original projects and datasets.

Follow the attached local-scattering prompt: CST Learning Edition Time Domain, actual SSOT facets and unchanged installation reference points, rear panel 8 included, matched free/installed normalization, actual cells below 100k before solving, R3/R4/R5 and mesh convergence, and provenance CST_LEARNING_LOCAL_SCATTERING_APPROX. Earlier original-stage mesh-verification exemptions do not establish convergence for this new installed stage. Never reuse a single S-band scattering correction over 1–27 GHz.

Verified S-band original Model.log: SBAND_MATCHING_WIRE15, 79,376 cells, four completed excitations. Installed simulation/export/import verification remains pending. Detailed status and frequency-source limitations: `docs/reports/cst_learning_installed_sband.md`.

### Owner clarification: operating-band installed calculations

Owner clarified that each antenna should be calculated in its own operating bands within the overall 1–27 GHz envelope. Use existing port excitations; a separate EM scan is not part of the installed-pattern task. The pending full-range-versus-operating-band question above is resolved in favor of operating bands. The report now records S TC/TM, GNSS L1/L5 plus the 1.207 GHz proxy, ISL and Ka bands, and the deferred SAR example. Assumed bandwidth windows remain labelled; the 1.207 GHz proxy must not be relabelled as genuine GPS L2. Ka feed-only and SAR leaf-only ports do not establish complete reflector/array installed results.

### Latest owner-approved execution (2026-10-04)

Scope subsequently expanded: retain geometry and port excitation; evaluate each existing antenna at each interferer band (8 bands), not just its own operating band. No separate EM scan. Installed models only S/L where actual mesh budget permits; ISL/Ka free-space; SAR source pattern deferred but evaluate other antennas in 8.9–10.4 GHz. ISL owner band 10.55–10.65 GHz; L2 first point 1.22760 GHz on the fixed L geometry (not the measured-source 1.207 GHz proxy).

Actual ISL_FIXED_10G6: 29,988 cells, four successful excitations, 50 s, no logged warnings/errors. At 10.6 GHz: accepted-power RHCP peak 10.142 dBi, HPBW 58.527 deg, active RL min 7.157 dB; vs original 10.4, +0.122 dB / -0.979 deg / +1.515 dB. Existing assumed-template gates pass; no mesh-convergence claim. New frequency-tagged dataset files added with old files preserved; active binding ISL_10P6.

New S_TM FREE actual run: 71,632 cells, four excitations, 133.6 s. SBA_NADIR installed R3 true panels 1/6/8: 620,658 cells at 8 steps/wave, 377,720 at 6, 171,808 at 4 with ratio 10. GPSA_1 L1 R3 true panels 3/4: 528,656 at 8, 333,822 at 6. Over-limit installed solvers not started. Geometry invariants pass 3 Python tests. Frequency-response batch outputs and live statuses: results/rfc_frequency_cases. Current execution report: docs/reports/cst_rfc_frequency_execution.md.
