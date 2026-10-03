"""Separate accepted-power CP radiation error from active matching loss."""
import csv,json
from pathlib import Path
import numpy as np
from rfc_validation import metrics,source_reference_metrics

def frequency_validation(out):
    """Fixed intended LHCP at all frequencies; matching remains diagnostic."""
    out=Path(out);data=np.load(out/'s_matrix.npz');report={}
    summary=json.loads((out/'summary.json').read_text())
    for key,item in summary.items():
        frequency=item['frequency_ghz'];base=key.split('_f')[0]
        folder=out if '_f' not in key else out/f'f_{frequency:g}'
        with (folder/f'{base}.csv').open() as stream:rows=list(csv.DictReader(stream))
        idx=np.argmin(abs(data['frequency_ghz']-frequency))
        accepted=1-float(np.mean(abs(data['active_gamma'][idx])**2))
        if accepted<=0:raise ValueError('Nonpositive accepted power')
        correction=-10*np.log10(accepted)
        theta=np.array([float(r['theta']) for r in rows])
        gain=np.array([float(r['cp_minus_db']) for r in rows])+correction
        reference=np.array([float(r['target_gain']) for r in rows])
        mask=np.minimum(theta,360-theta)<=90
        error=max(0,float(np.linalg.svd(data['s'][idx],compute_uv=False).max())**2-1)
        report[key]={'frequency_ghz':frequency,'gain_basis':'ACCEPTED_POWER_GAIN',
            'intended_hand':'IEEE_LHCP','active_return_loss_db':item['active_return_loss_db'],
            'matching_role':'DIAGNOSTIC_ONLY','accepted_power_fraction':accepted,
            'normalization_reliable':accepted>5*error,
            'metrics':metrics(theta,gain,reference),
            'source_comparison':source_reference_metrics(theta,gain,reference),
            'coverage_axial_ratio_max_db':float(max(float(r['axial_ratio_db']) for r,m in zip(rows,mask) if m)),
            'status':'PRE_FINAL_MESH_AND_SOURCE_GUARDS_PENDING'}
    (out/'accepted_power_frequency_validation.json').write_text(json.dumps(report,indent=2))
    return report

def evaluate(out):
    out=Path(out);data=np.load(out/'s_matrix.npz');f=data['frequency_ghz'];gamma=data['active_gamma']
    report={}
    for path in sorted(out.glob('SBA[14]_??_?Z.csv')):
        frequency=2.06 if '_TC_' in path.name else 2.25
        idx=np.argmin(abs(f-frequency));accepted=1-float(np.mean(abs(gamma[idx])**2))
        if accepted<=0:raise ValueError('Nonpositive accepted power')
        correction=-10*np.log10(accepted)
        with path.open() as stream:rows=list(csv.DictReader(stream))
        sense='cp_plus_db' if float(rows[0]['cp_plus_db'])>=float(rows[0]['cp_minus_db']) else 'cp_minus_db'
        cp=np.array([float(r[sense]) for r in rows])+correction
        m=metrics([float(r['theta']) for r in rows],cp,[float(r['target_gain']) for r in rows])
        passivity_error=max(0,float(np.linalg.svd(data['s'][idx],compute_uv=False).max())**2-1)
        reliable=accepted>5*passivity_error
        report[path.stem]={'accepted_power_fraction':accepted,'matching_loss_db':float(correction),
            'passivity_power_error':passivity_error,'normalization_reliable':reliable,
            'handedness':'IEEE_RHCP' if sense=='cp_plus_db' else 'IEEE_LHCP',
            'metrics_accepted_power_cp':m,
            'radiation_score':m['main_mae_db']+0.5*m['peak_error_db'],
            'status':'RADIATION_ONLY_NOT_RFC_PASS' if reliable else 'INCONCLUSIVE_ACCEPTED_POWER_BELOW_NUMERICAL_ERROR_MARGIN'}
    (out/'radiation_only.json').write_text(json.dumps(report,indent=2))
    return report

if __name__=='__main__':
    import argparse
    a=argparse.ArgumentParser();a.add_argument('out');args=a.parse_args()
    for k,v in evaluate(args.out).items():
        if k.startswith('SBA1'):print(k,round(v['metrics_accepted_power_cp']['main_mae_db'],3),round(v['metrics_accepted_power_cp']['peak_error_db'],3))
