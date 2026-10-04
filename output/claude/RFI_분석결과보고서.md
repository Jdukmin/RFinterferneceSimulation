# RFI 간섭 해석 결과보고서 — 단순화 위성체 baseline

작성 2026-10-04. 실행 **GNU Octave 9.2.0**(MATLAB 미사용), 저장소 `main` @ `5a9332a` 기준. CST 신규 계산은 하지 않았다.
- 무엇을 어떤 패턴으로 계산했는지: `RFI_분석근거.md` (3단 분리 방법은 §11)
- 행 단위 결과: `results/`
- 용어: 간섭원(interferer) / 피간섭원(victim)
- **이번 갱신:**
  - RFI를 **세 영역으로 분리**했다. A. 기본파 대역 밖 blocker(dBm), B. 피간섭원 대역 불요방사 PSD(dBm/Hz), C. 수신기 적분 효과(dBm, I/N, C/N0, J/S).
  - RFI 규격의 1차 기준은 피간섭원 tuning 대역 전체의 **PSD mask**(`PSD_victim_port(f) ≤ PSD_allowable`)다. 수신기 대역폭 적분은 2차 평가다.
  - 기존 `수신 레벨 − 허용 레벨 = 필요 제거도`는 요구사항으로 쓰지 않는다. `screening_suppression_to_inband_limit_db`(진단값)로 이름을 바꿨다.
  - Ka KAA는 CST feed + 검증된 반사판 aperture 모델을 source로 쓰고, 탑재 blocker는 aperture 근거리 직접장(`REFLECTOR_APERTURE_NEAR_FIELD`)으로 계산한다(§3.4).
  - 이전 결과 파일의 해시는 `results/previous_run_manifest.csv`에 있다.

## 1. 요약

### A. 기본파 대역 밖 blocker 노출 [dBm, TX 반송파 주파수] — `results/oob_blocking_results.csv`

- 150 pair 행: **72행 포트 전력 평가**(Ka 근거리 12행 포함), **60행 INPUT_MISSING**(피간섭원 안테나의 TX 대역 응답 없음), **18행 NOT_EVALUATED**(같은 포트).
- 기존 blocker 값은 그대로 유지했다.
  - **S-TM@SBA_ZENITH → GPSA_1: −21.3 dBm @ 2.25 GHz** (변형 B −20.0 dBm), LOS CLEAR, GPS L1·L2·L5 케이스 공통
  - **S-TM → 반대편 S-TC: −32.3 dBm @ 2.25 GHz** (BLOCKED 경로의 자유공간 값)
  - Ka → ISL_RX: −63.4 / −63.2 dBm @ 25.5–27 GHz(공칭), 짐벌 최악 −37.2 dBm(KAA_2)
- **판정 상태: 전 경로 `PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN`.** 수신기 프리셀렉터/BPF rejection, 블로킹 한계, P1dB, 감도저하, IIP3가 없다.
- 이전의 "필요 제거도"(예: S-TM → GPSA_1 83.5 dB)는 `screening_suppression_to_inband_limit_db`로 바뀌었다. 이는 "2.25 GHz blocker 총전력을 GPS 대역 내 열잡음 기준 수준까지 낮추는 등가 억압량"일 뿐 **GPS OOB rejection 요구가 아니다.**

### B. 피간섭원 대역 불요방사 PSD [dBm/Hz] — `results/victim_band_psd_results.csv`, `psd_pair_summary.csv`

- 기준: **GPS L1/L2/L5 −178 dBm/Hz**(NF 2 dB, I/N −6 dB), **S-TC −177 dBm/Hz**(NF 3 dB), ISL −177 dBm/Hz. 피간섭원 tuning 대역 전체(21점)에서 비교한다.
- **결합 C_EM은 피간섭원 주파수의 CST 응답으로 계산했다**(TX 운용대역 이득 재사용 금지). 예: S-TM@ZENITH → GPSA_1의 C_EM(L1)은 −81.4 ~ −81.0 dB로, 기본파 S21(−58.3 dB)보다 23 dB 낮다.
- **TX emission mask가 하나도 없다**(`data/rfi_psd/tx_emission_masks.csv` 비어 있음). 그래서 포트 PSD와 PASS/FAIL은 아직 없다. 대신 각 pair에서 기준을 만족하는 **TX 안테나 포트 불요방사 한계**를 도출했다(§3.6).
  - 가장 엄격: **S-TM → 반대편 S-TC ≤ −107.9 dBm/Hz**(반송파 대비 −144.9 dBc/Hz)
  - S-TM@ZENITH → GPSA_1 ≤ −97.0 dBm/Hz(−134.0 dBc/Hz)
- 평가 가능 pair 56개(C_EM 계산 완료, mask만 필요), mesh/정규화 문제로 막힌 pair 16개(S 안테나 L2/L5 응답 정규화 불안정), Ka 60개는 radiated EIRP PSD 또는 KAA 저주파 응답이 필요하다.
- **Reference cross-check 재현:** 필터 전 −120 dBm/Hz → GPS −178 대비 **58 dB FAIL**, 60 dB 필터 후 −180 dBm/Hz → **+2 dB PASS**.

### C. 수신기 적분 효과 [dBm, I/N, C/N0, J/S] — `results/receiver_integrated_results.csv`

- 실제 채널·대역폭에서 `I_rx = ∫ PSD |H|² df`를 계산하는 2차 단계다. B의 포트 PSD가 없어 **미션 pair는 모두 미평가**다.
- 적분 대역폭: S-TC 5.53 kHz(4096 bps, RRC α 0.35, engineering baseline), GPS 20.46 MHz(**가정**: 신호 main-lobe 폭, 수신기 BW 미확정), ISL 20 MHz(잠정).
- reference 예(60 dB 필터 후 −180 dBm/Hz, GPS 20.46 MHz): I = −106.9 dBm, I/N = −8.0 dB. C/N0·J/S는 수신기 모델이 필요해 산출하지 않았다.

### 판정 보류 요약

- **TX emission mask / spur 표 없음:** S-TM, ISL, Ka, SAR 송신기 전부. B와 C의 최종 판정을 막는 1순위 입력이다.
- **수신기 blocking 데이터 없음:** A의 최종 판정을 막는다.
- **Learning Edition mesh 한도:** L 안테나 @ X/Ka, S 안테나 @ Ka 응답이 없어 A의 ISL → GPS, Ka → S/GPS blocker가 막혀 있다. 이 중 **ISL → GPS는 B 경로로 평가 가능해졌다**(ISL 안테나 @ L, L 안테나 @ L 응답 존재).
- **SAR**: SAR 안테나 패턴이 없다. 이번 Ka 작업의 SAR 관련 경로는 SAR 송신이 아니라 **KAA 송신 → SAR 수신**이다.

