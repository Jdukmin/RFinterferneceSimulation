"""Install SBA/ISL attacker projects within the existing 22-file closed-network set; NO solver."""
import sys,json,csv,tempfile,shutil,math,hashlib
from pathlib import Path
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from fixed_body_geometry import ROOT,BANDS,geometry,solids,port_coordinates,full_hull,sha,write_json
from cst_com_common import connect_cst,method,get_active_project,add_to_history
from cst_com import save,monitor
from cst_geometry import port
CN=ROOT/'cst/projects/closed_network'

def names(p):
 s=method(p,'Solid');return [method(s,'GetNameOfShapeFromIndex',i) for i in range(int(method(s,'GetNumberOfShapes')))]
def rotation_angles(identity,R):
 return [(90,0,0),(0,0,90)] if identity=='ISL' else [(float(np.degrees(np.arctan2(-R[1,2],R[2,2]))),0,0)]
def transform_code(name,angle=None,vector=None,duplicate=False,centre=(0,0,0)):
 code=f'With Transform\n .Reset\n .Name "{name}"\n .MultipleObjects "{str(duplicate)}"\n .GroupObjects "False"\n .Repetitions "1"\n .MultipleSelection "False"\n'
 if angle is not None:
  code+=' .Origin "Free"\n .Center '+', '.join(f'"{v:.12g}"' for v in centre)+'\n .Angle '+', '.join(f'"{v:.12g}"' for v in angle)+'\n .RotateAdvanced\n'
 else:code+=' .Vector '+', '.join(f'"{v:.12g}"' for v in vector)+'\n .TranslateAdvanced\n'
 return code+'End With\n'

