"""Evaluate fixed ISL geometry at the owner-updated operating band."""
import json
from pathlib import Path
import numpy as np
from cst_com import ROOT, save
from cst_com_common import connect_cst, method
import verify_isl_results as verifier

def main():
    project=ROOT/'projects/ISL_FIXED_10G6.cst'
    out=ROOT/'results/ISL_FIXED_10G6'
    app=connect_cst(False)
    p=method(app,'OpenFile',str(project))
    if p is None:
        p=method(app,'Active3D')
    verifier.FREQS=[10.4,10.55,10.6,10.65]
    report=verifier.verify(p,out,project)
    verifier.export(out,report['status']=='ISL_ASSUMED_TEMPLATE_PASS')
    baseline=json.loads((ROOT/'results/ISL_C4_CUP_R14P7/validation.json').read_text())
    comparisons={}
    for freq in verifier.FREQS:
        for plane in ['XZ','YZ']:
            key=f'f{freq:g}_{plane}'
            current=report['cuts'][key]
            old=baseline['cuts'][f'f10.4_{plane}']
            comparisons[key]={k:current[k]-old[k] for k in
                ['peak_dbi','boresight_dbi','hpbw_deg','active_return_loss_min_db']}
            import csv
            def gain(path):
                with path.open() as stream:
                    return np.array([float(row['gain']) for row in csv.DictReader(stream)])
            delta=gain(out/f'accepted_power_f{freq:g}_{plane}.csv')-gain(
                ROOT/f'results/ISL_C4_CUP_R14P7/accepted_power_f10.4_{plane}.csv')
            mask=np.minimum(np.arange(360),360-np.arange(360))<=60
            comparisons[key].update(coverage_rms_difference_db=float(np.sqrt(np.mean(delta[mask]**2))),
                coverage_max_abs_difference_db=float(np.max(abs(delta[mask]))))
    (out/'frequency_change_comparison.json').write_text(json.dumps({
        'geometry_changed':False,'operating_band_ghz':[10.55,10.65],
        'baseline_frequency_ghz':10.4,'comparisons':comparisons},indent=2))
    save(p,project)
    print(json.dumps({'solver':report['solver'],'status':report['status'],
        'comparisons':comparisons},indent=2),flush=True)

if __name__=='__main__':main()
