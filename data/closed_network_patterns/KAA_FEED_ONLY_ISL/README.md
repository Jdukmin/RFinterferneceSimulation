# KAA_FEED_ONLY_ISL

RAW CST exports only; do not clip/floor.

Expected files (GHz, six decimals):

- f10.550000_XZ.csv
- f10.550000_YZ.csv
- f10.600000_XZ.csv
- f10.600000_YZ.csv
- f10.650000_XZ.csv
- f10.650000_YZ.csv

Optional: corresponding _3D.csv. Preserve raw_s_matrix.npz, solver/convergence logs and provenance.json. No solved results are supplied by project preparation. Missing/failed data must never be replaced by zero or another pattern.
