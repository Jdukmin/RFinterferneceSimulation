"""Clone fixed CST models; prepare complete SSOT hull; never start any solver."""
import csv,json,hashlib,shutil,sys,math,argparse
from pathlib import Path
import numpy as np
from cst_com_common import connect_cst,method,add_to_history,get_active_project
from cst_com import save,monitor
ROOT=Path(__file__).resolve().parent.parent;OUT=ROOT/'cst/projects/closed_network'
BANDS={'STM':[2.2,2.25,2.3],'L1':[1.563,1.57542,1.588],'SAR':[8.9,9.65,10.4],'ISL':[10.55,10.6,10.65]}
BASE={'KAA':'KA_FEED_C_OEWG','SBA':'SBAND_MATCHING_WIRE15','GPS':'LBAND_GNSS_FINAL_COMPROMISE','ISL':'ISL_C4_CUP_R14P7','SAR':None}

def table(p):
 with (ROOT/p).open(encoding='utf-8-sig') as f:return list(csv.DictReader(line for line in f if not line.startswith('#')))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write_json(p,obj):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8')
def inventory():
 rows=[]
 def add(family,name,config,band,installation=None,source=None,missing=''):
  rows.append(dict(project_file=f'cst/projects/closed_network/{family.lower()}/{name}.cst',antenna=family,configuration=config,victim_band=band,
   f_low_ghz=BANDS[band][0],f_center_ghz=BANDS[band][1],f_high_ghz=BANDS[band][2],spacecraft_geometry='FULL_SSOT_BUS_HULL_8_PANELS' if installation else 'NONE',
   port_status='PENDING',monitor_status='PENDING',solver_status='INPUT_MISSING' if missing else 'NOT_GENERATED',expected_output_directory='data/closed_network_patterns/'+name.replace('RFC_',''),
   installation_identity=installation or '',source_project=source or ('cst/projects/'+BASE[family]+'.cst' if BASE[family] else ''),missing_input=missing))
 for band in BANDS:
  add('KAA','RFC_KAA_FEED_ONLY_'+band,'FEED_ONLY',band)
  add('KAA','RFC_KAA_WITH_REFLECTOR_'+band,'FEED_WITH_REFLECTOR',band,source='cst/projects/closed_network/kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.cst')
 for family,band,identities in [('SBA','STM',['SBA_NADIR','SBA_ZENITH']),('GPS','L1',['GPSA_1','GPSA_2']),('ISL','ISL',['ISL'])]:
  add(family,'RFC_'+('SBA_TM' if family=='SBA' else 'GPS_L1' if family=='GPS' else 'ISL')+'_ORIGINAL','ORIGINAL',band)
  for identity in identities:
   suffix=identity.replace('SBA_','') if family=='SBA' else identity.replace('_','') if family=='GPS' else 'RX'
   add(family,'RFC_INSTALLED_'+('SBA_TM_' if family=='SBA' else 'GPS_L1_' if family=='GPS' else 'ISL_')+suffix,'INSTALLED',band,identity)
 for family,bands in [('ISL',['SAR','STM','L1']),('SBA',['ISL','SAR','L1'])]:
  for band in bands:add(family,'RFC_'+('ISL_TX' if family=='ISL' else 'SBA_TC')+'_ORIGINAL_'+band,'ATTACKER_ORIGINAL',band)
 return rows

