"""Exact 22-case completeness, numeric macro identity and source protection checks."""
import collections,csv,json,re,sys
from pathlib import Path
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from prepare_2024_rebuild import ROOT,OUT,digest,vba_text
from fixed_body_geometry import sha,geometry,write_json

EXPECTED={
 'KAA':['RFC_KAA_'+config+'_'+band for band in ['STM','L1','SAR','ISL'] for config in ['FEED_ONLY','WITH_REFLECTOR']],
 'SBA':['RFC_SBA_TM_ORIGINAL','RFC_INSTALLED_SBA_TM_NADIR','RFC_INSTALLED_SBA_TM_ZENITH']+['RFC_SBA_TC_ORIGINAL_'+b for b in ['ISL','SAR','L1']],
 'GPS':['RFC_GPS_L1_ORIGINAL','RFC_INSTALLED_GPS_L1_GPSA1','RFC_INSTALLED_GPS_L1_GPSA2'],
 'ISL':['RFC_ISL_ORIGINAL','RFC_INSTALLED_ISL_RX']+['RFC_ISL_TX_ORIGINAL_'+b for b in ['SAR','STM','L1']]}

def main():
 rows=list(csv.DictReader((ROOT/'docs/CST2024_REBUILD_22_PROJECTS.csv').open(encoding='utf-8')))
 expected={c for group in EXPECTED.values() for c in group};assert len(rows)==22 and {r['case_id'] for r in rows}==expected
 assert collections.Counter(r['antenna'] for r in rows)=={'KAA':8,'SBA':6,'GPS':3,'ISL':5}
 files=['build_2024.vba','build_manifest.json','source_geometry.json','validation_reference.json','README.md'];counts={name:len(list(OUT.glob('*/*/'+name))) for name in files}
 assert all(n==22 for n in counts.values()),counts
 groups=collections.defaultdict(list);installed=0;body=geometry();records=[]
 for row in rows:
  folder=(ROOT/row['manifest']).parent;m=json.loads((folder/'build_manifest.json').read_text());g=json.loads((folder/'source_geometry.json').read_text());v=json.loads((folder/'validation_reference.json').read_text());macro=(folder/'build_2024.vba').read_text()
  assert macro==vba_text(row['case_id'],g['project_history']),'VBA/JSON numeric commands differ'
  executable='\n'.join(line for line in macro.splitlines() if not line.lstrip().startswith("'"))
  assert not re.search(r'\b(?:Solver\.Start|StartSolver|CombineResults\.Run|ImportCST|Python)\b',executable,re.I)
  assert '2026' not in macro and '{{' not in macro
  assert digest(g['geometry_history'])==g['source_geometry_hash']==m['source_geometry_hash']==v['source_geometry_hash']
  assert sha(folder/'build_2024.vba')==m['build_vba_sha256'] and sha(folder/'source_geometry.json')==m['source_geometry_file_sha256']
  assert sha(ROOT/m['source_project'])==v['source_project_sha256'] and sha(ROOT/m['accepted_base_project'])==m['accepted_base_sha256']
  assert m['target_cst_version']==2024 and not m['actual_cst2024_execution'] and not m['solver_started']
  assert m['status']==row['status']=='READY_FOR_CST2024_REBUILD'
  assert m['expected_native_filename']==row['expected_native_filename']==row['case_id']+'_CST2024.cst'
  assert len(m['monitor_frequencies_ghz'])==v['monitor_count']==3
  assert len(g['ports'])==m['port_count']==v['port_count'];assert v['geometry_object_count']==m['expected_object_count']
  assert v['classic_history_replay_cst2026']=='PASS' and m['classic_history_replay_cst2026']=='PASS'
  assert m['expected_bbox_mm']==v['bounding_box_mm'] and len(v['bounding_box_mm'])==6
  if g['installation_frames']:
   installed+=1;assert g['spacecraft_panel_count']==v['spacecraft_panel_count']==m['spacecraft_panel_count']==8
   assert g['spacecraft_geometry']==v['spacecraft_geometry']==m['spacecraft_geometry']=='FULL_SSOT_BUS_HULL_8_PANELS'
   assert g['spacecraft_panels']==body['full_outer_panels'] and not g['cropped'] and not m['cropped']
   for inst in g['installation_frames']:
    R=np.array(inst['nominal_R_BL']);panel=next(p for p in body['full_outer_panels'] if p['panel_id']==inst['panel_id'])
    np.testing.assert_allclose(R[:,2],panel['outward_normal_body'],atol=1e-9);np.testing.assert_allclose(R.T@R,np.eye(3),atol=1e-9);assert abs(np.linalg.det(R)-1)<1e-9
  else:assert g['spacecraft_panel_count']==0 and v['boresight']==[[0,0,1]]
  if row['antenna']=='KAA':key='KAA_'+row['configuration']
  elif row['configuration']=='ATTACKER_INSTALLED':key=row['antenna']+'_ATTACKER_INSTALLED'
  else:key=row['case_id']
  groups[key].append(g['source_geometry_hash'])
  records.append(dict(case_id=row['case_id'],objects=v['geometry_object_count'],ports=v['port_count'],monitors=3,panels=v['spacecraft_panel_count'],source_geometry_hash=g['source_geometry_hash']))
 assert len(groups['KAA_FEED_ONLY'])==len(groups['KAA_FEED_WITH_REFLECTOR'])==4
 assert len(groups['SBA_ATTACKER_INSTALLED'])==len(groups['ISL_ATTACKER_INSTALLED'])==3
 for key,hashes in groups.items():assert len(set(hashes))==1,(key,hashes)
 replay=json.loads((OUT/'cst2026_replay_validation.json').read_text());assert replay['projects']==22 and not replay['actual_cst2024_execution'] and not replay['solver_started']
 plan=json.loads((ROOT/'analysis/closed_network/rfi_plan.json').read_text());bindings=json.loads((ROOT/'cst/projects/closed_network/dataset_bindings.json').read_text());ids={b['dataset_id'] for b in bindings}
 assert len({p['pair_id'] for p in plan})==10
 for p in plan:assert p['tx_dataset'] in ids and (p['rx_dataset'] in ids or p['rx_dataset']=='SAR_ENGINEERING_RECEIVE_BASELINE')
 summary=dict(status='PASS',planned_projects=22,case_directories=22,file_counts=counts,family_counts={'KAA':8,'SBA':6,'GPS':3,'ISL':5},kaa_feed_only=4,kaa_with_reflector=4,installed_full_8_panel_cases=installed,geometry_hash_consistency='PASS',rfi_pairs=10,rfi_pattern_bindings=25,
  actual_cst2024_execution=False,classic_history_replay_actual_version=2026,solver_started=False,source_projects_unchanged=True,records=records)
 write_json(OUT/'completeness_validation.json',summary);print('PASS: 22/22 five-file packages, 22 inventory rows; hash consistency; 8-panel installed geometry; 10/10 RFI pairs. CST2024 not run; solver not run.')

if __name__=='__main__':main()
