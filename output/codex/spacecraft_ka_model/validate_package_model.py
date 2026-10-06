"""Verify SSOT geometry, render reference preview, package geometry-only transfer."""
import csv,hashlib,json,zipfile
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

OUT=Path(__file__).resolve().parent; ROOT=OUT.parents[2]
m=json.loads((OUT/'model_manifest.json').read_text(encoding='utf-8'))
project=Path(m['project']); assert project.exists() and m['actual_pec_shapes']==10
assert m['em_ports']==0 and not m['mesh_generated'] and not m['solver_started']
def rows(path):return list(csv.DictReader(l for l in path.read_text(encoding='utf-8-sig').splitlines() if not l.startswith('#')))
ds=ROOT/'data/spacecraft/simplified_spacecraft_v1'
normals={r['panel_id']:np.array([float(r[k]) for k in ['n_x','n_y','n_z']]) for r in rows(ds/'panels.csv')}
for face in m['body_faces']:
    points=np.array(face['body_points_mm']); n=np.cross(points[1]-points[0],points[2]-points[0]);n/=np.linalg.norm(n)
    assert np.dot(n,normals[face['name']])>0.9999999
for r in m['reflectors']:
    frame=np.array(r['local_to_body_rotation']); assert np.allclose(frame.T@frame,np.eye(3),atol=1e-12)
    assert np.isclose(np.linalg.det(frame),1) and r['diameter_mm']==220
    assert np.allclose(frame[:,2],normals[r['panel']]/np.linalg.norm(normals[r['panel']]))
    assert abs(r['rim_depth_mm']-(110**2/(4*r['equivalent_focal_length_mm'])))<1e-12
for name,expected in m['source_hashes'].items():assert hashlib.sha256((ds/name).read_bytes()).hexdigest()==expected
fig=plt.figure(figsize=(15,5.8)); axes=[fig.add_subplot(1,3,i+1,projection='3d') for i in range(3)]
ax=axes[0];faces=[np.array(f['body_points_mm']) for f in m['body_faces']]
ax.add_collection3d(Poly3DCollection(faces,alpha=.13,facecolor='#8ba7c0',edgecolor='#586777',linewidth=.5))
for r in m['installation_references']:
    p=np.array([float(r[k]) for k in ['x_mm','y_mm','z_mm']]);ax.scatter(*p,s=14);ax.text(*p,r['antenna_id'],fontsize=6)
ax.set_xlim(0,6700);ax.set_ylim(-1500,1600);ax.set_zlim(-1500,1300);ax.set_box_aspect((6.7,3.1,2.8));ax.view_init(elev=22,azim=-55)
ax.set_title('Saved SSOT spacecraft + antenna references\nPEC shell; references are not radiating solids',fontsize=10)
for ax,r in zip(axes[1:],m['reflectors']):
    f=r['equivalent_focal_length_mm']; u,v=np.meshgrid(np.linspace(0,110,24),np.linspace(0,2*np.pi,96))
    ax.plot_surface(u*np.cos(v),u*np.sin(v),u*u/(4*f),color='#cd9443',alpha=.85,linewidth=0)
    ax.set_xlim(-120,120);ax.set_ylim(-120,120);ax.set_zlim(0,90);ax.set_box_aspect((240,240,90))
    ax.set_title(f"{r['name']}: equivalent paraboloid in local frame\nD=220 mm; depth={r['rim_depth_mm']:.3f} mm",fontsize=10)
    ax.set_xlabel('local X [mm]');ax.set_ylabel('local Y [mm]');ax.set_zlabel('local Z [mm]')
axes[0].set_xlabel('body X [mm]');axes[0].set_ylabel('body Y [mm]');axes[0].set_zlabel('body Z [mm]')
fig.tight_layout();fig.savefig(OUT/'geometry_preview.png',dpi=160);plt.close(fig)
files=[project]
files.extend(p for p in project.with_suffix('').rglob('*') if p.is_file() and 'Temp' not in p.parts and p.suffix not in ['.lok','.lck'])
files.extend([OUT/'geometry_history.vba',OUT/'model_manifest.json',OUT/'spacecraft_ka_reference_mm.stl',ROOT/'docs/guides/closed_network_cst_simulation.md',ROOT/'cst/build_spacecraft_ka_model.py'])
files.extend(ds.glob('*.csv'))
hashes=[{'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in sorted(files)]
with (OUT/'transfer_hashes.csv').open('w',newline='',encoding='utf-8') as stream:
    writer=csv.DictWriter(stream,fieldnames=['path','sha256','bytes']);writer.writeheader();writer.writerows(hashes)
with zipfile.ZipFile(OUT/'closed_network_model_bundle.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for p in files:archive.write(p,p.relative_to(ROOT).as_posix())
    archive.write(OUT/'transfer_hashes.csv',(OUT/'transfer_hashes.csv').relative_to(ROOT).as_posix())
(OUT/'geometry_validation.json').write_text(json.dumps({'status':'PASS','cst_shapes':10,'body_outward_normals':'PASS','ka_frames_and_dimensions':'PASS','source_hashes':'PASS','project_sha256':hashlib.sha256(project.read_bytes()).hexdigest(),'mesh_or_solve_executed':False,'bundle_scope':'geometry-only project and source/SSOT; separate antenna projects and RF analysis dependencies must also be transferred per guide'},indent=2)+'\n',encoding='utf-8')
print('PASS: 10 CST shapes, SSOT normals/frames/hashes; geometry-only bundle created')
