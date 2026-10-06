' Numeric reconstruction for CST Studio Suite 2024. No Python/runtime or binary import.
' Built-in PEC is used. Validate on CST 2024 before native Save As.
Option Explicit
Sub Main ()
    If Solid.GetNumberOfShapes > 0 Then
        MsgBox "Use a NEW empty Microwave Studio project."
        Exit Sub
    End If
    BuildBlock0000
    BuildBlock0001
    BuildBlock0002
    BuildBlock0003
    BuildBlock0004
    BuildBlock0005
    BuildBlock0006
    BuildBlock0007
    BuildBlock0008
    BuildBlock0009
    BuildBlock0010
    BuildBlock0011
    BuildBlock0012
    BuildBlock0013
    BuildBlock0014
    BuildBlock0015
    BuildBlock0016
    BuildBlock0017
    BuildBlock0018
    BuildBlock0019
    BuildBlock0020
    BuildBlock0021
    BuildBlock0022
    BuildBlock0023
    BuildBlock0024
    BuildBlock0025
    BuildBlock0026
    BuildBlock0027
    BuildBlock0028
    BuildBlock0029
    BuildBlock0030
    BuildBlock0031
    BuildBlock0032
    BuildBlock0033
    BuildBlock0034
    BuildBlock0035
    BuildBlock0036
    BuildBlock0037
    BuildBlock0038
    BuildBlock0039
    BuildBlock0040
    BuildBlock0041
    BuildBlock0042
    BuildBlock0043
    BuildBlock0044
    MsgBox "RFC_GPS_L1_ORIGINAL: reconstruction finished. Check geometry, ports, monitors and mesh; save RFC_GPS_L1_ORIGINAL_CST2024.cst. Solver not started."
End Sub

Private Sub BuildBlock0000 ()
    Dim h As String
    h = ""
    h = h & "WCS.ActivateWCS ""global""" & vbCrLf
    h = h & "With Units" & vbCrLf
    h = h & " .Geometry ""mm""" & vbCrLf
    h = h & " .Frequency ""GHz""" & vbCrLf
    h = h & " .Time ""ns""" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Units and global coordinates", h
End Sub

Private Sub BuildBlock0001 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""outer_diameter"", ""200"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter outer_diameter", h
End Sub

Private Sub BuildBlock0002 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""maximum_overall_height"", ""87"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter maximum_overall_height", h
End Sub

Private Sub BuildBlock0003 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""cup_inner_diameter"", ""160"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter cup_inner_diameter", h
End Sub

Private Sub BuildBlock0004 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""cup_wall_thickness"", ""2"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter cup_wall_thickness", h
End Sub

Private Sub BuildBlock0005 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""cup_depth"", ""45"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter cup_depth", h
End Sub

Private Sub BuildBlock0006 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""lower_patch_diameter"", ""140"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter lower_patch_diameter", h
End Sub

Private Sub BuildBlock0007 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""upper_patch_diameter"", ""123"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter upper_patch_diameter", h
End Sub

Private Sub BuildBlock0008 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""patch_to_ground_height"", ""12"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter patch_to_ground_height", h
End Sub

Private Sub BuildBlock0009 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""patch_spacing"", ""12"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter patch_spacing", h
End Sub

Private Sub BuildBlock0010 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""patch_thickness"", ""1"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter patch_thickness", h
End Sub

Private Sub BuildBlock0011 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""feed_radius"", ""35"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter feed_radius", h
End Sub

Private Sub BuildBlock0012 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""feed_probe_radius"", ""1.5"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter feed_probe_radius", h
End Sub

Private Sub BuildBlock0013 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""choke1_inner_radius"", ""82"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter choke1_inner_radius", h
End Sub

Private Sub BuildBlock0014 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""choke1_outer_radius"", ""91"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter choke1_outer_radius", h
End Sub

Private Sub BuildBlock0015 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""choke2_inner_radius"", ""93"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter choke2_inner_radius", h
End Sub

Private Sub BuildBlock0016 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""choke2_outer_radius"", ""98"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter choke2_outer_radius", h
End Sub