## 2. 해석 조건

- **설치 패턴 정책:** 자유공간 우선이다. 승인된 설치 패턴은 0개이며, S 잠정 설치 결과는 민감도로만 썼다(§5.2).
- **ISL·SAR:** 자유공간이다. ISL은 활성 바인딩 `ISL_10P6`(10.55–10.65 GHz)을 쓴다.
- **Ka source model routing:**
  - KAA 송신 → `REFLECTOR_APERTURE_NEAR_FIELD`. 검증된 KAA 모델(`cst/results/KA_FEED_C_OEWG` feed + `KA_REFLECTOR_KA_FEED_C_OEWG` 등가 포물면)을 **재생성 없이** 그대로 읽는다.
  - 원거리 패턴 경로(동결 `data/Kaband_KAA_CST`)는 검증용, 그리고 거리 ≥ 2D²/λ일 때만 쓴다. 이번 결과에서는 변형 **B**(Friis 참고값)로 남겼다.
  - S·ISL 송신은 기존 자유공간 패턴(Friis) 경로 그대로다.
- **이득 종류:**
  - 피간섭원 측은 간섭원 주파수에서의 **CST RealizedGain**(입사 전력 기준 total)이다. Ka 기본파는 반드시 피간섭원의 **25.5–27 GHz 대역 밖 응답**을 쓴다. 자기 운용대역 이득은 코드에서 거부된다.
  - 간섭원 측은 두 변형으로 계산했다.
    - **A**(기본): S·ISL은 CST RealizedGain, **Ka는 aperture 근거리 등가이득** Geq = 4πd²S/P(accepted-power 기준)다.
    - **B**: 동결 기준 패턴(SBA1/SBA4, ISL, Ka) + Friis.
  - mismatch는 RealizedGain에 한 번만 들어 있고 추가 차감은 없다. 편파·차폐 손실도 적용하지 않았다.
- **주파수:** 송신 점유 대역(`rf_systems.csv`) 21점에서 계산한 뒤 선형 전력 평균을 냈다. Ka 근거리는 CST feed monitor 25.5/26.25/27 GHz 3점의 선형 평균이다(보간·외삽 없음).
- **RF 기준값**(`rf_systems.csv`; 공개 표준과 engineering assumption이 섞여 있음, provenance는 원본 참고):

  | 시스템 | 대역 | 전력 / 수신 기준 | 허용 레벨 |
  |---|---|---|---|
  | S TM | 2.250 GHz / 2.7 MHz | 36.99 dBm | — |
  | S TC | 2.050 GHz / 0.2 MHz | NF 3 dB | −123.96 dBm |
  | GPS L1·L2·L5 | 20.46 MHz | NF 2 dB | −104.87 dBm |
  | ISL | 10.6 GHz / 20 MHz | 30 dBm, NF 3 dB | −103.96 dBm |
  | SAR RX | 9.65 GHz / 525 MHz | NF 5 dB (가정) | — (패턴·수신 기준 미확정) |
  | Ka | 26.25 GHz / 1.5 GHz | 48.45 dBm | — |

  I/N 기준은 모두 −6 dB이다.

## 3. 결과

### 3.1 A. 기본파 blocker — 평가된 pair (CASE_SBA1_L1, 대표; 물리 pair 12개)

| 간섭원 → 피간섭원 | 거리 [m] | LOS | 결합 모델 | S21 A [dB] | blocker 포트 A [dBm] | screening 억압량 A / B [dB] (진단) |
|---|---|---|---|---|---|---|
| S_TM@SBA_ZENITH → GPS@GPSA_1 | 1.81 | CLEAR | 원거리 Friis | −58.3 | **−21.3** | **83.5** / 84.8 |
| S_TM@SBA_ZENITH → GPS@GPSA_2 | 2.90 | CLEAR | 원거리 Friis | −62.8 | −25.8 | 79.1 / 80.4 |
| S_TM@SBA_NADIR → S_TC@SBA_ZENITH | 2.67 | BLOCKED | 원거리 Friis | −69.3 | −32.3 | **91.7** / 87.0 |
| S_TM@SBA_ZENITH → S_TC@SBA_NADIR | 2.67 | BLOCKED | 원거리 Friis | −69.3 | −32.3 | **91.7** / 88.7 |
| S_TM@SBA_NADIR → GPS@GPSA_1 | 3.15 | BLOCKED | 원거리 Friis | −79.3 | −42.3 | 62.5 / 64.9 |
| S_TM@SBA_NADIR → GPS@GPSA_2 | 3.88 | BLOCKED | 원거리 Friis | −81.8 | −44.9 | 60.0 / 61.7 |
| S_TM@SBA_ZENITH → ISL_RX | 6.14 | CLEAR | 원거리 Friis | −93.9 | −56.9 | 47.1 / 48.2 |
| ISL_TX → S_TC@SBA_ZENITH | 6.14 | CLEAR | 원거리 Friis | −88.9 | −58.9 | 65.1 / 66.4 |
| ISL_TX → S_TC@SBA_NADIR | 6.56 | BLOCKED | 원거리 Friis | −89.0 | −59.0 | 65.0 / 68.9 |
| S_TM@SBA_NADIR → ISL_RX | 6.56 | BLOCKED | 원거리 Friis | −97.2 | −60.2 | 43.7 / 44.8 |
| Ka@KAA_2 → ISL_RX | 2.34 | CLEAR | **aperture 근거리** | −111.7 | −63.2 | 40.7 / 56.5 |
| Ka@KAA_1 → ISL_RX | 1.78 | CLEAR | **aperture 근거리** | −111.9 | −63.4 | 40.5 / 59.0 |

- screening 억압량 = blocker 포트 전력 − 대역 내 허용 전력. **요구사항이 아닌 진단값**이다(§1 A).

그림: `figures/oob_blocker_exposure_CASE_SBA1_L1.svg`, `figures/oob_blocker_exposure_CASE_SBA4_L1.svg`.

**A와 B 차이가 생기는 이유.** 같은 SBA 안테나라도 CST RealizedGain(형상 1개, 2.25 GHz 실제 응답)과 SBA1/SBA4 datasheet 포락선의 방향 이득이 측면·후면에서 수 dB 다르다.
- 예: SBA_NADIR TM 송신의 SBA_ZENITH 방향(θ = 151.7°) 이득은 A −10.2 dBi, B(SBA1) −14.8 dBi, B(SBA4) −16.3 dBi다.
- 그래서 S TM↔S TC 쌍의 결론은 A(더 보수적) 기준으로 읽기를 권한다.
- **Ka는 반대로 B가 15.7–18.5 dB 크다.** 이유는 §3.4.3에 있다. 광각에서는 직접장 모델이 보수적이지 않을 수 있으므로 Ka 쌍은 A와 B를 함께 읽어야 한다.

