"""Ordered coordinate sweeps; geometry is rebuilt deterministically per candidate."""
import json
from pathlib import Path
import yaml
from cst_com import ROOT,save
from generate_sband_ttc import build
from verify_sband_results import verify

def pattern_score(reports):
    # Select SBA1 as primary; report SBA4 independently rather than mixing products.
    r=[v for k,v in reports.items() if k.startswith('SBA1')]
    return sum(v['coverage_rmse_db']+0.5*v['peak_error_db'] for v in r)/len(r)

def main():
    spec=yaml.safe_load((ROOT/'specs/sband_ttc.yaml').read_text())
    v={k:d['value'] for k,d in spec['dimensions'].items() if isinstance(d['value'],(int,float))}
    initial=json.loads((ROOT/'results/sband_initial/summary.json').read_text())
    best=pattern_score(initial);current=dict(v);records=[]
    stages=[('A_diameter','helix_diameter',[12,21]),
            ('B_pitch','helix_height',[45,75]),
            ('C_length','turns',[0.5,1.0])]
    for stage,key,values in stages:
        stage_best=best;stage_v=dict(current)
        for value in values:
            candidate=dict(current);candidate[key]=value
            label=f'SBAND_{stage}_{value:g}'
            path=ROOT/'projects'/f'{label}.cst';out=ROOT/'results'/label
            print('CANDIDATE',label,candidate,flush=True)
            if (out/'summary.json').exists():reports=json.loads((out/'summary.json').read_text())
            else:
                app,p=build(candidate,path,True);reports=verify(p,out);save(p,path)
            score=pattern_score(reports)
            records.append({'label':label,'parameters':candidate,'pattern_score':score})
            print('SCORE',label,score,flush=True)
            if score<stage_best:stage_best=score;stage_v=candidate
            (ROOT/'results/sband_tuning.json').write_text(json.dumps({'initial_score':pattern_score(initial),'best_score':stage_best,'current':stage_v,'records':records},indent=2))
        current=stage_v;best=stage_best

if __name__=='__main__':main()
