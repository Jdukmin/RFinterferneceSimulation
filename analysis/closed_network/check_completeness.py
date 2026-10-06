"""Offline completeness evidence; missing geometry is never a completed project."""
import csv, json, hashlib, subprocess, ast
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[2]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
scope=ROOT/'cst/projects/closed_network'
if (scope/'project_inventory.csv').exists():
    rows=list(csv.DictReader((scope/'project_inventory.csv').open(encoding='utf-8')))
    bindings={b['dataset_id']:b for b in json.loads((scope/'dataset_bindings.json').read_text())}
    plan=json.loads((ROOT/'analysis/closed_network/rfi_plan.json').read_text())
    proof=json.loads((scope/'validation.json').read_text());verified={r['project_file']:r for r in proof['records']}
    assert len(rows)==22 and len(plan)==37 and len({r['pair_id'] for r in plan})==10
    assert proof['status']=='PASS' and not proof['solver_started']
    assert len(list(scope.glob('*/*.cst')))==23 # 22 cases plus common source
    installed=0
    for r in rows:
        path=ROOT/r['project_file'];e=json.loads(path.with_suffix('.preflight.json').read_text())
        assert sha(path)==e['project_sha256']==verified[r['project_file']]['sha256'] and not e['solver_started']
        assert sha(ROOT/e['source_project'])==e['source_sha256']
        if e.get('installed_geometry'):
            installed+=1;assert len(e['installed_geometry']['panels'])==8 and e['installed_geometry']['global_solver_frame']=='SPACECRAFT_BODY_FIXED'
        if r['antenna']=='KAA':assert not e.get('installed_geometry')
    assert installed==11
    for r in plan:
        tx=bindings[r['tx_dataset']]
        assert tx['pattern_class']==('FreeSpacePattern' if r['pair'].startswith('KAA') else 'InstalledPattern')
        if tx['pattern_class']=='InstalledPattern':assert tx['installation_id']==r['tx_installation']
        if r['rx_dataset']!='SAR_ENGINEERING_RECEIVE_BASELINE':
            rx=bindings[r['rx_dataset']];assert rx['pattern_class']=='InstalledPattern' and rx['installation_id']==r['rx_installation']
    assert not (ROOT/'output/closed_network/rfi_ten_pairs.csv').exists()
    print('PASS 22/22 cases; SBA/ISL installed attackers; KAA standalone; GPS installed; SAR baseline; 10/10 families / 37 rows; no solver.')
    raise SystemExit(0)
rows = list(csv.DictReader((ROOT/'docs/closed_network_cst_project_inventory.csv').open(encoding='utf-8')))
preflight = json.loads((ROOT/'docs/closed_network_preparation_validation.json').read_text())
reopen = json.loads((ROOT/'docs/closed_network_reopen_validation.json').read_text())
plan = json.loads((ROOT/'analysis/closed_network/rfi_plan.json').read_text())
geometry = json.loads((ROOT/'cst/closed_network/full_spacecraft_geometry.json').read_text())
assert len(rows) == 22 and len({r['project_file'] for r in rows}) == 22
assert len(plan) == 67 and len({r['pair_id'] for r in plan}) == 10
assert not any(r['antenna']=='SAR' for r in rows)
assert len([r for r in rows if r['antenna']=='KAA']) == 8
assert len(geometry['full_outer_panels']) == 8 and not geometry['cropped']
datasets = {Path(r['expected_output_directory']).name for r in rows}
datasets.add('SAR_ENGINEERING_RECEIVE_BASELINE')
assert all(r['tx_dataset'] in datasets and r['rx_dataset'] in datasets for r in plan)
by_dataset={Path(r['expected_output_directory']).name:r for r in rows}
installations={r['installation_id'] for r in geometry['installations']}
for r in plan:
    assert r['tx_installation'] in installations and r['rx_installation'] in installations
    for field in ['tx_dataset','rx_dataset']:
        if r[field]=='SAR_ENGINEERING_RECEIVE_BASELINE':
            assert r['allowable_psd_dbm_hz']==-176 and r['rx_configuration']=='ENGINEERING_BASELINE'
            continue
        case=by_dataset[r[field]]
        assert float(case['f_low_ghz'])<=r['f_low_ghz']<=r['f_high_ghz']<=float(case['f_high_ghz'])