**이전 보고서와 값이 다른 이유.**
- **GPS:** 이전 엔진 결과(동결 패턴 양 끝, Phase 8)는 GPS 피간섭원 이득으로 L1 자기 대역 패턴(−6.2 dBi)을 2.25 GHz에 재사용했다. 이번 해석은 GPS 안테나의 **2.25 GHz 실제 CST 응답**(−12.0 dBi, mismatch 포함, accepted fraction 0.109)을 썼다. 그 결과 수신 레벨이 −14.2 → **−21.3 dBm**으로 약 7 dB 낮아졌다. 이전 값은 수신 안테나의 운용 대역 이득으로 다른 대역을 대체해 과대평가된 것이다.
- **Ka → ISL:** 이전 버전(`4493d4d`)은 동결 Ka export(검증 주빔 + legacy 포락선)를 Friis로 써서 −45.0 / −47.5 dBm였다. 이번에는 aperture 근거리 직접장으로 −63.4 / −63.2 dBm다(§3.4).

### 3.2 GPS L1 / L2 / L5 및 SBA1 / SBA4 조합

- **GPS 대역:** 간섭원 S TM(2.25 GHz)에 대한 GPS 안테나 응답은 같은 물리 안테나의 2.25 GHz 응답이다. 그래서 **L1·L2·L5 케이스의 수신 레벨이 같다**.
  - 세 수신기는 NF·필터 폭·I/N 기준이 같아 허용 레벨(PSD −178 dBm/Hz)도 같다.
  - 대역별 차이는 수신기의 대역 밖 선택도·블로킹 특성에서만 생기는데, 이 입력이 없다.
- **SBA variant:** A는 형상 1개라 같은 값이다. B는 S TM 송신 측 이득이 바뀐다.
  - SBA_NADIR → GPSA_2: SBA1 −43.1 vs SBA4 −49.9 dBm
  - SBA_ZENITH → GPSA_1: −20.0 vs −20.3 dBm
  - 최대 노출 경로(SBA_ZENITH)는 variant에 거의 무관하다(0.3 dB).

### 3.3 피간섭원별 집계 (활성 TX 선형 합, CASE_SBA1_L1)

| 모드 | 피간섭원 | 활성 TX | 평가/누락 | 집계 blocker [dBm] | screening 억압량 [dB] (진단) | 최대 기여 |
|---|---|---|---|---|---|---|
| SCREENING_ALL_TX | GPS@GPSA_1 | 5 | 2 / **3 누락** | −21.3 (하한) | 83.6 | S_TM@ZENITH |
| SCREENING_ALL_TX | S_TC@SBA_NADIR | 5 | 2 / 2 누락 (+1 자기포트) | −32.3 (하한) | 91.7 | S_TM@ZENITH |
| SCREENING_ALL_TX | ISL_RX | 5 | 4 / 0 | −54.1 | 49.9 | S_TM@ZENITH (Ka 기여 −63.4 / −63.2) |
| NOM_ZENITH_KAA2 | GPS@GPSA_1 | 3 | 1 / 2 누락 | −21.3 (하한) | 83.5 | S_TM@ZENITH |
| NOM_NADIR_KAA1 | GPS@GPSA_1 | 3 | 1 / 2 누락 | −42.3 (하한) | 62.5 | S_TM@NADIR |
| NOM_NADIR_KAA1 | S_TC@SBA_NADIR | 3 | 1 / 1 누락 | −59.0 (하한) | 65.0 | ISL_TX |

- 누락 기여가 있는 집계는 `PARTIAL_LOWER_BOUND`로 표시했다(누락분을 0으로 넣지 않음).
- 집계의 Ka 기여는 **공칭 짐벌 기준 지향**이다. 짐벌 최악은 §3.4.4에 따로 있다.
- 전체 18개 모드×케이스 조합 결과: `results/aggregate_by_victim.csv`.
- 정상 운용 모드는 잠정 템플릿이다. `SCREENING_ALL_TX`는 운용 모드가 아닌 동시 활성 가정이다.

### 3.4 Ka KAA 송신 — 반사판 aperture 근거리 직접장

**경로 정의.** 두 경로를 분리했다(`results/ka_nearfield_pair_results.csv`의 `path`).

| 경로 | 내용 | 피간섭원 이득 | 이번 상태 |
|---|---|---|---|
| `KA_FUNDAMENTAL_OOB_BLOCKING` | KAA 25.5–27 GHz 기본파 → 반사판 근거리 → 피간섭원 안테나(26 GHz) → 포트 → 수신 전단 | 피간섭원의 **Ka 대역 밖 응답** | ISL만 평가, 나머지 INPUT_MISSING |
| `KA_SPUR_INBAND` | Ka 송신 스퓨리어스·고조파가 S/L/SAR 수신대역에 직접 떨어지는 경우 | 피간섭원의 **정상 대역 내 이득** | 20행 모두 INPUT_MISSING (KAA emission mask 없음) |

#### 3.4.1 근거리–원거리 검증 (26.25 GHz, `results/ka_nearfield_validation.csv`)

| 항목 | 결과 |
|---|---|
| 반사판 원거리 재현: MATLAB aperture 적분 vs 기존 Python CSV(`fine_0p05deg`, `full_1deg`) | 최대 0.0095 dB, 주빔 0.0000 dB (25.5/26.25/27 GHz, φ = 0/90°) |
| 절대 정규화: aperture 전력 = feed 환형 차단 전력 | 0.53708 = 0.53708 (26.25 GHz), 균일 개구 지향성 = 4πA/λ² (2e-3 dB 이내) |
| 거리 R = 100·R_ff (R_ff = 2D²/λ = 8.48 m) | 주빔·부엽·광각(0–150°) 최대 4e-4 dB. 단 3.75° null 0.03 dB |
| R = 10·R_ff | 주빔 5e-4 dB, 광각 최대 0.037 dB (null 제외) |
| R = 1·R_ff | 주빔 −0.05 dB, 광각 최대 2.7 dB |
| R = 0.2·R_ff (≈1.7 m, 실제 KAA–ISL 거리대) | 보어사이트 −1.32 dB, 부엽·null 구조가 사라짐(3.75°에서 +31.6 dB, 10°에서 −8.8 dB) |

- 수렴 판정: R ≥ 10·R_ff의 null 제외 전 행 PASS(허용 0.05 dB / 100·R_ff 0.005 dB). FAIL 0행.
- 의미: 같은 aperture가 먼 거리에서 기존 검증 패턴으로 정확히 수렴하므로 **절대 정규화가 확인**됐다. 실제 탑재 거리에서는 원거리 패턴과 dB 단위로 크게 다를 수 있음을 보여준다.
- 그림: `figures/ka_nearfield_convergence.svg`.

