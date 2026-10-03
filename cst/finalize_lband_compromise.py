"""User-directed common-geometry compromise, with honest band fit diagnostics."""
import csv,json,re
from pathlib import Path
import numpy as np
from rfc_validation import export_screening
from finalize_lband_band import finalize
ROOT=Path(__file__).resolve().parent

def main():
    source=ROOT/'results/LBAND_GNSS_V05_BANDCHECK';validation=json.loads((source/'validation.json').read_text())
    strict=finalize(source);out=ROOT/'exports/lband';out.mkdir(parents=True,exist_ok=True)
    bands=[(1.17645,'L5_1176MHz'),(1.207,'L2_proxy_1207MHz'),(1.57542,'L1_1575MHz')]
    report={'decision':'USER_DIRECTED_ACCEPTED_COMMON_GEOMETRY_COMPROMISE',
            'strict_all_band_em_fit':'NOT_PASS','gain_basis':'ACCEPTED_POWER_RHCP_GAIN',
            'geometry_project':'cst/projects/LBAND_GNSS_FINAL_COMPROMISE.cst',
            'geometry_parameters':json.loads((ROOT/'projects/LBAND_GNSS_FINAL_COMPROMISE.geometry.json').read_text())['parameters'],
            'matching':'DIAGNOSTIC_ONLY','mesh_validation':'DISABLED_BY_USER','bands':{}}
    scores=[]
    for frequency,band in bands:
        for plane in ['XZ','YZ']:
            key=f'f{frequency:g}_{plane}';v=validation[key]
            with (source/f'accepted_power_{key}.csv').open() as stream:rows=list(csv.DictReader(stream))
            valid=strict['cuts'][key]['overall']=='PASS'
            dest=out/f'Extended_GNSS_PEC_{band}_{plane}.csv'
            export_screening(rows,dest,main_valid=valid)
            metadata=dest.with_suffix('.regions.json');regions=json.loads(metadata.read_text())
            regions['model_status']='USER_ACCEPTED_RFC_SCREENING_COMPROMISE'
            regions['strict_raw_band_fit']=strict['cuts'][key]['overall']
            regions['source_reference_status']='Approximate upper-envelope screening data, not numeric EM truth'
            metadata.write_text(json.dumps(regions,indent=2))
            exported=list(csv.DictReader(dest.open()))
            conservative=all(float(e['gain'])>=float(r['target_gain']) for e,r in zip(exported,rows)) if not valid else True
            assert len(exported)==360 and [int(r['theta']) for r in exported]==list(range(360))
            assert conservative
            report['bands'][key]={'reference_band':band,'raw_metrics':v['metrics'],
                'strict_checks':strict['cuts'][key]['checks'],
                'hpbw_deg':strict['cuts'][key]['hpbw_deg'],
                'ar_through60_db':strict['cuts'][key]['ar_max_through60_db'],
                'active_return_loss_db':v['active_return_loss_db'],
                'screening_treatment':'CST accepted-power CP in validated main; conservative max outside' if valid else 'Entire uncertain cut uses max(CST accepted-power CP, screening reference)',
                'export':str(dest.relative_to(ROOT.parent))}
            scores.append(v['metrics']['main_mae_db'])
    report['pooled_nominal_coverage_mae_db']=float(np.mean(scores))
    # Subset a native source without changing a single complex field sample.
    native=out/'lband_common_compromise.ffs';text=native.read_text()
    marker='// >> Total #phi samples, total #theta samples'
    blocks=text.split(marker);assert len(blocks)==8
    before,power=blocks[0].split('// Radiated/Accepted/Stimulated Power , Frequency',1)
    values=[float(x) for x in power.split()];assert len(values)==28
    powers=np.array(values).reshape(7,4);indices=[1,3,5]
    assert np.allclose(powers[indices,3],[x[0]*1e9 for x in bands])
    before=re.sub(r'(// #Frequencies\s*)7',r'\g<1>3',before)
    selected=before+'// Radiated/Accepted/Stimulated Power , Frequency\n'
    for index in indices:selected+='\n'.join(f'{v:.9e}' for v in powers[index])+'\n\n'
    selected+=''.join(marker+blocks[index+1] for index in indices)
    (out/'lband_nominal_sources.ffs').write_text(selected)
    report['complex_source']={'file':'cst/exports/lband/lband_nominal_sources.ffs',
        'native_source':'cst/exports/lband/lband_common_compromise.ffs','frequency_count':3,
        'angular_sampling_deg':5,'sample_grid_per_frequency':[73,37],
        'field_samples_unchanged':True,'conservative_envelope_applied_to_complex_fields':False,
        'normalization':'Retain native radiated/accepted/stimulated powers; use accepted or radiated power at import, not conducted-power transfer.',
        'installed_axis_rotation_CST_to_repository':[[0,0,1],[1,0,0],[0,1,0]],
        'limitation':'Raw installed-source model retains L1 coverage uncertainty. Conservative scalar screening exports remain the RFC bound; do not treat the raw source as product truth.'}
    (out/'lband_compromise_validation.json').write_text(json.dumps(report,indent=2))
    print(report['decision'],report['pooled_nominal_coverage_mae_db'])

if __name__=='__main__':main()
