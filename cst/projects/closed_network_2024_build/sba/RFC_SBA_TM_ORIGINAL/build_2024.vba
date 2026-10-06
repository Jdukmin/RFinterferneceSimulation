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
    MsgBox "RFC_SBA_TM_ORIGINAL: reconstruction finished. Check geometry, ports, monitors and mesh; save RFC_SBA_TM_ORIGINAL_CST2024.cst. Solver not started."
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
    h = h & "StoreParameterWithDescription ""cn_rebuild_version"", ""2024"", ""RFC_SBA_TM_ORIGINAL_CST2024; native save after checks""" & vbCrLf
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
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""1""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""9"", ""0"", ""0""" & vbCrLf
    h = h & " .Point2 ""9"", ""0"", ""1.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 1", h
End Sub

Private Sub BuildBlock0030 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""2""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""5.51091059616e-16"", ""9"", ""0""" & vbCrLf
    h = h & " .Point2 ""5.51091059616e-16"", ""9"", ""1.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 2", h
End Sub

Private Sub BuildBlock0031 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""3""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""-9"", ""1.10218211923e-15"", ""0""" & vbCrLf
    h = h & " .Point2 ""-9"", ""1.10218211923e-15"", ""1.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 3", h
End Sub

Private Sub BuildBlock0032 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""4""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""-1.65327317885e-15"", ""-9"", ""0""" & vbCrLf
    h = h & " .Point2 ""-1.65327317885e-15"", ""-9"", ""1.2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 4", h
End Sub

Private Sub BuildBlock0033 ()
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

Private Sub BuildBlock0034 ()
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

Private Sub BuildBlock0035 ()
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

Private Sub BuildBlock0036 ()
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

Private Sub BuildBlock0037 ()
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
    h = h & "End With" & vbCrLf
    AddToHistory "CP field-combination definition; no result calculation", h
End Sub

Private Sub BuildBlock0038 ()
    Dim h As String
    h = ""
    h = h & "ResetViewToStructure" & vbCrLf
    h = h & "Plot.ZoomToStructure" & vbCrLf
    AddToHistory "Structure view", h
End Sub

