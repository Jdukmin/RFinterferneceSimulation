# CST Studio Suite 2026
# S-band axial-mode helix surrogate generator
# Intended for CST's built-in Python scripting environment.
#
# Creates:
#   - PEC square ground plane
#   - 3-turn polygonal helix (PEC wire segments)
#   - 50-ohm discrete port
#   - 2.20-2.30 GHz range
#   - open(add space) boundaries
#   - 2.25 GHz far-field monitor
#
# This is a SURROGATE training model, not a reconstruction of the
# Beyond Gravity / RUAG SBA1/SBA4 antenna.

import sys
import math

CST_PY = r"C:\Program Files\CST Studio Suite 2026\AMD64\python_cst_libraries"
sys.path.insert(0, CST_PY)

import cst
from cst.interface import DesignEnvironment

print("CST API:", cst.__file__)

de = DesignEnvironment.connect_to_any()
prj = de.active_project()

def add_history(title, vba):
    prj.modeler.add_to_history(title, vba)

# ---------------- USER PARAMETERS ----------------
F0_GHZ = 2.25
FMIN_GHZ = 2.20
FMAX_GHZ = 2.30

N_TURNS = 3.0
SEG_PER_TURN = 24          # intentionally light for Learning Edition
WIRE_RADIUS_MM = 1.25
FEED_GAP_MM = 2.0
GROUND_SIZE_MM = 110.0
GROUND_THICKNESS_MM = 2.0

# Axial-mode starting geometry:
# circumference ~ 1 lambda, pitch ~ 0.23 lambda
C0_MM_PER_GHZ = 299.792458
LAMBDA_MM = C0_MM_PER_GHZ / F0_GHZ
HELIX_RADIUS_MM = LAMBDA_MM / (2.0 * math.pi)
PITCH_MM = 0.23 * LAMBDA_MM

# -------------------------------------------------

prj = get_current_project()

def add_history(title, vba):
    """CST 2024-2026 compatibility wrapper."""
    if hasattr(prj, "model3d") and hasattr(prj.model3d, "add_to_history"):
        return prj.model3d.add_to_history(title, vba)
    if hasattr(prj, "modeler") and hasattr(prj.modeler, "add_to_history"):
        return prj.modeler.add_to_history(title, vba)
    raise RuntimeError("Cannot find CST add_to_history interface.")

def f(x):
    return f"{x:.9g}"

print("Building S-band helix surrogate")
print(f"lambda0 = {LAMBDA_MM:.3f} mm")
print(f"helix radius = {HELIX_RADIUS_MM:.3f} mm")
print(f"pitch = {PITCH_MM:.3f} mm")

add_history("Python: units", r'''
With Units
    .SetUnit "Length", "mm"
    .SetUnit "Frequency", "GHz"
    .SetUnit "Time", "ns"
End With
''')

add_history("Python: time-domain solver and frequency", f'''
ChangeSolverType "HF Time Domain"
Solver.FrequencyRange "{FMIN_GHZ}", "{FMAX_GHZ}"
''')

add_history("Python: open boundaries", r'''
With Boundary
    .Xmin "open (add space)"
    .Xmax "open (add space)"
    .Ymin "open (add space)"
    .Ymax "open (add space)"
    .Zmin "open (add space)"
    .Zmax "open (add space)"
    .ApplyInAllDirections "False"
End With
''')

g = GROUND_SIZE_MM / 2.0
add_history("Python: PEC ground plane", f'''
With Brick
    .Reset
    .Name "ground"
    .Component "SbandHelix"
    .Material "PEC"
    .Xrange "{f(-g)}", "{f(g)}"
    .Yrange "{f(-g)}", "{f(g)}"
    .Zrange "{f(-GROUND_THICKNESS_MM)}", "0"
    .Create
End With
''')

# Polygonal helix made from short PEC Wire solids.
# First helix point is at (R,0,FEED_GAP), so the discrete port bridges
# from the ground top to the helix start.
nseg = int(round(N_TURNS * SEG_PER_TURN))

for i in range(nseg):
    t1 = 2.0 * math.pi * i / SEG_PER_TURN
    t2 = 2.0 * math.pi * (i + 1) / SEG_PER_TURN

    x1 = HELIX_RADIUS_MM * math.cos(t1)
    y1 = HELIX_RADIUS_MM * math.sin(t1)
    z1 = FEED_GAP_MM + PITCH_MM * t1 / (2.0 * math.pi)

    x2 = HELIX_RADIUS_MM * math.cos(t2)
    y2 = HELIX_RADIUS_MM * math.sin(t2)
    z2 = FEED_GAP_MM + PITCH_MM * t2 / (2.0 * math.pi)

    add_history(f"Python: helix segment {i+1:03d}", f'''
With Wire
    .Reset
    .Name "helix_{i+1:03d}"
    .Component "SbandHelix"
    .Material "PEC"
    .Type "Wire"
    .Xcoordinate "{f(x1)}", "{f(x2)}"
    .Ycoordinate "{f(y1)}", "{f(y2)}"
    .Zcoordinate "{f(z1)}", "{f(z2)}"
    .Radius "{f(WIRE_RADIUS_MM)}"
    .Segments "0"
    .ArcFactor "0"
    .Closed "False"
    .Create
End With
''')

px = HELIX_RADIUS_MM
add_history("Python: 50 ohm discrete port", f'''
With DiscretePort
    .Reset
    .Type "Sparameter"
    .PortNumber "1"
    .SetP1 "False", "{f(px)}", "0", "0"
    .SetP2 "False", "{f(px)}", "0", "{f(FEED_GAP_MM)}"
    .Impedance "50"
    .Voltage "1"
    .Current "1"
    .Radius "0"
    .Create
End With
''')

add_history("Python: 2.25 GHz farfield monitor", f'''
With Monitor
    .Reset
    .Name "farfield (f={F0_GHZ})"
    .FieldType "Farfield"
    .Domain "frequency"
    .Frequency "{F0_GHZ}"
    .UseSubvolume "False"
    .Create
End With
''')

add_history("Python: transient solver settings", r'''
With Solver
    .Method "Hexahedral"
    .StimulationPort "All"
    .StimulationMode "All"
    .SteadyStateLimit "-30"
    .AutoNormImpedance "True"
    .PrepareFarfields "True"
End With
''')

print("")
print("Done.")
print("Inspect geometry and Port 1 before running the solver.")
print("Then run the Time Domain solver manually.")
print(r"Expected result tree after solve: Farfields\farfield (f=2.25) [1]")
