# RFI 간섭 해석 결과보고서 — 단순화 위성체 baseline

**결론.** 이번 판은 최종 RFI 판정이 아니다. 독립 분석을 위한 **분석 틀**을 정리한 판이다.
- 1차 RFI 기준은 피간섭원 수신 대역의 불요방사 전력밀도(PSD, dBm/Hz)다. 수신기별 허용 PSD는 GPS −178 dBm/Hz, S-TC −177 dBm/Hz, ISL −177 dBm/Hz이고, 피간섭원 포트에서 비교한다.
- 송신기 불요방사(OOB/spurious) 규격이 하나도 입력되지 않았다. 그래서 모든 pair의 PSD margin과 적합 판정은 **보류**다.
- 대신 계산이 끝난 결합으로 각 pair의 **최대 허용 TX 불요방사 PSD**를 산출했다. 가장 엄격한 값은 S-TM → 반대편 S-TC의 **−107.9 dBm/Hz**(TX 안테나 포트, 필터 0 dB 기준)다. 반송파 36.99 dBm 대비로는 −144.9 dBc/Hz다.

## 1. Executive Summary

- **S-TC TX filter design (Task 1, 별도 보고서 [S-TC_TX_억제요구_결과보고서.md](S-TC_TX_억제요구_결과보고서.md)):** 이 행들만 ITU RR AP3 / SM.329 source(5 W → −49.02 dBm/Hz, 안테나 포트)를 입력해 계산했다. 아래 나머지 pair의 "규격 미입력" 서술은 그 밖의 TX에 해당한다.

  | S-TC TX (legacy id: S_TM_TX) victim | Effective source [dBm/Hz] | Victim PSD [dBm/Hz] | Limit [dBm/Hz] | Required suppression [dB] | First PASS | Design target | Confidence |
  |---|---|---|---|---|---|---|---|
  | GPS L1 | −49.02 | −130.00 | −178 | 48.00 | 60 dB | 60 dB | 시뮬레이션 |
  | GPS L2 | −59.02 (−10 dB rescaling) | −107.55 | −178 | 70.45 | 80 dB | 90 dB | ENGINEERING_BOUND — L1-referenced 10 dB port-mismatch rescaling |
  | GPS L5 | −59.02 (−10 dB rescaling) | −107.13 | −178 | 70.87 | 80 dB | 90 dB | ENGINEERING_BOUND — L1-referenced 10 dB port-mismatch rescaling |
  | S-TM RX (legacy id: S_TC_RX) | −49.02 | −118.11 | −177 | 58.89 | 60 dB | 70 dB | 시뮬레이션 |
  | ISL RX | −49.02 | −137.74 | −177 | 39.26 | 40 dB | 50 dB | 시뮬레이션 |

  억제 조건: 요구량은 0 dB 추가 필터 기준 총 요구량 max(0, PSD − limit)이다. First PASS는 0/40/60/70/80 dB screening 중 처음 margin ≥ 0인 값이다. Design target은 요구량 + 10 dB reserve를 10 dB 단위로 올린 계획값이다. owner baseline −58 dBm/Hz를 쓰면 L2/L5 요구량은 +1.02 dB이며 first PASS는 바뀌지 않는다. SAR RX와 동일 포트 경로는 미판정이다.

- **판정 범위:** 피간섭원 대역 결합 계산은 34개 TX→RX 조합에서 끝났다(conducted 16, Ka radiated 18).
  - 송신기 불요방사 규격이 없어 PSD 적합 판정은 **0개 조합에서 수행**했다. 모두 최종 판정 보류다.
  - 수신기 블로킹 판정도 수신기 데이터가 없어 보류다.
- **대표 worst case**(산출: 허용 PSD − 결합. 송신기 규격이 이 값보다 높으면 기준 초과):

  | pair | 피간섭원 대역 | 피간섭원 대역 결합 [dB] | 최대 허용 TX PSD [dBm/Hz] | 기준면 |
  |---|---|---|---|---|
  | S-TM → 반대편 S-TC | 2025–2110 MHz | −70.2 ~ −69.1 | **−107.9** | TX 안테나 포트 (conducted) |
  | S-TM@ZENITH → GPSA_1 | GPS L1 1563–1588 MHz | −81.4 ~ −81.0 | **−97.0** | TX 안테나 포트 |
  | KAA_2 → S-TC@NADIR | 2025–2110 MHz | −55.6 ~ −55.4 (수신측만) | **−121.6** | 방사 EIRP PSD |

