# RFI 간섭 해석 결과보고서 — 단순화 위성체 baseline

작성 2026-10-04. 실행 **GNU Octave 9.2.0**(MATLAB 미사용), 저장소 `main` @ `7f0db47`. CST 신규 계산은 하지 않았다.
- 무엇을 어떤 패턴으로 계산했는지: `RFI_분석근거.md`
- 행 단위 결과: `results/`
- 용어: 간섭원(interferer) / 피간섭원(victim)

## 1. 요약

- **실행 범위:** 6개 미션 조합 × 25 TX×RX = **150 pair 행**을 실제 계산했다.
  - **72행 평가**: 대역 밖 수신 레벨 60행 + Ka 근거리 추정 12행
  - **60행 INPUT_MISSING**: 피간섭원 안테나의 해당 대역 CST 응답 없음
  - **18행 NOT_EVALUATED**: 같은 안테나 포트
- **대역 관계:** 이번 RF baseline에서는 **모든 간섭원–피간섭원 쌍이 대역 밖**이다. 따라서 대역 내 기본파 간섭 전력은 없고 I/N 판정 대상도 없다.
- **핵심 지표:** 피간섭원 안테나 단자의 수신 레벨, 그리고 수신단이 이를 걸러야 하는 **필요 제거도**(수신 레벨 − 허용 레벨)다. 블로킹·포화·스퓨리어스는 P1dB/IIP3/emission mask가 없어 판정하지 않았다.
- **가장 큰 노출:** **S-band TM 송신(SBA_ZENITH) → GPS 수신(GPSA_1)**이다.
  - 수신 레벨 **−21.3 dBm**, 필요 제거도 **83.5 dB**(기준 패턴 변형 B: −20.0 dBm / 84.8 dB)
  - 원거리장 성립, LOS CLEAR이다. GPS L1·L2·L5 케이스 모두 같은 값이다(아래 §3.2).
- **가장 큰 필요 제거도:** **S TM ↔ 다른 SBA의 S TC**(nadir↔zenith)다.
  - 수신 레벨 −32.3 dBm, 필요 제거도 **91.7 dB**
  - TC 허용 레벨이 −124 dBm으로 가장 엄격하다. 경로가 선체를 관통(BLOCKED)하므로 자유공간 상한이다.
- **판정 보류인 큰 위험:**
  - **Ka → S TC / GPS**, **ISL → GPS**: 피간섭원 안테나의 Ka·X 대역 응답을 CST가 mesh 한도로 계산하지 못했다.
  - **KAA_1 조향**: 주빔을 SBA_NADIR 쪽으로 돌리면(반구 조향 가정 안) 피간섭원 이득 0 dBi 기준 약 **+4.6 dBm**, 필요 제거도 약 **129 dB**가 된다(근거리 추정).
  - **SAR**: 송신 2.5–5 kW 가정 시 S TC 단자에 **−11 ~ +12 dBm**(SAR 이득 −10~+10 dBi 가정), 필요 제거도 **113–136 dB**다.

## 2. 해석 조건

- **설치 패턴 정책:** 자유공간 우선이다. 승인된 설치 패턴은 0개이며, S 잠정 설치 결과는 민감도로만 썼다(§5.2).
- **ISL·Ka·SAR:** 자유공간이다. ISL은 활성 바인딩 `ISL_10P6`(10.55–10.65 GHz)을 쓴다.
- **이득 종류:**
  - 피간섭원 측은 간섭원 주파수에서의 **CST RealizedGain**(입사 전력 기준 total)이다.
  - 간섭원 측은 두 변형으로 계산했다.
    - **A**(기본): CST RealizedGain. Ka는 CST 반사판 응답이 없어 동결 패턴을 쓴다.
    - **B**: 동결 기준 패턴(SBA1/SBA4, ISL, Ka).
  - mismatch는 RealizedGain에 한 번만 들어 있고 추가 차감은 없다. 편파·차폐 손실도 적용하지 않았다.
