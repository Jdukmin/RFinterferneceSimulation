"""Owner scope, SAR reconstruction and cutoff route; no CST/MAT/Octave execution."""
from pathlib import Path
import csv, json, math, hashlib, bisect, shutil, re
from collections import defaultdict
from complete_suppression_design import OUT, ROOT, read, read_data, write, actual, fmt, first, passdesc, tab, ROLE, BAND
C=299792458.0
WG_SOURCE='https://www.ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/d9425aa2b1acd0c1fc121965ad7eafec_MIT6_013S09_lec16.pdf'

def anchors(axis):
    a=dict(axis['samples']);a[axis['half_power_angle_deg']]=-3.;a[axis['first_null_angle_deg']]=axis['first_null_db'];a[axis['maximum_sidelobe_angle_deg']]=axis['maximum_sidelobe_db']
    return sorted(a.items())

def envelope(axis,angle):
    x=abs(angle);pts=anchors(axis)
    if x>80:return None
    for xx,y in pts:
        if abs(x-xx)<1e-10:return y
    if x>pts[-1][0]:return axis['maximum_sidelobe_db'] # unsampled 60..80: declared sidelobe ceiling, no invented low tail
    j=bisect.bisect_left([p[0] for p in pts],x);(x0,y0),(x1,y1)=pts[j-1:j+1]
    if x<=axis['first_null_angle_deg']:return y0+(y1-y0)*(x-x0)/(x1-x0)
    return max(y0,y1) # upper-envelope interpolation, not invented nulls

def rectangular_cutoff(f,a,length):
    if a is None:return (None,)*4
    if a<=0 or (length is not None and length<0):raise ValueError('positive broad wall / nonnegative physical effective length required')
    fc=C/(2*a);alpha=math.sqrt(max(0,(math.pi/a)**2-(2*math.pi*f/C)**2))
    return fc,f/fc,alpha,20/math.log(10)*alpha*length if length is not None else None

def unit(v):
    n=math.sqrt(sum(x*x for x in v));return [x/n for x in v]
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def frame(normal):
    # Boresight is +X antenna; same panel normal. Transverse roll is not approved SAR axes.
    x=unit(normal);ref=[0,0,1] if abs(x[2])<.99 else [0,1,0];y=unit(cross(ref,x));z=cross(x,y);return x,y,z
def interp(pts,x):
    j=bisect.bisect_left([p[0] for p in pts],x)
    if j<len(pts) and pts[j][0]==x:return pts[j][1]
    if j==0 or j==len(pts):raise ValueError('no extrapolation')
    (x0,y0),(x1,y1)=pts[j-1:j+1];return y0+(y1-y0)*(x-x0)/(x1-x0)

def plot_pattern(pattern,policy):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,axes=plt.subplots(2,2,figsize=(12,7))
    for i,name in enumerate(['azimuth','elevation']):
        rr=[r for r in pattern if r['axis']==name];xs=[r['angle_deg'] for r in rr];ys=[r['co_normalized_db'] for r in rr]
        nodes=anchors(policy[name]);ax=[-p[0] for p in nodes[::-1]]+[p[0] for p in nodes];ay=[p[1] for p in nodes[::-1]]+[p[1] for p in nodes]
        for j in [0,1]:
            a=axes[i,j];a.plot(xs,ys,label='Engineering envelope',linewidth=1);a.scatter(ax,ay,s=18,color='darkorange',label='Owner anchors',zorder=3)
            a.axhline(-120,color='gray',linestyle='--',label='Cx / Co peak floor')
            a.set_xlim((-0.7,0.7) if i==0 and j==0 else (-2.5,2.5) if j==0 else (-80,80))
            a.set_ylim((-45,2) if j==0 else (-125,2));a.grid(alpha=.3);a.set_title(name.title()+(' main beam' if j==0 else ' supplied angular domain'))
            a.set_xlabel('Angle (degrees)');a.set_ylabel('Normalized Co (dB)');a.legend(fontsize=8)
    fig.suptitle('Owner SAR reference reconstruction: symmetric cuts; absolute gain unknown; no MAT export')
    fig.tight_layout();fig.savefig(OUT/'sar_reference_envelope.png',dpi=150);plt.close(fig)

