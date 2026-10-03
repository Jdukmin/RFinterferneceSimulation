' SOURCE: cst_com_common.brick_code (actual smoke test); installed Dipole Antenna^+MWS.mcs
' VARS: name, component, xmin, xmax, ymin, ymax, zmin, zmax
'@@ Brick {{component}}:{{name}}
WCS.ActivateWCS "global"
With Brick
 .Reset
 .Name "{{name}}"
 .Component "{{component}}"
 .Material "PEC"
 .Xrange "{{xmin}}", "{{xmax}}"
 .Yrange "{{ymin}}", "{{ymax}}"
 .Zrange "{{zmin}}", "{{zmax}}"
 .Create
End With
