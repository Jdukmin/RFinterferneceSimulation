# GPS L1/L2/L5 matching candidate

The original accepted antenna and all 22 closed-network projects are unchanged.
Local CST 2026 all-port results are in `validation.json` and `s_matrix.npz`.
This engineering surrogate is not a measured product antenna.

For CST 2024: create an empty Microwave Studio project, run `build_2024.vba`,
check all four 50-ohm discrete ports, nine monitors and mesh, then save as
`GPS_TRIBAND_MATCH65_CST2024.cst`. The build macro does not start a solver.
Actual CST 2024 execution has not been performed on this development PC.

Run all four ports. After solving, combine equal amplitudes with phases
`0, -90, -180, -270` degrees. Calculate acceptance from the full complex
four-port S-matrix, not S11 alone. Do not change the 50-ohm reference to
obtain apparent matching. Export RAW realized gain and complex fields
without clipping. Existing local RAW cuts are separate candidate data;
they have not replaced the RFI baseline or installed patterns.