- **receiver criterion:** PSD mask(1차, tuning 대역 전체)와 채널 적분 I/N(2차)을 분리했다.
  - GPS 적분 대역폭 20.46 MHz는 가정이다.
  - S-TC 5.5296 kHz는 engineering baseline(4096 bps, RRC 0.35)이다.
- **최종 판정에 필요한 입력:**
  1. S-TM·ISL·Ka 송신기의 피간섭원 대역 불요방사 규격. 단위, 기준 대역폭, 기준면, 출처를 함께 넣는다. Ka는 방사 EIRP PSD가 필요하다.
  2. 실제 TX 필터 감쇠 table
  3. 수신기 블로킹·P1dB·프리셀렉터 데이터
- **필터 scenario:** 0/40/60/70/80 dB screening 감쇠와 주파수별 table을 넣어 sweep할 수 있다. 0/40/60/70/80 dB는 설계값이 아니다.
- **Secondary:** 기본파 대역 밖 blocker 노출은 유지했지만 1차 요구사항이 아니다. 대표값은 S-TM@ZENITH → GPSA_1 −21.3 dBm @ 2.25 GHz, S-TM → 반대편 S-TC −32.3 dBm @ 2.25 GHz다(블로킹 판정 보류).
- **KAA 저주파 방사응답 후속:** KAA의 victim band 방사응답은 계산할 수 없어(`GAIN_BOUND_ONLY`) 최대 이득 상한으로 닫았고, ITU 불요방사 source와 결합한 요구 추가 억제량을 별도 보고서 [KAA_저주파_방사응답_결과보고서.md](KAA_저주파_방사응답_결과보고서.md)에 정리했다. 이 보고서의 수치는 바꾸지 않았다.

## 2. 주요 RFI 결과 / 요구 억제도 / margin

- **PSD margin과 요구 추가 억제량은 산출하지 않았다.** 송신기 불요방사 입력이 없기 때문이며(미확정), 0이나 임의 값으로 대체하지 않았다.
- 정의(규격 입력 시 같은 엔진이 계산):
  - margin = 허용 PSD − 피간섭원 포트 PSD. 양수는 여유, 음수는 초과다.
  - 요구 추가 억제량 = max(0, 피간섭원 포트 PSD − 허용 PSD) [dB]
- **계산 검증(reference, 산출):** 다른 위성 S → L 예를 같은 엔진으로 재현했다.

  | 필터 감쇠 [dB] | 0 | 40 | 60 | 70 | 80 |
  |---|---|---|---|---|---|
  | 피간섭원 포트 PSD [dBm/Hz] | −120 | −160 | −180 | −190 | −200 |
  | margin vs GPS −178 dBm/Hz [dB] | −58 (기준 초과) | −18 (기준 초과) | +2 (기준 충족) | +12 | +22 |
  | 요구 추가 억제량 [dB] | 58 | 18 | 0 | 0 | 0 |

  이 표는 엔진 검증용 외부 reference이며 이 위성의 결과가 아니다.

## 3. Victim-band PSD 결과 (메인)

**결과.** 34개 조합의 피간섭원 대역 결합과 최대 허용 TX PSD를 산출했다. 송신기 규격이 없어 PSD 비교는 보류다.

- **결합 계산(산출, CST 시뮬레이션 데이터 기반):** 결합은 **피간섭원 주파수에서** 계산했다. 송신 운용 주파수의 이득은 재사용하지 않았다.
  - conducted 규격용 결합 = G_TX(f_v) + G_RX(f_v) − FSPL(f_v)
  - 방사 EIRP 규격용 결합 = G_RX(f_v) − FSPL(f_v)
- **최대 허용 TX PSD** = 허용 PSD − 결합 + 필터 감쇠. 아래는 필터 0 dB 값이다. 필터 X dB이면 X dB 완화된다.
- 범위는 각 대역 21점 중 최악점이다.

