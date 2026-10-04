# RFI 해석·보고서 작성 워커 전달 프롬프트

현재 작업 디렉터리는 Windows의 `C:\Users\ykyk1\source\repos\RFInterferenceSimulation`이다. 기존 CST 결과와 RF 시스템 정의를 연결하여 RFI 간섭 해석을 실제로 수행하고, 재현 가능한 결과 파일과 한국어 보고서를 작성하라. 사용자는 이후 CST 담당 워커와 보고서를 교차검증할 예정이다. 계획 설명으로 끝내지 말고 실행·검증·보고서 작성까지 진행하라.

## 1. 최신 사용자 결정

- 안테나 형상·포트·위치·지향을 변경하지 않는다. 추가 CST 계산, EM scan, 설치 구조물 축소 작업은 중단된 상태다. 재개하지 않는다.
- S는 TM 송신과 TC 수신, L(GPS)은 수신만, ISL은 송신·수신, Ka는 송신만이다. Ka RX와 L TX를 생성하지 않는다. ISL RX는 반드시 유지한다.
- 설치 패턴을 확보하지 못한 경우 자유공간 패턴을 우선 사용한다. S의 작은 국부 구조물 계산은 잠정 결과로만 취급하고 기본 보고서는 자유공간 기준으로 작성한다. 검증된 설치 패턴이 없다는 이유로 전체 RFI 해석을 중단하지 않는다.
- ISL과 Ka는 자유공간 패턴을 사용한다. SAR는 아직 분석에 연결된 패턴이 없지만, SAR 대역에서 다른 안테나의 응답과 향후 영향성을 가능한 범위에서 평가한다.
- 기존 frozen original pattern을 수정하거나 재튜닝하지 않는다. 새 해석·보고서는 별도 파일로 작성한다. 다른 워커의 동시 변경을 보존한다.

## 2. 먼저 확인할 자료

아래 경로는 모두 repo 기준 상대 경로다. 원본을 직접 읽고 최신 내용을 확인하라.

- `docs/reports/rfi_handoff/current_cst_status.csv`: 전달 시점의 실제 status.json을 수집한 스냅샷. 과거 summary보다 우선한다.
- `docs/reports/rfi_handoff/realized_gain_peaks.csv`: 실제 공개된 RealizedGain 컷 120개의 대역·주파수·평면별 최대값과 원본 CSV 경로. 최대값은 요약용이며 결합 방향의 이득을 대체하지 않는다.
- `data/antenna_port_response_cst/provenance.json`: 대역별 자유공간 포트 응답 CSV 목록, 출처, 수치 종류, 정규화 신뢰도, 품질 한계. 340개 공개 컷이 Python 검증을 통과했다.
- `data/antenna_port_response_cst/{S,L,ISL}/{band}/`: 실제 대역별 Gain/RealizedGain/IntendedCPGain XZ·YZ CSV.
- `cst/results/rfc_frequency_cases/*/status.json`: 실제 solver 상태·mesh·안테나 파라미터·주파수·품질·출처. 이 파일들이 계산 상태의 최종 근거다. `case_summary.csv`와 provenance의 cases 목록은 마지막 갱신 시점 이후의 설치 결과가 덜 반영되어 있을 수 있다.
- `cst/results/rfc_frequency_cases/active_queue.json`: 중단 상태와 최신 TX/RX 역할.
- `data/spacecraft/simplified_spacecraft_v1/antenna_functions.csv`, `pattern_bindings.csv`, `rf_systems.csv`: 기능·패턴 연결·RF 시스템 baseline.
- 동일 디렉터리의 설치 위치, 좌표계, steering 관련 정의와 `docs/icd/mission_spacecraft.md`.
- `examples/mission_cases.m`, `examples/rfc_level_report.m`, `examples/load_cst_port_response.m`, `src/+rfscreen/`와 관련 테스트.
- `docs/reports/cst_rfc_frequency_execution.md`: CST 경과와 ISL 변경 영향성. 과거 문구와 최신 사용자 결정이 충돌하면 이번 프롬프트와 실제 결과를 우선한다.
- `data/PATTERN_FREEZE.md`, `data/pattern_freeze_manifest.csv`: 원본 보존 규칙.

