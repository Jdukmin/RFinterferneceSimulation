"""Create one 10 mm PEC brick in the currently open CST project."""
import argparse
from cst_com_common import CstError, method, connect_cst, get_active_project, add_to_history, brick_code, report_error


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--attach-only", action="store_true")
    args = parser.parse_args()
    stage = "connect_cst"
    try:
        app = connect_cst(args.attach_only)
        stage = "Active3D"
        project = get_active_project(app)
        stage = "preflight: duplicate brick name"
        solid = method(project, "Solid")
        names = [method(solid, "GetNameOfShapeFromIndex", i)
                 for i in range(method(solid, "GetNumberOfShapes"))]
        if "COMSmokeTest:com_test_brick" in names:
            raise CstError("COMSmokeTest:com_test_brick already exists. Open a fresh project. No changes made.")
        stage = "AddToHistory / units and com_test_brick (duplicate names are errors)"
        add_to_history(project, "COM smoke test: 10 mm PEC brick", '''With Units
 .Geometry "mm"
End With
''' + brick_code("com_test_brick", "COMSmokeTest", 0, 10, 0, 10, 0, 10))
        stage = "read back brick material and volume"
        name = "COMSmokeTest:com_test_brick"
        if method(solid, "GetMaterialNameForShape", name) != "PEC" or abs(method(solid, "GetVolume", name) - 1000) > 1e-6:
            raise CstError("Brick readback did not match PEC / 1000 mm^3")
        print("SUCCESS: COMSmokeTest:com_test_brick created (10 x 10 x 10 mm, PEC).")
        return 0
    except Exception as error:
        report_error(stage, error)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
