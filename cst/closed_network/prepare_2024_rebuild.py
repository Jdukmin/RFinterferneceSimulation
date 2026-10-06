"""Generate numeric classic History/VBA packages. No CST access and no solver."""
import csv, hashlib, json, math, re, sys
from pathlib import Path
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from cst_geometry import cylinder, segment, port, swept_wire
from generate_ka_feed import horn
from generate_isl import cup_patch
from fixed_body_geometry import ROOT, geometry, full_hull, sha, write_json
from prepare_attacker_installations import transform_code, rotation_angles

CN=ROOT/'cst/projects/closed_network'
OUT=ROOT/'cst/projects/closed_network_2024_build'
BASE={'KAA':'KA_FEED_C_OEWG','SBA':'SBAND_MATCHING_WIRE15','GPS':'LBAND_GNSS_FINAL_COMPROMISE','ISL':'ISL_C4_CUP_R14P7'}

def digest(value):
    return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()

class Recorder:
    def __init__(self): self.blocks=[]
    def _FlagAsMethod(self,name): pass
    def AddToHistory(self,name,code):
        self.blocks.append(dict(name=name,code=code)); return True

def values(antenna):
    if antenna in ['KAA','ISL']:
        return json.loads((ROOT/f'cst/tools/commands/{BASE[antenna]}/candidate.json').read_text())['inputs']
    return json.loads((ROOT/f'cst/projects/{BASE[antenna]}.geometry.json').read_text())['parameters']

def native(antenna,v):
    p=Recorder()
    if antenna=='KAA': horn(p,v)
    elif antenna=='ISL': cup_patch(p,v)
    elif antenna=='SBA':
        r=v['helix_diameter']/2;h=v['helix_height'];n=v['turns'];gap=v['feed_gap'];w=v['wire_radius'];g=v['groove_depth']
        cylinder(p,'base_floor',32.5,-v['base_depth'],-g)
        for name,ri,ro in [('base_center',0,12),('groove_wall_1',20,22),('outer_wall',30,32.5)]: cylinder(p,name,ro,-g,0,ri)
        count=round(n*v['segments_per_turn']);top=gap+4*w+h
        for arm in range(4):
            phase=math.pi*arm/2;x,y=r*math.cos(phase),r*math.sin(phase);name=f'arm{arm+1}'
            pts=[(x,y,gap),(x,y,gap+2*w)]
            for index in range(count+1):
                t=index/count;angle=phase+2*math.pi*n*t;rr=r+v['perturbation_amplitude']*math.sin(4*math.pi*t)**2
                pts.append((rr*math.cos(angle),rr*math.sin(angle),gap+4*w+h*t))
            swept_wire(p,name,pts,w)
            end=phase+2*math.pi*n
            segment(p,name+'_termination',(r*math.cos(end),r*math.sin(end),top),(0,0,top),w)
            port(p,arm+1,(x,y,0),(x,y,gap))
    elif antenna=='GPS':
        radius=v['cup_inner_diameter']/2;rim=v['cup_depth'];bottom=rim-v['choke_depth'];outer=v['outer_diameter']/2
        cylinder(p,'cup_floor',radius,-3,0)
        cylinder(p,'cup_wall',radius+v['cup_wall_thickness'],bottom,rim,radius)
        cylinder(p,'choke_floor',outer,bottom-3,bottom,radius+v['cup_wall_thickness'])
        cylinder(p,'choke_separator',v['choke2_inner_radius'],bottom,rim,v['choke1_outer_radius'])
        cylinder(p,'outer_wall',outer,bottom,rim,v['choke2_outer_radius'])
        h=v['patch_to_ground_height'];th=v['patch_thickness'];upper=h+th+v['patch_spacing']
        cylinder(p,'lower_patch',v['lower_patch_diameter']/2,h,h+th)
        cylinder(p,'upper_patch',v['upper_patch_diameter']/2,upper,upper+th)
        for i in range(4):
            a=i*math.pi/2;x=v['feed_radius']*math.cos(a);y=v['feed_radius']*math.sin(a)
            cylinder(p,f'probe{i+1}',v['feed_probe_radius'],2,h+th,x=x,y=y)
            port(p,i+1,(x,y,0),(x,y,2))
    return p.blocks

