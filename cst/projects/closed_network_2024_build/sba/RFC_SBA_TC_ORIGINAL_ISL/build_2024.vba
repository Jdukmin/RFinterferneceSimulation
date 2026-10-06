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
    BuildBlock0063
    BuildBlock0064
    BuildBlock0065
    BuildBlock0066
    BuildBlock0067
    BuildBlock0068
    BuildBlock0069
    BuildBlock0070
    BuildBlock0071
    BuildBlock0072
    BuildBlock0073
    BuildBlock0074
    BuildBlock0075
    BuildBlock0076
    BuildBlock0077
    BuildBlock0078
    BuildBlock0079
    BuildBlock0080
    BuildBlock0081
    BuildBlock0082
    BuildBlock0083
    BuildBlock0084
    BuildBlock0085
    BuildBlock0086
    BuildBlock0087
    MsgBox "RFC_SBA_TC_ORIGINAL_ISL: reconstruction finished. Check geometry, ports, monitors and mesh; save RFC_SBA_TC_ORIGINAL_ISL_CST2024.cst. Solver not started."
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
    h = h & "StoreParameterWithDescription ""base_diameter"", ""65"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter base_diameter", h
End Sub

Private Sub BuildBlock0002 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""base_depth"", ""32"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter base_depth", h
End Sub

Private Sub BuildBlock0003 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""helix_diameter"", ""18"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter helix_diameter", h
End Sub

Private Sub BuildBlock0004 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""helix_height"", ""52"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter helix_height", h
End Sub

Private Sub BuildBlock0005 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""turns"", ""0.5"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter turns", h
End Sub

Private Sub BuildBlock0006 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""wire_radius"", ""1.5"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter wire_radius", h
End Sub

Private Sub BuildBlock0007 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""feed_gap"", ""1.2"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter feed_gap", h
End Sub

Private Sub BuildBlock0008 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""groove_depth"", ""20"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter groove_depth", h
End Sub

Private Sub BuildBlock0009 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""perturbation_amplitude"", ""0"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter perturbation_amplitude", h
End Sub

Private Sub BuildBlock0010 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""segments_per_turn"", ""24"", ""Accepted numeric geometry; documentation parameter""" & vbCrLf
    AddToHistory "Accepted parameter segments_per_turn", h
End Sub

Private Sub BuildBlock0011 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_low"", ""10.55""" & vbCrLf
    AddToHistory "cn_f_low", h
End Sub

Private Sub BuildBlock0012 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_center"", ""10.6""" & vbCrLf
    AddToHistory "cn_f_center", h
End Sub

Private Sub BuildBlock0013 ()
    Dim h As String
    h = ""
    h = h & "StoreParameter ""cn_f_high"", ""10.65""" & vbCrLf
    AddToHistory "cn_f_high", h
End Sub

Private Sub BuildBlock0014 ()
    Dim h As String
    h = ""
    h = h & "StoreParameterWithDescription ""cn_rebuild_version"", ""2024"", ""RFC_SBA_TC_ORIGINAL_ISL_CST2024; native save after checks""" & vbCrLf
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
    h = h & " .FrequencyRange ""10.55"", ""10.65""" & vbCrLf
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
    h = h & " .Name ""base_floor""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""32.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-32"", ""-20""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "base_floor", h
End Sub

Private Sub BuildBlock0018 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""base_center""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""12""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-20"", ""0""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "base_center", h
End Sub

Private Sub BuildBlock0019 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""groove_wall_1""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""22""" & vbCrLf
    h = h & " .InnerRadius ""20""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-20"", ""0""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "groove_wall_1", h
End Sub

Private Sub BuildBlock0020 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""outer_wall""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""32.5""" & vbCrLf
    h = h & " .InnerRadius ""30""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""-20"", ""0""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "outer_wall", h
End Sub

