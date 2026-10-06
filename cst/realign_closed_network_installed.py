"""Regenerate only installed projects in fixed body coordinates; never run solver."""
import json,tempfile,shutil
from pathlib import Path
from prepare_closed_network import *

def main():
 g=geometry();rows=inventory();app=connect_cst(False);backup=Path(tempfile.mkdtemp(prefix='cst_before_body_alignment_'))
 for row in rows:
  if row['configuration']!='INSTALLED':continue
  dest=ROOT/row['project_file'];old=json.loads(dest.with_suffix('.preflight.json').read_text());shutil.copy2(dest,backup/dest.name)
  temp=dict(row);temp['project_file']=row['project_file'].replace('.cst','_BODY_FRAME_ALIGNED.cst')
  record=prepare(temp,app,g)
  tempdest=ROOT/temp['project_file'];shutil.copy2(tempdest,dest)
  record['project_file']=row['project_file'];record['project_sha256']=sha(dest)
  record['solver_selection_policy']=old['solver_selection_policy'];record['preferred_solver_review']=old['preferred_solver_review']
  record['orientation_update']='OWNER_FIXED_SPACECRAFT_BODY_FRAME; ISL_PANEL_7_PLUS_X'
  write_json(dest.with_suffix('.preflight.json'),record)
  tempdest.unlink();tempdest.with_suffix('.preflight.json').unlink()
 write_json(ROOT/'cst/closed_network/full_spacecraft_geometry.json',g)
 print('Backup:',backup,flush=True)
if __name__=='__main__':main()
