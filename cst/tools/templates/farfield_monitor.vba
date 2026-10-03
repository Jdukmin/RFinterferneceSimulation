' SOURCE: cst_com.monitor (actual runs)
' VARS: freq (GHz)
'@@ Farfield {{freq}} GHz
With Monitor
 .Reset
 .Name "farfield (f={{freq}})"
 .Domain "Frequency"
 .FieldType "Farfield"
 .Frequency "{{freq}}"
 .Create
End With
