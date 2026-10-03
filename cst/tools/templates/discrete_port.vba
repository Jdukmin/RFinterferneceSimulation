' SOURCE: cst_geometry.port (actual runs); installed Library/Macros/File/ADS Converter 1.bas
' VARS: number, impedance, x1,y1,z1, x2,y2,z2
'@@ Port {{number}}
With DiscretePort
 .Reset
 .PortNumber "{{number}}"
 .Type "SParameter"
 .Impedance "{{impedance}}"
 .Voltage "1"
 .Current "1"
 .Point1 "{{x1}}", "{{y1}}", "{{z1}}"
 .Point2 "{{x2}}", "{{y2}}", "{{z2}}"
 .UsePickedPoints "False"
 .LocalCoordinates "False"
 .Monitor "False"
 .Create
End With
