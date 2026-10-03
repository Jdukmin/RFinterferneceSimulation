"""Fresh-process candidate evaluation with pinned source/config manifest."""
import argparse,hashlib,json,subprocess,sys
from pathlib import Path
import numpy as np
from cst_com import ROOT,save
from generate_sband_ttc import build
from verify_sband_results import verify
from rfc_validation import reevaluate

def fingerprint(config):
    paths=sorted(ROOT.glob('*.py'))+sorted((ROOT/'specs').glob('*.yaml'))
    return {'git_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT).decode().strip(),
        'python':sys.version,'config':config,
        'source_sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}}

def main():
    a=argparse.ArgumentParser();a.add_argument('config');a.add_argument('--label',required=True)
    a.add_argument('--mesh-lines-per-wavelength',type=float)
    a.add_argument('--mesh-arm-step',type=float)
    args=a.parse_args();v=json.loads(Path(args.config).read_text());label=args.label
    path=ROOT/'projects'/f'{label}.cst';out=ROOT/'results'/label;out.mkdir(parents=True,exist_ok=True)
    manifest=fingerprint(v);manifest['evidence_status']='PRE_FINAL_UNTIL_ALL_GATES_PASS'
    manifest['mesh_lines_per_wavelength']=args.mesh_lines_per_wavelength
    manifest['mesh_arm_step_mm']=args.mesh_arm_step
    (out/'run_manifest.json').write_text(json.dumps(manifest,indent=2))
    app,p=build(v,path,True,mesh_lines_per_wavelength=args.mesh_lines_per_wavelength,
                  mesh_arm_step=args.mesh_arm_step)
    verify(p,out,frequency_robustness=True);save(p,path);reevaluate(out)
    after=fingerprint(v)
    if any(manifest[k]!=after[k] for k in ['git_sha','source_sha256','config']):
        raise RuntimeError('Source/config changed during execution; invalid final evidence')
    manifest['source_config_stable']=True
    (out/'run_manifest.json').write_text(json.dumps(manifest,indent=2))

if __name__=='__main__':main()
