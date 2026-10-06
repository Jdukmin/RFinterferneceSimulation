"""Validate RAW gain; create separate import views without changing originals."""
import csv,json,math,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
rows=list(csv.DictReader((ROOT/'docs/closed_network_cst_project_inventory.csv').open(encoding='utf-8')));registry=[]
for r in rows:
 dataset=Path(r['expected_output_directory']);folder=ROOT/dataset;provenance=folder/'provenance.json'
 if not provenance.is_file():continue
 meta=json.loads(provenance.read_text());assert meta['status']=='SOLVED_ACCEPTED' and meta['gain_quantity']=='RealizedGain' and meta['gain_unit']=='dBi' and meta['convergence_accepted']
 assert meta['project_file']==r['project_file'] and meta['frame']=='CST_LOCAL_PRESERVED'
 if r['configuration']=='INSTALLED':
  evidence=json.loads((ROOT/r['project_file']).with_suffix('.preflight.json').read_text())
  assert meta['solver_frame']=='SPACECRAFT_BODY_FIXED' and meta['gain_cut_resampled_in_antenna_local_frame']
  assert meta['cut_direction_rotation_local_to_solver']==evidence['installed_geometry']['installation']['nominal_R_BL']
 assert sorted(float(m['frequency_ghz']) for m in meta['monitors'])==sorted(float(r[k]) for k in ['f_low_ghz','f_center_ghz','f_high_ghz'])
 assert all(m['normalization_reliable'] for m in meta['monitors'])
 imported=folder/'registered';imported.mkdir(exist_ok=True)
 files=[]
 for f in [float(r[k]) for k in ['f_low_ghz','f_center_ghz','f_high_ghz']]:
  for plane in ['XZ','YZ']:
   name=f'f{f:.6f}_{plane}.csv';raw=list(csv.DictReader((folder/name).open(encoding='utf-8')))
   assert len(raw)==360 and [float(v['theta']) for v in raw]==list(range(360)),name
   assert all(math.isfinite(float(v['realized_gain_dbi'])) for v in raw),name
   target=imported/name
   with target.open('w',newline='',encoding='utf-8') as stream:
    w=csv.writer(stream);w.writerow(['theta','gain']);w.writerows((v['theta'],v['realized_gain_dbi']) for v in raw)
   files.append(dict(path=str((dataset/'registered'/name).as_posix()),raw_sha256=hashlib.sha256((folder/name).read_bytes()).hexdigest()))
 registry.append(dict(dataset_id=Path(r['project_file']).stem.replace('RFC_',''),configuration_id='CN_'+Path(r['project_file']).stem.replace('RFC_',''),pattern_class='InstalledPattern' if r['configuration']=='INSTALLED' else 'FreeSpacePattern',
  installation_id=r['installation_identity'],directory=dataset.as_posix(),frequencies_ghz=[float(r[k]) for k in ['f_low_ghz','f_center_ghz','f_high_ghz']],files=files,frame='CST_LOCAL_PRESERVED',gain_quantity='RealizedGain'))
owner=ROOT/'output/codex/emission_inputs/latest_owner_policy.json'
anchors=ROOT/'output/codex/sar_owner_pattern_anchors.csv'
policy=json.loads(owner.read_text(encoding='utf-8'))
assert policy['sar_absolute_peak_gain_dbi']==52 and policy['sar_rear_relative_peak_db']==-50 and policy['sar_allowable_psd_dbm_hz']==-176
registry.append(dict(dataset_id='SAR_ENGINEERING_RECEIVE_BASELINE',configuration_id='CN_SAR_ENGINEERING_RECEIVE_BASELINE',pattern_class='EngineeringReceiveBaseline',
 installation_id='SAR_ANT',directory='output/codex',frequencies_ghz=[9.65],frequency_span_ghz=[9.3875,9.9125],
 frequency_model='OWNER_ENGINEERING_RECEIVE_BASELINE_HELD_CONSTANT_OVER_SAR_TUNING_BAND; NOT_THREE_CST_MONITORS',
 frame='REPOSITORY_ANTENNA_X_BORESIGHT',gain_quantity='OwnerEngineeringGain',gain_unit='dBi',
 peak_gain_dbi=52,rear_gain_dbi=2,allowable_psd_dbm_hz=-176,provenance='OWNER_EXTRACTED_FROM_K8_SAR_PATTERN_MAT; ENGINEERING_RECONSTRUCTION; OWNER_ENGINEERING_REAR_ENVELOPE',
 source_hashes={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in [owner,anchors]}))
(ROOT/'data/closed_network_patterns/registry.json').write_text(json.dumps(registry,indent=2)+'\n',encoding='utf-8')
print('Registered datasets:',len(registry),'(accepted CST:',len(registry)-1,'; SAR engineering baseline: 1)')
