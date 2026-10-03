"""Read back PEC solids and check feed clearance through installed COM methods."""
import math
from cst_com_common import connect_cst, get_active_project, method


if __name__ == "__main__":
    app = connect_cst(True)
    project = get_active_project(app)
    solid = method(project, "Solid")
    count = method(solid, "GetNumberOfShapes")
    names = [method(solid, "GetNameOfShapeFromIndex", i) for i in range(count)]
    print("SOLIDS", names)
    assert set(names) == {"SURROGATE_TRAINING_MODEL:ground", "SURROGATE_TRAINING_MODEL:helix"}
    for name in names:
        material = method(solid, "GetMaterialNameForShape", name)
        volume = method(solid, "GetVolume", name)
        print(name, "material=", material, "volume mm^3=", volume)
        assert material == "PEC" and volume > 0
    radius = 299.792458 / 2.25 / (2*math.pi)
    pitch = 0.23*299.792458/2.25
    for i in range(72):
        angle = 2*math.pi*(i+0.5)/24
        # Polygon chord midpoint, rather than the ideal smooth helix.
        x = radius*math.cos(angle)*math.cos(math.pi/24)
        y = radius*math.sin(angle)*math.cos(math.pi/24)
        z = 3.25+pitch*(i+0.5)/24
        assert method(solid, "IsPointInsideShape", x, y, z, "SURROGATE_TRAINING_MODEL:helix"), i
    print("HELIX: all 72 chord midpoints inside PEC; 3 turns advance along +Z")
    for z, ground_expected, helix_expected in ((-1, True, False), (1, False, False), (2.1, False, True)):
        checks = [bool(method(solid, "IsPointInsideShape", radius, 0, z, name)) for name in names]
        print(f"FEED ({radius:.9g},0,{z}) inside solids:", dict(zip(names, checks)))
        assert checks[names.index("SURROGATE_TRAINING_MODEL:ground")] == ground_expected
        assert checks[names.index("SURROGATE_TRAINING_MODEL:helix")] == helix_expected
    port = method(project, "Port")
    nports = method(port, "StartPortNumberIteration")
    print("PORT COUNT", nports)
    assert nports == 1
    number = method(port, "GetNextPortNumber")
    impedance = method(port, "GetLineImpedance", number, 1)
    print("PORT", number, "impedance", impedance)
    assert number == 1 and float(impedance) == 50
    print("PASS: two PEC solids, feed clearance, Port #1 impedance")
