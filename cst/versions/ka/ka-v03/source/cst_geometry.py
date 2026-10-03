"""Numeric History geometry with audited dimensions saved alongside each project."""
import math
import cst_sband_helix_com as baseline
from cst_com_common import add_to_history,method

COMPONENT='RECONSTRUCTION'

def cylinder(p,name,r,z0,z1,inner=0,x=0,y=0,material='PEC'):
    if not 0<=inner<r or not z0<z1:raise ValueError('Invalid cylinder dimensions')
    add_to_history(p,name,f'''With Cylinder
 .Reset
 .Name "{name}"
 .Component "{COMPONENT}"
 .Material "{material}"
 .OuterRadius "{r:.12g}"
 .InnerRadius "{inner:.12g}"
 .Axis "z"
 .Zrange "{z0:.12g}", "{z1:.12g}"
 .Xcenter "{x:.12g}"
 .Ycenter "{y:.12g}"
 .Segments "0"
 .Create
End With''')

def segment(p,name,a,b,r,unite=None):
    previous=baseline.COMPONENT
    try:
        baseline.COMPONENT=COMPONENT
        code=baseline.cylinder_segment(name,a,b,r)
    finally:baseline.COMPONENT=previous
    if unite:code+=f'\nSolid.Add "{COMPONENT}:{unite}", "{COMPONENT}:{name}"'
    add_to_history(p,name,code)

def port(p,number,a,b,impedance=50):
    xyz=lambda q:', '.join(f'"{v:.12g}"' for v in q)
    add_to_history(p,f'Port {number}',f'''With DiscretePort
 .Reset
 .PortNumber "{number}"
 .Type "SParameter"
 .Impedance "{impedance}"
 .Voltage "1"
 .Current "1"
 .Point1 {xyz(a)}
 .Point2 {xyz(b)}
 .UsePickedPoints "False"
 .LocalCoordinates "False"
 .Monitor "False"
 .Create
End With''')

def swept_wire(p,name,points,r):
    """One solid per arm using CST's installed Polygon3D + SweepCurve syntax."""
    curve=f'path_{name}'
    x,y,z=points[0]
    code=f'''Curve.NewCurve "{curve}"
With Polygon3D
 .Reset
 .Name "centerline"
 .Curve "{curve}"
 .SetInterpolation "Spline"
'''
    for a,b,c in points:code+=f' .Point "{a:.12g}", "{b:.12g}", "{c:.12g}"\n'
    code+=' .Create\nEnd With\n'
    code+=f'''With Circle
 .Reset
 .Name "profile"
 .Curve "{curve}"
 .Radius "{r:.12g}"
 .Xcenter "{x:.12g}"
 .Ycenter "{y:.12g}"
 .Segments "0"
 .Create
End With
With Transform
 .Reset
 .Name "{curve}:profile"
 .Vector "0", "0", "{z:.12g}"
 .UsePickedPoints "False"
 .InvertPickedPoints "False"
 .MultipleObjects "False"
 .GroupObjects "False"
 .Repetitions "1"
 .MultipleSelection "False"
 .TranslateCurve
End With
With SweepCurve
 .Reset
 .Name "{name}"
 .Component "{COMPONENT}"
 .Material "PEC"
 .Twistangle "0"
 .Taperangle "0"
 .ProjectProfileToPathAdvanced "True"
 .Path "{curve}:centerline"
 .Curve "{curve}:profile"
 .Create
End With'''
    add_to_history(p,name,code)

def validate(p,ports):
    s=method(p,'Solid');count=method(s,'GetNumberOfShapes')
    solids={}
    for i in range(count):
        name=method(s,'GetNameOfShapeFromIndex',i)
        vol=method(s,'GetVolume',name)
        if vol<=0:raise ValueError(f'Zero volume: {name}')
        solids[name]={'volume_mm3':vol,'material':method(s,'GetMaterialNameForShape',name)}
    if method(method(p,'Port'),'StartPortNumberIteration')!=ports:raise ValueError('Port count mismatch')
    return solids
