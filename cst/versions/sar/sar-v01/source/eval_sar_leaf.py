"""X-band SAR leaf evaluation (CST) + illustrative analytic array (NON-CST).

Leaf gates (owner: beamwidth is an array property, not a leaf gate): broadside peak,
Ludwig-3 co/cross-pol at broadside, resonance placement (S11 minimum) reported.
Return loss is diagnostic (accepted-power gain basis). Array pattern = leaf cut x
Taylor array factor (SAR-A4/A5), reported as an example only.
"""
import argparse,csv,json,math
from pathlib import Path
import numpy as np
import yaml
from cst_com_common import connect_cst,get_active_project,method
from cst_com import ROOT,save
from cst_results import s_matrix,farfield_complex,active_reflection
from verify_sband_results import tree_paths
from generate_sar_leaf import MONITORS

SPEC=yaml.safe_load((ROOT/'specs/xband_sar.yaml').read_text(encoding='utf-8'))
NX,NY,D=80,13,28.106

def taylor(N,sll=25,nbar=4):
    A=np.arccosh(10**(sll/20))/np.pi;s2=nbar**2/(A**2+(nbar-0.5)**2)
    x=(np.arange(N)-(N-1)/2)/N;w=np.ones(N)
    for m in range(1,nbar):
        F=(-1)**(m+1)*np.prod([1-m**2/s2/(A**2+(n-0.5)**2) for n in range(1,nbar)])/(2*np.prod([1-m**2/n**2 for n in range(1,nbar) if n!=m]))
        w+=2*F*np.cos(2*np.pi*m*x)
    return w/w.max()

def af_db(theta_deg,N,f):
    lam=299.792458/f;k=2*np.pi/lam;w=taylor(N);x=(np.arange(N)-(N-1)/2)*D
    t=np.radians(theta_deg);a=np.abs(np.exp(1j*k*np.outer(np.sin(t),x))@w)**2
    return 10*np.log10(np.maximum(a/(w.sum()**2),1e-30)),w

def hpbw(theta,g):
    i=np.argmax(g<g[0]-3);return 2*float(np.interp(g[0]-3,[g[i],g[i-1]],[theta[i],theta[i-1]]))

def evaluate(p,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    n=int(method(method(p,'Port'),'StartPortNumberIteration'))
    f,s=s_matrix(p,n);phases=[0,180][:n]
    if n>1:
        active=active_reflection(s,phases)
        obj=method(p,'CombineResults');method(obj,'Reset');method(obj,'SetMonitorType','frequency')
        method(obj,'FarfieldsOnly',True);method(obj,'EnableAutomaticLabeling',False);method(obj,'SetLabel','LEAF_DIFF')
        for i,ph in enumerate(phases):method(obj,'SetPortModeValues',i+1,1,1.0,ph)
        method(obj,'Run');tag='LEAF_DIFF'
    else:active=s[:,:,0];tag='[1]'
    s11=active[:,0];rl=-20*np.log10(np.maximum(abs(s11),1e-15))
    np.savez(out/'s_matrix.npz',frequency_ghz=f,s=s,active_gamma=active,phases_deg=phases)
    paths=tree_paths(p);report={'leaf':{'s11_min_db':float(-rl.max()),'s11_min_freq_ghz':float(f[np.argmax(rl)]),
        'return_loss_role':'DIAGNOSTIC_ONLY'},'array_example':{'stage':'NON_CST_ANALYTIC',
        'layout':f'{NX} x {NY}, {D} mm, Taylor -25 dB'},'mesh_validation':'DISABLED_BY_USER'}
    for freq in MONITORS:
        m=[x for x in paths if f'f={freq:g})' in x and tag in x]
        if len(m)!=1:raise ValueError(f'monitor {freq}: {m}')
        rows=farfield_complex(p,m[0]);idx=int(np.argmin(abs(f-freq)));acc=1-float(np.mean(abs(active[idx])**2))
        corr=-10*np.log10(acc);cuts={}
        for plane,co_key in [('XZ','etheta'),('YZ','ephi')]:
            sel=[r for r in rows if r['plane']==plane];co=[];xp=[]
            for r in sel:
                et=abs(complex(r['etheta_re'],r['etheta_im']))**2;ep=abs(complex(r['ephi_re'],r['ephi_im']))**2
                tot=10**(r['gain']/10)/max(et+ep,1e-30)   # Abs = linear total gain (realized)
                c,x=(et,ep) if co_key=='etheta' else (ep,et)
                co.append(10*np.log10(max(c*tot,1e-30))+corr);xp.append(10*np.log10(max(x*tot,1e-30))+corr)
            cuts[plane]=(np.array([r['theta'] for r in sel]),np.array(co),np.array(xp))
        th=np.arange(0,91);leafr={}
        for plane,(t,co,xp) in cuts.items():
            half=co[:91];leafr[plane]={'broadside_dbi':float(co[0]),'peak_angle_deg':int(np.argmax(np.where(np.minimum(t,360-t)<=90,co,-1e9))),
                'hpbw_deg':hpbw(th,half),'xpol_broadside_db':float(co[0]-xp[0]),
                'front_to_back_db':float(co[0]-co[180])}
        fine=np.round(np.arange(0,20.0001,0.01),2);arr={}
        for plane,N in [('XZ',NX),('YZ',NY)]:
            t,co,_=cuts[plane];e=np.interp(fine,np.arange(0,91),co[:91])-co[0]
            a,w=af_db(fine,N,freq);arr[plane]={'hpbw_deg':hpbw(fine,a+e),
                'first_sidelobe_db':float(max((a+e)[fine>hpbw(fine,a+e)])) }
        lam=299.792458/freq;eta=taylor(NX).sum()**2/NX/(taylor(NX)**2).sum()*taylor(NY).sum()**2/NY/(taylor(NY)**2).sum()
        arr['gain_aperture_dbi']=10*math.log10(4*math.pi*NX*NY*D*D/lam**2*eta)
        arr['gain_leaf_crosscheck_dbi']=float((cuts['XZ'][1][0]+cuts['YZ'][1][0])/2+10*math.log10(NX*NY*eta))
        report[f'f{freq:g}']={'leaf':leafr,'accepted_power_fraction':float(acc),'return_loss_db':float(rl[idx]),'array_example':arr}
        with (out/f'leaf_f{freq:g}.csv').open('w',newline='') as st:
            w_=csv.writer(st);w_.writerow(['theta','XZ_co_dbi','XZ_x_dbi','YZ_co_dbi','YZ_x_dbi'])
            w_.writerows(zip(range(360),*(np.round(v,4) for pl in ['XZ','YZ'] for v in cuts[pl][1:])))
    ok=all(report[f'f{fr:g}']['leaf'][pl]['peak_angle_deg']==0 and report[f'f{fr:g}']['leaf'][pl]['xpol_broadside_db']>=SPEC['acceptance']['leaf_xpol_broadside_db']
           for fr in MONITORS for pl in ['XZ','YZ'])
    report['status']='SAR_LEAF_PASS' if ok and 7.85<=report['leaf']['s11_min_freq_ghz']<=8.15 else 'SAR_LEAF_NOT_PASS'
    (out/'validation.json').write_text(json.dumps(report,indent=2));return report

if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('project');args=a.parse_args();project=Path(args.project).resolve()
    if not project.exists():raise SystemExit(f'Project not found: {project}')
    app=connect_cst(False);p=method(app,'OpenFile',str(project))
    if p is None:p=get_active_project(app)
    r=evaluate(p,ROOT/'results'/project.stem);save(p,project)
    print(json.dumps(r,indent=1))