def prepare_installed(row,app,g):
 target=ROOT/row['project_file'];old=json.loads(target.with_suffix('.preflight.json').read_text(encoding='utf-8'))
 if old.get('attacker_installed_update')=='SBA_ISL_INSTALLED_22_PROJECT_SET':return old
 src=ROOT/row['source_project'];src_hash=sha(src);folder=Path(tempfile.mkdtemp(prefix='closed_network_attacker_'));candidate=folder/target.name;shutil.copy2(src,candidate)
 p=method(app,'OpenFile',str(candidate));p=p or get_active_project(app)
 original=solids(p);coords=port_coordinates(p);imp=[float(method(method(p,'Port'),'GetLineImpedance',i,1)) for i in range(1,5)]
 assert all(abs(v-50)<1e-9 for v in imp)
 ids=row['installation_identity'].split(';');insts=[next(i for i in g['installations'] if i['installation_id']==identity) for identity in ids]
 groups=[];maps=[]
 # Duplicate native solids for the second mounting identity before moving originals.
 if len(insts)==2:
  i=insts[1];R=np.array(i['nominal_R_BL']);angles=rotation_angles(ids[1],R)
  add_to_history(p,'Clone native antenna at second installation; rigid rotation only','WCS.ActivateWCS "global"\n'+''.join(transform_code(n,angle=angles[0],duplicate=True) for n in original))
  current=set(names(p));duplicates=current-set(original);assert len(duplicates)==len(original),(len(duplicates),len(original))
  mapping={n:n+'_1' for n in original};assert set(mapping.values())==duplicates,sorted(duplicates)[:6]
  code=''
  for n in mapping.values():
   for a in angles[1:]:code+=transform_code(n,angle=a)
   code+=transform_code(n,vector=i['position_body_mm'])
  add_to_history(p,'Place second native antenna at SSOT body position',code);maps.append(mapping)
 else:maps.append(None)
 i=insts[0];R=np.array(i['nominal_R_BL']);code='WCS.ActivateWCS "global"\n'
 for n in original:
  for a in rotation_angles(ids[0],R):code+=transform_code(n,angle=a)
  code+=transform_code(n,vector=i['position_body_mm'])
 add_to_history(p,'Place first native antenna at SSOT body position',code)
 for no in range(1,5):add_to_history(p,f'Replace native port {no} coordinates',f'Port.Delete "{no}"')
 phases=[0,90,180,270] if row['antenna']=='SBA' else [0,-90,-180,-270]
 for k,i in enumerate(insts):
  R=np.array(i['nominal_R_BL']);origin=np.array(i['position_body_mm']);expected=(coords.reshape(4,2,3)@R.T+origin).reshape(4,6)
  numbers=list(range(k*4+1,k*4+5))
  for j,no in enumerate(numbers):port(p,no,expected[j,:3],expected[j,3:],imp[j])
  groups.append(dict(installation=i,port_numbers=numbers,phases_deg=phases,port_endpoints_body_mm=expected.tolist(),source_port_impedances_ohm=imp,dataset_id=row['dataset_ids'][k],expected_output_directory='data/closed_network_patterns/'+row['dataset_ids'][k]))
 installed=full_hull(p,g,ids[0]);final=solids(p);maxerr=0
 for n,v in original.items():
  targets=[n]+([n+'_1'] if len(insts)==2 else [])
  for name in targets:
   assert final[name]['material']==v['material']
   err=abs(final[name]['volume_mm3']-v['volume_mm3'])/max(1,abs(v['volume_mm3']));maxerr=max(maxerr,err)
   assert err<1e-5,(name,err)
 frequencies=BANDS[row['victim_band']]
 add_to_history(p,'Victim band frequencies; do not start solver',f'Solver.FrequencyRange "{frequencies[0]}", "{frequencies[-1]}"')
 m=method(p,'Monitor');oldnames=[method(m,'GetMonitorNameFromIndex',j) for j in range(int(method(m,'GetNumberOfMonitors')))];wanted=[f'farfield (f={f:g})' for f in frequencies]
 for n in oldnames:
  if n not in wanted:add_to_history(p,'Remove unrelated monitor '+n,f'Monitor.Delete "{n}"')
 for f,n in zip(frequencies,wanted):
  if n not in oldnames:monitor(p,f)
 count=len(groups)*4;assert int(method(method(p,'Port'),'StartPortNumberIteration'))==count
 combine=method(p,'CombineResults');method(combine,'Reset');method(combine,'SetMonitorType','frequency');method(combine,'FarfieldsOnly',True);method(combine,'EnableAutomaticLabeling',False);method(combine,'SetLabel','CN_'+ids[0])
 for no in range(1,count+1):method(combine,'SetPortModeValues',no,1,1. if no<=4 else 0.,phases[(no-1)%4])
 mesh=method(p,'Mesh');method(mesh,'Update');lines=[int(method(mesh,'GetN'+a)) for a in 'xyz'];cells=math.prod(n-1 for n in lines)
 save(p,candidate);method(p,'Quit');assert sha(src)==src_hash
 backup=folder/('before_'+target.name);shutil.copy2(target,backup);shutil.copy2(candidate,target)
 result=dict(old);result.update(project_sha256=sha(target),ports=count,installation_groups=groups,installed_geometry=installed,attacker_installed_update='SBA_ISL_INSTALLED_22_PROJECT_SET',
  source_solids=original,source_materials_preserved=True,rigid_solid_volume_relative_tolerance=1e-5,solid_volume_max_relative_error=maxerr,mesh_line_counts=lines,mesh_cells=cells,mesh_memory_128bytes_per_cell_gib_lower_planning_estimate=cells*128/1024**3,
  port_geometry_preserved_by_no_port_edit=False,port_relative_geometry_preserved_by_rigid_transform=True,solver_started=False,solver_status='READY_NOT_SOLVED',
  preferred_solver_review='IE_MLFMM_OR_HYBRID',solver_selection_policy='LICENSED_CST_RESOURCE_AND_PORT_COMPATIBILITY_REVIEW; NOT_FORCED_TIME_DOMAIN',
  antenna_instances=len(groups),inactive_port_termination='MATCHED_50_OHM_ENGINEERING_ASSUMPTION; other installation not excited',monitor_frequencies_ghz=frequencies,verified_monitor_names=wanted,
  saved_active_installation=ids[0],geometry_provenance='NATIVE_ANTENNA_RIGID_INSTANCES_WITH_FULL_SSOT_BUS_HULL_8_PANELS; NOT_COMPLETE_SATELLITE_CAD')
 write_json(target.with_suffix('.preflight.json'),result);print(json.dumps(dict(project=target.name,instances=ids,ports=count,mesh_cells=cells,solver_started=False)),flush=True)
 return result

