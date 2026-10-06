"""Post-solve group export for the 22 closed-network projects; NEVER start solver."""
import sys,argparse,json,csv,math
from pathlib import Path
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'analysis/closed_network'))
from cst2024_provenance import verify_native_2024
from fixed_body_geometry import ROOT,sha
from cst_com_common import connect_cst,method,get_active_project
from cst_results import s_matrix
from verify_sband_results import tree_paths
from fixed_body_geometry import local_cut_direction_in_solver
def db(x):return 10*math.log10(x) if x>0 else -math.inf if x==0 else math.nan
CN=ROOT/'cst/projects/closed_network'

def excitation_vector(n,ports,phases):
 a=np.zeros(n,dtype=complex);a[np.array(ports)-1]=np.exp(1j*np.radians(phases));return a

def net_accepted_fraction(s,a):
 # Zero excitation on inactive matched ports. Include power leaving ALL network ports.
 incident=float(np.vdot(a,a).real);b=np.einsum('fij,j->fi',s,a)
 return 1-np.sum(abs(b)**2,axis=1)/incident,b

def export_group(p,path,e,group,freq,s):
 out=ROOT/group['expected_output_directory'];out.mkdir(parents=True,exist_ok=True)
 assert not (out/'provenance.json').exists(),'Archive existing RAW exports; no overwrite.'
 a=excitation_vector(e['ports'],group['port_numbers'],group['phases_deg']);accepted,b=net_accepted_fraction(s,a)
 np.savez(out/'raw_s_matrix.npz',frequency_ghz=freq,s=s,excitation=a,outgoing_port_waves=b,net_accepted_fraction=accepted)
 combine=method(p,'CombineResults');method(combine,'Reset');method(combine,'SetMonitorType','frequency');method(combine,'FarfieldsOnly',True);method(combine,'EnableAutomaticLabeling',False)
 label='CN_'+(group['installation']['installation_id'] if group.get('installation') else 'ORIGINAL');method(combine,'SetLabel',label)
 for no in range(1,e['ports']+1):method(combine,'SetPortModeValues',no,1,float(abs(a[no-1])),float(np.degrees(np.angle(a[no-1]))))
 method(combine,'Run') # completed-results combination only; NOT Solver.Start
 paths=tree_paths(p);checks=[];sampling={'installed_geometry':{'installation':group['installation']}} if group.get('installation') else {}
 for f in e['monitor_frequencies_ghz']:
  matches=[v for v in paths if f'f={f:g})' in v and label in v];assert len(matches)==1,matches
  j=int(np.argmin(abs(freq-f)));excess=max(0,float(np.linalg.svd(s[j],compute_uv=False).max())**2-1);fraction=float(accepted[j]);reliable=fraction>max(1e-6,5*excess);correction=-10*math.log10(fraction) if fraction>0 else math.nan
  method(p,'SelectTreeItem',matches[0]);ff=method(p,'FarfieldPlot');method(ff,'Reset');method(ff,'SetPlotMode','Realized Gain');method(ff,'SetScaleLinear',True)
  for phi in [0,90]:
   for theta in range(360):t,ph=local_cut_direction_in_solver(theta,phi,sampling);method(ff,'AddListItem',t,ph,1)
  method(ff,'CalculateList',matches[0]);rows=[]
  for i in range(720):
   et=complex(method(ff,'GetListItem',i,'th_re'),method(ff,'GetListItem',i,'th_im'));ep=complex(method(ff,'GetListItem',i,'ph_re'),method(ff,'GetListItem',i,'ph_im'));power=float(method(ff,'GetListItem',i,'Abs'))
   fields=abs(et)**2+abs(ep)**2;plus=abs((et+1j*ep)/math.sqrt(2))**2;minus=abs((et-1j*ep)/math.sqrt(2))**2;t,ph=local_cut_direction_in_solver(i%360,0 if i<360 else 90,sampling)
   rows.append(dict(plane='XZ' if i<360 else 'YZ',theta=i%360,solver_theta_deg=t,solver_phi_deg=ph,realized_gain_linear=power,realized_gain_dbi=db(power),net_accepted_power_gain_dbi=db(power)+correction,
    etheta_re=et.real,etheta_im=et.imag,ephi_re=ep.real,ephi_im=ep.imag,cp_plus_gain_dbi=db(power*plus/fields) if fields>0 else math.nan,cp_minus_gain_dbi=db(power*minus/fields) if fields>0 else math.nan))
  for plane in ['XZ','YZ']:
   selected=[r for r in rows if r['plane']==plane]
   with (out/f'f{f:.6f}_{plane}.csv').open('w',encoding='utf-8',newline='') as stream:w=csv.DictWriter(stream,fieldnames=list(selected[0]));w.writeheader();w.writerows(selected)
  checks.append(dict(frequency_ghz=f,accepted_power_fraction=fraction,s_matrix_passivity_excess=excess,normalization_reliable=reliable,raw_floor_applied=False))
 R=group['installation']['nominal_R_BL'] if group.get('installation') else np.eye(3).tolist()
 meta=dict(project_file=path.relative_to(ROOT).as_posix(),project_sha256=sha(path),dataset_id=group['dataset_id'],installation_id=group['installation']['installation_id'] if group.get('installation') else '',
  status='SOLVED_ACCEPTED' if all(c['normalization_reliable'] for c in checks) else 'NORMALIZATION_FAILED',gain_quantity='RealizedGain',gain_unit='dBi',source_reference_plane='INCIDENT_POWER_AT_SELECTED_FOUR_NATIVE_DISCRETE_PORTS',
  frame='CST_LOCAL_PRESERVED',solver_frame='SPACECRAFT_BODY_FIXED' if group.get('installation') else 'CST_LOCAL_PRESERVED',gain_cut_resampled_in_antenna_local_frame=True,cut_direction_rotation_local_to_solver=R,
  complex_e_components_frame='SOLVER_GLOBAL_SPHERICAL_BASIS_AT_SAMPLED_DIRECTION',angle_convention='local theta 0..359; local +Z boresight; XZ phi0/180 YZ phi90/270',convergence_accepted=True,monitors=checks,
  phases_deg=group['phases_deg'],active_port_numbers=group['port_numbers'],inactive_ports='ZERO_INCIDENT_AMPLITUDE; MATCHED_50_OHM_ENGINEERING_ASSUMPTION',net_accepted_power_reference='Incident selected-group power minus outgoing power at ALL ports; diagnostic only; primary uses RAW CST RealizedGain',solver_started_by_exporter=False)
 if e.get('cst2024_rebuild'):
  meta.update(e['cst2024_rebuild'])
 (out/'provenance.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf-8');print(group['dataset_id'],meta['status'],flush=True)

