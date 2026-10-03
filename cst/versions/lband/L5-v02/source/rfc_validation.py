"""RFC acceptance and conservative scalar export; raw EM fields stay separate."""
import csv,json
from pathlib import Path
import numpy as np

def source_reference_metrics(theta,gain,reference,coverage=90,anchors=None,lower=None,upper=None):
    """Only explicitly provenance-qualified anchors are hard guards.

    Envelope distance is zero inside supplied source min/max bounds. A lone
    screening upper envelope cannot establish an unavailable lower bound.
    """
    t=np.asarray(theta);g=np.asarray(gain);r=np.asarray(reference)
    mask=np.minimum(t,360-t)<=coverage
    if (lower is None)!=(upper is None):
        raise ValueError('Both source envelope bounds are required')
    if lower is None:
        distance=np.abs(g-r);kind='SCREENING_REFERENCE_DEVIATION'
    else:
        lo=np.asarray(lower);hi=np.asarray(upper)
        if np.any(lo>hi):raise ValueError('Inverted source envelope')
        distance=np.maximum(np.maximum(lo-g,g-hi),0);kind='SOURCE_ENVELOPE_DISTANCE'
    guards={}
    for anchor in anchors or []:
        if anchor['provenance'] not in ('PUBLIC_DATASHEET','PUBLIC_PAPER'):
            continue
        if anchor.get('interpolated',False) or anchor.get('assumed',False):continue
        i=np.argmin(abs(t-anchor['theta_deg']))
        limit=anchor.get('limit_db',2.0)
        guards[str(anchor['theta_deg'])]={'error_db':float(distance[i]),'limit_db':limit,
                                         'pass':bool(distance[i]<=limit)}
    mae=float(np.mean(distance[mask]))
    return {'comparison':kind,'main_mae_db':mae,'main_mae_pass':mae<=1.5,
            'source_anchor_guards':guards,'source_anchors_verified':bool(guards),
            'anchor_pass':all(x['pass'] for x in guards.values()) if guards else None}

def metrics(theta,gain,reference,coverage=90):
    t=np.asarray(theta);g=np.asarray(gain);r=np.asarray(reference)
    mask=np.minimum(t,360-t)<=coverage;error=g-r
    anchors=[0,30,60,80,90]
    return {'coverage_deg':coverage,'main_mae_db':float(np.mean(abs(error[mask]))),
        'main_max_error_db':float(np.max(abs(error[mask]))),
        'main_rmse_db':float(np.sqrt(np.mean(error[mask]**2))),
        'peak_error_db':float(abs(g.max()-r.max())),
        'anchor_errors_db':{str(a):float(error[np.argmin(abs(t-a))]) for a in anchors},
        'eoc_gain_error_db':float(error[np.argmin(abs(t-coverage))]),
        'boresight_error_db':float(error[np.argmin(abs(t))])}

def sband_pass(m,active_rl,cp_verified=False,mesh_verified=False,frequency_verified=False,
               eoc_angle_verified=False,rolloff_verified=False,axis_verified=False,
               conservative_regions_verified=False,gain_basis='REALIZED_GAIN'):
    if gain_basis not in ('REALIZED_GAIN','ACCEPTED_POWER_GAIN'):
        raise ValueError('Explicit supported gain basis required')
    matching_required=gain_basis=='REALIZED_GAIN'
    checks={'peak':m['peak_error_db']<=1,'main_mae':m['main_mae_db']<=1.5,
        'main_max':m['main_max_error_db']<=2.5,
        'anchors':max(map(abs,m['anchor_errors_db'].values()))<=2,
        'eoc_gain':abs(m['eoc_gain_error_db'])<=1.5,
        'active_match':active_rl>10 if matching_required else True,'polarization':bool(cp_verified),
        'mesh_convergence':bool(mesh_verified),'frequency_robustness':bool(frequency_verified),
        'eoc_angle':bool(eoc_angle_verified),'rolloff_trend':bool(rolloff_verified),
        'coverage_axis':bool(axis_verified),'conservative_unknown_regions':bool(conservative_regions_verified)}
    return {'checks':checks,'gain_basis':gain_basis,
            'matching_required':matching_required,'active_return_loss_db':float(active_rl),
            'matching_role':'HARD_GATE' if matching_required else 'DIAGNOSTIC_ONLY',
            'overall':'PASS' if all(checks.values()) else 'FAIL'}

def export_screening(rows,path,coverage=90,main_valid=False):
    """Export 1-degree scalar gain; never advertise envelope as EM truth."""
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    exported=[];regions=[]
    for row in rows:
        theta=int(float(row['theta']));g=float(row['gain']);ref=float(row['target_gain'])
        main=min(theta,360-theta)<=coverage
        region='VALIDATED_MAIN' if main and main_valid else ('UNKNOWN' if main else ('BACKLOBE' if 90<theta<270 else 'UNVALIDATED_SIDELOBE'))
        output=g if region=='VALIDATED_MAIN' else max(g,ref)
        exported.append({'theta':theta,'gain':output})
        regions.append({'theta':theta,'region':region,'raw_cst_gain':g,'conservative_reference':ref,'export_gain':output})
    with path.open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['theta','gain']);w.writeheader();w.writerows(exported)
    path.with_suffix('.regions.json').write_text(json.dumps({'model_status':'RFC_PASS' if main_valid else 'PROVISIONAL_NOT_RFC_VALIDATED',
        'provenance':'SURROGATE + CONSERVATIVE_ENVELOPE','complex_field':False,'regions':regions},indent=2))
    return exported

def reevaluate(out):
    out=Path(out);report={}
    summary=json.loads((out/'summary.json').read_text())
    for key,r in summary.items():
        basekey=key.split('_f')[0]
        folder=out if '_f' not in key else out/f"f_{r['frequency_ghz']:g}"
        with (folder/f'{basekey}.csv').open() as f:rows=list(csv.DictReader(f))
        # Hold one circular sense across the cut, selected at boresight; do not
        # select a different hand at each angle to mask cross-polarization.
        sense='cp_plus_db' if float(rows[0]['cp_plus_db'])>=float(rows[0]['cp_minus_db']) else 'cp_minus_db'
        for row in rows:row['total_realized_gain']=row['gain'];row['gain']=row[sense]
        m=metrics([float(x['theta']) for x in rows],[float(x['gain']) for x in rows],[float(x['target_gain']) for x in rows])
        validity=sband_pass(m,r['active_return_loss_db'])
        report[key]={'metrics':m,'circular_sense':sense,'handedness':'UNVERIFIED',**validity}
        export_screening(rows,out/'screening_export'/f'{key}.csv',main_valid=False)
    (out/'rfc_validation.json').write_text(json.dumps(report,indent=2))
    return report

if __name__=='__main__':
    import argparse
    a=argparse.ArgumentParser();a.add_argument('out');args=a.parse_args()
    for k,v in reevaluate(args.out).items():print(k,v['overall'],round(v['metrics']['main_mae_db'],3))
