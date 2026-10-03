# L5 initial EM validation

Actual CST project: cst/projects/LBAND_GNSS_BUDGET.cst. All four port solves completed successfully; model has 78,400 cells. Mesh is configured to fit Learning Edition; convergence verification is disabled by user instruction.

Geometry: 200 mm exterior diameter, finite 160 mm inner cup, two circular PEC patches (140 and 135 mm diameters), four probes at 35 mm radius, and two concentric exterior grooves. Internal dimensions and ideal probe implementation are confidence C. No product CAD equivalence is claimed.

Fixed intended excitation phases 0/-90/-180/-270 degrees produce dominant IEEE RHCP at boresight. The reported gain is accepted-power RHCP gain, not realized gain or absolute conducted-to-radiated power transfer. Active reflection is diagnostic only.

| Frequency GHz | Coverage MAE dB | Boresight error dB | 60-degree error dB | 90-degree error dB |
|---|---:|---:|---:|---:|
| 1.164 | 2.382 | -3.235 | -0.985 | 3.750 |
| 1.17645 | 0.529 | -0.177 | -0.187 | 1.809 |
| 1.189 | 0.445 | 0.692 | 0.069 | 0.599 |

Overall NOT PASS: low-band coverage/boresight fail; center horizon discrepancy and angular polarization remain unresolved. Boresight purity alone does not establish hemispherical CP: axial ratio at 60 degrees is 12.55/5.78/3.11 dB at low/center/high.

Source CSV is a screening upper/max envelope with 10-degree approximated samples and interpolated 1-degree values, not numeric EM truth. Missing lower envelope bounds are not invented; assumed backlobe values are not hard anchors. Exports under provisional_screening remain explicitly unvalidated conservative scalar envelopes, separate from raw CST complex cuts.

Next controlled radiation-only test: reduce upper parasitic patch diameter 135 to 120 mm, holding all other geometry and feed/resource settings fixed. This tests coupled-mode sensitivity; it is not matching optimization or mesh refinement.