Private Sub BuildBlock0021 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""path_arm1""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""centerline""" & vbCrLf
    h = h & " .Curve ""path_arm1""" & vbCrLf
    h = h & " .SetInterpolation ""Spline""" & vbCrLf
    h = h & " .Point ""9"", ""0"", ""1.2""" & vbCrLf
    h = h & " .Point ""9"", ""0"", ""4.2""" & vbCrLf
    h = h & " .Point ""9"", ""0"", ""7.2""" & vbCrLf
    h = h & " .Point ""8.6933324366"", ""2.32937140592"", ""11.5333333333""" & vbCrLf
    h = h & " .Point ""7.79422863406"", ""4.5"", ""15.8666666667""" & vbCrLf
    h = h & " .Point ""6.36396103068"", ""6.36396103068"", ""20.2""" & vbCrLf
    h = h & " .Point ""4.5"", ""7.79422863406"", ""24.5333333333""" & vbCrLf
    h = h & " .Point ""2.32937140592"", ""8.6933324366"", ""28.8666666667""" & vbCrLf
    h = h & " .Point ""5.51091059616e-16"", ""9"", ""33.2""" & vbCrLf
    h = h & " .Point ""-2.32937140592"", ""8.6933324366"", ""37.5333333333""" & vbCrLf
    h = h & " .Point ""-4.5"", ""7.79422863406"", ""41.8666666667""" & vbCrLf
    h = h & " .Point ""-6.36396103068"", ""6.36396103068"", ""46.2""" & vbCrLf
    h = h & " .Point ""-7.79422863406"", ""4.5"", ""50.5333333333""" & vbCrLf
    h = h & " .Point ""-8.6933324366"", ""2.32937140592"", ""54.8666666667""" & vbCrLf
    h = h & " .Point ""-9"", ""1.10218211923e-15"", ""59.2""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Circle" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""profile""" & vbCrLf
    h = h & " .Curve ""path_arm1""" & vbCrLf
    h = h & " .Radius ""1.5""" & vbCrLf
    h = h & " .Xcenter ""9""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""path_arm1:profile""" & vbCrLf
    h = h & " .Vector ""0"", ""0"", ""1.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateCurve" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With SweepCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""arm1""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Twistangle ""0""" & vbCrLf
    h = h & " .Taperangle ""0""" & vbCrLf
    h = h & " .ProjectProfileToPathAdvanced ""True""" & vbCrLf
    h = h & " .Path ""path_arm1:centerline""" & vbCrLf
    h = h & " .Curve ""path_arm1:profile""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "arm1", h
End Sub

Private Sub BuildBlock0022 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""arm1_termination""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""1.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""9""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm1_termination""" & vbCrLf
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
    h = h & " .Name ""RECONSTRUCTION:arm1_termination""" & vbCrLf
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
    h = h & " .Name ""RECONSTRUCTION:arm1_termination""" & vbCrLf
    h = h & " .Vector ""-9"", ""1.10218211923e-15"", ""59.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "arm1_termination", h
End Sub

Private Sub BuildBlock0023 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""path_arm2""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""centerline""" & vbCrLf
    h = h & " .Curve ""path_arm2""" & vbCrLf
    h = h & " .SetInterpolation ""Spline""" & vbCrLf
    h = h & " .Point ""5.51091059616e-16"", ""9"", ""1.2""" & vbCrLf
    h = h & " .Point ""5.51091059616e-16"", ""9"", ""4.2""" & vbCrLf
    h = h & " .Point ""5.51091059616e-16"", ""9"", ""7.2""" & vbCrLf
    h = h & " .Point ""-2.32937140592"", ""8.6933324366"", ""11.5333333333""" & vbCrLf
    h = h & " .Point ""-4.5"", ""7.79422863406"", ""15.8666666667""" & vbCrLf
    h = h & " .Point ""-6.36396103068"", ""6.36396103068"", ""20.2""" & vbCrLf
    h = h & " .Point ""-7.79422863406"", ""4.5"", ""24.5333333333""" & vbCrLf
    h = h & " .Point ""-8.6933324366"", ""2.32937140592"", ""28.8666666667""" & vbCrLf
    h = h & " .Point ""-9"", ""1.10218211923e-15"", ""33.2""" & vbCrLf
    h = h & " .Point ""-8.6933324366"", ""-2.32937140592"", ""37.5333333333""" & vbCrLf
    h = h & " .Point ""-7.79422863406"", ""-4.5"", ""41.8666666667""" & vbCrLf
    h = h & " .Point ""-6.36396103068"", ""-6.36396103068"", ""46.2""" & vbCrLf
    h = h & " .Point ""-4.5"", ""-7.79422863406"", ""50.5333333333""" & vbCrLf
    h = h & " .Point ""-2.32937140592"", ""-8.6933324366"", ""54.8666666667""" & vbCrLf
    h = h & " .Point ""-1.65327317885e-15"", ""-9"", ""59.2""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Circle" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""profile""" & vbCrLf
    h = h & " .Curve ""path_arm2""" & vbCrLf
    h = h & " .Radius ""1.5""" & vbCrLf
    h = h & " .Xcenter ""5.51091059616e-16""" & vbCrLf
    h = h & " .Ycenter ""9""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""path_arm2:profile""" & vbCrLf
    h = h & " .Vector ""0"", ""0"", ""1.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateCurve" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With SweepCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""arm2""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Twistangle ""0""" & vbCrLf
    h = h & " .Taperangle ""0""" & vbCrLf
    h = h & " .ProjectProfileToPathAdvanced ""True""" & vbCrLf
    h = h & " .Path ""path_arm2:centerline""" & vbCrLf
    h = h & " .Curve ""path_arm2:profile""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "arm2", h
