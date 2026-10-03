# L-band: selected common-geometry RFC surrogate

Decision: user-directed L1/1207-proxy/L5 compromise, not a claim that all strict per-band product-pattern gates pass. Stop dimension tuning.

Final project: [LBAND_GNSS_FINAL_COMPROMISE.cst](projects/LBAND_GNSS_FINAL_COMPROMISE.cst). Actual CST solver results and raw field cuts remain under `results/LBAND_GNSS_V05_BANDCHECK/`; the independently accepted L5 result remains under `results/LBAND_GNSS_CHOKE637/`.

## Implemented shape and feed

- 200 mm exterior diameter [A], within the published 87 mm height limit [A]. Implemented height is 66.7 mm [C].
- Conductive circular cup: inner diameter 160 mm, 2 mm wall, 45 mm depth [C]. Finite ground floor; no infinite plane.
- Lower driven circular patch: diameter 140 mm, bottom 12 mm above ground, thickness 1 mm [C].
- Upper coupled circular patch: diameter 123 mm, 12 mm spacing above the lower patch's top, thickness 1 mm [C].
- Four probes at radius 35 mm, probe radius 1.5 mm, 2 mm discrete-feed gap [C]. Ideal 50-ohm ports replace the de-embedded commercial feed network.
- Two concentric outer grooves: radii 82–91 mm and 93–98 mm, common depth 63.7 mm [C]. The depth is a L5 quarter-wave initial estimate, then EM-selected; no image scaling is claimed.
- Equal-amplitude 0/−90/−180/−270-degree excitation gives the intended IEEE RHCP. Accepted-power RHCP gain is used; active return loss remains diagnostic only.

The paired patches and finite cup support CP while the two exterior grooves shape horizon and backside radiation. A simple arithmetic midpoint in choke depth generated an undesirable resonant mode near 1207 MHz; it was rejected. The selected shape gives the best balanced existing three-reference result without continuing separate band optimization.

## Actual center-frequency comparison

| Reference | 0–90 degree MAE, XZ | Peak error | 90-degree error |
|---|---:|---:|---:|
| L5, 1176.45 MHz | 0.536 dB | 0.851 dB | −0.189 dB |
| 1207 MHz proxy | 0.440 dB | 0.995 dB | −0.603 dB |
| L1, 1575.42 MHz | 1.519 dB | 1.223 dB | −4.998 dB |

Pooled three-center coverage MAE across both cuts: 0.832 dB. L1 is an explicit fit limitation, particularly near horizon. The 1207 MHz reference is not GPS L2 1227.60 MHz product-certified data.

The separately solved L5 configuration satisfies the strict radiation gates at 1164/1176.45/1189 MHz: MAE 0.59–0.60 dB, peak error 0.60–0.97 dB, all original screening anchors within their limits, HPBW approximately 69–71 degrees versus 71.8-degree interpolated target. Do not extend that acceptance to the wider solver-band configuration: its L5 endpoints differed. No mesh-convergence verification is claimed; it is disabled by user instruction.

## RFC exports and installed-source handoff

- Six canonical 360-row, 1-degree CSVs under `exports/lband/`, with original repository-compatible names.
- Where the raw nominal band cut meets strict gates, validated main uses the CST accepted-power RHCP cut. Other regions use max(CST, reference).
- For unvalidated L1 coverage, the entire uncertain scalar cut uses max(CST, reference), so the roughly 5 dB horizon shortfall is not propagated as an optimistic RFC screening value. Classification and raw gains remain in `.regions.json` files.
- `lband_common_compromise.ffs` is a genuine native CST broadband complex source with seven frequencies. `lband_nominal_sources.ffs` contains the three nominal frequency blocks with every complex field sample unchanged. Native source grid is 5 degrees (73 phi by 37 theta samples); the scalar comparison/export grid is 1 degree.
- Preserve the source's radiated/accepted/stimulated power metadata. Normalize the imported source to accepted or radiated power, not to unverified absolute conducted-power transfer.
- Native source boresight is +Z; use the recorded proper rotation to repository +X when installing it. Native phase origin is retained. Actual commercial phase center is unknown.
- Complex fields are never clipped to the conservative scalar envelope. The raw source retains L1 model uncertainty; scalar screening bounds and uncertainty must accompany installed analyses.

## Provenance and limits

[Beyond Gravity GNSS receiver antenna datasheet](https://www.beyondgravity.com/sites/default/files/media_document/2024-07/Antennas_for_GNSS_receivers_D-I-PRB-00029-SE_01-24.pdf) supplies the exterior envelope and measured pattern-envelope basis. Internal dimensions are confidence C, `ASSUMED_GEOMETRY` / `SURROGATE`. Original target samples are approximate upper-envelope digitizations [B], interpolated to 1 degree; lower-envelope bounds are unavailable in the CSVs and are not invented.

No product CAD, radome dielectric, isolated four-feed network, or exact commercial phase center is claimed. Actual CST geometry screenshots remain missing because the headless/offscreen window capture failed. A post-solve History graphics command opened a result-invalidation confirmation; it was cancelled, preserving results. Source API syntax is verified, but a Python geometry plot is not substituted for CST implementation evidence.

Version manifests and source/evidence snapshots are under `versions/lband/`; current source snapshots are explicitly distinguished from historical generation proof. Geometry validity is supported by actual CST solids/ports and completed EM solves. Strict band fit and user-directed conservative screening acceptance are reported separately in `exports/lband/lband_compromise_validation.json`.
