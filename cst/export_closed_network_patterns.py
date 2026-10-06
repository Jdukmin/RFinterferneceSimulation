"""POST-SOLVE export only; never starts CST solver; no clipping or gain floor."""
import argparse,csv,json,math,sys
from pathlib import Path
import numpy as np
from cst_com_common import connect_cst,method,get_active_project
from cst_results import s_matrix,active_reflection
from verify_sband_results import tree_paths
from prepare_closed_network import ROOT,BANDS

def db(x):return 10*math.log10(x) if x>0 else -math.inf if x==0 else math.nan

def local_cut_direction_in_solver(theta,phi,evidence):
 th=math.radians(theta);ph=math.radians(phi)
 d=np.array([math.sin(th)*math.cos(ph),math.sin(th)*math.sin(ph),math.cos(th)])
 if evidence.get('installed_geometry'):
  d=np.array(evidence['installed_geometry']['installation']['nominal_R_BL'])@d
 return math.degrees(math.acos(float(np.clip(d[2],-1,1)))),math.degrees(math.atan2(d[1],d[0]))%360

def main():
 a=argparse.ArgumentParser();a.add_argument('project_file');a.add_argument('--convergence-accepted',action='store_true',required=True);args=a.parse_args()
 path=Path(args.project_file).resolve();assert path.is_relative_to(ROOT/'cst/projects/closed_network')
 evidence=json.loads(path.with_suffix('.preflight.json').read_text());out=ROOT/'data/closed_network_patterns'/path.stem.replace('RFC_','');out.mkdir(parents=True,exist_ok=True)
 assert not (out/'provenance.json').exists(),'Refuse overwrite of raw results; archive prior export separately.'
 app=connect_cst(False);p=method(app,'OpenFile',str(path));p=p or get_active_project(app)
 ffreq,s=s_matrix(p,evidence['ports']);gamma=active_reflection(s,evidence['phases_deg'])
 np.savez(out/'raw_s_matrix.npz',frequency_ghz=ffreq,s=s,active_gamma=gamma,phases_deg=evidence['phases_deg'])
 combine=method(p,'CombineResults');method(combine,'Reset');method(combine,'SetMonitorType','frequency');method(combine,'FarfieldsOnly',True)
 method(combine,'EnableAutomaticLabeling',False);method(combine,'SetLabel','CLOSED_NETWORK_FIXED_PHASES')
 for i,phase in enumerate(evidence['phases_deg']):method(combine,'SetPortModeValues',i+1,1,1.,phase)
 method(combine,'Run') # post-processing completed results, NOT Solver.Start
 paths=tree_paths(p);checks=[]
 for f in evidence['monitor_frequencies_ghz']:
  matches=[v for v in paths if f'f={f:g})' in v and 'CLOSED_NETWORK_FIXED_PHASES' in v];assert len(matches)==1,matches
  index=int(np.argmin(abs(ffreq-f)));accepted=1-float(np.mean(abs(gamma[index])**2));excess=max(0,float(np.linalg.svd(s[index],compute_uv=False).max())**2-1)
  reliable=accepted>max(1e-6,5*excess);correction=-10*math.log10(accepted) if accepted>0 else math.nan
  method(p,'SelectTreeItem',matches[0]);ff=method(p,'FarfieldPlot');method(ff,'Reset');method(ff,'SetPlotMode','Realized Gain');method(ff,'SetScaleLinear',True)
  for phi in [0,90]:
   for theta in range(360):
    global_theta,global_phi=local_cut_direction_in_solver(theta,phi,evidence)
    method(ff,'AddListItem',global_theta,global_phi,1)
  method(ff,'CalculateList',matches[0])
  rows=[]
  for i in range(720):
   et=complex(method(ff,'GetListItem',i,'th_re'),method(ff,'GetListItem',i,'th_im'));ep=complex(method(ff,'GetListItem',i,'ph_re'),method(ff,'GetListItem',i,'ph_im'));power=float(method(ff,'GetListItem',i,'Abs'))
   fields=abs(et)**2+abs(ep)**2;plus=abs((et+1j*ep)/math.sqrt(2))**2;minus=abs((et-1j*ep)/math.sqrt(2))**2
   solver_theta,solver_phi=local_cut_direction_in_solver(i%360,0 if i<360 else 90,evidence)
   rows.append(dict(plane='XZ' if i<360 else 'YZ',theta=i%360,solver_theta_deg=solver_theta,solver_phi_deg=solver_phi,realized_gain_linear=power,realized_gain_dbi=db(power),accepted_power_gain_dbi=db(power)+correction,
    etheta_re=et.real,etheta_im=et.imag,ephi_re=ep.real,ephi_im=ep.imag,cp_plus_gain_dbi=db(power*plus/fields) if fields>0 else math.nan,cp_minus_gain_dbi=db(power*minus/fields) if fields>0 else math.nan))
  for plane in ['XZ','YZ']:
   selected=[r for r in rows if r['plane']==plane]
   with (out/f'f{f:.6f}_{plane}.csv').open('w',encoding='utf-8',newline='') as stream:
    writer=csv.DictWriter(stream,fieldnames=list(selected[0]));writer.writeheader();writer.writerows(selected)
  checks.append(dict(frequency_ghz=f,accepted_power_fraction=accepted,s_matrix_passivity_excess=excess,normalization_reliable=reliable,raw_floor_applied=False))
 record=dict(project_file=str(path.relative_to(ROOT)),status='SOLVED_ACCEPTED' if all(v['normalization_reliable'] for v in checks) else 'NORMALIZATION_FAILED',gain_quantity='RealizedGain',gain_unit='dBi',
  source_reference_plane='NATIVE_DISCRETE_ANTENNA_PORT',angle_convention='theta 0..359; antenna-local boresight +Z; local XZ phi0/180, YZ phi90/270',frame='CST_LOCAL_PRESERVED',convergence_accepted=args.convergence_accepted,
  solver_frame='SPACECRAFT_BODY_FIXED' if evidence.get('installed_geometry') else 'CST_LOCAL_PRESERVED',
  cut_direction_rotation_local_to_solver=evidence['installed_geometry']['installation']['nominal_R_BL'] if evidence.get('installed_geometry') else np.eye(3).tolist(),
  gain_cut_resampled_in_antenna_local_frame=True,complex_e_components_frame='SOLVER_GLOBAL_SPHERICAL_BASIS_AT_SAMPLED_DIRECTION; NOT_LOCAL_POLARIZATION',
  monitors=checks,phases_deg=evidence['phases_deg'],solver_started_by_exporter=False,cp_handness='CP_PLUS_MINUS_RETAINED; RHCP_LHCP assignment requires verified CST convention')
 (out/'provenance.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8');method(p,'Quit');print(record['status'])
if __name__=='__main__':main()