End Sub

Private Sub BuildBlock0024 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""arm2_termination""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""1.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""9""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm2_termination""" & vbCrLf
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
    h = h & " .Name ""RECONSTRUCTION:arm2_termination""" & vbCrLf
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
    h = h & " .Name ""RECONSTRUCTION:arm2_termination""" & vbCrLf
    h = h & " .Vector ""-1.65327317885e-15"", ""-9"", ""59.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "arm2_termination", h
End Sub

Private Sub BuildBlock0025 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""path_arm3""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""centerline""" & vbCrLf
    h = h & " .Curve ""path_arm3""" & vbCrLf
    h = h & " .SetInterpolation ""Spline""" & vbCrLf
    h = h & " .Point ""-9"", ""1.10218211923e-15"", ""1.2""" & vbCrLf
    h = h & " .Point ""-9"", ""1.10218211923e-15"", ""4.2""" & vbCrLf
    h = h & " .Point ""-9"", ""1.10218211923e-15"", ""7.2""" & vbCrLf
    h = h & " .Point ""-8.6933324366"", ""-2.32937140592"", ""11.5333333333""" & vbCrLf
    h = h & " .Point ""-7.79422863406"", ""-4.5"", ""15.8666666667""" & vbCrLf
    h = h & " .Point ""-6.36396103068"", ""-6.36396103068"", ""20.2""" & vbCrLf
    h = h & " .Point ""-4.5"", ""-7.79422863406"", ""24.5333333333""" & vbCrLf
    h = h & " .Point ""-2.32937140592"", ""-8.6933324366"", ""28.8666666667""" & vbCrLf
    h = h & " .Point ""-1.65327317885e-15"", ""-9"", ""33.2""" & vbCrLf
    h = h & " .Point ""2.32937140592"", ""-8.6933324366"", ""37.5333333333""" & vbCrLf
    h = h & " .Point ""4.5"", ""-7.79422863406"", ""41.8666666667""" & vbCrLf
    h = h & " .Point ""6.36396103068"", ""-6.36396103068"", ""46.2""" & vbCrLf
    h = h & " .Point ""7.79422863406"", ""-4.5"", ""50.5333333333""" & vbCrLf
    h = h & " .Point ""8.6933324366"", ""-2.32937140592"", ""54.8666666667""" & vbCrLf
    h = h & " .Point ""9"", ""-2.20436423847e-15"", ""59.2""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Circle" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""profile""" & vbCrLf
    h = h & " .Curve ""path_arm3""" & vbCrLf
    h = h & " .Radius ""1.5""" & vbCrLf
    h = h & " .Xcenter ""-9""" & vbCrLf
    h = h & " .Ycenter ""1.10218211923e-15""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""path_arm3:profile""" & vbCrLf
    h = h & " .Vector ""0"", ""0"", ""1.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateCurve" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With SweepCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""arm3""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Twistangle ""0""" & vbCrLf
    h = h & " .Taperangle ""0""" & vbCrLf
    h = h & " .ProjectProfileToPathAdvanced ""True""" & vbCrLf
    h = h & " .Path ""path_arm3:centerline""" & vbCrLf
    h = h & " .Curve ""path_arm3:profile""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "arm3", h
End Sub

Private Sub BuildBlock0026 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""arm3_termination""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""1.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""9""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm3_termination""" & vbCrLf
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
    h = h & " .Name ""RECONSTRUCTION:arm3_termination""" & vbCrLf
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
    h = h & " .Name ""RECONSTRUCTION:arm3_termination""" & vbCrLf
    h = h & " .Vector ""9"", ""-2.20436423847e-15"", ""59.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "arm3_termination", h
End Sub

