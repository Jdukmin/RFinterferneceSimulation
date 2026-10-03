' SOURCE: cst_sband_helix_com.configure_frequency (actual Learning Edition runs);
'         installed Library/Macros/Construct/Demo Examples/Dipole Antenna^+MWS.mcs
' VARS: fmin, fmax (GHz), accuracy (dB, e.g. -40)
'@@ Units mm/GHz/ns
WCS.ActivateWCS "global"
With Units
 .Geometry "mm"
 .Frequency "GHz"
 .Time "ns"
End With
'@@ Time domain solver and frequency band
ChangeSolverType "HF Time Domain"
With Solver
 .FrequencyRange "{{fmin}}", "{{fmax}}"
 .CalculationType "TD-S"
 .StimulationPort "All"
 .StimulationMode "All"
 .SteadyStateLimit "{{accuracy}}"
End With
