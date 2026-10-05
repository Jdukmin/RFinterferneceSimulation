"""Latest Owner engineering policy applied to independent frozen Codex evidence."""
import json, math, csv, hashlib, re
from collections import defaultdict
from complete_suppression_design import OUT, ROOT, read, read_data, write, first, passdesc, tab, fmt, target, ITU, RR
from task2_scope_analysis import rectangular_cutoff, unit, dot, interp, envelope, C
BANDS=['L1','L2','L5','S_TC','ISL','SAR']

def number(x):
    try:return float(x) if math.isfinite(float(x)) else None
    except (TypeError,ValueError):return None

def worst(pool):
    valid=[r for r in pool if number(r['psd_victim_0db_dbm_hz']) is not None]
    return max(valid,key=lambda r:float(r['psd_victim_0db_dbm_hz'])) if valid else pool[0]

def victim(b):return 'GPS '+b if b.startswith('L') else 'S-TM RX' if b=='S_TC' else 'ISL RX' if b=='ISL' else 'SAR RX'

def main():
    policy=json.loads((OUT/'emission_inputs/latest_owner_policy.json').read_text(encoding='utf-8'))
    for r in read('emission_inputs/freeze_input_hashes.csv'):
        assert hashlib.sha256((ROOT/r['path']).read_bytes()).hexdigest()==r['sha256']
    old=read('legacy_task1/all_pair_required_suppression.csv')
    detail=read('victim_band_coupling.csv');groups=defaultdict(list)
    for r in detail:groups[(r['case_id'],r['tx_id'],r['rx_id'],r['victim_band'])].append(r)
    length=policy['effective_below_cutoff_length_m'];a=policy['rectangular_broad_wall_a_m']
    assert length==.05 and a==.010668
    itu_s=-49.020599913279625;anchor=itu_s-10
    eirp_dbw=10*math.log10(70)+31;conducted=30+10*math.log10(70)-60-10*math.log10(4000);eirp_psd=conducted+31
    # Relative TX shape only: subtract one shared peak from BOTH cuts at each frequency.
    # No unreliable absolute RealizedGain or accepted-power fraction enters a link budget.
    meta=json.loads((ROOT/'data/antenna_port_response_cst/provenance.json').read_text())
    cuts=defaultdict(dict)
    for c in meta['cuts']:
        if c['family']=='S' and c['band'] in ['L2','L5'] and c['quantity']=='RealizedGain':
            assert not c['normalization_reliable']
            with (ROOT/c['path']).open(encoding='utf-8-sig') as f:raw=[(float(r['theta']),float(r['gain'])) for r in csv.DictReader(f)]
            cuts[(c['band'],c['frequency_hz'])][c['plane']]=raw
    shape_nodes={}
    for (band,f),planes in cuts.items():
        peak=max(y for pts in planes.values() for x,y in pts)
        shape_nodes[(band,f)]={plane:[(x,y-peak) for x,y in pts]+[(360,pts[0][1]-peak)] for plane,pts in planes.items()}
    inst={r['antenna_id']:r for r in read_data('data/spacecraft/simplified_spacecraft_v1/antenna_installations.csv')}
    panels={r['panel_id']:r for r in read_data('data/spacecraft/simplified_spacecraft_v1/panels.csv')}
    def pos(i):return [float(inst[i][k])/1000 for k in ['x_mm','y_mm','z_mm']]
    def shape(tx,rx,band,f):
        u=unit([v-w for v,w in zip(pos(rx),pos(tx))]);panel=panels[inst[tx]['panel_id']]
        n=[float(panel[k]) for k in ['n_x','n_y','n_z']]
        theta=math.degrees(math.acos(max(-1,min(1,dot(u,n)))))
        vals=[]
        for ff in sorted(f0 for b,f0 in shape_nodes if b==band):
            pp=shape_nodes[(band,ff)]
            vals.append((ff,max(interp(pts,t) for pts in pp.values() for t in [theta,360-theta])))
        v=interp(vals,f);assert v<=1e-8
        return v
    sar_coefficients={(r['case_id'],r['tx_id']):r for r in read('stc_sar_spurious_results.csv')}
    comparisons=[];active=[]
    for rr in old:
        if not rr['tx_id'].startswith('S_TM_TX'):continue
        r=dict(rr);band=r['victim_band'];key=tuple(r[k] for k in ['case_id','tx_id','rx_id','victim_band'])
        if band=='SAR':
            sr=sar_coefficients[(r['case_id'],r['tx_id'])]
            assert float(sr['sar_polar_off_axis_deg'])>80
            coeff=float(sr['port_psd_coefficient_dbm_hz']);port=coeff+52-50;need=max(0,port+176)
            r.update(itu_unwanted_source_psd_dbm_hz=itu_s,source_reference_plane='ANTENNA_PORT',port_mismatch_rescaling_db=0,
                tx_victim_gain_dbi=sr['tx_sar_band_gain_dbi'],derived_eirp_psd_dbm_hz=itu_s+float(sr['tx_sar_band_gain_dbi']),coupling_db=port-itu_s,
                psd_victim_0db_dbm_hz=port,allowable_psd_dbm_hz=-176,margin_0db_db=-176-port,required_additional_suppression_db=need,
                first_passing_scenario=first(need),recommended_design_target_db=target(need),screening_design_class=passdesc(need),
                model_fidelity='TX_RELIABLE_CST_CUT_ENVELOPE_PLUS_OWNER_SAR_REAR',evaluation='SAR_GENERIC_SPURIOUS_PRIMARY',confidence='OWNER_SAR_GAIN_AND_REAR_ENVELOPE',missing_reason='',
                distance_m=sr['distance_m'],worst_frequency_hz=sr['worst_frequency_hz'],bound_provenance='OWNER_ENGINEERING_ESTIMATE_FROM_HPBW; OWNER_ENGINEERING_REAR_ENVELOPE')
        elif band in ['L2','L5']:
            rows=groups[key]
            peak=max(rows,key=lambda v:anchor+float(v['radiated_transfer_db']))
            shape_peak=max(rows,key=lambda v:anchor+shape(r['tx_id'].split('@')[1],r['rx_id'].split('@')[1],band,float(v['frequency_hz']))+float(v['radiated_transfer_db']))
            tr=float(peak['radiated_transfer_db']);port=anchor+tr;need=max(0,port+178)
            shaped=anchor+shape(r['tx_id'].split('@')[1],r['rx_id'].split('@')[1],band,float(shape_peak['frequency_hz']))+float(shape_peak['radiated_transfer_db'])
            comparisons.append(dict(case_id=r['case_id'],tx_id=r['tx_id'],rx_id=r['rx_id'],victim_band=band,itu_source_dbm_hz=itu_s,mismatch_db=-10,post_mismatch_source_dbm_hz=anchor,
                current_bound_gain_dbi=float(rr['tx_radiation_model_gain_dbi']),current_bound_victim_psd_dbm_hz=float(rr['psd_victim_0db_dbm_hz']),current_bound_required_db=float(rr['required_additional_suppression_db']),
                current_bound_first_pass=rr['first_passing_scenario'],owner_only_angular_ceiling_db=0,owner_only_victim_psd_dbm_hz=port,owner_only_required_db=need,owner_only_first_pass=first(need),
                shape_only_sensitivity_psd_dbm_hz=shaped,shape_only_sensitivity_required_db=max(0,shaped+178),primary_selection='OWNER_RESCALING_ONLY_ROUTE',shape_confidence='RELATIVE_CUT_SHAPE_UNVALIDATED_SENSITIVITY_ONLY',
                anchor_assumption=policy['l2_l5_anchor_interpretation']))
            r.update(tx_radiation_model_gain_dbi=0,tx_victim_gain_dbi=-10,derived_eirp_psd_dbm_hz=anchor,coupling_db=tr-10,
                psd_victim_0db_dbm_hz=port,margin_0db_db=-178-port,required_additional_suppression_db=need,first_passing_scenario=first(need),
                recommended_design_target_db=target(need),screening_design_class=passdesc(need),confidence='OWNER_ENGINEERING_RADIATED_PEAK_ANCHOR',evaluation='OWNER_RESCALING_ONLY_ROUTE',
                model_fidelity='OWNER_RESCALING_ONLY_ROUTE',bound_provenance='No finite-mode gain bound in primary; normalized shape ceiling 0dB',worst_frequency_hz=peak['frequency_hz'],
                effective_source_reference_plane='OWNER_PEAK_EQUIVALENT_RADIATED_PSD_ANCHOR',missing_reason='')
        active.append(r)
    write('lband_route_comparison.csv',comparisons)
    cases=sorted({r['case_id'] for r in old})
    for tx in ['KAA_1','KAA_2']:
        delta=[x-y for x,y in zip(pos(tx),pos('SAR_ANT'))];dist=math.sqrt(sum(v*v for v in delta))
        theta=math.degrees(math.acos(delta[2]/dist)) # frozen SAR Panel1 normal +Z
        assert theta>80
        for case in cases:
            key=(case,'KA_DLS_TX@'+tx,'SAR_X_RX@SAR_ANT','SAR')
            groups[key]=[]
            for j in range(161):
                f=9.3875e9+(9.9125e9-9.3875e9)*j/160;fspl=20*math.log10(4*math.pi*f*dist/C)
                groups[key].append(dict(case_id=case,tx_id=key[1],rx_id=key[2],victim_band='SAR',frequency_hz=f,radiated_transfer_db=2-fspl,rx_gain_dbi=2,fspl_db=fspl,distance_m=dist,
                    sar_rx_polar_angle_deg=theta,rx_source='OWNER52DBI_MINUS50DB_REAR_ENVELOPE'))
    ka=[]
    for key,rr in groups.items():
        if not key[1].startswith('KA_DLS_TX') or key[3] not in BANDS:continue
        peak=max(rr,key=lambda r:eirp_psd-rectangular_cutoff(float(r['frequency_hz']),a,length)[3]+float(r['radiated_transfer_db']))
        f=float(peak['frequency_hz']);atten=rectangular_cutoff(f,a,length)[3];transfer=float(peak['radiated_transfer_db']);port=eirp_psd-atten+transfer;limit=-178 if key[3].startswith('L') else -176 if key[3]=='SAR' else -177
        r={k:'' for k in old[0]};r.update({k:peak[k] for k in ['case_id','tx_id','rx_id','victim_band']})
        r.update(actual_attacker='Ka DLS TX',actual_victim=victim(key[3]),actual_victim_band=key[3],itu_unwanted_source_psd_dbm_hz=conducted,source_reference_plane='UPSTREAM_GUIDE_ANTENNA_PORT_EQUIVALENT_OWNER_ASSUMPTION',
            tx_victim_gain_dbi=31,derived_eirp_psd_dbm_hz=eirp_psd-atten,coupling_db=31-atten+transfer,psd_victim_0db_dbm_hz=port,allowable_psd_dbm_hz=limit,margin_0db_db=limit-port,
            required_additional_suppression_db=max(0,port-limit),first_passing_scenario=first(max(0,port-limit)),screening_design_class=passdesc(max(0,port-limit)),recommended_design_target_db=target(max(0,port-limit)),
            confidence='OWNER_ENGINEERING_ASSUMPTION; NOT_FULL_WAVE_VALIDATED',evaluation='KA_WR42_50MM_PRIMARY',model_fidelity='WAVEGUIDE_BELOW_CUTOFF_BOUND',worst_frequency_hz=f,distance_m=peak['distance_m'],missing_reason='',
            source_provenance=ITU,bound_provenance=policy['ka_spectral_reference_plane_assumption'])
        active.append(r)
        ka.append(dict(case_id=key[0],tx_id=key[1],rx_id=key[2],victim_band=key[3],worst_frequency_hz=f,actual_waveguide='WR-42',broad_wall_a_m=a,effective_length_m=length,
            source_conducted_psd_dbm_hz=conducted,owner_gain_reference_dbi=31,rx_gain_dbi=float(peak['rx_gain_dbi']),fspl_db=float(peak['fspl_db']),distance_m=float(peak['distance_m']),source_eirp_psd_dbm_hz=eirp_psd,cutoff_attenuation_db=atten,attenuated_eirp_psd_dbm_hz=eirp_psd-atten,
            victim_coupling_db=transfer,victim_psd_dbm_hz=port,allowable_psd_dbm_hz=limit,margin_0db_db=limit-port,required_additional_suppression_db=max(0,port-limit),first_passing_scenario=r['first_passing_scenario'],
            zero_credit_required_db=max(0,eirp_psd+transfer-limit),provenance='OWNER_ENGINEERING_ASSUMPTION; WAVEGUIDE_BELOW_CUTOFF_BOUND; NOT_FULL_WAVE_VALIDATED',reference_plane_assumption=policy['ka_spectral_reference_plane_assumption']))
    write('ka_cutoff_pair_requirements.csv',ka)
    baseline={r['victim_band']:r for r in read_data('data/rfi_psd/receiver_baseline.csv')};band_rows=[]
    for band in BANDS:
        f=float(baseline[band]['tuning_hi_mhz'])*1e6;fc,ratio,alpha,atten=rectangular_cutoff(f,a,length)
        pool=[r for r in ka if r['victim_band']==band];k=max(pool,key=lambda r:r['victim_psd_dbm_hz']) if pool else None
        band_rows.append(dict(victim_band=band,primary_scope='PRIMARY',actual_waveguide='WR-42',broad_wall_a_m=a,te10_cutoff_hz=fc,band_upper_hz=f,frequency_ratio=ratio,alpha_np_m=alpha,effective_length_m=length,
            minimum_band_cutoff_attenuation_db=atten,source_eirp_reference_dbw=eirp_dbw,source_eirp_psd_dbm_hz=eirp_psd,
            victim_psd_dbm_hz=k['victim_psd_dbm_hz'] if k else '',required_additional_suppression_db=k['required_additional_suppression_db'] if k else '',
            provenance='OWNER_ENGINEERING_ASSUMPTION; WAVEGUIDE_BELOW_CUTOFF_BOUND; NOT_FULL_WAVE_VALIDATED'))
    write('ka_cutoff_band_results.csv',band_rows)
    write('all_pair_required_suppression.csv',active);write('task2_primary_pairs.csv',active)
    scenarios=[]
    for r in active:
        port=number(r['psd_victim_0db_dbm_hz']);lim=float(r['allowable_psd_dbm_hz'])
        for fdb in [0,40,60,70,80]:
            scenarios.append(dict(case_id=r['case_id'],tx_id=r['tx_id'],rx_id=r['rx_id'],actual_attacker=r['actual_attacker'],actual_victim=r['actual_victim'],victim_band=r['victim_band'],evaluation=r['evaluation'],filter_db=fdb,
                victim_psd_dbm_hz=port-fdb if port is not None else '',margin_db=lim-port+fdb if port is not None else '',required_additional_suppression_db=r['required_additional_suppression_db'],first_passing_scenario=r['first_passing_scenario'],
                status=('PASS' if lim-port+fdb>=0 else 'FAIL') if port is not None else 'NOT_APPLICABLE' if r['evaluation']=='NO_HARMONIC_OVERLAP' else 'UNKNOWN',confidence=r['confidence']))
    write('design_filter_scenarios.csv',scenarios)
    chosen=[worst([r for r in active if r['tx_id'].startswith(tx) and r['victim_band']==b]) for tx in ['S_TM_TX','KA_DLS_TX'] for b in BANDS]
    write('main_design_results.csv',chosen)
    summary=[]
    for tx in ['S_TM_TX','KA_DLS_TX']:
        pool=[r for r in active if r['tx_id'].startswith(tx)];w=worst(pool)
        summary.append(dict(tx='S-TC TX' if tx=='S_TM_TX' else 'Ka DLS TX',worst_victim=victim(w['victim_band']),required_additional_suppression_db=w['required_additional_suppression_db'],first_passing_scenario=w['first_passing_scenario'],recommended_design_target_db=w['recommended_design_target_db'],
            unresolved_primary_pair_count=sum(number(r['psd_victim_0db_dbm_hz']) is None and r['evaluation']!='NO_HARMONIC_OVERLAP' for r in pool),confidence=w['confidence']))
    write('filter_design_summary.csv',summary)
    # Latest SAR engineering baseline. Retained generic spurious is sensitivity ONLY.
    noise=10*math.log10(1.380649e-23*290*1000)+4
    write('sar_receiver_owner_baseline.csv',[dict(peak_gain_dbi=52,peak_gain_provenance=policy['sar_absolute_gain_provenance'],rear_relative_peak_db=-50,rear_absolute_gain_ceiling_dbi=2,rear_provenance=policy['sar_rear_provenance'],nf_db=4,temperature_k=290,i_n_db=-6,noise_psd_exact_dbm_hz=noise,allowable_psd_exact_dbm_hz=noise-6,allowable_primary_rounded_dbm_hz=-176,provenance='OWNER_ENGINEERING_BASELINE')])
    sar=read('stc_sar_spurious_results.csv')
    for r in sar:
        port=float(r['port_psd_coefficient_dbm_hz'])+52-50
        r.update(primary_scope='GENERIC_SPURIOUS_PRIMARY_SEPARATE_FROM_HARMONIC',normalized_directional_gain_db=-50,sar_absolute_peak_gain_dbi=52,victim_psd_dbm_hz=port,allowable_psd_dbm_hz=-176,required_additional_suppression_db=max(0,port+176),first_passing_scenario=first(max(0,port+176)),
            status='OWNER_REAR_ENVELOPE_PRIMARY',port_formula='coefficient + 52dBi - 50dB rear envelope',required_formula='max(0, victim_psd + 176)',sar_provenance='OWNER_ENGINEERING_ESTIMATE_FROM_HPBW; OWNER_ENGINEERING_REAR_ENVELOPE',model_fidelity='RELIABLE_TX_CST_CUTS_AND_OWNER_SAR_ABSOLUTE_REAR_GAIN')
    write('stc_sar_spurious_results.csv',sar)
    pattern=read('sar_reference_envelope.csv');pattern=[r for r in pattern if abs(float(r['angle_deg']))<=80]
    for r in pattern:r.update(absolute_co_gain_dbi=52+float(r['co_normalized_db']),absolute_gain_provenance=policy['sar_absolute_gain_provenance'])
    for axis in ['azimuth','elevation']:
        for angle in [-180,-150,-120,-90,-80.000001,80.000001,90,120,150,180]:
            r=dict(next(r for r in pattern if r['axis']==axis));r.update(angle_deg=angle,co_normalized_db=-50,absolute_co_gain_dbi=2,provenance=policy['sar_rear_provenance'],interpolation='OWNER_CONSTANT_REAR_CEILING',fidelity='OWNER_ENGINEERING_REAR_ENVELOPE');pattern.append(r)
    write('sar_reference_envelope.csv',pattern)
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,axes=plt.subplots(1,2,figsize=(12,4))
    for axis_name in ['azimuth','elevation']:
        rr=sorted((r for r in pattern if r['axis']==axis_name),key=lambda r:float(r['angle_deg']))
        axes[0].plot([float(r['angle_deg']) for r in rr],[float(r['co_normalized_db']) for r in rr],label=axis_name)
        axes[1].plot([float(r['angle_deg']) for r in rr],[float(r['absolute_co_gain_dbi']) for r in rr],label=axis_name)
    for ax in axes:ax.grid(alpha=.3);ax.legend();ax.set_xlabel('Angle (deg)');ax.set_xlim(-180,180)
    axes[0].set_ylabel('Co normalized to peak (dB)');axes[1].set_ylabel('Co gain (dBi), owner engineering estimate')
    fig.suptitle('Owner SAR reconstruction: peak 52 dBi; rear ceiling +2 dBi; no original MAT export')
    fig.tight_layout();fig.savefig(OUT/'sar_reference_envelope.png',dpi=150);plt.close(fig)

    scope=read('task2_role_matrix.csv')
    for r in scope:
        if r['legacy_tx_id']=='S_TM_TX' and r['victim']=='SAR':r['primary_scope']='GENERIC_SPURIOUS_PRIMARY_WITH_SEPARATE_HARMONIC_CHECK';r['harmonic_route']='NO_HARMONIC_OVERLAP'
        if r['legacy_tx_id']=='KA_DLS_TX' and r['victim']=='SAR':r['primary_scope']='PRIMARY_SPURIOUS_WAVEGUIDE_AND_OWNER_REAR_ENVELOPE'
    write('task2_role_matrix.csv',scope)
    comparisons_band=[]
    for b in ['L2','L5']:
        pool=[r for r in comparisons if r['victim_band']==b]
        comparisons_band.append(dict(victim_band=b,current_bound_required_db=max(r['current_bound_required_db'] for r in pool),owner_only_required_db=max(r['owner_only_required_db'] for r in pool),shape_sensitivity_required_db=max(r['shape_only_sensitivity_required_db'] for r in pool)))
    write('lband_route_summary.csv',comparisons_band)
    ka_comparison=[]
    for b in BANDS:
        pool=[r for r in ka if r['victim_band']==b]
        ka_comparison.append(dict(victim_band=b,previous_zero_credit_required_db=max(r['zero_credit_required_db'] for r in pool),wr42_50mm_required_db=max(r['required_additional_suppression_db'] for r in pool),primary_selection='WR42_50MM_OWNER_ENGINEERING_ASSUMPTION',legacy_gain_bound_selection='SENSITIVITY_ONLY'))
    write('ka_route_comparison.csv',ka_comparison)
    # Cross-check equations, assumptions and unchanged independent results.
    for r in active:
        port=number(r['psd_victim_0db_dbm_hz'])
        if port is not None:
            assert abs(port-(float(r['itu_unwanted_source_psd_dbm_hz'])+float(r['coupling_db'])))<1e-7
            assert abs(float(r['required_additional_suppression_db'])-max(0,port-float(r['allowable_psd_dbm_hz'])))<1e-7
            assert r['first_passing_scenario']==first(float(r['required_additional_suppression_db']))
    for r in ka:
        assert abs(r['victim_psd_dbm_hz']-(conducted+31-r['cutoff_attenuation_db']+r['victim_coupling_db']))<1e-9
        assert abs(r['cutoff_attenuation_db']-rectangular_cutoff(r['worst_frequency_hz'],a,.05)[3])<1e-9
    for b,expected in [('L1',48.000831707320376),('S_TC',58.88653586972038),('ISL',39.240968602720386)]:
        w=next(r for r in chosen if r['tx_id'].startswith('S_TM_TX') and r['victim_band']==b)
        assert abs(float(w['required_additional_suppression_db'])-expected)<1e-5,(b,w['required_additional_suppression_db'])
    for planes in cuts.values():
        raw_peak=max(y for pts in planes.values() for x,y in pts)
        shifted_peak=max(y+137.5 for pts in planes.values() for x,y in pts)
        assert all(abs((y-raw_peak)-((y+137.5)-shifted_peak))<1e-10 for pts in planes.values() for x,y in pts)
    assert all(r['status']=='NO_HARMONIC_OVERLAP' for r in read('sar_harmonic_overlap.csv'))
    assert not any(r['tx_id'].startswith(('ISL','SAR')) for r in active)
    assert all(number(r['psd_victim_0db_dbm_hz']) is not None and float(r['allowable_psd_dbm_hz'])==-176 and not r['missing_reason'] for r in active if r['victim_band']=='SAR')
    assert len([r for r in active if r['victim_band']=='SAR'])==24
    assert abs(eirp_psd-(-16.569619513137056))<1e-9 and abs(anchor-(-59.020599913279625))<1e-9
    for r in comparisons:
        assert abs(r['current_bound_victim_psd_dbm_hz']-r['owner_only_victim_psd_dbm_hz']-r['current_bound_gain_dbi'])<1e-7
        assert r['shape_only_sensitivity_psd_dbm_hz']<=r['owner_only_victim_psd_dbm_hz']+1e-7
    for s in scenarios:
        if s['status'] in ['PASS','FAIL']:assert s['status']==('PASS' if float(s['margin_db'])>=0 else 'FAIL')
    for k in [(r['case_id'],r['tx_id'],r['rx_id'],r['victim_band']) for r in active]:
        assert len([s for s in scenarios if tuple(s[x] for x in ['case_id','tx_id','rx_id','victim_band'])==k])==5
    sar_skip_audit=[dict(location='latest_owner_analysis.py / primary S-TC and Ka branches',legacy_status='SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN / OUTSIDE_OWNER_PATTERN_DOMAIN',latest_disposition='Resolved by owner52dBi / -50dB rear / NF4; SAR_RX active numeric primary'),dict(location='complete_suppression_design.py / historical Task1 emit SAR',legacy_status='SAR_VICTIM_ANTENNA_RESPONSE_MISSING',latest_disposition='Historical intermediate only; overwritten by latest_owner_analysis; shared src unchanged'),dict(location='src/+rfscreen/+kaa/KaVictimResponse.m',legacy_status='SAR response at 25.5-27GHz missing',latest_disposition='Different frequency: fundamental Ka blocker response; not SAR9.3875-9.9125GHz victim route; retained'),dict(location='run_rfi_octave.m / historical sar_response',legacy_status='SAR_PATTERN_MISSING_NO_ABSOLUTE_RFI',latest_disposition='Historical SAR transmitter response diagnostic; not current primary; SAR_TX excluded')]
    write('sar_skip_audit.csv',sar_skip_audit)
    validation=dict(status='PASS',start_head=policy['start_head'],branch=policy['start_branch'],initial_tracked_worktree_clean=True,initial_untracked=policy['initial_untracked'],freeze_sha='8469e8903da83b6ebed014aae311f90855c31715',shared_freeze_hashes_unchanged=True,
        primary_pair_count=len(active),scenario_count=len(scenarios),additional_cst_run=False,full_wave_validated=False,unreliable_absolute_gain_used=False,normalized_shape_used_in_primary=False,sar_victim_primary_active=True,sar_primary_pair_count=24,sar_latest_peak_gain_dbi=52,sar_rear_gain_dbi=2,sar_allowable_dbm_hz=-176,cutoff_and_gain_applied_once=True,l1_realized_gain_no_extra_mismatch=True,
        tests=['unchanged L1/S-TM/ISL regression','ITU4kHz and total EIRP separation','50mm TE10 attenuation and gain counted once','all pair source/PSD/margin/required/first PASS identities','five scenario signs','unreliable gain offset cancels in shape sensitivity','SAR harmonic/generic separation','actual roles and excluded attackers','shared freeze hashes unchanged'])
    tests_path=OUT/'latest_owner_full_test_results.json'
    if tests_path.exists():validation['full_suite']=json.loads(tests_path.read_text(encoding='utf-8'))
    (OUT/'latest_owner_validation.json').write_text(json.dumps(validation,indent=2)+'\n',encoding='utf-8')
    report='# RFI 분석결과 보고서 — 최신 Owner 입력 적용\n\n## 1. Executive Summary\n\n'
    report+='**S-TC TX→SAR RX의 일반 불요방사에 필요한 추가 억제도는 64.36 dB이며, 첫 통과 시나리오는 70 dB다.** 정수 고조파는 SAR 대역과 겹치지 않지만, 일반 불요방사 영향은 별도로 계산했다. SAR 52 dBi peak gain, 후방 이득 +2 dBi, NF 4 dB와 허용 PSD −176 dBm/Hz를 적용했다.\n\n'
    report+='**Ka DLS→SAR RX는 추가 억제 9.08 dB로 Ka의 최악 경로이며, Ka→ISL RX는 6.58 dB가 필요하다. 두 경로의 첫 통과 시나리오는 40 dB다.** WR-42 유효 길이 50 mm의 차단주파수 이하 감쇠를 적용하면 GPS L1/L2/L5와 S-TM RX는 추가 억제 0 dB로 해당 PSD 기준을 충족한다. 결과는 Owner 입력과 자유공간 모델을 전제로 한다.\n\n'
    report+='S-TC→GPS L1 48.00 dB, S-TM 58.89 dB, ISL 39.24 dB는 기존 값을 유지했다. L2/L5는 Owner rescaling-only 해석을 primary로 선택하고 기존 finite-mode gain 결과를 별도 비교했다. S-TC와 Ka만 간섭원이며 ISL·SAR는 수신 피간섭원이다.\n'
    report+=tab(['간섭원','피간섭원','송신 모델','수신 PSD (dBm/Hz)','허용 PSD (dBm/Hz)','요구 추가 억제 (dB)','첫 통과','근거'],
        [['S-TC TX' if r['tx_id'].startswith('S_TM') else 'Ka DLS TX',victim(r['victim_band']),('ITU + 도파관 감쇠' if r['tx_id'].startswith('KA') else 'ITU + Owner −10 dB' if r['victim_band'] in ['L2','L5'] else 'ITU + CST + SAR 후방 이득' if r['victim_band']=='SAR' else 'ITU + CST'),fmt(r['psd_victim_0db_dbm_hz']),fmt(r['allowable_psd_dbm_hz']),fmt(r['required_additional_suppression_db']),passdesc(float(r['required_additional_suppression_db'])),'Owner 공학 가정' if r['tx_id'].startswith('KA') or r['victim_band'] in ['L2','L5','SAR'] else '기존 CST 결합'] for r in chosen])
    report+='표는 각 대역의 설치·case별 최대 수신 PSD를 나타낸다. Actual **S-TC TX = legacy S_TM_TX**, **S-TM RX = legacy S_TC_RX**다. 동일 포트 S-TC→S-TM 전달계수 미확정 경로는 CSV에 유지했다. 위 S-TM 수치는 확보된 opposite-port 경로이며 전체 시스템 적합 판정을 뜻하지 않는다.\n\n## 2. S-TC→SAR의 실제 영향\n'
    unique_sar=[next(r for r in sar if r['tx_id'].endswith(tx)) for tx in ['SBA_NADIR','SBA_ZENITH']]
    report+=tab(['간섭원','피간섭원','송신 PSD (dBm/Hz)','경로 결합 (dB)','RX 이득 (dBi)','수신 PSD (dBm/Hz)','허용 PSD (dBm/Hz)','요구 억제 (dB)'],
        [[r['actual_attacker'],'SAR RX',fmt(itu_s),fmt(float(r['port_psd_coefficient_dbm_hz'])-itu_s),'+2.00',fmt(r['victim_psd_dbm_hz']),'-176.00',fmt(r['required_additional_suppression_db'])] for r in unique_sar])
    report+='경로 결합은 SAR 수신 gain 적용 전의 S-TX SAR-band RealizedGain − FSPL이다. 기존 coefficient −113.6363/−114.1745 dBm/Hz에 Owner rear gain +2 dBi를 한 번 더했다. 수신 PSD는 각각 −111.6363/−112.1745 dBm/Hz이며 간섭 여유는 각각 −64.3637/−63.8255 dB다. 송신 RealizedGain에 이미 포함된 mismatch는 다시 적용하지 않았다.\n\n**Integer harmonic overlap: none (NO_HARMONIC_OVERLAP).** 2.25 GHz의 4차 9.0 GHz, 5차 11.25 GHz는 SAR 9.3875–9.9125 GHz 밖이다. Occupied band와 legacy 2.2–2.29 GHz tuning interval의 정수 배수 검사도 비중첩이다. 고조파 비중첩과 일반 spurious의 수신 영향은 서로 다른 결과다.\n\n## 3. Ka 불요방사와 victim-band PSD\n\n'
    report+=f'Ka DLS의 불요방사(spurious emission)는 WR-42 도파관의 차단주파수 이하 감쇠(below-cutoff waveguide attenuation)를 적용한 후 피간섭원 입력 전력밀도(victim input PSD)로 환산했다. 허용 간섭 PSD와 비교하여 간섭 여유(interference margin)와 요구 추가 억제도(required additional suppression)를 산출했다.\n\n70 W 기준 송신기 불요방사 PSD는 **{conducted:.6f} dBm/Hz**, 31 dBi reference를 포함한 방사 불요파 EIRP PSD(spurious EIRP spectral density)는 **{eirp_psd:.6f} dBm/Hz**다. 총 EIRP reference **{eirp_dbw:.6f} dBW**와 PSD를 구분한다. ITU 60 dBc / 4 kHz를 broadband-equivalent PSD로 적용했으며 discrete spur를 broadband noise로 바꾸지 않았다.\n'
    ka_worst=[max([r for r in ka if r['victim_band']==b],key=lambda r:r['victim_psd_dbm_hz']) for b in BANDS]
    report+=tab(['Interferer','Victim','TX spurious PSD (dBm/Hz)','WG attenuation (dB)','Path coupling (dB)','Victim PSD (dBm/Hz)','Allowable PSD (dBm/Hz)','Margin (dB)','Required suppression (dB)'],
        [['Ka DLS TX',victim(r['victim_band']),fmt(conducted),fmt(r['cutoff_attenuation_db']),fmt(31+r['victim_coupling_db']),fmt(r['victim_psd_dbm_hz']),fmt(r['allowable_psd_dbm_hz']),fmt(r['margin_0db_db']),fmt(r['required_additional_suppression_db'])] for r in ka_worst])
    report+='표의 경로 결합(path coupling)은 **31 dBi 송신 gain reference + 수신 방향 이득 − FSPL**이다. 송신 PSD 기준으로 표현했으므로 송신 gain을 이 열에 한 번 포함했다. EIRP PSD에서 시작하는 경우 경로 결합은 수신 방향 이득 − FSPL만 사용한다. 각 행의 감쇠는 그 행의 최대 수신 PSD 주파수에 해당한다.\n\n`PSD_victim = TX spurious PSD − A_WG + (31 dBi + G_RX − FSPL)`\n\n`margin = allowable PSD − victim PSD`, `required = max(0, −margin)`이다.\n'
    report+=tab(['피간섭원 대역','대역 상단 (GHz)','α (Np/m)','WR-42 50 mm 감쇠 (dB)'],[[victim(r['victim_band']),f"{r['band_upper_hz']/1e9:.6f}",fmt(r['alpha_np_m']),fmt(r['minimum_band_cutoff_attenuation_db'])] for r in band_rows])
    report+='WR-42 a=10.668 mm, TE10 fc=14.051015 GHz, 유효 길이 L=0.05 m다. `A_WG=8.685889638×sqrt((π/a)^2−(2πf/c)^2)×0.05`를 적용했다. 대역 상단의 값은 해당 대역에서 가장 작은 감쇠다. PSD 최대값은 전 주파수에서 감쇠와 수신 결합을 함께 평가했다.\n\n기준면: ITU conducted source envelope는 도파관 입력 상당 기준면에 배치하고, 도파관 감쇠 후 31 dBi reference를 한 번 적용했다. 이 배치는 Owner 계산 경로의 공학 가정이다. 공급사 source 규격이 이미 도파관 출력 기준이면 감쇠를 다시 적용하면 안 된다.\n\n## 4. L2/L5 두 계산 모델 비교\n'
    report+=tab(['대역','기존 finite-mode 모델 요구 (dB)','Owner rescaling-only 요구 (dB)','상대 pattern 민감도 요구 (dB)','Owner 모델 첫 통과'],[[r['victim_band'],fmt(r['current_bound_required_db']),fmt(r['owner_only_required_db']),fmt(r['shape_sensitivity_required_db']),passdesc(r['owner_only_required_db'])] for r in comparisons_band])
    report+='ITU source −49.0206 dBm/Hz에 Owner mismatch −10 dB를 적용하면 **−59.0206 dBm/Hz**다. 기존 모델은 추가 +9.0309 dBi finite-mode gain을 더했다. 이 gain은 mismatch 결정에서 도출되지 않으며 전류 체적과 고차 모드 제한이라는 추가 가정이다.\n\nPrimary는 Owner 의도에 더 직접적인 **rescaling-only**를 선택했다. Post-mismatch radiation level을 peak equivalent EIRP PSD −59.0206 dBm/Hz로 anchor하고 angular ceiling 0 dB를 적용했다. 실제 gain을 0 dBi로 측정했다는 뜻이 아니며 mismatch만으로 directivity가 정해진다는 주장도 아니다. 해당 source를 accepted power로만 해석하면 radiation gain이 추가로 필요하므로 peak-EIRP anchor는 명시적인 worker 공학 가정이다. 기존 모델은 더 보수적인 비교 결과로 보존하며 어느 쪽도 모든 가능한 방사에 대한 엄밀한 상한으로 확정하지 않는다.\n\n각 L2/L5 주파수에서 두 cut 전체의 공통 peak를 빼 상대 angular shape도 계산했다. 입사 polar angle의 네 half-cut 중 높은 값을 썼으며 raw absolute RealizedGain이나 accepted-power fraction은 link budget에 사용하지 않았다. 상대 shape 자체도 검증되지 않았으므로 primary에는 적용하지 않았다. L1은 기존 validated RealizedGain을 유지하고 mismatch −10 dB를 중복 적용하지 않았다.\n\n## 5. Receiver criterion와 필터 요구\n\n'
    report+=f'GPS −178, S-TM/ISL −177 dBm/Hz는 유지한다. SAR는 NF=4 dB, T=290 K, I/N=−6 dB다. Noise PSD {noise:.4f} dBm/Hz, allowable PSD {noise-6:.4f} dBm/Hz에서 Owner 지정 반올림 기준 **−176 dBm/Hz**를 primary로 사용했다. 이전 NF5/−175 기준을 교체했다.\n\nSAR peak gain 52 dBi는 Owner의 HPBW 기반 추정값이다. ±80° 밖 및 rear는 peak 대비 −50 dB로 절대 이득 ceiling +2 dBi다. 기존 Azimuth/Elevation HPBW 0.242294°/1.112221°와 Co reconstruction을 유지했다. Cx는 Co peak 대비 −120 dB provenance를 유지하며 별도 자기 peak로 정규화하지 않았다.\n'
    report+=tab(['TX','Worst victim','요구 억제 (dB)','첫 통과','권장 설계 목표 (dB)'],[[r['tx'],r['worst_victim'],fmt(r['required_additional_suppression_db']),passdesc(float(r['required_additional_suppression_db'])),fmt(r['recommended_design_target_db'])] for r in summary])
    report+='설계 목표는 최소 요구에 10 dB 여유를 더해 10 dB 단위로 올림한 계획값이다. 규격이나 실제 필터 보증값은 아니다. TX 불요방사 억제와 RX blocker rejection·diplexer isolation·preselector는 서로 다른 요구다.\n'
    report+=tab(['TX→Victim','0 dB','40 dB','60 dB','70 dB','80 dB'],[[('S-TC' if r['tx_id'].startswith('S_TM') else 'Ka')+'→'+victim(r['victim_band'])]+[fmt(float(r['margin_0db_db'])+f)+' / '+('충족' if float(r['margin_0db_db'])+f>=0 else '초과') for f in [0,40,60,70,80]] for r in chosen])
    report+='각 cell은 margin(dB) / 해당 모델의 PSD 기준 판정이다.\n\n## 6. 입력과 모델 한계\n\nKa의 guide upstream 기준면, 실제 feed/discontinuity/cable 누설, 31 dBi 방사 reference와 자유공간 근거리 결합은 미검증 가정이다. 도파관 감쇠는 ordinary filter loss나 실측 isolation으로 해석하지 않는다. SAR gain/rear envelope도 Owner 추정값이며 원본 full 3D pattern은 아니다. L2/L5 radiation anchor, 동일 포트 전달계수, 실제 장비 emission measurement, 동시 간섭 합산과 receiver blocking/P1dB/IIP3는 추가 검증이 필요하다.\n\n## 7. Secondary blocker\n\n기존 S-TC→GPS −21.317 dBm, S-TC→opposite S-TM −32.288 dBm은 secondary로 유지했다. 이를 victim-band PSD나 TX 추가 억제량으로 환산하지 않았다. Receiver 전단 보호 판정은 해당 blocking·compression 기준 확보 후 수행한다.\n\n## 8. Appendix / provenance와 검증\n\n'
    report+=f'[ITU-R SM.329-13]({ITU}) §4.1 / §4.2 Table2 space stations 및 [RR Appendix3 TableI]({RR})의 source를 유지했다. 4 kHz broadband-equivalent와 discrete spur의 구분은 기존 독립 source evidence를 따른다.\n\n'
    report+='시작 HEAD `16dde560b192841656f6d65e91d849e46c323d2f`, branch `codex/rfi-emission-8469e89`, freeze `8469e8903da83b6ebed014aae311f90855c31715`. 시작 tracked tree는 clean이었고 기존 untracked standards/만 있었다. Shared src/data/tests를 변경하지 않았고 추가 CST는 실행하지 않았다.\n\nProvenance: Ka OWNER_ENGINEERING_ASSUMPTION / WAVEGUIDE_BELOW_CUTOFF_BOUND / NOT_FULL_WAVE_VALIDATED; SAR OWNER_ENGINEERING_ESTIMATE_FROM_HPBW / OWNER_ENGINEERING_REAR_ENVELOPE. L2/L5 비교 CSV의 CURRENT_BOUND_ROUTE / OWNER_RESCALING_ONLY_ROUTE는 내부 조회 명칭이다. 과거 gain-bound와 zero-cutoff 결과는 당시 정책의 역사적 기록이며 최신 primary에는 사용하지 않는다.\n\n[Owner 입력](emission_inputs/latest_owner_policy.json), [L2/L5 비교](lband_route_comparison.csv), [Ka pair](ka_cutoff_pair_requirements.csv), [Ka band](ka_cutoff_band_results.csv), [SAR 기준](sar_receiver_owner_baseline.csv), [S→SAR 결과](stc_sar_spurious_results.csv), [SAR pattern](sar_reference_envelope.csv), [harmonic 검사](sar_harmonic_overlap.csv), [전체 pair](all_pair_required_suppression.csv), [scenario](design_filter_scenarios.csv), [검증](latest_owner_validation.json), [full test log](latest_owner_full_tests.log), [SAR skip 감사](sar_skip_audit.csv)을 참조한다. 원본 MAT/1601-point vectors는 읽거나 반출하지 않았다. 재현은 `python output/codex/complete_suppression_design.py`다.\n'
    log=OUT/'latest_owner_full_tests.log'
    if log.exists():report+='\n전체 test 실행 결과: '+next((l.strip() for l in log.read_text(encoding='utf-8').splitlines() if 'Passed:' in l),'log 참조')+'; 별도 engineering validation PASS. 최초 실행의 Windows xcopy 임시 파일 복사 오류는 test 프로세스 PATH에 Git cp.exe를 추가해 해결했다. 공유 test나 계산 코드는 수정하지 않았다.\n'
    (OUT/'결과보고서.md').write_text(report,encoding='utf-8')
    for link in re.findall(r'\]\(([^)]+)\)',report):
        if not link.startswith('https:'):assert (OUT/link).exists(),link
    print(json.dumps(validation,indent=2))
    print('Latest worst requirements:',[(r['actual_attacker'],r['victim_band'],r['required_additional_suppression_db']) for r in chosen])

if __name__=='__main__':main()