Private Sub BuildBlock0027 ()
    Dim h As String
    h = ""
    h = h & "Curve.NewCurve ""path_arm4""" & vbCrLf
    h = h & "With Polygon3D" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""centerline""" & vbCrLf
    h = h & " .Curve ""path_arm4""" & vbCrLf
    h = h & " .SetInterpolation ""Spline""" & vbCrLf
    h = h & " .Point ""-1.65327317885e-15"", ""-9"", ""1.2""" & vbCrLf
    h = h & " .Point ""-1.65327317885e-15"", ""-9"", ""4.2""" & vbCrLf
    h = h & " .Point ""-1.65327317885e-15"", ""-9"", ""7.2""" & vbCrLf
    h = h & " .Point ""2.32937140592"", ""-8.6933324366"", ""11.5333333333""" & vbCrLf
    h = h & " .Point ""4.5"", ""-7.79422863406"", ""15.8666666667""" & vbCrLf
    h = h & " .Point ""6.36396103068"", ""-6.36396103068"", ""20.2""" & vbCrLf
    h = h & " .Point ""7.79422863406"", ""-4.5"", ""24.5333333333""" & vbCrLf
    h = h & " .Point ""8.6933324366"", ""-2.32937140592"", ""28.8666666667""" & vbCrLf
    h = h & " .Point ""9"", ""-2.20436423847e-15"", ""33.2""" & vbCrLf
    h = h & " .Point ""8.6933324366"", ""2.32937140592"", ""37.5333333333""" & vbCrLf
    h = h & " .Point ""7.79422863406"", ""4.5"", ""41.8666666667""" & vbCrLf
    h = h & " .Point ""6.36396103068"", ""6.36396103068"", ""46.2""" & vbCrLf
    h = h & " .Point ""4.5"", ""7.79422863406"", ""50.5333333333""" & vbCrLf
    h = h & " .Point ""2.32937140592"", ""8.6933324366"", ""54.8666666667""" & vbCrLf
    h = h & " .Point ""2.75545529808e-15"", ""9"", ""59.2""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Circle" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""profile""" & vbCrLf
    h = h & " .Curve ""path_arm4""" & vbCrLf
    h = h & " .Radius ""1.5""" & vbCrLf
    h = h & " .Xcenter ""-1.65327317885e-15""" & vbCrLf
    h = h & " .Ycenter ""-9""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""path_arm4:profile""" & vbCrLf
    h = h & " .Vector ""0"", ""0"", ""1.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateCurve" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With SweepCurve" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""arm4""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .Twistangle ""0""" & vbCrLf
    h = h & " .Taperangle ""0""" & vbCrLf
    h = h & " .ProjectProfileToPathAdvanced ""True""" & vbCrLf
    h = h & " .Path ""path_arm4:centerline""" & vbCrLf
    h = h & " .Curve ""path_arm4:profile""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "arm4", h
End Sub

Private Sub BuildBlock0028 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""arm4_termination""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""1.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""0"", ""9""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm4_termination""" & vbCrLf
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
    h = h & " .Name ""RECONSTRUCTION:arm4_termination""" & vbCrLf
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
    h = h & " .Name ""RECONSTRUCTION:arm4_termination""" & vbCrLf
    h = h & " .Vector ""2.75545529808e-15"", ""9"", ""59.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .InvertPickedPoints ""False""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "arm4_termination", h
End Sub

Private Sub BuildBlock0029 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:base_floor""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:base_center""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:groove_wall_1""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:outer_wall""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm1""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm1_termination""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm2""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm2_termination""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm3""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm3_termination""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm4""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm4_termination""" & vbCrLf
    h = h & " .MultipleObjects ""True""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-180"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Duplicate accepted antenna for second installation", h
End Sub

Private Sub BuildBlock0030 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:base_floor_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0031 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:base_center_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0032 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:groove_wall_1_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0033 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:outer_wall_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0034 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm1_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0035 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm1_termination_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0036 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm2_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0037 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm2_termination_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0038 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm3_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0039 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm3_termination_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0040 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm4_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0041 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm4_termination_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Second installation position", h
End Sub

Private Sub BuildBlock0042 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:base_floor""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0043 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:base_floor""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0044 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:base_center""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0045 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:base_center""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0046 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:groove_wall_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0047 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:groove_wall_1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0048 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:outer_wall""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0049 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:outer_wall""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0050 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0051 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm1""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0052 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm1_termination""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0053 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm1_termination""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0054 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm2""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0055 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm2""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0056 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm2_termination""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0057 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm2_termination""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0058 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm3""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0059 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm3""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0060 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm3_termination""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0061 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm3_termination""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0062 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm4""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0063 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm4""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0064 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm4_termination""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Origin ""Free""" & vbCrLf
    h = h & " .Center ""0"", ""0"", ""0""" & vbCrLf
    h = h & " .Angle ""-60.0000000062"", ""0"", ""0""" & vbCrLf
    h = h & " .RotateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation rotation", h
End Sub

