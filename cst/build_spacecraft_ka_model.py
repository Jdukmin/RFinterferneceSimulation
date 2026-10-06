"""Geometry-only spacecraft + two equivalent Ka paraboloid PEC surfaces.

No Mesh.Update, Solver.Start, excitation, or radiation result is produced.
AnalyticalFace syntax verified in CST 2026 installed Spherical Grid/NASA Almond macros.
CoverCurve syntax already exercised in the local-scattering workstream.
"""
import argparse,csv,hashlib,json,math
from pathlib import Path
import numpy as np
from cst_com import new_project,save
from cst_com_common import add_to_history,method

ROOT=Path(__file__).resolve().parent.parent
DS=ROOT/'data/spacecraft/simplified_spacecraft_v1'
OUT=ROOT/'output/codex/spacecraft_ka_model'
PROJECT=ROOT/'cst/projects/SPACECRAFT_KA_MODEL_ONLY_V2.cst'
def table(path):
    return list(csv.DictReader(l for l in path.read_text(encoding='utf-8-sig').splitlines() if not l.startswith('#')))
def sheet(name,points):
    curve='outline_'+name
    code=f'WCS.ActivateWCS "global"\nCurve.NewCurve "{curve}"\nWith Polygon3D\n .Reset\n .Name "outline"\n .Curve "{curve}"\n'
    for v in points+[points[0]]:code+=' .Point '+', '.join(f'"{float(q):.12g}"' for q in v)+'\n'
    return code+f''' .Create
End With
With CoverCurve
 .Reset
 .Name "{name}"
 .Component "SPACECRAFT_PEC"
 .Material "PEC"
 .Curve "{curve}:outline"
 .Create
End With'''
def reflector(name,position,frame,focal,radius):
    expressions=['u*cos(v)','u*sin(v)',f'u*u/(4*{focal:.14g})']
    laws=[]
    for i in range(3):
        laws.append(f'{position[i]:.14g}'+''.join(f'+({frame[i,j]:.14g})*({expressions[j]})' for j in range(3)))
    return f'''WCS.ActivateWCS "global"
With AnalyticalFace
 .Reset
 .Name "equivalent_paraboloid"
 .Component "{name}"
 .Material "PEC"
 .LawX "{laws[0]}"
 .LawY "{laws[1]}"
 .LawZ "{laws[2]}"
 .ParameterRangeU "0", "{radius:.14g}"
 .ParameterRangeV "0", "2*pi"
 .Create
End With'''
def stl(path,triangles):
    with path.open('w',encoding='ascii') as stream:
        stream.write('solid spacecraft_ka_model_only\n')
        for tri in triangles:
            a,b,c=np.array(tri); n=np.cross(b-a,c-a); length=np.linalg.norm(n)
            if length<1e-12:continue
            n/=length;stream.write(' facet normal '+' '.join(f'{x:.10g}' for x in n)+'\n  outer loop\n')
            for v in tri:stream.write('   vertex '+' '.join(f'{x:.10g}' for x in v)+'\n')
            stream.write('  endloop\n endfacet\n')
        stream.write('endsolid spacecraft_ka_model_only\n')
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--build-cst',action='store_true');args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    vertices={r['vertex_id']:[float(r['y_mm']),float(r['z_mm'])] for r in table(DS/'hull_cross_section.csv')}
    params={r['key']:r['value'] for r in table(DS/'hull_parameters.csv')}; xmin=float(params['x_min_mm']);xmax=float(params['x_max_mm'])
    panels=table(DS/'panels.csv'); normal={r['panel_id']:np.array([float(r[k]) for k in ['n_x','n_y','n_z']]) for r in panels}
    installations=table(DS/'antenna_installations.csv'); optical=json.loads((ROOT/'data/Kaband_KAA_CST/ka_final_validation.json').read_text())['reflector']
    diameter=optical['D_mm'];focal=optical['Fe_mm'];radius=diameter/2
    blocks=[]; faces=[]; triangles=[]
    def add(name,points):
        blocks.append((name,sheet(name,points)));faces.append({'name':name,'body_points_mm':points})
        for j in range(1,len(points)-1):triangles.append([points[0],points[j],points[j+1]])
    for row in panels:
        if row['kind']=='SIDE':
            a=vertices[row['vertex_from']];b=vertices[row['vertex_to']]
            add(row['panel_id'],[[xmin,*a],[xmin,*b],[xmax,*b],[xmax,*a]])
        else:
            x=xmin if row['face_x_ref']=='x_min_mm' else xmax
            points=[[x,*v] for v in vertices.values()]
            if x==xmin:points.reverse()
            add(row['panel_id'],points)
    dishes=[]
    for row in installations:
        if not row['antenna_id'].startswith('KAA_'):continue
        pos=np.array([float(row[k]) for k in ['x_mm','y_mm','z_mm']]);z=normal[row['panel_id']];z=z/np.linalg.norm(z)
        x=np.array([1.,0,0]);y=np.cross(z,x);frame=np.column_stack([x,y,z]);assert np.allclose(frame.T@frame,np.eye(3))
        name=row['antenna_id'];blocks.append((name,reflector(name,pos,frame,focal,radius)))
        nrad=24;nphi=96
        def point(r,phi):return (pos+frame@np.array([r*math.cos(phi),r*math.sin(phi),r*r/(4*focal)])).tolist()
        for ri in range(nrad):
            r0=radius*ri/nrad;r1=radius*(ri+1)/nrad
            for pi in range(nphi):
                a=2*math.pi*pi/nphi;b=2*math.pi*(pi+1)/nphi
                p0=point(r0,a);p1=point(r1,a);p2=point(r1,b);p3=point(r0,b)
                triangles.append([p0,p1,p2])
                if ri>0:triangles.append([p0,p2,p3])
        dishes.append({'name':name,'reference_mm':pos.tolist(),'reference_is_assumed_vertex':True,'panel':row['panel_id'],'boresight_body':z.tolist(),'local_to_body_rotation':frame.tolist(),'diameter_mm':diameter,'equivalent_focal_length_mm':focal,'rim_depth_mm':radius*radius/(4*focal),'optical_focus_reference_mm':(pos+focal*z).tolist(),'geometry_status':'EQUIVALENT_PARABOLOID_NOT_ACTUAL_CASSEGRAIN','source':'data/Kaband_KAA_CST/ka_final_validation.json'})
    history="' GEOMETRY ONLY; NO PORTS, NO MESH, NO SOLVER\n"+'\n\n'.join(f"'@@ {name}\n{code}" for name,code in blocks)
    (OUT/'geometry_history.vba').write_text(history,encoding='utf-8')
    stl(OUT/'spacecraft_ka_reference_mm.stl',triangles)
    sourcepaths=['hull_cross_section.csv','hull_parameters.csv','panels.csv','antenna_installations.csv','steering_constraints.csv']
    metadata={'status':'GEOMETRY_GENERATED_CST_NOT_YET_BUILT','units':'mm','project':str(PROJECT),'body_x_extent_mm':[xmin,xmax],'body_faces':faces,'reflectors':dishes,'installation_references':installations,'expected_pec_shapes':10,'em_ports':0,'mesh_generated':False,'solver_started':False,'material':'ideal PEC sheets; actual materials/thickness not supplied','stl_units':'mm (STL itself has no unit field)','stl_is_cad_tessellation_not_em_mesh':True,'limitations':['Ka vertex mapped to installation reference is an explicit geometry assumption','Focal length is an equivalent optical model, not actual product height','44 mm subreflector value is blockage in aperture integration; no actual hyperboloid/feed/strut/hinge dimensions supplied','Other antennas are reference positions in metadata, not imported radiating solids or ports','No solar arrays/radomes/brackets/cables/material loss/thermal distortion supplied'],'source_hashes':{f:hashlib.sha256((DS/f).read_bytes()).hexdigest() for f in sourcepaths}}
    if args.build_cst:
        if PROJECT.exists():raise FileExistsError(PROJECT)
        app,p=new_project(1.,27.)
        for name,code in blocks:add_to_history(p,'Model only '+name,code)
        number=int(method(method(p,'Solid'),'GetNumberOfShapes'));assert number==10,number
        save(p,PROJECT)
        metadata.update(status='CST_GEOMETRY_BUILD_VERIFIED_NO_MESH_NO_SOLVE',actual_pec_shapes=number)
    (OUT/'model_manifest.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'status':metadata['status'],'shapes':metadata.get('actual_pec_shapes'),'path':str(PROJECT),'mesh_generated':False,'solver_started':False}),flush=True)
if __name__=='__main__':main()