#### 3.4.2 공칭 지향 결과 (짐벌 기준축 = 장착 패널 법선)

| KAA → 피간섭원 | 거리 [m] | LOS | aperture θ [°] | S (26.25) [dBm/m²] | 피간섭원 응답 | P_port 25.5 / 26.25 / 27 [dBm] | P_port 대역 [dBm] |
|---|---|---|---|---|---|---|---|
| KAA_1 → ISL_RX | 1.78 | CLEAR | 158.5 | −5.5 | CST `RFC_ISL_KA_FREE` | −60.8 / −63.8 / −69.8 | **−63.4** |
| KAA_2 → ISL_RX | 2.34 | CLEAR | 114.2 | −9.7 | CST `RFC_ISL_KA_FREE` | −59.0 / −70.4 / −72.1 | **−63.2** |
| KAA_1 → S_TC@SBA_NADIR | 6.04 | CLEAR | 88.3 | −5.3 | **없음 (MESH_LIMIT)** | — | INPUT_MISSING |
| KAA_1 → S_TC@SBA_ZENITH | 6.11 | BLOCKED | 110.0 | −16.8 | 없음 | — | INPUT_MISSING |
| KAA_1 → GPS@GPSA_1 / GPSA_2 | 4.55 / 3.64 | BLOCKED | 118.2 / 126.1 | −3.5 / −2.7 | 없음 (MESH_LIMIT) | — | INPUT_MISSING |
| KAA_1 → SAR_RX | 2.93 | CLEAR | 91.0 | +0.4 | 없음 (NO_PATTERN_BOUND) | — | INPUT_MISSING |
| KAA_2 → S_TC@SBA_NADIR / ZENITH | 5.75 / 6.25 | CLEAR / BLOCKED | 96.1 / 96.3 | −2.9 / −3.5 | 없음 | — | INPUT_MISSING |
| KAA_2 → GPS@GPSA_1 / GPSA_2 | 4.59 / 3.70 | BLOCKED | 95.4 / 96.7 | −1.5 / +1.4 | 없음 | — | INPUT_MISSING |
| KAA_2 → SAR_RX | 3.02 | BLOCKED | 114.4 | −14.1 | 없음 | — | INPUT_MISSING |

- **KAA별 기본파 pair 수**(수신 시스템 기준, GPS L1/L2/L5 별도): KAA_1 평가 1 / 누락 9, KAA_2 평가 1 / 누락 9. 스퓨리어스 경로는 KAA별 10행 모두 INPUT_MISSING이다.
- ISL 수신 측 근거리 파면 방향(위상 기울기)과 기하 방향의 차이는 1.9° / 1.0°이다. 1° 컷 해상도 수준이라 피간섭원 이득은 기하 방향으로 평가했다.
- **BLOCKED 경로**의 직접장은 선체 차폐·회절을 넣지 않은 값이다. 물리적 결합으로 읽지 말고 입력 크기 가늠용으로만 본다.

#### 3.4.3 근거리 직접장 vs 기존 원거리(Friis) 값

| 경로 (26.25 GHz, 공칭) | 근거리 Geq [dBi] | aperture 원거리 G(θ) [dBi] | 동결 export G(θ) [dBi] | P_port: 근거리 / aperture Friis / 동결 Friis [dBm] |
|---|---|---|---|---|
| KAA_1 → ISL_RX (θ = 158.5°) | −38.0 | −34.5 | −18.9 | −63.4 / −60.7 / −45.0 |
| KAA_2 → ISL_RX (θ = 114.2°) | −39.7 | −41.5 | −16.6 | −63.2 / −63.4 / −47.6 |

- 근거리와 aperture 원거리의 차이(±3 dB)는 근거리 효과다.
- **동결 export와의 15–18 dB 차이는 근거리 효과가 아니라 source 모델 차이다.** 동결 export는 1° 밖에서 `max(모델, legacy 포락선)`이고 광각은 legacy의 보수 가정(≈ −15 ~ −19 dBi)이다. aperture 모델은 광각에서 개구 가장자리 회절 수준(−25 ~ −45 dBi)이다.
- aperture 적분은 **반사된 개구장만** 포함한다. feed spillover, 부반사판·스트럿 산란, 반사판 뒷면 누설은 포함하지 않는다. 데이터시트로 검증된 영역은 주빔 0–1°뿐이다.
- 그래서 **광각(θ > 약 10°) 결과는 보수적이라고 할 수 없다.** 판정 전 수신기 데이터가 들어오면 B(동결 Friis) 값도 함께 비교하기를 권한다.

#### 3.4.4 짐벌 최악 지향 screening (`results/ka_gimbal_worstcase.csv`)

방법: aperture가 축대칭이고 aperture 중심을 설치 기준점에 고정했다(pivot offset 미정의 → 가정). 그러면 결합은 거리와 "보어사이트–피간섭원 각 θ"만의 함수다. 반구 가정에서 도달 가능한 θ 범위 [max(0, α−90°), min(180°, α+90°)] 전체를 0.25° → 0.01°로 탐색했다. 3D 무작위 지향 brute-force(6° 격자)가 이 최대를 넘지 않음을 테스트로 확인했다.

| KAA → 피간섭원 | 공칭 S [dBm/m²] | 피간섭원 지향 가능? | 최대 결합 지향 (θ_ap, 기준축 대비) | 최대 S [dBm/m²] | 차이 [dB] | P_port 공칭 → 최대 [dBm] |
|---|---|---|---|---|---|---|
| KAA_1 → SAR_ANT | +4.2 | 아니오(경계 0.98° 밖) | 0.98°, 90.0° | **59.2** | +55.0 | INPUT_MISSING |
| KAA_1 → SBA_NADIR | −1.7 | **예** | 0°, 88.3° | 54.4 | +56.1 | INPUT_MISSING |
| KAA_2 → GPSA_1 | −0.1 | 아니오 | 5.37°, 90.0° | 39.8 | +40.0 | INPUT_MISSING |
| KAA_2 → GPSA_2 | +1.6 | 아니오 | 6.67°, 90.0° | 35.0 | +33.4 | INPUT_MISSING |
| KAA_2 → SBA_NADIR | −2.1 | 아니오 | 6.09°, 90.0° | 34.9 | +37.1 | INPUT_MISSING |
| KAA_2 → SBA_ZENITH | −2.9 | 아니오 | 6.31°, 90.0° | 32.6 | +35.5 | INPUT_MISSING |
| KAA_2 → ISL | −2.6 | 아니오 | 27.1°, 87.1° | 23.8 | +26.4 | **−63.2 → −37.2** |
| KAA_2 → SAR_ANT | −4.6 | 아니오 | 27.0°, 87.5° | 22.1 | +26.8 | INPUT_MISSING |
| KAA_1 → SBA_ZENITH | −6.0 | 아니오 | 20.6°, 89.4° | 17.6 | +23.6 | INPUT_MISSING |
| KAA_1 → GPSA_1 | −6.3 | 아니오 | 28.2°, 90.0° | 16.8 | +23.1 | INPUT_MISSING |
| KAA_1 → GPSA_2 | −5.6 | 아니오 | 45.3°, 80.8° | 13.0 | +18.6 | INPUT_MISSING |
| KAA_1 → ISL | −5.0 | 아니오 | 72.9°, 85.6° | 11.9 | +16.9 | **−63.4 → −46.8** |