Private Sub BuildBlock0065 ()
    Dim h As String
    h = ""
    h = h & "With Transform" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""RECONSTRUCTION:arm4_termination""" & vbCrLf
    h = h & " .MultipleObjects ""False""" & vbCrLf
    h = h & " .GroupObjects ""False""" & vbCrLf
    h = h & " .Repetitions ""1""" & vbCrLf
    h = h & " .MultipleSelection ""False""" & vbCrLf
    h = h & " .Vector ""255"", ""870"", ""1030""" & vbCrLf
    h = h & " .TranslateAdvanced" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "First installation position", h
End Sub

Private Sub BuildBlock0066 ()
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

Private Sub BuildBlock0067 ()
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

Private Sub BuildBlock0068 ()
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

Private Sub BuildBlock0069 ()
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

Private Sub BuildBlock0070 ()
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

Private Sub BuildBlock0071 ()
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

Private Sub BuildBlock0072 ()
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

Private Sub BuildBlock0073 ()
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

Private Sub BuildBlock0074 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""1""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""264"", ""870"", ""1030""" & vbCrLf
    h = h & " .Point2 ""264"", ""871.039230485"", ""1030.6""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 1", h
End Sub

Private Sub BuildBlock0075 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""2""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""255"", ""874.499999999"", ""1022.20577137""" & vbCrLf
    h = h & " .Point2 ""255"", ""875.539230484"", ""1022.80577137""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 2", h
End Sub

Private Sub BuildBlock0076 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""3""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""246"", ""870"", ""1030""" & vbCrLf
    h = h & " .Point2 ""246"", ""871.039230485"", ""1030.6""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 3", h
End Sub

Private Sub BuildBlock0077 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""4""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""255"", ""865.500000001"", ""1037.79422863""" & vbCrLf
    h = h & " .Point2 ""255"", ""866.539230485"", ""1038.39422863""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 4", h
End Sub

Private Sub BuildBlock0078 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""5""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""264"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .Point2 ""264"", ""-530"", ""-1241.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 5", h
End Sub

Private Sub BuildBlock0079 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""6""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""255"", ""-539"", ""-1240""" & vbCrLf
    h = h & " .Point2 ""255"", ""-539"", ""-1241.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 6", h
End Sub

Private Sub BuildBlock0080 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""7""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""246"", ""-530"", ""-1240""" & vbCrLf
    h = h & " .Point2 ""246"", ""-530"", ""-1241.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 7", h
End Sub

Private Sub BuildBlock0081 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""8""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""255"", ""-521"", ""-1240""" & vbCrLf
    h = h & " .Point2 ""255"", ""-521"", ""-1241.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 8", h
End Sub

Private Sub BuildBlock0082 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=10.55)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""10.55""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 10.55", h
End Sub

Private Sub BuildBlock0083 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=10.6)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""10.6""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 10.6", h
End Sub

Private Sub BuildBlock0084 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=10.65)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""10.65""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 10.65", h
End Sub

Private Sub BuildBlock0085 ()
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

Private Sub BuildBlock0086 ()
    Dim h As String
    h = ""
    h = h & "With CombineResults" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .SetMonitorType ""frequency""" & vbCrLf
    h = h & " .FarfieldsOnly ""True""" & vbCrLf
    h = h & " .EnableAutomaticLabeling ""False""" & vbCrLf
    h = h & " .SetLabel ""CN_DEFAULT_GROUP""" & vbCrLf
    h = h & " .SetPortModeValues ""1"", ""1"", ""1"", ""0""" & vbCrLf
    h = h & " .SetPortModeValues ""2"", ""1"", ""1"", ""90""" & vbCrLf
    h = h & " .SetPortModeValues ""3"", ""1"", ""1"", ""180""" & vbCrLf
    h = h & " .SetPortModeValues ""4"", ""1"", ""1"", ""270""" & vbCrLf
    h = h & " .SetPortModeValues ""5"", ""1"", ""0"", ""0""" & vbCrLf
    h = h & " .SetPortModeValues ""6"", ""1"", ""0"", ""90""" & vbCrLf
    h = h & " .SetPortModeValues ""7"", ""1"", ""0"", ""180""" & vbCrLf
    h = h & " .SetPortModeValues ""8"", ""1"", ""0"", ""270""" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "CP field-combination definition; no result calculation", h
End Sub

Private Sub BuildBlock0087 ()
    Dim h As String
    h = ""
    h = h & "ResetViewToStructure" & vbCrLf
    h = h & "Plot.ZoomToStructure" & vbCrLf
    AddToHistory "Structure view", h
End Sub

