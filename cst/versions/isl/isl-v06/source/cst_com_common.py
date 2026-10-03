"""CST OLE automation; no CST Python runtime is required."""
import sys


class CstError(RuntimeError):
    pass


def method(obj, name, *args):
    # Late-bound CST methods can otherwise be mistaken for properties.
    obj._FlagAsMethod(name)
    return getattr(obj, name)(*args)


def connect_cst(attach_only=False):
    import win32com.client
    try:
        app = win32com.client.GetActiveObject("CSTStudio.Application")
        print("COM: attached using GetActiveObject", flush=True)
        return app
    except Exception as error:
        print(f"COM: GetActiveObject unavailable: {error}", flush=True)
        if attach_only:
            raise CstError("attach-only requested; no accessible running CST instance") from error
    app = win32com.client.Dispatch("CSTStudio.Application")
    print("COM: connected using Dispatch", flush=True)
    return app


def get_active_project(app):
    project = method(app, "Active3D")
    if project is None:
        raise CstError("No active 3D project. Open a Microwave Studio 3D project in CST first.")
    return project


def add_to_history(project, name, code):
    result = method(project, "AddToHistory", name, code)
    if result is False:
        raise CstError(f"AddToHistory returned False: {name}")
    print(f"OK: {name}", flush=True)


def report_error(stage, error):
    print(f"FAILED at {stage}: {type(error).__name__}: {error}", file=sys.stderr)
    if hasattr(error, "hresult"):
        print(f"HRESULT: 0x{error.hresult & 0xffffffff:08X} ({error.hresult})", file=sys.stderr)
        print(f"COM message: {error.strerror}; details: {error.excepinfo}", file=sys.stderr)


def brick_code(name, component, xmin, xmax, ymin, ymax, zmin, zmax):
    return f'''WCS.ActivateWCS "global"
With Brick
 .Reset
 .Name "{name}"
 .Component "{component}"
 .Material "PEC"
 .Xrange "{xmin}", "{xmax}"
 .Yrange "{ymin}", "{ymax}"
 .Zrange "{zmin}", "{zmax}"
 .Create
End With
'''
