"""ITU design supplement from independent Codex freeze coupling, with honest conditional bounds."""
from pathlib import Path
import csv, json, math, hashlib, re
from collections import defaultdict
OUT=Path(__file__).resolve().parent; ROOT=OUT.parent.parent
SCENARIOS=[0,40,60,70,80]
ROLE={'S_TM_TX':'S-TC TX','S_TC_RX':'S-TM RX','ISL_X_TX':'ISL TX','ISL_X_RX':'ISL RX','KA_DLS_TX':'Ka DLS TX','SAR_X_RX':'SAR RX'}
BAND={'S_TC':'S (2025–2110 MHz)','L1':'L1','L2':'L2','L5':'L5','ISL':'X (10.55–10.65 GHz)','SAR':'SAR X'}
NIST='https://nvlpubs.nist.gov/nistpubs/jres/64D/jresv64Dn1p1_A1b.pdf'
ITU='https://www.itu.int/dms_pubrec/itu-r/rec/sm/R-REC-SM.329-13-202409-I!!PDF-E.pdf'
RR='https://search.itu.int/history/HistoryDigitalCollectionDocLibrary/1.49.48.en.102.pdf'
def read(p):return list(csv.DictReader(l for l in (OUT/p).read_text(encoding='utf-8-sig').splitlines() if not l.startswith('#')))
def read_data(p):return list(csv.DictReader(l for l in (ROOT/p).read_text(encoding='utf-8').splitlines() if not l.startswith('#')))
def write(p,rows):
    with (OUT/p).open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def actual(id):
    t,*loc=id.split('@');v=ROLE.get(t,t.replace('_RX',' RX').replace('_',' '))
    return v+(' @ '+loc[0] if loc else '')
def fnum(x):return float(x)
def fmt(x):return f'{float(x):.2f}' if str(x) not in ['UNKNOWN','nan','NaN',''] and math.isfinite(float(x)) else '미판정'
def first(s):return next((f'FILTER_{a}DB' for a in SCENARIOS if a+1e-9>=s),'ABOVE_80DB_SEPARATE_DESIGN')
def cls(s):return next((f'{a} dB class' for a in SCENARIOS if a+1e-9>=s),'80 dB 초과 / 별도 설계')
def passdesc(s):return next((f'{a} dB' for a in SCENARIOS if a+1e-9>=s),'없음 (80 dB 초과)')
def confidence_text(r):return '시뮬레이션' if r['confidence']=='SIMULATED' else 'Engineering bound — L1 기준 10 dB mismatch' if r['model_fidelity']=='PORT_MISMATCH_RESCALED_LBAND' else '조건부 bound; primary 보류' if 'BOUNDED' in r['confidence'] else 'Primary 미판정'
def target(s):return math.ceil((s+10)/10)*10
def tab(head,rows):return '\n| '+' | '.join(head)+' |\n| '+' | '.join(['---']*len(head))+' |\n'+''.join('| '+' | '.join(map(str,r))+' |\n' for r in rows)+'\n'
def gain_bound(f,diam):
    # Conditional source extent <= D in EACH Cartesian dimension, not D/2 enclosing-sphere shortcut.
    a=math.sqrt(3)*diam/2;ka=2*math.pi*f*a/299792458
    n=max(1,math.ceil(ka));g=10*math.log10(n*n+2*n)
    return g,a,n