- 모든 최악 지향은 가정 반구 **안**에 있다(`allowed_in_domain = 1`). 다만 대부분 기준축에서 85–90°, 즉 **장착 패널을 스치는 경계 지향**이다. 실제 hard-stop·keep-out·기구 shadowing이 정의되지 않아 이 지향이 실제로 가능한지는 판단하지 않았다(가정으로 표시).
- **최대 Ka 포트 결합 경로: KAA_2 → ISL_RX, 짐벌 최악 −37.2 dBm**. 공칭 대비 +26.1 dB다.
- 입사장 기준 최대는 KAA_1 → SAR_ANT(59.2 dBm/m²)와 KAA_1 → SBA_NADIR(54.4 dBm/m²) 주빔 경로다. 피간섭원 Ka 응답이 없어 포트 전력은 산출하지 않았다.
  - 0 dBi 가정 참고값(`ASSUMPTION_ONLY`, `results/ka_assumption_only_sensitivity.csv`)은 각각 +9.4 dBm, +4.5 dBm이다.
- 그림: `figures/ka_gimbal_power_density.svg`.

#### 3.4.5 수신기 영향

- 평가된 포트 결합(KAA → ISL_RX)의 상태는 `PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN`이다.
- ISL·S TC·GPS·SAR 수신기 모두 Ka 주파수에서의 BPF/프리셀렉터 제거도, LNA/믹서 블로킹 레벨, P1dB, IIP3가 없다(`results/ka_input_availability.csv`, 24행 INPUT_MISSING).
- 따라서 압축·감도저하·블로킹의 **PASS/FAIL은 선언하지 않았다.** 포트 레벨(−63 ~ −37 dBm)은 수신기 데이터와 비교할 입력값이다.

### 3.5 기존 결과와의 호환

- 이전 결과(`4493d4d`) 대비 행 단위로 비교했다.
  - `pair_results.csv` 150행 중 바뀐 60행은 모두 Ka 행이다. Ka→ISL 12행은 값이, Ka→S/GPS 48행은 상태 문구·누락 사유가 바뀌었다.
  - `band_results.csv`: Ka 180행만 바뀌었다.
  - `engine_crosscheck.csv`, `sar_assessment.csv`의 S/ISL 행: 변경 없음.
  - `aggregate_by_victim.csv`: Ka 기여가 들어가는 ISL_RX 집계 18행만 바뀌었다.
- 이전 파일의 sha256과 재현 명령은 `results/previous_run_manifest.csv`에 있다.

### 3.6 B. 피간섭원 대역 불요방사 PSD (victim-band emission)

계산: `PSD_port(f) = PSD_TX(f) − L_TXchain(f) + C_EM(f)`, `C_EM(f) = G_tx,realized(f) + G_rx,realized(f) − FSPL(f)`, f는 **피간섭원 주파수**. tuning 대역 전체 21점 sweep.

**TX emission mask가 없으므로** 아래 표는 결합과, 허용 PSD를 만족하기 위한 **TX 안테나 포트 불요방사 PSD 한계**(= 허용 PSD − max C_EM, 파생 요구값)다. 포트 PSD·margin은 mask가 들어오면 같은 파일에서 바로 채워진다.

| 간섭원 → 피간섭원 (대역) | C_EM 범위 [dB] (CST, f_victim) | 허용 PSD [dBm/Hz] | TX 포트 불요방사 한계 [dBm/Hz] | 반송파 대비 [dBc/Hz] |
|---|---|---|---|---|
| S-TM@NADIR → S-TC@ZENITH (2025–2110 MHz) | −70.2 ~ −69.1 | −177 | **−107.9** | **−144.9** |
| S-TM@ZENITH → S-TC@NADIR | −70.2 ~ −69.1 | −177 | **−107.9** | **−144.9** |
| S-TM@ZENITH → GPSA_1 (L1 1563–1588 MHz) | −81.4 ~ −81.0 | −178 | −97.0 | −134.0 |
| S-TM@ZENITH → GPSA_2 (L1) | −86.5 ~ −86.1 | −178 | −91.9 | −128.9 |
| S-TM@NADIR → GPSA_1 / GPSA_2 (L1) | −106.9 ~ −105.4 / −105.0 ~ −103.6 | −178 | −72.6 / −74.4 | −109.6 / −111.4 |
| S-TM@NADIR / ZENITH → ISL_RX (10.55–10.65 GHz) | −89.2 ~ −88.7 | −177 | −88.2 / −88.3 | −125.2 / −125.3 |
| ISL_TX → S-TC@ZENITH / NADIR | −95.2 ~ −94.3 / −98.7 ~ −97.7 | −177 | −82.7 / −79.3 | −112.7 / −109.3 |
| ISL_TX → GPSA_1 / GPSA_2 (L1) | −122.2 ~ −122.2 / −119.7 ~ −119.7 | −178 | −55.8 / −58.3 | −85.8 / −88.3 |
| ISL_TX → GPSA_1 / GPSA_2 (L2) | −105.1 ~ −103.3 / −102.6 ~ −100.8 | −178 | −74.7 / −77.2 | −104.7 / −107.2 |
| ISL_TX → GPSA_1 / GPSA_2 (L5) | −104.9 ~ −103.2 / −102.4 ~ −100.7 | −178 | −74.8 / −77.3 | −104.8 / −107.3 |
| S-TM → GPS (L2, L5) | — | −178 | — | `COUPLING_INPUT_MISSING`: S 안테나 L2/L5 응답 정규화 불안정 |
| Ka → S-TC / GPS / ISL | G_rx − FSPL만 | −177 / −178 | EIRP 한계 −121.6 ~ −93.4 dBm/Hz | Ka: radiated EIRP PSD 또는 KAA 저주파 응답 필요 |

