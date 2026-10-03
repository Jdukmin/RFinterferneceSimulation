"""Extract the CST Ka feed's accepted-power RHCP/LHCP gain cuts (feed boresight +Z)."""
import argparse,json
from pathlib import Path
import numpy as np
from cst_com_common import connect_cst,get_active_project,method
from cst_com import ROOT,save
from cst_results import s_matrix,active_reflection,farfield_complex
from verify_sband_results import tree_paths
from generate_ka_feed import MONITORS

PHASES=[0,-90,-180,-270];LABEL='RHCP_INTENDED'

def extract(p,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    f,s=s_matrix(p);active=active_reflection(s,PHASES)
    np.savez(out/'s_matrix.npz',frequency_ghz=f,s=s,active_gamma=active,phases_deg=PHASES)
    obj=method(p,'CombineResults');method(obj,'Reset')
    method(obj,'SetMonitorType','frequency');method(obj,'FarfieldsOnly',True)
    method(obj,'EnableAutomaticLabeling',False);method(obj,'SetLabel',LABEL)
    for i,ph in enumerate(PHASES):method(obj,'SetPortModeValues',i+1,1,1.0,ph)
    method(obj,'Run');paths=tree_paths(p);feed={}
    for freq in MONITORS:
        m=[x for x in paths if f'f={freq:g})' in x and LABEL in x]
        if len(m)!=1:raise ValueError(f'missing combined monitor {freq}: {m}')
        rows=farfield_complex(p,m[0]);idx=int(np.argmin(abs(f-freq)))
        accepted=1-float(np.mean(abs(active[idx])**2));corr=-10*np.log10(accepted)
        cut={}
        for plane in ['XZ','YZ']:
            sel=[r for r in rows if r['plane']==plane]
            cut[plane]={'theta':[r['theta'] for r in sel],
                        'rhcp_dbi':[r['cp_plus_db']+corr for r in sel],
                        'lhcp_dbi':[r['cp_minus_db']+corr for r in sel],
                        'axial_ratio_db':[r['axial_ratio_db'] for r in sel]}
        rl=-20*np.log10(np.maximum(abs(active[idx]),1e-15))
        feed[f'{freq:g}']={'accepted_power_fraction':accepted,'active_return_loss_db':rl.tolist(),'cuts':cut}
    (out/'feed_pattern.json').write_text(json.dumps(feed))
    return feed

if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('project');args=a.parse_args()
    project=Path(args.project).resolve()
    if not project.exists():raise SystemExit(f'Project not found: {project}')
    app=connect_cst(False);p=method(app,'OpenFile',str(project))
    if p is None:p=get_active_project(app)
    feed=extract(p,ROOT/'results'/project.stem);save(p,project)
    for k,v in feed.items():
        c=v['cuts']['XZ'];t=np.array(c['theta']);g=np.array(c['rhcp_dbi'])
        hp=[x for x in range(0,90) if g[x]<g[0]-3][:1]
        print(k,'GHz RHCP0',round(g[0],2),'XPD0',round(g[0]-c['lhcp_dbi'][0],1),'-3dB@',hp,'-10dB@',[x for x in range(0,90) if g[x]<g[0]-10][:1],
              'acc',round(v['accepted_power_fraction'],3),'RL',[round(x,1) for x in v['active_return_loss_db']])