def main():
    for r in read('emission_inputs/freeze_input_hashes.csv'):
        assert hashlib.sha256((ROOT/r['path']).read_bytes()).hexdigest()==r['sha256'],r['path']
    groups=defaultdict(list)
    for r in read('victim_band_coupling.csv'):groups[(r['case_id'],r['tx_id'],r['rx_id'],r['victim_band'])].append(r)
    B={r['victim_band']:r for r in read_data('data/rfi_psd/receiver_baseline.csv')}
    dimensions={r['function_id']:float(r['max_dimension_m']) for r in read_data('data/spacecraft/simplified_spacecraft_v1/antenna_functions.csv') if r['max_dimension_m']}
    diameters={'S_TM_TX':dimensions['SBA_NADIR_TM'],'KA_DLS_TX':dimensions['KAA_1']}
    policy=json.loads((OUT/'emission_inputs/owner_port_mismatch_policy.json').read_text(encoding='utf-8'))
    assert policy['port_mismatch_rescaling_db']==-10 and policy['applied_victim_bands']==['L2','L5']
    powers={'S_TM_TX':5,'ISL_X_TX':1,'KA_DLS_TX':70}
    sources=[]
    for tx,power in powers.items():
        att=min(43+10*math.log10(power),60);pdbm=30+10*math.log10(power);p4=pdbm-att;psd=p4-10*math.log10(4000)
        for band,b in B.items():
            if band=='ISL' and tx=='ISL_X_TX':continue
            sources.append(dict(tx_system=tx,actual_role=ROLE[tx],victim_band=band,source_power_w=power,
                frequency_lo_hz=float(b['tuning_lo_mhz'])*1e6,frequency_hi_hz=float(b['tuning_hi_mhz'])*1e6,
                carrier_frequency_hz={'S_TM_TX':2.25e9,'ISL_X_TX':10.6e9,'KA_DLS_TX':26.25e9}[tx],
                attenuation_dbc=att,emission_domain='SPURIOUS',assumption_class='REGULATORY_LIMIT',filter_state='FILTER_0DB',
                conducted_limit_dbm_per_4khz=p4,itu_source_psd_dbm_hz=psd,reference_bandwidth_hz=4000,
                source_reference_plane='ANTENNA_PORT',standard='RR2024 AP3 TableI; SM329-13 4.1/4.2 Table2 space stations',
                provenance=ITU+'; '+RR,emission_type='BROADBAND_EQUIVALENT_ONLY_NOT_DISCRETE_SPUR'))
    source_map={(s['tx_system'],s['victim_band']):s for s in sources}
    results=[];bounds=[];scenarios=[]
    def emit(key,rows,confidence,missing='',bound=False,owner_rescaled=False):
        case,tx,rx,band=key;template=tx.split('@')[0];source=source_map[(template,band)];b=B[band]
        limit=-174+float(b['nf_db'])+float(b['i_n_max_db']);psd=source['itu_source_psd_dbm_hz']
        rescale=policy['port_mismatch_rescaling_db'] if owner_rescaled else 0.0
        effective_source=psd+rescale
        peak=None;g=math.nan;a=math.nan;n=math.nan;ff=math.nan
        if rows and not missing:
            evaluated=[]
            for row in rows:
                freq=float(row['frequency_hz'])
                if bound or owner_rescaled:
                    g0,a0,n0=gain_bound(freq,diameters[template])
                    g0+=rescale
                    transfer=float(row['radiated_transfer_db']);coupling=transfer+g0
                else:
                    g0=float(row['tx_gain_dbi']);a0=n0=math.nan;coupling=float(row['conducted_coupling_db'])
                evaluated.append((psd+coupling,row,g0,a0,n0,coupling))
            peak=max(evaluated,key=lambda x:x[0]);g,a,n=peak[2:5]
        port=peak[0] if peak else math.nan;coupling=peak[5] if peak else math.nan;margin=limit-port;need=max(0,-margin) if peak else math.nan
        if peak and (bound or owner_rescaled):ff=2*(2*a)**2*float(peak[1]['frequency_hz'])/299792458
        evaluation='CONDITIONAL_BOUND' if bound else 'OWNER_ENGINEERING_PRIMARY' if owner_rescaled else 'ITU_PRIMARY'
        r=dict(case_id=case,tx_id=tx,rx_id=rx,actual_attacker=actual(tx),actual_victim=actual(rx),victim_band=band,actual_victim_band=BAND[band],
          itu_unwanted_source_psd_dbm_hz=psd,source_reference_plane='ANTENNA_PORT',
          port_mismatch_rescaling_db=rescale,effective_tx_lband_source_dbm_hz=effective_source,
          effective_source_reference_plane=policy['effective_source_reference_plane'] if owner_rescaled else 'ANTENNA_PORT',
          tx_radiation_model_gain_dbi=g-rescale if peak else math.nan,
          mismatch_provenance_class=policy['provenance_class'] if owner_rescaled else 'NOT_SEPARATELY_APPLIED',
          mismatch_provenance=policy['provenance'] if owner_rescaled else 'L1 mismatch already included in validated CST RealizedGain' if template=='S_TM_TX' and band=='L1' else '',
          tx_victim_gain_dbi=g,derived_eirp_psd_dbm_hz=psd+g if peak else math.nan,coupling_db=coupling,
          psd_victim_0db_dbm_hz=port,allowable_psd_dbm_hz=limit,margin_0db_db=margin,
          required_additional_suppression_db=need,first_passing_scenario=first(need) if peak else 'UNKNOWN',
          screening_design_class=cls(need) if peak else 'PRIMARY UNKNOWN',recommended_design_target_db=target(need) if peak else math.nan,
          confidence=confidence,evaluation=evaluation,model_fidelity=policy['result_route'] if owner_rescaled else 'CONDITIONAL_MODAL_GAIN_ENVELOPE_FREE_SPACE' if bound else 'FREE_SPACE_SIMULATED_2D_CUTS' if peak else 'PRIMARY_UNKNOWN',
          missing_reason=missing,worst_frequency_hz=float(peak[1]['frequency_hz']) if peak else math.nan,
          enclosing_radius_m=a,modal_order_n=n,distance_m=float(peak[1]['distance_m']) if peak else math.nan,
          bound_tx_far_field_screen_distance_m=ff,
          bound_tx_far_field_screen='OUTSIDE_2D2_OVER_LAMBDA' if peak and (bound or owner_rescaled) and float(peak[1]['distance_m'])>=ff else 'NEAR_FIELD_CONDITIONAL_ONLY' if peak and (bound or owner_rescaled) else 'NOT_BOUND_ROUTE',
          source_provenance=ITU,bound_provenance=NIST+' Sec2 Eq(19); finite spherical modes n<=N; normal-mode cutoff chosen by worker' if bound or owner_rescaled else '')
        (bounds if bound else results).append(r)
        for atten in SCENARIOS:
            m=margin+atten;status='UNKNOWN' if not peak else ('PASS' if m>=0 else 'FAIL')
            scenarios.append(dict(case_id=case,tx_id=tx,rx_id=rx,actual_attacker=actual(tx),actual_victim=actual(rx),victim_band=band,
              evaluation=evaluation,filter_db=atten,victim_psd_dbm_hz=port-atten,
              margin_db=m,required_additional_suppression_db=need,first_passing_scenario=r['first_passing_scenario'],status=status,confidence=confidence))
    for key,rows in groups.items():
        case,tx,rx,band=key;t=tx.split('@')[0]
        valid=all(math.isfinite(float(r['conducted_coupling_db'])) for r in rows)
        missing='' if valid else ('S_L2_L5_NORMALIZATION_UNRELIABLE' if t=='S_TM_TX' and band in ['L2','L5'] else 'KAA_VICTIM_BAND_RADIATION_RESPONSE_MISSING')
        rescaled=t=='S_TM_TX' and band in policy['applied_victim_bands']
        if rescaled:
            assert not valid and all(math.isfinite(float(r['radiated_transfer_db'])) for r in rows)
            emit(key,rows,policy['confidence'],owner_rescaled=True)
        else:emit(key,rows,'SIMULATED' if valid else 'PRIMARY UNKNOWN',missing)
        if not valid and all(math.isfinite(float(r['radiated_transfer_db'])) for r in rows):
            emit(key,rows,'BOUNDED CONDITIONAL: enclosing-current-volume and finite-modal-cutoff assumptions',bound=True)
    # Retain missing same-port and SAR paths, rather than silently dropping them.
    for r in read('emission_exclusions.csv'):
        tx=r['tx_id'];rx=r['rx_id'];t=tx.split('@')[0]
        if t=='ISL_X_TX':continue # ISL self-path is not an unwanted-spurious domain pair.
        emit((r['case_id'],tx,rx,'S_TC'),[],'PRIMARY UNKNOWN','SAME_PORT_TRANSFER_MISSING; independent TX spectral requirement remains')
    # SAR response/antenna is unbound in freeze. Source and criterion remain explicit.
    for case in sorted({k[0] for k in groups}):
        for tx in ['S_TM_TX@SBA_NADIR','S_TM_TX@SBA_ZENITH','KA_DLS_TX@KAA_1','KA_DLS_TX@KAA_2']:
            emit((case,tx,'SAR_X_RX@SAR_ANT','SAR'),[],'PRIMARY UNKNOWN','SAR_VICTIM_ANTENNA_RESPONSE_MISSING; no justified RX gain bound (dimensions absent)')
    write('all_pair_required_suppression.csv',results);write('conditional_bound_required_suppression.csv',bounds);write('design_filter_scenarios.csv',scenarios);write('itu_design_source_table.csv',sources)
    # Legacy schemas are preserved; append physical names to old tables and archived report.
    for name in ['victim_band_scenarios.csv','victim_band_coupling.csv','pair_filter_requirements.csv','discrete_spur_results.csv','emission_exclusions.csv',
                 'rfi_pairs.csv','case_summary.csv','frequency_direction_evidence.csv','receiver_aggregates.csv','excluded_same_installation.csv','sar_response_sensitivity.csv']:
        rows=read(name)
        for row in rows:
            for k in ['tx_id','rx_id','strongest_evaluated_tx','strongest_evaluated_rx']:
                if k in row:row[k+'_actual_role']=actual(row[k])
        write(name,rows)
    rows=read('band_summary.csv')
    for row in rows:row['actual_attacker_role']={'S_TM':'S-TC TX','ISL':'ISL TX','KA':'Ka DLS TX'}[row['tx_band']]
    write('band_summary.csv',rows)
    rows=read('emission_inputs/receiver_baseline.csv')
    for row in rows:row['actual_receiver_role']=actual(row['receiver'])
    write('emission_inputs/receiver_baseline.csv',rows)
    rows=read('case_pattern_evidence.csv')
    for row in rows:
        fid=row['function_id']
        row['actual_function_role']='S-TC TX' if fid.startswith('SBA_') and fid.endswith('_TM') else 'S-TM RX' if fid.startswith('SBA_') and fid.endswith('_TC') else row['role']
    write('case_pattern_evidence.csv',rows)
    for name in ['tx_filter_design_summary.csv','source_derivation.csv','domain_classification.csv','emission_inputs/tx_emission_masks.csv']:
        rows=read(name)
        for row in rows:row['actual_tx_role']=ROLE[row['tx_system']]
        write(name,rows)
    # Regression: ITU values use identical independently evaluated coupling to prior GENERIC_ITU set.
    old=read('victim_band_scenarios.csv')
    oldmap={(r['case_id'],r['tx_id'],r['rx_id']):r for r in old if r['filter_db']=='0' and (r['source_set']=='GENERIC_ITU' if r['tx_system']=='S_TM_TX' else r['source_set']=='PRIMARY')}
    for r in results:
        if r['model_fidelity']=='FREE_SPACE_SIMULATED_2D_CUTS':
            o=oldmap[(r['case_id'],r['tx_id'],r['rx_id'])];assert abs(r['required_additional_suppression_db']-float(o['minimum_required_additional_suppression_db']))<1e-7
    for r in results+bounds:
        if math.isfinite(r['psd_victim_0db_dbm_hz']):
            assert abs(r['psd_victim_0db_dbm_hz']-(r['itu_unwanted_source_psd_dbm_hz']+r['coupling_db']))<1e-10
            assert r['required_additional_suppression_db']==max(0,-r['margin_0db_db'])
    for r in scenarios:
        if r['status']!='UNKNOWN':
            assert r['status']==('PASS' if r['margin_db']>=0 else 'FAIL')
            assert abs(r['required_additional_suppression_db']-max(0,-(r['margin_db']-r['filter_db'])))<1e-10
    for r in results+bounds:
        if math.isfinite(r['required_additional_suppression_db']):
            passing=[s['filter_db'] for s in scenarios if (s['case_id'],s['tx_id'],s['rx_id'],s['evaluation'])==(r['case_id'],r['tx_id'],r['rx_id'],r['evaluation']) and s['status']=='PASS']
            assert r['first_passing_scenario']==(f'FILTER_{min(passing)}DB' if passing else 'ABOVE_80DB_SEPARATE_DESIGN')
    assert len({(r['case_id'],r['tx_id'],r['rx_id'],r['victim_band']) for r in results})==len(results)
    assert len(scenarios)==5*(len(results)+len(bounds))
    for r in results+bounds:assert r['actual_attacker']==actual(r['tx_id']) and r['actual_victim']==actual(r['rx_id'])
    regress={}
    for band,expect in [('L1',48),('S_TC',58.8865359066),('ISL',39.247)]:
        rr=[r for r in results if r['tx_id'].startswith('S_TM_TX') and r['victim_band']==band and math.isfinite(r['required_additional_suppression_db'])]
        value=max(r['required_additional_suppression_db'] for r in rr);regress[band]=value;assert abs(value-expect)<.1
    summary=[];chosen=[]
    for tx in powers:
        for band in ['L1','L2','L5','S_TC','ISL','SAR']:
            if tx=='ISL_X_TX' and band in ['ISL','SAR']:continue
            rr=[r for r in results if r['tx_id'].split('@')[0]==tx and r['victim_band']==band]
            ff=[r for r in rr if math.isfinite(r['required_additional_suppression_db'])]
            bb=[r for r in bounds if r['tx_id'].split('@')[0]==tx and r['victim_band']==band]
            pool=ff or bb or rr
            p=max(pool,key=lambda r:r['required_additional_suppression_db']) if ff or bb else pool[0]
            chosen.append(p)
        txr=[r for r in chosen if r['tx_id'].split('@')[0]==tx]
        for kind in ['SIMULATED','ENGINEERING_BOUND','BOUNDED']:
            rr=[r for r in txr if ('SIMULATED' in r['confidence'] if kind=='SIMULATED' else r['model_fidelity']=='PORT_MISMATCH_RESCALED_LBAND' if kind=='ENGINEERING_BOUND' else 'BOUNDED' in r['confidence'])]
            if rr:
                p=max(rr,key=lambda r:r['required_additional_suppression_db']);summary.append(dict(tx=ROLE[tx],scope=kind,worst_victim=actual(p['rx_id'])+' / '+BAND[p['victim_band']],
                    required_additional_suppression_db=p['required_additional_suppression_db'],first_passing_scenario=p['first_passing_scenario'],recommended_design_target_db=p['recommended_design_target_db'],
                    unresolved_primary_pair_count=sum(r['confidence']=='PRIMARY UNKNOWN' for r in results if r['tx_id'].split('@')[0]==tx),confidence=p['confidence']))
    write('filter_design_summary.csv',summary);write('main_design_results.csv',chosen)
    lband=[r for r in chosen if r['tx_id'].startswith('S_TM_TX') and r['victim_band'] in ['L1','L2','L5']]
    write('task1_lband_summary.csv',lband)
    write('task1_lband_pair_results.csv',[r for r in results if r['tx_id'].startswith('S_TM_TX') and r['victim_band'] in ['L1','L2','L5']])
    write('task1_lband_filter_scenarios.csv',[s for s in scenarios if s['tx_id'].startswith('S_TM_TX') and s['victim_band'] in ['L1','L2','L5'] and s['evaluation']!='CONDITIONAL_BOUND'])
    evidence=[]
    for cut in json.loads((ROOT/'data/antenna_port_response_cst/provenance.json').read_text())['cuts']:
        if cut['family']!='S' or cut['band'] not in ['L1','L2','L5'] or cut['quantity']!='RealizedGain':continue
        p=ROOT/cut['path'];raw=list(csv.DictReader(p.open(encoding='utf-8-sig')))
        evidence.append(dict(victim_band=cut['band'],frequency_hz=cut['frequency_hz'],plane=cut['plane'],
            raw_peak_realized_gain_dbi=max(float(v['gain']) for v in raw),accepted_power_fraction=cut['accepted_power_fraction'],
            normalization_reliable=cut['normalization_reliable'],primary_used=cut['band']=='L1',
            disposition='VALIDATED_CST_L1_REFERENCE' if cut['band']=='L1' else 'CST_VALUE_PRESENT_BUT_NORMALIZATION_UNRELIABLE',
            source_path=cut['path'],sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
    write('task1_cst_normalization_evidence.csv',evidence)
    # New engineering route changes only the 16 S-TC/GPS L2/L5 primary paths.
    bound_map={(r['case_id'],r['tx_id'],r['rx_id'],r['victim_band']):r for r in bounds}
    engineered=[r for r in results if r['model_fidelity']==policy['result_route']]
    assert len(engineered)==16
    for r in engineered:
        old_bound=bound_map[(r['case_id'],r['tx_id'],r['rx_id'],r['victim_band'])]
        assert abs(r['psd_victim_0db_dbm_hz']-(old_bound['psd_victim_0db_dbm_hz']-10))<1e-10
        assert abs(r['effective_tx_lband_source_dbm_hz']-(-59.020599913279625))<1e-10
        assert abs(r['derived_eirp_psd_dbm_hz']-(r['effective_tx_lband_source_dbm_hz']+r['tx_radiation_model_gain_dbi']))<1e-10
        assert r['confidence']==policy['confidence'] and not r['missing_reason']
    for r in results:
        if r['tx_id'].startswith('S_TM_TX') and r['victim_band']=='L1':
            o=oldmap[(r['case_id'],r['tx_id'],r['rx_id'])]
            assert r['port_mismatch_rescaling_db']==0 and r['confidence']=='SIMULATED'
            assert abs(r['coupling_db']-float(o['coupling_db']))<1e-10
            assert abs(r['psd_victim_0db_dbm_hz']-float(o['victim_psd_dbm_hz']))<1e-7
    assert all(not r['primary_used'] and not r['normalization_reliable'] for r in evidence if r['victim_band'] in ['L2','L5'])
    task1_validation=dict(status='PASS',freeze_sha='8469e8903da83b6ebed014aae311f90855c31715',
        supplement_start_head='99b96a339b68a4a1fa28ad7bd067914ab88caf48',
        supplement_branch='codex/rfi-emission-8469e89',initial_tracked_worktree_clean=True,
        initial_worktree_status='?? output/codex/standards/',
        source_psd_dbm_hz=lband[0]['itu_unwanted_source_psd_dbm_hz'],rescaling_db=-10,
        effective_source_dbm_hz=-59.020599913279625,owner_approximate_source_dbm_hz=-58,
        computed_minus_owner_approximate_db=-1.020599913279625,
        engineering_primary_pair_count=16,lband_pair_count=24,lband_scenario_count=120,
        confidence=policy['confidence'],mismatch_provenance_class=policy['provenance_class'],
        unreliable_cst_absolute_gain_used=False,l1_extra_rescaling_applied=False,l1_regression_max_delta_db=0,
        shared_freeze_hashes_unchanged=True,cst_or_octave_rerun=False,
        band_worst=[{k:r[k] for k in ['victim_band','itu_unwanted_source_psd_dbm_hz','coupling_db','effective_tx_lband_source_dbm_hz','derived_eirp_psd_dbm_hz','psd_victim_0db_dbm_hz','margin_0db_db','required_additional_suppression_db','first_passing_scenario','confidence']} for r in lband],
        checks=['owner policy exact -10 dB and L2/L5-only scope','regulatory source unchanged and -59.0206 arithmetic',
            'engineering EIRP excludes duplicate mismatch','unrescaled envelope-to-owner route delta exactly -10 dB',
            'all L1 original source/coupling/port values unchanged','unreliable CST gains excluded',
            'all pair source/coupling/margin/required identities','all five scenario signs and first PASS','all shared freeze hashes'])
    (OUT/'task1_validation.json').write_text(json.dumps(task1_validation,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    report='''# RFI 설계 보고서 — ITU source 기반 추가 TX 억제 요구

## 1. Executive Summary

**S-TC TX → GPS L1은 최소 48.00 dB, 첫 통과 screening은 60 dB다.** S-TC TX → S-TM RX는 58.89 dB로 60 dB minimum / 70 dB design target이다. ISL TX → S-TM RX는 33.70 dB로 40 dB class다.

**S-TC TX → GPS L2/L5는 owner 지정 10 dB port-mismatch rescaling으로 정량 engineering bound를 확보했다.** 최소 추가 억제량은 각각 81.19/81.61 dB로, 80 dB screening은 부족하다. CST normalization 문제가 해결된 것으로 해석하지 않으며, L1은 기존 검증 경로를 유지한다. Ka는 기존 조건부 bound / primary 보류를 유지하고 SAR와 동일 포트 경로도 미판정이다.

'''
    design=[]
    for r in chosen:
        design.append([ROLE[r['tx_id'].split('@')[0]],'GPS RX' if r['victim_band'].startswith('L') else 'S-TM RX' if r['victim_band']=='S_TC' else r['victim_band']+' RX',BAND[r['victim_band']],fmt(r['itu_unwanted_source_psd_dbm_hz']),fmt(r['coupling_db']),fmt(r['psd_victim_0db_dbm_hz']),fmt(r['allowable_psd_dbm_hz']),fmt(r['required_additional_suppression_db']),r['screening_design_class'] if r['confidence']!='PRIMARY UNKNOWN' else '최종 판정 보류',confidence_text(r)])
    report+=tab(['Attacker','Victim','Band','Source PSD/EIRP','Coupling','Victim PSD','Limit','Required suppression','Design class','Confidence'],design)
    report+='\n### S-TC TX filter design — Executive Summary\n'
    st_design=[r for r in chosen if r['tx_id'].startswith('S_TM_TX') and r['victim_band'] in ['L1','L2','L5','S_TC','ISL']]
    report+=tab(['Victim','0 dB margin (dB)','Required suppression (dB)','First PASS','Design target (dB)','Confidence'],
        [['S-TM RX' if r['victim_band']=='S_TC' else 'ISL RX' if r['victim_band']=='ISL' else 'GPS '+r['victim_band'],fmt(r['margin_0db_db']),fmt(r['required_additional_suppression_db']),passdesc(r['required_additional_suppression_db']),fmt(r['recommended_design_target_db']),confidence_text(r)] for r in st_design])
    report+='Source/Victim/Limit는 dBm/Hz, Coupling/Required는 dB다. Source는 ITU **conducted** PSD이며 bound 행은 TX gain ceiling을 coupling에 포함했다. EIRP와 TX gain을 중복 적용하지 않았다. 표는 각 TX/victim의 대표 worst이며 동일 포트 미확정 경로까지 통과했다는 뜻이 아니다.\n\n현재 legacy `S_TM_TX`는 **actual S-TC TX**, `S_TC_RX`는 **actual S-TM RX**다. 예: **S-TC TX @ SBA_ZENITH (legacy id: S_TM_TX)**. 역할 명칭만 바로잡고 ID·주파수·계산 코드는 유지했다. CSV의 `S_TC`는 S-TM RX의 기존 대역 키다.\n\n## 2. S-TC TX → GPS L-band 최우선 결과\n\n'
    lr=[r for r in chosen if r['tx_id'].startswith('S_TM_TX') and r['victim_band'] in ['L1','L2','L5']]
    report+=tab(['Attacker','Victim','Band','ITU source PSD (dBm/Hz)','Port mismatch rescaling (dB)','Effective TX L-band source (dBm/Hz)','Victim PSD (dBm/Hz)','Limit (dBm/Hz)','Required suppression (dB)'],
        [['S-TC TX','GPS RX',r['victim_band'],fmt(r['itu_unwanted_source_psd_dbm_hz']),fmt(r['port_mismatch_rescaling_db']),fmt(r['effective_tx_lband_source_dbm_hz']),fmt(r['psd_victim_0db_dbm_hz']),fmt(r['allowable_psd_dbm_hz']),fmt(r['required_additional_suppression_db'])] for r in lr])
    report+='Effective source는 mismatch 이후 accepted-power 상당 PSD이며 EIRP가 아니다. L1의 0 dB는 별도 rescaling을 적용하지 않았다는 뜻이며, 실제 mismatch는 CST RealizedGain에 이미 포함되어 있다. L2/L5는 effective source에 accepted-power gain envelope 9.03 dBi를 한 번 적용한 뒤 GPS receive RealizedGain과 FSPL을 결합했다.\n'
    report+=tab(['경로','Incident 기준 TX equivalent gain (dBi)','Victim PSD (dBm/Hz)','Margin (dB)','Required (dB)','First PASS','근거'],[[f"S-TC TX → GPS {r['victim_band']}",fmt(r['tx_victim_gain_dbi']),fmt(r['psd_victim_0db_dbm_hz']),fmt(r['margin_0db_db']),fmt(r['required_additional_suppression_db']),passdesc(r['required_additional_suppression_db']) if math.isfinite(r['required_additional_suppression_db']) else '미판정',confidence_text(r)] for r in lr])
    report+='L2/L5 equivalent gain −0.97 dBi는 radiation envelope 9.03 dBi + owner mismatch −10 dB다. 메인 표의 coupling도 이 mismatch를 포함하므로 ITU source에서 port PSD를 구할 때 −10 dB를 다시 빼지 않는다.\n\n'
    report+='L1의 source와 coupling은 기존 ITU 결과와 동일하다. 이전 ECSS primary 37.99 dB와의 차이는 source 선정의 10.01 dB 차이다. **L2/L5 primary는 이번 Task 1에서 owner engineering bound로 전환했다.** 불안정한 CST absolute gain이나 accepted-power fraction은 계산에 사용하지 않는다. 기존 mismatch 미적용 gain envelope 결과 91.19/91.61 dB는 sensitivity CSV에 보존했다.\n\n−49.0206 dBm/Hz − 10 dB = **−59.0206 dBm/Hz**다. Owner의 약 −58 dBm/Hz 표현과는 **−1.0206 dB** 차이가 있으며 −58로 맞추기 위해 source를 변경하지 않았다. Gain envelope 적용 후 EIRP screening level은 **−49.9897 dBm/Hz**로 별도 구분한다. −10 dB는 owner 결정이며 CST 측정값이나 ITU 규격값이 아니다.\n\n## 3. Source·기준면·required suppression 정의\n\n'
    report+=f'''[ITU-R SM.329-13]({ITU}) §4.1 / §4.2 Table2 space stations 및 [RR Appendix3 TableI]({RR})의 4 kHz 한계를 그대로 사용한다. `A=min(43+10log10(P_W),60)`, `Source=P_dBm−A−10log10(4000)`이며 S-TC 5 W / ISL 1 W는 −49.0206 dBm/Hz, Ka 70 W는 −47.5696 dBm/Hz 상당이다. 기준면은 ANTENNA_PORT다. Flat broadband-equivalent만 PSD로 계산하며 discrete spur를 4 kHz로 나눈 noise로 바꾸지 않는다.

`PSD_victim_0dB = PSD_TX_unwanted + G_TX(victim) + G_RX(victim) − FSPL`

`margin_0dB = PSD_allowable − PSD_victim_0dB`

`required_additional_suppression_db = max(0, −margin_0dB)`

L2/L5 engineering route는 `PSD_victim = ITU source − 10 dB + G_radiation_envelope + G_RX − FSPL`이다. 기존 GPS L2/L5 receive RealizedGain을 유지하며 TX CST absolute RealizedGain은 사용하지 않는다.

EIRP route는 `EIRP + G_RX − FSPL`이다. 추가필터 F는 margin을 F dB 증가시키며 최소 요구는 항상 **0 dB 기준 총 요구량**이다. 필터 적용 후 남은 요구와 혼동하지 않는다. Receiver criterion은 GPS −178, S-TM/ISL −177 dBm/Hz이며 SAR는 freeze NF5 / I/N−6의 −175 dBm/Hz 가정이다.

## 4. L2/L5 owner engineering bound와 Ka 한계

'''
    report+=f'''[Harrington, 1960 §2 Eq.(19)]({NIST})의 제한된 spherical modes `n≤N`에서 `Dmax=N²+2N`을 사용했다. 독립 계산에서 `a=√3·D/2`, `N=max(1,ceil(2πfa/c))`를 선택했다. D는 freeze S surrogate 0.065 m, KAA 0.220 m다. 각 축의 current extent가 D 이내이고 상위 모드·superdirectivity가 없다는 **미확인 가정** 아래 unity efficiency/matching, 모든 방위 maximum을 사용한 보수적 bound다. 26 GHz 패턴 외삽은 없다.

Finite-mode 조건에서의 상한이며 크기만으로 모든 가능한 안테나의 엄밀한 gain 상한이 되는 것은 아니다. S-TC L2/L5에는 이 radiation envelope와 owner 승인 −10 dB mismatch 정책을 결합해 **ENGINEERING_BOUND — L1-referenced 10 dB port-mismatch rescaling**으로 정량 결과를 제공한다. 이는 CST normalization의 재검증이 아니며 장착 구조·전류 범위·고차 모드 가정과 자유공간 모델을 전제로 한다. Ka의 confidence는 기존 조건부 bound, primary는 최종 판정 보류다. Ka → ISL은 근거리 조건 때문에 FSPL 경로도 보수적 상한으로 보증할 수 없다. SAR는 RX gain bound도 정당화할 수 없어 미판정이다.

## 5. TX별 filter design summary

'''
    report+=tab(['TX','Worst victim','Required suppression','First passing scenario','Recommended design target'],[[s['tx']+' / '+{'SIMULATED':'시뮬레이션','ENGINEERING_BOUND':'Owner engineering bound','BOUNDED':'조건부 bound'}[s['scope']],s['worst_victim'],fmt(s['required_additional_suppression_db'])+' dB',passdesc(s['required_additional_suppression_db']),fmt(s['recommended_design_target_db'])+' dB'+(' (모델 가정 적용)' if s['scope']!='SIMULATED' else ' (확보 경로)')] for s in summary])
    strows=[r for r in chosen if r['tx_id'].startswith('S_TM_TX') and r['victim_band'] in ['S_TC','ISL']]
    report+=tab(['S-TC TX victim','Minimum suppression','First PASS','Design target'],[['S-TM RX' if r['victim_band']=='S_TC' else 'ISL RX',fmt(r['required_additional_suppression_db'])+' dB',passdesc(r['required_additional_suppression_db']),fmt(r['recommended_design_target_db'])+' dB'] for r in strows])
    report+='Design target은 최소 억제량에 **10 dB engineering reserve를 더하고 10 dB 단위로 올림**한 계획값이다. 규격·실제 필터 보증값이 아니다. Same-port transfer/SAR 미확정 경로가 남아 있으므로 TX 전체의 최종 요구는 아직 보류다.\n\n## 6. 0/40/60/70/80 dB scenario\n\n'
    report+=tab(['TX → Victim','0 dB','40 dB','60 dB','70 dB','80 dB'],[[ROLE[r['tx_id'].split('@')[0]]+' → '+('S-TM RX' if r['victim_band']=='S_TC' else r['victim_band'])]+[(fmt(r['margin_0db_db']+a)+' / '+('기준 충족' if r['margin_0db_db']+a>=0 else '기준 초과')) if math.isfinite(r['margin_0db_db']) else '미판정' for a in SCENARIOS] for r in chosen])
    report+='Bound 행의 PASS는 조건부 모델의 PASS다. Primary unknown을 해소하지 않는다.\n\n## 7. 모든 pair 산출물과 판정 한계\n\n[all_pair_required_suppression.csv](all_pair_required_suppression.csv)는 case·물리 설치 pair별 ITU primary 결과다. Source, 기준면, TX victim-band gain/EIRP, coupling, port PSD, criterion, margin, required suppression, first PASS, fidelity를 모두 담았다. [conditional_bound_required_suppression.csv](conditional_bound_required_suppression.csv)는 해당 누락 경로의 별도 bound다. [design_filter_scenarios.csv](design_filter_scenarios.csv)는 각 pair의 5개 scenario다.\n\nSame-port S-TC TX → S-TM RX는 독립 spectral compatibility requirement를 유지한다. Transfer가 없으므로 숫자를 임의 생성하지 않았다. TX unwanted 억제 요구는 RX blocker rejection·diplexer isolation·preselector attenuation과 별개다. 동시 attacker 합산, 개별 tone 성능, 최종 장비 적합성을 이 per-pair PSD 표만으로 통과 판정하지 않는다.\n\n## 8. Secondary blocker\n\n기존 **S-TC TX @ SBA_ZENITH → GPSA1 −21.317 dBm**, **S-TC TX → 반대편 S-TM RX −32.288 dBm** 입력은 유지했다. 이번 TX spectral filter 요구에 사용하지 않았다. Blocking/P1dB/preselector/IIP3 기준 미확보로 전단 보호 판정은 보류다.\n\n## 9. Appendix / provenance와 검증\n\n'
    report+='Freeze `8469e8903da83b6ebed014aae311f90855c31715`, branch `codex/rfi-emission-8469e89`. 기존 Codex coupling CSV만 재사용했으며 공유 src/data/test 의미는 변경하지 않았다. 실제 역할 교정은 `actual_*` 열과 보고서에만 적용했다. Legacy ID를 lookup/join 키로 유지했다. 기존 ECSS·ITU 결과는 삭제하지 않고 ITU 설계 보완 표와 구분했다.\n\n[itu_design_source_table.csv](itu_design_source_table.csv), [main_design_results.csv](main_design_results.csv), [filter_design_summary.csv](filter_design_summary.csv), [suppression_design_validation.json](suppression_design_validation.json)을 참조한다. 동일 입력 hash·ITU regression·전력/PSD식·최소 억제식·5개 scenario·실제 역할 표기를 검증했다. 재현은 `python output/codex/complete_suppression_design.py`다. 공유 코드의 기존 PSD unit tests 76개 통과 기록은 [emission_execution.log](emission_execution.log)에 보존했다.\n'
    report+='\n### Bound 경로의 거리 적용 범위\n\nKa → ISL 거리 약 1.78–2.34 m는 가정한 enclosing sphere 기준 TX far-field screening 거리보다 짧다. 해당 FSPL 결과는 조건부 sensitivity이며 near-field coupling 상한을 보증하지 않는다. 다른 bound도 우주선 구조·케이블의 방사 전류가 가정한 체적 밖에 존재하면 다시 평가해야 한다. CSV의 `distance_m`, `bound_tx_far_field_screen_distance_m`, `bound_tx_far_field_screen`에 거리 검토를 남겼다.\n\n규격 후보 비교와 기존 OOB/spurious 경계 검토는 [standard_candidates.csv](standard_candidates.csv), [domain_classification.csv](domain_classification.csv)에 보존했다. 후보 CSV의 과거 PRIMARY 표시는 이전 분석 선택이며 최신 설계 표는 ITU 규격이다. Harrington 모드 한계의 식 번호는 §2 Eq.(19)이며 `N=ceil(ka)` 선택과 전류 체적은 worker의 조건부 engineering assumption이다.\n'
    if (OUT/'suppression_design_audit.json').exists():report+='\nTask 1 이전의 원본 열 보존 검사는 [suppression_design_audit.json](suppression_design_audit.json)에 보존했다. 이번 변경의 검증은 [task1_validation.json](task1_validation.json)을 참조한다.\n'
    report+='\n### Task 1의 입력과 원본 CST 보존\n\n[Owner mismatch 정책](emission_inputs/owner_port_mismatch_policy.json)에 −10 dB, 적용 대역 L2/L5, owner provenance, radiation 모델 가정을 기록했다. [task1_cst_normalization_evidence.csv](task1_cst_normalization_evidence.csv)에 기존 S/L1·L2·L5 각 주파수/단면의 gain peak, accepted-power fraction, 원본 hash, primary 사용 여부를 보존했다. L1 band 최소 accepted-power fraction 약 0.0957에 비해 10 dB 감쇠는 fraction 0.1에 해당하는 더 약한 감쇠다. L2/L5의 신뢰 불가 값은 primary에 사용하지 않았다.\n\n[task1_lband_summary.csv](task1_lband_summary.csv)는 band별 대표 worst, [task1_lband_pair_results.csv](task1_lband_pair_results.csv)는 24개 설치/case 경로, [task1_lband_filter_scenarios.csv](task1_lband_filter_scenarios.csv)는 120개 scenario다. L1 source/coupling, 기타 attacker 결과, freeze 입력을 유지하며 CST/Octave를 다시 실행하지 않았다.\n'
    (OUT/'결과보고서.md').write_text(report,encoding='utf-8')
    # Historical human document gets an explicit role notice and corrected display labels.
    p=OUT/'emission_inputs/pre_emission_report.md';s=p.read_text(encoding='utf-8')
    marker='<!-- actual-role-labels-applied -->'
    if marker not in s:
        # This archive was translated once when this supplement was created.
        # Correct the old unqualified labels only; a second run must preserve actual names.
        s=re.sub(r'S-TM(?! RX)', 'S-ROLE-TX',s)
        s=re.sub(r'S-TC(?! TX)', 'S-TM RX',s).replace('S-ROLE-TX','S-TC TX')
        s=marker+'\n\n'+s
    p.write_text(s,encoding='utf-8')
    checks=dict(status='PASS',freeze_shared_hashes_unchanged=True,primary_pair_rows=len(results),conditional_bound_pair_rows=len(bounds),scenario_rows=len(scenarios),
        itu_regression_required_db=regress,regression_max_delta_db=0,actual_roles_applied=True,legacy_ids_unchanged=True,
        bounds='Ka remains conditional / primary unknown; S-TC L2/L5 primary uses owner mismatch engineering route',new_cst_simulation_run=False,
        owner_engineering_primary_rows=len(engineered))
    (OUT/'suppression_design_validation.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
    for p in re.findall(r'\]\(([^)]+)\)',report):
        if not p.startswith('https:'):assert (OUT/p).exists(),p
    print(json.dumps(summary,indent=2));print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
