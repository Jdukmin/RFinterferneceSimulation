"""Deterministic air-loaded stacked-patch cup surrogate, L5 first."""
import argparse,json,math
from pathlib import Path
import yaml
from cst_com import ROOT,new_project,monitor,save,run
from cst_com_common import add_to_history
from cst_geometry import cylinder,port,validate

def build(spec,path,solve=False):
    path=Path(path).resolve()
    if path.exists():raise FileExistsError(f'Refusing overwrite: {path}')
    v={k:d['value'] for k,d in spec['dimensions'].items()}
    app,p=new_project(*spec['frequency']['initial_solve_ghz'])
    radius=v['cup_inner_diameter']/2;rim=v['cup_depth']
    bottom=rim-v['choke_depth'];outer=v['outer_diameter']/2
    cylinder(p,'cup_floor',radius,-3,0)
    cylinder(p,'cup_wall',radius+v['cup_wall_thickness'],bottom,rim,radius)
    cylinder(p,'choke_floor',outer,bottom-3,bottom,radius+v['cup_wall_thickness'])
    cylinder(p,'choke_separator',v['choke2_inner_radius'],bottom,rim,v['choke1_outer_radius'])
    cylinder(p,'outer_wall',outer,bottom,rim,v['choke2_outer_radius'])
    h=v['patch_to_ground_height'];th=v['patch_thickness']
    cylinder(p,'lower_patch',v['lower_patch_diameter']/2,h,h+th)
    upper=h+th+v['patch_spacing']
    cylinder(p,'upper_patch',v['upper_patch_diameter']/2,upper,upper+th)
    gap=2.0
    for i in range(4):
        angle=i*math.pi/2;x=v['feed_radius']*math.cos(angle);y=v['feed_radius']*math.sin(angle)
        cylinder(p,f'probe{i+1}',v['feed_probe_radius'],gap,h+th,x=x,y=y)
        port(p,i+1,(x,y,0),(x,y,gap))
    for f in spec['frequency']['initial_monitors_ghz']:monitor(p,f)
    # Installed ADS/Sonnet converter macros explicitly use thin-PEC fixpoint
    # merging for planar conductors. Resource configuration, not convergence.
    add_to_history(p,'Thin PEC plate mesh resource setting',
                   'With Mesh\n .MergeThinPECLayerFixpoints "True"\n .RatioLimit "5"\nEnd With')
    # MeshSettings.Set keys are recorded in installed CST demo macros;
    # Hex mesh type is recorded in the installed mesh-group macros.
    add_to_history(p,'Learning Edition global mesh resource budget', '''With MeshSettings
 .SetMeshType "Hex"
 .Set "StepsPerWaveNear", "8"
 .Set "StepsPerWaveFar", "8"
 .Set "StepsPerBoxNear", "8"
 .Set "StepsPerBoxFar", "8"
End With''')
    add_to_history(p,'Structure view','ResetViewToStructure\nPlot.ZoomToStructure')
    evidence={'model_identity':spec['model_identity'],'parameters':v,'solids':validate(p,4),
              'mesh_validation':'DISABLED_BY_USER','gain_basis':'ACCEPTED_POWER_GAIN',
              'feed_gap_mm':gap,'status':'GEOMETRY_CREATED'}
    evidence['frequency']=spec['frequency']
    evidence['mesh_resource_setting']='Hex 8 cells/wavelength and model box; thin PEC merging; ratio limit 5; no convergence claim'
    save(p,path)
    if solve:
        run(p)
        logpath=path.with_suffix('')/'Result'/'Model.log'
        log=logpath.read_text(errors='replace') if logpath.exists() else ''
        # CST appends runs to Model.log; older failures are not this run.
        log=log.rsplit('Solver started at:',1)[-1]
        evidence['status']='SOLVER_COMPLETED' if 'solver finished successfully' in log and '*** Error ***' not in log else 'SOLVER_FAILED'
        save(p,path)
    path.with_suffix('.geometry.json').write_text(json.dumps(evidence,indent=2))
    if evidence['status']=='SOLVER_FAILED':raise RuntimeError('Inspect actual CST Model.log')
    return app,p

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--run',action='store_true')
    parser.add_argument('--upper-patch-diameter',type=float)
    parser.add_argument('--choke-depth',type=float)
    parser.add_argument('--cup-depth',type=float)
    parser.add_argument('--broadband-validation',action='store_true')
    parser.add_argument('--reference-band',choices=['L5','L1','1207'],default='L5')
    parser.add_argument('--output',default=str(ROOT/'projects/LBAND_GNSS_INITIAL.cst'))
    args=parser.parse_args();spec=yaml.safe_load((ROOT/'specs/lband_gnss.yaml').read_text())
    if args.upper_patch_diameter is not None:
        spec['dimensions']['upper_patch_diameter']['value']=args.upper_patch_diameter
    if args.choke_depth is not None:
        spec['dimensions']['choke_depth']['value']=args.choke_depth
    if args.cup_depth is not None:
        spec['dimensions']['cup_depth']['value']=args.cup_depth
    if args.broadband_validation:
        spec['frequency']['initial_solve_ghz']=[1.164,1.588]
        spec['frequency']['initial_monitors_ghz']=[1.164,1.17645,1.189,1.207,1.563,1.57542,1.588]
    elif args.reference_band=='L1':
        spec['frequency']['initial_solve_ghz']=[1.55,1.60]
        spec['frequency']['initial_monitors_ghz']=[1.563,1.57542,1.588]
    elif args.reference_band=='1207':
        spec['frequency']['initial_solve_ghz']=[1.19,1.225]
        spec['frequency']['initial_monitors_ghz']=[1.195,1.207,1.219]
    build(spec,args.output,args.run)