- **주파수:** 송신 점유 대역(`rf_systems.csv`) 21점에서 계산한 뒤 선형 전력 평균을 냈다. 보간은 계산된 monitor 사이에서만 했다.
- **RF 기준값**(`rf_systems.csv`; 공개 표준과 engineering assumption이 섞여 있음, provenance는 원본 참고):

  | 시스템 | 대역 | 전력 / 수신 기준 | 허용 레벨 |
  |---|---|---|---|
  | S TM | 2.250 GHz / 2.7 MHz | 36.99 dBm | — |
  | S TC | 2.050 GHz / 0.2 MHz | NF 3 dB | −123.96 dBm |
  | GPS L1·L2·L5 | 20.46 MHz | NF 2 dB | −104.87 dBm |
  | ISL | 10.6 GHz / 20 MHz | 30 dBm, NF 3 dB | −103.96 dBm |
  | Ka | 26.25 GHz / 1.5 GHz | 48.45 dBm | — |

  I/N 기준은 모두 −6 dB이다.

## 3. 결과

### 3.1 평가된 pair (CASE_SBA1_L1, 대표; 물리 pair 12개)

| 간섭원 → 피간섭원 | 거리 [m] | LOS | 원거리장 | S21 A [dB] | 수신 레벨 A [dBm] | 필요 제거도 A / B [dB] |
|---|---|---|---|---|---|---|
| S_TM@SBA_ZENITH → GPS@GPSA_1 | 1.81 | CLEAR | OK | −58.3 | **−21.3** | **83.5** / 84.8 |
| S_TM@SBA_ZENITH → GPS@GPSA_2 | 2.90 | CLEAR | OK | −62.8 | −25.8 | 79.1 / 80.4 |
| S_TM@SBA_NADIR → S_TC@SBA_ZENITH | 2.67 | BLOCKED | OK | −69.3 | −32.3 | **91.7** / 87.0 |
| S_TM@SBA_ZENITH → S_TC@SBA_NADIR | 2.67 | BLOCKED | OK | −69.3 | −32.3 | **91.7** / 88.7 |
| S_TM@SBA_NADIR → GPS@GPSA_1 | 3.15 | BLOCKED | OK | −79.3 | −42.3 | 62.5 / 64.9 |
| S_TM@SBA_NADIR → GPS@GPSA_2 | 3.88 | BLOCKED | OK | −81.8 | −44.9 | 60.0 / 61.7 |
| Ka@KAA_1 → ISL_RX | 1.78 | CLEAR | 근거리(추정) | −93.4 | −45.0 | 59.0 / 59.0 |
| Ka@KAA_2 → ISL_RX | 2.34 | CLEAR | 근거리(추정) | −95.9 | −47.5 | 56.5 / 56.5 |
| S_TM@SBA_ZENITH → ISL_RX | 6.14 | CLEAR | OK | −93.9 | −56.9 | 47.1 / 48.2 |
| ISL_TX → S_TC@SBA_ZENITH | 6.14 | CLEAR | OK | −88.9 | −58.9 | 65.1 / 66.4 |
| ISL_TX → S_TC@SBA_NADIR | 6.56 | BLOCKED | OK | −89.0 | −59.0 | 65.0 / 68.9 |
| S_TM@SBA_NADIR → ISL_RX | 6.56 | BLOCKED | OK | −97.2 | −60.2 | 43.7 / 44.8 |

그림: `figures/required_rejection_CASE_SBA1_L1.svg`, `figures/required_rejection_CASE_SBA4_L1.svg`.

**A와 B 차이가 생기는 이유.** 같은 SBA 안테나라도 CST RealizedGain(형상 1개, 2.25 GHz 실제 응답)과 SBA1/SBA4 datasheet 포락선의 방향 이득이 측면·후면에서 수 dB 다르다.
- 예: SBA_NADIR TM 송신의 SBA_ZENITH 방향(θ = 151.7°) 이득은 A −10.2 dBi, B(SBA1) −14.8 dBi, B(SBA4) −16.3 dBi다.
- 그래서 S TM↔S TC 쌍의 결론은 A(더 보수적) 기준으로 읽기를 권한다.

