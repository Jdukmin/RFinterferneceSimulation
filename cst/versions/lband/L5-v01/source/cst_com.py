"""Deterministic CST COM operations; never rebuild the user's active model."""
from pathlib import Path
from types import SimpleNamespace
from cst_com_common import method, connect_cst, add_to_history, CstError
from cst_sband_helix_com import configure_frequency, configure_boundaries

ROOT = Path(__file__).resolve().parent

def new_project(fmin, fmax, accuracy=-40):
    app = connect_cst(False)
    p = method(app, 'NewMWS')
    if method(method(p,'Solid'),'GetNumberOfShapes'):
        raise CstError('New project is not empty')
    configure_frequency(p, SimpleNamespace(fmin=fmin,fmax=fmax))
    configure_boundaries(p)
    # Installed Horn antenna macro uses this spelling. CST PML help defines
    # it as min(center frequency, nonzero monitor frequencies), avoiding
    # inaccurate low-band monitor treatment at the default center reference.
    add_to_history(p,'PML reference includes lowest monitor',
                   'Boundary.MinimumDistanceReferenceFrequencyType "CenterNMonitors"')
    add_to_history(p,'Analysis accuracy',f'Solver.SteadyStateLimit "{accuracy}"')
    return app,p

def save(p,path):
    path=Path(path).resolve(); path.parent.mkdir(parents=True,exist_ok=True)
    method(p,'SaveAs',str(path),True)

def monitor(p,freq):
    add_to_history(p,f'Farfield {freq:g} GHz',f'''With Monitor
 .Reset
 .Name "farfield (f={freq:g})"
 .Domain "Frequency"
 .FieldType "Farfield"
 .Frequency "{freq:g}"
 .Create
End With''')

def run(p):
    result=method(method(p,'Solver'),'Start')
    if result is False: raise CstError('Solver.Start returned False; inspect solver log')
    return result

def quadrature(p,n=4,label='CP_QUADRATURE'):
    obj=method(p,'CombineResults'); method(obj,'Reset')
    method(obj,'SetMonitorType','frequency');method(obj,'FarfieldsOnly',True)
    method(obj,'EnableAutomaticLabeling',False);method(obj,'SetLabel',label)
    for i in range(n):method(obj,'SetPortModeValues',i+1,1,1.0,360*i/n)
    method(obj,'Run')
    return label
