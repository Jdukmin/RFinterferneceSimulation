"""Validate unchanged-engine outputs and build readable independent report."""
from pathlib import Path
import csv, json, math, hashlib, re, subprocess
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent.parent

def read(name):
    return list(csv.DictReader((OUT/name).open(encoding='utf-8-sig')))
def num(r,k):return float(r[k])
def table(headers,rows):
    return '\n| '+' | '.join(headers)+' |\n| '+' | '.join(['---']*len(headers))+' |\n'+''.join('| '+' | '.join(map(str,r))+' |\n' for r in rows)+'\n'
def fmt(x):return f'{x:.2f}' if math.isfinite(x) else '미판정'
def first(req):return next((str(a)+' dB' for a in [0,40,60,70,80] if a>=req),'80 dB 초과 / 별도 설계')
def write(name,rows):
    with (OUT/name).open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def main():
    R=read('victim_band_scenarios.csv'); Z=[r for r in R if num(r,'filter_db')==0]
    # Normalize the column to total requirement from FILTER_0DB, not residual after each scenario.
    # This also supports logs from a driver already loaded when the label correction was made.
    bases={(r['case_id'],r['tx_id'],r['rx_id'],r['source_set']):r for r in Z}
    for r in R:
        z=bases[(r['case_id'],r['tx_id'],r['rx_id'],r['source_set'])]
        r['minimum_required_additional_suppression_db']=z['minimum_required_additional_suppression_db']
        if r['status']!='UNKNOWN':
            assert abs(num(r,'margin_db')-(num(z,'margin_db')+num(r,'filter_db')))<1e-7
            assert r['status']==('PASS' if num(r,'margin_db')>=0 else 'FAIL')
            assert abs(num(r,'victim_psd_dbm_hz')-(num(r,'source_psd_dbm_hz')+num(r,'coupling_db')-num(r,'filter_db')))<1e-7
            assert num(r,'sweep_refinement_delta_db')<0.01
    write('victim_band_scenarios.csv',R)
    assert len({r['filter_db'] for r in R})==5
    # Shared freeze inputs must remain byte-for-byte unchanged.
    for r in read('emission_inputs/freeze_input_hashes.csv'):
        assert hashlib.sha256((ROOT/r['path']).read_bytes()).hexdigest()==r['sha256'],r['path']
    primary=[r for r in Z if r['source_set']=='PRIMARY']
    compact=[]; requirements=[]
    for tx in ['S_TM_TX','ISL_X_TX','KA_DLS_TX']:
        for band in ['L1','L2','L5','S_TC','ISL']:
            rr=[r for r in primary if r['tx_system']==tx and r['victim_band']==band]
            if not rr:continue
            finite=[r for r in rr if r['status']!='UNKNOWN']
            p=max(finite,key=lambda r:num(r,'victim_psd_dbm_hz')) if finite else rr[0]
            compact.append(p)
            for z in rr:
                requirements.append(dict(case_id=z['case_id'],tx_id=z['tx_id'],rx_id=z['rx_id'],source_set='PRIMARY',
                    victim_band=band,margin_0db=z['margin_db'],minimum_required_additional_suppression_db=z['minimum_required_additional_suppression_db'],
                    first_passing_scenario=first(num(z,'minimum_required_additional_suppression_db')) if z['status']!='UNKNOWN' else 'UNKNOWN',
                    limitation=z['missing_reason']))
    write('pair_filter_requirements.csv',requirements)
    labels={'S_TM_TX':'S-TM','ISL_X_TX':'ISL/X','KA_DLS_TX':'Ka DLS'}
    txsummary=[]
    for tx in labels:
        rr=[r for r in primary if r['tx_system']==tx];ff=[r for r in rr if r['status']!='UNKNOWN']
        p=max(ff,key=lambda r:num(r,'minimum_required_additional_suppression_db')) if ff else None
        bound=[r for r in Z if r['tx_system']==tx and r['source_set']=='GAIN_CAP_40' and r['status']!='UNKNOWN']
        cap=max(bound,key=lambda r:num(r,'minimum_required_additional_suppression_db')) if bound else None
        txsummary.append(dict(tx_system=tx,worst_evaluated_victim=p['victim_band'] if p else 'UNKNOWN',
          minimum_rejection_evaluated_db=num(p,'minimum_required_additional_suppression_db') if p else 'UNKNOWN',
          first_passing_evaluated=first(num(p,'minimum_required_additional_suppression_db')) if p else 'UNKNOWN',
          unresolved_primary_pair_rows=sum(r['status']=='UNKNOWN' for r in rr),
          conditional_g40_rejection_db=num(cap,'minimum_required_additional_suppression_db') if cap else '',
          conditional_g40_first_passing=first(num(cap,'minimum_required_additional_suppression_db')) if cap else '',
          final_design_status='UNKNOWN: missing antenna response / same-port isolation / discrete spur criterion; screening is not equipment qualification'))
    write('tx_filter_design_summary.csv',txsummary)
    ecss='https://ecss.nl/wp-content/uploads/standards/ecss-e/ECSS-E-ST-50-05C_Rev24October2011.pdf'
    itu='https://www.itu.int/dms_pubrec/itu-r/rec/sm/R-REC-SM.329-13-202409-I!!PDF-E.pdf'
    rrurl='https://search.itu.int/history/HistoryDigitalCollectionDocLibrary/1.49.48.en.102.pdf'
    ccsds='https://ccsds.org/Pubs/401x0b32.pdf'
    sources=[
      dict(standard='ECSS-E-ST-50-05C Rev2',date='2011-10-04',clause='1 scope; 3.2.13; 5.5.1.1 Table 5-6',service='Space operation / research / EESS spacecraft-Earth; not data-relay supported craft',applicability='S-TM and Ka adopted screening standard; contract adoption unconfirmed; ISL not direct',domain='spurious; carrier 100..40500 MHz',limit='-60 dBc',rbw_hz='4000',plane='antenna transmission line; not a fixed unwanted EIRP bound',conservatism='S stricter than ITU by 10.0103 dB; Ka same at 70 W',selected='S/Ka PRIMARY',url=ecss),
      dict(standard='RR 2024 Appendix 3',date='2024 edition',clause='AP3 8; 10; Table I space stations note 10 and 17; Annex 1',service='space stations excluding deep-space SRS exception',applicability='ISL generic space-station design basis; authorization/allocation unconfirmed',domain='spurious',limit='min(43+10log10(P_W);60) dB below carrier',rbw_hz='4000',plane='antenna transmission line; EIRP method does not remove antenna-gain dependency',conservatism='least stringent generic compliant space-service envelope',selected='ISL PRIMARY / S and Ka generic sensitivity',url=rrurl),
      dict(standard='ITU-R SM.329-13',date='2024-09',clause='2.3; 4.1; 4.2 Table 2 note 2/3/5/6; Annex2 1.6/2.3; Annex1 2',service='space stations Category A design limits',applicability='same numeric generic space-service envelope as RR',domain='spurious; general boundary +/-2.5 BN with exceptions',limit='min(43+10log10(P_W);60) dB',rbw_hz='4000',plane='conducted; radiated measurement must account for gain',conservatism='generic sensitivity versus direct industrial standard',selected='ISL PRIMARY companion / GENERIC_ITU sensitivity',url=itu),
      dict(standard='CCSDS 401.0-B-32',date='2021-10; rec2.4.16 sheet May1997',clause='2.4.16',service='Earth stations and spacecraft',applicability='discrete spectral lines only',domain='single spurious spectral component',limit='-60 dBc total single line',rbw_hz='not a broadband density RBW',plane='transmitter output referenced to unmodulated carrier total power',conservatism='would reduce line limit; cannot replace broadband mask',selected='compared; not used as PSD; no engine conversion',url=ccsds),
      dict(standard='ITU-R SM.1541-7',date='2024-09',clause='recognizing e definitions; recommends1 and 2; service-specific annexes',service='generic OOB domains',applicability='defines distinction; carrier-adjacent mask not extrapolated to distant victims',domain='OOB immediately outside necessary bandwidth',limit='service-specific; not selected for these distant frequencies',rbw_hz='service dependent',plane='service dependent',conservatism='cannot invent distant victim emission from adjacent mask',selected='domain review only',url='https://www.itu.int/dms_pubrec/itu-r/rec/sm/R-REC-SM.1541-7-202409-I!!PDF-E.pdf'),
      dict(standard='SFCG REC30-2',date='PDF 2010-07-14; official index effective2011-06-15',clause='considering a/g; recommends1/2',service='25.5..27GHz EESS/SRS space-Earth',applicability='VCM/ACM and tracking guidance; Earth-surface in-band PFD is not onboard L/S/X EIRP bound',domain='Ka operating band',limit='no applicable distant L/S/X unwanted source mask in document',rbw_hz='not applicable',plane='Earth surface PFD context',conservatism='not applied as onboard emission ceiling',selected='not source mask',url='https://sfcgonline.org/resources/recommendations/')]
    write('standard_candidates.csv',sources)
    catalog=[]
    prior_catalog={r['id']:r for r in read('standard_source_evidence.csv')} if (OUT/'standard_source_evidence.csv').exists() else {}
    for name,url in [('ecss',ecss),('sm329',itu),('rr2024',rrurl),('ccsds',ccsds),('sm1541',sources[4]['url']),('sfcg30_2','https://sfcgonline.org/index.php?gf-download=2025%2F07%2F%2FREC-SFCG-30-2-Use-of-the-band-25.5-27-GHz.pdf&form-id=7&field-id=9&entry-id=387&hash=85b7c09d82aa5efc1620be845e891ad4b41ee21779806faf18a881e5e28f9189')]:
        p=OUT/'standards'/(name+'.pdf')
        if p.exists():catalog.append(dict(id=name,url=url,access_date='2026-10-04',sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
        else:
            assert name in prior_catalog and prior_catalog[name]['url']==url
            catalog.append(prior_catalog[name])
    write('standard_source_evidence.csv',catalog)
    report='''# 독립 RFI 분석 결과 — 규격 기반 victim-band PSD

## 1. Executive Summary

송신 규격의 worst-compliant broadband-equivalent source를 적용해 추가 필터 억제량을 산출했다. S-TM과 Ka는 ECSS spacecraft–Earth 규격, ISL은 RR/ITU space-station 규격을 채택했다. 결과는 개별 attacker 경로의 대역 평균 PSD screening이며 실제 장비 적합 인증은 아니다.

'''
    report+=table(['TX','확보 경로 worst victim','최소 추가 억제 (dB)','첫 통과 scenario','판정 범위'],[[labels[t['tx_system']],t['worst_evaluated_victim'] if t['worst_evaluated_victim']!='UNKNOWN' else '미판정',fmt(float(t['minimum_rejection_evaluated_db'])) if t['minimum_rejection_evaluated_db']!='UNKNOWN' else '미판정',t['first_passing_evaluated'] if t['first_passing_evaluated']!='UNKNOWN' else '미판정','S L2/L5 보류' if t['tx_system']=='S_TM_TX' else 'KAA 응답 보류' if t['tx_system']=='KA_DLS_TX' else 'GPS/S-TC 확보 경로'] for t in txsummary])
    report+='Ka는 conducted source를 숫자로 산출했으나 KAA 저주파 방사응답이 없어 primary port PSD는 보류다. 이를 끝점으로 삼지 않고 0/20/40 dBi의 명시적 방사이득 상한을 둔 EIRP sensitivity를 계산했다. 이 상한은 규제가 보장하는 값이 아니며 확인 전에는 최종 필터 규격으로 사용할 수 없다. S의 L2/L5도 freeze 정규화 불안정 때문에 primary 판정을 보류했다.\n\n## 2. 적용한 OOB/spurious 규격\n\n'
    report+=table(['TX','Standard','Domain','Limit','RBW','Reference plane'],[['S-TM','ECSS Rev2 Table5-6','spurious','−60 dBc','4 kHz','안테나 입력'],['ISL/X','RR AP3 TableI / SM.329 Table2','spurious','min(43+10log P,60) dB','4 kHz','안테나 입력'],['Ka DLS','ECSS Rev2 Table5-6','spurious','−60 dBc','4 kHz','안테나 입력']])
    report+=f'''ECSS는 spacecraft–Earth 서비스에 적용해 채택했으며 실제 계약 채택 여부는 미확정이다. ISL은 직접 적용 범위가 아니므로 generic space-station 한계를 사용했다. Category-B deep-space harmonic 예외는 이번 비고조파 victim에 적용하지 않는다. [ECSS 공식 PDF]({ecss}), [RR 2024 AP3]({rrurl}), [SM.329-13]({itu}).

Freeze 대역폭을 necessary/occupied bandwidth의 임시 proxy로 사용했다. 일반 ±2.5B 경계는 S 2.24325–2.25675 GHz, ISL 10.55–10.65 GHz, Ka 22.50–30.00 GHz다. S/Ka→모든 victim 및 ISL→GPS/S-TC는 멀리 떨어진 spurious domain이다. ISL→동일 ISL RX는 기본파·OOB가 섞인 동일 포트 경로로 제외하고 격리 입력을 요구한다. BN 통지값·광대역 예외는 미확정이지만 먼 victim의 분류는 이 proxy 범위에서 동일하다. 주파수 도메인과 방출 메커니즘은 별개다. harmonic, discrete spur, broadband noise를 같은 source로 섞지 않았다. [SM.1541-7 정의]({sources[4]['url']}).

후보의 서비스·적용성·limit·RBW·기준면·보수성·채택 여부는 [standard_candidates.csv](standard_candidates.csv)에 있다. CCSDS 2.4.16의 −60 dBc는 단일 spectral line의 총전력이며 PSD source로 채택하지 않았다. SFCG 30-2의 Ka 지상 PFD·운용 지침도 onboard 저주파 EIRP 상한으로 바꾸지 않았다. [CCSDS 공식 PDF]({ccsds}), [SFCG 공식 목록]({sources[5]['url']}).

## 3. 규격별 source PSD derivation

`P_dBm = 30 + 10log10(P_W)`, `P_4k = P_dBm − A`, `PSD_equiv = P_4k − 10log10(4000)`이다. 마지막 항은 **36.0206 dB**다. 외부 추가 필터 0 dB이며 송신기 자체 규격을 만족하는 출력 기준이다. 공급사 실측값이나 필터 없는 PA의 실제 방출값으로 주장하지 않는다.

'''
    D=read('source_derivation.csv'); unique={(r['tx_system'],r['source_set']):r for r in D}
    report+=table(['TX / source','P (W)','Carrier (dBm)','A (dB)','Limit (dBm/4 kHz)','Broadband equiv. (dBm/Hz)'],[[labels[tx]+' / '+ss,r['power_w'],fmt(num(r,'power_dbm')),fmt(num(r,'attenuation_db')),fmt(num(r,'band_power_dbm')),fmt(num(r,'broadband_equivalent_dbm_hz'))] for (tx,ss),r in unique.items()])
    report+='이는 flat broadband-equivalent envelope다. 4 kHz 평균 제한만으로 임의 1 Hz bin의 상한이나 discrete line PSD를 보장하지 않는다. Discrete spur는 같은 dBm 총전력을 별도 경로로 계산해 [discrete_spur_results.csv](discrete_spur_results.csv)에 보존했다. 수신기의 tone 기준이 없어 최종 spur 판정은 보류다. 규격의 RBW와 측정 RBW/ENBW는 별개이며 분석은 4 kHz를 사용했다. Detector·modulation·기준면 조건은 독립 source table에 기록했다.\n'
    report+=table(['TX','Victim band','Worst compliant source PSD (dBm/Hz)','Provenance'],[[labels[tx],'GPS L1/L2/L5, S-TC'+(', ISL' if tx!='ISL_X_TX' else ''),fmt(num(unique[(tx,'PRIMARY')],'broadband_equivalent_dbm_hz')),'공식 규격 / 4 kHz flat-equivalent'] for tx in labels])
    report+='\n## 4. Victim-band PSD 결과\n\n`PSD_victim = PSD_source − 추가필터 + 결합`, `margin = 허용 PSD − victim PSD`다. 양수는 해당 모델 기준 여유, 음수는 초과다. 표는 TX/victim별 확보 경로 worst case이며 반복 설치·case 전체는 CSV에 남겼다.\n'
    report+=table(['TX → Victim','Source (dBm/Hz)','Coupling (dB)','Victim (dBm/Hz)','Limit (dBm/Hz)','Margin (dB)'],[[labels[r['tx_system']]+' → '+r['victim_band'],fmt(num(r,'source_psd_dbm_hz')),fmt(num(r,'coupling_db')),fmt(num(r,'victim_psd_dbm_hz')),fmt(num(r,'allowable_dbm_hz')),fmt(num(r,'margin_db'))] for r in compact])
    report+='미판정은 source 규격 미조사라는 뜻이 아니다. Source는 확보했고 S L2/L5의 불안정 TX 정규화와 Ka의 victim-band TX 응답이 port PSD 산출을 막는다.\n\nKa 조건부 radiated route는 `EIRP_equiv = conducted PSD + G_cap`, `coupling = G_rx − FSPL`이다. TX 이득을 다시 더하지 않는다. 26 GHz reflector 패턴 재사용·외삽은 없다.\n'
    caprows=[]
    for band in ['L1','L2','L5','S_TC','ISL']:
        for cap in [0,20,40]:
            rr=[r for r in Z if r['tx_system']=='KA_DLS_TX' and r['victim_band']==band and r['source_set']==f'GAIN_CAP_{cap}' and r['status']!='UNKNOWN']
            if rr:
                r=max(rr,key=lambda r:num(r,'victim_psd_dbm_hz'));caprows.append([band,str(cap),fmt(num(r,'source_psd_dbm_hz')),fmt(num(r,'coupling_db')),fmt(num(r,'victim_psd_dbm_hz')),fmt(num(r,'margin_db'))])
    report+=table(['Ka victim','G cap (dBi)','EIRP (dBm/Hz)','Transfer (dB)','Victim (dBm/Hz)','Margin (dB)'],caprows)
    report+='Gcap는 임의의 KAA response 대체값이 아니라 조건부 상한 sweep이다. 40 dBi는 의도적으로 느슨한 screening ceiling이지만 superdirectivity·구조 효과까지 포함한 엄밀한 상한은 아니다. 확정에는 방사 측정/검증된 저주파 gain envelope가 필요하다.\n\n## 5. TX별 최소 추가 필터 억제량\n\n`max(0, −margin_0db)`가 최소 추가 TX unwanted-emission 억제량이다. 실제 주파수별 필터가 이 값을 전 tuning 범위에서 제공해야 한다. 기본파 RX blocker rejection과 별개다.\n'
    report+=table(['TX → Victim','0 dB margin','Required additional suppression','First passing scenario'],[[labels[r['tx_system']]+' → '+r['victim_band'],fmt(num(r,'margin_db'))+' dB',fmt(num(r,'minimum_required_additional_suppression_db'))+' dB' if r['status']!='UNKNOWN' else '미판정',first(num(r,'minimum_required_additional_suppression_db')) if r['status']!='UNKNOWN' else '미판정'] for r in compact])
    report+=table(['TX','Worst victim','Required rejection','Recommended screening filter class'],[[labels[t['tx_system']],t['worst_evaluated_victim'] if t['worst_evaluated_victim']!='UNKNOWN' else '미확정',fmt(float(t['minimum_rejection_evaluated_db']))+' dB' if t['minimum_rejection_evaluated_db']!='UNKNOWN' else '미확정',t['first_passing_evaluated']+' (확보 경로)' if t['minimum_rejection_evaluated_db']!='UNKNOWN' else '별도 설계 / KAA 응답 확인'] for t in txsummary])
    for t in txsummary:
        if t['conditional_g40_rejection_db']!='':report+=f"{labels[t['tx_system']]}의 Gcap 40 dBi sensitivity에서 추가 억제량은 {t['conditional_g40_rejection_db']:.2f} dB, 첫 통과는 {t['conditional_g40_first_passing']}다. Primary 확정값은 아니다.\n\n"
    sensitivity=[]
    for tx in ['S_TM_TX','KA_DLS_TX']:
        for cap in [0,20,40]:
            ff=[r for r in Z if r['tx_system']==tx and r['source_set']==f'GAIN_CAP_{cap}' and r['status']!='UNKNOWN']
            p=max(ff,key=lambda r:num(r,'minimum_required_additional_suppression_db'))
            sensitivity.append([labels[tx],p['victim_band'],str(cap),fmt(num(p,'minimum_required_additional_suppression_db')),first(num(p,'minimum_required_additional_suppression_db'))])
    report+=table(['조건부 TX','Worst victim','G cap (dBi)','Required (dB)','First passing scenario'],sensitivity)
    k0=[]
    for band in ['L1','L2','L5','S_TC','ISL']:
        ff=[r for r in Z if r['tx_system']=='KA_DLS_TX' and r['victim_band']==band and r['source_set']=='GAIN_CAP_0' and r['status']!='UNKNOWN']
        p=max(ff,key=lambda r:num(r,'minimum_required_additional_suppression_db'));need=num(p,'minimum_required_additional_suppression_db')
        k0.append([band,fmt(60-need),fmt(70-need),fmt(80-need)])
    report+='Ka 필터를 조건부 설계 입력으로 바꾸면 아래는 각 대역에서 검증해야 할 **최대 realized radiation gain ceiling**이다. 예를 들어 80 dB 추가필터를 쓰려면 L5 방사이득이 4.48 dBi 이하임을 별도로 입증해야 한다. 일반적인 공통 gain ceiling G를 적용한다면 worst-band 최소 요구는 `max(0, 75.52 + G) dB`다. 이 값은 허용 gain을 역산한 것이며 실제 gain을 가정해 확정한 결과가 아니다.\n'
    report+=table(['Ka victim','60 dB filter 허용 gain (dBi)','70 dB 허용 gain (dBi)','80 dB 허용 gain (dBi)'],k0)
    report+='## 6. 0/40/60/70/80 dB scenario 결과\n\n각 셀은 margin(dB) / PASS·FAIL이며 미판정 경로는 필터만 추가해도 판정되지 않는다. 모두 실제 부품 보증값이 아닌 flat 추가필터 screening이다.\n'
    def scenario_table(rows):
        result=[]
        for z in rows:
            rr=[r for r in R if all(r[k]==z[k] for k in ['case_id','tx_id','rx_id','source_set'])]
            result.append([labels[z['tx_system']]+' → '+z['victim_band']]+[next((fmt(num(r,'margin_db'))+' / '+r['status'] if r['status']!='UNKNOWN' else '미판정' for r in rr if num(r,'filter_db')==a),'미판정') for a in [0,40,60,70,80]])
        return table(['TX → Victim','0 dB','40 dB','60 dB','70 dB','80 dB'],result)
    report+=scenario_table(compact)
    generic=[r for r in Z if r['source_set']=='GENERIC_ITU' and r['status']!='UNKNOWN']
    if generic:
        p=max(generic,key=lambda r:num(r,'minimum_required_additional_suppression_db'))
        report+=f"S-TM의 generic ITU sensitivity worst case는 {p['victim_band']}, 최소 {num(p,'minimum_required_additional_suppression_db'):.2f} dB이며 첫 통과는 {first(num(p,'minimum_required_additional_suppression_db'))}다. Primary source보다 10.01 dB 높은 emission envelope다.\n\n"
    report+='전체 pair와 conditional EIRP scenario는 [victim_band_scenarios.csv](victim_band_scenarios.csv)에 있다. Case별 조회 키와 source_set으로 primary/generic/gain-cap을 구분한다.\n\n## 7. Receiver criterion\n\nGPS L1/L2/L5는 **−178 dBm/Hz**(NF 2 dB, I/N −6 dB), S-TC와 ISL은 **−177 dBm/Hz**(NF 3 dB, I/N −6 dB)다. Freeze engineering baseline을 변경하지 않았다. GPS sweep은 freeze CST monitor 범위, S-TC는 2025–2110 MHz, ISL은 10.55–10.65 GHz다.\n\n수신 BW 적분은 이번 primary filter 선정에 사용하지 않았다. 실제 C/N0·J/S 및 tone susceptibility는 별도 기준이 필요하다. S→L reference는 engine test에서 −120 → 60 dB filter → −180 dBm/Hz, GPS 대비 **+2 dB**를 확인했다. 이 reference는 현재 TX emission source로 사용하지 않았다.\n\n## 8. 입력/모델 한계\n\nSource limit은 준수 장비를 가정한 상한이며 공급사 측정값이 아니다. Broadband 평균 envelope 판정, 개별 discrete spur 적합성, 동시 TX 합산 적합성을 구분해야 한다. 이번 margin·필터 요구는 각 attacker별이며 전체 합산 PASS를 주장하지 않는다.\n\nPrimary S L2/L5 정규화 불안정, Ka conducted route의 저주파 방사응답, 동일 포트 S-TM/S-TC·ISL 격리, 실제 필터 주파수 응답, tone 기준, 허가 서비스·BN·계약 규격 채택은 미확정이다. 10.6 GHz ISL 서비스/주파수 정의는 freeze 잠정값이며 이번 분석이 주파수 허가를 입증하지 않는다.\n\n자유공간 native 1° 컷과 기존 두 컷 방위 보간을 사용했다. CST 값은 시뮬레이션이고 실측이 아니다. 설치 구조물 차폐를 임의 적용하지 않았다. 근거리/구조 결합을 보장한 상한이 아니며 Ka low-band sensitivity 역시 자유공간 route다. Ka carrier 근거리 solver를 이번 primary 결과에 섞지 않았다.\n\n## 9. Secondary blocker\n\n기존 Codex freeze 결과의 S-TM zenith → GPSA1 **−21.317 dBm**, 반대편 S-TC **−32.288 dBm** 필터 전 적분 입력을 그대로 보존했다. 이 값에서 이번 TX 추가 필터 요구를 도출하지 않았다. P1dB·blocking·preselector·IIP3가 없어 최종 전단 보호 판정은 보류다. 상세는 기존 [rfi_pairs.csv](rfi_pairs.csv); 분석 경로는 `SECONDARY_OOB_BLOCKER_ANALYSIS`다.\n\n## 10. Appendix\n\n'
    report+=f"Freeze: `8469e8903da83b6ebed014aae311f90855c31715`; branch: `codex/rfi-emission-8469e89`. 시작 원본 작업 트리는 dirty였고 새 분석 worktree는 freeze HEAD에서 clean이었다. [freeze_record.json](freeze_record.json)에 상태를 기록했다. 공유 코드·입력은 hash로 불변 확인했으며 다른 worker 결과를 읽지 않았다.\n\n"
    report+='161점 sweep과 원본 monitor 주파수를 포함했고 81점+monitor와 worst PSD 차이 0.01 dB 미만을 검사했다. 전체 방향·주파수·gain·source는 [victim_band_coupling.csv](victim_band_coupling.csv)에 있다. Engine의 기존 `test_rfi_psd`와 독립 Python consistency 검증을 수행했다. [emission_execution.log](emission_execution.log), [emission_validation.json](emission_validation.json)을 참조한다. CST 신규 solve는 수행하지 않았다.\n\n'
    report+=table(['파일','역할'],[['emission_inputs/tx_emission_masks.csv','primary / generic / conditional EIRP / discrete source 및 조항·RBW·기준면'],['source_derivation.csv / domain_classification.csv','전력·attenuation·단위 변환과 domain 경계'],['standard_candidates.csv / standard_source_evidence.csv','채택 비교·공식 URL·확인 날짜·PDF hash'],['victim_band_scenarios.csv / pair_filter_requirements.csv','전체 pair scenario와 최소 추가 억제량'],['tx_filter_design_summary.csv','TX별 screening class와 미확정 범위'],['discrete_spur_results.csv / emission_exclusions.csv','tone 전력과 동일 포트 제외 사유'],['prepare_emission_analysis.py / run_emission_analysis.m','worker 독립 입력 준비·변경 없는 engine 실행'],['summarize_emission_analysis.py','기존 출력 검증·보고서 정리']])
    report+='재현: freeze worktree에서 `python output/codex/prepare_emission_analysis.py`, Octave에서 `addpath(\'tests\'); addpath(\'output/codex\'); run_emission_analysis;`, 이어 `python output/codex/summarize_emission_analysis.py`를 실행한다. 공개 규격 PDF는 저장소에 재배포하지 않고 URL/hash만 제공한다.\n'
    existing=OUT/'결과보고서.md'
    if not (OUT/'emission_inputs/pre_emission_report.md').exists():(OUT/'emission_inputs/pre_emission_report.md').write_bytes(existing.read_bytes())
    report=report.replace('미판정 dB','미판정')
    existing.write_text(report,encoding='utf-8')
    v=dict(status='PASS',scope='worker analysis numeric consistency; not spacecraft RFI qualification',
      freeze_sha='8469e8903da83b6ebed014aae311f90855c31715',scenario_rows=len(R),primary_pair_rows=len(primary),
      primary_evaluated_pair_rows=sum(r['status']!='UNKNOWN' for r in primary),primary_unknown_pair_rows=sum(r['status']=='UNKNOWN' for r in primary),
      shared_input_hashes_unchanged=True,scenarios=[0,40,60,70,80],reference_margin_db=2,
      max_sweep_refinement_db=max(num(r,'sweep_refinement_delta_db') for r in R if r['status']!='UNKNOWN'),
      engine_test='test_rfi_psd executed in Octave; see emission_execution.log',
      python_checks=['source+coupling-filter=port','margin=limit-port','scenario margin shift','PASS/FAIL sign','freeze shared hashes'])
    (OUT/'emission_validation.json').write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
    for target in re.findall(r'\]\(([^)]+)\)',report):
        if not target.startswith('https:'):assert (OUT/target).exists(),target
    print(json.dumps(txsummary,indent=2));print(json.dumps(v,indent=2))
if __name__=='__main__':
    main()
    from complete_suppression_design import main as complete_design
    complete_design()
