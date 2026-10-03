' SOURCE: cst_sband_helix_com.configure_boundaries + cst_com.new_project (actual runs);
'         "expanded open" == GUI "open (add space)"; PML reference spelling from installed Horn antenna macro.
'@@ Vacuum background and open (add space) boundaries
With Background
 .Type "Normal"
 .Epsilon "1.0"
 .Mu "1.0"
 .XminSpace "0.0"
 .XmaxSpace "0.0"
 .YminSpace "0.0"
 .YmaxSpace "0.0"
 .ZminSpace "0.0"
 .ZmaxSpace "0.0"
End With
With Boundary
 .Xmin "expanded open"
 .Xmax "expanded open"
 .Ymin "expanded open"
 .Ymax "expanded open"
 .Zmin "expanded open"
 .Zmax "expanded open"
 .Xsymmetry "none"
 .Ysymmetry "none"
 .Zsymmetry "none"
End With
'@@ PML reference includes lowest monitor
Boundary.MinimumDistanceReferenceFrequencyType "CenterNMonitors"
