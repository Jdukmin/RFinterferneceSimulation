# KAA victim-band 방사응답과 ITU 불요방사 결합 결과보고서 (screening)

> **상태: legacy sensitivity (Task 2).** owner 결정으로 Ka primary route는 "최대 EIRP + 도파관 below-cutoff"로 바뀌었다([RFI_Task2_범위단순화_결과보고서.md](RFI_Task2_범위단순화_결과보고서.md)). 이 보고서의 최대 이득 상한 결과는 primary에서 제외하고 비교용으로만 유지한다.

**결론.** KAA의 L/S/X victim band 방사응답은 **현재 입력으로 계산할 수 없다**. 분류는 `GAIN_BOUND_ONLY`이며, 이 주파수들은 안테나 크기에서 얻은 **최대 이득 상한(Tier 3, `ENGINEERING_BOUND`, `NOT_MEASURED`, `NOT_CST_VALIDATED`)** 으로 닫았다.
- **의미:** ITU 규격을 만족하는 송신기라도 KAA 방사만 고려하면(WR-42 cutoff·급전선·필터 감쇠 0 dB) 모든 평가 victim에서 허용 PSD를 크게 초과한다. 추가로 필요한 억제량은 GPS L1 59.0~63.9 dB, L2 79.0~86.1 dB, L5 81.1~86.6 dB, S-band 84.6~89.2 dB, ISL X-band 86.1~87.2 dB다(Tier 3 상한 기준, 자유공간).
- **이 값들은 상한 기준의 보수적 요구량이다.** 실제 KAA 이득이 아니며, 실제 응답이 상한보다 낮으면 요구량도 같은 dB만큼 줄어든다. 최종 필터 규격으로 쓰지 않는다.
- **SAR X-band는 포트 PSD와 요구 억제량을 산출하지 못했다.** victim인 SAR 안테나의 응답이 없다(미확정). 0 dBi로 대체하지 않았고, 수신 안테나 이득 이전의 PSD만 제시한다.
- **계산 완료 범위:** KAA 2기 × victim 10개 = 20개 조합(GPS L1/L2/L5 × GPSA_1/2, S-TC × SBA 2개, ISL, SAR). 20개 조합 중 18개가 victim-port PSD까지 계산되었고, SAR 2개 조합은 보류다. 전체 적합 여부 판정이 아니라 ITU 상한 조건의 screening이다.

## 1. KAA victim-band 방사 모델과 reflector 포함 가능 여부

| 항목 | 판정 | 근거 (유형) |
|---|---|---|
| CST solver 모델 | **feed only** | `KA_FEED_C_OEWG` 개방형 원형 도파관, monitor 25.5/26.25/27 GHz뿐 (시뮬레이션 데이터) |
| Reflector 단계 | 비-CST 등가 포물면 | 직경 220 mm, Fe 151.1 mm, 차폐 44 mm, Python 개구면 적분. Ka feed 패턴이 필요해 Ka monitor에서만 정의됨 |
| CST/solver 내 reflector 형상 | 형상만 존재, 미해석 | 별도 작업본 위성체 모델에 AnalyticalFace 포물면이 있으나 port·mesh·solver 없음 |
| L/S/X feed 패턴, 여기(excitation) 정의 | **없음** | 26 GHz 패턴을 외삽하지 않음. victim 대역 에너지가 feed에 어떻게 들어가는지는 이번에 제외한 WR-42/급전 거동 그 자체임 |
| Learning Edition mesh (100 000 cell) | 미실증 | 맨 reflector 면만의 균일 격자 **추정**은 X-band λ/10에서 약 7.5~9.2만 cell로 한도 이내이나, feed·부반사판·hull을 넣으면 더 커진다. CST mesh 확인을 시도했으나 응답이 없어 중단했고, 솔버 검증 cell 수는 없다 |

- **분류:** 4개 분류 중 `GAIN_BOUND_ONLY`. `FULL_REFLECTOR_VICTIM_BAND_AVAILABLE`, `EQUIVALENT_REFLECTOR_MODEL_AVAILABLE`, `FEED_ONLY_AVAILABLE`은 L/S/X에서 성립하지 않는다. feed-only CST는 Ka에만 있고 victim 대역으로 쓸 수 없다.
- **Tier 1(검증된 reflector 패턴)에 필요한 입력:** 실제 Cassegrain CAD(feed horn·부반사판·strut), feed throat의 victim 대역 여기 정의, Learning Edition 한도를 넘는 solver. **Tier 2(등가 포물면)에 필요한 입력:** victim 대역 feed 패턴(실측 또는 CST).
- Ka 정상 운용대역 25.5–27 GHz는 기존 결과를 그대로 쓰며 이번에 바꾸지 않았다.