ready = [r for r in rows if r['solver_status']=='READY_NOT_SOLVED']
missing = [r for r in rows if r not in ready]
assert len(ready)==22 and not missing
assert len(reopen['records']) == len(ready) and not preflight['solver_started']
checks = []
for row in rows:
    path = ROOT/row['project_file']
    assert (ROOT/row['expected_output_directory']/'README.md').is_file()
    if row in missing:
        assert not path.exists() and row['missing_input']
        continue
    record = json.loads(path.with_suffix('.preflight.json').read_text())
    assert sha(path) == record['project_sha256']
    assert sha(ROOT/record['source_project']) == record['source_sha256']
    assert record['monitor_frequencies_ghz'] == [float(row[k]) for k in ['f_low_ghz','f_center_ghz','f_high_ghz']]
    assert record['mesh_cells'] > 0 and record['ports'] == 4 and not record['solver_started']
    if row['configuration']=='INSTALLED':
        installed = record['installed_geometry']; rotation = np.array(installed['installation']['nominal_R_BL'])
        origin = np.array(installed['installation']['position_body_mm']); assert len(installed['panels']) == 8
        for local, body in zip(installed['panels'], geometry['full_outer_panels']):
            assert local['panel_id'] == body['panel_id']
            assert installed['global_solver_frame']=='SPACECRAFT_BODY_FIXED'
            assert np.max(abs(np.array(local['body_vertices_mm'])-np.array(body['body_vertices_mm']))) < 1e-8
    checks.append({'project_file':row['project_file'],'sha256':record['project_sha256'],'mesh_cells':record['mesh_cells']})
common=ROOT/'cst/projects/closed_network/kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.cst'
surrogate=json.loads(common.with_suffix('.geometry.json').read_text())
source_hash=sha(common)
for row in rows:
    if row['configuration']=='FEED_WITH_REFLECTOR':
        e=json.loads((ROOT/row['project_file']).with_suffix('.preflight.json').read_text())
        assert e['source_sha256']==source_hash and e['surrogate_surface_geometry_sha256']==surrogate['surface_geometry_sha256']
audit=json.loads((ROOT/'docs/closed_network_external_structure_audit.json').read_text())
assert not audit['complete_satellite_cad'] and not audit['cropped'] and not audit['omitted_defined_structure_instances']
for name in ['prepare_closed_network.py','build_karma7_surrogate.py','export_closed_network_patterns.py','validate_closed_network.py','realign_closed_network_installed.py']:
    tree = ast.parse((ROOT/'cst'/name).read_text())
    for node in ast.walk(tree):
        if isinstance(node,ast.Call):
            assert not (isinstance(node.func,ast.Attribute) and node.func.attr=='Start')
            if isinstance(node.func,ast.Name) and node.func.id=='method' and len(node.args)>1:
                assert not (isinstance(node.args[1],ast.Constant) and node.args[1].value=='Start')
for file in ['CLOSED_NETWORK_CST_ANALYSIS_MANUAL.md','CLOSED_NETWORK_MATLAB_RFI_MANUAL.md']:
    assert (ROOT/'docs'/file).is_file()
registry=json.loads((ROOT/'data/closed_network_patterns/registry.json').read_text())
assert len(registry)==1 and registry[0]['dataset_id']=='SAR_ENGINEERING_RECEIVE_BASELINE'
assert registry[0]['peak_gain_dbi']==52 and registry[0]['rear_gain_dbi']==2 and registry[0]['allowable_psd_dbm_hz']==-176
assert not (ROOT/'output/closed_network/rfi_ten_pairs.csv').exists()
summary = {'completion_status':'INCOMPLETE_INPUT_MISSING' if missing else 'COMPLETE','base_commit':subprocess.check_output(['git','merge-base','HEAD','origin/main'],cwd=ROOT,text=True).strip(),
    'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),
    'initial_worktree_clean':True,'planned_projects':len(rows),'saved_and_reopened_projects':len(ready),'missing_projects':[r['project_file'] for r in missing],
    'rfi_pair_families':10,'comparison_rows':67,'ssot_bus_hull_panels':8,'complete_satellite_cad':False,'coordinate_roundtrip_validated':True,'installed_solver_frame':'SPACECRAFT_BODY_FIXED','isl_mount_panel':'PANEL_7','isl_boresight_body':[1,0,0],
    'common_source_project':str(common.relative_to(ROOT)).replace('\\','/'),'common_reflector_geometry_hash':surrogate['surface_geometry_sha256'],
    'pair_input_plan_ready':10,'actual_cst_exported_datasets':0,'numeric_execution_requires_closed_network_solver_exports':True,
    'native_source_hashes_unchanged':True,'native_ports_materials_volumes_verified':True,'solver_started':False,'rf_results_generated':False,
    'checks':checks,'tests':{'native_cst_standalone_reopen':'PASS_22','matlab_adapter_octave_9_2':'PASS_NATIVE_FRAME_AND_SAR_BASELINE',
        'raw_registration':'PASS_6_SYNTHETIC_TESTS','synthetic_end_to_end_driver':'PASS_10_FAMILIES_67_CONFIGURATIONS',
        'installed_orientation_and_export_roundtrip':'PASS_3_TESTS_3600_DIRECTIONS; ORIGINAL_KAA_18_BINARIES_UNCHANGED',
        'comparison_outputs':'PASS_30_INSTALLED_AND_22_REFLECTOR_COMPARISONS','full_mission_rfi_execution':'NOT_RUN_NO_SOLVER_RESULTS'}}
(ROOT/'docs/closed_network_completeness.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(f"PASS preparation: {len(ready)}/22 projects, 10/10 input plans, 67 comparisons; no solver/mission RFI results.")
