' SOURCE: generate_lband_gnss.py (actual runs). Mesh/MeshSettings keys from installed
'         ADS/Sonnet converter and demo macros. RESOURCE SETTING ONLY - no convergence claim.
' VARS: steps (cells per wavelength), ratio
'@@ Thin PEC plate mesh resource setting
With Mesh
 .MergeThinPECLayerFixpoints "True"
 .RatioLimit "{{ratio}}"
End With
'@@ Learning Edition global mesh resource budget
With MeshSettings
 .SetMeshType "Hex"
 .Set "StepsPerWaveNear", "{{steps}}"
 .Set "StepsPerWaveFar", "{{steps}}"
 .Set "StepsPerBoxNear", "{{steps}}"
 .Set "StepsPerBoxFar", "{{steps}}"
End With
