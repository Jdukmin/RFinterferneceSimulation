"""Owner-authorized engineering reflector surrogate; fixed native feed; NO solver."""
import json, math, shutil, hashlib
import numpy as np
from prepare_closed_network import ROOT, sha, solids, write_json
from cst_com_common import connect_cst, method, get_active_project, add_to_history
from cst_com import save

BASE=ROOT/'cst/projects/closed_network/kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.cst'
SEED=ROOT/'cst/results/KA_REFLECTOR_KA_FEED_C_OEWG/reflector_validation.json'
FEED=ROOT/'cst/projects/KA_FEED_C_OEWG.cst'

def surface(name, radius, rings, height, sectors=64):
    faces=[]
    for ring in range(rings):
        r0=radius*ring/rings;r1=radius*(ring+1)/rings
        for j in range(sectors):
            def p(r,k):
                t=2*math.pi*k/sectors;return [r*math.cos(t),r*math.sin(t),height(r)]
            a,b,c,d=p(r0,j),p(r1,j),p(r1,j+1),p(r0,j+1)
            faces.append(dict(name=f'{name}_{ring}_{j}_a',vertices_mm=[a,b,c]))
            if ring:faces.append(dict(name=f'{name}_{ring}_{j}_b',vertices_mm=[a,c,d]))
    return faces

def geometry():
    seed=json.loads(SEED.read_text())['reflector'];D=seed['D_mm'];F=seed['Fe_mm'];Ds=seed['Ds_mm']
    # Additional explicit geometry assumptions, NOT Kongsberg dimensions:
    # main vertex -80 mm, phase-centre proxy native OEWG aperture z=20 mm.
    # A convex hyperbolic secondary redirects the forward feed toward the main dish.
    zv=-80.;feed_focus=20.;main_focus=zv+F;centre=(feed_focus+main_focus)/2
    c=(main_focus-feed_focus)/2;vertex=60.;a=vertex-centre;b2=c*c-a*a;assert 0<a<c
    faces=surface('MAIN',D/2,8,lambda r:zv+r*r/(4*F))
    faces+=surface('SECONDARY',Ds/2,4,lambda r:centre+a*math.sqrt(1+r*r/b2))
    payload=dict(faces=faces,seed_sha256=sha(SEED),feed_sha256=sha(FEED),
        public_anchors=dict(diameter_mm=220,operating_band_ghz=[25.5,27],system_gain_dbi=31,polarization='RHCP_OR_LHCP_OR_DUAL',
         product_url='https://www.kongsberg.com/what-we-do/space/space-mechanisms/apm/karma-7-fg/',
         datasheet_url='https://www.kongsberg.com/globalassets/kongsberg/1.-what-we-do/3.-space/2.-space-mechanisms/apm/karma-7-fg-product-data-sheet.pdf',revision='2022/09; pp1-2'),
        assumptions=dict(Fe_mm=F,theta_f_deg=seed['theta_f_deg'],secondary_diameter_mm=Ds,main_vertex_z_mm=zv,
         feed_phase_centre_proxy_z_mm=feed_focus,secondary_vertex_z_mm=vertex,main_focus_z_mm=main_focus,
         hyperbola_centre_z_mm=centre,hyperbola_a_mm=a,hyperbola_b2_mm2=b2,material='PEC_ZERO_THICKNESS_SHEETS',
         tessellation='64 azimuth sectors; main 8 radial rings; secondary 4 radial rings',
         primary_rim_chord_sag_mm=D/2*(1-math.cos(math.pi/64))),
        provenance='OWNER_AUTHORIZED_ENGINEERING_SURROGATE; NOT_VENDOR_CAD; NOT_FULL_WAVE_VALIDATED',
        limitations=['Equivalent Fe is used as a physical paraboloid focal proxy, not an approved KARMA optical prescription.',
         'Secondary profile and axial placement are engineering assumptions; not recovered from photo.',
         'No struts/gimbal/radome/material loss invented; no tuning/optimization; no predicted 31 dBi guarantee.',
         'Native feed geometry/material/ports/local frame and 0/-90/-180/-270 phases unchanged.'])
    payload['surface_geometry_sha256']=hashlib.sha256(json.dumps(faces,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    return payload

def build():
    g=geometry();write_json(BASE.with_suffix('.geometry.json'),g)
    if BASE.exists():
        e=json.loads(BASE.with_suffix('.preflight.json').read_text());assert e['project_sha256']==sha(BASE) and e['surface_geometry_sha256']==g['surface_geometry_sha256'];return
    BASE.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(FEED,BASE);app=connect_cst(False)
    p=method(app,'OpenFile',str(BASE));p=p or get_active_project(app);initial=solids(p)
    blocks=[]
    for face in g['faces']:
        curve='sur_'+face['name'];code=f'Curve.NewCurve "{curve}"\nWith Polygon3D\n .Reset\n .Name "outline"\n .Curve "{curve}"\n'
        for v in face['vertices_mm']+[face['vertices_mm'][0]]:code+=' .Point '+', '.join(f'"{x:.12g}"' for x in v)+'\n'
        code+=f' .Create\nEnd With\nWith CoverCurve\n .Reset\n .Name "{face["name"]}"\n .Component "KARMA7_SURROGATE"\n .Material "PEC"\n .Curve "{curve}:outline"\n .Create\nEnd With\n'
        blocks.append(code)
    for i in range(0,len(blocks),64):add_to_history(p,f'Owner engineering surrogate faces {i}-{min(i+64,len(blocks))-1}','\n'.join(blocks[i:i+64]))
    final=solids(p)
    for name,value in initial.items():assert final[name]==value
    assert len(final)==len(initial)+len(g['faces'])
    assert int(method(method(p,'Port'),'StartPortNumberIteration'))==4
    combine=method(p,'CombineResults');method(combine,'Reset');method(combine,'SetMonitorType','frequency');method(combine,'FarfieldsOnly',True)
    method(combine,'EnableAutomaticLabeling',False);method(combine,'SetLabel','CLOSED_NETWORK_FIXED_PHASES')
    for i,phase in enumerate([0,-90,-180,-270]):method(combine,'SetPortModeValues',i+1,1,1.,phase)
    save(p,BASE);method(p,'Quit');assert sha(FEED)==g['feed_sha256']
    write_json(BASE.with_suffix('.preflight.json'),dict(project_file=str(BASE.relative_to(ROOT)).replace('\\','/'),project_sha256=sha(BASE),feed_sha256=sha(FEED),
      surface_geometry_sha256=g['surface_geometry_sha256'],source_solids=initial,surrogate_surfaces=len(g['faces']),solver_started=False,
      status='COMMON_GEOMETRY_SOURCE_NOT_ANALYSIS_CASE',phases_deg=[0,-90,-180,-270],feed_geometry_unchanged=True))
    print('Saved common source',BASE.name,'surfaces',len(g['faces']),flush=True)
if __name__=='__main__':build()
