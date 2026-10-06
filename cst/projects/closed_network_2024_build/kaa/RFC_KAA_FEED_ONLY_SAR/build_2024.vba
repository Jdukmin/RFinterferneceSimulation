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
    MsgBox "RFC_KAA_FEED_ONLY_SAR: reconstruction finished. Check geometry, ports, monitors and mesh; save RFC_KAA_FEED_ONLY_SAR_CST2024.cst. Solver not started."
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
    h = h & "StoreParameterWithDescription ""wg_radius"", ""4.4"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter wg_radius", h
End Sub

Private Sub BuildBlock0002 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""wall"", ""1"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter wall", h
End Sub

Private Sub BuildBlock0003 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""wg_length"", ""20"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter wg_length", h
End Sub

Private Sub BuildBlock0004 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""probe_z"", ""4.4"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter probe_z", h
End Sub

Private Sub BuildBlock0005 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""probe_radius"", ""0.5"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter probe_radius", h
End Sub

Private Sub BuildBlock0006 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""probe_length"", ""2.2"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter probe_length", h
End Sub

Private Sub BuildBlock0007 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""feed_gap"", ""0.5"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter feed_gap", h
End Sub

Private Sub BuildBlock0008 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""aperture_radius"", ""4.4"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter aperture_radius", h
End Sub

Private Sub BuildBlock0009 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""flare_length"", ""0"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter flare_length", h
End Sub

Private Sub BuildBlock0010 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""flare_steps"", ""0"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter flare_steps", h
End Sub

Private Sub BuildBlock0011 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_low"", ""8.9""" & vbCrLf
    AddToHistory "cn_f_low", h
End Sub

Private Sub BuildBlock0012 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_center"", ""9.65""" & vbCrLf
    AddToHistory "cn_f_center", h
End Sub

Private Sub BuildBlock0013 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_high"", ""10.4""" & vbCrLf
    AddToHistory "cn_f_high", h
End Sub

Private Sub BuildBlock0014 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""cn_rebuild_version"", ""2024"", ""RFC_KAA_FEED_ONLY_SAR_CST2024; native save after checks""" & vbCrLf
    AddToHistory "Case identity", h
End Sub

Private Sub BuildBlock0015 ()
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

Private Sub BuildBlock0016 ()
    Dim h As String
    h = ""
    h = h & "ChangeSolverType ""HF Time Domain""" & vbCrLf
    h = h & "With Solver" & vbCrLf
    h = h & " .FrequencyRange ""8.9"", ""10.4""" & vbCrLf
    h = h & " .CalculationType ""TD-S""" & vbCrLf
    h = h & " .StimulationPort ""All""" & vbCrLf
    h = h & " .StimulationMode ""All""" & vbCrLf
    h = h & " .SteadyStateLimit ""-40""" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Initial solver configuration; manual resource review required", h
End Sub

Private Sub BuildBlock0017 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""back_short""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""5.4""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-1"", ""0""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "back_short", h
End Sub

Private Sub BuildBlock0018 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""waveguide""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""5.4""" & vbCrLf
    h = h & " .InnerRadius ""4.4""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""20""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "waveguide", h
End Sub

Private Sub BuildBlock0019 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe1""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""0.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""2.2""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe1""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""90"", ""0""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe1""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""180""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe1""" & vbCrLf
    h = h & " .Vector ""3.9"", ""0"", ""4.4""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe1", h
End Sub

Private Sub BuildBlock0020 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe2""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""0.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""2.2""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe2""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""90"", ""0""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe2""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""-90""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe2""" & vbCrLf
    h = h & " .Vector ""2.38806125834e-16"", ""3.9"", ""4.4""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe2", h
End Sub

Private Sub BuildBlock0021 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe3""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""0.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""2.2""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe3""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""90"", ""0""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe3""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""-7.01670929853e-15""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe3""" & vbCrLf
    h = h & " .Vector ""-3.9"", ""4.77612251667e-16"", ""4.4""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe3", h
End Sub

Private Sub BuildBlock0022 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe4""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""0.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""2.2""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe4""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""90"", ""0""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe4""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""90""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe4""" & vbCrLf
    h = h & " .Vector ""-7.16418377501e-16"", ""-3.9"", ""4.4""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe4", h
End Sub

Private Sub BuildBlock0023 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""1""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""4.4"", ""0"", ""4.4""" & vbCrLf
    h = h & " .Point2 ""3.9"", ""0"", ""4.4""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 1", h
End Sub

Private Sub BuildBlock0024 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""2""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""2.69422295812e-16"", ""4.4"", ""4.4""" & vbCrLf
    h = h & " .Point2 ""2.38806125834e-16"", ""3.9"", ""4.4""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 2", h
End Sub

Private Sub BuildBlock0025 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""3""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""-4.4"", ""5.38844591625e-16"", ""4.4""" & vbCrLf
    h = h & " .Point2 ""-3.9"", ""4.77612251667e-16"", ""4.4""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 3", h
End Sub

Private Sub BuildBlock0026 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""4""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""-8.08266887437e-16"", ""-4.4"", ""4.4""" & vbCrLf
    h = h & " .Point2 ""-7.16418377501e-16"", ""-3.9"", ""4.4""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 4", h
End Sub

Private Sub BuildBlock0027 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=8.9)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""8.9""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 8.9", h
End Sub

Private Sub BuildBlock0028 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=9.65)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""9.65""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 9.65", h
End Sub

Private Sub BuildBlock0029 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=10.4)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""10.4""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 10.4", h
End Sub

Private Sub BuildBlock0030 ()
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

Private Sub BuildBlock0031 ()
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

Private Sub BuildBlock0032 ()
    Dim h As String
    h = ""
    h = h & "ResetViewToStructure" & vbCrLf
    h = h & "Plot.ZoomToStructure" & vbCrLf
    AddToHistory "Structure view", h
End Sub

