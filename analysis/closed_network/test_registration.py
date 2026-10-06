"""Temporary synthetic exports only; no solver or repository dataset mutation."""
import csv,json,shutil,subprocess,sys,tempfile,unittest
from pathlib import Path
SCRIPT=Path(__file__).with_name('register_closed_network_patterns.py')
class RegistrationTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(prefix='codex_pattern_registration_');self.addCleanup(self.temp.cleanup)
  self.root=Path(self.temp.name);self.script=self.root/'analysis/closed_network'/SCRIPT.name
  self.script.parent.mkdir(parents=True);shutil.copy2(SCRIPT,self.script)
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