**이전 보고서와 값이 다른 이유.** 이전 엔진 결과(동결 패턴 양 끝, Phase 8)는 GPS 피간섭원 이득으로 L1 자기 대역 패턴(−6.2 dBi)을 2.25 GHz에 재사용했다. 이번 해석은 GPS 안테나의 **2.25 GHz 실제 CST 응답**(−12.0 dBi, mismatch 포함, accepted fraction 0.109)을 썼다.
- 그 결과 수신 레벨이 −14.2 → **−21.3 dBm**으로 약 7 dB 낮아졌다.
- 이전 값은 수신 안테나의 운용 대역 이득으로 다른 대역을 대체해 과대평가된 것이다.

### 3.2 GPS L1 / L2 / L5 및 SBA1 / SBA4 조합

- **GPS 대역:** 간섭원 S TM(2.25 GHz)에 대한 GPS 안테나 응답은 같은 물리 안테나의 2.25 GHz 응답이다. 그래서 **L1·L2·L5 케이스의 수신 레벨이 같다**.
  - 세 수신기는 NF·필터 폭·I/N 기준이 같아 허용 레벨도 같고, 필요 제거도도 같다.
  - 대역별 차이는 수신기의 대역 밖 선택도·블로킹 특성에서만 생기는데, 이 입력이 없다.
- **SBA variant:** A는 형상 1개라 같은 값이다. B는 S TM 송신 측 이득이 바뀐다.
  - SBA_NADIR → GPSA_2: SBA1 −43.1 vs SBA4 −49.9 dBm
  - SBA_ZENITH → GPSA_1: −20.0 vs −20.3 dBm
  - 최대 노출 경로(SBA_ZENITH)는 variant에 거의 무관하다(0.3 dB).

### 3.3 피간섭원별 집계 (활성 TX 선형 합, CASE_SBA1_L1)

| 모드 | 피간섭원 | 활성 TX | 평가/누락 | 집계 수신 레벨 [dBm] | 필요 제거도 [dB] | 최대 기여 |
|---|---|---|---|---|---|---|
| SCREENING_ALL_TX | GPS@GPSA_1 | 5 | 2 / **3 누락** | −21.3 (하한) | 83.6 | S_TM@ZENITH |
| SCREENING_ALL_TX | S_TC@SBA_NADIR | 5 | 2 / 2 누락 (+1 자기포트) | −32.3 (하한) | 91.7 | S_TM@ZENITH |
| SCREENING_ALL_TX | ISL_RX | 5 | 4 / 0 | −42.8 | 61.2 | Ka@KAA_1 |
| NOM_ZENITH_KAA2 | GPS@GPSA_1 | 3 | 1 / 2 누락 | −21.3 (하한) | 83.5 | S_TM@ZENITH |
| NOM_NADIR_KAA1 | GPS@GPSA_1 | 3 | 1 / 2 누락 | −42.3 (하한) | 62.5 | S_TM@NADIR |
| NOM_NADIR_KAA1 | S_TC@SBA_NADIR | 3 | 1 / 1 누락 | −59.0 (하한) | 65.0 | ISL_TX |

- 누락 기여가 있는 집계는 `PARTIAL_LOWER_BOUND`로 표시했다(누락분을 0으로 넣지 않음).
- 전체 18개 모드×케이스 조합 결과: `results/aggregate_by_victim.csv`.
- 정상 운용 모드는 잠정 템플릿이다. `SCREENING_ALL_TX`는 운용 모드가 아닌 동시 활성 가정이다.

## 4. 판정 보류 (NOT_EVALUATED / INPUT_MISSING / MODEL_LIMIT)

