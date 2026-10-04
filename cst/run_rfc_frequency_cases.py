"""Fixed-geometry port-driven RFC cases; preflight before every Time Domain run.

Never overwrite baseline projects. Sheet syntax and mesh getters come from
installed CST macros; (Nx-1)*(Ny-1)*(Nz-1) was checked against the 29,988-cell
ISL_FIXED_10G6 solver log. Records skipped cases instead of inventing patterns.
"""
import argparse,csv,json,math,time
from pathlib import Path
import numpy as np
import yaml
from cst_com import ROOT,new_project,monitor,save,run
from cst_com_common import method,add_to_history,connect_cst
from cst_results import s_matrix,active_reflection,farfield_complex
from verify_sband_results import tree_paths
from verify_isl_results import model_log,hpbw
from local_scattering.geometry import local_facets,add_facets,INSTALLATIONS

BANDS={
 'S_TM':[2.2,2.25,2.3], 'S_TC':[2.,2.06,2.12],
 'L1':[1.563,1.57542,1.588], 'L2':[1.21737,1.2276,1.23783],
 'L5':[1.164,1.17645,1.189], 'ISL':[10.55,10.6,10.65],
 'SAR':[8.9,9.65,10.4], 'KA':[25.5,26.25,27.]}
OUT=ROOT/'results/rfc_frequency_cases'
USAGE_ROLES={'S':['TX','RX'],'L':['RX'],'ISL':['TX','RX'],'KA':['TX']}

def dump(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(value,indent=2),encoding='utf-8')

def mesh_resource(p,steps):
    add_to_history(p,f'Mesh resource {steps}',f'''With Mesh
 .MergeThinPECLayerFixpoints "True"
 .RatioLimit "5"
End With
With MeshSettings
 .SetMeshType "Hex"
 .Set "StepsPerWaveNear", "{steps}"
 .Set "StepsPerWaveFar", "{steps}"
 .Set "StepsPerBoxNear", "{steps}"
 .Set "StepsPerBoxFar", "{steps}"
End With''')

def preflight(p):
    mesh=method(p,'Mesh');method(mesh,'Update')
    dimensions=[int(method(mesh,'GetN'+a)) for a in ['x','y','z']]
    if min(dimensions)<2:raise RuntimeError('Mesh update did not provide valid lines')
    lines=[np.array([method(mesh,'Get'+a,i) for i in range(n)],float)
           for a,n in zip('XYZ',dimensions)]
    differences=np.concatenate([np.diff(v) for v in lines])
    return {'mesh_cells':math.prod(n-1 for n in dimensions),'mesh_line_counts':dimensions,
        'bounding_box_mm':[[float(v[0]),float(v[-1])] for v in lines],
        'min_mesh_step_mm':float(differences.min()),'max_mesh_step_mm':float(differences.max())}

def build(family,band,path):
    frequencies=BANDS[band];lo=min(frequencies);hi=max(frequencies)
    solve_range=[max(.01,lo-.01),hi+.01]
    if family=='S':
        from generate_sband_ttc import build as sbuild
        params=json.loads((ROOT/'specs/sband_matching_wire15.json').read_text())
        app,p=sbuild(params,path,frequency_range=solve_range,monitor_frequencies=frequencies)
    elif family=='L':
        from generate_lband_gnss import build as lbuild
        params=json.loads((ROOT/'projects/LBAND_GNSS_FINAL_COMPROMISE.geometry.json').read_text())['parameters']
        spec=yaml.safe_load((ROOT/'specs/lband_gnss.yaml').read_text())
        for k,v in params.items():spec['dimensions'][k]['value']=v
        spec['frequency']['initial_solve_ghz']=solve_range
        spec['frequency']['initial_monitors_ghz']=frequencies
        app,p=lbuild(spec,path)
    else:
        from generate_isl import cup_patch
        params=json.loads((ROOT/'tools/commands/ISL_C4_CUP_R14P7/candidate.json').read_text())['inputs']
        app,p=new_project(*solve_range);cup_patch(p,params)
        for frequency in frequencies:monitor(p,frequency)
        save(p,path)
    return app,p,params,solve_range

