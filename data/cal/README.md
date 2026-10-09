# data/cal — CST full-sphere 3D Realized Gain drop-in folder (CAL path)

Copy the owner CST Studio ASCII far-field exports here **unchanged** and run, from the repository root:

```bash
octave-cli --no-gui --eval "main('--cal')"      # or, in MATLAB / Octave: main('--cal')
```

```
data/cal/
├─ gps/  GPSA_ORIGINAL_f1.2.txt  GPSA_GPSA1_f1.2.txt  GPSA_GPSA2_f1.2.txt
├─ isl/  RFC_ISL_f1.1764.txt ... RFC_ISL_f10.6.txt            (8 files)
├─ kaa/  RFC_KAA_f1.1764.txt ... RFC_KAA_f10.6.txt            (8 files)
└─ sba/  RFC_SBA_f1.1764.txt ... RFC_SBA_f10.6.txt            (9 files, incl. f2.06)
         RFC_SBA_NADIR_f2.06.txt  RFC_SBA_NADIR_f2.25.txt
         RFC_SBA_ZENITH_f2.06.txt RFC_SBA_ZENITH_f2.25.txt
```

* Format: whitespace-delimited, header + separator lines (their text is ignored), then
  `Theta Phi RealizedGain(dBi) |Eθ| ∠Eθ |Eφ| ∠Eφ AR` — only columns 1–3 are used, by position.
* Full sphere θ 0…180°, φ 0…360°−Δ, any row order, any uniform step (detected from the data).
* Frames: free-space export = antenna local frame (`+Z_CST` = boresight, source frame `CST_LOCAL`); installed export =
  spacecraft body frame as modelled in CST (source frame `SPACECRAFT_BODY_FIXED`, queried without extra rotation).
* `GPSA_*_f1.2` is one CST solve at ≈ 1.2 GHz; its spatial pattern is used as a surrogate at L5 / L2 / L1.
* A file that does not follow these names, sits in the wrong folder, uses an unlisted frequency token or fails
  validation is listed in `output/cal/validation/pattern_inventory.csv` and **not used**. The console, the inventory,
  `output/cal/validation/pattern_diagnostics.json` and the run-summary Appendix give the failing stage, error id,
  line number and θ / φ / sample statistics of every file.
* No file here = `INPUT_MISSING`; nothing is synthesised.

Contract: [`docs/icd/cal_cst_3d.md`](../../docs/icd/cal_cst_3d.md). Configuration: `data/cal_config/`.