| 항목 | 상태 | 이유 | 경계값(가정, `sensitivity.csv`) |
|---|---|---|---|
| Ka → GPS (KAA_1/2 → GPSA_1/2) | INPUT_MISSING | L 안테나 Ka 응답 없음(`RFC_L_KA_FREE` MESH_LIMIT 1.47 M cells) | 피간섭원 0 dBi 가정 시 −39.2 ~ −42.4 dBm, 필요 제거도 62.5–65.7 dB |
| Ka → S TC (KAA_1/2 → SBA_NADIR/ZENITH) | INPUT_MISSING | S 안테나 Ka 응답 없음(`RFC_S_KA_FREE` MESH_LIMIT 255,600) | 0 dBi 가정 시 −42.8 ~ −44.4 dBm, 필요 제거도 79.5–81.1 dB |
| ISL → GPS | INPUT_MISSING | L 안테나 X 대역 응답 없음(`RFC_L_HIGH_FREE` MESH_LIMIT 212,940) | 0 dBi 가정 시 −45.1 ~ −47.6 dBm, 필요 제거도 57.3–59.7 dB |
| KAA 조향 최악 | 가정 | KAA_1 → SBA_NADIR 방향만 반구 안(나머지 KAA 방향은 반구 밖) | 주빔 32.6 dBi, 피간섭원 0 dBi 가정: **+4.6 dBm**, 필요 제거도 **≈129 dB**(근거리 추정) |
| S TM ↔ 같은 SBA의 S TC, ISL TX ↔ ISL RX | NOT_EVALUATED | 같은 포트: 다이플렉서/T-R 격리, 송신 잡음 입력 없음 | — |
| 블로킹·포화·IM3 | NOT_EVALUATED | 수신기 P1dB/IIP3/블로킹 데이터 없음(NaN 유지) | — |
| 송신 스퓨리어스·고조파 | NOT_EVALUATED | emission mask 없음 | 참고: S TM 4차 고조파 9.0 GHz는 SAR 평가대역(8.9–10.4) 안이지만 rf_systems SAR 대역(9.39–9.91) 밖 |
| GNSS 최종 판정 | 보류 | I/N은 임시 기준. 최종은 C/N0·J/S | — |

## 5. 민감도

### 5.1 KAA 조향

반구 조향 가정에서 주빔이 피간섭원 방향을 향할 수 있는 조합은 **KAA_1 → SBA_NADIR**뿐이다.
- 이 경우 S 안테나의 Ka 응답이 없어 절대 판정은 보류다. 그래도 피간섭원 0 dBi 가정 시 필요 제거도가 약 129 dB다.
- **운용상 KAA_1의 SBA_NADIR 방향 지향 금지(keep-out) 검토를 권한다.**
- 반구는 하드웨어 한계가 아닌 단순화 가정이다.

### 5.2 S 잠정 설치 ΔG (기본 결과에 미반영)

방법: `RFC_S_LOW_SBA_{NADIR,ZENITH}_R1P75` − `RFC_S_LOW_FREE_M4R10`, `realized_gain_dbi`, 2.2/2.25/2.3 GHz.

| pair | ΔG [dB] | 수신 레벨 A → 설치 반영 [dBm] |
|---|---|---|
| S_TM@ZENITH → GPSA_1 | +0.1 / +0.3 / +0.4 | −21.3 → −21.1 |
| S_TM@ZENITH → GPSA_2 | +0.1 / +0.3 / +0.4 | −25.8 → −25.5 |
| S_TM@NADIR → GPSA_1 | −1.9 / −2.0 / −1.9 | −42.3 → −44.2 |
| S_TM@NADIR → GPSA_2 | −3.7 / −3.9 / −3.5 | −44.9 → −48.6 |
| S_TM ↔ S_TC (양 SBA 국부 구조 반영) | −1.6 / −1.5 / −1.2 | −32.3 → −33.7 |

- 결론(최대 노출 경로, 필요 제거도 순위)은 바뀌지 않는다.
- 이 결과는 구조 범위·mesh 수렴이 확인되지 않았다(R3/R4/R5 미충족). **최종 설치 패턴이 아니며 참고 비교 전용이다.**