def main():
    policy=json.loads((OUT/'emission_inputs/task2_owner_scope.json').read_text(encoding='utf-8'))
    for r in read('emission_inputs/freeze_input_hashes.csv'):assert hashlib.sha256((ROOT/r['path']).read_bytes()).hexdigest()==r['sha256']
    # Snapshot freshly generated Task 1 tables before replacing their current scope.
    legacy=OUT/'legacy_task1';legacy.mkdir(exist_ok=True)
    fresh=any(r['tx_id'].startswith('ISL_X_TX') for r in read('all_pair_required_suppression.csv'))
    if fresh:
        for name in ['all_pair_required_suppression.csv','main_design_results.csv','design_filter_scenarios.csv','filter_design_summary.csv']:
            shutil.copy2(OUT/name,legacy/name)
    old=read('legacy_task1/all_pair_required_suppression.csv');old_scenarios=read('legacy_task1/design_filter_scenarios.csv')
    scope=[]
    for tx in ['S_TM_TX','KA_DLS_TX','ISL_X_TX','SAR_X_TX']:
        for v in ['GPS','S-TM','ISL','SAR']:
            scope.append(dict(actual_attacker=ROLE.get(tx,'SAR TX'),legacy_tx_id=tx,victim=v,
                primary_scope='EXCLUDED_VICTIM_ONLY' if tx in policy['excluded_attackers'] else 'WAVEGUIDE_BELOW_CUTOFF_BOUND' if tx=='KA_DLS_TX' else 'ANALYZE_GENERIC_SPURIOUS',
                harmonic_route='SEPARATE_HARMONIC_OVERLAP_TEST' if tx=='S_TM_TX' and v=='SAR' else 'NOT_HARMONIC_ANALYSIS'))
    write('task2_role_matrix.csv',scope)
    # Owner anchors and a generated grid. This is not the withheld original 1601-point vectors.
    pattern=[];anchor_rows=[]
    for name in ['azimuth','elevation']:
        axis=policy[name];grid={i*.02 for i in range(-150,151)}|{float(i) for i in range(-80,81)}
        for x,y in anchors(axis):grid|={x,-x};anchor_rows.append(dict(axis=name,absolute_angle_deg=x,co_normalized_db=y,provenance=policy['sar_pattern_source']))
        for x in sorted(grid):
            pattern.append(dict(axis=name,angle_deg=x,co_normalized_db=envelope(axis,x),cx_relative_co_peak_db=-120,
                fidelity='ENGINEERING_RECONSTRUCTION',provenance='OWNER_EXTRACTED_FROM_K8_SAR_PATTERN_MAT; NOT_FULL_1601_POINT_EXPORT',
                interpolation='PIECEWISE_DB_MAIN_BEAM' if abs(x)<=axis['first_null_angle_deg'] else 'DECLARED_SIDELobe_CEILING_UNSAMPLED_TAIL' if abs(x)>60 else 'ADJACENT_HIGHER_UPPER_ENVELOPE',
                cross_pol_status='CROSS_POL_NEGLIGIBLE_FOR_CURRENT_SCREENING'))
    write('sar_reference_envelope.csv',pattern);write('sar_owner_pattern_anchors.csv',anchor_rows)
    plot_pattern(pattern,policy)
    # Nominal occupied TX band harmonics and full legacy tuning/allocation envelope are distinct tests.
    B={r['victim_band']:r for r in read_data('data/rfi_psd/receiver_baseline.csv')}
    sar_lo=float(B['SAR']['tuning_lo_mhz'])*1e6;sar_hi=float(B['SAR']['tuning_hi_mhz'])*1e6
    harmonics=[]
    for tag,lo,hi in [('NOMINAL_2P25GHz_2P7MHz',2.24865e9,2.25135e9),('LEGACY_2200_2290MHz_TUNING_RANGE',2.2e9,2.29e9)]:
        for n in range(1,math.ceil(sar_hi/lo)+2):
            l,h=n*lo,n*hi;overlap=max(0,min(h,sar_hi)-max(l,sar_lo))
            harmonics.append(dict(carrier_case=tag,harmonic_order=n,harmonic_lo_hz=l,harmonic_hi_hz=h,sar_lo_hz=sar_lo,sar_hi_hz=sar_hi,
                overlap_hz=overlap,status='HARMONIC_OVERLAP' if max(l,sar_lo)<=min(h,sar_hi) else 'NO_HARMONIC_OVERLAP',
                bandwidth_rule='n times input occupied/tuning interval; no arbitrary nonlinear spectral broadening'))
    write('sar_harmonic_overlap.csv',harmonics)
    # Receiver orientation/absolute gain are not inferred from complex-field magnitude.
    installations={r['antenna_id']:r for r in read_data('data/spacecraft/simplified_spacecraft_v1/antenna_installations.csv')}
    panels={r['panel_id']:r for r in read_data('data/spacecraft/simplified_spacecraft_v1/panels.csv')}
    def position(i):return [float(installations[i][k])/1000 for k in ['x_mm','y_mm','z_mm']]
    def normal(i):return [float(panels[installations[i]['panel_id']][k]) for k in ['n_x','n_y','n_z']]
    metadata=json.loads((ROOT/'data/antenna_port_response_cst/provenance.json').read_text())
    cache={}
    def st_gain(f,d):
        # Unchanged two-cut dB interpolation; max over the transverse roll basis removes an unconfirmed roll.
        cuts=[r for r in metadata['cuts'] if r['family']=='S' and r['band']=='SAR' and r['quantity']=='RealizedGain']
        assert all(r['normalization_reliable'] for r in cuts)
        theta=math.degrees(math.acos(max(-1,min(1,d))));vals=[]
        for freq in sorted({r['frequency_hz'] for r in cuts}):
            vv=[]
            for cut in cuts:
                if cut['frequency_hz']!=freq:continue
                p=ROOT/cut['path']
                if cut['path'] not in cache:cache[cut['path']]=[(float(v['theta']),float(v['gain'])) for v in csv.DictReader(p.open())]
                vv.extend([interp(cache[cut['path']],theta),interp(cache[cut['path']],360-theta)])
            vals.append((freq,max(vv)))
        return interp(vals,f)
    sar=[];cases=sorted({r['case_id'] for r in old});source=-49.020599913279625
    for tx in ['SBA_NADIR','SBA_ZENITH']:
        delta=[b-a for a,b in zip(position(tx),position('SAR_ANT'))];dist=math.sqrt(sum(x*x for x in delta));u=unit(delta)
        tx_theta_cos=dot(u,normal(tx));rx_theta=math.degrees(math.acos(max(-1,min(1,dot([-x for x in u],normal('SAR_ANT'))))))
        # Both actual directions exceed the supplied +/-80 deg domain. No backside extrapolation.
        samples=[]
        for j in range(161):
            f=sar_lo+(sar_hi-sar_lo)*j/160;gain=st_gain(f,tx_theta_cos);loss=20*math.log10(4*math.pi*dist*f/C)
            samples.append((source+gain-loss,f,gain,loss))
        coeff,f,gt,loss=max(samples)
        for case in cases:
            sar.append(dict(case_id=case,tx_id='S_TM_TX@'+tx,rx_id='SAR_X_RX@SAR_ANT',actual_attacker=actual('S_TM_TX@'+tx),actual_victim='SAR RX',victim_band='SAR',
                route='GENERIC_SPURIOUS_NOT_HARMONIC',source_psd_dbm_hz=source,tx_sar_band_gain_dbi=gt,distance_m=dist,worst_frequency_hz=f,fspl_db=loss,
                sar_polar_off_axis_deg=rx_theta,normalized_directional_gain_db=None,sar_absolute_peak_gain_dbi=policy['sar_absolute_peak_gain_dbi'],
                port_psd_coefficient_dbm_hz=coeff,port_formula='coefficient + SAR_peak_gain_dBi + normalized_directional_gain_dB',
                allowable_psd_dbm_hz=-175,required_formula='max(0, coefficient + SAR_peak_gain_dBi + normalized_directional_gain_dB + 175)',
                status='SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN; SAR_DIRECTION_OUTSIDE_OWNER_PATTERN_DOMAIN',
                model_fidelity='FREE_SPACE_TX_REALIZEDGAIN_ENVELOPE; RX_RECONSTRUCTED_NORMALIZED_ONLY',
                source_provenance='RR Appendix3 / SM329; 5W -13dBm/4kHz',tx_gain_provenance='frozen S/SAR reliable CST cuts; conservative max over XZ/YZ half cuts; frequency interpolation',
                sar_provenance=policy['sar_pattern_source']))
    write('stc_sar_spurious_results.csv',sar)
    # Actual rectangular hardware remains unconfirmed; TE10 is supported but no invented WR choice/length.
    wg=policy['actual_waveguide_type'];a=policy['rectangular_broad_wall_a_m'];length=policy['effective_below_cutoff_length_m']
    eirp_dbw=10*math.log10(policy['ka_power_w'])+policy['ka_owner_gain_reference_dbi'];eirp_dbm=eirp_dbw+30
    # Keep the previously authorized ITU spurious envelope. Total EIRP is NOT divided alone by an RBW.
    itu_atten=min(43+10*math.log10(policy['ka_power_w']),60)
    eirp_psd=eirp_dbm-itu_atten-10*math.log10(4000)
    ka=[]
    for band in ['L1','L2','L5','S_TC','ISL','SAR']:
        b=B[band];f=float(b['tuning_hi_mhz'])*1e6
        fc,ratio,alpha,atten=rectangular_cutoff(f,a,length)
        ka.append(dict(victim_band=band,actual_waveguide_type=wg,broad_wall_a_m=a,te10_cutoff_hz=fc,
            victim_frequency_hz=f,victim_frequency_over_cutoff=ratio,below_cutoff_alpha_np_m=alpha,effective_length_m=length,
            below_cutoff_attenuation_db_per_mm=20/math.log(10)*alpha/1000 if alpha is not None else None,
            total_cutoff_attenuation_db=atten,source_max_eirp_dbw=eirp_dbw,source_max_eirp_dbm=eirp_dbm,
            attenuated_eirp_total_dbm=eirp_dbm-atten if atten is not None else None,
            source_eirp_psd_dbm_hz=eirp_psd,victim_coupling_db=None,victim_psd_dbm_hz=None,required_additional_suppression_db=None,
            status='EFFECTIVE_WAVEGUIDE_LENGTH_UNCONFIRMED; ZERO_CUTOFF_CREDIT_SCREENING_AVAILABLE',
            provenance='WAVEGUIDE_BELOW_CUTOFF_BOUND; ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED',
            dimension_length_provenance=policy['waveguide_provenance'],source_provenance='OWNER_70W_31dBi_SCREENING_REFERENCE_NOT_HARDWARE_MAX_GAIN',
            spectral_note='Existing ITU 60dBc/4kHz spurious envelope + owner31dBi reference; no direct total-EIRP division. Any length credit additionally requires upstream spectral reference plane confirmation.',equation='fc=c/(2a); alpha=sqrt((pi/a)^2-(2pi*f/c)^2); A=8.685889638*alpha*L'))
    write('ka_cutoff_band_results.csv',ka)
    # Existing victim transfer allows a quantitative requirement on radiated density even with no guide/source PSD.
    detail=read('victim_band_coupling.csv');groups=defaultdict(list)
    for r in detail:
        if r['tx_id'].startswith('KA_DLS_TX'):groups[(r['case_id'],r['tx_id'],r['rx_id'],r['victim_band'])].append(r)
    constraints=[]
    for key,rr in groups.items():
        limit=-178 if key[3].startswith('L') else -177
        peak=max(rr,key=lambda r:eirp_psd+float(r['radiated_transfer_db'])-(rectangular_cutoff(float(r['frequency_hz']),a,length)[3] or 0))
        tr=float(peak['radiated_transfer_db']);fc,ratio,alpha,atten=rectangular_cutoff(float(peak['frequency_hz']),a,length)
        port=eirp_psd+tr-(atten if atten is not None else 0);margin=limit-port;need=max(0,-margin)
        length_requirement=max(max(0,eirp_psd+float(v['radiated_transfer_db'])-limit)/(rectangular_cutoff(float(v['frequency_hz']),a,None)[2]*8.685889638065036/1000) for v in rr)
        constraints.append(dict(case_id=key[0],tx_id=key[1],rx_id=key[2],actual_attacker=actual(key[1]),actual_victim=actual(key[2]),victim_band=key[3],
            worst_frequency_hz=peak['frequency_hz'],victim_coupling_db=tr,allowable_psd_dbm_hz=limit,maximum_radiated_psd_dbm_hz=limit-tr,
            source_max_eirp_total_dbm=eirp_dbm,source_psd_dbm_hz=eirp_psd,cutoff_attenuation_db=atten,cutoff_credit_applied_db=atten if atten is not None else 0,
            victim_psd_dbm_hz=port,margin_0db_db=margin,required_additional_suppression_db=need,first_passing_scenario=first(need),
            minimum_effective_length_for_no_additional_filter_mm=length_requirement,
            required_formula='max over frequency max(0, EIRP_PSD_source - 8.685889638*alpha(f)*L_eff + transfer(f) - limit)',
            status='ENGINEERING_ZERO_CUTOFF_CREDIT_UPPER_SCREEN_LENGTH_UNKNOWN',model_fidelity='WAVEGUIDE_BELOW_CUTOFF_BOUND; ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED'))
    write('ka_cutoff_pair_requirements.csv',constraints)
    for band_row in ka:
        pool=[r for r in constraints if r['victim_band']==band_row['victim_band']]
        if pool:
            worst=max(pool,key=lambda r:r['required_additional_suppression_db'])
            band_row.update(victim_coupling_db=worst['victim_coupling_db'],victim_psd_dbm_hz=worst['victim_psd_dbm_hz'],
                required_additional_suppression_db=worst['required_additional_suppression_db'])
    write('ka_cutoff_band_results.csv',ka)
    route_comparison=[]
    for band in ['L1','L2','L5','S_TC','ISL']:
        previous=[r for r in read('conditional_bound_required_suppression.csv') if r['tx_id'].startswith('KA_DLS_TX') and r['victim_band']==band]
        old_req=max(float(r['required_additional_suppression_db']) for r in previous)
        current_req=max(r['required_additional_suppression_db'] for r in constraints if r['victim_band']==band)
        route_comparison.append(dict(victim_band=band,legacy_gain_bound_required_db=old_req,new_cutoff_zero_credit_required_db=current_req,
            new_minus_legacy_db=current_req-old_req,primary_selection='OWNER_WR42_EIRP_ROUTE_NO_CUTOFF_CREDIT',
            legacy_selection='SENSITIVITY_ONLY_NOT_PRIMARY',comparison_note='Different TX radiation envelope; neither value proves actual waveguide leakage; no full-wave simulation'))
    write('ka_route_comparison.csv',route_comparison)
    # Canonical primary tables no longer contain ISL/SAR attackers or the KAA low-frequency gain-bound route.
    active=[r for r in old if r['tx_id'].startswith('S_TM_TX')]
    sar_lookup={(r['case_id'],r['tx_id']):r for r in sar}
    for r in active:
        if r['victim_band']=='SAR':
            r['model_fidelity']='SAR_OWNER_RECONSTRUCTION_NORMALIZED_ONLY';r['missing_reason']='SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN; SAR_DIRECTION_OUTSIDE_OWNER_PATTERN_DOMAIN'
            s=sar_lookup[(r['case_id'],r['tx_id'])]
            r['tx_victim_gain_dbi']=s['tx_sar_band_gain_dbi'];r['distance_m']=s['distance_m'];r['worst_frequency_hz']=s['worst_frequency_hz']
    template=old[0]
    for k in constraints:
        r={key:'' for key in template};r.update({key:k[key] for key in ['case_id','tx_id','rx_id','actual_attacker','actual_victim','victim_band']})
        r.update(actual_victim_band=BAND[k['victim_band']],allowable_psd_dbm_hz=k['allowable_psd_dbm_hz'],coupling_db=k['victim_coupling_db'],
            itu_unwanted_source_psd_dbm_hz=k['source_psd_dbm_hz'],derived_eirp_psd_dbm_hz=k['source_psd_dbm_hz'],
            psd_victim_0db_dbm_hz=k['victim_psd_dbm_hz'],margin_0db_db=k['margin_0db_db'],required_additional_suppression_db=k['required_additional_suppression_db'],
            confidence='ENGINEERING_BOUND_NO_CUTOFF_CREDIT_LENGTH_UNKNOWN',model_fidelity='WAVEGUIDE_BELOW_CUTOFF_BOUND',evaluation='KA_CUTOFF_PRIMARY',first_passing_scenario=k['first_passing_scenario'],
            missing_reason=k['status'],source_reference_plane='RADIATED_EIRP_PSD; ITU_SPURIOUS_EQUIVALENT_PLUS_OWNER31DBI',screening_design_class=passdesc(k['required_additional_suppression_db']))
        active.append(r)
    # Explicit SAR Ka victim rows retain the missing normalized-domain / peak / waveguide requirements.
    for r in old:
        if r['tx_id'].startswith('KA_DLS_TX') and r['victim_band']=='SAR':
            rr=dict(r);rr.update(model_fidelity='WAVEGUIDE_BELOW_CUTOFF_BOUND',source_reference_plane='RADIATED_EIRP_PSD; ITU_SPURIOUS_EQUIVALENT_PLUS_OWNER31DBI',evaluation='KA_CUTOFF_PRIMARY',missing_reason='EFFECTIVE_LENGTH_UNCONFIRMED; SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN')
            for name in ['itu_unwanted_source_psd_dbm_hz','tx_victim_gain_dbi','derived_eirp_psd_dbm_hz']:rr[name]=''
            rr['itu_unwanted_source_psd_dbm_hz']=eirp_psd;rr['derived_eirp_psd_dbm_hz']=eirp_psd
            active.append(rr)
    write('all_pair_required_suppression.csv',active);write('task2_primary_pairs.csv',active)
    scenarios=[r for r in old_scenarios if r['tx_id'].startswith('S_TM_TX') and r['evaluation']!='CONDITIONAL_BOUND']
    stemplate=old_scenarios[0]
    for r in active:
        if not r['tx_id'].startswith('KA_DLS_TX'):continue
        for fdb in [0,40,60,70,80]:
            s={k:'' for k in stemplate};s.update({k:r[k] for k in ['case_id','tx_id','rx_id','actual_attacker','actual_victim','victim_band']})
            finite=r['psd_victim_0db_dbm_hz'] not in ['',None] and math.isfinite(float(r['psd_victim_0db_dbm_hz']))
            s.update(evaluation='KA_CUTOFF_PRIMARY',filter_db=fdb,status=('PASS' if float(r['margin_0db_db'])+fdb>=0 else 'FAIL') if finite else 'UNKNOWN',
                victim_psd_dbm_hz=float(r['psd_victim_0db_dbm_hz'])-fdb if finite else '',margin_db=float(r['margin_0db_db'])+fdb if finite else '',
                required_additional_suppression_db=r['required_additional_suppression_db'],first_passing_scenario=r['first_passing_scenario'],confidence=r['confidence']);scenarios.append(s)
    write('design_filter_scenarios.csv',scenarios)
    chosen=[]
    for tx in ['S_TM_TX','KA_DLS_TX']:
        for band in ['L1','L2','L5','S_TC','ISL','SAR']:
            pool=[r for r in active if r['tx_id'].startswith(tx) and r['victim_band']==band]
            finite=[r for r in pool if r['required_additional_suppression_db'] not in ['',None] and math.isfinite(float(r['required_additional_suppression_db']))]
            chosen.append(max(finite,key=lambda r:float(r['required_additional_suppression_db'])) if finite else pool[0])
    write('main_design_results.csv',chosen)
    summary=[r for r in read('legacy_task1/filter_design_summary.csv') if r['tx']=='S-TC TX']
    k=max(constraints,key=lambda r:r['required_additional_suppression_db'])
    summary.append(dict(tx='Ka DLS TX',scope='WAVEGUIDE_BELOW_CUTOFF_BOUND_ZERO_CREDIT',worst_victim=actual(k['rx_id']),required_additional_suppression_db=k['required_additional_suppression_db'],first_passing_scenario=k['first_passing_scenario'],recommended_design_target_db='',unresolved_primary_pair_count=72,confidence='EFFECTIVE_LENGTH_AND_UPSTREAM_SOURCE_PLANE_UNCONFIRMED; SAR_GAIN_UNKNOWN'))
    write('filter_design_summary.csv',summary)
    exclusions=[dict(tx_id='ISL_X_TX',actual_attacker='ISL TX',reason='OWNER_TASK2_VICTIM_ONLY; legacy results archived; not primary'),dict(tx_id='SAR_X_TX',actual_attacker='SAR TX',reason='OWNER_TASK2_VICTIM_ONLY')]
    write('task2_scope_exclusions.csv',exclusions)
    report='''# RFI 설계 보고서 — Task 2 scope 및 SAR/ISL victim-only

## 1. Executive Summary

**Primary attacker는 S-TC TX와 Ka DLS TX뿐이다. ISL과 SAR는 victim only다.** S-TC → ISL은 victim PSD −137.7596 dBm/Hz, 최소 추가 억제 39.2410 dB, 첫 통과 40 dB다. S-TC → GPS L1/L2/L5의 기존 48.00/81.19/81.61 dB 결과를 유지한다.

S-TC → SAR의 정수 고조파는 SAR band와 겹치지 않는다. 일반 spurious는 별도 경로이며, normalized SAR envelope를 생성했으나 절대 peak gain과 실제 입사 방향의 side/back 응답이 없어 최종 PSD·억제 요구는 보류다.

Ka는 owner 지정 WR-42 / 70 W / 31 dBi reference를 사용한다. TE10 cutoff는 14.051 GHz, 총 EIRP reference는 49.451 dBW다. 유효 길이가 미확정이므로 감쇠는 dB/mm와 길이의 곱으로 표시하고, primary screening에는 cutoff credit을 주지 않았다. 기존 ITU spurious envelope 기반의 0-credit PSD 결과를 함께 제공한다. 이전 KAA 저주파 gain-bound는 sensitivity로만 보존했다.

'''
    report+=tab(['Attacker','GPS','S-TM RX','ISL RX','SAR RX'],[['S-TC TX','분석','분석','분석','generic spurious / harmonic 분리'],['Ka DLS TX','cutoff route','cutoff route','cutoff route','cutoff route 보류'],['ISL TX','제외','제외','제외','제외'],['SAR TX','제외','제외','제외','제외']])
    st=[r for r in chosen if r['tx_id'].startswith('S_TM_TX') and r['victim_band']!='SAR']
    report+=tab(['S-TC TX victim','Victim PSD (dBm/Hz)','Limit (dBm/Hz)','0 dB margin (dB)','Required (dB)','First PASS'],[['S-TM RX' if r['victim_band']=='S_TC' else 'ISL RX' if r['victim_band']=='ISL' else 'GPS '+r['victim_band'],fmt(r['psd_victim_0db_dbm_hz']),fmt(r['allowable_psd_dbm_hz']),fmt(r['margin_0db_db']),fmt(r['required_additional_suppression_db']),passdesc(float(r['required_additional_suppression_db']))] for r in st])
    report+='Actual S-TC TX의 legacy ID는 `S_TM_TX`, S-TM RX는 `S_TC_RX`다. L2/L5는 owner −10 dB mismatch와 기존 radiation envelope의 engineering bound이며 신뢰 불가 CST absolute gain은 사용하지 않는다. [Task 1 source·결합 근거](task1_lband_summary.csv)를 보존한다.\n\n## 2. SAR reference pattern과 고조파 판정\n\n'
    report+=tab(['Cut','HPBW (°)','3 dB points (°)','First null','Maximum sidelobe'],[['Azimuth','0.242294','±0.121147','−39.083 dB @ ±0.3°','−13.565 dB @ ±0.4°'],['Elevation','1.112221','±0.556111','−31.241 dB @ ±1.3°','−13.270 dB @ ±1.8°']])
    report+='Owner 추출 Co 값으로 대칭 normalized envelope를 생성했다. Main beam은 exact half-power/null/sample anchors를 지나는 dB 선형 모델, side 영역은 adjacent higher upper envelope다. 60–80°의 미제공 tail은 제공 maximum sidelobe ceiling으로 덮었고 ±80° 밖은 외삽하지 않는다. 샘플만으로 모든 미관측 null/lobe를 복원하거나 true 3D로 확정하지 않는다. CSV는 evaluator 함수 `envelope(axis, angle)`의 engineering sampling snapshot이며 side 영역을 CSV 점 사이 선형 보간으로 다시 낮추면 안 된다.\n\nCx는 Co peak 대비 −120 dB floor와 XPD 120 dB provenance를 유지하고 primary에서는 Co만 사용한다. Cx 자기 peak로 normalization하지 않았다. 248.7072는 complex-field magnitude이며 dBi로 변환하지 않았다. 원본 MAT이나 원본 1601-point vectors는 읽거나 반출하지 않았다. 생성 CSV는 별도 engineering grid다. Elevation half-power 좌표로 계산한 1.112222°와 제공 HPBW 1.112221°의 차이 0.000001°는 입력 반올림 차이로 보존한다.\n\n**Harmonic-only: NO_HARMONIC_OVERLAP.** Nominal 2.25 GHz의 4차는 9.0 GHz, 5차는 11.25 GHz로 SAR 9.3875–9.9125 GHz 밖이다. Nominal occupied band 및 legacy 2.2–2.29 GHz tuning interval을 정수 배수로 확장한 검사도 겹치지 않는다. 이는 generic spurious가 없다는 뜻이 아니다.\n\n## 3. S-TC → SAR generic spurious\n\n'
    uniq=[sar[i] for i in [0,len(cases)]]
    report+=tab(['TX installation','거리 (m)','SAR polar angle (°)','Port coefficient (dBm/Hz)','판정'],[[r['actual_attacker'],fmt(r['distance_m']),fmt(r['sar_polar_off_axis_deg']),fmt(r['port_psd_coefficient_dbm_hz']),'절대 gain·입사 방향 응답 미확보'] for r in uniq])
    report+='계수 C는 ITU source −49.0206 dBm/Hz + 신뢰 가능한 S/SAR CST RealizedGain cut envelope − FSPL이다. `PSD_port = C + G_SAR_peak + P_normalized`, `Required = max(0, C + G_SAR_peak + P_normalized + 175)`로 필요한 입력을 분리했다. P_normalized나 G_peak에 임의 0 dBi를 넣지 않는다. SAR boresight는 frozen Panel 1 normal reference이며 실제 roll/scan도 확정되지 않았다. 두 실제 경로의 polar angle은 제공 ±80° 범위를 벗어난다. SAR −175 dBm/Hz criterion은 기존 NF=5 / I/N=−6 engineering baseline이다.\n\n## 4. S-TC → ISL 결과와 scenario\n\n'
    isl=next(r for r in st if r['victim_band']=='ISL')
    report+='S antenna @ ISL 및 ISL receiver @ ISL의 신뢰 가능한 frozen RealizedGain 결합을 그대로 사용했다. 기준은 −177 dBm/Hz다. TX spectral suppression과 receiver blocker rejection은 별개다.\n'
    report+=tab(['추가 TX 억제 (dB)','Margin (dB)','판정'],[[v,fmt(float(isl['margin_0db_db'])+v),'기준 충족' if float(isl['margin_0db_db'])+v>=0 else '기준 초과'] for v in [0,40,60,70,80]])
    report+='\n## 5. Ka maximum-EIRP / cutoff route\n\n'
    report+=f'70 W = {10*math.log10(70):.6f} dBW, owner 31 dBi reference와 합쳐 **{eirp_dbw:.6f} dBW = {eirp_dbm:.6f} dBm 총 EIRP**다. 31 dBi는 minimum/nominal reference이며 확인된 hardware maximum gain이 아니다. 따라서 owner screening reference와 실제 maximum 보증을 구분한다.\n\n'
    report+=f'Owner 후속 지시에 따라 **WR-42, a=10.668 mm, b=4.318 mm, TE10 fc={C/(2*a)/1e9:.6f} GHz**를 적용했다. [제조사 치수 도면]({policy["waveguide_dimension_source"]})으로 내부 치수를 확인했다. L은 actual effective evanescent length이며 아직 미확정이다. 아래는 각 대역 상단 주파수에서의 최소 dB/mm다.\n'
    report+=tab(['Victim band','Band upper (GHz)','f / fc','α (Np/m)','Attenuation (dB/mm)','L_eff (mm)','Total cutoff (dB)'],[[BAND[r['victim_band']],fmt(r['victim_frequency_hz']/1e9),f"{r['victim_frequency_over_cutoff']:.6f}",fmt(r['below_cutoff_alpha_np_m']),f"{r['below_cutoff_attenuation_db_per_mm']:.6f}",'미확정',f"{r['below_cutoff_attenuation_db_per_mm']:.6f} × L_mm"] for r in ka])
    report+=f'[TE10 cutoff 식의 근거]({WG_SOURCE}): air-filled rectangular guide에서 `fc=c/(2a)`, `alpha=sqrt((pi/a)^2-(2pi*f/c)^2)`, `A_cutoff=8.685889638*alpha*L_eff`다. 이는 **WAVEGUIDE_BELOW_CUTOFF_BOUND / ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED**이며 ordinary filter loss와 구분한다. 실제 leakage/discontinuity 경로는 이 식으로 보증하지 않는다.\n\n'
    report+=f'Repository의 circular CST surrogate body length 20 mm는 actual effective length의 확인값이 아니므로 WR-42 길이로 재사용하지 않았다.\n\n총 EIRP를 직접 PSD로 나누지 않고 **기존 ITU RR Appendix3 / SM.329 space-station spurious limit**를 유지했다. 70 W에서 attenuation=min(43+10log10(70),60)=60 dBc / 4 kHz다. Conducted broadband-equivalent −47.5696 dBm/Hz에 owner 31 dBi reference를 결합하여 EIRP source는 **{eirp_psd:.6f} dBm/Hz**다. Discrete spur를 broadband noise로 바꾼 결과가 아니며, 측정 PSD도 아니다.\n\n`EIRP_PSD_after = EIRP_PSD_source − A_cutoff`, `PSD_victim = EIRP_PSD_after + G_RX − FSPL`, `Required=max(0, PSD_victim−Limit)`다. 다만 ITU limit의 antenna-line 기준면과 effective guide의 source 기준면을 맞추기 전에는 추가 cutoff credit을 승인된 억제량으로 사용하지 않는다. 이번 숫자는 **0 dB cutoff credit의 conservative screening**이다.\n'
    report+=tab(['Ka victim','Source EIRP PSD (dBm/Hz)','RX gain − FSPL (dB)','0-credit Victim PSD (dBm/Hz)','Required upper screen (dB)','First PASS'],[[BAND[r['victim_band']],fmt(eirp_psd),fmt(r['victim_coupling_db']),fmt(r['victim_psd_dbm_hz']),fmt(r['required_additional_suppression_db']),passdesc(r['required_additional_suppression_db']) if r['required_additional_suppression_db'] is not None else '미판정'] for r in ka])
    thresholds=[]
    for band in ['L1','L2','L5','S_TC','ISL']:
        pool=[r for r in constraints if r['victim_band']==band];r=min(pool,key=lambda r:r['maximum_radiated_psd_dbm_hz']);thresholds.append([BAND[band],fmt(r['victim_coupling_db']),fmt(r['maximum_radiated_psd_dbm_hz']),'source PSD − A_cutoff가 이 값 이하여야 함'])
    report+=tab(['Ka victim','RX gain − FSPL (dB)','Maximum radiated PSD (dBm/Hz)','Required suppression 연결'],thresholds)
    lengths=[]
    for band in ['L1','L2','L5','S_TC','ISL']:
        pool=[r for r in constraints if r['victim_band']==band];lengths.append([BAND[band],fmt(max(r['minimum_effective_length_for_no_additional_filter_mm'] for r in pool)),'uniform guide / matched upstream reference-plane assumption'])
    report+=tab(['Victim','L_eff sufficient without added filter (mm)','조건'],lengths)
    report+='\n### 이전 KAA gain-bound와 새 route 비교\n'
    report+=tab(['Victim','Legacy gain-bound required (dB)','WR-42 route, 0-credit required (dB)','변경 (dB)'],
        [[BAND[r['victim_band']],fmt(r['legacy_gain_bound_required_db']),fmt(r['new_cutoff_zero_credit_required_db']),fmt(r['new_minus_legacy_db'])] for r in route_comparison])
    report+='이는 모델·source envelope가 다른 screening 비교다. 신규 route는 victim-frequency KAA gain을 사용하지 않고 owner 31 dBi EIRP reference를 사용한다. 변화량을 실제 장비 격리 성능의 향상/악화로 해석하지 않는다.\n'
    report+='길이 역산은 필요한 straight evanescent section의 engineering sizing이며 실제 설치 길이를 확정한 것이 아니다. 전 주파수·설치 경로에서 가장 큰 필요 길이를 사용했다. 실제 요구는 guide 길이·reference plane·leakage 검증 후 결정한다. 기존 KAA GAIN_BOUND_ONLY 숫자는 sensitivity로만 보존하며 cutoff primary 계산에는 사용하지 않는다.\n\n## 6. 입력 한계·Secondary blocker\n\nSAR absolute peak gain, ±80° 밖 normalized response/실제 orientation, WR-42 effective length와 upstream source reference plane이 필요하다. 기존 blocker −21.317 dBm(S-TC→GPS), −32.288 dBm(S-TC→opposite S-TM)은 secondary로 보존하고 TX unwanted suppression 요구에 사용하지 않는다. Receiver blocking/P1dB/IIP3 기준도 미확정이다.\n\n## 7. Appendix / detailed validation\n\n'
    report+='Freeze `8469e8903da83b6ebed014aae311f90855c31715`와 owner Task 1/2 입력만 사용했다. 다른 worker 결과를 분석 입력으로 쓰지 않았고 shared src/data/test를 변경하지 않았다. Additional CST simulation은 실행하지 않았다.\n\n[scope 입력](emission_inputs/task2_owner_scope.json), [SAR anchors](sar_owner_pattern_anchors.csv), [SAR envelope](sar_reference_envelope.csv), [harmonic overlap](sar_harmonic_overlap.csv), [S→SAR spurious](stc_sar_spurious_results.csv), [Ka band cutoff](ka_cutoff_band_results.csv), [Ka pair 요구식](ka_cutoff_pair_requirements.csv), [primary pair](all_pair_required_suppression.csv), [scenario](design_filter_scenarios.csv), [validation](task2_validation.json)을 참조한다. Task 1의 inclusive primary는 [legacy_task1](legacy_task1/all_pair_required_suppression.csv), KAA gain bound는 [sensitivity](conditional_bound_required_suppression.csv)에 보존했다.\n'
    report+='\n![SAR normalized engineering reference cuts](sar_reference_envelope.png)\n'
    (OUT/'결과보고서.md').write_text(report,encoding='utf-8')
    # Tests exercise anchors, symmetry, upper interpolation, units, domain and scope separation.
    for name in ['azimuth','elevation']:
        axis=policy[name]
        for x,y in anchors(axis):assert abs(envelope(axis,x)-y)<1e-9 and envelope(axis,-x)==envelope(axis,x)
        for (x0,y0),(x1,y1) in zip(anchors(axis),anchors(axis)[1:]):
            x=(x0+x1)/2
            if x>axis['first_null_angle_deg']:assert envelope(axis,x)>=max(y0,y1)
        assert envelope(axis,81) is None and envelope(axis,70)==axis['maximum_sidelobe_db']
    assert all(r['status']=='NO_HARMONIC_OVERLAP' for r in harmonics)
    fc,ratio,alpha,loss=rectangular_cutoff(C/(4*.01),.01,.1) # synthetic test fixture only, never primary input
    assert abs(fc-C/.02)<1e-8 and abs(alpha-math.pi/.01*math.sqrt(.75))<1e-9 and abs(loss-8.685889638065036*alpha*.1)<1e-8
    assert rectangular_cutoff(fc*1.1,.01,.1)[3]==0 and rectangular_cutoff(1e9,None,None)==(None,)*4
    assert all(r['tx_id'].startswith(('S_TM_TX','KA_DLS_TX')) for r in active)
    assert all(r['model_fidelity']=='WAVEGUIDE_BELOW_CUTOFF_BOUND' for r in active if r['tx_id'].startswith('KA_DLS_TX'))
    assert abs(float(isl['required_additional_suppression_db'])-39.240968602720386)<1e-9
    assert all(r['total_cutoff_attenuation_db'] is None and abs(r['source_eirp_psd_dbm_hz']-(-16.569619513137055))<1e-8 for r in ka)
    assert abs(C/(2*a)-14051015091.863516)<1e-6
    for r in constraints:
        assert abs(r['victim_psd_dbm_hz']-(r['source_psd_dbm_hz']+r['victim_coupling_db']))<1e-10
        assert r['required_additional_suppression_db']==max(0,-r['margin_0db_db'])
    for s in scenarios:
        if s['status']!='UNKNOWN':
            assert s['status']==('PASS' if float(s['margin_db'])>=0 else 'FAIL')
    for band in ['L1','L2','L5']:
        now=next(r for r in chosen if r['tx_id'].startswith('S_TM_TX') and r['victim_band']==band)
        prev=next(r for r in read('task1_lband_summary.csv') if r['victim_band']==band)
        assert float(now['required_additional_suppression_db'])==float(prev['required_additional_suppression_db'])
    tests=dict(status='PASS',scope='engineering reconstruction and bookkeeping; not full-wave qualification',
        primary_attackers=['S-TC TX','Ka DLS TX'],victim_only=['ISL','SAR'],primary_pair_rows=len(active),scenario_rows=len(scenarios),
        sar_generated_grid_rows=len(pattern),original_mat_read=False,original_1601_point_vectors_exported=False,
        harmonic_status='NO_HARMONIC_OVERLAP',sar_absolute_gain='UNKNOWN',ka_actual_waveguide=wg,ka_te10_cutoff_hz=C/(2*a),ka_effective_length='UNKNOWN',
        ka_power_dbw=10*math.log10(70),ka_total_eirp_reference_dbw=eirp_dbw,ka_total_eirp_arbitrarily_divided_into_psd=False,
        ka_spectral_limit='ITU RR AP3 / SM329 space stations 60dBc/4kHz at70W; broadband-equivalent only',ka_source_eirp_psd_dbm_hz=eirp_psd,
        additional_cst_run=False,octave_rerun=False,freeze_shared_hashes_unchanged=True,
        checks=['SAR owner anchors/HPBW/nulls/sample preservation','symmetry','side interpolation adjacent upper envelope',
            'out-of-domain handling and unsampled tail ceiling','Co referenced Cx floor; no absolute gain invented',
            'harmonic order and occupied/tuning band overlap','TE10 alpha dB factor / synthetic fixture / above-cutoff and missing-input cases',
            'ISL and GPS L1/L2/L5 regression and victim-only attacker exclusion','Ka gain-bound excluded from primary',
            'WR42 dimensions/cutoff and all Ka PSD/margin/required identities','all scenario PASS/FAIL signs',
            'total EIRP not silently turned into PSD'])
    (OUT/'task2_validation.json').write_text(json.dumps(tests,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for link in re.findall(r'\]\(([^)]+)\)',report):
        if not link.startswith('https:'):assert (OUT/link).exists(),link
    print(json.dumps(tests,ensure_ascii=True,indent=2))

if __name__=='__main__':main()
