# Simulation review — 2026-10-03

Model: SURROGATE_TRAINING_MODEL. Existing user-run results inspected; solver was not rerun and geometry was not changed.

## Completion

Model.log confirms successful steady-state termination at 18:55:45 KST. Total simulation time: 20 s; 41,472 cells; steady-state accuracy limit: -30 dB.

One mesh warning: 117 edges represented in staircase mode and filled with PEC; 70 edges partially filled with PEC. Mesh convergence remains unverified.

## Farfield at 2.25 GHz

CST GUI, Abs / Directivity:

- Maximum directivity: 10.57 dBi.
- Radiation efficiency: -0.0004337 dB (approximately 99.99%; PEC model).
- Total efficiency: -2.426 dB (approximately 57.2%).
- Inferred maximum realized gain: approximately 8.14 dBi (directivity + total efficiency in dB); not independently read from the realized-gain plot.
- Main lobe points approximately along +Z.
- Phi=90 degree cut, 1 degree plot sampling: peak 10.6 dBi, main-lobe direction theta=2 degrees, 3 dB angular width 51.8 degrees, sidelobe level -13.3 dB. These cut metrics are not full-sphere sidelobe metrics.
- Axial-ratio cut was viewed, but exact boresight value and handedness were not extracted. Circular-polarization qualification remains open.

## S11

COM ResultTree readback, returned result ID 3D:RunID:0, 1001 complex samples:

- At 2.25 GHz: -3.6868576335 dB.
- Over 2.20–2.30 GHz: minimum -4.3107430130 dB, maximum -3.5100778298 dB.
- Reflected power at 2.25 GHz: 42.7872%; VSWR: 4.78234.

The entire simulated band fails a -10 dB S11 criterion. The efficiency loss is consistent with port mismatch, while the PEC radiation efficiency is nearly unity. Pattern directionality is present, but feed matching, polarization, and mesh convergence require further work before using this as a validated antenna source.