### 5.3 SAR (패턴 미결합, 가정 민감도)

조건: SAR 송신 9.39–9.91 GHz, 2.5 kW(63.98 dBm) / 5 kW(66.99 dBm), SAR 이득 −10/0/+10 dBi 가정. 피간섭원의 SAR 대역 RealizedGain은 CST 실제 데이터다.

| 피간섭원 | 거리 [m] | LOS | 피간섭원 이득 [dBi] | 수신 레벨 범위 [dBm] | 필요 제거도 [dB] |
|---|---|---|---|---|---|
| S_TC@SBA_NADIR | 3.13 | CLEAR | −3.0 | −11.0 ~ +12.0 | 112.9 ~ 135.9 |
| S_TC@SBA_ZENITH | 3.66 | BLOCKED | −2.8 | −12.1 ~ +10.9 | 111.8 ~ 134.8 |
| ISL_RX | 3.56 | BLOCKED | −17.2 | −26.4 ~ −3.4 | 77.5 ~ 100.6 |
| GPS@GPSA_1/2 | 2.43 / 2.11 | BLOCKED | 없음 | INPUT_MISSING | — |

- **SAR가 피간섭원일 때** SAR 위치 0 dBi 기준 간섭원 측 레벨은 S_TM@NADIR −17.0, S_TM@ZENITH −23.5, Ka@KAA_1 −36.8, Ka@KAA_2 −38.6, ISL −48.0 dBm이다. SAR 이득과 SAR 수신 기준이 없어 판정하지 않았다.
- **해석:** SAR 송신 전력이 실제로 kW급이면 S TC 수신단이 가장 큰 제거도(>110 dB)를 요구한다. SAR 안테나 패턴, 실제 전력, 듀티, 송신 마스크가 SAR 영향 판정의 선결 입력이다.
- 그림: `figures/sar_assumption_required_rejection.svg`.

## 6. ISL 운용 대역 변경 영향

ISL은 10.6 GHz(10.55–10.65)로 해석했다(`ISL_10P6`).
- CST `ISL_FIXED_10G6`의 기존 10.4 GHz 대비 차이(`cst/results/ISL_FIXED_10G6/frequency_change_comparison.json`): peak +0.122 dB, HPBW −0.979°, coverage RMS 0.152 dB.
- 이는 가정 gate 확인이며 측정이나 mesh 수렴 검증이 아니다.
- 이번 결과에서 ISL 관련 수신 레벨(−45 ~ −60 dBm)은 이 차이보다 훨씬 큰 여유를 가진다.

## 7. 교차검증용 추적값 (핵심 pair)

| pair | CST case / 주파수 | 이득 종류 | 국소 방향 (θ, φ) | monitor 값 | 결과 |
|---|---|---|---|---|---|
| S_TM@ZENITH → GPSA_1 | TX `RFC_S_LOW_FREE` S/S_TM, RX `RFC_L_LOW_FREE` L/S_TM, 2.2/2.25/2.3 | RealizedGain total | TX (88.26°, 351.58°), RX (83.59°, 174.25°) | 2.25 GHz: Gtx −1.62, Grx −12.04, FSPL 44.65 → S21 −58.32 dB | 대역 평균 S21 −58.31, 수신 −21.32 dBm, 허용 −104.87 → 83.55 dB |
| S_TM@NADIR → S_TC@ZENITH | 양쪽 `RFC_S_LOW_FREE` S/S_TM | RealizedGain total | TX (151.66°, **90°**: YZ 컷), RX (148.34°, **270°**: YZ 컷 360−θ) | 2.25 GHz: Gtx −10.17, Grx −11.10, FSPL 48.01 → −69.28 dB | 수신 −32.29 dBm, 허용 −123.96 → 91.68 dB |
| Ka@KAA_1 → ISL_RX | TX 동결 `KAA_KA_*`, RX `RFC_ISL_KA_FREE` ISL/KA, 25.5/26.25/27 | TX accepted-power 모델+포락선, RX RealizedGain | TX (158.54°, 50.93°), RX (102.67°, 103.67°) | 26.25 GHz: Gtx −18.93, Grx −8.40, FSPL 65.83 → −93.16 dB | 수신 −44.96 dBm(근거리 추정, R_ff 8.72 m > 1.78 m) |
| ISL_TX → S_TC@ZENITH | TX `RFC_ISL_HIGH_FREE` ISL/ISL, RX `RFC_S_HIGH_FREE` S/ISL, 10.55/10.6/10.65 | RealizedGain total | TX (88.49°, 183.83°), RX (94.07°, 0.61°) | 10.6 GHz: Gtx −11.35, Grx −8.81, FSPL 68.71 → −88.87 dB | 수신 −58.87 dBm, 허용 −123.96 → 65.10 dB |

