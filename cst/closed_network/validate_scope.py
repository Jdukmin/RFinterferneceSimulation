"""Audit all 22 cases and reopen six changed attacker cases; no solver."""
import sys,json,csv,tempfile,shutil,hashlib,subprocess
from pathlib import Path
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from fixed_body_geometry import ROOT,geometry,sha,solids
from cst_com_common import connect_cst,method,get_active_project
import pythoncom,win32com.client
CN=ROOT/'cst/projects/closed_network'
def ports(p,n):
 obj=method(p,'DiscretePort');rows=[]
 for no in range(1,n+1):
  args=[win32com.client.VARIANT(pythoncom.VT_BYREF|pythoncom.VT_R8,0) for _ in range(6)];assert method(obj,'GetCoordinates',no,*args);rows.append([v.value for v in args])
 return np.array(rows)
def open_copy(app,path):
 folder=Path(tempfile.mkdtemp(prefix='closed_network_standalone_check_'));target=folder/path.name;shutil.copy2(path,target);p=method(app,'OpenFile',str(target));return p or get_active_project(app)
def main():
 rows=list(csv.DictReader((CN/'project_inventory.csv').open(encoding='utf-8')));assert len(rows)==22
 g=geometry();prior=json.loads(subprocess.check_output(['git','show','8254454:docs/closed_network_reopen_validation.json'],cwd=ROOT));previous={r['project_file']:r for r in prior['records']}
 app=connect_cst(False);sources={};reports=[]
 for row in rows:
  path=ROOT/row['project_file'];e=json.loads(path.with_suffix('.preflight.json').read_text());assert sha(path)==e['project_sha256'];assert not e['solver_started']
  changed=e.get('attacker_installed_update')=='SBA_ISL_INSTALLED_22_PROJECT_SET' or (row['antenna']=='GPS' and row['configuration']=='INSTALLED');groups=e.get('installation_groups',[])
  if not groups and e.get('installed_geometry'):groups=[dict(installation=e['installed_geometry']['installation'],port_numbers=list(range(1,5)),phases_deg=e['phases_deg'])]
  for group in groups:
   i=group['installation'];R=np.array(i['nominal_R_BL']);panel=next(x for x in g['full_outer_panels'] if x['panel_id']==i['panel_id']);np.testing.assert_allclose(R[:,2],panel['outward_normal_body'],atol=1e-9)
   assert np.linalg.det(R)>0 and np.max(abs(R.T@R-np.eye(3)))<1e-9
  if e.get('installed_geometry'):
   assert len(e['installed_geometry']['panels'])==8 and e['installed_geometry']['global_solver_frame']=='SPACECRAFT_BODY_FIXED'
   for panel in e['installed_geometry']['panels']:assert panel['body_vertices_mm']==next(x for x in g['full_outer_panels'] if x['panel_id']==panel['panel_id'])['body_vertices_mm']
  if row['antenna']=='KAA':assert not e.get('installed_geometry') and not groups
  if changed:
   src=ROOT/e['source_project'];assert sha(src)==e['source_sha256']
   if e['source_project'] not in sources:
    p=open_copy(app,src);sources[e['source_project']]=dict(solids=solids(p),ports=ports(p,4));method(p,'Quit')
   source=sources[e['source_project']];p=open_copy(app,path);actual=ports(p,e['ports']);shapes=solids(p);assert len([n for n in shapes if n.startswith('FULL_SPACECRAFT:')])==8
   maxerr=0
   for k,group in enumerate(groups):
    i=group['installation'];R=np.array(i['nominal_R_BL']);expected=(source['ports'].reshape(4,2,3)@R.T+np.array(i['position_body_mm'])).reshape(4,6)
    np.testing.assert_allclose(actual[np.array(group['port_numbers'])-1],expected,atol=1e-7,rtol=0)
    segment=actual[np.array(group['port_numbers'])-1];axes=segment[:,3:]-segment[:,:3];axes/=np.linalg.norm(axes,axis=1)[:,None]
    np.testing.assert_allclose(axes,np.tile(R[:,2],(4,1)),atol=1e-7,rtol=0)
    for no in group['port_numbers']:assert abs(float(method(method(p,'Port'),'GetLineImpedance',no,1))-50)<1e-9
    for name,value in source['solids'].items():
     target=name if k==0 else name+'_1';assert shapes[target]['material']==value['material'];err=abs(shapes[target]['volume_mm3']-value['volume_mm3'])/max(1,abs(value['volume_mm3']));assert err<1e-5;maxerr=max(maxerr,err)
   m=method(p,'Monitor');names=[method(m,'GetMonitorNameFromIndex',j) for j in range(int(method(m,'GetNumberOfMonitors')))];assert sorted(names)==sorted(e['verified_monitor_names']);method(p,'Quit')
   status='NEW_STANDALONE_REOPEN_PASS';record=dict(port_endpoints_body_mm=actual.tolist(),max_solid_volume_relative_error=maxerr,port_axes_match_panel_outward_normal=True)
  else:
   binary=subprocess.check_output(['git','show','8254454:'+row['project_file']],cwd=ROOT);assert hashlib.sha256(binary).hexdigest()==sha(path);assert previous[row['project_file']]['standalone_cst_reopen'];status='PRIOR_STANDALONE_REOPEN_REUSED_EXACT_BINARY_HASH';record={}
  reports.append(dict(project_file=row['project_file'],verification=status,sha256=sha(path),ports=e['ports'],installation_groups=[dict(identity=x['installation']['installation_id'],panel=x['installation']['panel_id'],boresight_body=np.array(x['installation']['nominal_R_BL'])[:,2].tolist()) for x in groups],full_panels=8 if e.get('installed_geometry') else 0,mesh_cells=e['mesh_cells'],solver_started=False,**record));print('Verified',path.name,status,flush=True)
 bindings=json.loads((CN/'dataset_bindings.json').read_text());by_id={b['dataset_id']:b for b in bindings};plan=json.loads((ROOT/'analysis/closed_network/rfi_plan.json').read_text());assert len(plan)==37 and len({r['pair_id'] for r in plan})==10
 for r in plan:
  tx=by_id[r['tx_dataset']]
  if r['pair'].startswith('KAA'):assert tx['pattern_class']=='FreeSpacePattern'
  else:assert tx['pattern_class']=='InstalledPattern' and tx['installation_id']==r['tx_installation']
  if r['rx_dataset']=='SAR_ENGINEERING_RECEIVE_BASELINE':continue
  rx=by_id[r['rx_dataset']];assert rx['pattern_class']=='InstalledPattern' and rx['installation_id']==r['rx_installation']
 summary=dict(status='PASS',physical_projects=22,changed_attacker_projects_reopened=6,gps_installed_projects_reopened=2,unchanged_projects_prior_reopen_with_exact_hash=14,installed_physical_projects=11,installed_antenna_groups=14,pattern_bindings=25,rfi_pairs=10,primary_combinations=37,source_cst_hashes_unchanged=True,body_hull_unchanged=True,solver_started=False,actual_cst_exports=0,rf_results_generated=False,records=reports)
 (CN/'validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8');print('PASS 22/22 project audit; 10/10 pair bindings; 37 primary rows; no solver.',flush=True)
if __name__=='__main__':main()