def export(p,family,band,out):
    phases=[0,90,180,270] if family=='S' else [0,-90,-180,-270]
    frequencies,s=s_matrix(p);gamma=active_reflection(s,phases)
    np.savez(out/'s_matrix.npz',frequency_ghz=frequencies,s=s,active_gamma=gamma,phases_deg=phases)
    combine=method(p,'CombineResults');method(combine,'Reset')
    method(combine,'SetMonitorType','frequency');method(combine,'FarfieldsOnly',True)
    method(combine,'EnableAutomaticLabeling',False);method(combine,'SetLabel','RFC_FIXED_PORTS')
    for i,phase in enumerate(phases):method(combine,'SetPortModeValues',i+1,1,1.,phase)
    method(combine,'Run');paths=tree_paths(p)
    report={}
    for freq in BANDS[band]:
        matches=[v for v in paths if f'f={freq:g})' in v and 'RFC_FIXED_PORTS' in v]
        if len(matches)!=1:raise RuntimeError(f'Farfield missing {freq}: {matches}')
        rows=farfield_complex(p,matches[0])
        idx=int(np.argmin(abs(frequencies-freq)));accepted=1-float(np.mean(abs(gamma[idx])**2))
        passivity_error=max(0,float(np.linalg.svd(s[idx],compute_uv=False).max())**2-1)
        reliable=accepted>max(1e-6,5*passivity_error)
        correction=-10*math.log10(accepted) if accepted>0 else None
        for row in rows:
            row['realized_gain_dbi']=row['gain']
            row['gain_dbi']=row['gain']+correction if correction is not None else None
            row['dominant_cp_gain_dbi']=row['cp_plus_db']+correction if correction is not None else None
        for plane in ['XZ','YZ']:
            sel=[r for r in rows if r['plane']==plane]
            with (out/f'f{freq:g}_{plane}.csv').open('w',newline='') as stream:
                writer=csv.DictWriter(stream,fieldnames=list(sel[0]));writer.writeheader();writer.writerows(sel)
            report[f'f{freq:g}_{plane}']={
                'accepted_power_fraction':accepted,'normalization_reliable':reliable,
                's_matrix_passivity_excess':passivity_error,
                'active_return_loss_min_db':float((-20*np.log10(np.maximum(abs(gamma[idx]),1e-15))).min()),
                'peak_realized_gain_dbi':max(r['realized_gain_dbi'] for r in sel),
                'gain_beam':hpbw(np.arange(360),[r['gain_dbi'] for r in sel]) if correction is not None else None}
    dump(out/'patterns.json',report)
    return report

