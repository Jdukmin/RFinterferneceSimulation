"""Physically consistent Ka-band 1-degree screening patterns (replacement proposal for data/Kaband_DLS).

0..1 deg (datasheet coverage, anchors passed) = model RHCP accepted-power gain.
Elsewhere = max(model, existing repository CSV): the CSV beyond 1 deg is an arbitrary
envelope, the aperture model omits strut/spillover/backlobe scattering, so the
conservative maximum is exported. Raw model cuts are exported separately.
"""
import argparse,csv,json,shutil
from pathlib import Path
from rfc_validation import export_screening

ROOT=Path(__file__).resolve().parent
REF=ROOT.parent/'data'/'Kaband_DLS'/'KARMA7_FG_KaBand_XZ.csv'

def main():
    a=argparse.ArgumentParser();a.add_argument('reflector_result');args=a.parse_args()
    res=ROOT/'results'/args.reflector_result;report=json.loads((res/'reflector_validation.json').read_text())
    if report['status']!='KA_DATASHEET_ANCHOR_PASS':raise SystemExit('not passed')
    dest=ROOT/'exports'/'ka'
    if dest.exists():raise FileExistsError(dest)
    ref={int(r['theta']):float(r['gain']) for r in csv.DictReader(REF.open())}
    out={}
    for f in ['25.5','26.25','27']:
        model={int(r['theta']):float(r['rhcp_gain_dbi']) for r in csv.DictReader((res/f'full_1deg_f{f}.csv').open())}
        rows=[{'theta':t,'gain':model[min(t,360-t)],'target_gain':ref[t]} for t in range(360)]
        name=f"KA_DLS_physical_f{f.replace('.','p')}"
        for plane in ['XZ','YZ']:   # axisymmetric aperture model: XZ == YZ
            export_screening(rows,dest/'screening_1deg'/f'{name}_{plane}.csv',coverage=1,main_valid=True)
        (dest/'raw_model').mkdir(parents=True,exist_ok=True)
        with (dest/'raw_model'/f'{name}_model.csv').open('w',newline='') as st:
            w=csv.writer(st);w.writerow(['theta','gain']);w.writerows((t,round(model[min(t,360-t)],4)) for t in range(360))
        shutil.copy2(res/f'fine_0p05deg_f{f}.csv',dest/'raw_model'/f'{name}_fine_0p05deg.csv')
        out[f]={k:report[f'f{f}'][k] for k in ['boresight_dbi','hpbw_deg','first_null_deg','first_sidelobe','xpd_within_1deg_db']}
    (dest/'ka_final_validation.json').write_text(json.dumps({'selected_feed':report['feed_project'],
        'reflector':report['reflector'],'datasheet_anchor_errors_db':report['anchor_errors_db'],
        'status':report['status'],'summary':out,
        'export_rule':'0..1 deg model (VALIDATED_MAIN); elsewhere max(model, repository CSV envelope)',
        'replaces':'data/Kaband_DLS arbitrary beamwidth (2 deg 28.5, 3 deg 15 dBi). data/ not modified (scope cst/ only).',
        'stage_note':'Feed = CST full-wave; reflector = Python equivalent-paraboloid aperture integration (Learning Edition has no PO).',
        'mesh_validation':'DISABLED_BY_USER'},indent=2))
    print(dest)

if __name__=='__main__':main()