- **행 위치:** 모든 행은 `results/pair_results.csv`(case_id + pair_id)에 있다. monitor 값은 `results/band_results.csv`에 있다.
- **좌표 변환과 수식:** `RFI_분석근거.md` §4–§5.
- **대조 확인 사항:**
  - peak 표 값은 방향 이득으로 쓰지 않았다(컷 대조에만 사용).
  - mismatch는 한 번만 적용했다.
  - 설치(잠정)·자유공간·가정 값을 서로 다른 파일과 열로 분리했다.

## 8. 산출물 목록

| 파일 | 내용 |
|---|---|
| `RFI_분석근거.md` | 패턴↔케이스 대응, 좌표 변환, 수식, 상태 코드, 검증 |
| `RFI_분석결과보고서.md` | 이 보고서 |
| `results/pair_results.csv` | 150 pair: 케이스·기능·설치·대역·전력 기준·패턴/quantity/source case·방향 각·이득·거리·LOS·원거리장·S21·수신 레벨·허용·필요 제거도·상태·누락 이유 |
| `results/band_results.csv` | 396행: pair × 송신 대역 monitor 주파수별 이득·FSPL·S21 |
| `results/aggregate_by_victim.csv` | 78행: 케이스 × 모드 × 피간섭원 선형 합 집계(완결성 표시) |
| `results/sensitivity.csv` | 누락 응답 경계값, KAA 조향 최악, S 잠정 설치 ΔG |
| `results/sar_assessment.csv` | SAR 가정 민감도·SAR 피간섭원 부분 계산 |
| `results/source_availability.csv` | 안테나군 × 평가대역 응답 확보 현황 |
| `results/pattern_usage_manifest.csv` | pair·측·변형별 사용 패턴 키·quantity·CST case·파일 경로 |
| `results/engine_crosscheck.csv`, `results/check_cut_directions.csv` | 기존 엔진 대조, 컷 방향 검증 |
| `results/run_log.txt`, `results/environment.txt`, `results/test_suite_log.txt` | 실행 로그·환경·전체 테스트(1425/1425) |
| `run_rfi_analysis.m`, `make_figures.m`, `code/*.m` | 재현 코드(Octave) |
| `figures/*.svg` | 필요 제거도·SAR 민감도 그림 |

## 9. 한계와 다음 입력

- **패턴 특성:** 모두 자유공간이다. 두 독립 컷으로 3D를 재구성한 근사(`APPROX_FROM_CUTS`)이고, CST 응답은 제조사 인증이나 mesh 수렴 결과가 아니다.
- **손실 미반영:** 편파·차폐·회절 손실은 넣지 않았다(BLOCKED pair는 상한). Ka pair는 근거리라 Friis 추정치다.
- **판정에 필요한 입력:**
  1. 수신기 대역 밖 선택도, P1dB/IIP3/블로킹(GPS, S TC, ISL)
  2. 송신 emission mask·고조파(S TM, ISL, Ka, SAR)
  3. L 안테나의 X·Ka 대역, S 안테나의 Ka 대역 응답
  4. SAR 패턴·전력·듀티
  5. 다이플렉서 격리
  6. GNSS C/N0 기준
  7. 운용 모드 확정
