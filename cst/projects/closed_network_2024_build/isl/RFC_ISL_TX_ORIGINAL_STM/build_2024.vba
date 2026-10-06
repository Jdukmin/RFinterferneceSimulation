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
    BuildBlock0045
    BuildBlock0046
    BuildBlock0047
    BuildBlock0048
    BuildBlock0049
    BuildBlock0050
    BuildBlock0051
    BuildBlock0052
    BuildBlock0053
    BuildBlock0054
    BuildBlock0055
    BuildBlock0056
    BuildBlock0057
    BuildBlock0058
    BuildBlock0059
    BuildBlock0060
    BuildBlock0061
    BuildBlock0062
    MsgBox "RFC_ISL_TX_ORIGINAL_STM: reconstruction finished. Check geometry, ports, monitors and mesh; save RFC_ISL_TX_ORIGINAL_STM_CST2024.cst. Solver not started."
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
    h = h & "StoreParameterWithDescription ""ground_radius"", ""14.7"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter ground_radius", h
End Sub

Private Sub BuildBlock0002 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""floor_thickness"", ""0.789"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter floor_thickness", h
End Sub

Private Sub BuildBlock0003 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""rim_height"", ""3.154"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter rim_height", h
End Sub

Private Sub BuildBlock0004 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""rim_thickness"", ""0.789"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter rim_thickness", h
End Sub

Private Sub BuildBlock0005 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""patch_diameter"", ""13.089"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter patch_diameter", h
End Sub

Private Sub BuildBlock0006 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""patch_height"", ""1.971"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter patch_height", h
End Sub

Private Sub BuildBlock0007 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""patch_thickness"", ""0.394"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter patch_thickness", h
End Sub

Private Sub BuildBlock0008 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""feed_radius"", ""2.365"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter feed_radius", h
End Sub

Private Sub BuildBlock0009 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""probe_radius"", ""0.315"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter probe_radius", h
End Sub

Private Sub BuildBlock0010 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""feed_gap"", ""0.394"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter feed_gap", h
End Sub

Private Sub BuildBlock0011 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_low"", ""2.2""" & vbCrLf
    AddToHistory "cn_f_low", h
End Sub

Private Sub BuildBlock0012 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_center"", ""2.25""" & vbCrLf
    AddToHistory "cn_f_center", h
End Sub

Private Sub BuildBlock0013 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_high"", ""2.3""" & vbCrLf
    AddToHistory "cn_f_high", h
End Sub

Private Sub BuildBlock0014 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""cn_rebuild_version"", ""2024"", ""RFC_ISL_TX_ORIGINAL_STM_CST2024; native save after checks""" & vbCrLf
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
    h = h & " .FrequencyRange ""2.2"", ""2.3""" & vbCrLf
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
    h = h & " .Name ""ground_floor""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""14.7""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-0.789"", ""0""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "ground_floor", h
End Sub

Private Sub BuildBlock0018 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""rim""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""14.7""" & vbCrLf
    h = h & " .InnerRadius ""13.911""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""3.154""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "rim", h
End Sub

Private Sub BuildBlock0019 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""patch""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""6.5445""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""1.971"", ""2.365""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "patch", h
End Sub

Private Sub BuildBlock0020 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe1""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""0.315""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0.394"", ""2.168""" & vbCrLf
    h = h & " .Xcenter ""2.365""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe1", h
End Sub

Private Sub BuildBlock0021 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe2""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""0.315""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0.394"", ""2.168""" & vbCrLf
    h = h & " .Xcenter ""1.44814483999e-16""" & vbCrLf
    h = h & " .Ycenter ""2.365""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe2", h
End Sub

Private Sub BuildBlock0022 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe3""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""0.315""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0.394"", ""2.168""" & vbCrLf
    h = h & " .Xcenter ""-2.365""" & vbCrLf
    h = h & " .Ycenter ""2.89628967998e-16""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe3", h
End Sub

Private Sub BuildBlock0023 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""probe4""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""0.315""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0.394"", ""2.168""" & vbCrLf
    h = h & " .Xcenter ""-4.34443451998e-16""" & vbCrLf
    h = h & " .Ycenter ""-2.365""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe4", h
End Sub

Private Sub BuildBlock0024 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:ground_floor""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""90"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0025 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:ground_floor""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""90""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0026 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:ground_floor""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""6375"", ""-595"", ""-805""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0027 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:rim""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""90"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0028 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:rim""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""90""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0029 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:rim""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""6375"", ""-595"", ""-805""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0030 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:patch""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""90"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0031 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:patch""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""90""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0032 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:patch""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""6375"", ""-595"", ""-805""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0033 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""90"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0034 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""90""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0035 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""6375"", ""-595"", ""-805""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0036 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe2""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""90"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0037 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe2""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""90""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0038 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe2""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""6375"", ""-595"", ""-805""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0039 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe3""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""90"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0040 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe3""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""90""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0041 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe3""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""6375"", ""-595"", ""-805""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0042 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe4""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""90"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0043 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe4""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""0"", ""0"", ""90""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0044 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:probe4""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""6375"", ""-595"", ""-805""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0045 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""full_PANEL_1""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outline""" & vbCrLf
    h = h & " .Curve ""full_PANEL_1""" & vbCrLf
    h = h & " .Point ""0"", ""783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""6000"", ""783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""6000"", ""-783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""0"", ""-783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""0"", ""783.188191"", ""800""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With CoverCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""PANEL_1""" & vbCrLf
    h = h & " .Component ""FULL_SPACECRAFT""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Curve ""full_PANEL_1:outline""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Full SSOT outer panel PANEL_1", h
