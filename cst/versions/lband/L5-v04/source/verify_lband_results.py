"""Fixed RHCP, accepted-power L5 surrogate validation; mesh disabled."""
import argparse,csv,json
from pathlib import Path
import numpy as np
from cst_com_common import connect_cst,get_active_project,method
from cst_com import ROOT,save
from cst_results import s_matrix,active_reflection,farfield_complex,compare
from verify_sband_results import tree_paths
from rfc_validation import metrics,source_reference_metrics,export_screening

def verify(p,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    phases=[0,-90,-180,-270]
    f,s=s_matrix(p);active=active_reflection(s,phases)
    rl=-20*np.log10(np.maximum(abs(active),1e-15))
    np.savez(out/'s_matrix.npz',frequency_ghz=f,s=s,active_gamma=active,phases_deg=phases)
    obj=method(p,'CombineResults');method(obj,'Reset')
    method(obj,'SetMonitorType','frequency');method(obj,'FarfieldsOnly',True)
    method(obj,'EnableAutomaticLabeling',False);method(obj,'SetLabel','RHCP_INTENDED')
    for i,phase in enumerate(phases):method(obj,'SetPortModeValues',i+1,1,1.0,phase)
    method(obj,'Run');paths=tree_paths(p);report={}
    (out/'farfield_tree.json').write_text(json.dumps(paths,indent=2))
    for freq in [1.164,1.17645,1.189]:
        matches=[item for item in paths if f'f={freq:g})' in item and 'RHCP_INTENDED' in item]
        if len(matches)!=1:raise ValueError(f'Combined monitor missing: {freq}')
        rows=farfield_complex(p,matches[0]);idx=np.argmin(abs(f-freq))
        accepted=1-float(np.mean(abs(active[idx])**2))
        if accepted<=0:raise ValueError('Nonpositive accepted power')
        correction=-10*np.log10(accepted)
        for plane in ['XZ','YZ']:
            selected=[dict(r) for r in rows if r['plane']==plane]
            target=ROOT.parent/'data/Lband_GPS'/f'Extended_GNSS_PEC_L5_1176MHz_{plane}.csv'
            frequency_label=f'{freq:g}'.replace('.','p')
            compare(selected,target,out/f'raw_realized_f{frequency_label}_{plane}')
            with target.open() as stream:reference={int(r['theta']):float(r['gain']) for r in csv.DictReader(stream)}
            for row in selected:
                row['raw_realized_gain']=row['gain']
                row['gain']=row['cp_plus_db']+correction
                row['target_gain']=reference[int(row['theta'])]
            theta=[r['theta'] for r in selected];g=[r['gain'] for r in selected];ref=[r['target_gain'] for r in selected]
            m=metrics(theta,g,ref)
            error=max(0,float(np.linalg.svd(s[idx],compute_uv=False).max())**2-1)
            anchors=[{'theta_deg':angle,'provenance':'PUBLIC_DATASHEET',
                      'confidence':'B','kind':'APPROXIMATED_UPPER_ENVELOPE_SAMPLE',
                      'limit_db':1.0 if angle==0 else (1.5 if angle in (60,90) else 2.0)}
                     for angle in range(0,91,10)]
            report[f'f{freq:g}_{plane}']={'gain_basis':'ACCEPTED_POWER_RHCP_GAIN',
                'metrics':m,'source_comparison':source_reference_metrics(theta,g,ref,anchors=anchors),
                'reference_limitation':'Digitized upper-envelope screening anchors, confidence B; independent lower envelope unavailable. This is not a measured point-table or source min/max interval PASS.',
                'active_return_loss_db':float(rl[idx].min()),'matching_role':'DIAGNOSTIC_ONLY',
                'accepted_power_fraction':accepted,'normalization_reliable':accepted>5*error,
                'boresight_cp_discrimination_db':selected[0]['cp_plus_db']-selected[0]['cp_minus_db'],
                'coverage_axial_ratio_max_db':max(r['axial_ratio_db'] for r in selected if min(r['theta'],360-r['theta'])<=90),
                'mesh_validation':'DISABLED_BY_USER','status':'PRE_FINAL_NOT_RFC_PASS'}
            path=out/f'accepted_power_f{freq:g}_{plane}.csv'
            with path.open('w',newline='') as stream:
                writer=csv.DictWriter(stream,fieldnames=list(selected[0]));writer.writeheader();writer.writerows(selected)
            export_screening(selected,out/'provisional_screening'/f'f{freq:g}_{plane}.csv',main_valid=False)
    (out/'validation.json').write_text(json.dumps(report,indent=2))
    return report

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('project');parser.add_argument('out');args=parser.parse_args()
    app=connect_cst(False);p=method(app,'OpenFile',str(Path(args.project).resolve()))
    if p is None:p=get_active_project(app)
    for key,r in verify(p,args.out).items():print(key,r['metrics']['main_mae_db'],r['metrics']['peak_error_db'],r['boresight_cp_discrimination_db'],flush=True)
    save(p,args.project)
