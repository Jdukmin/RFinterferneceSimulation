# data/cal — CST full-sphere 3D Realized Gain drop-in folder (CAL path)

Copy the owner CST Studio ASCII far-field exports here **unchanged** and run, from the repository root:

```bash
octave-cli --no-gui --eval "main('--cal')"      # or, in MATLAB / Octave: main('--cal')
```

```
data/cal/
├─ gps/  GPS_ORIGINAL_f1.2.txt  GPS_GPSA1_f1.2.txt  GPS_GPSA2_f1.2.txt
├─ isl/  RFC_ISL_f1.1764.txt ... RFC_ISL_f10.6.txt            (8 files)
├─ kaa/  RFC_KAA_f1.1764.txt ... RFC_KAA_f10.6.txt            (8 files)
└─ sba/  RFC_SBA_f1.1764.txt ... RFC_SBA_f10.6.txt            (9 files, incl. f2.06)
         RFC_SBA_NADIR_f2.06.txt  RFC_SBA_NADIR_f2.25.txt
         RFC_SBA_ZENITH_f2.06.txt RFC_SBA_ZENITH_f2.25.txt
```

* Format: whitespace-delimited, header + separator lines (their text is ignored), then
  `Theta Phi RealizedGain(dBi) |Eθ| ∠Eθ |Eφ| ∠Eφ AR` — only columns 1–3 are used, by position.
* Full sphere θ 0…180°, φ 0…360°−Δ, any row order, any uniform step (detected from the data).
* Frames: free-space `+Z_CST` = boresight; installed `+Z_CST` = mounting-face outward normal.
* `GPS_*_f1.2` is one spatial pattern shared by L5 / L2 / L1 (1.2 is not a frequency).
* A file that does not follow these names, sits in the wrong folder, uses an unlisted frequency token or fails
  validation is listed in `output/cal/validation/pattern_inventory.csv` and **not used**.
* No file here = `INPUT_MISSING`; nothing is synthesised.

Contract: [`docs/icd/cal_cst_3d.md`](../../docs/icd/cal_cst_3d.md). Configuration: `data/cal_config/`.
