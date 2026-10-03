' SOURCE: cst_geometry.cylinder (actual S/L-band runs)
' VARS: name, component, r, inner, z0, z1, x, y
'@@ Cylinder {{component}}:{{name}}
With Cylinder
 .Reset
 .Name "{{name}}"
 .Component "{{component}}"
 .Material "PEC"
 .OuterRadius "{{r}}"
 .InnerRadius "{{inner}}"
 .Axis "z"
 .Zrange "{{z0}}", "{{z1}}"
 .Xcenter "{{x}}"
 .Ycenter "{{y}}"
 .Segments "0"
 .Create
End With
