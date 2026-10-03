"""Accepted-power RHCP evaluation of an X-band ISL candidate vs the ASSUMED template.

No source data exist for ISL: every reference point is ASSUMED, so there are no
hard anchors. Judged quantities: 0..60 deg MAE and HPBW. Active return loss and
axial ratio are diagnostics. Mesh verification is disabled by user instruction.
"""
import argparse,csv,json,math
from pathlib import Path
import numpy as np
import yaml
from cst_com_common import connect_cst,get_active_project,method
from cst_com import ROOT,save
from cst_results import s_matrix,active_reflection,farfield_complex
from verify_sband_results import tree_paths
from rfc_validation import export_screening

SPEC=yaml.safe_load((ROOT/'specs/xband_isl.yaml').read_text(encoding='utf-8'))
ACC=SPEC['acceptance'];PHASES=[0,-90,-180,-270];LABEL='RHCP_INTENDED'
F=SPEC['assumptions'][0]['value'];FREQS=[F['fmin_ghz'],F['f0_ghz'],F['fmax_ghz']]
Q=SPEC['reference']['q'];G0=SPEC['reference']['peak_dbi'];FLOOR=-10.0

def template(theta):
    """ASSUMED G0 + cos^q power template (ISL-A3/A3b); -inf beyond 90 deg."""
    t=np.radians(np.minimum(theta,360-np.asarray(theta)))
    c=np.cos(t)
    return np.where(c>1e-9,G0+10*Q*np.log10(np.maximum(c,1e-12)),-np.inf)

def conservative(theta):
    return np.maximum(template(theta),FLOOR)   # ISL-A4

def hpbw(theta,gain):
    a=np.where(theta<=180,theta,theta-360).astype(float);o=np.argsort(a);a=a[o];g=np.asarray(gain)[o]
    i0=int(np.argmin(abs(a)));main=np.abs(a)<=90;ipk=int(np.argmax(np.where(main,g,-1e9)));half=g[ipk]-3.0
    def edge(step):
        i=ipk
        while 0<=i+step<len(a) and g[i+step]>=half:i+=step
        if not 0<=i+step<len(a):return a[i]
        j=i+step;return a[i]+(a[j]-a[i])*(g[i]-half)/(g[i]-g[j])
    left,right=edge(-1),edge(1)
    return {'hpbw_deg':float(right-left),'left_deg':float(left),'right_deg':float(right),
            'peak_angle_deg':float(a[ipk]),'peak_dbi':float(g[ipk]),'boresight_dbi':float(g[i0])}

def model_log(project):
    log=Path(str(project).removesuffix('.cst'))/'Result'/'Model.log'
    if not log.exists():return {}
    run=log.read_text(errors='replace').rsplit('Solver started at',1)[-1]
    import re
    return {'mesh_cells':sorted({int(x) for x in re.findall(r'Number of mesh cells:\s+(\d+)',run)}),
            'warnings':sorted(set(re.findall(r'\*\*\* Warning \*\*\*\s+[\d\- :]+\s+([^\r\n]+)',run))),
            'errors':sorted(set(re.findall(r'\*\*\* Error \*\*\*\s+[\d\- :]+\s+([^\r\n]+)',run))),
            'successful_excitations':run.count('solver finished successfully')}