def port_records(blocks):
    rows=[]
    for b in blocks:
        if 'With DiscretePort' not in b['code']:continue
        code=b['code'];points=[]
        for k in [1,2]: points.append([float(x) for x in re.search(r'\.Point'+str(k)+r' ([^\n]+)',code).group(1).replace('"','').split(',')])
        rows.append(dict(number=int(re.search(r'\.PortNumber "(\d+)"',code).group(1)),point1_mm=points[0],point2_mm=points[1],impedance_ohm=50))
    return rows

def shape_names(blocks):
    return ['RECONSTRUCTION:'+re.search(r'With (?:Cylinder|SweepCurve)\s+\.Reset\s+\.Name "([^"]+)"',b['code']).group(1) for b in blocks if ('With Cylinder' in b['code'] or 'With SweepCurve' in b['code'])]

def reflector_blocks(ref):
    rec=Recorder()
    for face in ref['faces']:
        name=face['name'];curve='sur_'+name
        code=f'Curve.NewCurve "{curve}"\nWith Polygon3D\n .Reset\n .Name "outline"\n .Curve "{curve}"\n'
        for point in face['vertices_mm']+[face['vertices_mm'][0]]:code+=' .Point '+', '.join(f'"{x:.12g}"' for x in point)+'\n'
        code+=f' .Create\nEnd With\nWith CoverCurve\n .Reset\n .Name "{name}"\n .Component "KARMA7_SURROGATE"\n .Material "PEC"\n .Curve "{curve}:outline"\n .Create\nEnd With'
        rec.AddToHistory('Reflector '+name,code)
    return [dict(name=f'Reflector faces {i}-{min(i+8,len(rec.blocks))-1}',code='\n'.join(b['code'] for b in rec.blocks[i:i+8])) for i in range(0,len(rec.blocks),8)]

def build_geometry(row):
    antenna=row['antenna'];v=values(antenna);raw=native(antenna,v);ports=port_records(raw);shapes=shape_names(raw)
    blocks=[b for b in raw if 'With DiscretePort' not in b['code']];native_hash=digest(blocks);g=geometry();insts=[];allports=ports
    if row['installation_identity']:
        insts=[next(i for i in g['installations'] if i['installation_id']==identity) for identity in row['installation_identity'].split(';')]
        rec=Recorder()
        if len(insts)==2:
            i=insts[1];angles=rotation_angles(i['installation_id'],np.array(i['nominal_R_BL']))
            rec.AddToHistory('Duplicate accepted antenna for second installation',''.join(transform_code(n,angle=angles[0],duplicate=True) for n in shapes))
            for n in shapes:
                for a in angles[1:]:rec.AddToHistory('Second installation rotation',transform_code(n+'_1',angle=a))
                rec.AddToHistory('Second installation position',transform_code(n+'_1',vector=i['position_body_mm']))
        i=insts[0]
        for n in shapes:
            for a in rotation_angles(i['installation_id'],np.array(i['nominal_R_BL'])):rec.AddToHistory('First installation rotation',transform_code(n,angle=a))
            rec.AddToHistory('First installation position',transform_code(n,vector=i['position_body_mm']))
        blocks+=rec.blocks;allports=[]
        for k,i in enumerate(insts):
            R=np.array(i['nominal_R_BL']);origin=np.array(i['position_body_mm'])
            for p in ports:allports.append(dict(number=k*4+p['number'],point1_mm=(R@p['point1_mm']+origin).tolist(),point2_mm=(R@p['point2_mm']+origin).tolist(),impedance_ohm=50))
        rec=Recorder();full_hull(rec,g,insts[0]['installation_id']);blocks+=rec.blocks
    ref=None
    if row['configuration']=='FEED_WITH_REFLECTOR':
        ref=json.loads((CN/'kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.geometry.json').read_text())
        ref['provenance']='ENGINEERING_SURROGATE_FROM_EXISTING_VALIDATED_EQUIVALENT_MODEL; NOT_VENDOR_CAD; NOT_FULL_WAVE_VALIDATED'
        blocks+=reflector_blocks(ref)
    rec=Recorder()
    for p in allports:port(rec,p['number'],p['point1_mm'],p['point2_mm'],p['impedance_ohm'])
    blocks+=rec.blocks
    return dict(units='mm',base_antenna=BASE[antenna],parameters=v,native_antenna_geometry_hash=native_hash,
        primitive_definitions=raw,geometry_history=blocks,ports=allports,installation_frames=insts,
        antenna_to_body_transform='p_B=R_BL*p_L+position_body_mm' if insts else 'IDENTITY_NATIVE_PLUS_Z',
        spacecraft_panels=g['full_outer_panels'] if insts else [],spacecraft_panel_count=8 if insts else 0,cropped=False,
        spacecraft_geometry='FULL_SSOT_BUS_HULL_8_PANELS' if insts else 'NONE',reflector=ref,material_list=['PEC'],
        boolean_operations='No additional Boolean union/subtraction; exact accepted separate solid topology and native rigid duplication preserved.',
        coordinate_system='SPACECRAFT_BODY_FIXED' if insts else 'NATIVE_ANTENNA_LOCAL_PLUS_Z',
        precision='History literals rounded to 12 significant figures, as in accepted generators; these exact commands are the numeric construction SSOT.')

