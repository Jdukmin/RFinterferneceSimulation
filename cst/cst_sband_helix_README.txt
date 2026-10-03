CST S-band helix surrogate — quick use

Recommended: Python version
---------------------------
1. Keep the empty CST project open.
2. Home -> Macros / Python -> Run Script (exact ribbon wording may vary).
3. Select cst_sband_helix_surrogate.py.
   If CST only lists scripts from its script folder, copy it to:
   <CST install>\Library\Python\scripts
   then click Python -> Update Menu.
4. The script creates:
   - 110 x 110 x 2 mm PEC ground
   - 3-turn polygonal axial-mode helix
   - 50-ohm Discrete Port #1
   - 2.20–2.30 GHz range
   - open(add space) boundaries
   - 2.25 GHz farfield monitor
5. Inspect Port 1 before solving.
6. Run the Time Domain solver manually.

Alternative: VBA macro
----------------------
Home -> Macros -> Import Macro and select:
cst_sband_helix_surrogate.mcr

Purpose / limitations
---------------------
This is a lightweight training surrogate for the CST workflow.
It is NOT a geometry reconstruction of the Beyond Gravity/RUAG SBA1 or SBA4.
The RFinterferenceSimulation repository's S-band data are datasheet-derived
gain-envelope cuts, not full complex Etheta/Ephi measured far-field data.

Nominal geometry at 2.25 GHz
----------------------------
lambda0     ~= 133.24 mm
helix R     ~= 21.21 mm  (circumference ~= 1 lambda)
pitch       ~= 30.65 mm  (~0.23 lambda)
turns       = 3
wire radius = 1.25 mm
feed gap    = 2 mm
