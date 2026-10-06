"""Read-only CST reopen and portability validation; never starts a solver."""
import csv,json,sys,hashlib,shutil,tempfile
from pathlib import Path
import pythoncom,win32com.client
import numpy as np
from cst_com_common import connect_cst,method,get_active_project
from prepare_closed_network import ROOT,sha,solids

def coordinates(p):
 obj=method(p,'DiscretePort');rows=[]
 for no in range(1,5):
  variants=[win32com.client.VARIANT(pythoncom.VT_BYREF|pythoncom.VT_R8,0) for _ in range(6)]
  assert method(obj,'GetCoordinates',no,*variants)
  rows.append([v.value for v in variants])
 return rows

def main():
 rows=list(csv.DictReader((ROOT/'docs/closed_network_cst_project_inventory.csv').open(encoding='utf-8')));app=connect_cst(False);sources={};reports=[]
 for row in rows:
  if row['solver_status']!='READY_NOT_SOLVED':continue
  src=ROOT/row['source_project'];hash0=sha(src)
  if row['source_project'] not in sources:
   p=method(app,'OpenFile',str(src.resolve()));p=p or get_active_project(app)
   sources[row['source_project']]=dict(solids=solids(p),ports=coordinates(p));method(p,'Quit');assert sha(src)==hash0
  evidence=json.loads((ROOT/row['project_file']).with_suffix('.preflight.json').read_text());project=ROOT/row['project_file'];assert sha(project)==evidence['project_sha256']
  # Transport .cst ALONE: no Model/Result/Temp sidecars are carried into this reopen.
  folder=Path(tempfile.mkdtemp(prefix='codex_cst_portability_'));copy=folder/project.name;shutil.copy2(project,copy)
  p=method(app,'OpenFile',str(copy));p=p or get_active_project(app);s=solids(p);ports=coordinates(p)
  expected=np.array(sources[row['source_project']]['ports'])
  if row['configuration']=='INSTALLED':
   inst=evidence['installed_geometry']['installation'];R=np.array(inst['nominal_R_BL']);origin=np.array(inst['position_body_mm'])
   expected=(expected.reshape(4,2,3)@R.T+origin).reshape(4,6)
  assert np.max(abs(np.array(ports)-expected))<1e-7
  for name,value in sources[row['source_project']]['solids'].items():
   assert name in s and s[name]['material']==value['material']
   assert abs(s[name]['volume_mm3']-value['volume_mm3'])<(1e-5 if row['configuration']=='INSTALLED' else 1e-7)*max(1,abs(value['volume_mm3']))
  if row['configuration']=='INSTALLED':assert len([n for n in s if n.startswith('FULL_SPACECRAFT:')])==8
  m=method(p,'Monitor');names=[method(m,'GetMonitorNameFromIndex',i) for i in range(int(method(m,'GetNumberOfMonitors')))];assert sorted(names)==sorted(evidence['verified_monitor_names'])
  method(p,'Quit');assert sha(project)==evidence['project_sha256'] and sha(src)==hash0
  reports.append(dict(project_file=row['project_file'],standalone_cst_reopen=True,native_port_relative_endpoints_preserved=True,port_frame='BODY' if row['configuration']=='INSTALLED' else 'NATIVE_LOCAL',native_port_endpoints_mm=ports,native_material_preserved=True,rigid_solid_volume_relative_tolerance=1e-5 if row['configuration']=='INSTALLED' else 1e-7,
   full_panels=8 if row['configuration']=='INSTALLED' else 0,monitor_count=3,solver_started=False))
  print('Verified',project.name,flush=True)
 plan=json.loads((ROOT/'analysis/closed_network/rfi_plan.json').read_text());assert len({r['pair_id'] for r in plan})==10
 assert sources['cst/projects/closed_network/kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.cst']['ports']==sources['cst/projects/KA_FEED_C_OEWG.cst']['ports']
 summary=dict(status='PASS_FOR_PREPARED_PROJECTS',overall_completion='COMPLETE' if len(reports)==len(rows) else 'INCOMPLETE_INPUT_MISSING',saved_projects_verified=len(reports),planned_projects=len(rows),exact_rfi_pair_families=10,comparison_matrix_rows=len(plan),
  missing_projects=[r['project_file'] for r in rows if r['solver_status']!='READY_NOT_SOLVED'],solver_started=False,records=reports)
 (ROOT/'docs/closed_network_reopen_validation.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
if __name__=='__main__':main()