def settings(row,geom):
    rec=Recorder();low=float(row['f_low_ghz']);high=float(row['f_high_ghz'])
    rec.AddToHistory('Units and global coordinates','WCS.ActivateWCS "global"\nWith Units\n .Geometry "mm"\n .Frequency "GHz"\n .Time "ns"\nEnd With')
    for key,value in geom['parameters'].items():rec.AddToHistory('Accepted parameter '+key,f'StoreParameterWithDescription "{key}", "{value:.12g}", "Accepted numeric geometry; documentation parameter"')
    for key,value in [('cn_f_low',low),('cn_f_center',float(row['f_center_ghz'])),('cn_f_high',high)]:rec.AddToHistory(key,f'StoreParameter "{key}", "{value:.12g}"')
    rec.AddToHistory('Case identity',f'StoreParameterWithDescription "cn_rebuild_version", "2024", "{Path(row["project_file"]).stem}_CST2024; native save after checks"')
    # PEC is CST's intrinsic perfect-conductor material, not a user dielectric.
    rec.AddToHistory('Vacuum and open boundaries','With Background\n .Type "Normal"\n .Epsilon "1"\n .Mu "1"\n .XminSpace "0"\n .XmaxSpace "0"\n .YminSpace "0"\n .YmaxSpace "0"\n .ZminSpace "0"\n .ZmaxSpace "0"\nEnd With\nWith Boundary\n .Xmin "expanded open"\n .Xmax "expanded open"\n .Ymin "expanded open"\n .Ymax "expanded open"\n .Zmin "expanded open"\n .Zmax "expanded open"\n .Xsymmetry "none"\n .Ysymmetry "none"\n .Zsymmetry "none"\nEnd With\nBoundary.MinimumDistanceReferenceFrequencyType "CenterNMonitors"')
    rec.AddToHistory('Initial solver configuration; manual resource review required',f'ChangeSolverType "HF Time Domain"\nWith Solver\n .FrequencyRange "{low:.12g}", "{high:.12g}"\n .CalculationType "TD-S"\n .StimulationPort "All"\n .StimulationMode "All"\n .SteadyStateLimit "-40"\nEnd With')
    initial=rec.blocks;rec=Recorder()
    for f in [low,float(row['f_center_ghz']),high]:rec.AddToHistory('Farfield '+str(f),f'With Monitor\n .Reset\n .Name "farfield (f={f:g})"\n .Domain "Frequency"\n .FieldType "Farfield"\n .Frequency "{f:.12g}"\n .Create\nEnd With')
    rec.AddToHistory('Initial mesh; resource baseline, not convergence','With Mesh\n .MergeThinPECLayerFixpoints "True"\n .RatioLimit "5"\nEnd With\nWith MeshSettings\n .SetMeshType "Hex"\n .Set "StepsPerWaveNear", "8"\n .Set "StepsPerWaveFar", "8"\n .Set "StepsPerBoxNear", "8"\n .Set "StepsPerBoxFar", "8"\nEnd With')
    phases=[0,90,180,270] if row['antenna']=='SBA' else [0,-90,-180,-270]
    code='With CombineResults\n .Reset\n .SetMonitorType "frequency"\n .FarfieldsOnly "True"\n .EnableAutomaticLabeling "False"\n .SetLabel "CN_DEFAULT_GROUP"\n'
    for p in geom['ports']:code+=f' .SetPortModeValues "{p["number"]}", "1", "{1 if p["number"]<=4 else 0}", "{phases[(p["number"]-1)%4]}"\n'
    rec.AddToHistory('CP field-combination definition; no result calculation',code+'End With')
    rec.AddToHistory('Structure view','ResetViewToStructure\nPlot.ZoomToStructure')
    return initial,rec.blocks,phases