def geometry():
 ds='data/spacecraft/simplified_spacecraft_v1/'
 vertices={r['vertex_id']:np.array([float(r['y_mm']),float(r['z_mm'])]) for r in table(ds+'hull_cross_section.csv')}
 pars={r['key']:r['value'] for r in table(ds+'hull_parameters.csv')};lo=float(pars['x_min_mm']);hi=float(pars['x_max_mm'])
 faces=[];normals={}
 for r in table(ds+'panels.csv'):
  normals[r['panel_id']]=np.array([float(r[k]) for k in ['n_x','n_y','n_z']])
  if r['kind']=='SIDE':
   y0,z0=vertices[r['vertex_from']];y1,z1=vertices[r['vertex_to']];pts=[[lo,y0,z0],[hi,y0,z0],[hi,y1,z1],[lo,y1,z1]]
  else:
   x=float(pars[r['face_x_ref']]);pts=[[x,*v] for v in vertices.values()]
  faces.append(dict(panel_id=r['panel_id'],body_vertices_mm=np.array(pts).tolist(),material='PEC',surface_type='SSOT_ZERO_THICKNESS_OUTER_PANEL'))
 installations=[]
 for r in table(ds+'antenna_installations.csv'):
  pos=np.array([float(r[k]) for k in ['x_mm','y_mm','z_mm']]);z=normals[r['panel_id']];z=z/np.linalg.norm(z)
  # Existing CstLocalFrameAdapter: local +Z boresight; local +X body +X orthogonalized.
  x=np.array([1.,0.,0.]);x=x-z*np.dot(x,z);x/=np.linalg.norm(x);y=np.cross(z,x);rotation=np.column_stack([x,y,z])
  assert np.linalg.norm(rotation.T@rotation-np.eye(3))<1e-8 and abs(np.linalg.det(rotation)-1)<1e-8
  installations.append(dict(installation_id=r['antenna_id'],position_body_mm=pos.tolist(),nominal_R_BL=rotation.tolist(),mount_type=r['mount_type'],panel_id=r['panel_id']))
 files=[ds+f for f in ['hull_parameters.csv','hull_cross_section.csv','panels.csv','antenna_installations.csv','steering_constraints.csv']]
 return dict(model_class='FULL_SSOT_BUS_HULL_8_PANELS',mechanical_cad_fidelity='SIMPLIFIED_BUS_HULL_NOT_COMPLETE_SATELLITE_CAD',full_outer_panels=faces,installations=installations,cropped=False,source_hashes={f:sha(ROOT/f) for f in files},
  external_metal_geometry='Only eight outer panels are defined as structures by SimplifiedSpacecraftBuilder. Gimbal/antenna references included as coordinate metadata; no invented bracket/radome/reflector/SAR CAD.',
  material_provenance='PEC sheet treatment retained from existing CST installed-facet model; SSOT specifies outer surfaces but no wall thickness')

def solids(p):
 s=method(p,'Solid');d={}
 for i in range(int(method(s,'GetNumberOfShapes'))):
  name=method(s,'GetNameOfShapeFromIndex',i);d[name]=dict(volume_mm3=method(s,'GetVolume',name),material=method(s,'GetMaterialNameForShape',name))
 return d

def full_hull(p,g,identity):
 inst=next(r for r in g['installations'] if r['installation_id']==identity);rotation=np.array(inst['nominal_R_BL']);origin=np.array(inst['position_body_mm'])
 records=[]
 for facet in g['full_outer_panels']:
  points=(np.array(facet['body_vertices_mm'])-origin)@rotation
  name=facet['panel_id'];curve='full_'+name
  code=f'Curve.NewCurve "{curve}"\nWith Polygon3D\n .Reset\n .Name "outline"\n .Curve "{curve}"\n'
  for point in np.vstack([points,points[0]]):code+=' .Point '+', '.join(f'"{v:.12g}"' for v in point)+'\n'
  code+=' .Create\nEnd With\n'
  code+=f'With CoverCurve\n .Reset\n .Name "{name}"\n .Component "FULL_SPACECRAFT"\n .Material "PEC"\n .Curve "{curve}:outline"\n .Create\nEnd With'
  add_to_history(p,'Full SSOT outer panel '+name,code)
  assert np.max(np.abs(points@rotation.T+origin-np.array(facet['body_vertices_mm'])))<1e-8
  records.append(dict(panel_id=name,local_vertices_mm=points.tolist()))
 return dict(installation=inst,panels=records,global_solver_frame='UNCHANGED_NATIVE_ANTENNA_CST_LOCAL',body_transform='p_B=R_BL*p_L+installation_position_B; all eight whole panels; no crops',antenna_or_ports_transformed=False)