### Tier 3 상한 (산출)

상한은 안테나 직경 D = 0.22 m에서 두 식의 큰 값이다. 방향과 무관한 천장값이다.

- 개구면: G = 4πA/λ² = (πD/λ)², A = πD²/4, 효율 1. 대구경 한계이며 D/λ ≈ 1에서는 엄밀한 상한이 아니다.
- 구(Harrington/Chu): G = (ka)² + 2ka, a = D/2. 반경 a 구 안의 임의 안테나 방향성 상한이다. 초지향(superdirective)이라 현실에서 달성되지 않는다. 개구면 상한과의 차이는 2ka로, X-band에서는 0.5 dB 미만이고 L/S에서 지배적이다.
- 지향성 상한은 realized gain의 상한이기도 하다(정합·손실은 이득을 낮출 뿐). 구는 개구 원판만 감싼다고 가정했고 feed 부피·hull은 포함하지 않았다. 구조가 이 구를 벗어나면 엄밀한 상한은 더 크다(a를 1.5배로 한 민감도는 응답 CSV에 있음).

| victim band | 중심 주파수 | Tier 3 상한 [dBi] (밴드 최대) | 전기적 크기 ka |
|---|---|---|---|
| ISL X-band | 10.6 GHz | 28.10 (28.14) | 24.4 |
| SAR X-band | 9.65 GHz | 27.32 (27.54) | 22.2 |
| S-band RX | 2.0675 GHz | 15.09 (15.24) | 4.8 |
| GPS L1 | 1.5754 GHz | 13.11 (13.16) | 3.6 |
| GPS L2 | 1.2276 GHz | 11.36 (11.41) | 2.8 |
| GPS L5 | 1.1765 GHz | 11.07 (11.14) | 2.7 |

- L/S 상한은 20 dBi 민감도보다 낮다. L/S에서 20 dBi 행은 물리 상한을 넘는 민감도일 뿐이며 `SENSITIVITY_EXCEEDS_PHYSICAL_CEILING`로 표시했다.
- 이 대역들에서 peak gain·victim 방향 gain·XZ/YZ RealizedGain cut은 패턴이 없어 산출하지 않았다(미확정). 상한은 peak와 victim 방향 모두의 천장이다. 응답 파일: `data/antenna_port_response_cst/KAA/kaa_victim_band_response.csv`.

## 2. Gimbal 분석

- **gimbal 모델:** 실제 hard-stop 값이 저장소에 없다. 외향 반구(90°)를 가정한 `OUTWARD_HEMISPHERE_SCREENING`이며 가정이다.
- **결과:** 상한은 패턴 형태가 없어 모든 pointing에서 같다. 그래서 공칭, victim 지향, 반구 내 최악의 세 상태가 같은 천장값을 가지며, gimbal 범위 최대 결합은 `상한 + G_RX − FSPL`이다.
- **도달성:** 20개 조합 중 boresight를 victim에 맞출 수 있는 것(victim이 외향 반구 안)은 KAA_1 → SBA_NADIR(88.3°) 1개뿐이다. 나머지는 victim이 반구 뒤쪽(91.0~158.5°)이라 boresight와 victim 사이에 최소 1~68.5° 오프셋이 남는다. 상한은 이 오프셋에서도 낮추지 않았으므로 **이 조합들의 결과는 특히 보수적**이다.
- 출력: `kaa_vb_gimbal.csv`(상태별), `kaa_vb_max_coupling.csv`(KAA → victim별 최대 결합).

## 3. ITU 불요방사 source 적용

- **source(규격):** ITU RR Appendix 3 / ITU-R SM.329-13 우주국 spurious 한계 = 평균 전력 대비 min(43 + 10log₁₀P[W], 60) dB 감쇠. P = 70 W(48.451 dBm)이면 43 + 18.45 = 61.45이므로 **60 dB(−60 dBc)** 다. 4 kHz 기준 대역폭이면 안테나 입력(conducted)에서 **−47.57 dBm/Hz**다(48.451 − 60 − 36.02).
- 기준 대역폭 4 kHz와 조항은 저장소의 기존 ITU 관례를 따랐고 이번에 ITU 원문과 대조하지 않았다. Ka 지구탐사 하향링크에의 적용과 계약 채택은 미확정이다. 이 값은 대역 내 평탄한 broadband 등가 상한이며 점별 보장이 아니다.
- **분리:** ITU 감쇠(−60 dBc)와 KAA 안테나 이득은 별개 항이다. 기준면이 안테나 입력이므로 방사 응답을 따로 더한다. `PSD_RX = PSD_TX,spur + G_KAA(f_victim) − FSPL + G_RX(f_victim)`. 저이득을 spurious 감쇠로 대체하지 않았다.
- **필터 0 dB:** WR-42 below-cutoff, 급전선, BPF, diplexer, PA 내부 필터링, 도파관 길이 감쇠를 적용하지 않았다(설계 근거 부족). 따라서 결과는 안테나 방사만 고려한 conservative screening이다.

