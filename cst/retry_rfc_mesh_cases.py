"""Try further mesh-resource adjustments without changing antenna geometry.

Coarser results are explicitly preliminary; no mesh-convergence PASS is issued.
Only newly generated RFC projects with a MESH_LIMIT status may be changed.
"""
import argparse,json,time
from run_rfc_frequency_cases import (ROOT,OUT,BANDS,connect_cst,method,add_to_history,
    mesh_resource,preflight,save,run,export,dump,model_log)

def retry(name,ratio=10):
    if not name.startswith('RFC_'):raise ValueError('Only new RFC candidate projects are mutable')
    out=OUT/name;statuspath=out/'status.json';record=json.loads(statuspath.read_text())
    if record['status']!='MESH_LIMIT':return record
    path=ROOT/'projects'/f'{name}.cst'
    app=connect_cst(False);p=method(app,'OpenFile',str(path))
    if p is None:p=method(app,'Active3D')
    for steps in [5,4]:
        mesh_resource(p,steps)
        add_to_history(p,'Additional ratio resource setting',f'Mesh.RatioLimit "{ratio}"')
        mesh=preflight(p);mesh.update(steps_per_wavelength=steps,ratio_limit=ratio)
        record['mesh_attempts'].append(mesh);dump(statuspath,record)
        print(json.dumps({'case':name,'preflight':mesh}),flush=True)
        if mesh['mesh_cells']<100000:break
    save(p,path)
    if mesh['mesh_cells']>=100000:return record
    record.update(status='SOLVING',mesh_quality='PRELIMINARY_COARSE_MESH_NOT_CONVERGED')
    dump(statuspath,record)
    started=time.monotonic();run(p);record['solver_runtime_s']=time.monotonic()-started
    record['actual_solver_log']=model_log(path)
    if record['actual_solver_log']['successful_excitations']!=4 or record['actual_solver_log']['errors']:
        record['status']='FAILED';dump(statuspath,record);raise RuntimeError('Actual solver did not finish correctly')
    if record['actual_solver_log']['mesh_cells']!=[mesh['mesh_cells']]:
        raise RuntimeError('Actual solver mesh differs from preflight')
    BANDS[record['band']]=record['monitor_frequencies_ghz']
    record['patterns']=export(p,record['family'],record['band'],out)
    save(p,path);record['status']='SOLVED';dump(statuspath,record)
    print(json.dumps({'case':name,'status':'SOLVED','cells':mesh['mesh_cells'],
        'seconds':record['solver_runtime_s'],'quality':record['mesh_quality']}),flush=True)
    return record

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('cases',nargs='+')
    parser.add_argument('--ratio',type=int,choices=[10,12,20],default=10)
    args=parser.parse_args()
    for name in args.cases:retry(name,args.ratio)
