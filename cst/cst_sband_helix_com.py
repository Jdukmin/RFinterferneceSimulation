"""SURROGATE_TRAINING_MODEL: polygonal PEC S-band helix via CST COM."""
import argparse
import math
from cst_com_common import (
    CstError, method, connect_cst, get_active_project, add_to_history,
    brick_code, report_error,
)

COMPONENT = "SURROGATE_TRAINING_MODEL"


def f(value):
    return format(value, ".12g")


def create_ground(project, args):
    half = args.ground_size_mm / 2
    add_to_history(project, "Surrogate: PEC ground", brick_code(
        "ground", COMPONENT, -half, half, -half, half, -2, 0))


def cylinder_segment(name, start, end, radius):
    dx, dy, dz = (b - a for a, b in zip(start, end))
    length = math.sqrt(dx*dx + dy*dy + dz*dz)
    # Rotate the +Z cylinder around Y, then Z; CST's installed macros
    # use Transform.Angle and RotateAdvanced, not an undocumented Wire API.
    tilt = math.degrees(math.acos(dz / length))
    azimuth = math.degrees(math.atan2(dy, dx))
    full_name = f"{COMPONENT}:{name}"
    code = f'''With Cylinder
 .Reset
 .Name "{name}"
 .Component "{COMPONENT}"
 .Material "PEC"
 .OuterRadius "{f(radius)}"
 .InnerRadius "0"
 .Axis "z"
 .Zrange "0", "{f(length)}"
 .Xcenter "0"
 .Ycenter "0"
 .Segments "0"
 .Create
End With
'''
    for angles in ((0, tilt, 0), (0, 0, azimuth)):
        code += f'''With Transform
 .Reset
 .Name "{full_name}"
 .Origin "Free"
 .Center "0", "0", "0"
 .Angle "{f(angles[0])}", "{f(angles[1])}", "{f(angles[2])}"
 .MultipleObjects "False"
 .GroupObjects "False"
 .Repetitions "1"
 .MultipleSelection "False"
 .RotateAdvanced
End With
'''
    code += f'''With Transform
 .Reset
 .Name "{full_name}"
 .Vector "{f(start[0])}", "{f(start[1])}", "{f(start[2])}"
 .UsePickedPoints "False"
 .InvertPickedPoints "False"
 .MultipleObjects "False"
 .GroupObjects "False"
 .Repetitions "1"
 .MultipleSelection "False"
 .TranslateAdvanced
End With
'''
    return code


def create_helix(project, args):
    wavelength = 299.792458 / args.f0
    radius, pitch = wavelength / (2*math.pi), 0.23*wavelength
    count = round(args.turns * args.segments_per_turn)
    # Place the centreline one wire radius above the desired surface gap.
    # A short vertical feed stub has its bottom face exactly at z=feed_gap.
    z0 = args.feed_gap_mm + args.wire_radius_mm
    points = []
    for i in range(count + 1):
        t = 2*math.pi*args.turns*i/count
        points.append((radius*math.cos(t), radius*math.sin(t), z0+pitch*t/(2*math.pi)))
    add_to_history(project, "Surrogate: feed stub", cylinder_segment(
        "helix", (radius, 0, args.feed_gap_mm),
        (radius, 0, z0+0.25), args.wire_radius_mm))
    for i, (start, end) in enumerate(zip(points, points[1:])):
        name = f"segment_{i+1:03d}"
        code = cylinder_segment(name, start, end, args.wire_radius_mm)
        # Adjacent capped cylinders share finite-volume intersections at
        # polygon vertices. Unite them into one connected editable PEC solid.
        code += f'Solid.Add "{COMPONENT}:helix", "{COMPONENT}:{name}"\n'
        add_to_history(project, f"Surrogate: helix segment {i+1}/{count}", code)
    print(f"lambda={wavelength:.5f} mm; R={radius:.5f} mm; pitch={pitch:.5f} mm; "
          f"turns={args.turns:g}; segments={count}; surface gap={args.feed_gap_mm:g} mm")
    return radius


def create_port(project, radius, args):
    # Point1/Point2 syntax comes from installed ADS Converter 1.bas.
    add_to_history(project, "Surrogate: discrete port 1 (50 ohm)", f'''With DiscretePort
 .Reset
 .PortNumber "1"
 .Type "SParameter"
 .Impedance "50.0"
 .Voltage "1.0"
 .Current "1.0"
 .Point1 "{f(radius)}", "0", "0"
 .Point2 "{f(radius)}", "0", "{f(args.feed_gap_mm)}"
 .UsePickedPoints "False"
 .LocalCoordinates "False"
 .Monitor "False"
 .Create
End With
''')