## 4. Victim-band PSD 결과와 요구 추가 억제량

기준면은 victim 포트, 필터 0 dB, 자유공간 직접 결합이다. 요구 추가 억제량 = max(0, victim 포트 PSD − 허용 PSD), 대역 내 최댓값, 두 KAA 중 최악 쪽이다. 허용 PSD는 kT₀ + NF + (I/N)max로 receiver baseline의 공학 가정이다.

| victim | 허용 PSD [dBm/Hz] | Tier 3 상한 [dB] | 0 dBi | 10 dBi | 20 dBi |
|---|---|---|---|---|---|
| ISL X (10.55–10.65 GHz) | −177 | 86.1 ~ 87.2 | 58.0 ~ 59.0 | 68.0 ~ 69.0 | 78.0 ~ 79.0 |
| S-TC (2025–2110 MHz) | −177 | 84.6 ~ 89.2 | 69.4 ~ 74.0 | 79.4 ~ 84.0 | 89.4 ~ 94.0 |
| GPS L1 (1563–1588 MHz) | −178 | 59.0 ~ 63.9 | 45.8 ~ 50.8 | 55.8 ~ 60.8 | 65.8 ~ 70.8 |
| GPS L2 (1217–1238 MHz) | −178 | 79.0 ~ 86.1 | 67.7 ~ 74.8 | 77.7 ~ 84.8 | 87.7 ~ 94.8 |
| GPS L5 (1164–1189 MHz) | −178 | 81.1 ~ 86.6 | 70.1 ~ 75.5 | 80.1 ~ 85.5 | 90.1 ~ 95.5 |
| SAR X (9387.5–9912.5 MHz) | −175 | 산출 불가 | 산출 불가 | 산출 불가 | 산출 불가 |

- **범위:** 각 칸은 KAA_1/2 × 해당 victim 안테나 조합(S는 2개, GPS는 2개, ISL 1개)의 최소~최대다. 같은 결합 모델로 계산한 값이며 10 dB 단위 이득 변화는 요구량을 같은 dB만큼 바꾼다.
- **Tier 구분:** 모든 칸은 Tier 3(상한 또는 가정 이득)이다. Tier 1/2 결과는 없다. 0/10/20 dBi 열은 가정 민감도이지 KAA 이득이 아니다.
- **대표 worst case:** KAA_2 → SBA_NADIR(S-TC): Tier 3 상한 15.2 dBi에서 victim 포트 PSD −87.8 dBm/Hz, 허용 −177 dBm/Hz 대비 89.2 dB 초과. 직접 경로가 열린(LOS CLEAR) 조합 중 PSD가 산출된 것은 ISL(86.1~87.2 dB)과 SBA_NADIR(85.4~89.2 dB)다.
- **GPS 경로는 모두 hull에 의한 가림(LOS BLOCKED)이다.** 이 분석은 자유공간 결합이라 가림을 감쇠로 인정하지 않았다. 가림·회절·산란은 미모델이며 결합을 높일 수도 낮출 수도 있다.
- **GPS L1이 L2/L5보다 요구량이 20 dB 안팎 낮은 이유:** victim GPS 안테나의 L1 이득이 같은 방향에서 L2/L5보다 낮게 저장된 CST 시뮬레이션 데이터 때문이다(KAA 방향 이득 약 −32~−35 dBi 대 −10~−17 dBi). 이 데이터 자체는 이번에 검증하지 않았다.
- **SAR:** KAA 쪽 항만 산출했다. 안테나 이득 이전 PSD는 상한에서 −81.7 dBm/Hz(0/10/20 dBi에서 −108.8/−98.8/−88.8)이고, 허용 −175 dBm/Hz와의 차이 93.3 dB에 SAR 안테나의 KAA 방향 이득[dBi]을 더한 값이 요구 추가 억제량이다. SAR 응답은 `DEFERRED_CLOSED_NETWORK`라 미확정이다.
- **근거리 주의:** 자유공간 Friis는 원거리 식이다. X-band에서 2D²/λ = 3.1~3.4 m이고 KAA–ISL(1.8~2.3 m)과 KAA–SAR(2.9~3.0 m) 거리는 이보다 짧아 `NEARFIELD_FRIIS_UNVERIFIED`로 표시했다. L/S 조합은 원거리 조건을 만족한다.

