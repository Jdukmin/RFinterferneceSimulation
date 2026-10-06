"""Closed-network fixed-body geometry and cut frames; no solver or geometry tuning."""
import csv,json,hashlib,math
from pathlib import Path
import numpy as np
from cst_com_common import method,add_to_history
ROOT=Path(__file__).resolve().parents[2]
BANDS={"STM":[2.2,2.25,2.3],"L1":[1.563,1.57542,1.588],"SAR":[8.9,9.65,10.4],"ISL":[10.55,10.6,10.65]}
def table(p):
 with (ROOT/p).open(encoding='utf-8-sig') as f:return list(csv.DictReader(line for line in f if not line.startswith('#')))

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def write_json(p,obj):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8')

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
  faces.append(dict(panel_id=r['panel_id'],body_vertices_mm=np.array(pts).tolist(),outward_normal_body=normals[r['panel_id']].tolist(),material='PEC',surface_type='SSOT_ZERO_THICKNESS_OUTER_PANEL'))
 installations=[]
 for r in table(ds+'antenna_installations.csv'):
  panel_id='PANEL_7' if r['antenna_id']=='ISL' else r['panel_id']
  pos=np.array([float(r[k]) for k in ['x_mm','y_mm','z_mm']]);z=normals[panel_id];z=z/np.linalg.norm(z)
  # Existing CstLocalFrameAdapter: local +Z boresight; local +X body +X orthogonalized.
  x=np.array([0.,1.,0.]) if abs(z[0])>.99 else np.array([1.,0.,0.]);x=x-z*np.dot(x,z);x/=np.linalg.norm(x);y=np.cross(z,x);rotation=np.column_stack([x,y,z])
  assert np.linalg.norm(rotation.T@rotation-np.eye(3))<1e-8 and abs(np.linalg.det(rotation)-1)<1e-8
  installations.append(dict(installation_id=r['antenna_id'],position_body_mm=pos.tolist(),nominal_R_BL=rotation.tolist(),mount_type=r['mount_type'],panel_id=panel_id,orientation_provenance='OWNER_PLUS_X_END_FACE_OVERRIDE' if r['antenna_id']=='ISL' else 'SSOT_PANEL_NORMAL'))
 files=[ds+f for f in ['hull_parameters.csv','hull_cross_section.csv','panels.csv','antenna_installations.csv','steering_constraints.csv']]
 return dict(model_class='FULL_SSOT_BUS_HULL_8_PANELS',mechanical_cad_fidelity='SIMPLIFIED_BUS_HULL_NOT_COMPLETE_SATELLITE_CAD',full_outer_panels=faces,installations=installations,cropped=False,source_hashes={f:sha(ROOT/f) for f in files},
  external_metal_geometry='Only eight outer panels are defined as structures by SimplifiedSpacecraftBuilder. Gimbal/antenna references included as coordinate metadata; no invented bracket/radome/reflector/SAR CAD.',
  material_provenance='PEC sheet treatment retained from existing CST installed-facet model; SSOT specifies outer surfaces but no wall thickness')

def solids(p):
 s=method(p,'Solid');d={}
 for i in range(int(method(s,'GetNumberOfShapes'))):
  name=method(s,'GetNameOfShapeFromIndex',i);d[name]=dict(volume_mm3=method(s,'GetVolume',name),material=method(s,'GetMaterialNameForShape',name))
 return d

def port_coordinates(p):
 import pythoncom,win32com.client
 obj=method(p,'DiscretePort');rows=[]
 for no in range(1,5):
  args=[win32com.client.VARIANT(pythoncom.VT_BYREF|pythoncom.VT_R8,0) for _ in range(6)]
  assert method(obj,'GetCoordinates',no,*args)
  rows.append([v.value for v in args])
 return np.array(rows)

def full_hull(p,g,identity):
 inst=next(r for r in g['installations'] if r['installation_id']==identity);rotation=np.array(inst['nominal_R_BL']);origin=np.array(inst['position_body_mm'])
 records=[]
 for facet in g['full_outer_panels']:
  points=np.array(facet['body_vertices_mm'])
  name=facet['panel_id'];curve='full_'+name
  code=f'Curve.NewCurve "{curve}"\nWith Polygon3D\n .Reset\n .Name "outline"\n .Curve "{curve}"\n'
  for point in np.vstack([points,points[0]]):code+=' .Point '+', '.join(f'"{v:.12g}"' for v in point)+'\n'
  code+=' .Create\nEnd With\n'
  code+=f'With CoverCurve\n .Reset\n .Name "{name}"\n .Component "FULL_SPACECRAFT"\n .Material "PEC"\n .Curve "{curve}:outline"\n .Create\nEnd With'
  add_to_history(p,'Full SSOT outer panel '+name,code)
  assert np.max(np.abs(points-np.array(facet['body_vertices_mm'])))<1e-8
  records.append(dict(panel_id=name,body_vertices_mm=points.tolist(),outward_normal_body=facet['outward_normal_body']))
 return dict(installation=inst,panels=records,global_solver_frame='SPACECRAFT_BODY_FIXED',body_transform='Hull remains SSOT body coordinates; antenna and port endpoints p_B=R_BL*p_L+position_B',antenna_or_ports_transformed=True)

def local_cut_direction_in_solver(theta,phi,evidence):
 th=math.radians(theta);ph=math.radians(phi)
 d=np.array([math.sin(th)*math.cos(ph),math.sin(th)*math.sin(ph),math.cos(th)])
 if evidence.get('installed_geometry'):
  d=np.array(evidence['installed_geometry']['installation']['nominal_R_BL'])@d
 return math.degrees(math.acos(float(np.clip(d[2],-1,1)))),math.degrees(math.atan2(d[1],d[0]))%360
