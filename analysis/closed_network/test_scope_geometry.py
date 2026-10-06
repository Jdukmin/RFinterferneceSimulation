"""Owner scope, multiport group power, and Installed cut frame tests; no solver."""
import sys,json,unittest,hashlib,subprocess
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'cst/closed_network'));sys.path.insert(0,str(ROOT/'cst'))
from export_patterns import excitation_vector,net_accepted_fraction
from fixed_body_geometry import local_cut_direction_in_solver
class ScopeTests(unittest.TestCase):
 def test_owner_scope_and_all_ten_pair_bindings(self):
  folder=ROOT/'cst/projects/closed_network';bindings={b['dataset_id']:b for b in json.loads((folder/'dataset_bindings.json').read_text())};plan=json.loads((ROOT/'analysis/closed_network/rfi_plan.json').read_text());self.assertEqual(len(plan),37);self.assertEqual(len({r['pair_id'] for r in plan}),10)
  for r in plan:
   tx=bindings[r['tx_dataset']];self.assertEqual(tx['pattern_class'],'FreeSpacePattern' if r['pair'].startswith('KAA') else 'InstalledPattern')
   if tx['pattern_class']=='InstalledPattern':self.assertEqual(tx['installation_id'],r['tx_installation'])
   if r['rx_dataset']=='SAR_ENGINEERING_RECEIVE_BASELINE':continue
   rx=bindings[r['rx_dataset']];self.assertEqual(rx['pattern_class'],'InstalledPattern');self.assertEqual(rx['installation_id'],r['rx_installation'])
  for p in folder.glob('kaa/*.cst'):
   prior=subprocess.check_output(['git','show','8254454:'+p.relative_to(ROOT).as_posix()],cwd=ROOT);self.assertEqual(hashlib.sha256(prior).hexdigest(),hashlib.sha256(p.read_bytes()).hexdigest())
 def test_four_active_ports_other_group_zero(self):
  a=excitation_vector(8,[5,6,7,8],[0,90,180,270]);np.testing.assert_array_equal(a[:4],0);self.assertAlmostEqual(float(np.vdot(a,a).real),4)
  s=np.zeros((1,8,8),complex);s[0,4:,4:]=np.eye(4)*.1;s[0,:4,4:]=np.eye(4)*.2
  accepted,b=net_accepted_fraction(s,a);self.assertAlmostEqual(accepted[0],.95);self.assertEqual(b.shape,(1,8))
 def test_installed_direction_export_roundtrip_all_groups(self):
  g=json.loads((ROOT/'cst/closed_network/full_spacecraft_geometry.json').read_text());panels={p['panel_id']:p for p in g['full_outer_panels']};count=0
  for p in (ROOT/'cst/projects/closed_network').glob('*/RFC*.preflight.json'):
   e=json.loads(p.read_text());groups=e.get('installation_groups',[])
   if not groups and e.get('installed_geometry'):groups=[dict(installation=e['installed_geometry']['installation'])]
   for group in groups:
    i=group['installation'];R=np.array(i['nominal_R_BL']);np.testing.assert_allclose(R[:,2],panels[i['panel_id']]['outward_normal_body'],atol=1e-9);self.assertAlmostEqual(np.linalg.det(R),1)
    for phi in [0,90]:
     for theta in range(360):
      sampling=dict(installed_geometry=dict(installation=i));t,p=local_cut_direction_in_solver(theta,phi,sampling);t,p=np.radians([t,p]);d=np.array([np.sin(t)*np.cos(p),np.sin(t)*np.sin(p),np.cos(t)]);tl,pl=np.radians([theta,phi]);expected=[np.sin(tl)*np.cos(pl),np.sin(tl)*np.sin(pl),np.cos(tl)];np.testing.assert_allclose(R.T@d,expected,atol=1e-12)
    count+=1
  self.assertEqual(count,14)
if __name__=='__main__':unittest.main(verbosity=2)
