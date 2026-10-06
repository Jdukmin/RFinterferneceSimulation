' GEOMETRY ONLY; NO PORTS, NO MESH, NO SOLVER
'@@ PANEL_1
WCS.ActivateWCS "global"
Curve.NewCurve "outline_PANEL_1"
With Polygon3D
 .Reset
 .Name "outline"
 .Curve "outline_PANEL_1"
 .Point "0", "783.188191", "800"
 .Point "0", "-783.188191", "800"
 .Point "6000", "-783.188191", "800"
 .Point "6000", "783.188191", "800"
 .Point "0", "783.188191", "800"
 .Create
End With
With CoverCurve
 .Reset
 .Name "PANEL_1"
 .Component "SPACECRAFT_PEC"
 .Material "PEC"
 .Curve "outline_PANEL_1:outline"
 .Create
End With

'@@ PANEL_2
WCS.ActivateWCS "global"
Curve.NewCurve "outline_PANEL_2"
With Polygon3D
 .Reset
 .Name "outline"
 .Curve "outline_PANEL_2"
 .Point "0", "-783.188191", "800"
 .Point "0", "-1084.414419", "278.26087"
 .Point "6000", "-1084.414419", "278.26087"
 .Point "6000", "-783.188191", "800"
 .Point "0", "-783.188191", "800"
 .Create
End With
With CoverCurve
 .Reset
 .Name "PANEL_2"
 .Component "SPACECRAFT_PEC"
 .Material "PEC"
 .Curve "outline_PANEL_2:outline"
 .Create
End With

'@@ PANEL_3
WCS.ActivateWCS "global"
Curve.NewCurve "outline_PANEL_3"
With Polygon3D
 .Reset
 .Name "outline"
 .Curve "outline_PANEL_3"
 .Point "0", "-1084.414419", "278.26087"
 .Point "0", "-301.226227", "-1078.26087"
 .Point "6000", "-301.226227", "-1078.26087"
 .Point "6000", "-1084.414419", "278.26087"
 .Point "0", "-1084.414419", "278.26087"
 .Create
End With
With CoverCurve
 .Reset
 .Name "PANEL_3"
 .Component "SPACECRAFT_PEC"
 .Material "PEC"
 .Curve "outline_PANEL_3:outline"
 .Create
End With

'@@ PANEL_4
WCS.ActivateWCS "global"
Curve.NewCurve "outline_PANEL_4"
With Polygon3D
 .Reset
 .Name "outline"
 .Curve "outline_PANEL_4"
 .Point "0", "-301.226227", "-1078.26087"
 .Point "0", "301.226227", "-1078.26087"
 .Point "6000", "301.226227", "-1078.26087"
 .Point "6000", "-301.226227", "-1078.26087"
 .Point "0", "-301.226227", "-1078.26087"
 .Create
End With
With CoverCurve
 .Reset
 .Name "PANEL_4"
 .Component "SPACECRAFT_PEC"
 .Material "PEC"
 .Curve "outline_PANEL_4:outline"
 .Create
End With

'@@ PANEL_5
WCS.ActivateWCS "global"
Curve.NewCurve "outline_PANEL_5"
With Polygon3D
 .Reset
 .Name "outline"
 .Curve "outline_PANEL_5"
 .Point "0", "301.226227", "-1078.26087"
 .Point "0", "1084.414419", "278.26087"
 .Point "6000", "1084.414419", "278.26087"
 .Point "6000", "301.226227", "-1078.26087"
 .Point "0", "301.226227", "-1078.26087"
 .Create
End With
With CoverCurve
 .Reset
 .Name "PANEL_5"
 .Component "SPACECRAFT_PEC"
 .Material "PEC"
 .Curve "outline_PANEL_5:outline"
 .Create
End With

'@@ PANEL_6
WCS.ActivateWCS "global"
Curve.NewCurve "outline_PANEL_6"
With Polygon3D
 .Reset
 .Name "outline"
 .Curve "outline_PANEL_6"
 .Point "0", "1084.414419", "278.26087"
 .Point "0", "783.188191", "800"
 .Point "6000", "783.188191", "800"
 .Point "6000", "1084.414419", "278.26087"
 .Point "0", "1084.414419", "278.26087"
 .Create
End With
With CoverCurve
 .Reset
 .Name "PANEL_6"
 .Component "SPACECRAFT_PEC"
 .Material "PEC"
 .Curve "outline_PANEL_6:outline"
 .Create
End With

'@@ PANEL_7
WCS.ActivateWCS "global"
Curve.NewCurve "outline_PANEL_7"
With Polygon3D
 .Reset
 .Name "outline"
 .Curve "outline_PANEL_7"
 .Point "6000", "-783.188191", "800"
 .Point "6000", "-1084.414419", "278.26087"
 .Point "6000", "-301.226227", "-1078.26087"
 .Point "6000", "301.226227", "-1078.26087"
 .Point "6000", "1084.414419", "278.26087"
 .Point "6000", "783.188191", "800"
 .Point "6000", "-783.188191", "800"
 .Create
End With
With CoverCurve
 .Reset
 .Name "PANEL_7"
 .Component "SPACECRAFT_PEC"
 .Material "PEC"
 .Curve "outline_PANEL_7:outline"
 .Create
End With

'@@ PANEL_8
WCS.ActivateWCS "global"
Curve.NewCurve "outline_PANEL_8"
With Polygon3D
 .Reset
 .Name "outline"
 .Curve "outline_PANEL_8"
 .Point "0", "783.188191", "800"
 .Point "0", "1084.414419", "278.26087"
 .Point "0", "301.226227", "-1078.26087"
 .Point "0", "-301.226227", "-1078.26087"
 .Point "0", "-1084.414419", "278.26087"
 .Point "0", "-783.188191", "800"
 .Point "0", "783.188191", "800"
 .Create
End With
With CoverCurve
 .Reset
 .Name "PANEL_8"
 .Component "SPACECRAFT_PEC"
 .Material "PEC"
 .Curve "outline_PANEL_8:outline"
 .Create
End With

'@@ KAA_1
WCS.ActivateWCS "global"
With AnalyticalFace
 .Reset
 .Name "equivalent_paraboloid"
 .Component "KAA_1"
 .Material "PEC"
 .LawX "5965+(1)*(u*cos(v))+(0)*(u*sin(v))+(0)*(u*u/(4*151.11125807))"
 .LawY "-1100+(0)*(u*cos(v))+(1)*(u*sin(v))+(0)*(u*u/(4*151.11125807))"
 .LawZ "850+(0)*(u*cos(v))+(0)*(u*sin(v))+(1)*(u*u/(4*151.11125807))"
 .ParameterRangeU "0", "110"
 .ParameterRangeV "0", "2*pi"
 .Create
End With

'@@ KAA_2
WCS.ActivateWCS "global"
With AnalyticalFace
 .Reset
 .Name "equivalent_paraboloid"
 .Component "KAA_2"
 .Material "PEC"
 .LawX "5965+(1)*(u*cos(v))+(0)*(u*sin(v))+(0)*(u*u/(4*151.11125807))"
 .LawY "1285+(0)*(u*cos(v))+(-0.49999999990666)*(u*sin(v))+(0.86602540383833)*(u*u/(4*151.11125807))"
 .LawZ "530+(0)*(u*cos(v))+(-0.86602540383833)*(u*sin(v))+(-0.49999999990666)*(u*u/(4*151.11125807))"
 .ParameterRangeU "0", "110"
 .ParameterRangeV "0", "2*pi"
 .Create
End With