## 3. 케이스 분류와 대역

설치 위치/참조 패턴 구분은 S nadir/zenith 각각 SBA1/SBA4 기준으로 4개, GPSA1/GPSA2 2개, ISL 1개로 총 7개이며 ISL은 자유공간이다. Ka의 실제 설치 위치 KAA1/KAA2는 별도로 유지한다. SAR는 현재 패턴 미결합이다.

자유공간 패턴 원본 정체성은 SBA1, SBA4, 공통 GNSS, ISL로 4개, Ka를 추가하면 5개다. CST 물리 S 형상은 하나이며 SBA1/SBA4의 참조 패턴 차이를 보존한다. 형상 하나의 CST 결과를 서로 다른 제품의 실제 측정 결과로 표현하지 않는다. 공통 GNSS 패턴을 사용해도 GPSA1/GPSA2의 위치·지향·RF 기능은 합치지 않는다.

기존 mission 분석 조합은 SBA variant {SBA1,SBA4} × GPS band {L1,L2,L5} = 6개다. 이 조합 수와 물리 설치 수, RF 기능 수, TX×RX pair 수를 구분해 보고하라. 동시에 활성화되는 기능은 rf_systems 등록 사실만으로 단정하지 말고 scenario의 활성 집합을 명시하라. 전체 동시 활성은 screening 가정으로 별도 표시할 수 있다.

평가 대역과 CST monitor (GHz):

| 대역 | 저/중/고 주파수 |
|---|---|
| S-TC | 2.0 / 2.06 / 2.12 |
| S-TM | 2.2 / 2.25 / 2.3 |
| L1 | 1.563 / 1.57542 / 1.588 |
| L2 | 1.21737 / 1.2276 / 1.23783 |
| L5 | 1.164 / 1.17645 / 1.189 |
| ISL | 10.55 / 10.6 / 10.65 |
| SAR | 8.9 / 9.65 / 10.4 |
| Ka | 25.5 / 26.25 / 27 |

ISL와 SAR 대역은 사용자 지정이다. L1/L5 window 및 L2의 20.46 MHz window는 repo 가정을 유지한다. L2는 기존 1.207 GHz proxy와 구분하고 현재 1.2276 GHz 계산 데이터를 사용한다. 평가 대역의 폭을 RF 송신 occupied bandwidth나 수신 필터 bandwidth와 혼동하지 않는다. RF bandwidth·전력·NF·허용 I/N 등은 `rf_systems.csv`에서 provenance와 함께 읽는다.

## 4. 실제 확보된 응답과 누락

자유공간의 고정 형상 응답:

- S: S-TC, S-TM, L1, L2, L5, SAR, ISL 확보. Ka 대역 응답은 mesh 제한으로 미확보.
- L: S-TC, S-TM, L1, L2, L5 확보. SAR/ISL/Ka 대역 응답은 mesh 제한으로 미확보.
- ISL: 8개 평가 대역 모두 확보. 송신·수신 역할 모두 유지.
- Ka: 기존 25.5–27 GHz 자유공간 reflector surrogate 자료를 사용. 다른 대역의 전체 reflector 응답은 확보하지 못했다. CST feed-only 결과를 전체 reflector 결과로 대체하지 않는다.
- SAR: 송수신 시스템 역할이 repo에 있을 수 있으나 현재 패턴 미결합이다. 패턴과 송신 스펙이 없으면 SAR→다른 수신기 절대 간섭을 계산 완료했다고 주장하지 않는다. SAR 대역 응답·누락·가정별 민감도까지 구분해서 보고한다.

잠정 설치 계산:

- `RFC_S_LOW_SBA_NADIR_R1P75`: 99,330 cells, 4 ports 성공, 오류·경고 없음, LOW 15개 주파수 계산 완료.
- `RFC_S_LOW_SBA_ZENITH_R1P75`: 98,670 cells, 같은 조건 완료.
- 공통 비교 자유공간 `RFC_S_LOW_FREE_M4R10`: 54,208 cells, 완료. 두 설치 결과의 `matched_free_case`에 기록되어 있다.
- GPSA1/GPSA2의 R1.25 구조물은 각각 133,920 cells로 solver 미실행. GPSA1에서 X 방향 구조물만 더 줄인 추가 시도도 103,680 cells로 solver 미실행. 사용자 요청으로 추가 시도 중단.
- S 잠정 결과는 구조 범위/mesh 수렴 미확인이며 R3/R4/R5 수렴 조건도 충족하지 않았다. 최종 installed pattern으로 승인된 결과가 아니다. 원시 컷만 있고 SBA1/SBA4 기준 ΔG 보정 및 최종 연결도 완료하지 않았다. 기본 자유공간 결과와 구분한 선택적 민감도 비교만 허용한다.
- 기존 `docs/reports/installed_local/`의 기타 구조 계산이 있으면 출처·방법·상태를 읽어 구분하고, 이를 이번 CST 설치 계산 성공 근거로 혼합하지 않는다.

ISL 운영 대역 변경 확인: `cst/results/ISL_FIXED_10G6/validation.json`, `frequency_change_comparison.json`. 10.6 GHz에서 기존 10.4 GHz 기준 대비 accepted-power RHCP peak +0.122 dB, HPBW -0.979°, coverage RMS 차이 0.152 dB. 이는 기존 가정 gate 확인이며 측정 검증이나 mesh 수렴 검증이 아니다. ISL active binding은 `ISL_10P6`이다.

## 5. Gain·결합 계산 시 필수 구분

- 주파수별 실제 RealizedGain을 우선 확인하고 RF 포트 기준 전력과 일관되게 연결한다. Gain은 accepted-power total, RealizedGain은 incident-power total, IntendedCPGain은 accepted-power intended circular component다. total RealizedGain을 co-polar 또는 cross-polar 이득으로 표현하지 않는다.
- 원시 CST CSV의 legacy `gain` 열은 RealizedGain일 수 있다. raw `gain_dbi`, `realized_gain_dbi`, `dominant_cp_gain_dbi`와 공개 CSV의 quantity를 반드시 확인한다. 공개 CSV의 `gain`은 파일명/manifest가 지시하는 물리량이다.
- RealizedGain에 포함된 mismatch loss를 다시 차감하지 않는다. accepted-power Gain에 mismatch가 필요하면 신뢰 가능한 실제 accepted fraction으로 한 번만 적용한다. 정규화가 불안정한 주파수의 accepted Gain은 사용하지 않는다.
- 간섭은 송신 스펙트럼의 각 주파수 f에서 송신 안테나 응답과 수신 안테나 응답을 모두 평가하고 수신 필터와 함께 적분/평가한다. 수신 안테나의 자기 운용 중심 이득으로 모든 송신 대역을 대체하지 않는다. 송신 안테나의 수신 대역 응답이 있다고 해서 해당 주파수의 emission이 존재한다고 단정하지 않는다.
- 공개 자료는 독립 1° XZ/YZ 컷이다. 완전한 3D가 아니다. `load_cst_port_response(...,'RealizedGain')`의 재구성은 `APPROX_FROM_CUTS`이며 임의 방위 결과의 한계를 표시한다. 기본 인자는 Gain이므로 RealizedGain을 명시한다. 가능한 실제 컷 방향 검증도 수행한다.
- 보간은 계산된 개별 대역의 저/중/고 monitor 안에서만 한다. 2.3→8.9 GHz 등의 미계산 구간을 보간으로 메우지 않는다. 누락된 대역의 자유공간 응답은 운용 대역 패턴으로 검증되었다고 표현하지 않는다. 근거 있는 대체 가정을 사용한다면 실제 확보 데이터 결과와 분리하여 민감도 또는 경계값으로 보고한다.
- 원거리 조건과 안테나 크기/거리/파장 기준을 pair별로 확인한다. 만족하지 않는 근거리 pair에 Friis 값을 적용해 정확한 절대 간섭이라고 주장하지 않는다. pattern-only 상대 screening과 절대 전력 평가를 구분한다. 구조 FOV 점유가 자동으로 감쇠·차폐 dB가 되는 것은 아니다.
- 수신 필터·대역 중첩·TX emission/mask·고조파·상호변조·blocking은 기존 엔진과 실제 입력의 지원 범위에서 평가한다. P1dB/IIP3/emission mask 등 누락 입력을 0이나 임의 제품 스펙으로 채워 PASS를 내지 않는다.
- polarization, port power reference, path loss, mismatch, receiver filter를 각각 한 번만 적용한다. 비중첩 대역의 기본파 결과가 작다는 이유로 전체 EMC 적합을 단정하지 않는다.