def prepare(row,app,g,force=False):
 dest=ROOT/row['project_file'];evidence=dest.with_suffix('.preflight.json')
 if evidence.exists() and not force:
  previous=json.loads(evidence.read_text());assert previous['source_sha256']==sha(ROOT/row['source_project']);assert previous['project_sha256']==sha(dest)
  return previous
 if dest.exists():raise FileExistsError('Refuse overwrite; inspect '+str(dest))
 source=ROOT/row['source_project'];before=sha(source);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
 p=method(app,'OpenFile',str(dest.resolve()));p=p or get_active_project(app)
 initial=solids(p);ports=int(method(method(p,'Port'),'StartPortNumberIteration'))
 assert ports==4,(dest,ports)
 frequencies=BANDS[row['victim_band']]
 add_to_history(p,'Victim band analysis; fixed antenna geometry',f'ChangeSolverType "HF Time Domain"\nSolver.FrequencyRange "{frequencies[0]}", "{frequencies[-1]}"')
 m=method(p,'Monitor');names=[method(m,'GetMonitorNameFromIndex',i) for i in range(int(method(m,'GetNumberOfMonitors')))]
 wanted=[f'farfield (f={f:g})' for f in frequencies]
 for name in names:
  if name not in wanted:add_to_history(p,'Remove unrelated monitor '+name,'Monitor.Delete "'+name+'"')
 for f,name in zip(frequencies,wanted):
  if name not in names:monitor(p,f)
 installation=full_hull(p,g,row['installation_identity']) if row['installation_identity'] else None
 final=solids(p)
 for name,original in initial.items():
  assert name in final and final[name]['material']==original['material']
  assert abs(final[name]['volume_mm3']-original['volume_mm3'])<=1e-7*max(1,abs(original['volume_mm3']))
 assert int(method(method(p,'Port'),'StartPortNumberIteration'))==ports
 # Configure original quadrature without Run: no solver and no result-combination run today.
 phases=[0,90,180,270] if row['antenna']=='SBA' else [0,-90,-180,-270]
 combine=method(p,'CombineResults');method(combine,'Reset');method(combine,'SetMonitorType','frequency');method(combine,'FarfieldsOnly',True)
 method(combine,'EnableAutomaticLabeling',False);method(combine,'SetLabel','CLOSED_NETWORK_FIXED_PHASES')
 for i,phase in enumerate(phases):method(combine,'SetPortModeValues',i+1,1,1.,phase)
 mesh=method(p,'Mesh');method(mesh,'Update');lines=[int(method(mesh,'GetN'+axis)) for axis in 'xyz'];assert min(lines)>=2
 cells=math.prod(n-1 for n in lines)
 monitors=[method(m,'GetMonitorNameFromIndex',i) for i in range(int(method(m,'GetNumberOfMonitors')))];assert sorted(monitors)==sorted(wanted)
 save(p,dest);method(p,'Quit');assert sha(source)==before
 result=dict(project_file=row['project_file'],source_project=row['source_project'],source_sha256=before,project_sha256=sha(dest),solver_started=False,solver_status='READY_NOT_SOLVED',
  source_solids=initial,antenna_geometry_preserved_by_native_clone=True,source_materials_and_volumes_unchanged=True,ports=ports,port_geometry_preserved_by_no_port_edit=True,
  phases_deg=phases,monitor_frequencies_ghz=frequencies,verified_monitor_names=monitors,solver='HF Time Domain',boundaries='INHERITED_SOURCE_OPEN_ADD_SPACE',mesh_line_counts=lines,mesh_cells=cells,
  mesh_memory_128bytes_per_cell_gib_lower_planning_estimate=cells*128/1024**3,mesh_convergence='NOT_ESTABLISHED; closed network mesh/convergence check required',
  installed_geometry=installation,readiness_scope='Project configuration / mesh only; no claim of excitation propagation/normalization/convergence before solve')
 write_json(evidence,result);print(json.dumps(dict(project=dest.name,cells=cells,solver_started=False)),flush=True)
 return result

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--plan-only',action='store_true');args=parser.parse_args()
 g=geometry();write_json(ROOT/'cst/closed_network/full_spacecraft_geometry.json',g);rows=inventory();records=[]
 app=None if args.plan_only else connect_cst(False)
 for row in rows:
  output=ROOT/row['expected_output_directory'];output.mkdir(parents=True,exist_ok=True)
  filenames=[f'f{f:.6f}_{plane}.csv' for f in BANDS[row['victim_band']] for plane in ['XZ','YZ']]
  (output/'README.md').write_text('# '+output.name+'\n\nRAW CST exports only; do not clip/floor.\n\nExpected files (GHz, six decimals):\n\n'+''.join('- '+name+'\n' for name in filenames)+'\nOptional: corresponding _3D.csv. Preserve raw_s_matrix.npz, solver/convergence logs and provenance.json. No solved results are supplied by project preparation. Missing/failed data must never be replaced by zero or another pattern.\n',encoding='utf-8')
  if row['missing_input']:continue
  evidence=ROOT/row['project_file'];evidence=evidence.with_suffix('.preflight.json')
  if args.plan_only:
   if evidence.exists():record=json.loads(evidence.read_text())
   else:continue
  else:
   try:record=prepare(row,app,g)
   except Exception as e:row['solver_status']='FAILED_PREPARATION';row['missing_input']=str(e);write_json(evidence,dict(solver_started=False,status='FAILED_PREPARATION',error=str(e)));raise
  record['solver_selection_policy']='LICENSED_CST_RESOURCE_AND_PORT_COMPATIBILITY_REVIEW; NOT_FORCED_TIME_DOMAIN'
  record['preferred_solver_review']='IE_MLFMM_OR_HYBRID' if row['configuration']=='INSTALLED' else 'TD_OR_FD; IE_OR_HYBRID_IF_RESOURCES_REQUIRE'
  if row['configuration']=='FEED_WITH_REFLECTOR':
   common=(ROOT/row['source_project']).with_suffix('.geometry.json')
   record['surrogate_surface_geometry_sha256']=json.loads(common.read_text())['surface_geometry_sha256']
   record['geometry_provenance']='OWNER_AUTHORIZED_KARMA7_FG_ENGINEERING_SURROGATE; NOT_VENDOR_CAD'
  write_json(evidence,record)
  row.update(port_status='NATIVE_PORTS_PRESERVED_4',monitor_status='VERIFIED_3_EDGE_CENTER',solver_status=record['solver_status']);records.append(record)
 for row in rows:
  row['saved_solver']='HF Time Domain'
  row['solver_selection_policy']='IE_MLFMM_OR_HYBRID_FIRST' if row['configuration']=='INSTALLED' else 'TD_FD_WITH_RESOURCE_REVIEW'
 columns=['project_file','antenna','configuration','victim_band','f_low_ghz','f_center_ghz','f_high_ghz','spacecraft_geometry','port_status','monitor_status','solver_status','expected_output_directory','installation_identity','source_project','missing_input','saved_solver','solver_selection_policy']
 with (ROOT/'docs/closed_network_cst_project_inventory.csv').open('w',encoding='utf-8',newline='') as f:
  w=csv.DictWriter(f,fieldnames=columns);w.writeheader();w.writerows(rows)
 summary=dict(completion_status='INCOMPLETE_INPUT_MISSING' if any(r['solver_status']!='READY_NOT_SOLVED' for r in rows) else 'COMPLETE',planned_projects=len(rows),saved_projects=len(records),
  missing_projects=[r for r in rows if r['solver_status']!='READY_NOT_SOLVED'],solver_started=False,ssot_bus_hull_panels=8,complete_satellite_cad=False,crops_used=False,original_feed_geometry_changed=False,reflector_surrogate_created=True,records=records)
 write_json(ROOT/'docs/closed_network_preparation_validation.json',summary)
 print('Preparation:',summary['completion_status'],len(records),'saved /',len(rows),'planned',flush=True)
if __name__=='__main__':main()
