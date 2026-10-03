"""Freeze the selected ISL candidate: scalar RFC exports + native complex CST sources."""
import argparse,json,shutil
from pathlib import Path
from cst_com_common import connect_cst,get_active_project,method
from cst_com import ROOT
from verify_isl_results import export,FREQS
from export_cst_source import export as export_source

def main():
    a=argparse.ArgumentParser();a.add_argument('label');args=a.parse_args()
    results=ROOT/'results'/args.label;report=json.loads((results/'validation.json').read_text())
    if report['status']!='ISL_ASSUMED_TEMPLATE_PASS':raise SystemExit('Selected candidate did not pass')
    dest=ROOT/'exports'/'isl'
    if dest.exists():raise FileExistsError(f'Refusing overwrite: {dest}')
    export(results,True)
    shutil.copytree(results/'screening_export',dest/'screening_1deg')
    project=ROOT/'projects'/f'{args.label}.cst'
    app=connect_cst(False);p=method(app,'OpenFile',str(project))
    if p is None:p=get_active_project(app)
    # Broadband export writes every monitor frequency into one file.
    sources={'file':str(export_source(p,dest/'isl_rhcp_broadband.ffs',FREQS[1])),'frequencies_ghz':FREQS}
    (dest/'isl_final_validation.json').write_text(json.dumps({'selected':args.label,'validation':report,
        'scalar_export':'1-degree; VALIDATED_MAIN (0..60 deg) = CST accepted-power RHCP; elsewhere max(CST, conservative assumed envelope)',
        'native_sources':sources,'complex_field_clipped':False,
        'boresight':'+Z native; rotate to repository +X with the recorded proper rotation when installing',
        'mesh_validation':'DISABLED_BY_USER; no convergence claim'},indent=2))
    print(dest)

if __name__=='__main__':main()
