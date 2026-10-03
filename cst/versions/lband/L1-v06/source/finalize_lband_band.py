"""Evidence-based band-level RFC gates; no matching or convergence hard gate."""
import argparse,csv,json
from pathlib import Path
import numpy as np
from rfc_validation import export_screening

def crossing(g,threshold):
    for i in range(1,len(g)):
        if g[i]<=threshold<g[i-1]:
            return i-1+(g[i-1]-threshold)/(g[i-1]-g[i])
    return None

def beamwidth(g):
    threshold=max(g)-3
    right=crossing(g[:91],threshold)
    left=crossing(np.r_[g[0],g[359:269:-1]],threshold)
    return None if right is None or left is None else float(right+left)

def finalize(out):
    out=Path(out);validation=json.loads((out/'validation.json').read_text());report={}
    for key,item in validation.items():
        with (out/f'accepted_power_{key}.csv').open() as stream:rows=list(csv.DictReader(stream))
        g=np.array([float(r['gain']) for r in rows]);ref=np.array([float(r['target_gain']) for r in rows])
        hpbw=beamwidth(g);target_hpbw=beamwidth(ref)
        pointing=min(int(np.argmax(g)),360-int(np.argmax(g)))
        ar60=max(float(r['axial_ratio_db']) for r in rows if min(int(r['theta']),360-int(r['theta']))<=60)
        # Handedness must remain the intended fixed sense, not point-wise hand selection.
        hand=min(float(r['cp_plus_db'])-float(r['cp_minus_db']) for r in rows if min(int(r['theta']),360-int(r['theta']))<=90)
        m=item['metrics'];checks={'main_mae':m['main_mae_db']<=1.5,
            'peak_gain':m['peak_error_db']<=1,'source_screening_anchors':item['source_comparison']['anchor_pass'] is True,
            'boresight':abs(m['boresight_error_db'])<=1,'eoc_gain':abs(m['eoc_gain_error_db'])<=1.5,
            'gain60':abs(m['anchor_errors_db']['60'])<=1.5,
            'hpbw':hpbw is not None and target_hpbw is not None and abs(hpbw/target_hpbw-1)<=.1,
            'pointing':target_hpbw is not None and pointing<=.1*target_hpbw,
            'intended_rhcp':hand>0,'accepted_power_normalization':item['normalization_reliable']}
        passed=all(checks.values())
        report[key]={'checks':checks,'overall':'PASS' if passed else 'FAIL',
            'hpbw_deg':hpbw,'reference_hpbw_deg':target_hpbw,'pointing_error_deg':pointing,
            'ar_max_through60_db':ar60,'hemisphere_rhcp_discrimination_min_db':hand,
            'mesh_validation':'DISABLED_BY_USER','active_matching':'DIAGNOSTIC_ONLY',
            'polarization_scope':'Intended RHCP verified; AR<3–5 dB is a preferred source-supported target, not an invented hard hemisphere guarantee.',
            'reference_scope':item['reference_limitation']}
    all_pass=bool(report) and all(item['overall']=='PASS' for item in report.values())
    if all_pass:
        for key in report:
            with (out/f'accepted_power_{key}.csv').open() as stream:rows=list(csv.DictReader(stream))
            export_screening(rows,out/'rfc_screening'/f'{key}.csv',main_valid=True)
    final={'overall':'PASS' if all_pass else 'FAIL','scope':'ONLY_FREQUENCIES_AND_CUTS_IN_THIS_REPORT',
           'gain_basis':'ACCEPTED_POWER_RHCP_GAIN','cuts':report,
           'geometry_screenshots':'SEPARATE_DELIVERABLE_NOT_YET_PROVEN',
           'installed_complex_source':'SEPARATE_DELIVERABLE_NOT_YET_PROVEN'}
    (out/'rfc_pass_matrix.json').write_text(json.dumps(final,indent=2))
    return final

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('out');a=parser.parse_args()
    report=finalize(a.out);print(report['overall'])
    for key,r in report['cuts'].items():print(key,r['overall'],r['hpbw_deg'],r['ar_max_through60_db'])
