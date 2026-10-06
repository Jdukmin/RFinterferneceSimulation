"""Temporary synthetic exports only; no solver or repository dataset mutation."""
import csv,json,shutil,subprocess,sys,tempfile,unittest
from pathlib import Path
SCRIPT=Path(__file__).with_name('register_closed_network_patterns.py')
class RegistrationTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(prefix='codex_pattern_registration_');self.addCleanup(self.temp.cleanup)
  self.root=Path(self.temp.name);self.script=self.root/'analysis/closed_network'/SCRIPT.name
  self.script.parent.mkdir(parents=True);shutil.copy2(SCRIPT,self.script)
  shutil.copy2(SCRIPT.with_name('cst2024_provenance.py'),self.script.parent)
  (self.root/'docs').mkdir();self.dataset=self.root/'data/closed_network_patterns/SYNTHETIC';self.dataset.mkdir(parents=True)
  self.row=dict(project_file='cst/projects/closed_network/test/RFC_SYNTHETIC.cst',expected_output_directory='data/closed_network_patterns/SYNTHETIC',
   configuration='INSTALLED',installation_identity='TEST_ONLY',f_low_ghz=1,f_center_ghz=2,f_high_ghz=3)
  with (self.root/'docs/closed_network_cst_project_inventory.csv').open('w',newline='') as f:
   w=csv.DictWriter(f,fieldnames=list(self.row));w.writeheader();w.writerow(self.row)
  self.meta=dict(project_file=self.row['project_file'],status='SOLVED_ACCEPTED',gain_quantity='RealizedGain',gain_unit='dBi',convergence_accepted=True,
   frame='CST_LOCAL_PRESERVED',solver_frame='SPACECRAFT_BODY_FIXED',gain_cut_resampled_in_antenna_local_frame=True,
   cut_direction_rotation_local_to_solver=[[1,0,0],[0,1,0],[0,0,1]],monitors=[dict(frequency_ghz=f,normalization_reliable=True) for f in [1,2,3]])
  self.save_meta()
  evidence=(self.root/self.row['project_file']).with_suffix('.preflight.json');evidence.parent.mkdir(parents=True)
  evidence.write_text(json.dumps(dict(installed_geometry=dict(installation=dict(nominal_R_BL=self.meta['cut_direction_rotation_local_to_solver'])))))
  owner=self.root/'output/codex/emission_inputs';owner.mkdir(parents=True)
  original=SCRIPT.parents[2]/'output/codex'
  shutil.copy2(original/'emission_inputs/latest_owner_policy.json',owner)
  shutil.copy2(original/'sar_owner_pattern_anchors.csv',owner.parent)
  for freq in [1,2,3]:
   for plane in ['XZ','YZ']:
    with (self.dataset/f'f{freq:.6f}_{plane}.csv').open('w',newline='') as f:
     w=csv.writer(f);w.writerow(['theta','realized_gain_dbi']);w.writerows((i,-30+i/100) for i in range(360))
 def save_meta(self):(self.dataset/'provenance.json').write_text(json.dumps(self.meta))
 def run_script(self):return subprocess.run([sys.executable,str(self.script)],capture_output=True,text=True)
 def test_accepted_dataset_and_raw_unchanged(self):
  before={p.name:p.read_bytes() for p in self.dataset.glob('*.csv')}
  result=self.run_script();self.assertEqual(result.returncode,0,result.stderr)
  entries=json.loads((self.dataset.parent/'registry.json').read_text());self.assertEqual(len(entries),2)
  self.assertEqual(entries[0]['pattern_class'],'InstalledPattern');self.assertEqual(len(entries[0]['files']),6)
  self.assertEqual(entries[1]['pattern_class'],'EngineeringReceiveBaseline');self.assertEqual(entries[1]['rear_gain_dbi'],2)
  self.assertEqual(entries[1]['frequencies_ghz'],[9.65]);self.assertEqual(entries[1]['frequency_span_ghz'],[9.3875,9.9125])
  self.assertEqual(before,{p.name:p.read_bytes() for p in self.dataset.glob('*.csv')})
 def configure_second_port_group_binding(self):
  import hashlib
  source=self.root/self.row['project_file'];source.write_bytes(b'SYNTHETIC_CST_FIXTURE_NOT_A_REAL_PROJECT')
  digest=hashlib.sha256(source.read_bytes()).hexdigest()
  binding=dict(dataset_id='SECOND_GROUP',project_file=self.row['project_file'],installation_id='TEST_ONLY',pattern_class='InstalledPattern',frequencies_ghz=[1,2,3],directory=self.row['expected_output_directory'],port_numbers=[5,6,7,8])
  file=self.root/'cst/projects/closed_network/dataset_bindings.json';file.parent.mkdir(parents=True,exist_ok=True);file.write_text(json.dumps([binding]))
  matrix=[[1,0,0],[0,1,0],[0,0,1]]
  first=dict(installation_id='FIRST_GROUP',nominal_R_BL=[[1,0,0],[0,-1,0],[0,0,-1]])
  second=dict(installation_id='TEST_ONLY',nominal_R_BL=matrix)
  source.with_suffix('.preflight.json').write_text(json.dumps(dict(project_sha256=digest,installed_geometry=dict(installation=first),installation_groups=[dict(installation=first,port_numbers=[1,2,3,4]),dict(installation=second,port_numbers=[5,6,7,8])])))
  self.meta.update(dataset_id='SECOND_GROUP',project_sha256=digest,installation_id='TEST_ONLY',active_port_numbers=[5,6,7,8]);self.save_meta()
 def test_second_port_group_registered_as_installed(self):
  self.configure_second_port_group_binding();result=self.run_script();self.assertEqual(result.returncode,0,result.stderr)
  entry=json.loads((self.dataset.parent/'registry.json').read_text())[0];self.assertEqual(entry['dataset_id'],'SECOND_GROUP');self.assertEqual(entry['pattern_class'],'InstalledPattern');self.assertEqual(entry['installation_id'],'TEST_ONLY')
 def test_wrong_active_port_group_rejected(self):
  self.configure_second_port_group_binding();self.meta['active_port_numbers']=[1,2,3,4];self.save_meta();self.assertNotEqual(self.run_script().returncode,0)
 def test_stale_project_hash_rejected(self):
  self.configure_second_port_group_binding();self.meta['project_sha256']='STALE';self.save_meta();self.assertNotEqual(self.run_script().returncode,0)
 def configure_native_2024(self):
  import hashlib
  self.configure_second_port_group_binding()
  package=self.root/'cst/projects/closed_network_2024_build/sba/RFC_SYNTHETIC';package.mkdir(parents=True)
  (package/'build_2024.vba').write_bytes(b'SYNTHETIC_MACRO_FIXTURE')
  (package/'source_geometry.json').write_bytes(b'{}')
  digest=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
  native=self.root/'cst/projects/closed_network_2024_native/sba/RFC_SYNTHETIC_CST2024.cst';native.parent.mkdir(parents=True);native.write_bytes(b'SYNTHETIC_NATIVE_2024_FIXTURE_NOT_CST')
  manifest=dict(case_id='RFC_SYNTHETIC',source_project=self.row['project_file'],source_geometry_hash='TEST_GEOMETRY_HASH',build_vba_sha256=digest(package/'build_2024.vba'),source_geometry_file_sha256=digest(package/'source_geometry.json'),expected_native_filename=native.name,expected_object_count=20,port_count=8,spacecraft_panel_count=8)
  (package/'build_manifest.json').write_text(json.dumps(manifest))
  checks=['geometry','bbox','materials','ports','phase','reference_plane','monitors','boundaries','installation_frames','all_ssot_panels','no_crop','native_2024_save']
  record=dict(case_id='RFC_SYNTHETIC',actual_cst_version=2024,status='GEOMETRY_ACCEPTED_CST2024',native_project_file=native.relative_to(self.root).as_posix(),native_project_sha256=digest(native),source_geometry_hash=manifest['source_geometry_hash'],build_vba_sha256=manifest['build_vba_sha256'],reviewer='SYNTHETIC_TEST_ONLY',checked_at='TEST_ONLY',about_version_text='SYNTHETIC_NOT_REAL_CST2024',checks={c:True for c in checks},geometry_object_count=20,port_count=8,monitor_count=3,spacecraft_panel_count=8)
  self.native_validation=native.with_suffix('.native_validation.json');self.native_validation.write_text(json.dumps(record))
  self.meta.update(cst_version=2024,project_file=native.relative_to(self.root).as_posix(),project_sha256=digest(native),binding_project_file=self.row['project_file'],build_package=package.relative_to(self.root).as_posix(),native_validation_file=self.native_validation.relative_to(self.root).as_posix(),source_geometry_hash=manifest['source_geometry_hash']);self.save_meta()
 def test_native_2024_hash_distinct_from_2026_accepted(self):
  self.configure_native_2024();result=self.run_script();self.assertEqual(result.returncode,0,result.stderr)
 def test_wrong_native_2024_version_rejected(self):
  self.configure_native_2024();record=json.loads(self.native_validation.read_text());record['actual_cst_version']=2026;self.native_validation.write_text(json.dumps(record));self.assertNotEqual(self.run_script().returncode,0)
 def test_unapproved_native_geometry_rejected(self):
  self.configure_native_2024();record=json.loads(self.native_validation.read_text());record['checks']['installation_frames']=False;self.native_validation.write_text(json.dumps(record));self.assertNotEqual(self.run_script().returncode,0)
 def test_stale_native_project_hash_rejected(self):
  self.configure_native_2024();record=json.loads(self.native_validation.read_text());record['native_project_sha256']='STALE';self.native_validation.write_text(json.dumps(record));self.assertNotEqual(self.run_script().returncode,0)
 def test_unreliable_normalization_rejected(self):
  self.meta['monitors'][0]['normalization_reliable']=False;self.save_meta();self.assertNotEqual(self.run_script().returncode,0)
 def test_wrong_frequency_rejected(self):
  self.meta['monitors'][0]['frequency_ghz']=1.1;self.save_meta();self.assertNotEqual(self.run_script().returncode,0)
 def test_body_cuts_without_local_resampling_rejected(self):
  self.meta['gain_cut_resampled_in_antenna_local_frame']=False;self.save_meta();self.assertNotEqual(self.run_script().returncode,0)
 def test_wrong_cut_rotation_rejected(self):
  self.meta['cut_direction_rotation_local_to_solver']=[[0,0,1],[1,0,0],[0,1,0]];self.save_meta();self.assertNotEqual(self.run_script().returncode,0)
 def test_nan_rejected(self):
  p=self.dataset/'f1.000000_XZ.csv';p.write_text(p.read_text().replace('0,-30.0','0,nan'))
  self.assertNotEqual(self.run_script().returncode,0)
if __name__=='__main__':unittest.main(verbosity=2)