| 간섭원 → 피간섭원 | 피간섭원 대역 | conducted 결합 [dB] | 최대 허용 TX PSD @ TX 안테나 포트 [dBm/Hz] | 최대 허용 방사 EIRP PSD [dBm/Hz] |
|---|---|---|---|---|
| S → L: S-TM@ZENITH → GPSA_1 / GPSA_2 | L1 1563–1588 MHz | −81.4 ~ −81.0 / −86.5 ~ −86.1 | −97.0 / −91.9 | −108.6 / −103.6 |
| S → L: S-TM@NADIR → GPSA_1 / GPSA_2 | L1 | −106.9 ~ −105.4 / −105.0 ~ −103.6 | −72.6 / −74.4 | −95.2 / −94.7 |
| S → L: S-TM → GPSA_1/2 | L2, L5 | 미확보 (S 안테나 L2/L5 응답 정규화 불안정) | 보류 | −131.6 ~ −115.2 |
| S → S-TC: S-TM → 반대편 S-TC | 2025–2110 MHz | −70.2 ~ −69.1 | **−107.9** | −119.2 / −118.3 |
| S → ISL: S-TM@NADIR / ZENITH → ISL | 10.55–10.65 GHz | −89.2 ~ −88.7 | −88.2 / −88.3 | −93.9 / −96.9 |
| ISL → L: ISL → GPSA_1 / GPSA_2 | L1 / L2 / L5 | −122.2 ~ −100.7 | −58.3 ~ −55.8 (L1), −77.3 ~ −74.7 (L2·L5) | −125.2 ~ −98.8 |
| ISL → S-TC: ISL → S-TC@ZENITH / NADIR | 2025–2110 MHz | −95.2 ~ −94.3 / −98.7 ~ −97.7 | −82.7 / −79.3 | −120.2 / −116.5 |
| Ka → L: KAA_1/2 → GPSA_1/2 | L1 / L2 / L5 | 해당 없음 (KAA 저주파 응답 없음) | 보류 | −98.4 ~ −93.4 (L1), −122.4 ~ −115.3 (L2), −123.1 ~ −117.6 (L5) |
| Ka → S-TC: KAA_1/2 → S-TC | 2025–2110 MHz | 해당 없음 | 보류 | −121.6 ~ −116.9 |
| Ka → ISL: KAA_1/2 → ISL | 10.55–10.65 GHz | 해당 없음 | 보류 | −105.5 / −106.6 |

**해석:**
- S-TM은 반대편 S-TC 대역에서 결합이 가장 크다. 그래서 같은 위성의 S-band 송신 잡음이 가장 엄격한 규격 요구가 된다.
- ISL → GPS는 GPS 안테나의 10.6 GHz 응답이 mesh 한도로 없다. 하지만 메인 분석은 L 대역 응답만 쓰므로 계산이 끝났다.
- **Ka:**
  - 방사 EIRP PSD 규격이 주어지면 KAA의 S/L/X 대역 패턴 없이 계산된다(피간섭원 PSD = EIRP PSD − FSPL + G_RX).
  - conducted 규격만 주어지면 KAA의 해당 대역 방사 응답이 필요하다. 현재 그 응답이 없으므로 conducted 규격으로는 판정이 보류된다.
  - 26 GHz 반사판 패턴은 S/L/X로 외삽하지 않는다.
- 기본파 blocker 결합과 다른 값이다. 예: S-TM@ZENITH → GPSA_1은 2.25 GHz에서 −58.3 dB, L1에서 −81.2 dB다.

상세: `results/psd_pair_summary.csv`(pair × 필터 scenario), `results/victim_band_psd_results.csv`(주파수별). 그림: `figures/psd_emission_limit_CASE_SBA1_L1.svg`.

## 4. Receiver criterion

**결과.** 1차 기준은 수신 tuning 대역 전체의 PSD mask다. 채널 적분은 2차 receiver-performance 평가에만 쓴다.

| 수신기 | PSD 판정 대역 | 허용 간섭 PSD [dBm/Hz] | 2차 적분 대역폭 | 근거 유형 |
|---|---|---|---|---|
| GPS L1 / L2 / L5 | 1563–1588 / 1217.37–1237.83 / 1164–1189 MHz | −178 | 20.46 MHz | NF 2 dB·I/N −6 dB는 가정(engineering baseline). 20.46 MHz는 **가정**(신호 main-lobe 폭, 수신기 대역폭 미확정) |
| S-TC | 2025–2110 MHz | −177 | 5.5296 kHz | NF 3 dB·I/N −6 dB 가정. 4096 bps·RRC 0.35 engineering baseline |
| ISL | 10.55–10.65 GHz | −177 | 20 MHz | 가정·잠정 |
| SAR | 9.3875–9.9125 GHz | −175 | 525 MHz | **보류**: SAR 안테나 패턴 미확정 |

- 잡음 PSD는 −174 dBm/Hz + NF다(290 K 관례).
- GPS의 −130 dBm은 원하는 신호의 기준이며 간섭 기준이 아니다.
- GPS 판정 대역은 CST 응답이 계산된 범위로 제한했다(외삽 없음).
- C/N0·J/S는 GNSS 수신기 모델이 필요해 미평가다.
- `rf_systems.csv`의 S-TC 128 kbps/200 kHz와 4096 bps 기준이 다르다. PSD 기준은 대역폭과 무관해 영향이 없다. 표시는 유지했다.

## 5. Filter / suppression requirement