Private Sub BuildBlock0017 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""choke_depth"", ""63.7"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter choke_depth", h
End Sub

Private Sub BuildBlock0018 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_low"", ""1.563""" & vbCrLf
    AddToHistory "cn_f_low", h
End Sub

Private Sub BuildBlock0019 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_center"", ""1.57542""" & vbCrLf
    AddToHistory "cn_f_center", h
End Sub

Private Sub BuildBlock0020 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_high"", ""1.588""" & vbCrLf
    AddToHistory "cn_f_high", h
End Sub

Private Sub BuildBlock0021 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""cn_rebuild_version"", ""2024"", ""RFC_GPS_L1_ORIGINAL_CST2024; native save after checks""" & vbCrLf
    AddToHistory "Case identity", h
End Sub

Private Sub BuildBlock0022 ()
    Dim h As String
    h = ""
    h = h & "With Background" & vbCrLf
    h = h & " .Type ""Normal""" & vbCrLf
    h = h & " .Epsilon ""1""" & vbCrLf
    h = h & " .Mu ""1""" & vbCrLf
    h = h & " .XminSpace ""0""" & vbCrLf
    h = h & " .XmaxSpace ""0""" & vbCrLf
    h = h & " .YminSpace ""0""" & vbCrLf
    h = h & " .YmaxSpace ""0""" & vbCrLf
    h = h & " .ZminSpace ""0""" & vbCrLf
    h = h & " .ZmaxSpace ""0""" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Boundary" & vbCrLf
    h = h & " .Xmin ""expanded open""" & vbCrLf
    h = h & " .Xmax ""expanded open""" & vbCrLf
    h = h & " .Ymin ""expanded open""" & vbCrLf
    h = h & " .Ymax ""expanded open""" & vbCrLf
    h = h & " .Zmin ""expanded open""" & vbCrLf
    h = h & " .Zmax ""expanded open""" & vbCrLf
    h = h & " .Xsymmetry ""none""" & vbCrLf
    h = h & " .Ysymmetry ""none""" & vbCrLf
    h = h & " .Zsymmetry ""none""" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "Boundary.MinimumDistanceReferenceFrequencyType ""CenterNMonitors""" & vbCrLf
    AddToHistory "Vacuum and open boundaries", h
End Sub

Private Sub BuildBlock0023 ()
    Dim h As String
    h = ""
    h = h & "ChangeSolverType ""HF Time Domain""" & vbCrLf
    h = h & "With Solver" & vbCrLf
    h = h & " .FrequencyRange ""1.563"", ""1.588""" & vbCrLf
    h = h & " .CalculationType ""TD-S""" & vbCrLf
    h = h & " .StimulationPort ""All""" & vbCrLf
    h = h & " .StimulationMode ""All""" & vbCrLf
    h = h & " .SteadyStateLimit ""-40""" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Initial solver configuration; manual resource review required", h
End Sub

Private Sub BuildBlock0024 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""cup_floor""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""80""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-3"", ""0""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "cup_floor", h
End Sub

Private Sub BuildBlock0025 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""cup_wall""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""82""" & vbCrLf
    h = h & " .InnerRadius ""80""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-18.7"", ""45""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "cup_wall", h
End Sub

Private Sub BuildBlock0026 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""choke_floor""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""100""" & vbCrLf
    h = h & " .InnerRadius ""82""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-21.7"", ""-18.7""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "choke_floor", h
End Sub

Private Sub BuildBlock0027 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""choke_separator""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""93""" & vbCrLf
    h = h & " .InnerRadius ""91""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-18.7"", ""45""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "choke_separator", h
End Sub

Private Sub BuildBlock0028 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outer_wall""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""100""" & vbCrLf
    h = h & " .InnerRadius ""98""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-18.7"", ""45""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "outer_wall", h
End Sub

Private Sub BuildBlock0029 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""lower_patch""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""70""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""12"", ""13""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "lower_patch", h
End Sub

Private Sub BuildBlock0030 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""upper_patch""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""61.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""25"", ""26""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "upper_patch", h
End Sub