End Sub

Private Sub BuildBlock0046 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""full_PANEL_2""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outline""" & vbCrLf
    h = h & " .Curve ""full_PANEL_2""" & vbCrLf
    h = h & " .Point ""0"", ""-783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""6000"", ""-783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""6000"", ""-1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""0"", ""-1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""0"", ""-783.188191"", ""800""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With CoverCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""PANEL_2""" & vbCrLf
    h = h & " .Component ""FULL_SPACECRAFT""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Curve ""full_PANEL_2:outline""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Full SSOT outer panel PANEL_2", h
End Sub

Private Sub BuildBlock0047 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""full_PANEL_3""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outline""" & vbCrLf
    h = h & " .Curve ""full_PANEL_3""" & vbCrLf
    h = h & " .Point ""0"", ""-1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""-1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""-301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""0"", ""-301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""0"", ""-1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With CoverCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""PANEL_3""" & vbCrLf
    h = h & " .Component ""FULL_SPACECRAFT""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Curve ""full_PANEL_3:outline""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Full SSOT outer panel PANEL_3", h
End Sub

Private Sub BuildBlock0048 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""full_PANEL_4""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outline""" & vbCrLf
    h = h & " .Curve ""full_PANEL_4""" & vbCrLf
    h = h & " .Point ""0"", ""-301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""-301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""0"", ""301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""0"", ""-301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With CoverCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""PANEL_4""" & vbCrLf
    h = h & " .Component ""FULL_SPACECRAFT""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Curve ""full_PANEL_4:outline""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Full SSOT outer panel PANEL_4", h
End Sub

Private Sub BuildBlock0049 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""full_PANEL_5""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outline""" & vbCrLf
    h = h & " .Curve ""full_PANEL_5""" & vbCrLf
    h = h & " .Point ""0"", ""301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""0"", ""1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""0"", ""301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With CoverCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""PANEL_5""" & vbCrLf
    h = h & " .Component ""FULL_SPACECRAFT""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Curve ""full_PANEL_5:outline""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Full SSOT outer panel PANEL_5", h
End Sub

Private Sub BuildBlock0050 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""full_PANEL_6""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outline""" & vbCrLf
    h = h & " .Curve ""full_PANEL_6""" & vbCrLf
    h = h & " .Point ""0"", ""1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""0"", ""783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""0"", ""1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With CoverCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""PANEL_6""" & vbCrLf
    h = h & " .Component ""FULL_SPACECRAFT""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Curve ""full_PANEL_6:outline""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Full SSOT outer panel PANEL_6", h
End Sub

Private Sub BuildBlock0051 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""full_PANEL_7""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outline""" & vbCrLf
    h = h & " .Curve ""full_PANEL_7""" & vbCrLf
    h = h & " .Point ""6000"", ""-783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""6000"", ""-1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""-301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""6000"", ""783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""6000"", ""-783.188191"", ""800""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With CoverCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""PANEL_7""" & vbCrLf
    h = h & " .Component ""FULL_SPACECRAFT""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Curve ""full_PANEL_7:outline""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Full SSOT outer panel PANEL_7", h
End Sub

Private Sub BuildBlock0052 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""full_PANEL_8""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outline""" & vbCrLf
    h = h & " .Curve ""full_PANEL_8""" & vbCrLf
    h = h & " .Point ""0"", ""-783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""0"", ""-1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""0"", ""-301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""0"", ""301.226227"", ""-1078.26087""" & vbCrLf
    h = h & " .Point ""0"", ""1084.414419"", ""278.26087""" & vbCrLf
    h = h & " .Point ""0"", ""783.188191"", ""800""" & vbCrLf
    h = h & " .Point ""0"", ""-783.188191"", ""800""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With CoverCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""PANEL_8""" & vbCrLf
    h = h & " .Component ""FULL_SPACECRAFT""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Curve ""full_PANEL_8:outline""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Full SSOT outer panel PANEL_8", h
End Sub

Private Sub BuildBlock0053 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""1""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""6375"", ""-592.635"", ""-805""" & vbCrLf
    h = h & " .Point2 ""6375.394"", ""-592.635"", ""-805""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 1", h
End Sub

Private Sub BuildBlock0054 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""2""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""6375"", ""-595"", ""-802.635""" & vbCrLf
    h = h & " .Point2 ""6375.394"", ""-595"", ""-802.635""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 2", h
End Sub

Private Sub BuildBlock0055 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""3""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""6375"", ""-597.365"", ""-805""" & vbCrLf
    h = h & " .Point2 ""6375.394"", ""-597.365"", ""-805""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 3", h
End Sub

Private Sub BuildBlock0056 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""4""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""6375"", ""-595"", ""-807.365""" & vbCrLf
    h = h & " .Point2 ""6375.394"", ""-595"", ""-807.365""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 4", h
End Sub

Private Sub BuildBlock0057 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=2.2)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""2.2""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 2.2", h
End Sub

Private Sub BuildBlock0058 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=2.25)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""2.25""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 2.25", h
End Sub

Private Sub BuildBlock0059 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=2.3)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""2.3""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 2.3", h
End Sub

Private Sub BuildBlock0060 ()
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

Private Sub BuildBlock0061 ()
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

Private Sub BuildBlock0062 ()
    Dim h As String
    h = ""
    h = h & "ResetViewToStructure" & vbCrLf
    h = h & "Plot.ZoomToStructure" & vbCrLf
    AddToHistory "Structure view", h
End Sub