- 기본파 blocker 경로와 결합 값이 다르다. 예: S-TM@ZENITH → GPSA_1은 2.25 GHz에서 S21 −58.3 dB, L1에서 C_EM −81.2 dB다. 두 값을 섞지 않는다.
- **mesh 한도에도 B 경로로 새로 평가 가능해진 pair:** ISL_TX → GPSA_1/GPSA_2(L1/L2/L5 모두). A 경로는 L 안테나 @ 10.6 GHz 응답이 없어 막혀 있다.
- 현재 상태 집계(150 pair): `EMISSION_MASK_MISSING_COUPLING_EVALUATED` 56, `COUPLING_INPUT_MISSING` 16, Ka 60, 같은 포트 18.
- 그림: `figures/psd_emission_limit_CASE_SBA1_L1.svg`.

**Reference cross-check (다른 위성 S → L 예, `victim_band_psd_results.csv` `REFERENCE_CROSSCHECK_S_TO_L`):**

| 단계 | 포트 PSD [dBm/Hz] | GPS 기준 [dBm/Hz] | margin [dB] | 상태 |
|---|---|---|---|---|
| TX 필터 전 | −120 | −178 | −58 | FAIL |
| 60 dB TX 필터 후 | −180 | −178 | +2 | PASS |

- 필터 감쇠는 dB, 반송파 상대 방사는 dBc/Hz로 분리해 입력한다(엔진이 단위 혼동을 거부).

### 3.7 C. 수신기 적분 효과 (2차)

- `I_rx = ∫ PSD_port(f) |H_rx(f)|² df`를 선택 채널(S-TC 2050 MHz / 5.53 kHz, GPS 중심 / 20.46 MHz, ISL 10.6 GHz / 20 MHz)에서 계산한다. |H|²는 이상적 사각형(가정)이다.
- 미션 pair 58행은 B의 포트 PSD가 없어 `NOT_EVALUATED_NO_VICTIM_PORT_PSD`다.
- 2차 허용 적분 전력(참고): S-TC −139.6 dBm(5.53 kHz), GPS −104.9 dBm(20.46 MHz), ISL −104.0 dBm(20 MHz).
- reference 예: 60 dB 필터 후 I = −106.9 dBm, I/N = −8.0 dB(GPS 20.46 MHz). 필터 전 I/N = +52.0 dB.
- C/N0, J/S는 GNSS 수신기 모델·신호 레벨(−130 dBm 기준값은 별도 항목)로 다음 단계에서 계산한다.

## 4. 판정 보류 (NOT_EVALUATED / INPUT_MISSING / MODEL_LIMIT)

| 항목 | 상태 | 이유 | 참고값(`ASSUMPTION_ONLY`, 결과 아님) |
|---|---|---|---|
| Ka → GPS (KAA_1/2 → GPSA_1/2) | INPUT_MISSING | L 안테나 Ka 응답 없음(`RFC_L_KA_FREE` MESH_LIMIT, 최소 시도 1,467,648 cells) | 공칭 근거리 S × λ²/4π × 0 dBi: −48.0 ~ −56.1 dBm |
| Ka → S TC (KAA_1/2 → SBA_NADIR/ZENITH) | INPUT_MISSING | S 안테나 Ka 응답 없음(`RFC_S_KA_FREE` MESH_LIMIT, 최소 시도 255,600 cells) | 같은 방식 −51.3 ~ −56.0 dBm |
| Ka → SAR RX (KAA_1/2 → SAR_ANT) | INPUT_MISSING | SAR 안테나 패턴 없음(NO_PATTERN_BOUND, DEFERRED_CLOSED_NETWORK) | 공칭 −45.5 / −54.2 dBm (SAR 수신 기준 미확정) |
| Ka 불요방사 → S/L/SAR/ISL 대역 내 (B) | INPUT_MISSING | KAA emission mask / radiated EIRP PSD, 저주파 KAA 응답 없음(Ka 패턴 재사용 금지) | 파생 EIRP PSD 한계 §3.6 |
| TX emission mask (S-TM, ISL, Ka, SAR) | INPUT_MISSING | `tx_emission_masks.csv` 비어 있음 | 파생 TX 포트 한계 §3.6 |
| S-TM → GPS L2/L5 (B) | COUPLING_INPUT_MISSING | S 안테나 L2/L5 RealizedGain 정규화 불안정 | — |
| Ka 수신기 영향 (BPF/블로킹/P1dB/IIP3) | RECEIVER_BLOCKING_UNKNOWN | 수신기 데이터 없음(NaN 유지) | — |
| ISL → GPS (A: blocker) | INPUT_MISSING | L 안테나 X 대역 응답 없음(`RFC_L_HIGH_FREE` MESH_LIMIT 212,940). **B(PSD) 경로는 평가 가능**(§3.6) | 0 dBi 가정 시 −45.1 ~ −47.6 dBm |
| KAA 짐벌 hard-stop / shadowing | 가정 | 반구(90°) 단순화. 최악 지향 대부분이 패널 스침 경계 | §3.4.4 |
| 구조물 산란·차폐 (Ka) | NOT_MODELED | 직접 반사판 장만 계산 | 산란으로 특정 위치 결합이 커질 수 있음 |
| S TM ↔ 같은 SBA의 S TC, ISL TX ↔ ISL RX | NOT_EVALUATED | 같은 포트: 다이플렉서/T-R 격리, 송신 잡음 입력 없음 | — |
| 블로킹·포화·IM3 (S/L/ISL) | NOT_EVALUATED | 수신기 P1dB/IIP3/블로킹 데이터 없음(NaN 유지) | — |
| 송신 스퓨리어스·고조파 (S/ISL/SAR) | NOT_EVALUATED | emission mask 없음 | 참고: S TM 4차 고조파 9.0 GHz는 SAR 평가대역(8.9–10.4) 안이지만 rf_systems SAR 대역(9.39–9.91) 밖 |
| GNSS 최종 판정 | 보류 | I/N은 임시 기준. 최종은 C/N0·J/S | — |

## 5. 민감도

### 5.1 KAA 조향 (근거리 직접장)

반구 조향 가정에서 주빔이 피간섭원 방향을 정확히 향할 수 있는 조합은 **KAA_1 → SBA_NADIR**뿐이다(기준축 대비 88.3°).
- 입사 전력밀도 54.4 dBm/m²(공칭 대비 +56 dB)다. 근거리라 원거리 주빔 대비 약 0.1 dB 낮다.
- S 안테나의 Ka 응답이 없어 포트 레벨은 미평가다. `ASSUMPTION_ONLY` 0 dBi 참고값은 +4.5 dBm이다.
- KAA_1 → SAR_ANT도 반구 경계(0.98° 차이)에서 거의 주빔(59.2 dBm/m²)이 닿는다.
- **운용상 KAA_1의 SBA_NADIR·SAR_ANT 방향 지향 금지(keep-out) 검토를 권한다.**
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

- 결론(최대 blocker 노출 경로와 순위)은 바뀌지 않는다.
- 이 결과는 구조 범위·mesh 수렴이 확인되지 않았다(R3/R4/R5 미충족). **최종 설치 패턴이 아니며 참고 비교 전용이다.**

