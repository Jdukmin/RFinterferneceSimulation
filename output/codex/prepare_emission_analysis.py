"""Prepare worker-only inputs; never mutates shared data or source code."""
from pathlib import Path
import csv, hashlib, json, math, subprocess

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent.parent
FREEZE = '8469e8903da83b6ebed014aae311f90855c31715'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()

def write_csv(path, rows):
    with path.open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)

def main():
    assert git('rev-parse', 'HEAD') == FREEZE
    inputs = OUT / 'emission_inputs'; inputs.mkdir(exist_ok=True)
    manifest = []
    for folder in ['src', 'data', 'tests']:
        for p in sorted((ROOT / folder).rglob('*')):
            if p.is_file():
                manifest.append(dict(path=p.relative_to(ROOT).as_posix(), sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
    write_csv(inputs / 'freeze_input_hashes.csv', manifest)
    state = dict(freeze_sha=FREEZE, analysis_head=git('rev-parse', 'HEAD'), branch=git('branch','--show-current'),
                 initial_analysis_worktree_clean=True, initial_analysis_worktree_status='',
                 original_workspace_head=FREEZE, original_workspace_clean=False,
                 original_workspace_status=[' M .gitignore','?? cst/build_spacecraft_ka_model.py','?? docs/guides/','?? output/codex/spacecraft_ka_model/'],
                 isolation='new clean worktree created directly at freeze; start status observed before creating standards directory',
                 other_worker_results_read=False, shared_code_modified=False,
                 antenna_gain_caps_dbi=[0,20,40], gain_caps_class='ENGINEERING_ASSUMPTION; not a guaranteed physical or regulatory EIRP bound')
    (OUT/'freeze_record.json').write_text(json.dumps(state,indent=2)+'\n',encoding='utf-8')
    def data_rows(p):
        return list(csv.DictReader(l for l in p.read_text(encoding='utf-8').splitlines() if not l.startswith('#')))
    B=data_rows(ROOT/'data/rfi_psd/receiver_baseline.csv')
    bands={r['victim_band']:r for r in B if r['victim_band']!='SAR'}
    for name in ['receiver_baseline.csv','filter_scenarios.csv','reference_scenarios.csv']:
        (inputs/name).write_bytes((ROOT/'data/rfi_psd'/name).read_bytes())
    ecss='https://ecss.nl/wp-content/uploads/standards/ecss-e/ECSS-E-ST-50-05C_Rev24October2011.pdf'
    itu='https://www.itu.int/dms_pubrec/itu-r/rec/sm/R-REC-SM.329-13-202409-I!!PDF-E.pdf'
    specs=[]; derivations=[]; domains=[]
    for tx,power,fc,bw in [('S_TM_TX',5,2250e6,2.7e6),('ISL_X_TX',1,10600e6,20e6),('KA_DLS_TX',70,26250e6,1500e6)]:
        pdbm=30+10*math.log10(power)
        for band,b in bands.items():
            lo=float(b['tuning_lo_mhz'])*1e6; hi=float(b['tuning_hi_mhz'])*1e6
            domain='SPURIOUS' if hi<fc-2.5*bw or lo>fc+2.5*bw else 'INBAND_AND_OOB_OVERLAP_NOT_SPURIOUS_WHOLE_BAND'
            domains.append(dict(tx_system=tx,victim_band=band,carrier_hz=fc,necessary_bw_proxy_hz=bw,
                                bw_class='FREEZE_ENGINEERING_PROXY_NOT_NOTIFIED_BN',lower_spurious_boundary_hz=fc-2.5*bw,
                                upper_spurious_boundary_hz=fc+2.5*bw,domain=domain))
            if domain!='SPURIOUS': continue
            for source,atten,url,clause in [('PRIMARY',60 if tx!='ISL_X_TX' else min(43+10*math.log10(power),60),
                   ecss if tx!='ISL_X_TX' else itu,'5.5.1.1 Table 5-6' if tx!='ISL_X_TX' else 'recommends 4.1; 4.2 Table 2 space stations note 3'),
                   ('GENERIC_ITU',min(43+10*math.log10(power),60),itu,'recommends 4.1; 4.2 Table 2 space stations note 3')]:
                if source=='GENERIC_ITU' and tx=='ISL_X_TX':continue
                absolute=pdbm-atten; density=absolute-10*math.log10(4000)
                for kind in ['BROADBAND_PSD','DISCRETE_SPUR']:
                    specs.append(dict(tx_system=tx,victim_band=band,frequency_hz='',frequency_lo_hz=lo,frequency_hi_hz=hi,
                        emission_type=kind,level=absolute,unit='dBm',reference_bandwidth_hz=4000,reference_plane='ANTENNA_PORT',
                        carrier_frequency_hz=fc,filter_state='FILTER_0DB_NO_ADDITIONAL_EXTERNAL_FILTER',
                        standard_or_source='ECSS-E-ST-50-05C Rev2 2011-10-04' if url==ecss else 'ITU-R SM.329-13 2024-09',
                        provenance=url,assumption_class='REGULATORY_LIMIT',exact_clause=clause,source_set=source,
                        power_w=power,attenuation_db=atten,domain=domain,
                        spectral_interpretation='4kHz band-average envelope; flat broadband-equivalent only; not pointwise guarantee' if kind=='BROADBAND_PSD' else 'total single tone power; unknown tone frequency within band; NEVER convert to PSD',
                        measurement_bandwidth_hz=4000,measurement_bw_condition='analysis adopts reference BW; actual measurement RBW/ENBW may differ with correction',
                        detector_condition='mean-power domain; no universal peak detector mandated; ECSS table has no detector prescription',
                        normative_status='industrial standard adopted for screening; contract adoption not established' if url==ecss else 'space station design limit; national authorization not established'))
                derivations.append(dict(tx_system=tx,victim_band=band,source_set=source,power_w=power,power_dbm=pdbm,
                    attenuation_db=atten,band_power_dbm=absolute,rbw_hz=4000,broadband_equivalent_dbm_hz=density,
                    discrete_spur_power_dbm=absolute,derivation='P_dBm - attenuation - 10log10(4000) for flat broadband ONLY'))
                # Conditional radiated route: add explicit gain ceiling, never reuse 26 GHz pattern.
                if source=='PRIMARY' and (tx=='KA_DLS_TX' or band in ['L2','L5'] and tx=='S_TM_TX'):
                    broadband_row=dict(specs[-2])
                    for cap in [0,20,40]:
                        r=dict(broadband_row);r.update(level=absolute+cap,reference_plane='RADIATED_EIRP_PSD',
                          source_set=f'GAIN_CAP_{cap}',assumption_class='ENGINEERING_ASSUMPTION',
                          spectral_interpretation=f'conditional EIRP envelope assuming victim-band realized gain <= {cap} dBi; NOT regulatory radiated bound',
                          provenance=url+'; conducted limit plus explicit worker gain cap; no KAA low-band pattern assumed available')
                        specs.append(r)
    write_csv(inputs/'tx_emission_masks.csv',specs); write_csv(OUT/'source_derivation.csv',derivations);write_csv(OUT/'domain_classification.csv',domains)
    # Reuse only this worker's freeze-point cut-reader helpers, not another worker's analysis driver.
    old=(OUT/'run_rfi_octave.m').read_text(encoding='utf-8')
    helper=old[old.index('function f=family(id)'):old.index('function [portW,inW')]
    helper=helper.replace("if isempty(list); return; end", "if isempty(list); return; end\n  if any(~[list.normalization_reliable]); source='NORMALIZATION_UNRELIABLE'; return; end")
    writer=old[old.index('function writecells('):]
    base=(OUT/'emission_driver_body.m').read_text(encoding='utf-8')
    (OUT/'run_emission_analysis.m').write_text(base+'\n'+helper+'\n'+writer,encoding='utf-8')
    print('Prepared independent source table, domains, freeze manifest, unchanged-engine driver')

if __name__=='__main__':main()