## 5. Receiver criterion

- 평가한 기준은 1차 PSD mask(tuning 대역 전체, 포트 PSD ≤ 허용 PSD) 하나다. 이 기준에서 Tier 3 상한 기준 18개 조합 전부가 초과(FAIL)다. FAIL은 "ITU 상한 + 안테나 방사만" 가정에서 해당 기준을 넘는다는 뜻이다.
- 채널 적분 I/N, C/N0, J/S, 블로킹·압축은 이번에 평가하지 않았다(미평가). 필요한 입력은 수신기 데이터와 적분 대역폭 확정이다.

## 6. Filter / suppression requirement

- 위 4절의 값은 **송신 측 추가 억제(TX 불요방사 억제)** 요구량이다. RX blocker rejection이 아니다.
- 이 요구량은 ITU 규격 송신기 + 안테나 방사만의 조건이다. 실제 도파관 cutoff·필터 감쇠를 확보하면 그만큼 줄어든다. 필터 데이터가 없어 얼마나 줄지 판단하지 않았다.
- 어떤 값도 검증된 필터 규격이 아니다. KAA 이득을 실제로 확정(Tier 1/2)하면 같은 엔진으로 다시 계산한다.

## 7. 입력 누락 및 분석 한계

- **추가 입력(우선순위순):** ① 실제 Cassegrain CAD와 feed throat 여기 정의, victim 대역 feed 패턴 또는 solver 환경 ② 실제 gimbal hard-stop·keep-out ③ SAR 안테나 응답 ④ 필터·cutoff 설계 데이터(적용 시) ⑤ ITU 한계의 RBW·조항 원문 대조와 계약 채택 확인 ⑥ 수신기 적분 대역폭·블로킹 데이터.
- **한계:** 상한은 직접파 자유공간 기준이다. hull 산란·회절·가림, 근거리 효과, 구 반경 가정(feed 부피 미포함), 두 KAA의 동시 송신은 모델링하지 않았다.
- **mesh 확인 시도:** 이번 작업 중 CST에서 맨 reflector의 mesh cell 수를 확인하려 했으나 `Mesh.Update`가 응답하지 않아 420초 후 중단했다. 따라서 Learning Edition 가능성은 추정 수준이다.

## 8. Secondary blocker analysis

Ka 기본파 blocker와 근거리 분석은 이번 작업에서 확대하지 않았다. 기존 결과(`RFI_분석결과보고서.md` Appendix A)를 그대로 유지한다.

## Appendix. 파일과 출처

| 파일 | 내용 |
|---|---|
| `data/antenna_port_response_cst/KAA/kaa_victim_band_response.csv` | band별 Tier 3 상한, 모델 유형, reflector 포함 여부, realized gain/directivity 구분, 정규화 유효성 |
| `data/rfi_psd/kaa_itu_spurious_source.csv` | ITU 불요방사 source 6행(조회 키: `victim_band`) |
| `output/claude/results/kaa_vb_model_feasibility.csv` | reflector 포함 가능 여부와 mesh 추정 |
| `output/claude/results/kaa_vb_pair_summary.csv`, `kaa_vb_psd_results.csv` | pair × 이득 시나리오 요약 / 주파수별 전체 행(`pair` 키) |
| `output/claude/results/kaa_vb_gimbal.csv`, `kaa_vb_max_coupling.csv` | gimbal 상태 / KAA→victim 최대 결합 |
| `output/claude/run_kaa_victimband_analysis.m`, `src/+rfscreen/+kaa/KaaVictimBandBound.m` | 실행 스크립트 / 상한 모델 |

재현: 저장소 루트에서 `octave-cli --no-gui --norc --eval "run('output/claude/run_kaa_victimband_analysis.m')"`. 실행 시점의 base commit과 working tree 상태는 `output/claude/results/run_provenance.csv`에 기록된다. 이 보고서는 Claude worker의 독립 산출물이며 `output/codex`의 수치를 가져오지 않았다. 다른 worker의 untracked 위성체 모델은 존재 확인에만 참조했다.
