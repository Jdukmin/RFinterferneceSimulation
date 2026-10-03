"""Ka reflector pattern from the CST feed + equivalent-paraboloid aperture integration.

Hard anchors: datasheet 25.5/27 GHz values at 0/0.5/0.75/1.0 deg (boresight 0.7 dB,
others 1.0 dB). 26.25 GHz is compared to the CSV band-average representative
(MAE only). Reflector stage is NON-CST (Learning Edition limits); feed is CST.
"""
import argparse,csv,json
from pathlib import Path
import numpy as np
import yaml
from ka_reflector_po import aperture_gain

ROOT=Path(__file__).resolve().parent
SPEC=yaml.safe_load((ROOT/'specs/kaband_dls.yaml').read_text(encoding='utf-8'))
SRC=SPEC['reference_audit']['primary_source']['values']
ANCH={25.5:{0:SRC['boresight_gain_dbi'][25.5]},27.0:{0:SRC['boresight_gain_dbi'][27.0]}}
for ang,v in SRC['eoc_gain_dbi'].items():
    for f in (25.5,27.0):ANCH[f][float(ang)]=v[f]
LIMIT=lambda a:0.7 if a==0 else 1.0
D=220.0

def feed_interp(feed,freq,pol='rhcp_dbi'):
    c=feed[f'{freq:g}']['cuts'];g=[]
    for plane in ['XZ','YZ']:
        t=np.array(c[plane]['theta']);v=np.array(c[plane][pol])
        g.append(10**(v[:181]/10));g.append(10**(v[[0]+list(range(359,179,-1))]/10))  # both half-cuts
    lin=np.mean(g,axis=0);psi=np.radians(np.arange(181))
    return lambda x:np.interp(x,psi,lin)

def evaluate(feed,theta_f,Ds,angles):
    Fe=D/(4*np.tan(np.radians(theta_f)/2));res={}
    for f in [25.5,26.25,27.0]:
        co=10*np.log10(np.maximum(aperture_gain(angles,f,feed_interp(feed,f),D=D,Fe=Fe,Ds=Ds),1e-30))
        x=10*np.log10(np.maximum(aperture_gain(angles,f,feed_interp(feed,f,'lhcp_dbi'),D=D,Fe=Fe,Ds=Ds),1e-30))
        res[f]=(co,x)
    return Fe,res

def score(feed,theta_f,Ds):
    a=[0,0.5,0.75,1.0];Fe,r=evaluate(feed,theta_f,Ds,a);errs={}
    for f in (25.5,27.0):
        for ang,g in zip(a,r[f][0]):errs[f'{f:g}@{ang:g}']=float(g-ANCH[f][ang])
    worst=max(abs(e)/LIMIT(float(k.split('@')[1])) for k,e in errs.items())
    return worst,errs,Fe

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('feed_label');ap.add_argument('--theta-f',type=float)
    ap.add_argument('--ds',type=float);ap.add_argument('--write',action='store_true');args=ap.parse_args()
    feed=json.loads((ROOT/'results'/args.feed_label/'feed_pattern.json').read_text())
    if args.theta_f is None:
        table=[]
        for tf in np.arange(14,46,2.0):
            for ds in [30,40,44,50,55]:
                w,e,Fe=score(feed,tf,ds);table.append((w,tf,ds,Fe,e))
        table.sort(key=lambda x:x[0])
        for w,tf,ds,Fe,e in table[:10]:print(f'worst/limit {w:.2f} theta_f {tf:.0f} Ds {ds} Fe {Fe:.0f}',{k:round(v,2) for k,v in e.items()})
        raise SystemExit
    w,e,Fe=score(feed,args.theta_f,args.ds);print('worst/limit',round(w,3),{k:round(v,2) for k,v in e.items()})
    if args.write:
        out=ROOT/'results'/f'KA_REFLECTOR_{args.feed_label}';out.mkdir(exist_ok=True)
        fine=np.round(np.arange(0,10.0001,0.05),2);full=np.arange(0,181)
        _,rf=evaluate(feed,args.theta_f,args.ds,fine);_,rc=evaluate(feed,args.theta_f,args.ds,full)
        report={'feed_project':args.feed_label,'reflector':{'D_mm':D,'theta_f_deg':args.theta_f,'Fe_mm':Fe,'Ds_mm':args.ds,
                'method':'equivalent paraboloid aperture integration, feed phase-centre focused, subreflector blockage, spillover lost',
                'stage':'NON_CST_PYTHON'},'anchor_errors_db':e,'worst_over_limit':w,
                'status':'KA_DATASHEET_ANCHOR_PASS' if w<=1 else 'NOT_PASS','gain_basis':'ACCEPTED_POWER_RHCP_GAIN',
                'mesh_validation':'DISABLED_BY_USER'}
        for f in rf:
            co,x=rf[f];g=co
            hp=2*np.interp(g[0]-3,g[::-1],fine[::-1])
            # first null / sidelobe from the full 0.05 deg grid
            d=np.diff(g);null=fine[1:-1][(d[:-1]<0)&(d[1:]>=0)][0] if np.any((d[:-1]<0)&(d[1:]>=0)) else None
            sl=[i for i in range(1,len(g)-1) if g[i]>g[i-1] and g[i]>=g[i+1]]
            report[f'f{f:g}']={'boresight_dbi':float(g[0]),'hpbw_deg':float(hp),'first_null_deg':None if null is None else float(null),
                'first_sidelobe':{'deg':float(fine[sl[0]]),'dbi':float(g[sl[0]])} if sl else None,
                'xpd_within_1deg_db':float(min(co[fine<=1.0]-x[fine<=1.0])),
                'gain_at_dbi':{str(a):float(g[np.argmin(abs(fine-a))]) for a in [0,0.5,0.75,1,1.5,2,3,4,5,6,8,10]}}
            with (out/f'fine_0p05deg_f{f:g}.csv').open('w',newline='') as st:
                w_=csv.writer(st);w_.writerow(['theta','rhcp_gain_dbi','lhcp_gain_dbi']);w_.writerows(zip(fine,np.round(co,4),np.round(x,4)))
            co1,x1=rc[f]
            with (out/f'full_1deg_f{f:g}.csv').open('w',newline='') as st:
                w_=csv.writer(st);w_.writerow(['theta','rhcp_gain_dbi','lhcp_gain_dbi']);w_.writerows(zip(full,np.round(co1,4),np.round(x1,4)))
        (out/'reflector_validation.json').write_text(json.dumps(report,indent=2))
        print(json.dumps({k:v for k,v in report.items() if k.startswith('f')},indent=1))
