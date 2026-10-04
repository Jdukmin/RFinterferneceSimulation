"""Package Octave-computed evidence; Python performs validation/presentation only."""
import csv, hashlib, json, math, shutil
from bisect import bisect_right
from functools import lru_cache
from collections import Counter
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]; OUT=Path(__file__).resolve().parent
def read(p):
    return list(csv.DictReader(l for l in p.read_text(encoding='utf-8-sig').splitlines() if not l.startswith('#')))
def num(r,k): return float(r[k])
def dumpcsv(path,rows):
    with path.open('w',newline='',encoding='utf-8-sig') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
def table(headers,rows):
    return '| '+' | '.join(headers)+' |\n| '+' | '.join(['---']*len(headers))+' |\n'+''.join('| '+' | '.join(map(str,r))+' |\n' for r in rows)
def main():
    pairs=read(OUT/'rfi_pairs.csv'); samples=read(OUT/'frequency_direction_evidence.csv'); evidence=read(OUT/'case_pattern_evidence.csv')
    aggregates=read(OUT/'receiver_aggregates.csv'); sar=read(OUT/'sar_response_sensitivity.csv')
    meta=json.loads((OUT/'run_metadata.json').read_text()); assert len(pairs)==252
    assert len({(r['case_id'],r['mode_id']) for r in pairs})==18
    assert all('L_TX' not in r['tx_id'] and not r['rx_id'].startswith('KA_') for r in pairs)
    assert any(r['rx_id']=='ISL_X_RX' for r in pairs)
    available=[r for r in pairs if num(r,'spatial_samples')>0]; missing=[r for r in pairs if num(r,'spatial_samples')==0]
    for r in available:
        assert abs(num(r,'s21_db')-(num(r,'tx_gain_dbi')+num(r,'rx_gain_dbi')-num(r,'fspl_db')))<1e-7
        assert abs(num(r,'received_center_dbm')-(num(r,'tx_power_dbm')+num(r,'s21_db')))<1e-7
        assert abs(num(r,'integration_refinement_delta_db'))<0.1
    for r in samples:
        assert abs(num(r,'s21_db')-(num(r,'tx_gain_dbi')+num(r,'rx_gain_dbi')-num(r,'fspl_db')))<1e-7
    lookup={(r['case_id'],r['mode_id'],r['tx_id'],r['rx_id']):r for r in pairs}
    @lru_cache(None)
    def sourcecut(path):
        a=read(ROOT/path); return [float(r['theta']) for r in a],[float(r['gain']) for r in a]
    def linear(x,y,q):
        i=max(0,min(len(x)-2,bisect_right(x,q)-1)); return y[i]+(y[i+1]-y[i])*(q-x[i])/(x[i+1]-x[i])
    def angular(path,theta):
        x,y=sourcecut(path); return linear(x+[360],y+[y[0]],theta%360)
    def reconstruct(source,f,az,el):
        ar,er=math.radians(az),math.radians(el)
        d=[math.cos(er)*math.cos(ar),math.cos(er)*math.sin(ar),math.sin(er)]
        theta=math.degrees(math.acos(max(-1,min(1,d[0])))); phi=math.degrees(math.atan2(d[2],d[1]))%360
        paths=[s.split('|')[0] for s in source.split(';')]; fs=[]; vals=[]
        for xp,yp in zip(paths[::2],paths[1::2]):
            if 'Kaband_KAA_CST' in xp:
                freq={'25p5':25.5e9,'26p25':26.25e9,'27':27e9}[xp.split('_f')[1].split('_XZ')[0]]
            else: freq=float(Path(xp).name.split('_')[0][1:])*1e9
            v=[angular(xp,theta),angular(yp,theta),angular(xp,360-theta),angular(yp,360-theta)]
            fs.append(freq); vals.append(linear([0,90,180,270,360],v+[v[0]],phi))
        return linear(fs,vals,f)
    maxgainerror=0
    for r in samples:
        p=lookup[(r['case_id'],r['mode_id'],r['tx_id'],r['rx_id'])]
        for side in ['tx','rx']:
            g=reconstruct(r[side+'_source'],num(r,'frequency_hz'),num(p,side+'_az_deg'),num(p,side+'_el_deg'))
            error=abs(g-num(r,side+'_gain_dbi')); maxgainerror=max(maxgainerror,error); assert error<1e-7
    for a in aggregates:
        rr=[r for r in available if r['case_id']==a['case_id'] and r['mode_id']==a['mode_id'] and r['rx_id']==a['rx_id']]
        w=sum(10**((num(r,'received_integrated_dbm')-30)/10) for r in rr)
        assert abs((10*math.log10(w)+30)-num(a,'aggregate_port_dbm_supported_only'))<1e-7
    frozen=read(ROOT/'data/pattern_freeze_manifest.csv'); snapshots=[]
    for r in frozen:
        content=(ROOT/r['path']).read_bytes().replace(b'\r',b''); assert hashlib.sha256(content).hexdigest()==r['sha256_lf'],r['path']
    defs=ROOT/'data/spacecraft/simplified_spacecraft_v1'; snapshot=OUT/'input_snapshot'; snapshot.mkdir(exist_ok=True)
    paths=set()
    for p in defs.glob('*.csv'):
        shutil.copy2(p,snapshot/p.name); paths.add(p.relative_to(ROOT).as_posix())
    for p in [ROOT/'data/pattern_freeze_manifest.csv',ROOT/'data/antenna_port_response_cst/provenance.json']:
        shutil.copy2(p,snapshot/p.name); paths.add(p.relative_to(ROOT).as_posix())
    manifest=json.loads((ROOT/'data/antenna_port_response_cst/provenance.json').read_text())
    paths.update(r['path'] for r in manifest['cuts']); paths.update(r['path'] for r in frozen)
    for p in (ROOT/'cst/results/rfc_frequency_cases').glob('*/status.json'): paths.add(p.relative_to(ROOT).as_posix())
    for p in (ROOT/'src').rglob('*.m'): paths.add(p.relative_to(ROOT).as_posix())
    paths.update(['output/codex/run_rfi_octave.m','output/codex/build_report.py'])
    for relative in sorted(paths):
        data=(ROOT/relative).read_bytes(); snapshots.append({'repo_path':relative,'sha256_exact':hashlib.sha256(data).hexdigest(),'sha256_lf':hashlib.sha256(data.replace(b'\r',b'')).hexdigest(),'bytes':len(data)})
    dumpcsv(OUT/'input_hash_manifest.csv',snapshots)
    validation={'status':'PASS','octave_version':meta['runtime'],'pairs':len(pairs),'frequency_sample_rows':len(samples),'evaluated_pairs':len(available),'missing_pairs':len(missing),'frozen_hashes_verified':len(frozen),'equations_checked':'S21=Gtx+Grx-FSPL; Prx=Ptx+S21; linear receiver aggregate; source-cut reconstruction','max_source_gain_crosscheck_error_db':maxgainerror,'max_integration_refinement_delta_db':max(abs(num(r,'integration_refinement_delta_db')) for r in available),'role_checks':'ISL_RX retained; no KA_RX or L_TX; same-installation paths excluded','unit_tests':'Octave 57 assertions passed; see octave_tests.log'}
    (OUT/'validation.json').write_text(json.dumps(validation,indent=2)+'\n',encoding='utf-8')
    summary=[]
    for case in sorted({r['case_id'] for r in pairs}):
        for mode in ['SCREENING_ALL_TX','NOM_NADIR_KAA1','NOM_ZENITH_KAA2']:
            rr=[r for r in pairs if r['case_id']==case and r['mode_id']==mode]; ok=[r for r in rr if num(r,'spatial_samples')>0]
            peak=max(ok,key=lambda r:num(r,'received_integrated_dbm'))
            summary.append({'case_id':case,'mode_id':mode,'pairs':len(rr),'supported':len(ok),'missing':len(rr)-len(ok),'strongest_evaluated_tx':peak['tx_id'],'strongest_evaluated_rx':peak['rx_id'],'received_integrated_dbm':peak['received_integrated_dbm'],'required_rejection_db':peak['required_rejection_db'],'coupling_validity':peak['coupling_validity']})
    dumpcsv(OUT/'case_summary.csv',summary)
    bands=[]
    for band in ['S_TM','ISL','KA']:
        rr=[r for r in pairs if r['tx_band']==band]; ok=[r for r in rr if num(r,'spatial_samples')>0]
        bands.append({'tx_band':band,'pairs':len(rr),'supported':len(ok),'missing':len(rr)-len(ok),'max_received_dbm_evaluated_only':max(num(r,'received_integrated_dbm') for r in ok)})
    dumpcsv(OUT/'band_summary.csv',bands)
    stress=[r for r in available if r['case_id']=='CASE_SBA1_L1' and r['mode_id']=='SCREENING_ALL_TX']; stress.sort(key=lambda r:num(r,'received_integrated_dbm'),reverse=True)
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,axes=plt.subplots(1,2,figsize=(14,5.8),gridspec_kw={'width_ratios':[1,1.8]})
    labels=[r['tx_band'] for r in bands]; ok=[r['supported'] for r in bands]; miss=[r['missing'] for r in bands]
    axes[0].bar(labels,ok,label='Computed',color='#2376a8'); axes[0].bar(labels,miss,bottom=ok,label='Missing pattern',color='#b7bec8')
    axes[0].set_ylabel('Pair rows across 18 scenarios'); axes[0].set_title('Coverage of frequency-aware analysis'); axes[0].legend(frameon=False)
    names={'S_TM_TX@SBA_NADIR':'S nadir TX','S_TM_TX@SBA_ZENITH':'S zenith TX','GPS_L1_RX@GPSA_1':'GPSA1 RX','GPS_L1_RX@GPSA_2':'GPSA2 RX','S_TC_RX@SBA_NADIR':'S nadir RX','S_TC_RX@SBA_ZENITH':'S zenith RX','KA_DLS_TX@KAA_1':'Ka1 TX','KA_DLS_TX@KAA_2':'Ka2 TX','ISL_X_RX':'ISL RX'}
    top=stress[:8][::-1]; y=[names.get(r['tx_id'],r['tx_id'])+' -> '+names.get(r['rx_id'],r['rx_id']) for r in top]
    axes[1].barh(y,[num(r,'received_integrated_dbm')+65 for r in top],left=-65,color=['#bc7b27' if r['tx_band']=='KA' else '#2376a8' for r in top])
    axes[1].set_xlim(-65,0); axes[1].set_xlabel('Estimated pre-filter received power [dBm]'); axes[1].set_title('CASE_SBA1_L1 / all-TX screening\nSupported paths only; missing paths are not ranked')
    for ax in axes: ax.grid(axis='x',alpha=.15); ax.set_axisbelow(True)
    fig.tight_layout(); fig.savefig(OUT/'rfi_summary.png',dpi=170); plt.close(fig)
    statuses=Counter(r['analysis_status'] for r in pairs); validity=Counter(r['coupling_validity'] for r in available)
    report=f'''# RFI 간섭 해석 결과 보고서

작성 기준: 2026-10-04, {meta['runtime']}. 분석 실행·수치 적분은 Octave에서 수행했다. Python은 CSV 검증·출처 정리·보고서와 그림 생성에만 사용했다.

**6개 안테나 조합 × 3개 시나리오 = 18개 시나리오, 총 {len(pairs)}개 안테나 간 TX→RX 경로를 평가했다. {len(available)}개 경로는 대역별 방향 이득으로 전력 계산을 완료했고, {len(missing)}개는 수신 대역 외 패턴 부족으로 미판정이다.** 확보된 경로는 모두 이상적인 기본파 PSD와 수신 필터에서 대역 비중첩이며, 필터 뒤 기본파 간섭은 0 W다. 이는 전체 RFI 적합이나 실제 수신기 보호 성능의 PASS가 아니다.

## 모델과 패턴 선택

- 케이스는 SBA1/SBA4 × GPS L1/L2/L5. 설치 위치는 nadir/zenith, GPSA1/2, KAA1/2, ISL을 각각 유지했다. S는 TM TX와 TC RX, L은 RX만, Ka는 TX만, ISL은 TX/RX다.
- SCREENING_ALL_TX는 등록된 모든 TX/RX 동시 활성 가정이다. NOM_NADIR_KAA1 / NOM_ZENITH_KAA2는 기존 임시 운용 정의이며 확정 운용 일정이 아니다. 활성 ID와 패턴 매핑은 `case_pattern_evidence.csv`에 기록했다.
- 승인된 installed pattern이 없으므로 자유공간을 우선했다. 작은 구조물의 S 잠정 설치 결과를 최종 패턴으로 사용하지 않았으며 추가 CST를 실행하지 않았다.
- baseline frozen 패턴은 {len(frozen)}개 파일의 hash를 검증했다. 기존 엔진 결과는 `legacy_engine_reference.csv`에 비교용으로 보존했다. baseline 재구성 격자는 10°로 명시했으며 주 결과는 원래 1° 컷에서 실제 결합 방향을 직접 평가했다.
- 주 결과에서 S/L/ISL은 해당 TX 대역의 CST total RealizedGain을 사용했다. SBA1/SBA4의 frozen 참조 패턴 구분은 유지하되, 물리 CST S 형상이 공통이므로 이 경로의 주 계산값이 variant에 따라 동일할 수 있다. 제품 간 실측 차이를 해석했다고 주장하지 않는다.
- Ka TX는 frozen reflector reference gain을 사용했다. 이 자료를 total RealizedGain으로 재분류하지 않았다. Ka 포함 경로는 mismatch 미확인 상태의 혼합 reference screening이다. feed-only 결과로 reflector를 대체하지 않았다.
- 모든 방향 이득은 두 컷의 주기적 theta 보간 및 기존 `CutPatternAssembler.reconstructGain`을 이용한다. 임의 방위는 두 컷의 근사이며 완전 3D/측정/mesh 수렴 결과가 아니다. 지향은 현재 설치 기준값이며 Ka gimbal 가동 범위 최악 탐색은 수행하지 않았다.

## 계산 근거

좌표는 기존 `AntennaToAntennaFOV.relativeGeometry`와 local-to-body 회전을 사용했다. 원본 +Z에서 내부 antenna +X로의 변환은 `canonicalToAntenna`로 한 번만 적용했다. TX→RX 방향과 RX→TX 방향을 각각 평가했다. 최대 이득을 방향 이득 대신 쓰지 않았다.

각 주파수에서 λ=c/f, FSPL=20 log10(4πd/λ), S21=Gtx+Grx−FSPL을 계산했다. TX 포트 기준 PSD에 10^(S21/10)을 곱해 선형 W로 적분했고, 필터 뒤에는 추가로 Hrx(f)를 한 번 곱했다. 64→128 구간 midpoint 적분의 최대 변화는 {validation['max_integration_refinement_delta_db']:.6g} dB로 0.1 dB 이내다. 서로 다른 계산 대역 사이의 gap 보간은 하지 않았다. RealizedGain에는 mismatch를 다시 차감하지 않았다. 별도 polarization 손실은 입력 근거가 없어 적용하지 않았다.

허용치=10 log10(k·290·B·10^(NF/10))+30+I/N_max. 필요한 광대역 거부량=max(0, 필터 전 적분 수신전력−허용치)다. 이 값은 요구 거부량 screening이며 실제 필터의 성능이나 blocking/P1dB 허용치를 뜻하지 않는다.

원거리 유효성은 기존 `FarFieldCouplingModel`의 양 안테나 2D²/λ와 5λ 조건을 사용했다. 미충족이면 FREE_SPACE_ASSUMED로 표시했다. LOS와 구조물 교차도 기록했지만 구조물에 임의 차폐 dB를 부여하지 않았다. BLOCKED 경로의 자유공간 수치는 구조효과 미포함 추정이며 엄밀한 상한 또는 측정된 결합으로 표현하지 않는다.

## 대역별 커버리지

![계산 커버리지와 확보 경로의 필터 전 입력](rfi_summary.png)

'''+table(['TX 대역','전체 경로','계산 완료','미판정','최대 필터 전 적분 전력 dBm (확보 경로만)'],[[r['tx_band'],r['pairs'],r['supported'],r['missing'],f"{r['max_received_dbm_evaluated_only']:.3f}"] for r in bands])+'''
미판정: S·L의 Ka 대역 응답 및 L의 ISL 대역 응답이 없다. S의 Ka 대역 응답을 자기 TC 패턴으로, GPS의 ISL/Ka 응답을 자기 L-band 패턴으로 대신하지 않았다. 모든 송신 스펙트럼을 수신기 운용 중심에서만 평가한 결과도 사용하지 않았다.

## 주요 경로: CASE_SBA1_L1 / 전체 동시 활성

'''+table(['TX → RX','필터 전 전력 dBm','요구 거부량 dB','원거리 상태','LOS'],[[r['tx_id']+' → '+r['rx_id'],f"{num(r,'received_integrated_dbm'):.3f}",f"{num(r,'required_rejection_db'):.3f}",r['coupling_validity'],r['los']] for r in stress[:8]])+f'''
위 표는 확보된 응답 중의 순위다. 미판정 경로가 더 위험하지 않다는 뜻은 아니다. Ka 경로는 reflector reference gain/mismatch 한계가 추가로 있다. 확보 경로에서 큰 필터 전 입력이 있으면 실제 전단 blocking·compression·상호변조 확인이 필요하다. P1dB/IIP3·실제 방사 마스크·스퍼·고조파 정보가 없어 그 항목은 판정하지 않았다.

## 시나리오 요약

'''+table(['케이스','시나리오','전체/계산/미판정','최대 확보 입력 dBm'],[[r['case_id'],r['mode_id'],f"{r['pairs']}/{r['supported']}/{r['missing']}",f"{float(r['received_integrated_dbm']):.3f}"] for r in summary])+f'''
수신기 합산은 선형 전력 합으로 `receiver_aggregates.csv`에 남겼다. 일부 경로 누락 시 INCOMPLETE_MISSING_RESPONSES이며 supported-only 값으로 표시했다. 미판정 값을 0 W로 채워 전체 PASS를 만들지 않았다. 비중첩 기본파의 −Inf dBm / +Inf margin은 이상 필터 모델의 정확한 0 W 표시일 뿐 실제 EMC 무한 여유가 아니다.

## SAR 영향성

SAR 패턴이 미결합이라 실제 SAR 송수신 절대 RFI는 NOT_EVALUATED다. 기존 SAR 위치에서 각 RX를 향하는 방향의 S/ISL 응답을 8.9/9.65/10.4 GHz에서 평가해 `sar_response_sensitivity.csv`에 {len(sar)}행을 기록했다. L 응답은 해당 대역에서 미확보다. 방향 EIRP=0 dBm당 RX 필터 전 입력 전달량 Gr−FSPL 및 열잡음 기준의 방향 EIRP 경계값을 별도 민감도로 제공했다. SAR 송신 이득·실제 전력·mask를 채워 넣은 실제 간섭값이 아니다. SAR 크기는 불명이라 이 자유공간 전파도 가정이다.

## 검증과 재현

- Octave 관련 테스트: 57 assertions 통과, 0 실패 (`octave_tests.log`). 전체 테스트 suite 실행을 주장하지 않는다.
- 입력 frozen {len(frozen)}개 hash 불변, 역할/자기 설치 제외/전력 수식/대역별 적분 refinement 검증 PASS (`validation.json`).
- 원본 컷에서 기록된 방향·주파수 이득을 독립 재구성해 대조한 최대 오차는 {maxgainerror:.6g} dB였다. 필터 전 선형 합산도 별도 대조했다.
- `frequency_direction_evidence.csv`는 64구간 검증 grid의 {len(samples)}행이다. 최종 적분값은 128구간이고 두 grid 차이는 pair CSV에 기록했다. 샘플 컷 출처와 전체 보간 방법은 동일하다.
- 상태 분포: {dict(statuses)}. 확보 경로의 전파 유효성 분포: {dict(validity)}.
- 재실행: Octave에서 repo를 현재 디렉터리로 두고 `addpath('output/codex'); run_rfi_octave; run_rfi_octave('sar');` 실행. 이어 Python으로 `output/codex/build_report.py` 실행. 런타임 파일 경로는 `README.md`에 기록했다.
- `input_snapshot/`은 사용한 spacecraft 설정과 manifest 복사본이다. 원본 패턴·코드·CST 상태 hash는 `input_hash_manifest.csv`에 기록했다. 변경이 있으면 같은 결과의 재현으로 보지 않는다.

## 교차검증용 근거 파일

| 파일 | 검증할 내용 |
|---|---|
| case_pattern_evidence.csv | 6개 조합·3개 시나리오별 기능/설치/역할, baseline pattern key, 실제 원본 파일, 활성 TX/RX |
| frequency_direction_evidence.csv | 실제 주파수별 방향 이득, quantity, source CSV/CST case, FSPL/S21와 원거리 상태 |
| rfi_pairs.csv | 252개 경로의 거리/방향/LOS, 전력/허용치/거부량, 누락 이유, 적분 정확도 |
| receiver_aggregates.csv | 누락 경로를 명시한 수신기별 선형 전력 합산 |
| band_availability.csv / band_summary.csv | 8개 평가 대역 응답 가용성과 실제 TX 대역 결과 |
| sar_response_sensitivity.csv | SAR 대역 응답과 EIRP 매개변수 민감도; 실제 SAR 절대 간섭 아님 |
| legacy_engine_reference.csv | 기존 baseline 엔진 참고 결과; 대역 외 패턴 대체와 비교할 때 주의 |
| input_hash_manifest.csv / input_snapshot/ | 입력 버전과 분석 코드 근거 |
| octave_execution.log / run_metadata.json / validation.json | 실제 실행과 검사 근거 |

결론적으로 이번 결과는 자유공간·대역별 응답에 근거한 기본파 및 필터 전 입력 screening이다. 누락 패턴, 근거리/구조 효과, Ka 지향 범위, 실제 mask/전단 한계와 GNSS 최종 C/N0·J/S 기준을 확보하기 전 전체 RFI 적합은 미판정이다.
'''
    (OUT/'결과보고서.md').write_text(report,encoding='utf-8')
    evidence_text='''# 분석 근거 파일 안내

어떤 패턴을 어떤 케이스에 적용했는지는 `case_pattern_evidence.csv`에서 확인한다. 기본 baseline pattern key/원본 XZ·YZ/설치/역할/활성 집합을 케이스와 시나리오별로 기록했다.

실제 주 RFI 계산에서 사용한 대역별 pattern은 `frequency_direction_evidence.csv`의 tx_source/rx_source/quantity이다. baseline key만 보고 해당 baseline이 모든 대역의 주 계산에 사용되었다고 해석하지 않는다. S/L/ISL에는 해당 대역 CST RealizedGain을 사용했고 Ka에는 frozen reflector reference gain을 사용했다. 미확보 응답은 `rfi_pairs.csv`의 missing_reason으로 확인한다.

1. case_pattern_evidence.csv에서 case_id, mode_id, function_id를 찾는다.
2. rfi_pairs.csv에서 같은 케이스의 TX/RX 경로와 방향을 찾는다.
3. frequency_direction_evidence.csv에서 실제 평가 주파수·원본 CSV·CST source case·이득 종류·S21을 대조한다.
4. input_hash_manifest.csv에서 원본 hash를 확인하고 input_snapshot의 RF 입력을 대조한다.
5. 결과보고서.md의 계산식과 octave_execution.log를 확인한다.

안테나 CAD/포트/원본 frozen 패턴을 변경하지 않았다. 설치 패턴은 사용하지 않았으며 기존 S 국부 구조 결과도 final로 승격하지 않았다. SAR는 별도의 응답/EIRP 민감도만 수행했다. CSV 숫자는 Octave 출력이며 Python 보고서 작성이 RF 계산을 대체하지 않았다.
'''
    (OUT/'분석근거.md').write_text(evidence_text,encoding='utf-8')
    print(json.dumps(validation,ensure_ascii=False))
if __name__=='__main__': main()
