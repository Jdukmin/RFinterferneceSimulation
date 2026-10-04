# KAA victim-band response (L/S/X) — Tier 3 ENGINEERING_BOUND only

`kaa_victim_band_response.csv` holds **no CST result and no pattern**. The KAA has a feed-only CST model at 25.5/26.25/27 GHz and a
non-CST equivalent-paraboloid stage; there is no victim-band feed pattern, reflector solve, or excitation definition, so the
classification is `GAIN_BOUND_ONLY`. The table gives a direction-independent ceiling on the KAA radiation gain:

    G_max = max( (pi D / lambda)^2 , (ka)^2 + 2 ka ),  D = 0.22 m, a = D/2, k = 2 pi / lambda      [dBi]

(aperture bound 4 pi A / lambda^2 with eta = 1; Harrington/Chu sphere bound; directivity bounds realised gain). Every row is tagged
`ENGINEERING_BOUND;NOT_MEASURED;NOT_CST_VALIDATED`. The XZ/YZ RealizedGain cuts, the victim-direction gain, and the normalisation are
`NOT_AVAILABLE` / `NOT_APPLICABLE` by design; the 25.5-27 GHz CST patterns (`data/Kaband_KAA_CST`) are never extrapolated here.
Do not read these values as measured or CST-validated gain. Source: `src/+rfscreen/+kaa/KaaVictimBandBound.m`; used by
`output/claude/run_kaa_victimband_analysis.m`; report `output/claude/KAA_저주파_방사응답_결과보고서.md`.