**결과.** 필터 감쇠는 scenario로 sweep한다. 실제 필터 데이터가 없어 요구 감쇠는 산출하지 않았다.

- **지원 방식:**
  - 일정 감쇠: 0/40/60/70/80 dB. 설계값이 아닌 screening scenario다.
  - 주파수별 감쇠 table: dB 선형 보간. 범위 밖은 평가하지 않는다.
- 모든 결과에 scenario 이름·감쇠·출처를 기록한다.
- **필터가 의미하는 것**(TX 불요방사 억제이며, 수신기 blocker rejection과는 다르다):
  - 송신기 출력(필터 전) 기준 규격: TX 출력 필터
  - 필터 후·안테나 포트·방사 EIRP 기준 규격: 규격에 포함된 것 외의 추가 외부 필터
- 필터 후 케이블 손실을 모르면 0 dB를 적용한다(보수적). 이 사실을 결과에 표시한다.
- 단위: 필터 감쇠는 dB, 반송파 상대 방사는 dBc/Hz(또는 기준 대역폭당 dBc), discrete spur·고조파는 dBm/dBc다. spur는 PSD mask에 넣지 않고 수신 채널 적분에서 다룬다.

## 6. 입력 누락 및 분석 한계

**결과.** 45개 TX→RX 조합 중 바로 PSD 판정이 가능한 조합은 없다. 다음 입력이 들어오면 같은 엔진으로 판정된다.

| 상태 | 조합 수 | 완료된 계산 | 막힌 평가 / 필요한 입력 |
|---|---|---|---|
| 결합 계산 완료, TX 규격 미입력으로 판정 보류 | 16 | S-TM → GPS L1·S-TC(반대편)·ISL, ISL → GPS L1/L2/L5·S-TC의 conducted 결합 | S-TM·ISL 송신기의 해당 대역 불요방사 규격 |
| Ka: 수신측 결합 완료, 방사 PSD 미입력으로 판정 보류 | 18 | Ka → GPS·S-TC·ISL의 G_RX − FSPL | Ka 송신기 방사 EIRP PSD(또는 conducted 규격 + KAA 해당 대역 방사 응답) |
| 결합 입력 미확보로 conducted 판정 보류 | 8 | S-TM → GPS L2/L5의 수신측 결합 | S 안테나 L2/L5 응답(현재 정규화 불안정, 시뮬레이션 데이터 미사용) 또는 S-TM 방사 EIRP PSD |
| 같은 안테나 포트 | 3 | — | 다이플렉서 격리, TX 잡음 PSD |

- **공통 한계:**
  - 모든 결합은 자유공간 CST 시뮬레이션 데이터다. 설치 구조 산란은 포함하지 않았다.
  - 두 독립 컷으로 3D를 근사했다.
  - TX 필터 실측 table과 케이블 손실이 없다.
- 입력 위치와 schema는 Appendix B에 있다. 조합별 목록: `results/rfi_analysis_readiness.csv`.

## 7. Secondary blocker analysis

**결과.** 기본파 대역 밖 blocker 노출(TX 반송파 주파수의 피간섭원 포트 전력)은 기존 값 그대로다. 수신기 프리셀렉터·블로킹 한계·P1dB가 없어 모든 경로가 최종 판정 보류다.

| 대표 경로 | blocker 포트 전력 [dBm] | 주파수 |
|---|---|---|
| S-TM@ZENITH → GPSA_1 | −21.3 | 2.25 GHz |
| S-TM → 반대편 S-TC | −32.3 | 2.25 GHz |
| ISL → S-TC | −58.9 / −59.0 | 10.6 GHz |
| Ka → ISL (공칭 / 짐벌 최악) | −63.4 / −63.2, 최악 −37.2 | 25.5–27 GHz |

- "blocker 전력 − 수신 대역 내 허용치"(예: S-TM → GPSA_1 83.5 dB)는 **진단용 screening 차이**다. 검증된 수신기 OOB rejection 요구값이 아니다.
- 이 경로가 막힌 조합(피간섭원 안테나의 송신 주파수 응답이 mesh 한도로 없음: ISL → GPS, Ka → S/GPS/SAR)도 메인 PSD 분석에는 영향이 없다.
- 상세: `results/oob_blocking_results.csv`, `results/pair_results.csv`. 그림: `figures/oob_blocker_exposure_CASE_SBA*_L1.svg`.

## Appendix A. Ka near-field (요약)