def configure_frequency(project, args):
    add_to_history(project, "Surrogate: mm/GHz/ns units", '''WCS.ActivateWCS "global"
With Units
 .Geometry "mm"
 .Frequency "GHz"
 .Time "ns"
End With
''')
    add_to_history(project, "Surrogate: time domain and frequency band", f'''ChangeSolverType "HF Time Domain"
With Solver
 .FrequencyRange "{f(args.fmin)}", "{f(args.fmax)}"
 .CalculationType "TD-S"
 .StimulationPort "All"
 .StimulationMode "All"
 .SteadyStateLimit "-30"
End With
''')


def configure_boundaries(project):
    add_to_history(project, "Surrogate: vacuum and open (add space)", '''With Background
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
''')


def create_farfield_monitor(project, args):
    add_to_history(project, "Surrogate: farfield monitor", f'''With Monitor
 .Reset
 .Name "farfield (f={f(args.f0)})"
 .Domain "Frequency"
 .FieldType "Farfield"
 .Frequency "{f(args.f0)}"
 .Create
End With
''')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--f0", type=float, default=2.25, help="GHz")
    parser.add_argument("--fmin", type=float, default=2.20, help="GHz")
    parser.add_argument("--fmax", type=float, default=2.30, help="GHz")
    parser.add_argument("--turns", type=float, default=3)
    parser.add_argument("--segments-per-turn", type=int, default=24)
    parser.add_argument("--ground-size-mm", type=float, default=110)
    parser.add_argument("--wire-radius-mm", type=float, default=1.25)
    parser.add_argument("--feed-gap-mm", type=float, default=2)
    parser.add_argument("--attach-only", action="store_true")
    parser.add_argument("--new-project", action="store_true", help="Create a separate empty Microwave Studio project")
    args = parser.parse_args()
    values = (args.f0, args.fmin, args.fmax, args.turns, args.ground_size_mm,
              args.wire_radius_mm, args.feed_gap_mm)
    if not all(math.isfinite(x) and x > 0 for x in values):
        parser.error("all dimensions, frequencies and turns must be finite and positive")
    if not args.fmin <= args.f0 <= args.fmax or args.fmin == args.fmax:
        parser.error("require fmin <= f0 <= fmax, with fmin < fmax")
    if args.segments_per_turn < 8 or not 1 <= round(args.turns*args.segments_per_turn) <= 240:
        parser.error("require >=8 segments per turn and 1..240 total segments")
    if args.ground_size_mm / 2 <= 299.792458/args.f0/(2*math.pi)+args.wire_radius_mm:
        parser.error("ground must extend beyond helix radius plus wire radius")
    stage = "connect_cst"
    try:
        app = connect_cst(args.attach_only)
        stage = "NewMWS / Active3D"
        project = method(app, "NewMWS") if args.new_project else get_active_project(app)
        stage = "preflight: require an empty project (duplicate protection)"
        solid = method(project, "Solid")
        count = method(solid, "GetNumberOfShapes")
        if count:
            raise CstError(f"Project contains {count} shapes. Use a new empty project or --new-project. No changes made.")
        if method(method(project, "Port"), "StartPortNumberIteration"):
            raise CstError("Project already contains ports. Open a fresh project or use --new-project. No changes made.")
        for stage, operation in (
            ("units / solver / frequency", lambda: configure_frequency(project, args)),
            ("radiation boundaries", lambda: configure_boundaries(project)),
            ("ground", lambda: create_ground(project, args)),
        ):
            operation()
        stage = "helix cylinders / union"
        radius = create_helix(project, args)
        stage = "DiscretePort 1"
        create_port(project, radius, args)
        stage = "farfield monitor"
        create_farfield_monitor(project, args)
        stage = "read back final PEC geometry"
        names = [method(solid, "GetNameOfShapeFromIndex", i)
                 for i in range(method(solid, "GetNumberOfShapes"))]
        if set(names) != {f"{COMPONENT}:ground", f"{COMPONENT}:helix"}:
            raise CstError(f"Unexpected final solids: {names}")
        for name in names:
            if method(solid, "GetMaterialNameForShape", name) != "PEC" or method(solid, "GetVolume", name) <= 0:
                raise CstError(f"Invalid final PEC solid: {name}")
        stage = "view"
        add_to_history(project, "Surrogate: structure view", 'ResetViewToStructure\nPlot.ZoomToStructure\n')
        print("SUCCESS: SURROGATE_TRAINING_MODEL created. Inspect mesh and Port 1 in GUI before solving.")
        return 0
    except Exception as error:
        report_error(stage, error)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
