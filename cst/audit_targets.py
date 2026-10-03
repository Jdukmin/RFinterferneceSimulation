"""Read repository target cuts without changing their screening provenance."""
import csv,json,hashlib
from pathlib import Path
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
ANGLES=[0,15,30,45,60,75,80,85,90,105,120,150,180]

def audit():
    entries=[]
    for folder in ['Sband_TMTC','Lband_GPS','Kaband_DLS']:
        for path in sorted((ROOT/'data'/folder).glob('*.csv')):
            with path.open() as f:rows=list(csv.DictReader(f))
            theta=np.array([float(r['theta']) for r in rows]);gain=np.array([float(r['gain']) for r in rows])
            entries.append({'path':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                'samples':len(rows),'peak_gain_dbi':float(gain.max()),'peak_theta_deg':float(theta[gain.argmax()]),
                'angle_gain_dbi':dict(zip(map(str,ANGLES),map(float,np.interp(ANGLES,theta,gain)))),
                'provenance':'DATASHEET_DERIVED_SCREENING_ENVELOPE_NOT_COMPLEX_EM_TRUTH'})
    # Read all text in antenna/pattern sources, docs and examples; retain audit hashes.
    texts={}
    for folder in ['src','docs','examples']:
        for path in (ROOT/folder).rglob('*'):
            if path.suffix.lower() in ['.md','.m','.txt','.yaml','.json']:
                content=path.read_text(encoding='utf-8',errors='replace')
                if 'antenna' in content.lower() or 'pattern' in content.lower():
                    texts[path.relative_to(ROOT).as_posix()]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'characters':len(content)}
    result={'cuts':entries,'repository_text_audit':texts,
        'coordinate_map_source_to_antenna':[[0,0,1],[1,0,0],[0,1,0]],
        'xband_isl':{'status':'NO_REPOSITORY_NUMERIC_TARGET_FOUND','frequency':'ASSUMPTION_REQUIRED','beamwidth':'120 deg coverage is user requirement, not established HPBW'},
        'xband_sar':{'status':'NO_REPOSITORY_NUMERIC_TARGET_FOUND','f0_ghz':9.65,'provenance':'USER_REFERENCE_ARCHITECTURE'},
        'ka_conflict':'Repository README says 31.2 dBi at 27 GHz / 1 deg; user range says 32.2. Preserve CSV 31.4 representative and report separately.'}
    out=ROOT/'cst'/'specs';out.mkdir(exist_ok=True)
    (out/'repository_ssot.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(entries,indent=2))

if __name__=='__main__':audit()
