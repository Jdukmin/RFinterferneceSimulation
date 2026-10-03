"""Export actual CST S matrices and coherently combined complex farfields."""
import csv,json,math
from pathlib import Path
import numpy as np
from cst_com_common import method

def result(p,path):
    tree=method(p,'ResultTree');ids=method(tree,'GetResultIDsFromTreeItem',path)
    if not ids:raise ValueError(f'No calculated results: {path}')
    return method(tree,'GetResultFromTreeItem',path,ids[-1])

def s_matrix(p,n=4):
    spectra={};frequency=None
    for i in range(n):
        for j in range(n):
            r=result(p,rf'1D Results\S-Parameters\S{i+1},{j+1}')
            x=np.array(method(r,'GetArray','x'))
            if frequency is None:frequency=x
            elif not np.array_equal(x,frequency):raise ValueError('S matrix frequency grids differ')
            spectra[i,j]=np.array(method(r,'GetArray','yre'))+1j*np.array(method(r,'GetArray','yim'))
    return frequency,np.stack([spectra[i,j] for i in range(n) for j in range(n)],axis=1).reshape(-1,n,n)

def active_reflection(s,phases):
    a=np.exp(1j*np.deg2rad(phases))
    return np.einsum('fij,j->fi',s,a)/a

def farfield_complex(p,path,mode='Realized Gain'):
    method(p,'SelectTreeItem',path)
    ff=method(p,'FarfieldPlot');method(ff,'Reset');method(ff,'SetPlotMode',mode)
    method(ff,'SetScaleLinear',True)
    # Full signed cuts, not a mirrored assumption: opposite half uses phi+180.
    for phi in [0,90]:
        for theta in range(360):
            method(ff,'AddListItem',theta if theta<=180 else 360-theta,phi if theta<=180 else phi+180,1)
    method(ff,'CalculateList',path)
    rows=[]
    for i in range(720):
        et=complex(method(ff,'GetListItem',i,'th_re'),method(ff,'GetListItem',i,'th_im'))
        ep=complex(method(ff,'GetListItem',i,'ph_re'),method(ff,'GetListItem',i,'ph_im'))
        # Store both circular senses; handedness depends on verified CST convention.
        cp_plus=abs((et+1j*ep)/math.sqrt(2))**2
        cp_minus=abs((et-1j*ep)/math.sqrt(2))**2
        field_power=abs(et)**2+abs(ep)**2
        # CST GetListItem Abs in gain modes is LINEAR POWER GAIN.
        # Complex field entries retain a distinct physical normalization.
        total=float(method(ff,'GetListItem',i,'Abs'))
        cp_plus=total*cp_plus/max(field_power,1e-30)
        cp_minus=total*cp_minus/max(field_power,1e-30)
        large,small=sorted([math.sqrt(cp_plus),math.sqrt(cp_minus)],reverse=True)
        ratio=(large+small)/max(large-small,1e-15)
        rows.append({'plane':'XZ' if i<360 else 'YZ','theta':i%360,
            'gain':10*math.log10(max(total,1e-30)),
            'cp_plus_db':10*math.log10(max(cp_plus,1e-30)),
            'cp_minus_db':10*math.log10(max(cp_minus,1e-30)),
            'axial_ratio_db':20*math.log10(max(ratio,1)),
            'etheta_re':et.real,'etheta_im':et.imag,'ephi_re':ep.real,'ephi_im':ep.imag})
    return rows

def compare(rows,target_path,out,coverage=90,make_plot=False):
    out=Path(out);out.parent.mkdir(parents=True,exist_ok=True)
    with open(target_path) as f:t=list(csv.DictReader(f))
    target={int(float(r['theta'])):float(r['gain']) for r in t}
    errors=[];angles=[0,15,30,45,60,75,80,85,90,105,120,150,180]
    for row in rows:
        d=dict(row);d['target_gain']=target[row['theta']];d['error_db']=row['gain']-d['target_gain'];errors.append(d)
    with out.with_suffix('.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(errors[0]));w.writeheader();w.writerows(errors)
    front=[r for r in errors if min(r['theta'],360-r['theta'])<=coverage]
    peak=max(r['gain'] for r in rows);peak_error=abs(peak-max(target.values()))
    rmse=float(np.sqrt(np.mean([r['error_db']**2 for r in front])))
    report={'coverage_rmse_db':rmse,'full_cut_rmse_db':float(np.sqrt(np.mean([r['error_db']**2 for r in errors]))),
            'peak_gain_dbi':peak,'peak_error_db':peak_error,
            'angle_errors':[r for r in errors if r['theta'] in angles],
            'gain_quantity':'total realized gain; compare dominant CP gain separately after convention verification',
            'target_provenance':'screening envelope, not manufacturer numeric EM truth'}
    out.with_suffix('.json').write_text(json.dumps(report,indent=2))
    if not make_plot:return report
    import matplotlib;matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,ax=plt.subplots(figsize=(9,5))
    ax.plot(list(target),list(target.values()),'k--',label='Repository screening target')
    for plane in ['XZ','YZ']:
        cut=[r for r in rows if r['plane']==plane];ax.plot([r['theta'] for r in cut],[r['gain'] for r in cut],label=f'CST {plane}')
    ax.set(xlabel='Signed cut angle (deg)',ylabel='Realized gain (dBi)',xlim=(0,359));ax.grid();ax.legend();fig.tight_layout();fig.savefig(out.with_suffix('.png'));plt.close(fig)
    return report

def objective(pattern_rmse,peak_error,active_rl,ar,beam_shape_error=0):
    """Declared engineering loss; no hidden vertical pattern offset or rescaling."""
    return pattern_rmse+0.5*peak_error+0.2*max(0,10-active_rl)+0.2*max(0,ar-3)+0.2*beam_shape_error
