"""Read complete four-port results, combine CP, and compare all S-band targets."""
import argparse,json
from pathlib import Path
import numpy as np
from cst_com_common import connect_cst,get_active_project,method
from cst_com import ROOT,quadrature,save
from cst_results import s_matrix,active_reflection,farfield_complex,compare,objective

def tree_paths(p,root='Farfields'):
    tree=method(p,'ResultTree');paths=[]
    def children(parent):
        child=method(tree,'GetFirstChildName',parent)
        while child:
            paths.append(child);children(child)
            child=method(tree,'GetNextItemName',child)
    children(root)
    return paths

def verify(p,out,frequency_robustness=False):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    f,s=s_matrix(p);active=active_reflection(s,[0,90,180,270])
    rl=-20*np.log10(np.maximum(np.abs(active),1e-15))
    np.savez(out/'s_matrix.npz',frequency_ghz=f,s=s,phases_deg=[0,90,180,270],active_gamma=active)
    np.savetxt(out/'active_return_loss.csv',np.column_stack([f,rl]),delimiter=',',header='frequency_ghz,port1_rl_db,port2_rl_db,port3_rl_db,port4_rl_db',comments='')
    print('ACTIVE RL',float(rl.min()),float(rl.max()),flush=True)
    quadrature(p)
    paths=tree_paths(p);(out/'farfield_tree.json').write_text(json.dumps(paths,indent=2));print('TREE',paths,flush=True)
    reports={}
    frequencies=[(2.06,'TC'),(2.25,'TM')]
    if frequency_robustness:frequencies=[(2.0,'TC'),(2.06,'TC'),(2.12,'TC'),(2.2,'TM'),(2.25,'TM'),(2.3,'TM')]
    for freq,band in frequencies:
        freqout=out if freq in [2.06,2.25] else out/f'f_{freq:g}'
        freqout.mkdir(parents=True,exist_ok=True)
        matches=[s for s in paths if f'f={freq:g})' in s and 'CP_QUADRATURE' in s]
        if len(matches)!=1:raise ValueError(f'Expected one combined farfield for {freq}: {matches}')
        rows=farfield_complex(p,matches[0]);idx=np.argmin(abs(f-freq));active_rl=float(rl[idx].min())
        for variant in ['SBA1','SBA4']:
            for plane in ['XZ','YZ']:
                target=ROOT.parent/'data/Sband_TMTC'/f'{variant}_{band}_{plane}.csv'
                report=compare([r for r in rows if r['plane']==plane],target,freqout/f'{variant}_{band}_{plane}')
                ar=max(r['axial_ratio_db'] for r in rows if min(r['theta'],360-r['theta'])<=85)
                report.update(active_return_loss_db=active_rl,coverage_axial_ratio_max_db=ar,
                    objective=objective(report['coverage_rmse_db'],report['peak_error_db'],active_rl,ar))
                report['frequency_ghz']=freq
                reports[f'{variant}_{band}_{plane}'+('' if freq in [2.06,2.25] else f'_f{freq:g}')]=report
    (out/'summary.json').write_text(json.dumps(reports,indent=2))
    return reports

if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('--out',default=str(ROOT/'results/sband_initial'))
    a.add_argument('--project',default=str(ROOT/'projects/SBAND_TTC_INITIAL.cst'));args=a.parse_args()
    app=connect_cst(False);p=method(app,'OpenFile',str(Path(args.project).resolve()))
    if p is None:p=get_active_project(app)
    verify(p,args.out)
