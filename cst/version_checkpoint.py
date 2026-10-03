"""Immutable version index for existing CST projects and validation evidence."""
import argparse,hashlib,json,shutil,subprocess
from datetime import datetime,timezone
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

ISL_SOURCES=['generate_isl.py','verify_isl_results.py','cst_com.py','cst_geometry.py','cst_results.py',
             'cst_com_common.py','rfc_validation.py','export_cst_source.py','specs/xband_isl.yaml',
             'specs/rfc_acceptance.yaml','tools/invoke-cst.ps1']

KA_SOURCES=['generate_ka_feed.py','ka_feed_results.py','ka_reflector_po.py','ka_reflector_eval.py','finalize_ka.py',
            'cst_com.py','cst_geometry.py','cst_results.py','cst_com_common.py','rfc_validation.py',
            'specs/kaband_dls.yaml','specs/rfc_acceptance.yaml','tools/invoke-cst.ps1']

SAR_SOURCES=['generate_sar_leaf.py','eval_sar_leaf.py','finalize_sar.py','cst_com.py','cst_geometry.py',
             'cst_results.py','cst_com_common.py','export_cst_source.py','specs/xband_sar.yaml','tools/invoke-cst.ps1']

def checkpoint(version,label,note,band='lband'):
    dest=ROOT/'versions'/band/version
    if dest.exists():raise FileExistsError(f'Immutable checkpoint already exists: {dest}')
    project=ROOT/'projects'/f'{label}.cst';results=ROOT/'results'/label
    if not project.exists():raise FileNotFoundError(project)
    dest.mkdir(parents=True)
    names=ISL_SOURCES if band=='isl' else KA_SOURCES if band=='ka' else SAR_SOURCES if band=='sar' else ['generate_lband_gnss.py','verify_lband_results.py','cst_com.py',
                             'cst_geometry.py','cst_results.py','cst_com_common.py',
                             'rfc_validation.py','finalize_lband_band.py','export_cst_source.py',
                             'specs/lband_gnss.yaml','specs/rfc_acceptance.yaml']
    sources=[ROOT/p for p in names]
    manifest={'version':version,'label':label,'recorded_utc':datetime.now(timezone.utc).isoformat(),
              'git_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT).decode().strip(),
              'project':str(project),'project_sha256':sha(project),'note':note,
              'source_snapshot_scope':'CURRENT_CHECKPOINT_STATE_NOT_RETROACTIVE_GENERATION_PROOF',
              'mesh_validation':'DISABLED_BY_USER','sources':{},'evidence':{}}
    for path in sources:
        relative=path.relative_to(ROOT);target=dest/'source'/relative
        target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,target)
        manifest['sources'][str(relative)]=sha(path)
    evidence=[project.with_suffix('.geometry.json'),results/'validation.json',results/'s_matrix.npz',
              results/'rfc_pass_matrix.json',results/'feed_pattern.json',results/'s_parameters.csv',ROOT/'tools'/'commands'/label/'history.vba',
              ROOT/'tools'/'commands'/label/'job.json',ROOT/'tools'/'commands'/label/'candidate.json']
    for path in evidence:
        if path.exists():
            target=dest/'evidence'/path.name;
            target.parent.mkdir(exist_ok=True)
            shutil.copy2(path,target);manifest['evidence'][str(path.relative_to(ROOT))]=sha(path)
    log=project.with_suffix('')/'Result'/'Model.log'
    if log.exists():
        target=dest/'evidence'/'Model.log';target.parent.mkdir(exist_ok=True);shutil.copy2(log,target)
        manifest['evidence'][str(log.relative_to(ROOT))]=sha(log)
    (dest/'manifest.json').write_text(json.dumps(manifest,indent=2))
    with (ROOT/'versions'/band/'index.jsonl').open('a') as stream:
        stream.write(json.dumps({'version':version,'label':label,'note':note,'manifest':str(dest/'manifest.json')})+'\n')
    return dest

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('version');p.add_argument('label');p.add_argument('note');p.add_argument('--band',default='lband');a=p.parse_args()
    print(checkpoint(a.version,a.label,a.note,a.band))
