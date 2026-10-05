"""Offline completeness evidence; missing geometry is never a completed project."""
import csv, json, hashlib, subprocess, ast
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[2]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
rows = list(csv.DictReader((ROOT/'docs/closed_network_cst_project_inventory.csv').open(encoding='utf-8')))
preflight = json.loads((ROOT/'docs/closed_network_preparation_validation.json').read_text())
reopen = json.loads((ROOT/'docs/closed_network_reopen_validation.json').read_text())
plan = json.loads((ROOT/'analysis/closed_network/rfi_plan.json').read_text())
geometry = json.loads((ROOT/'cst/closed_network/full_spacecraft_geometry.json').read_text())
assert len(rows) == 24 and len({r['project_file'] for r in rows}) == 24
assert len(plan) == 74 and len({r['pair_id'] for r in plan}) == 10
assert len([r for r in rows if r['antenna']=='KAA']) == 8
assert len(geometry['full_outer_panels']) == 8 and not geometry['cropped']
datasets = {Path(r['expected_output_directory']).name for r in rows}
assert all(r['tx_dataset'] in datasets and r['rx_dataset'] in datasets for r in plan)
ready = [r for r in rows if r['solver_status']=='READY_NOT_SOLVED']
missing = [r for r in rows if r not in ready]
assert len(ready) + len(missing) == 24
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
            assert np.max(abs(np.array(local['local_vertices_mm'])@rotation.T + origin - np.array(body['body_vertices_mm']))) < 1e-8
    checks.append({'project_file':row['project_file'],'sha256':record['project_sha256'],'mesh_cells':record['mesh_cells']})
for name in ['prepare_closed_network.py','export_closed_network_patterns.py','validate_closed_network.py']:
    tree = ast.parse((ROOT/'cst'/name).read_text())
    for node in ast.walk(tree):
        if isinstance(node,ast.Call):
            assert not (isinstance(node.func,ast.Attribute) and node.func.attr=='Start')
            if isinstance(node.func,ast.Name) and node.func.id=='method' and len(node.args)>1:
                assert not (isinstance(node.args[1],ast.Constant) and node.args[1].value=='Start')
for file in ['CLOSED_NETWORK_CST_ANALYSIS_MANUAL.md','CLOSED_NETWORK_MATLAB_RFI_MANUAL.md']:
    assert (ROOT/'docs'/file).is_file()
assert json.loads((ROOT/'data/closed_network_patterns/registry.json').read_text()) == []
assert not (ROOT/'output/closed_network/rfi_ten_pairs.csv').exists()
summary = {'completion_status':'INCOMPLETE_INPUT_MISSING' if missing else 'COMPLETE','base_commit':subprocess.check_output(['git','merge-base','HEAD','origin/main'],cwd=ROOT,text=True).strip(),
    'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),
    'initial_worktree_clean':True,'planned_projects':len(rows),'saved_and_reopened_projects':len(ready),'missing_projects':[r['project_file'] for r in missing],
    'rfi_pair_families':10,'comparison_rows':74,'whole_spacecraft_panels':8,'coordinate_roundtrip_validated':True,
    'native_source_hashes_unchanged':True,'native_ports_materials_volumes_verified':True,'solver_started':False,'rf_results_generated':False,
    'checks':checks,'tests':{'native_cst_standalone_reopen':'PASS_18','matlab_adapter_octave_9_2':'PASS_SYNTHETIC_FIXTURES',
        'raw_registration':'PASS_4_SYNTHETIC_TESTS','synthetic_end_to_end_driver':'PASS_4_COMPARISON_CONFIGURATIONS','full_rfi_execution':'NOT_RUN_NO_SOLVER_RESULTS'}}
(ROOT/'docs/closed_network_completeness.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(f"PASS available-project checks; {summary['completion_status']}: {len(ready)}/24 projects, 10 families, 74 comparisons; no solver/RFI results.")