def inventory_and_bindings():
 rows=json.loads((CN/'source_inventory.json').read_text());bindings=[]
 for r in rows:
  stem=Path(r['project_file']).stem.replace('RFC_','');ids=[];datasets=[]
  if r['antenna']=='KAA':
   ids=[''];datasets=[stem]
  elif r['configuration']=='ATTACKER_ORIGINAL':
   ids=['ISL'] if r['antenna']=='ISL' else ['SBA_NADIR','SBA_ZENITH']
   base=stem.replace('_ORIGINAL','');datasets=['INSTALLED_'+base+('_'+i.replace('SBA_','') if r['antenna']=='SBA' else '') for i in ids]
  elif r['installation_identity']:ids=[r['installation_identity']];datasets=[stem]
  else:ids=[''];datasets=[stem]
  r['installation_identity']=';'.join(ids);r['dataset_ids']=datasets
  if any(ids):
   r['spacecraft_geometry']='FULL_SSOT_BUS_HULL_8_PANELS';r['solver_selection_policy']='IE_MLFMM_OR_HYBRID_FIRST'
  for idx,(i,d) in enumerate(zip(ids,datasets)):
   bindings.append(dict(dataset_id=d,project_file=r['project_file'],installation_id=i,pattern_class='InstalledPattern' if i else 'FreeSpacePattern',frequencies_ghz=[float(r[k]) for k in ['f_low_ghz','f_center_ghz','f_high_ghz']],directory='data/closed_network_patterns/'+d,port_numbers=list(range(idx*4+1,idx*4+5)),source_variant=r['configuration']))
 return rows,bindings

def main():
 import argparse
 parser=argparse.ArgumentParser();parser.add_argument('--metadata-only',action='store_true');args=parser.parse_args()
 rows,bindings=inventory_and_bindings();g=geometry();write_json(ROOT/'cst/closed_network/full_spacecraft_geometry.json',g);app=None if args.metadata_only else connect_cst(False)
 for r in sorted(rows,key=lambda r:0 if r['antenna']=='ISL' else 1 if r['antenna']=='SBA' else 2):
  if r['configuration']=='ATTACKER_ORIGINAL':
   if not args.metadata_only:prepare_installed(r,app,g)
 for b in bindings:
  directory=ROOT/b['directory'];directory.mkdir(parents=True,exist_ok=True)
  (directory/'README.md').write_text('# '+b['dataset_id']+'\n\nSeparate raw export for installation '+(b['installation_id'] or 'ORIGINAL')+'.\nProject: '+b['project_file']+'\nPort group: '+str(b['port_numbers'])+'\nAntennna-local XZ/YZ cuts; no gain floor.\n'+''.join(f'- f{f:.6f}_{plane}.csv\n' for f in b['frequencies_ghz'] for plane in ['XZ','YZ']),encoding='utf-8')
 for r in rows:
  e=json.loads((ROOT/r['project_file']).with_suffix('.preflight.json').read_text());r['port_status']=f"VERIFIED_{e['ports']}_RIGID_PORTS";r['solver_status']=e['solver_status'];r['expected_output_directory']=';'.join(b['directory'] for b in bindings if b['project_file']==r['project_file']);r['dataset_ids']=';'.join(r['dataset_ids'])
  r['analysis_role']='REFERENCE_ONLY' if r['configuration']=='ORIGINAL' else 'PRIMARY_PATTERN'
  if r['configuration']=='ATTACKER_ORIGINAL':r['configuration']='ATTACKER_INSTALLED'
 columns=list(rows[0]);
 with (CN/'project_inventory.csv').open('w',encoding='utf-8',newline='') as f:w=csv.DictWriter(f,fieldnames=columns);w.writeheader();w.writerows(rows)
 write_json(CN/'dataset_bindings.json',bindings)
 plan=json.loads((ROOT/'analysis/closed_network/rfi_plan.json').read_text());by_key={(b['project_file'],b['installation_id']):b for b in bindings}
 oldrows=json.loads((CN/'source_inventory.json').read_text());oldmap={Path(r['expected_output_directory']).name:r['project_file'] for r in oldrows}
 for r in plan:
  oldid=r['tx_dataset'];project=oldmap.get(oldid)
  if project is None:continue
  b=by_key.get((project,r['tx_installation']),by_key.get((project,'')));r['tx_dataset']=b['dataset_id'];r['tx_pattern_state']=b['pattern_class']
  if not r['tx_configuration'].startswith('FEED'):r['tx_configuration']='INSTALLED'
 filtered=[]
 for r in plan:
  if r['rx_configuration']=='ORIGINAL':continue
  filtered.append(r)
 write_json(ROOT/'analysis/closed_network/rfi_plan.json',filtered)
 print('22 physical projects; '+str(len(bindings))+' pattern bindings; installed SBA/ISL attackers; KAA standalone; GPS installed; SAR baseline.',flush=True)
if __name__=='__main__':main()
