"""Generate a separate 4-arm resonant multifilar reconstruction in CST 2026."""
import argparse,json,math
from pathlib import Path
import yaml
from cst_com import ROOT,new_project,save,monitor,run
from cst_com_common import add_to_history,method
from cst_geometry import cylinder,segment,port,validate,swept_wire

def build(v,path,solve=False,mesh_lines_per_wavelength=None,mesh_arm_step=None):
    path=Path(path).resolve()
    if path.exists():raise FileExistsError(f'Refusing overwrite: {path}')
    app,p=new_project(2.0,2.3)
    for k,val in v.items():method(p,'StoreParameter',k,str(val))
    r=v['helix_diameter']/2;h=v['helix_height'];n=v['turns'];gap=v['feed_gap'];w=v['wire_radius']
    base=v['base_depth'];g=v['groove_depth']
    cylinder(p,'base_floor',32.5,-base,-g)
    for name,ri,ro in [('base_center',0,12),('groove_wall_1',20,22),('outer_wall',30,32.5)]:
        cylinder(p,name,ro,-g,0,ri)
    # Four bottom-fed arms sharing only the far-end hub; no infinite ground.
    count=round(n*v['segments_per_turn'])
    top=gap+4*w+h
    for arm in range(4):
        phase=math.pi*arm/2
        x,y=r*math.cos(phase),r*math.sin(phase)
        name=f'arm{arm+1}'
        pts=[(x,y,gap),(x,y,gap+2*w)]
        for index in range(count+1):
            t=index/count
            angle=phase+2*math.pi*n*t
            rr=r+v['perturbation_amplitude']*math.sin(4*math.pi*t)**2
            pts.append((rr*math.cos(angle),rr*math.sin(angle),gap+4*w+h*t))
        swept_wire(p,name,pts,w)
        endangle=phase+2*math.pi*n
        segment(p,f'{name}_termination',(r*math.cos(endangle),r*math.sin(endangle),top),(0,0,top),w)
        port(p,arm+1,(x,y,0),(x,y,gap))
    for f in [2.0,2.06,2.12,2.2,2.25,2.3]:monitor(p,f)
    if mesh_lines_per_wavelength is not None:
        # Exact Mesh syntax from installed ADS Converter 1.bas, lines 4255-4260.
        add_to_history(p,'Controlled wavelength mesh refinement',
                       f'Mesh.LinesPerWavelength "{float(mesh_lines_per_wavelength):g}"')
    if mesh_arm_step is not None:
        # Exact group/ItemMeshSettings/Step syntax from installed
        # Apply Mesh Refinement To Dummy Object^-DS.mcr.
        code='Group.Add "RFC_ARM_REFINEMENT", "mesh"\n'
        for i in range(1,5):
            code+=f'Group.AddItem "solid$RECONSTRUCTION:arm{i}", "RFC_ARM_REFINEMENT"\n'
        step=float(mesh_arm_step)
        code+=f'''With MeshSettings
 With .ItemMeshSettings ("group$RFC_ARM_REFINEMENT")
  .SetMeshType "Hex"
  .Set "Step", "{step:g}", "{step:g}", "{step:g}"
 End With
End With'''
        add_to_history(p,'Single controlled local arm mesh refinement',code)
    add_to_history(p,'Structure view','ResetViewToStructure\nPlot.ZoomToStructure')
    solids=validate(p,4)
    evidence={'parameters':v,'solids':solids,'project':str(path),'status':'GEOMETRY_CREATED_SOLVER_NOT_RUN'}
    evidence['mesh_lines_per_wavelength']=mesh_lines_per_wavelength
    evidence['mesh_arm_step_mm']=mesh_arm_step
    save(p,path)
    if solve:
        run(p)
        logpath=path.with_suffix('')/'Result'/'Model.log'
        log=logpath.read_text(encoding='utf-8',errors='replace') if logpath.exists() else ''
        if '*** Error ***' in log or 'solver finished successfully' not in log:
            evidence['status']='SOLVER_FAILED'
            evidence['solver_log']=str(logpath)
            path.with_suffix('.geometry.json').write_text(json.dumps(evidence,indent=2),encoding='utf-8')
            raise RuntimeError(f'Solver did not complete successfully: {logpath}')
        save(p,path);evidence['status']='SOLVER_COMPLETED_CHECK_RESULTS_AND_VALIDATION'
    path.with_suffix('.geometry.json').write_text(json.dumps(evidence,indent=2),encoding='utf-8')
    return app,p

def main():
    a=argparse.ArgumentParser(description=__doc__)
    a.add_argument('--spec',default=str(ROOT/'specs/sband_ttc.yaml'))
    a.add_argument('--output',default=str(ROOT/'projects/SBAND_TTC_INITIAL.cst'))
    a.add_argument('--run',action='store_true')
    a.add_argument('--set',action='append',default=[],metavar='PARAM=VALUE')
    args=a.parse_args();spec=yaml.safe_load(Path(args.spec).read_text(encoding='utf-8'))
    v={k:d['value'] for k,d in spec['dimensions'].items() if isinstance(d['value'],(int,float))}
    for item in args.set:
        k,value=item.split('=',1)
        if k not in v:raise ValueError(f'Unknown parameter {k}')
        v[k]=float(value)
    if not (0<v['helix_diameter']/2-v['wire_radius'] and v['helix_diameter']/2+v['wire_radius']<12):
        raise ValueError('Feed must sit over the conductive center disk; enlarge center disk before using D>=22 mm')
    if not 0<v['groove_depth']<v['base_depth']:raise ValueError('Invalid groove depth')
    if v['helix_height']+v['feed_gap']+2*v['wire_radius']>204:raise ValueError('Height above mounting interface exceeds source envelope')
    build(v,args.output,args.run)

if __name__=='__main__':main()