def main():
 parser=argparse.ArgumentParser();parser.add_argument('project_file');parser.add_argument('--installation-id');parser.add_argument('--convergence-accepted',action='store_true',required=True)
 parser.add_argument('--build-package');parser.add_argument('--native-validation');args=parser.parse_args()
 path=Path(args.project_file).resolve()
 if args.build_package:
  assert args.native_validation,'CST2024 native validation record required.'
  manifest,record=verify_native_2024(ROOT,args.build_package,path,args.native_validation)
  e=json.loads((ROOT/manifest['source_project']).with_suffix('.preflight.json').read_text())
  e['cst2024_rebuild']=dict(cst_version=2024,build_package=str(Path(args.build_package).as_posix()),native_validation_file=str(Path(args.native_validation).as_posix()),binding_project_file=manifest['source_project'],source_geometry_hash=manifest['source_geometry_hash'])
 else:
  assert path.is_relative_to(CN);e=json.loads(path.with_suffix('.preflight.json').read_text());assert sha(path)==e['project_sha256']
 groups=e.get('installation_groups')
 if not groups:
  binding_project=e['cst2024_rebuild']['binding_project_file'] if e.get('cst2024_rebuild') else path.relative_to(ROOT).as_posix()
  bind=next(b for b in json.loads((CN/'dataset_bindings.json').read_text()) if b['project_file']==binding_project)
  groups=[dict(installation=e['installed_geometry']['installation'] if e.get('installed_geometry') else None,port_numbers=list(range(1,5)),phases_deg=e['phases_deg'],dataset_id=bind['dataset_id'],expected_output_directory=bind['directory'])]
 if args.installation_id:groups=[g for g in groups if g.get('installation') and g['installation']['installation_id']==args.installation_id];assert groups
 app=connect_cst(False);p=method(app,'OpenFile',str(path));p=p or get_active_project(app);freq,s=s_matrix(p,e['ports'])
 for group in groups:export_group(p,path,e,group,freq,s)
 method(p,'Quit')
if __name__=='__main__':main()
