# Acceptance checkpoint

This is a source-stable fresh-process PRE-FINAL candidate, not an RFC PASS.

- Geometry: four common-ended half-turn arms; helix diameter 18 mm, axial rise 52 mm, wire radius 1.5 mm, feed gap 1.2 mm; 65 mm conductive grooved base. Internal dimensions are assumed/EM-derived, not commercial CAD.
- Center-frequency accepted-power CP radiation MAE: TC 0.726 dB; TM 1.029 dB (XZ/YZ). These meet the radiation-only primary MAE gate. Hold radiation geometry rather than continue pattern fitting.
- Actual active return loss across the solved band: approximately 4.00–5.79 dB; FAIL against >10 dB. Accepted-power normalization does not establish realized-gain acceptance.
- Six frequency farfields and all-port S matrix were extracted. Mesh convergence and final polarization/coverage validation remain incomplete.
- Repository data/Sband_TMTC/README.md identifies the target as an approximated upper/max datasheet envelope, sampled originally every 10 degrees and interpolated to 1 degree. Independent min-envelope data are unavailable in the CSVs.
- Interpolated points contribute to main MAE only. Assumed sidelobe/backlobe samples are not hard anchors. Source-qualified anchors require explicit provenance. A complete source min/max envelope uses distance outside the interval, with zero penalty inside it; the existing lone upper curve cannot prove interval inclusion.
- The existing legacy rfc_validation.json retains its older fixed-anchor evaluation. It is PRE-FINAL and is not final evidence under the revised source-qualified policy. The new source_reference_metrics implementation and regression test establish the revised calculation; source anchor/bound extraction is still pending.

Next: preserve the radiation baseline, validate a physically credible matching approach, then verify realized CP gain, low/center/high robustness and mesh convergence in a fresh pinned run. No later antenna has been declared complete.