- Ka 기본파 blocker는 KAA 반사판 aperture 근거리 모델로 계산했다. CST feed 시뮬레이션 데이터와 데이터시트 주빔으로 검증된 등가 포물면을 쓴다.
- 이 모델은 원거리에서 기존 반사판 패턴으로 수렴한다(오차 ≤ 0.01 dB).
- 직접 반사판 장만 계산하며 구조 산란은 포함하지 않았다. 따라서 상한이 아니다.
- 포트 전력은 KAA → ISL만 산출됐다. S/GPS/SAR는 피간섭원의 Ka 응답이 없어 보류다.
- 이 내용은 secondary blocker 자료다. Ka의 메인 RFI 경로는 §3의 victim-band PSD다.
- 상세: `RFI_분석근거.md` §10, `results/ka_nearfield_pair_results.csv`, `ka_gimbal_worstcase.csv`, `ka_nearfield_validation.csv`, `ka_input_availability.csv`.

## Appendix B. 입력·산출물·상태 코드·provenance

**입력**(`data/rfi_psd/`):

| 파일 | 내용 | 현재 상태 |
|---|---|---|
| `tx_emission_masks.csv` | TX source 불요방사 규격: tx_system, victim_band, frequency_hz 또는 frequency_lo/hi_hz, emission_type, level, unit, reference_bandwidth_hz, reference_plane, carrier_frequency_hz, filter_state, standard_or_source, provenance, assumption_class | 비어 있음 |
| `reference_scenarios.csv` | 외부·사용자 reference(같은 열 + scenario_id, rx_receiver, coupling_override_db) | S → L 예 1건 |
| `filter_scenarios.csv` | FLAT 0/40/60/70/80 dB, TABLE 추가 가능 | screening 5건 |
| `tx_chain_losses.csv` | 필터 후 케이블 손실 | 비어 있음 |
| `receiver_baseline.csv` | 수신기 PSD 기준·tuning 대역·적분 대역폭·출처 | 6 수신기 |

**산출물**(`results/`):
- 메인: `psd_pair_summary.csv`, `victim_band_psd_results.csv`, `rfi_analysis_readiness.csv`
- 수신기: `receiver_baseline.csv`, `receiver_integrated_results.csv`
- secondary: `oob_blocking_results.csv`, `pair_results.csv`, `band_results.csv`, `aggregate_by_victim.csv`, `sensitivity.csv`, `sar_assessment.csv`
- Ka: `ka_*.csv`
- 그림: `figures/`

**상태 코드 매핑:**

| CSV 상태 | 의미 |
|---|---|
| `READY_FOR_PSD_ANALYSIS` | 규격·결합 모두 있음, 판정 가능 |
| `EMISSION_SPEC_MISSING` | 결합 완료, TX 규격 미입력으로 판정 보류 |
| `KAA_RADIATED_PSD_OR_LOWBAND_RESPONSE_REQUIRED` | Ka 수신측 결합 완료, 방사 EIRP PSD(또는 KAA 해당 대역 응답) 필요 |
| `KAA_VICTIM_BAND_RADIATION_RESPONSE_MISSING` | Ka conducted 규격이 있으나 KAA 해당 대역 응답이 없어 보류 |
| `COUPLING_INPUT_MISSING` | 결합 입력 미확보로 보류 |
| `NOT_APPLICABLE_SAME_PORT` | 같은 안테나 포트(다이플렉서 격리 필요) |
| `PASS` / `FAIL` | 해당 PSD 기준 충족 / 초과 |
| `PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN` | blocker 포트 전력 계산 완료, 블로킹 판정 보류 |
| `SECONDARY_OOB_BLOCKER_ANALYSIS` | blocker 결과의 분석 등급(1차 요구사항 아님) |

**Provenance:**
- 이 보고서는 고정 commit SHA를 적지 않는다.
- 실행별 기준 commit(실행 시 HEAD)과 작업트리 상태(CLEAN/DIRTY)는 `results/run_provenance.csv`에 있다.
- 결과와 보고서가 저장된 commit은 `git log -- output/claude`로 확인한다. DIRTY 실행 결과는 해당 기준 commit 다음 commit에 함께 저장된다.
- 실행 환경: GNU Octave 9.2.0(MATLAB 미사용), CST 신규 계산 없음(`results/environment.txt`).
- 재현 순서: `run_ka_nearfield_analysis.m` → `run_rfi_analysis.m` → `run_psd_analysis.m` → `make_figures.m`.
- 엔진: `src/+rfscreen/+psd`, `src/+rfscreen/+kaa`
- 테스트: `tests/test_rfi_psd.m`, `tests/test_ka_nearfield.m`(결과: `results/test_suite_log.txt`)
- 방법 상세: `RFI_분석근거.md` §11–§12