def vba_text(case,blocks):
    # One helper per block avoids VBA's per-procedure bytecode and continuation limits.
    lines=["' Numeric reconstruction for CST Studio Suite 2024. No Python/runtime or binary import.","' Built-in PEC is used. Validate on CST 2024 before native Save As.",'Option Explicit','Sub Main ()',
        '    If Solid.GetNumberOfShapes > 0 Then','        MsgBox "Use a NEW empty Microwave Studio project."','        Exit Sub','    End If']
    lines += [f'    BuildBlock{i:04d}' for i in range(len(blocks))]
    lines += [f'    MsgBox "{case}: reconstruction finished. Check geometry, ports, monitors and mesh; save {case}_CST2024.cst. Solver not started."','End Sub','']
    for i,b in enumerate(blocks):
        lines += [f'Private Sub BuildBlock{i:04d} ()','    Dim h As String','    h = ""']
        lines += ['    h = h & "'+line.replace('"','""')+'" & vbCrLf' for line in b['code'].splitlines()]
        lines += ['    AddToHistory "'+b['name'].replace('"','""')+'", h','End Sub','']
    return '\n'.join(lines)+'\n'

def generate():
    rows=list(csv.DictReader((CN/'project_inventory.csv').open(encoding='utf-8')))
    order={k:i for i,k in enumerate(['KAA','SBA','GPS','ISL'])};rows.sort(key=lambda r:order[r['antenna']])
    inventory=[]
    for idx,row in enumerate(rows,1):
        case=Path(row['project_file']).stem;folder=OUT/row['antenna'].lower()/case;folder.mkdir(parents=True,exist_ok=True)
        geom=build_geometry(row);geom['source_geometry_hash']=digest(geom['geometry_history']);before,after,phases=settings(row,geom)
        blocks=before+geom['geometry_history']+after
        geom['project_history']=blocks
        write_json(folder/'source_geometry.json',geom)
        (folder/'build_2024.vba').write_text(vba_text(case,blocks),encoding='ascii')
        e=json.loads((ROOT/row['project_file']).with_suffix('.preflight.json').read_text())
        count=len(shape_names(geom['primitive_definitions']))*max(1,len(geom['installation_frames']))+geom['spacecraft_panel_count']+(len(geom['reflector']['faces']) if geom['reflector'] else 0)
        reference=dict(geometry_object_count=count,component_count=1+bool(geom['installation_frames'])+bool(geom['reflector']),material_count=1,material_count_definition='Distinct materials assigned to solids (intrinsic PEC); vacuum background separately defined.',port_count=len(geom['ports']),monitor_count=3,
            bounding_box_mm=None,bounding_box_status='AWAITING_CST2026_REFERENCE_EXTRACTION',key_dimensions_mm=geom['parameters'],antenna_reference_point=[i['position_body_mm'] for i in geom['installation_frames']] or [[0,0,0]],
            boresight=[np.array(i['nominal_R_BL'])[:,2].tolist() for i in geom['installation_frames']] or [[0,0,1]],orientation_matrix=[i['nominal_R_BL'] for i in geom['installation_frames']] or [np.eye(3).tolist()],spacecraft_panel_count=geom['spacecraft_panel_count'],spacecraft_geometry=geom['spacecraft_geometry'],cropped=False,
            project_frequency_range_ghz=[float(row['f_low_ghz']),float(row['f_high_ghz'])],monitor_frequencies_ghz=e['monitor_frequencies_ghz'],source_project=row['project_file'],source_project_sha256=sha(ROOT/row['project_file']),source_preflight_sha256=sha((ROOT/row['project_file']).with_suffix('.preflight.json')),source_geometry_hash=geom['source_geometry_hash'],
            source_base_solid_volumes=e['source_solids'],source_mesh_cells=e['mesh_cells'],actual_cst2024_execution=False,solver_started=False)
        write_json(folder/'validation_reference.json',reference)
        manifest=dict(case_id=case,antenna=row['antenna'],configuration=row['configuration'],source_project=row['project_file'],accepted_base_project=f'cst/projects/{BASE[row["antenna"]]}.cst',accepted_base_sha256=sha(ROOT/f'cst/projects/{BASE[row["antenna"]]}.cst'),target_cst_version=2024,
            frequency_low_ghz=float(row['f_low_ghz']),frequency_center_ghz=float(row['f_center_ghz']),frequency_high_ghz=float(row['f_high_ghz']),monitor_frequencies_ghz=e['monitor_frequencies_ghz'],port_count=len(geom['ports']),port_type='DiscretePort SParameter; 50 ohm',
            excitation_amplitudes=[1 if i<4 else 0 for i in range(len(geom['ports']))],excitation_phases_deg=[phases[i%4] for i in range(len(geom['ports']))],material_list=['PEC'],material_definition='Intrinsic CST PEC; vacuum epsilon_r=mu_r=1.',boundary_type='expanded open, all six faces; no symmetry; CenterNMonitors reference',
            solver_recommendation=row['solver_selection_policy'],initial_solver='HF Time Domain; configuration only, never automatically run',installed_identity=row['installation_identity'],spacecraft_geometry=geom['spacecraft_geometry'],spacecraft_panel_count=geom['spacecraft_panel_count'],cropped=False,
            expected_object_count=count,expected_bbox_mm=None,source_geometry_hash=geom['source_geometry_hash'],native_antenna_geometry_hash=geom['native_antenna_geometry_hash'],build_vba_sha256=sha(folder/'build_2024.vba'),source_geometry_file_sha256=sha(folder/'source_geometry.json'),
            expected_native_filename=case+'_CST2024.cst',expected_native_directory='cst/projects/closed_network_2024_native/'+row['antenna'].lower(),dataset_ids=row['dataset_ids'].split(';'),expected_output_directories=row['expected_output_directory'].split(';'),
            status='READY_FOR_CST2024_REBUILD',actual_cst2024_execution=False,solver_started=False,
            notes=['Classic AddToHistory VBA only; no CST2026 binary or CST Python API dependency.','Geometry reconstruction uses exact accepted numeric recipes; no tuning.','Initial TD/hex setup is a editable baseline, not a mandate to solve installed cases with TD.','Select license-compatible solver and verify discrete ports before solve.','SBA attacker filenames retain ORIGINAL legacy name but contain installed NADIR/ZENITH groups.','No new reflector support geometry: no approved support dimensions exist in source; existing surrogate sheets are preserved.'] )
        write_json(folder/'build_manifest.json',manifest)
        rel=folder.relative_to(ROOT).as_posix()
        inventory.append(dict(index=idx,case_id=case,antenna=row['antenna'],configuration=row['configuration'],victim_band=row['victim_band'],source_project=row['project_file'],build_vba=rel+'/build_2024.vba',manifest=rel+'/build_manifest.json',geometry_json=rel+'/source_geometry.json',validation_json=rel+'/validation_reference.json',installed_identity=row['installation_identity'],spacecraft_geometry=geom['spacecraft_geometry'],target_version=2024,status='READY_FOR_CST2024_REBUILD',expected_native_filename=manifest['expected_native_filename']))
        text=f'''# {case} — CST 2024 재구축

이 macro는 기존 numeric geometry를 새 프로젝트에 생성합니다. CST 2024에서 아직 실행하지 않았으며 solver를 자동 실행하지 않습니다. 설치 identity: {row['installation_identity'] or '없음; native +Z'}. 위성체: {geom['spacecraft_geometry']}.

1. CST Studio Suite **2024**를 실행하고 Help → About에서 버전을 확인합니다.
2. 새 빈 Microwave Studio 3D project를 만듭니다. 기존 `.cst`를 열지 않습니다.
3. Macro → New Macro의 editor에 `build_2024.vba` 전체를 붙여 넣고 실행합니다. 필요하면 파일을 로컬 `.mcr`로 복사해 editor로 엽니다. History item에 `Sub Main` 전체를 직접 넣지 않습니다.
4. Message window와 History list 오류를 확인합니다. 오류가 있으면 중단하고 command/line/error를 기록합니다.
5. `validation_reference.json`과 object/component count, bounding box, 주요 치수와 설치 방향을 비교합니다. 설치형은 PANEL_1~PANEL_8 전부를 확인합니다.
6. Port {len(geom['ports'])}개, endpoint/reference plane, 50 Ω와 CP phase를 확인합니다. SBA 두 설치형은 1–4 NADIR / 5–8 ZENITH를 각각 활성화하며 나머지는 amplitude 0입니다.
7. Farfield monitor 3개({', '.join(str(f) for f in e['monitor_frequencies_ghz'])} GHz), frequency range, open boundary를 확인합니다.
8. Mesh와 자원을 점검합니다. 권장 검토: `{row['solver_selection_policy']}`. 초기 TD 설정은 실행 권고가 아닙니다. Installed ISL은 약 2.269e9-cell TD 계획 때문에 IE/MLFMM 또는 Hybrid를 먼저 검토합니다. hull을 자르지 않습니다.
9. CST 2024에서 native **`{case}_CST2024.cst`**로 Save As합니다. 저장 위치는 repository의 `{manifest['expected_native_directory']}`입니다. master manual의 native validation 기록을 남깁니다.
10. 폐쇄망 사용자가 solver/port/mesh/resource를 승인한 뒤 직접 solver를 실행합니다. 수렴 및 normalization을 검증하고 RAW farfield를 export합니다.

재구축 세부 절차와 RAW→MATLAB 연결: [master manual](../../../../../docs/CST2024_CLOSED_NETWORK_REBUILD_MANUAL.md). intrinsic PEC를 사용하며 새 dielectric이나 제조사 CAD를 만들지 않습니다. Reflector의 F/illumination/secondary 값은 기존 engineering surrogate의 가정입니다.
'''
        (folder/'README.md').write_text(text,encoding='utf-8')
    with (ROOT/'docs/CST2024_REBUILD_22_PROJECTS.csv').open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(inventory[0]));w.writeheader();w.writerows(inventory)
    return inventory

if __name__=='__main__':
    print('Generated',len(generate()),'packages; no CST or solver started.')