### 5.3 SAR (패턴 미결합, 가정 민감도)

조건: SAR 송신 9.39–9.91 GHz, 2.5 kW(63.98 dBm) / 5 kW(66.99 dBm), SAR 이득 −10/0/+10 dBi 가정. 피간섭원의 SAR 대역 RealizedGain은 CST 실제 데이터다.

| 피간섭원 | 거리 [m] | LOS | 피간섭원 이득 [dBi] | blocker 포트 범위 [dBm] | screening 억압량 [dB] (진단) |
|---|---|---|---|---|---|
| S_TC@SBA_NADIR | 3.13 | CLEAR | −3.0 | −11.0 ~ +12.0 | 112.9 ~ 135.9 |
| S_TC@SBA_ZENITH | 3.66 | BLOCKED | −2.8 | −12.1 ~ +10.9 | 111.8 ~ 134.8 |
| ISL_RX | 3.56 | BLOCKED | −17.2 | −26.4 ~ −3.4 | 77.5 ~ 100.6 |
| GPS@GPSA_1/2 | 2.43 / 2.11 | BLOCKED | 없음 | INPUT_MISSING | — |

- **SAR가 피간섭원일 때** SAR 위치 0 dBi 기준 간섭원 측 레벨은 S_TM@NADIR −17.0, S_TM@ZENITH −23.5, ISL −48.0 dBm이다. SAR 이득과 SAR 수신 기준이 없어 판정하지 않았다.
- **KAA → SAR 수신**은 이번에 근거리 직접장으로 바꿨다(§3.4). SAR 안테나 Ka 응답이 없어 INPUT_MISSING이다. 이전의 0 dBi 기준 Friis 값(−36.8 / −38.6 dBm)은 삭제했다.
- **해석:** SAR 송신 전력이 실제로 kW급이면 S TC 포트의 9.65 GHz blocker가 −11 ~ +12 dBm에 이른다. 블로킹 판정에는 S-TC 수신기의 X 대역 rejection·블로킹 한계가 필요하다. SAR 안테나 패턴, 실제 전력, 듀티, 송신 마스크가 SAR 영향 판정의 선결 입력이다.
- 그림: `figures/sar_assumption_blocker_exposure.svg`.

## 6. ISL 운용 대역 변경 영향

ISL은 10.6 GHz(10.55–10.65)로 해석했다(`ISL_10P6`).
- CST `ISL_FIXED_10G6`의 기존 10.4 GHz 대비 차이(`cst/results/ISL_FIXED_10G6/frequency_change_comparison.json`): peak +0.122 dB, HPBW −0.979°, coverage RMS 0.152 dB.
- 이는 가정 gate 확인이며 측정이나 mesh 수렴 검증이 아니다.
- 이번 결과에서 ISL 관련 수신 레벨(−37 ~ −63 dBm)은 이 차이보다 훨씬 큰 여유를 가진다.

## 7. 교차검증용 추적값 (핵심 pair)

| pair | CST case / 주파수 | 이득 종류 | 국소 방향 (θ, φ) | monitor 값 | 결과 |
|---|---|---|---|---|---|
| S_TM@ZENITH → GPSA_1 (A) | TX `RFC_S_LOW_FREE` S/S_TM, RX `RFC_L_LOW_FREE` L/S_TM, 2.2/2.25/2.3 | RealizedGain total | TX (88.26°, 351.58°), RX (83.59°, 174.25°) | 2.25 GHz: Gtx −1.62, Grx −12.04, FSPL 44.65 → S21 −58.32 dB | 대역 평균 S21 −58.31, blocker −21.32 dBm (진단 억압량 83.55 dB) |
| S_TM@NADIR → S_TC@ZENITH (A) | 양쪽 `RFC_S_LOW_FREE` S/S_TM | RealizedGain total | TX (151.66°, **90°**: YZ 컷), RX (148.34°, **270°**: YZ 컷 360−θ) | 2.25 GHz: Gtx −10.17, Grx −11.10, FSPL 48.01 → −69.28 dB | blocker −32.29 dBm (진단 억압량 91.68 dB) |
| Ka@KAA_1 → ISL_RX | TX KAA aperture(`KA_FEED_C_OEWG` + 등가 포물면 D 220 / Fe 151.11 / Ds 44 mm), RX `RFC_ISL_KA_FREE` ISL/KA, 25.5/26.25/27 | TX 근거리 Geq(accepted-power), RX RealizedGain | TX aperture (158.54°, 50.93°), RX (102.67°, 103.67°) | 26.25 GHz: S −5.54 dBm/m², Geq −38.00 dBi, Grx −8.40, FSPL 65.83 → P_port −63.78 dBm | 3-monitor 평균 blocker −63.45 dBm (`DIRECT_REFLECTOR_FIELD_ONLY`) |
| ISL_TX → S_TC@ZENITH (A) | TX `RFC_ISL_HIGH_FREE` ISL/ISL, RX `RFC_S_HIGH_FREE` S/ISL, 10.55/10.6/10.65 | RealizedGain total | TX (88.49°, 183.83°), RX (94.07°, 0.61°) | 10.6 GHz: Gtx −11.35, Grx −8.81, FSPL 68.71 → −88.87 dB | blocker −58.87 dBm |
| S_TM@ZENITH → GPSA_1 (B) | TX `RFC_S_L1_FREE`/`S/L1`, RX `RFC_L_LOW_FREE` `L/L1`, 1.563/1.57542/1.588 | RealizedGain total | 같은 방향 | L1 sweep: C_EM −81.4 ~ −81.0 dB | TX 포트 한계 −97.0 dBm/Hz (mask 없음) |

- **행 위치:** 모든 행은 `results/pair_results.csv`(case_id + pair_id)에 있다. monitor 값은 `results/band_results.csv`, Ka 근거리 상세는 `results/ka_nearfield_pair_results.csv`에 있다.
- **좌표 변환과 수식:** `RFI_분석근거.md` §4–§5, §10.
- **대조 확인 사항:**
  - peak 표 값은 방향 이득으로 쓰지 않았다(컷 대조에만 사용).
  - mismatch는 한 번만 적용했다.
  - 설치(잠정)·자유공간·가정 값을 서로 다른 파일과 열로 분리했다.
  - Ka 근거리 값은 `run_rfi_analysis.m`과 `run_ka_nearfield_analysis.m`이 같은 함수(`code/rfi_ka_point.m`)로 계산한다. 두 출력은 동일하다(−63.4462 dBm).

## 8. 산출물 목록

