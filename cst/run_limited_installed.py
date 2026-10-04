"""Learning-budget local patches: actual fields, explicitly NOT extent-converged.

The owner's mesh-budget condition permits reducing the structure extent while
keeping every antenna dimension/port unchanged. These cases do not replace the
failed R3/R4/R5 convergence requirement with a PASS.
"""
import argparse,json,time
from run_rfc_frequency_cases import (ROOT,OUT,BANDS,build,local_facets,add_facets,
    INSTALLATIONS,mesh_resource,preflight,save,run,export,dump,model_log,add_to_history,USAGE_ROLES)

def low_monitors():
    BANDS['LOW']=sorted({f for key in ['S_TM','S_TC','L1','L2','L5'] for f in BANDS[key]})

def calculate(family,installation=None,radius=None,profile=None,profile_ratio=10,x_radius=None):
    low_monitors()
    suffix=f'{installation}_R{str(radius).replace(".","P")}' if installation else f'FREE_M{profile}R{profile_ratio}'
    if installation and x_radius is not None:suffix+=f'_X{str(x_radius).replace(".","P")}'
    name=f'RFC_{family}_LOW_{suffix}';out=OUT/name;out.mkdir(parents=True,exist_ok=True)
    statuspath=out/'status.json';path=ROOT/'projects'/f'{name}.cst'
    if statuspath.exists():
        old=json.loads(statuspath.read_text())
        if old['status'] in ['SOLVED','MESH_LIMIT']:return old
    if path.exists():raise FileExistsError(f'Inspect unfinished {name}')
    record={'case':name,'family':family,'band':'LOW','monitor_frequencies_ghz':BANDS['LOW'],
        'rf_usage_roles':USAGE_ROLES[family],
        'installation':installation,'geometry_changed':False,'status':'BUILDING',
        'edition':'CST Studio Suite 2026 Learning Edition','solver':'Time Domain',
        'mesh_attempts':[],'mesh_convergence':'NOT_ESTABLISHED',
        'extent_convergence':'NOT_ESTABLISHED; R3 cannot fit; smaller budget-limited patch',
        'provenance':'CST_LEARNING_LOCAL_SCATTERING_APPROX' if installation else 'CST_FIXED_GEOMETRY_PORT_RESPONSE',
        'angular_sampling':'independent 1-degree XZ/YZ cuts; no installed axisymmetry assumption',
        'quality':'PRELIMINARY_LEARNING_BUDGET_LIMITED_NOT_EXTENT_VALIDATED'}
    dump(statuspath,record)
    app,p,params,solve_range=build(family,'LOW',path)
    record.update(parameters=params,solve_range_ghz=solve_range)
    if installation:
        ref=2.25 if family=='S' else 1.57542
        geometry=local_facets(installation,ref,radius,x_radius_lambda=x_radius)
        required=[INSTALLATIONS[installation][2]]+([8] if family=='S' else [])
        if any(panel not in geometry['included_panels'] for panel in required):
            record.update(status='LOCAL_EXTENT_INFEASIBLE',local_geometry=geometry)
            dump(statuspath,record);return record
        add_facets(p,geometry);record['local_geometry']=geometry
    for steps in ([profile] if profile is not None else [8,6,5,4]):
        mesh_resource(p,steps)
        ratio=profile_ratio if profile is not None else (10 if steps<=5 else 5)
        add_to_history(p,'Budget ratio setting',f'Mesh.RatioLimit "{ratio}"')
        mesh=preflight(p);mesh.update(steps_per_wavelength=steps,ratio_limit=ratio)
        record['mesh_attempts'].append(mesh);dump(statuspath,record)
        print(json.dumps({'case':name,'preflight':mesh}),flush=True)
        if mesh['mesh_cells']<100000:break
    save(p,path)
    if mesh['mesh_cells']>=100000:
        record['status']='MESH_LIMIT';dump(statuspath,record);return record
    record['status']='SOLVING';dump(statuspath,record)
    started=time.monotonic();run(p);record['solver_runtime_s']=time.monotonic()-started
    record['actual_solver_log']=model_log(path)
    if record['actual_solver_log']['successful_excitations']!=4 or record['actual_solver_log']['errors']:
        record['status']='FAILED';dump(statuspath,record);raise RuntimeError('Solver failure')
    if record['actual_solver_log']['mesh_cells']!=[mesh['mesh_cells']]:raise RuntimeError('Mesh count mismatch')
    record['patterns']=export(p,family,'LOW',out);save(p,path)
    record['status']='SOLVED';dump(statuspath,record)
    print(json.dumps({'case':name,'status':'SOLVED','cells':mesh['mesh_cells'],
        'seconds':record['solver_runtime_s'],'quality':record['quality']}),flush=True)
    if installation:
        profile=mesh['steps_per_wavelength']
        record['matched_free_case']=calculate(family,profile=profile,profile_ratio=mesh['ratio_limit'])['case']
        dump(statuspath,record)
    return record

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--all',action='store_true')
    parser.add_argument('--installation',choices=list(INSTALLATIONS),default='SBA_ZENITH')
    parser.add_argument('--radius',type=float)
    parser.add_argument('--x-radius',type=float)
    args=parser.parse_args()
    names=list(INSTALLATIONS) if args.all else [args.installation]
    for name in names:
        family=INSTALLATIONS[name][3]
        calculate(family,name,args.radius if args.radius is not None else (1.75 if family=='S' else 1.25),x_radius=args.x_radius)
