"""True prism facets clipped near unchanged installation references; mm."""
import math
import numpy as np

VERTICES=np.array([[-783.188191,800],[-1084.414419,278.260870],
    [-301.226227,-1078.260870],[301.226227,-1078.260870],
    [1084.414419,278.260870],[783.188191,800]])
EDGES=[(5,0),(0,1),(1,2),(2,3),(3,4),(4,5)]
INSTALLATIONS={
 'SBA_NADIR':([255,870,1030],[0,math.sqrt(3)/2,.5],6,'S'),
 'SBA_ZENITH':([255,-530,-1240],[0,0,-1],4,'S'),
 'GPSA_1':([2045,-265,-1295],[0,-math.sqrt(3)/2,-.5],3,'L'),
 'GPSA_2':([3145,-265,-1295],[0,-math.sqrt(3)/2,-.5],3,'L')}

def segment_distance(q,a,b):
    t=np.clip(np.dot(q-a,b-a)/np.dot(b-a,b-a),0,1)
    return float(np.linalg.norm(q-(a+t*(b-a))))

def clip_polygon(poly,lo,hi):
    poly=[np.asarray(p,float) for p in poly]
    for axis in range(2):
        for bound,sign in [(lo[axis],1),(hi[axis],-1)]:
            if not poly:return []
            output=[]
            for a,b in zip(poly,poly[1:]+poly[:1]):
                ina=sign*(a[axis]-bound)>=-1e-9
                inb=sign*(b[axis]-bound)>=-1e-9
                if ina:output.append(a)
                if ina!=inb:output.append(a+(b-a)*(bound-a[axis])/(b[axis]-a[axis]))
            poly=output
    return poly

def clip_segment(a,b,lo,hi):
    d=b-a;t0=0.;t1=1.
    for i in range(2):
        if abs(d[i])<1e-12:
            if not lo[i]<=a[i]<=hi[i]:return None
        else:
            aa,bb=sorted([(lo[i]-a[i])/d[i],(hi[i]-a[i])/d[i]])
            t0=max(t0,aa);t1=min(t1,bb)
    if t1<=t0:return None
    return a+t0*d,a+t1*d

def local_facets(installation,frequency_ghz,radius_lambda,x_radius_lambda=None):
    position,z,mount,family=INSTALLATIONS[installation]
    pos=np.array(position,float);z=np.array(z);x=np.array([1.,0,0]);y=np.cross(z,x)
    frame=np.column_stack([x,y,z]);radius=299.792458/frequency_ghz*radius_lambda
    lo=pos[1:]-radius;hi=pos[1:]+radius
    xradius=radius if x_radius_lambda is None else 299.792458/frequency_ghz*x_radius_lambda
    xmin=max(0,pos[0]-xradius);xmax=min(6000,pos[0]+xradius)
    # For SBA the real rear boundary is mandatory even if outside R at high f.
    if family=='S':xmin=0.
    facets=[];distances=[]
    for number,(ia,ib) in enumerate(EDGES,1):
        a,b=VERTICES[ia],VERTICES[ib]
        dist=segment_distance(pos[1:],a,b)
        normal=np.array([-(b-a)[1],(b-a)[0]])
        normal/=np.linalg.norm(normal)
        distances.append({'panel':number,'plane_distance_mm':float(abs(np.dot(pos[1:]-a,normal))),
            'finite_facet_distance_mm':dist,
            'nearest_longitudinal_edge_distance_mm':float(min(np.linalg.norm(pos[1:]-a),np.linalg.norm(pos[1:]-b)))})
        if dist>radius and number!=mount:continue
        segment=clip_segment(a,b,lo,hi)
        if segment is None:continue
        aa,bb=segment
        points=np.array([[xmin,*aa],[xmax,*aa],[xmax,*bb],[xmin,*bb]])
        facets.append({'panel':number,'points_local_mm':((points-pos)@frame).tolist()})
    cap=clip_polygon(VERTICES,lo,hi)
    if cap and xmin==0:
        points=np.array([[0,*p] for p in cap])
        facets.append({'panel':8,'points_local_mm':((points-pos)@frame).tolist()})
    def cross2(a,b):return a[0]*b[1]-a[1]*b[0]
    inside=all(cross2(VERTICES[(i+1)%6]-VERTICES[i],pos[1:]-VERTICES[i])>=-1e-8 for i in range(6))
    lateral=0 if inside else min(segment_distance(pos[1:],VERTICES[a],VERTICES[b]) for a,b in EDGES)
    distances.append({'panel':8,'plane_distance_mm':float(pos[0]),
        'finite_facet_distance_mm':float(math.hypot(pos[0],lateral))})
    return {'installation':installation,'position_mm':position,'boresight':z.tolist(),
        'local_to_body_rotation':frame.tolist(),'frequency_ghz':frequency_ghz,
        'radius_lambda':radius_lambda,'radius_mm':radius,'x_radius_lambda':x_radius_lambda,
        'x_radius_mm':xradius,'x_extent_mm':[xmin,xmax],
        'facets':facets,'structure_distances':distances,'included_panels':[f['panel'] for f in facets],
        'excluded_structures':'front cap; facets outside crop; unknown brackets/cables/radomes',
        'crop_definition':'YZ square +/-R at reference; true side facets and rear cap only; artificial forward/YZ edges'}

def add_facets(p,geometry):
    from cst_com_common import add_to_history
    for facet in geometry['facets']:
        name=f"panel_{facet['panel']}";curve=f'local_{name}'
        code=f'Curve.NewCurve "{curve}"\nWith Polygon3D\n .Reset\n .Name "outline"\n .Curve "{curve}"\n'
        points=facet['points_local_mm']
        for point in points+[points[0]]:
            code+=' .Point '+', '.join(f'"{v:.12g}"' for v in point)+'\n'
        code+=' .Create\nEnd With\n'
        code+=f'With CoverCurve\n .Reset\n .Name "{name}"\n .Component "LOCAL_SPACECRAFT"\n .Material "PEC"\n .Curve "{curve}:outline"\n .Create\nEnd With'
        add_to_history(p,f'True PEC sheet {name}',code)