## 6. 수행·검증·보고서 산출물

1. 현재 코드·입력과 사용 가능한 실행 환경을 확인하고 기존 분석 엔진을 이용해 6개 mission 조합 및 필요한 활성 scenario의 TX×RX pair를 실제 실행하라. MATLAB 미설치면 수행 가능한 동등 계산 경로를 명시하고 수치·단위·기존 엔진 수식과 대조하라. 실행하지 않은 테스트나 분석은 완료로 표기하지 않는다.
2. 대역별 source availability 표와 역할별 pair 목록을 먼저 만들고, 계산 가능/대체 가정/입력 부족/근거리 제한을 명확히 구분하라. 계산 가능한 pair는 완료하고 누락 때문에 전체 작업을 멈추지 않는다.
3. 보고서는 `docs/reports/rfi_analysis/`에 작성한다. 최소한 한국어 Markdown 보고서, pair별 CSV, 대역별 CSV, 사용 입력/패턴 출처 manifest, 실행 방법·환경·로그, 필요한 그림을 저장한다.
4. CSV에는 scenario/case, TX/RX 기능과 설치 ID, 주파수/대역, TX 전력 기준, 사용 패턴·quantity·source case·방향 이득, 거리/지향/steering, coupling 방법과 유효성, 수신 간섭·허용치·margin·판정·누락 이유를 남긴다. 집계 간섭은 선형 전력 합으로 계산하고 동시 활성 가정을 명시한다.
5. 보고서는 주요 위험 pair와 margin을 먼저 설명하고, 자유공간 우선 정책, SBA1/SBA4 및 GPS band 조합, ISL 변경, SAR 영향성의 가능한 범위, Ka→L 등 미확보 대역 응답의 미판정 사항을 포함한다. unsupported 항목은 NOT_EVALUATED/INPUT_MISSING/MODEL_LIMIT 같은 명확한 상태로 표기한다.
6. CST 담당 워커가 교차검증할 수 있도록 각 핵심 결론의 입력 CSV 행, CST case/주파수, 이득 종류, 좌표 변환, 보간 범위, 전력 합산·margin 수식을 추적 가능하게 남긴다. peak 표만으로 방향 이득을 대신하지 않았는지, mismatch 이중 적용이 없는지, 설치/자유공간/측정/가정이 혼합되지 않았는지 확인한다.
7. frozen original 데이터 변경이 없는지 확인하고, 의미 있는 관련 테스트를 실행한다. 결과와 미완료 항목을 사실대로 보고하라. CST 재계산·형상 변경·설치 작업 재개는 하지 않는다.

최종 응답에는 보고서 경로, 실제 실행한 케이스/pair 수, 핵심 결과, 판정 보류 항목, 교차검증용 산출물 경로를 제시하라.