Private Sub BuildBlock0031 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe1""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""1.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""2"", ""13""" & vbCrLf
    h = h & " .Xcenter ""35""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe1", h
End Sub

Private Sub BuildBlock0032 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe2""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""1.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""2"", ""13""" & vbCrLf
    h = h & " .Xcenter ""2.14313189851e-15""" & vbCrLf
    h = h & " .Ycenter ""35""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe2", h
End Sub

Private Sub BuildBlock0033 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe3""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""1.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""2"", ""13""" & vbCrLf
    h = h & " .Xcenter ""-35""" & vbCrLf
    h = h & " .Ycenter ""4.28626379702e-15""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe3", h
End Sub

Private Sub BuildBlock0034 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe4""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""1.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""2"", ""13""" & vbCrLf
    h = h & " .Xcenter ""-6.42939569552e-15""" & vbCrLf
    h = h & " .Ycenter ""-35""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe4", h
End Sub

Private Sub BuildBlock0035 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""1""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""35"", ""0"", ""0""" & vbCrLf
    h = h & " .Point2 ""35"", ""0"", ""2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 1", h
End Sub

Private Sub BuildBlock0036 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""2""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""2.14313189851e-15"", ""35"", ""0""" & vbCrLf
    h = h & " .Point2 ""2.14313189851e-15"", ""35"", ""2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 2", h
End Sub

Private Sub BuildBlock0037 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""3""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""-35"", ""4.28626379702e-15"", ""0""" & vbCrLf
    h = h & " .Point2 ""-35"", ""4.28626379702e-15"", ""2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 3", h
End Sub

Private Sub BuildBlock0038 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""4""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""-6.42939569552e-15"", ""-35"", ""0""" & vbCrLf
    h = h & " .Point2 ""-6.42939569552e-15"", ""-35"", ""2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 4", h
End Sub

Private Sub BuildBlock0039 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=1.563)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""1.563""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 1.563", h
End Sub

Private Sub BuildBlock0040 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=1.57542)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""1.57542""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 1.57542", h
End Sub

Private Sub BuildBlock0041 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=1.588)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""1.588""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 1.588", h
End Sub

Private Sub BuildBlock0042 ()
    Dim h As String
    h = ""
    h = h & "With Mesh" & vbCrLf
    h = h & " .MergeThinPECLayerFixpoints ""True""" & vbCrLf
    h = h & " .RatioLimit ""5""" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With MeshSettings" & vbCrLf
    h = h & " .SetMeshType ""Hex""" & vbCrLf
    h = h & " .Set ""StepsPerWaveNear"", ""8""" & vbCrLf
    h = h & " .Set ""StepsPerWaveFar"", ""8""" & vbCrLf
    h = h & " .Set ""StepsPerBoxNear"", ""8""" & vbCrLf
    h = h & " .Set ""StepsPerBoxFar"", ""8""" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Initial mesh; resource baseline, not convergence", h
End Sub

Private Sub BuildBlock0043 ()
    Dim h As String
    h = ""
    h = h & "With CombineResults" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .SetMonitorType ""frequency""" & vbCrLf
    h = h & " .FarfieldsOnly ""True""" & vbCrLf
    h = h & " .EnableAutomaticLabeling ""False""" & vbCrLf
    h = h & " .SetLabel ""CN_DEFAULT_GROUP""" & vbCrLf
    h = h & " .SetPortModeValues ""1"", ""1"", ""1"", ""0""" & vbCrLf
    h = h & " .SetPortModeValues ""2"", ""1"", ""1"", ""-90""" & vbCrLf
    h = h & " .SetPortModeValues ""3"", ""1"", ""1"", ""-180""" & vbCrLf
    h = h & " .SetPortModeValues ""4"", ""1"", ""1"", ""-270""" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "CP field-combination definition; no result calculation", h
End Sub

Private Sub BuildBlock0044 ()
    Dim h As String
    h = ""
    h = h & "ResetViewToStructure" & vbCrLf
    h = h & "Plot.ZoomToStructure" & vbCrLf
    AddToHistory "Structure view", h
End Sub

