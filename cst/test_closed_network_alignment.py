"""Installed frames, export direction mapping, and untouched original project checks."""
import hashlib,json,subprocess,unittest
from pathlib import Path
import numpy as np
from prepare_closed_network import ROOT,geometry
from export_closed_network_patterns import local_cut_direction_in_solver

class AlignmentTests(unittest.TestCase):
 def test_installed_boresight_and_fixed_hull(self):
  g=geometry();old=json.loads(subprocess.check_output(['git','show','b5adc44:cst/closed_network/full_spacecraft_geometry.json'],cwd=ROOT))
  for a,b in zip(g['full_outer_panels'],old['full_outer_panels']):self.assertEqual(a['body_vertices_mm'],b['body_vertices_mm'])
  for path in (ROOT/'cst/projects/closed_network').glob('*/RFC_INSTALLED*.preflight.json'):
   e=json.loads(path.read_text());ig=e['installed_geometry'];i=ig['installation'];R=np.array(i['nominal_R_BL'])
   panel=next(p for p in g['full_outer_panels'] if p['panel_id']==i['panel_id'])
   np.testing.assert_allclose(R[:,2],panel['outward_normal_body'],atol=1e-9)
   self.assertEqual(ig['global_solver_frame'],'SPACECRAFT_BODY_FIXED');self.assertFalse(e['solver_started'])
   if i['installation_id']=='ISL':self.assertEqual(i['panel_id'],'PANEL_7');np.testing.assert_allclose(R[:,2],[1,0,0])
   for p in ig['panels']:self.assertEqual(p['body_vertices_mm'],next(q for q in g['full_outer_panels'] if q['panel_id']==p['panel_id'])['body_vertices_mm'])
 def test_local_cut_resampling_roundtrip(self):
  for path in (ROOT/'cst/projects/closed_network').glob('*/RFC_INSTALLED*.preflight.json'):
   e=json.loads(path.read_text());R=np.array(e['installed_geometry']['installation']['nominal_R_BL'])
   for phi in [0,90]:
    for theta in range(360):
     t,p=local_cut_direction_in_solver(theta,phi,e);t,p=np.radians([t,p]);d=np.array([np.sin(t)*np.cos(p),np.sin(t)*np.sin(p),np.cos(t)])
     tl,pl=np.radians([theta,phi]);expected=np.array([np.sin(tl)*np.cos(pl),np.sin(tl)*np.sin(pl),np.cos(tl)])
     np.testing.assert_allclose(R.T@d,expected,atol=1e-12)
 def test_original_and_kaa_binaries_unchanged(self):
  count=0
  for p in (ROOT/'cst/projects/closed_network').glob('*/*.cst'):
   if p.name.startswith('RFC_INSTALLED'):continue
   prior=subprocess.check_output(['git','show','b5adc44:'+p.relative_to(ROOT).as_posix()],cwd=ROOT)
   self.assertEqual(hashlib.sha256(prior).hexdigest(),hashlib.sha256(p.read_bytes()).hexdigest());count+=1
  self.assertEqual(count,18)
if __name__=='__main__':unittest.main(verbosity=2)