def verify(p,out,project):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    f,s=s_matrix(p);active=active_reflection(s,PHASES)
    rl=-20*np.log10(np.maximum(abs(active),1e-15))
    np.savez(out/'s_matrix.npz',frequency_ghz=f,s=s,active_gamma=active,phases_deg=PHASES)
    obj=method(p,'CombineResults');method(obj,'Reset')
    method(obj,'SetMonitorType','frequency');method(obj,'FarfieldsOnly',True)
    method(obj,'EnableAutomaticLabeling',False);method(obj,'SetLabel',LABEL)
    for i,ph in enumerate(PHASES):method(obj,'SetPortModeValues',i+1,1,1.0,ph)
    method(obj,'Run');paths=tree_paths(p)
    (out/'farfield_tree.json').write_text(json.dumps(paths,indent=2))
    report={'candidate':out.name,'gain_basis':'ACCEPTED_POWER_RHCP_GAIN','reference':f'ASSUMED template G0={G0:.2f} dBi, q={Q:.3f} (ISL-A3/A3b); no hard anchors',
            'solver':model_log(project),'mesh_validation':'DISABLED_BY_USER','cuts':{}}
    for freq in FREQS:
        m=[x for x in paths if f'f={freq:g})' in x and LABEL in x]
        if len(m)!=1:raise ValueError(f'Combined monitor missing for {freq}: {m}')
        rows=farfield_complex(p,m[0]);idx=int(np.argmin(abs(f-freq)))
        accepted=1-float(np.mean(abs(active[idx])**2))
        if accepted<=0:raise ValueError('Nonpositive accepted power')
        corr=-10*np.log10(accepted)
        for plane in ['XZ','YZ']:
            sel=[dict(r) for r in rows if r['plane']==plane]
            theta=np.array([r['theta'] for r in sel])
            ref=template(theta);cons=conservative(theta)
            for r,rv,cv in zip(sel,ref,cons):
                r['raw_realized_total_gain']=r['gain'];r['gain']=r['cp_plus_db']+corr
                r['assumed_template_gain']=float(rv) if np.isfinite(rv) else None
                r['target_gain']=float(cv)   # conservative envelope used by export_screening
            g=np.array([r['gain'] for r in sel]);cov=np.minimum(theta,360-theta)<=ACC['coverage_deg']
            err=g[cov]-ref[cov];beam=hpbw(theta,g)
            shape=(g[cov]-g.max())-(ref[cov]-ref[np.isfinite(ref)].max())
            ar=np.array([r['axial_ratio_db'] for r in sel])
            hp_ok=abs(beam['hpbw_deg']-ACC['hpbw_target_deg'])<=ACC['hpbw_relative_error']*ACC['hpbw_target_deg']
            mae=float(np.mean(abs(err)))
            report['cuts'][f'f{freq:g}_{plane}']={
                'main_mae_db':mae,'main_max_error_db':float(np.max(abs(err))),
                'shape_only_mae_db':float(np.mean(abs(shape))),
                'gain_error_at_0_db':float(err[theta[cov]==0][0]),
                'gain_error_at_60_db':float(np.mean([e for e,t in zip(err,theta[cov]) if t in (60,300)])),
                **beam,'hpbw_pass':bool(hp_ok),'mae_pass':mae<=ACC['main_mae_db'],
                'boresight_axial_ratio_db':float(ar[theta==0][0]),
                'coverage_axial_ratio_max_db':float(ar[cov].max()),
                'boresight_cp_discrimination_db':sel[0]['cp_plus_db']-sel[0]['cp_minus_db'],
                'active_return_loss_min_db':float(rl[idx].min()),'matching_role':'DIAGNOSTIC_ONLY',
                'accepted_power_fraction':accepted}
            with (out/f'accepted_power_f{freq:g}_{plane}.csv').open('w',newline='') as st:
                w=csv.DictWriter(st,fieldnames=list(sel[0]));w.writeheader();w.writerows(sel)
            (out/'_cuts').mkdir(exist_ok=True)
            json.dump(sel,(out/'_cuts'/f'f{freq:g}_{plane}.json').open('w'))
    cuts=report['cuts'].values()
    report['all_mae_pass']=all(c['mae_pass'] for c in cuts)
    report['all_hpbw_pass']=all(c['hpbw_pass'] for c in cuts)
    report['worst_mae_db']=max(c['main_mae_db'] for c in cuts)
    report['status']='ISL_ASSUMED_TEMPLATE_PASS' if report['all_mae_pass'] and report['all_hpbw_pass'] else 'NOT_PASS'
    (out/'validation.json').write_text(json.dumps(report,indent=2))
    return report

def export(out,valid):
    """Scalar 1-degree RFC export: validated main = CST; else max(CST, conservative)."""
    out=Path(out)
    for path in sorted((out/'_cuts').glob('*.json')):
        sel=json.loads(path.read_text())
        export_screening(sel,out/'screening_export'/f'{path.stem}.csv',coverage=ACC['coverage_deg'],main_valid=valid)

if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('project');a.add_argument('--out')
    args=a.parse_args();project=Path(args.project).resolve()
    if not project.exists():raise SystemExit(f'Project not found: {project}')
    out=Path(args.out) if args.out else ROOT/'results'/project.stem
    app=connect_cst(False);p=method(app,'OpenFile',str(project))
    if p is None:p=get_active_project(app)
    r=verify(p,out,project);save(p,project)
    for k,c in r['cuts'].items():
        print(k,f"MAE {c['main_mae_db']:.2f} shape {c['shape_only_mae_db']:.2f} pk {c['peak_dbi']:.2f} HPBW {c['hpbw_deg']:.1f} "
              f"e0 {c['gain_error_at_0_db']:+.2f} e60 {c['gain_error_at_60_db']:+.2f} AR0 {c['boresight_axial_ratio_db']:.2f} "
              f"ARcov {c['coverage_axial_ratio_max_db']:.2f} RL {c['active_return_loss_min_db']:.2f}",flush=True)
    print('STATUS',r['status'],'worst MAE',round(r['worst_mae_db'],3),'solver',r['solver'],flush=True)
