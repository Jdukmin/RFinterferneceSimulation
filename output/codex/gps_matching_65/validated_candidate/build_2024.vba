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
    MsgBox "GPS_TRIBAND_MATCH65: reconstruction finished. Check geometry, ports, monitors and mesh; save GPS_TRIBAND_MATCH65_CST2024.cst. Solver not started."
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
    AddToHistory "Surrogate: mm/GHz/ns units", h
End Sub

Private Sub BuildBlock0001 ()
    Dim h As String
    h = ""
    h = h & "ChangeSolverType ""HF Time Domain""" & vbCrLf
    h = h & "With Solver" & vbCrLf
    h = h & " .FrequencyRange ""1.164"", ""1.588""" & vbCrLf
    h = h & " .CalculationType ""TD-S""" & vbCrLf
    h = h & " .StimulationPort ""All""" & vbCrLf
    h = h & " .StimulationMode ""All""" & vbCrLf
    h = h & " .SteadyStateLimit ""-30""" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Surrogate: time domain and frequency band", h
End Sub

Private Sub BuildBlock0002 ()
    Dim h As String
    h = ""
    h = h & "With Background" & vbCrLf
    h = h & " .Type ""Normal""" & vbCrLf
    h = h & " .Epsilon ""1.0""" & vbCrLf
    h = h & " .Mu ""1.0""" & vbCrLf
    h = h & " .XminSpace ""0.0""" & vbCrLf
    h = h & " .XmaxSpace ""0.0""" & vbCrLf
    h = h & " .YminSpace ""0.0""" & vbCrLf
    h = h & " .YmaxSpace ""0.0""" & vbCrLf
    h = h & " .ZminSpace ""0.0""" & vbCrLf
    h = h & " .ZmaxSpace ""0.0""" & vbCrLf
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
    AddToHistory "Surrogate: vacuum and open (add space)", h
End Sub

Private Sub BuildBlock0003 ()
    Dim h As String
    h = ""
    h = h & "Boundary.MinimumDistanceReferenceFrequencyType ""CenterNMonitors""" & vbCrLf
    AddToHistory "Lowest-monitor PML reference", h
End Sub

Private Sub BuildBlock0004 ()
    Dim h As String
    h = ""
    h = h & "Solver.SteadyStateLimit ""-40""" & vbCrLf
    AddToHistory "Steady-state accuracy", h
End Sub

Private Sub BuildBlock0005 ()
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

Private Sub BuildBlock0006 ()
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

Private Sub BuildBlock0007 ()
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

Private Sub BuildBlock0008 ()
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

Private Sub BuildBlock0009 ()
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

Private Sub BuildBlock0010 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""lower_patch""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""65""" & vbCrLf
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

Private Sub BuildBlock0011 ()
    Dim h As String
    h = ""
    h = h & "With Cylinder" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""upper_patch""" & vbCrLf
    h = h & " .Component ""RECONSTRUCTION""" & vbCrLf
    h = h & " .Material ""PEC""" & vbCrLf
    h = h & " .OuterRadius ""46.5""" & vbCrLf
    h = h & " .InnerRadius ""0""" & vbCrLf
    h = h & " .Axis ""z""" & vbCrLf
    h = h & " .Zrange ""19"", ""20""" & vbCrLf
    h = h & " .Xcenter ""0""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "upper_patch", h
End Sub

Private Sub BuildBlock0012 ()
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
    h = h & " .Xcenter ""45""" & vbCrLf
    h = h & " .Ycenter ""0""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe1", h
End Sub

Private Sub BuildBlock0013 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""1""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""45"", ""0"", ""0""" & vbCrLf
    h = h & " .Point2 ""45"", ""0"", ""2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 1", h
End Sub

Private Sub BuildBlock0014 ()
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
    h = h & " .Xcenter ""2.75545529808e-15""" & vbCrLf
    h = h & " .Ycenter ""45""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe2", h
End Sub

Private Sub BuildBlock0015 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""2""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""2.75545529808e-15"", ""45"", ""0""" & vbCrLf
    h = h & " .Point2 ""2.75545529808e-15"", ""45"", ""2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 2", h
End Sub

Private Sub BuildBlock0016 ()
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
    h = h & " .Xcenter ""-45""" & vbCrLf
    h = h & " .Ycenter ""5.51091059616e-15""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe3", h
End Sub

Private Sub BuildBlock0017 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""3""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""-45"", ""5.51091059616e-15"", ""0""" & vbCrLf
    h = h & " .Point2 ""-45"", ""5.51091059616e-15"", ""2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 3", h
End Sub

Private Sub BuildBlock0018 ()
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
    h = h & " .Xcenter ""-8.26636589424e-15""" & vbCrLf
    h = h & " .Ycenter ""-45""" & vbCrLf
    h = h & " .Segments ""0""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "probe4", h
End Sub

Private Sub BuildBlock0019 ()
    Dim h As String
    h = ""
    h = h & "With DiscretePort" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .PortNumber ""4""" & vbCrLf
    h = h & " .Type ""SParameter""" & vbCrLf
    h = h & " .Impedance ""50""" & vbCrLf
    h = h & " .Voltage ""1""" & vbCrLf
    h = h & " .Current ""1""" & vbCrLf
    h = h & " .Point1 ""-8.26636589424e-15"", ""-45"", ""0""" & vbCrLf
    h = h & " .Point2 ""-8.26636589424e-15"", ""-45"", ""2""" & vbCrLf
    h = h & " .UsePickedPoints ""False""" & vbCrLf
    h = h & " .LocalCoordinates ""False""" & vbCrLf
    h = h & " .Monitor ""False""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Port 4", h
End Sub

Private Sub BuildBlock0020 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=1.164)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""1.164""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 1.164 GHz", h
End Sub

Private Sub BuildBlock0021 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=1.17645)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""1.17645""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 1.17645 GHz", h
End Sub

Private Sub BuildBlock0022 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=1.189)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""1.189""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 1.189 GHz", h
End Sub

Private Sub BuildBlock0023 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=1.21737)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""1.21737""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 1.21737 GHz", h
End Sub

Private Sub BuildBlock0024 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=1.2276)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""1.2276""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 1.2276 GHz", h
End Sub

Private Sub BuildBlock0025 ()
    Dim h As String
    h = ""
    h = h & "With Monitor" & vbCrLf
    h = h & " .Reset" & vbCrLf
    h = h & " .Name ""farfield (f=1.23783)""" & vbCrLf
    h = h & " .Domain ""Frequency""" & vbCrLf
    h = h & " .FieldType ""Farfield""" & vbCrLf
    h = h & " .Frequency ""1.23783""" & vbCrLf
    h = h & " .Create" & vbCrLf
    h = h & "End With" & vbCrLf
    AddToHistory "Farfield 1.23783 GHz", h
End Sub

Private Sub BuildBlock0026 ()
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
    AddToHistory "Farfield 1.563 GHz", h
End Sub

Private Sub BuildBlock0027 ()
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
    AddToHistory "Farfield 1.57542 GHz", h
End Sub

Private Sub BuildBlock0028 ()
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
    AddToHistory "Farfield 1.588 GHz", h
End Sub

Private Sub BuildBlock0029 ()
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
    AddToHistory "Mesh resource configuration", h
End Sub

Private Sub BuildBlock0030 ()
    Dim h As String
    h = ""
    h = h & "ResetViewToStructure" & vbCrLf
    h = h & "Plot.ZoomToStructure" & vbCrLf
    AddToHistory "Structure view", h
End Sub