| 파일 | 내용 |
|---|---|
| `RFI_분석근거.md` | 패턴↔케이스 대응, 좌표 변환, 수식, 상태 코드, 검증, Ka 근거리 source(§10) |
| `RFI_분석결과보고서.md` | 이 보고서 |
| `results/pair_results.csv` | 150 pair: 케이스·기능·설치·대역·전력 기준·패턴/quantity/source case·방향 각·이득·거리·LOS·원거리장·S21·**oob_blocker_port_A/B_dbm**·허용·**screening_suppression_to_inband_limit_A/B_db**(진단)·상태·누락 이유 |
| `results/oob_blocking_results.csv` | A. 150행: blocker 주파수·TX 전력·결합·blocker 포트·수신기 rejection·post-filter·blocking 한계·margin·상태 |
| `results/victim_band_psd_results.csv` | B. 2472행: pair × 피간섭원 대역 주파수 sweep, emission 유형·TX PSD·체인 손실·TX/RX 이득 출처·C_EM·포트 PSD·허용 PSD·margin·TX 포트 한계·상태·provenance (+ reference cross-check) |
| `results/psd_pair_summary.csv` | B. 150행 pair 요약: C_EM 범위, TX 포트/EIRP 불요방사 한계, 상태 |
| `results/receiver_integrated_results.csv` | C. 58행: 채널·적분 BW·I_rx·잡음·허용 적분 전력·I/N·C/N0·J/S·상태 |
| `results/receiver_baseline.csv` | 수신기 tuning 대역·적분 BW·NF·잡음 PSD·허용 간섭 PSD·desired signal 기준·provenance |
| `data/rfi_psd/*.csv` | 입력: receiver_baseline, tx_emission_masks(비어 있음), tx_chain_losses(비어 있음) |
| `results/band_results.csv` | 396행: pair × 송신 대역 monitor 주파수별 이득·FSPL·S21 (Ka A = 근거리 Geq) |
| `results/aggregate_by_victim.csv` | 78행: 케이스 × 모드 × 피간섭원 선형 합 집계(완결성 표시) |
| `results/sensitivity.csv` | 누락 응답 경계값(Ka는 `ASSUMPTION_ONLY`), KAA 짐벌 최대 결합(근거리), S 잠정 설치 ΔG |
| `results/sar_assessment.csv` | SAR 가정 민감도·SAR 피간섭원 부분 계산 |
| `results/ka_nearfield_pair_results.csv` | **40행**: KAA × 피간섭원 시스템 × 경로(기본파/스퓨리어스), 위치·거리·짐벌 상태·aperture 방향·source model·응답 출처·전계/전력밀도·P_port(주파수별/대역)·상태·provenance·구조 산란 flag |
| `results/ka_gimbal_worstcase.csv` | 36행: KAA × 피간섭원 위치 × {공칭, 피간섭원 지향/최근접 허용, 최대 결합} |
| `results/ka_nearfield_validation.csv` | 296행: 근거리 vs 원거리 vs Python 반사판 CSV, 거리 sweep |
| `results/ka_input_availability.csv` | 34행: 피간섭원 Ka 응답, 수신기 BPF/블로킹/P1dB/IIP3, emission mask, 가정 항목 |
| `results/ka_assumption_only_sensitivity.csv` | 누락 피간섭원의 0 dBi 참고값(**결과 아님**) |
| `results/previous_run_manifest.csv` | 덮어쓰기 전 `output/claude` 파일 22개의 sha256·commit |
| `results/source_availability.csv` | 안테나군 × 평가대역 응답 확보 현황 |
| `results/pattern_usage_manifest.csv` | pair·측·변형별 사용 패턴 키·quantity·CST case·파일 경로 |
| `results/engine_crosscheck.csv`, `results/check_cut_directions.csv` | 기존 엔진 대조, 컷 방향 검증 |
| `results/run_log.txt`, `results/ka_nearfield_run_log.txt`, `results/environment.txt`, `results/test_suite_log.txt` | 실행 로그·환경·전체 테스트 |
| `run_ka_nearfield_analysis.m` → `run_rfi_analysis.m` → `run_psd_analysis.m` → `make_figures.m`, `code/*.m` | 재현 코드(Octave, 이 순서) |
| `src/+rfscreen/+kaa/*.m`, `tests/test_ka_nearfield.m` | Ka 근거리 solver·좌표 adapter·피간섭원 응답·경로 routing·짐벌 screening, 회귀 테스트 |
| `src/+rfscreen/+psd/*.m`, `tests/test_rfi_psd.m` | PSD 단위·emission spec(기준면)·band 응답·victim-band 결합·PSD 경로·blocker 경로·수신기 기준, 회귀 테스트 |
| `figures/*.svg` | blocker 노출·SAR blocker 가정·victim-band TX 불요방사 한계·Ka 근거리 수렴·Ka 짐벌 전력밀도 그림 |

## 9. 한계와 다음 입력

- **패턴 특성:** S/L/ISL은 모두 자유공간이다. 두 독립 컷으로 3D를 재구성한 근사(`APPROX_FROM_CUTS`)이고, CST 응답은 제조사 인증이나 mesh 수렴 결과가 아니다.
- **손실 미반영:** 편파·차폐·회절 손실은 넣지 않았다(BLOCKED pair는 자유공간 값).
- **Ka 근거리:**
  - 직접 반사판 장만 계산했다. 구조 산란·feed spillover·부반사판·스트럿은 모델링하지 않았고 상한이 아니다.
  - 반사판 모델은 주빔 0–1°만 데이터시트로 검증됐다. 광각 결과는 동결 export(legacy 포락선) 대비 15–18 dB 낮다.
  - 피간섭원은 국소 평면파 입사(S × λ²/4π × G)로 결합했다. 근거리 위상 방향과 기하 방향 차는 ≤ 2°다.
  - aperture 중심을 설치 기준점에 고정했다(pivot offset 미정의).
- **판정에 필요한 입력:**
  1. **송신 emission mask(dBc/Hz 또는 dBm/Hz, 기준면 명시)·스퓨리어스·고조파**(S TM, ISL, Ka는 radiated EIRP PSD 또는 필터 후 conducted PSD, SAR) → B·C 판정
  2. TX 출력 필터/다이플렉서 rejection(victim 대역), 수신기 대역 밖 선택도(2.25 / 10.6 / 25.5–27 GHz), P1dB/IIP3/블로킹(GPS, S TC, ISL, SAR) → A 판정
  3. L 안테나의 X·Ka 대역, S 안테나의 Ka 대역, SAR 안테나의 Ka 대역 응답
  4. KAA 짐벌 hard-stop·keep-out·pivot offset, 설치 구조를 포함한 Ka 산란 해석
  5. SAR 패턴·전력·듀티
  6. 다이플렉서 격리
  7. GNSS C/N0 기준
  8. 운용 모드 확정