def case(family,band,installation=None,radius=3):
    name=f"RFC_{family}_{band}_{installation+'_R'+str(radius) if installation else 'FREE'}"
    path=ROOT/'projects'/f'{name}.cst';out=OUT/name;out.mkdir(parents=True,exist_ok=True)
    statuspath=out/'status.json'
    if statuspath.exists():
        previous=json.loads(statuspath.read_text())
        if previous['status'] in ['SOLVED','MESH_LIMIT']:return previous
    if path.exists():raise FileExistsError(f'Inspect unfinished project before retry: {path}')
    record={'case':name,'family':family,'band':band,'monitor_frequencies_ghz':BANDS[band],
        'rf_usage_roles':USAGE_ROLES[family],
        'geometry_changed':False,'installation':installation,'solver':'Time Domain',
        'edition':'CST Studio Suite 2026 Learning Edition','status':'BUILDING',
        'provenance':'CST_LEARNING_LOCAL_SCATTERING_APPROX' if installation else 'CST_FIXED_GEOMETRY_PORT_RESPONSE',
        'frequency_limitations':'L2 center GPS 1.22760 GHz; +/-10.23 MHz from existing assumed 20.46 MHz receiver filter; no measured L2 reference; other provisional windows labelled',
        'mesh_convergence':'NOT_ESTABLISHED','angular_sampling':'independent 1-degree XZ/YZ cuts'}
    dump(statuspath,record)
    try:
        app,p,params,solve_range=build(family,band,path)
        record.update(parameters=params,solve_range_ghz=solve_range)
        if installation:
            geometry=local_facets(installation,BANDS[band][len(BANDS[band])//2],radius)
            mandatory=[INSTALLATIONS[installation][2]]+([8] if family=='S' else [])
            if any(number not in geometry['included_panels'] for number in mandatory):
                record.update(status='LOCAL_EXTENT_INFEASIBLE',local_geometry=geometry,
                    error='Requested crop cannot reach all mandatory real facets; no installed pattern generated')
                dump(statuspath,record);return record
            add_facets(p,geometry);record['local_geometry']=geometry
        record['mesh_attempts']=[]
        for steps in [8,6]:
            mesh_resource(p,steps);mesh=preflight(p);mesh['steps_per_wavelength']=steps
            record['mesh_attempts'].append(mesh);dump(statuspath,record)
            print(json.dumps({'case':name,'preflight':mesh}),flush=True)
            if mesh['mesh_cells']<100000:break
        save(p,path)
        if mesh['mesh_cells']>=100000:
            record['status']='MESH_LIMIT';dump(statuspath,record);return record
        started=time.monotonic();run(p);record['solver_runtime_s']=time.monotonic()-started
        record['actual_solver_log']=model_log(path)
        if record['actual_solver_log'].get('successful_excitations')!=4 or record['actual_solver_log'].get('errors'):
            raise RuntimeError('Solver failed or did not finish four excitations')
        actual=record['actual_solver_log']['mesh_cells']
        if actual!=[mesh['mesh_cells']]:raise RuntimeError(f'Preflight/log cell mismatch: {mesh} vs {actual}')
        record['patterns']=export(p,family,band,out);save(p,path)
        record['status']='SOLVED';dump(statuspath,record)
        print(json.dumps({'case':name,'status':'SOLVED','cells':actual,'seconds':record['solver_runtime_s']}),flush=True)
    except Exception as error:
        record.update(status='FAILED',error=str(error));dump(statuspath,record)
        raise
    return record

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--family',choices=['S','L','ISL'],default='S')
    parser.add_argument('--band',choices=list(BANDS),default='S_TM')
    parser.add_argument('--installation',choices=list(INSTALLATIONS))
    parser.add_argument('--radius',type=int,choices=[3,4,5],default=3)
    parser.add_argument('--all-free',action='store_true')
    parser.add_argument('--grouped-free',action='store_true',
        help='Reuse one TD solve per mesh-compatible low/high frequency group')
    args=parser.parse_args()
    dump(OUT/'frequency_plan.json',{'bands_ghz':BANDS,'frequency_scope':'each existing antenna at each interferer band',
        'rf_usage_roles':USAGE_ROLES,'excluded_role_jobs':['KA_RX','L_TX'],
        'installed_families':['S','L'],'free_only':['ISL','KA','SAR when data available'],
        'ka_limitation':'Existing full Ka free pattern only 25.5-27; CST ports are feed-only, not full reflector',
        'sar_limitation':'No SAR source pattern; existing other antennas can be evaluated in SAR 8.9-10.4',
        'l2':'1.22760 GHz on fixed L geometry; +/-10.23 MHz existing assumed receiver window; not the 1.207 GHz datasheet proxy'})
    if args.installation and INSTALLATIONS[args.installation][3]!=args.family:
        parser.error('Installation and family mismatch')
    if args.grouped_free:
        BANDS['LOW']=sorted({f for key in ['S_TM','S_TC','L1','L2','L5'] for f in BANDS[key]})
        BANDS['HIGH']=sorted({f for key in ['SAR','ISL'] for f in BANDS[key]})
        for family in ['S','L','ISL']:
            for band in ['LOW','HIGH','KA']:case(family,band)
    elif args.all_free:
        for family in ['S','L','ISL']:
            for band in BANDS:case(family,band)
    else:case(args.family,args.band,args.installation,args.radius)

if __name__=='__main__':main()
