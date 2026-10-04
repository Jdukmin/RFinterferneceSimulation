# RFI 간섭 해석 — 분석근거 (패턴·케이스·수식·검증)

작성 2026-10-04. 실행 환경 **GNU Octave 9.2.0** (MATLAB 미사용). 고정 SHA는 적지 않는다: 실행 기준 commit·작업트리 상태는 `results/run_provenance.csv`, 저장 commit은 `git log -- output/claude`로 확인한다. 메인 RFI 경로는 victim-band PSD(§11–§12), Ka 근거리(§10)는 secondary blocker 보조 자료다.
CST 신규 계산·형상 변경·설치 작업은 하지 않았다. 기존 CST 출력과 저장소 데이터만 읽었다.
결과 수치는 `RFI_분석결과보고서.md`, 기계 판독 근거는 `results/` 아래 CSV에 있다.

---

## 1. 무엇을 계산했나 (개수 구분)

| 구분 | 개수 | 내용 |
|---|---|---|
| 미션 분석 조합 | **6** | SBA variant {SBA1, SBA4} × GPS 대역 {L1, L2, L5} (`analysis_cases.csv`) |
| 물리 설치 위치 | 8 | SBA_NADIR, SBA_ZENITH, GPSA_1, GPSA_2, ISL, KAA_1, KAA_2, SAR_ANT |
| 설치/참조 패턴 구분 | 7 (+KAA 2, SAR 미결합) | S nadir/zenith × SBA1/SBA4 = 4, GPSA_1/GPSA_2 = 2, ISL = 1(자유공간) |
| 자유공간 패턴 원본 정체성 | 5 | SBA1, SBA4, 공통 GNSS, ISL, Ka (CST 물리 S 형상은 1개) |
| 케이스당 RF 기능 | TX 5 / RX 5 | TX: S_TM×2, ISL_TX, KA_TX×2 · RX: S_TC×2, GPS(케이스 대역)×2, ISL_RX |
| 케이스당 TX×RX | 25 | 같은 안테나 포트 3쌍(S_TM↔S_TC 같은 SBA 2, ISL_TX↔ISL_RX 1) 포함 |
| 전체 pair 행 | **150** | 6 × 25 (`results/pair_results.csv`) |

역할은 `active_queue.json`·`rf_systems.csv`를 따른다. S는 TM 송신과 TC 수신, L(GPS)은 수신만, ISL은 송·수신, Ka는 송신만이다.
Ka RX와 L TX는 만들지 않았다. SAR는 패턴이 결합되지 않아 가정 민감도로만 다룬다(§7).

동시 활성 집합은 `operating_modes.csv`의 scenario 정의에서 읽었다.
- `SCREENING_ALL_TX`: 등록된 모든 TX와 RX가 동시에 켜진 screening 가정이며, 운용 모드가 아니다.
- `NOM_NADIR_KAA1`, `NOM_ZENITH_KAA2`: 잠정 운용 모드 템플릿이다.

집계는 이 활성 집합 안에서 선형 전력 합으로 했다(`results/aggregate_by_victim.csv`).

## 2. 사용 입력 (원본 경로)

| 입력 | 경로 | 용도 |
|---|---|---|
| CST 상태 스냅샷 | `docs/reports/rfi_handoff/current_cst_status.csv`, `cst/results/rfc_frequency_cases/*/status.json` | case 상태·mesh·국소좌표 확인 |
| CST 자유공간 포트 응답 | `data/antenna_port_response_cst/provenance.json` + `{S,L,ISL}/{band}/` | **RealizedGain** 컷(XZ/YZ, 1°) |
| peak 요약 | `docs/reports/rfi_handoff/realized_gain_peaks.csv` | 컷 읽기 대조용으로만 사용(방향 이득으로 쓰지 않음) |
| 동결 기준 패턴 | `pattern_bindings.csv` → `data/Sband_TMTC`, `data/Lband_GPS`, `data/Lband_GPS_CST_L2`, `data/Xband_ISL`, `data/Kaband_KAA_CST` | 기준 TX 패턴(B), 엔진 대조 |
| S 잠정 설치 원시 컷 | `cst/results/rfc_frequency_cases/RFC_S_LOW_SBA_{NADIR,ZENITH}_R1P75/`, `RFC_S_LOW_FREE_M4R10/` | **민감도 전용** ΔG |
| RF 시스템 | `rf_systems.csv` | 주파수·대역폭·전력·NF·I/N 기준(provenance 포함) |
| 형상·설치 | `hull_*.csv`, `panels.csv`, `antenna_installations.csv`, `steering_constraints.csv` | 위치·보어사이트·LOS·KAA 반구 |
| 안테나 치수 | `antenna_functions.csv: max_dimension_m` | 원거리장 판정 |

## 3. 어떤 패턴을 어떤 케이스에 썼나

전체 행 단위 목록은 `results/pattern_usage_manifest.csv`(396행)에 있다. 각 pair·측(TX/RX)·변형마다 파일 경로까지 남겼다.
요약하면 다음과 같다. **6개 케이스 모두** 아래 규칙을 따르고, 케이스마다 바뀌는 것은 *SBA variant(B 변형의 S TX 패턴)*와 *GPS 수신기 대역(허용 레벨·피간섭원 ID)*뿐이다.

### 3.1 간섭원(TX) 측 이득 — 자기 운용 대역

| 간섭원 | 변형 A (기본: 포트 기준 일관) | 변형 B (기준 패턴) |
|---|---|---|
| S_TM_TX@SBA_NADIR / @SBA_ZENITH (2.2487–2.2513 GHz) | CST `RFC_S_LOW_FREE`, `S/S_TM` **RealizedGain**, monitor 2.2/2.25/2.3 GHz. SBA1·SBA4 공통(형상 1개) | 동결 `SBA1_TM` (SBA1 케이스) / `SBA4_TM` (SBA4 케이스), `data/Sband_TMTC/SBAx_TM_{XZ,YZ}.csv` (datasheet 포락선) |
| ISL_X_TX (10.59–10.61 GHz) | CST `RFC_ISL_HIGH_FREE`, `ISL/ISL` RealizedGain, 10.55/10.6/10.65 GHz | 동결 `ISL_10P55/10P6/10P65` (`data/Xband_ISL/f10.*`) |
| KA_DLS_TX@KAA_1 / @KAA_2 (25.5–27.0 GHz) | **반사판 aperture 근거리 직접장** (`REFLECTOR_APERTURE_NEAR_FIELD`, §10): CST feed `KA_FEED_C_OEWG` + 검증된 등가 포물면 aperture, 25.5/26.25/27 GHz. 등가이득 Geq = 4πd²S/P | 동결 `KAA_KA_25P5/26P25/27P0` (`data/Kaband_KAA_CST/`) + Friis (원거리 참고값) |

### 3.2 피간섭원(RX) 측 응답 — 간섭원 주파수에서

A·B 공통으로 **CST 자유공간 RealizedGain**을 쓴다. 피간섭원의 자기 운용 대역 이득으로 대체하지 않았다.

| 피간섭원 \ 간섭원 주파수 | S_TM (2.25) | ISL (10.6) | Ka (25.5–27) |
|---|---|---|---|
| S_TC_RX@SBA_NADIR/ZENITH (S 안테나) | `RFC_S_LOW_FREE` `S/S_TM` | `RFC_S_HIGH_FREE` `S/ISL` | **없음** (`RFC_S_KA_FREE` MESH_LIMIT 255,600) → INPUT_MISSING |
| GPS_Lx_RX@GPSA_1/2 (L 안테나, L1/L2/L5 케이스 공통) | `RFC_L_LOW_FREE` `L/S_TM` | **없음** (`RFC_L_HIGH_FREE` MESH_LIMIT 212,940) | **없음** (`RFC_L_KA_FREE` MESH_LIMIT 1,467,648) |
| ISL_X_RX (ISL 안테나) | `RFC_ISL_LOW_FREE` `ISL/S_TM` | 같은 안테나(자기 포트) → NOT_EVALUATED | `RFC_ISL_KA_FREE` `ISL/KA` |
| SAR_X_RX (SAR 안테나, Ka 경로만) | — | — | **없음** (NO_PATTERN_BOUND) → INPUT_MISSING |

정규화 신뢰도:
- 위에서 사용한 모든 컷은 `normalization_reliable = true`이다.
- `S/L2`, `S/L5` RealizedGain은 정규화 불안정(false)이다. 이번 pair에는 필요가 없어 사용하지 않았다(S는 L 대역에서 송신·수신하지 않음).

### 3.3 대조·민감도에만 쓴 패턴

| 용도 | 패턴 |
|---|---|
| 기존 엔진 대조(변형 E) | 양 끝 동결 패턴. S_TC → `SBAx_TC`, GPS → `GPS_L1` / `GPS_L2`(CST 1227.6 MHz) / `GPS_L5`, ISL → `ISL_10P6`, 단일 주파수 재사용(엔진 방식) |
| S 잠정 설치 ΔG | `RFC_S_LOW_SBA_NADIR_R1P75`, `RFC_S_LOW_SBA_ZENITH_R1P75` − `RFC_S_LOW_FREE_M4R10`. 원시 열 `realized_gain_dbi`(legacy `gain` 열은 사용 안 함), 2.2/2.25/2.3 GHz. 기본 결과에 섞지 않음 |
| 누락 응답 경계값 | 피간섭원 이득 가정 −10 / 0 / +5 dBi (ASSUMPTION). Ka는 근거리 전력밀도 기반 `ASSUMPTION_ONLY` |
| KAA 조향 최악 | 근거리 직접장 짐벌 screening(§10.6). 반구 조향 가정 내에서만 |
| SAR 가정 | 피간섭원의 SAR 대역 RealizedGain은 CST(`S/SAR`, `ISL/SAR`, `RFC_*_HIGH_FREE`)를 쓴다. SAR 쪽 이득 −10/0/+10 dBi와 전력 63.98/66.99 dBm은 가정이다 |

## 4. 좌표 변환 (CST 교차검증용)

**국소좌표.** CST case와 동일하게 다음을 쓴다(`status.json local_to_body_rotation`과 일치 확인).
- `+X_L = +X_B`, `+Z_L = 보어사이트(장착 패널 외향 법선)`, `+Y_L = +Z_L × +X_L`
- `R_BL = [X_L Y_L Z_L]`, `d_L = R_BLᵀ d_B`
- 확인값: SBA_NADIR `R_BL = [[1,0,0],[0,0.5,0.866],[0,−0.866,0.5]]`, SBA_ZENITH `[[1,0,0],[0,−1,0],[0,0,−1]]`

**방향 각도.**
- `θ = acos(d_z)`(보어사이트로부터), `φ = atan2(d_y, d_x)`
- 간섭원 측은 피간섭원을 향한 단위벡터, 피간섭원 측은 간섭원을 향한 단위벡터를 쓴다.
- 각 pair의 `tx/rx_off_boresight_deg`, `tx/rx_phi_local_deg`를 CSV에 기록했다.

**두 컷 재구성.**
- XZ 컷 각 t는 방향 (sin t, 0, cos t), YZ 컷 각 t는 (0, sin t, cos t)이다.
- φ = 0/90/180/270에 각각 XZ(θ), YZ(θ), XZ(360−θ), YZ(360−θ) 값을 놓고 φ에 대해 선형 보간한다(`APPROX_FROM_CUTS`, 완전 3D 아님).
- 구현: `code/rfi_cut_gain.m`.

**기존 `CutPatternAssembler`를 CST 응답에 쓰지 않은 이유.** 이 함수는 원본 +X를 저장소 안테나 프레임 +Y_A로 보낸다. CST 국소 +X(=+X_B)는 저장소 프레임의 +Z_A이므로, XZ·YZ가 다른 CST 응답에 쓰면 두 평면이 뒤바뀐다. 동결 패턴(XZ≈YZ)에서는 영향이 거의 없고, 엔진 대조로 확인했다(§8).

**검증.** XZ·YZ 평면 위의 방향에서 평가값이 컷 값과 같다(최대 오차 5.3e-15 dB, `results/check_cut_directions.csv`).
- S_NADIR↔S_ZENITH 쌍은 φ가 정확히 90°/270°이다. 즉 YZ 컷 값(θ = 151.66°/148.34°)을 그대로 읽으면 된다.

## 5. 수식 (각 항은 한 번만 적용)

송신 점유 대역 [f_lo, f_hi] = `fc ± bw/2`(`rf_systems.csv`)를 21점으로 나눈 각 f_k에서 다음을 계산한다.

```
S21(f_k) = G_tx(f_k, θ_tx, φ_tx) + G_rx(f_k, θ_rx, φ_rx) − FSPL(f_k, d)        [dB]
FSPL(f,d) = 20·log10(4π d f / c)
blocker    P_blk = P_tx + 10·log10( mean_k 10^(S21(f_k)/10) )                 [dBm, 피간섭원 안테나 포트, TX 반송파 대역]
대역 내 간섭 P_I = P_tx + 10·log10(B_overlap/B_tx) + 10·log10(mean over overlap 10^(S21/10))   (중첩 없으면 −∞)
허용 레벨  P_allow = kTB + NF + (I/N)_max          (B = 수신 필터 대역, I/N = −6 dB, rf_systems)
진단값     screening_suppression_to_inband_limit = P_blk − P_allow   (요구사항 아님, §11.5)
집계      P_agg = 10·log10( Σ_i 10^(P_blk,i/10) )          (활성 TX만, 선형 합)
```

- **P_tx:** 송신 안테나 입력단 기준 전력이다. RealizedGain(입사 전력 기준)과 맞는 기준이다.
- **mismatch:** RealizedGain에 이미 들어 있으므로 다시 빼지 않았다. accepted Gain은 사용하지 않았다.
- **동결 패턴(B, Ka):** 이득 기준(datasheet 포락선 또는 accepted-power 모델)을 그대로 두었다. mismatch를 따로 더하거나 빼지 않았다.
- **편파 손실:** RealizedGain이 total 이득이라 적용하지 않았다.
- **차폐·회절:** LOS가 BLOCKED여도 손실을 넣지 않았다. 따라서 BLOCKED pair의 값은 자유공간 상한이다.
- **주파수 보간:** 한 대역의 계산된 저/중/고 monitor 사이에서만 dB 선형 보간한다. 미계산 구간은 메우지 않는다(`code/rfi_eval_set.m`).
- **원거리장 판정:** `R_ff = max(2·D_max²/λ, 5λ)`(λ는 송신 대역 상단 기준, D는 `max_dimension_m`)이다.
  - 만족하면 `FAR_FIELD_OK`이다.
  - 만족하지 못하면 `NEAR_FIELD_FRIIS_ESTIMATE`이고, 해당 값은 추정치다.
  - **Ka pair는 Friis를 쓰지 않는다.** 모든 KAA–피간섭원 거리(1.8–6.2 m)가 R_ff(8.2–8.7 m)보다 짧아 `NEAR_FIELD_APERTURE_INTEGRATION`(§10)으로 계산한다. 수신 레벨은 `P_port = S·λ²/(4π)·G_rx`의 3-monitor 선형 평균이다.

## 6. 상태 코드

| 상태 | 의미 |
|---|---|
| `EVALUATED_OOB_LEVEL` | 대역 밖 pair. blocker 포트 전력을 계산했다. 블로킹은 판정하지 않았다(`PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN`) |
| `EVALUATED_OOB_LEVEL_ESTIMATE` | 위와 같고, 근거리장이라 Friis 추정치다 |
| `EVALUATED_OOB_LEVEL_NEAR_FIELD` | Ka: 반사판 aperture 근거리 직접장으로 포트 레벨을 계산했다 (`DIRECT_REFLECTOR_FIELD_ONLY`, `STRUCTURE_SCATTERING_NOT_MODELED`) |
| `PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN` | blocker 포트 전력은 평가했고, 수신기 BPF/블로킹/P1dB/IIP3가 없어 블로킹 판정은 하지 않았다(Ka 포함 전 경로 공통; Ka 1차 갱신 때의 `PORT_COUPLING_EVALUATED_RECEIVER_BLOCKING_UNKNOWN`을 대체) |
| `EMISSION_MASK_MISSING_COUPLING_EVALUATED` | victim-band PSD 경로: 피간섭원 주파수의 C_EM은 계산했고 TX emission mask가 없어 포트 PSD는 미평가 |
| `COUPLING_INPUT_MISSING` | victim-band PSD 경로: 송신 또는 수신 안테나의 피간섭원 대역 CST 응답이 없거나 정규화 불안정 |
| `KA_EMISSION_REQUIRES_RADIATED_EIRP_PSD_OR_CONDUCTED_PSD_PLUS_KAA_LOWBAND_RESPONSE` | Ka victim-band 경로: KAA의 S/L/X 대역 응답이 없고 Ka 패턴을 재사용하지 않음. G_rx − FSPL만 계산 |
| `TX_CHAIN_LOSS_MISSING`, `MASK_NOT_DEFINED_AT_FREQUENCY` | mask는 있으나 기준면 하류 손실이 없거나, 해당 주파수에 mask가 정의되지 않음 |
| `PORT_COUPLING_NOT_EVALUATED` | Ka: 피간섭원 Ka 응답이 없어 포트 결합 자체를 평가하지 않았다 |
| `ASSUMPTION_ONLY` | 결과가 아닌 참고값(예: 누락 피간섭원 0 dBi). 별도 파일·열에만 둔다 |
| `EVALUATED_IN_BAND` | 대역 내 중첩 pair(이번 기준에는 없음) |
| `INPUT_MISSING` | 피간섭원 안테나의 간섭원 대역 응답이 없다(CST MESH_LIMIT). `sensitivity.csv`에 경계값만 있다 |
| `NOT_EVALUATED` | 같은 안테나 포트(다이플렉서/T-R 격리, 송신 잡음 입력 없음) |

PASS/FAIL은 대역 내 pair에서만 내는데, 해당 pair가 없다. 대역 밖 결과가 작다고 EMC 적합으로 판정하지 않는다.

## 7. SAR

- **송신 가정:** SAR를 송신원으로 가정할 때 대역(9.3875–9.9125 GHz)과 전력(2.5/5 kW)은 `rf_systems.csv` 값이다.
- **실제 데이터인 부분:** 피간섭원(S, ISL)의 SAR 대역 RealizedGain은 CST 실제 데이터다.
- **가정인 부분:** SAR 안테나 이득(피간섭원 방향)은 −10/0/+10 dBi로 가정했다. 결과는 가정 민감도다(`results/sar_assessment.csv`).
- **GPS:** L 안테나의 SAR 대역 응답이 없어 INPUT_MISSING이다.
- **SAR가 피간섭원일 때:** 간섭원 측(이득 + FSPL)만 계산했다. SAR 이득과 SAR 수신 기준이 없어 판정하지 않았다.

## 8. 검증 기록

| 검증 | 결과 | 파일 |
|---|---|---|
| 컷 방향(평면 위 방향 = 컷 값) | 최대 5.3e-15 dB | `results/check_cut_directions.csv` |
| peak 표(120개 컷 최대값) 재현 | 120/120 일치(오차 0) | `results/run_log.txt` |
| 기존 엔진(MissionCaseBuilder + RfcLevelReport) 대조: 동결 패턴 양 끝, fc 단일 주파수 | 132 pair, 최대 0.158 dB, 평균 0.007 dB (엔진 2° 격자 보간 차이) | `results/engine_crosscheck.csv` |
| 순·역방향 대칭(같은 주파수·같은 CST 응답) | S_TM NADIR→TC ZENITH = ZENITH→TC NADIR = −69.28 dB | `pair_results.csv` |
| A 변형의 케이스 독립성 | 6개 케이스에서 같은 물리 pair의 A값이 모두 동일(형상 1개, GPS 응답은 2.25 GHz에서 같은 안테나) | 스크립트 점검 |
| 동결 원본 불변 | `data/`, `cst/` 변경 없음(KAA 반사판 모델·검증 포함). `src/`는 `+kaa` 패키지 추가만, 기존 파일 무변경. 동결 테스트 포함 전체 1512/1512 통과(기존 1425 + Ka 87) | `results/test_suite_log.txt` |
| Ka 근거리 → 원거리 수렴 | 10·R_ff 이상 null 제외 FAIL 0행; 100·R_ff 최대 4e-4 dB | `results/ka_nearfield_validation.csv` |
| Ka 원거리 재현(MATLAB vs Python 반사판 CSV) | 최대 0.0095 dB, 주빔 0.0000 dB | 같은 파일 |
| 비-Ka 결과 불변 | 이전(`4493d4d`) 대비 S/L/ISL 행 무변경 | `results/previous_run_manifest.csv` |

## 9. 재현

저장소 루트에서 다음을 실행한다(환경: `results/environment.txt`, 로그: `results/run_log.txt`).

```
octave-cli --no-gui --norc --eval "run('output/claude/run_ka_nearfield_analysis.m')"   # 먼저 실행 (ka_*.csv)
octave-cli --no-gui --norc --eval "run('output/claude/run_rfi_analysis.m')"
octave-cli --no-gui --norc --eval "run('output/claude/run_psd_analysis.m')"          # blocker / PSD / 수신기 3단 (pair_results.csv 사용)
octave-cli --no-gui --norc --eval "run('output/claude/make_figures.m')"
```

`run_rfi_analysis.m`은 짐벌 최악값을 `results/ka_gimbal_worstcase.csv`에서 읽으므로 Ka 스크립트를 먼저 실행해야 한다(없으면 오류로 멈춤).

## 10. Ka KAA source model — 반사판 aperture 근거리 직접장

### 10.1 왜 바꿨나

- 이전 Ka 경로는 동결 패턴 + `Gtx + Grx − FSPL`(Friis)이었다.
- 그런데 KAA–피간섭원 거리(1.78–6.25 m)가 모두 2D²/λ(D = 0.22 m: 8.23 / 8.48 / 8.72 m)보다 짧다. 원거리 패턴의 전제가 성립하지 않는다.
- 그래서 반사판 aperture 장을 피간섭원 위치까지 직접 적분한다.

### 10.2 재사용한 KAA 모델 (재생성 없음)

| 항목 | 값 / 파일 |
|---|---|
| feed | CST full-wave `KA_FEED_C_OEWG`(`cst/results/KA_FEED_C_OEWG/feed_pattern.json`), RHCP, 네 반쪽 컷 선형 평균(= `ka_reflector_eval.py feed_interp`) |
| 반사판 | `cst/results/KA_REFLECTOR_KA_FEED_C_OEWG/reflector_validation.json`: D = 220 mm, θ_f = 40°, Fe = 151.11 mm, Ds = 44 mm, `KA_DATASHEET_ANCHOR_PASS` |
| aperture 장 | `ka_reflector_po.py`와 동일: ρ ∈ [Ds/2, D/2](부반사판 차폐), ψ = 2·atan(ρ/2Fe), r' = Fe/cos²(ψ/2), a(ρ) = √Gf(ψ)/r', 위상 = 등광로 GO(feed 위상오차 무시) |
| 이득 기준 | accepted-power(spillover 손실 포함). TX 전력 48.45 dBm을 accepted power로 둔다(기존 Ka 경로와 같은 기준) |
| 대조 | `data/Kaband_KAA_CST/ka_final_validation.json`의 D/Fe/Ds와 일치(테스트) |

### 10.3 Solver (`src/+rfscreen/+kaa/ApertureNearFieldSolver.m`)

```
Ea(ρ,φ)  = √(2ηP/4π) · a(ρ,φ)                          (∫|Ea|²/2η dA = P·∫Gf sinψ dψ dφ/4π)
E(r)     = √(2ηP/4π) · (jk/2π) · Σ_i a_i dA_i · Q_i · e^{−jkR_i}/R_i
Q_i      = ½[1 + cosχ_i (1 + 1/(jkR_i))],  cosχ_i = z/R_i,  R_i = |r − r'_i|
S        = |E|²/(2η)       Geq = 4πd²S/P       (d = aperture 중심–관측점 거리)
P_port   = S · λ²/(4π) · G_rx(f, 도래방향)       (피간섭원 국소 평면파 입사)
```

- 포함: 실제 진폭 taper, aperture 위상, 부반사판 차폐, 요소별 구면 위상, 1/R, 25.5/26.25/27 GHz.
- 적분: ρ 400점(사다리꼴) × φ 720점(주기 규칙). 임의 3D 관측점을 받는다.
- 원거리 극한은 `ka_reflector_po.py`의 `G(θ) = (k/2π)²|∫…|²((1+cosθ)/2)²`와 정확히 같다.
- 범위: `DIRECT_REFLECTOR_FIELD_ONLY`, `STRUCTURE_SCATTERING_NOT_MODELED`. feed spillover·부반사판·스트럿·선체 산란은 없다. 그래서 상한이라고 부르지 않는다.
- 근거리 파면 방향(위상 기울기)을 진단값으로 계산한다. ISL 수신 위치에서 기하 방향과 1.0–1.9° 차이다.

### 10.4 좌표계 (`CstLocalFrameAdapter`)

| 프레임 | 정의 |
|---|---|
| B (body) | 저장소 기준. 설치 위치는 B, m |
| A (repository antenna) | +X_A = 보어사이트, +Z_A = +X_B의 보어사이트 수직 성분, +Y_A = Z_A × X_A (`sideMountR_BA`, `GimbalSteeringDomain.steeredR_BA`) |
| L (CST local = KAA aperture) | +Z_L = 보어사이트, +X_L = +X_B(직교화), +Y_L = Z_L × X_L (CST `status.json local_to_body_rotation`) |

- 명시적 변환: `v_A = M_AL v_L`, `M_AL = [0 0 1; 0 −1 0; 1 0 0]`(det = +1), `R_BL = R_BA · M_AL`.
- 일반 `CutPatternAssembler.canonicalToAntenna()`(`[0 0 1; 1 0 0; 0 1 0]`)는 **쓰지 않는다.** 이 함수는 CST XZ 면을 X_A–Y_A 면으로 보내 비대칭 source에서 평면이 뒤바뀐다. 테스트에서 15° 기울인 합성 aperture로 이 차이(>15 dB)를 고정했다.
- 계산 순서: 짐벌 지향 u_B → `steeredR_BA(u_B)` → `R_BL` → 피간섭원 위치를 `r_L = R_BLᵀ(p_victim − p_KAA)`로 aperture frame에 넣는다.
- 확인값: KAA_1 `R_BL = I`(Panel #1 +Z), KAA_2 `R_BL = [[1,0,0],[0,−0.5,0.866],[0,−0.866,−0.5]]`. 짐벌 기준 지향 = 고정 장착 frame = `run_rfi_analysis.m local_frame`.

### 10.5 피간섭원 Ka 응답과 경로 분리

- `KaVictimResponse`는 `data/antenna_port_response_cst/provenance.json`의 `band = KA` RealizedGain만 읽는다.
  - S·L: `RFC_S_KA_FREE` / `RFC_L_KA_FREE` status.json이 MESH_LIMIT이다 → `INPUT_MISSING`(사유에 최소 mesh cell 수 기록).
  - SAR: 패턴 자체가 없음 → `INPUT_MISSING (NO_PATTERN_BOUND)`.
  - ISL: `RFC_ISL_KA_FREE` → `AVAILABLE`.
- 누락 응답은 컷을 갖지 않는다. 이득 평가를 요청하면 오류(`victimResponseMissing`)를 낸다. 0 dBi나 가정 제거도로 채우지 않는다.
- Ka 기본파 경로에 S_TC 등 **자기 운용대역 응답**을 넣으면 오류(`inBandGainForbidden`)를 낸다. 25.5–27 GHz 밖 주파수도 거부한다.
- `KA_SPUR_INBAND`은 별도 행이다. 피간섭원 대역 내 이득을 쓰는 경로이지만 KAA emission mask가 없어 `INPUT_MISSING`이다.
- 수신기 단계: BPF/블로킹/P1dB/IIP3가 없으면 `PORT_COUPLING_EVALUATED_RECEIVER_BLOCKING_UNKNOWN`. PASS/FAIL은 내지 않는다.

### 10.6 짐벌 screening (`KaGimbalScreening`)

- aperture가 축대칭이고 중심이 고정이므로 결합은 거리 d와 θ = ∠(u, v)만의 함수다(v = 피간섭원 방향).
- 반구(기준축 n, 90°)에서 도달 가능한 θ: [max(0, α−90°), min(180°, α+90°)], α = ∠(n, v). u는 (v, n) 평면에서 v → n 쪽으로 θ만큼 돌린 방향이다.
- 탐색: 0.25° 간격(축소 표본 160×360) → 최대 주변 ±0.25°를 0.01° 간격(전체 표본 400×720)으로 정밀화. 지표는 피간섭원 이득을 넣은 대역 평균 포트 전력, 응답이 없으면 대역 평균 전력밀도다.
- 상태 3개: 공칭(기준축), 피간섭원 지향(불가하면 최근접 허용 경계), 최대 결합. 각 상태의 `allowed_in_domain`을 기록했다.
- 회귀: 3D brute-force(6° 격자, `sampleDirections`)가 1-D 최대를 넘지 않는다.
- 가정: 반구는 단순화 가정이다. hard-stop·keep-out·기구 shadowing·pivot offset은 정의되지 않았다.

### 10.7 테스트 (`tests/test_ka_nearfield.m`, 87 checks)

| 범주 | 내용 |
|---|---|
| aperture 정규화 | aperture 전력 = feed 환형 전력(3주파수), 균일 개구 지향성 = 4πA/λ², 전력 선형성, P_port 식 |
| 원거리 수렴 | 26.25 GHz, 0–30°, 10·R_ff ≤ 0.05 dB, 100·R_ff ≤ 1e-3 dB, Python CSV ≤ 0.01 dB, 1.78 m 보어사이트는 원거리보다 0.5 dB 이상 낮음 |
| 대칭 | ±X, ±Y, XZ = YZ (0.8/4/25/120°) |
| 주파수 scaling | 균일 개구 이득 ∝ f², R_ff ∝ f, 검증 모델 보어사이트 32.28→32.98 dBi |
| KAA_1/KAA_2 좌표 | R_BL 확인값, CST local_frame 일치, 짐벌 기준 = 고정 장착, 거리 보존 |
| 짐벌 회전 | 피간섭원 지향 시 θ_ap = 0, +Y_B 지향 frame, 반구 밖 거부, worst ≥ nominal/directed, brute-force 상한 |
| 비대칭 합성 frame 회귀 | 15° 기울인 aperture: body 빔 방향 일치, canonical 매핑과 >10°·>15 dB 차이, X 거울대칭 아님 |
| 누락 응답 negative | S/L(MESH_LIMIT), SAR(NO_PATTERN_BOUND) INPUT_MISSING, 평가 시 오류, 컷 없음 |
| 대역 내 이득 오사용 방지 | S_TC 응답 거부, Ka 밖 주파수 거부, feed monitor 외 주파수 거부 |
| routing | S/ISL → free-space, KAA → near field, 원거리·검증 → far-field, 수신기·스퓨리어스 상태 |

## 11. RFI 3단 분리 — fundamental blocker / victim-band PSD / 수신기 적분

KARI reference 구조를 그대로 따른다: `TX spectrum → antenna / installed EM coupling → RX 기준면의 전력 또는 PSD → 수신기 감수성 → 유효 간섭 / margin`. 안테나 결합 자체를 수신기 rejection이라 부르지 않는다.

### 11.1 세 경로

| 경로 | 무엇 | 단위 | 주파수 | 결과 파일 |
|---|---|---|---|---|
| A. `FUNDAMENTAL_OOB_BLOCKER` | TX 반송파 → TX 안테나 @ f_TX → 결합 → 피간섭원 안테나 @ f_TX → 포트 blocker 전력 | dBm | TX 운용대역 | `oob_blocking_results.csv` |
| B. `VICTIM_BAND_EMISSION_PSD` | TX 불요 방사(mask) → TX 체인 감쇠 → C_EM @ f_victim → 포트 PSD vs 허용 PSD | dBm/Hz | 피간섭원 tuning 대역 전체 | `victim_band_psd_results.csv`, `psd_pair_summary.csv` |
| C. 수신기 적분 (2차) | I_rx = ∫ PSD_port \|H_rx\|² df (실제 채널·대역폭) → I/N, C/N0, J/S | dBm, dB | 선택 채널 | `receiver_integrated_results.csv` |

- A의 blocker 수치는 이전 결과와 **동일**하다(pair_results.csv에서 그대로 복사).
- A의 최종 판정에는 수신기 프리셀렉터/BPF rejection @ f_TX, 블로킹 한계, P1dB, 감도저하, IIP3가 필요하다. 없으면 `PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN`.
- B는 A의 결합을 쓰지 않는다. 예: S-TM → GPS L1은 `S 안테나 @ 1.57542 GHz + GPS 안테나 @ 1.57542 GHz − FSPL @ 1.57542 GHz`.

### 11.2 Victim-band PSD 식 (`src/+rfscreen/+psd`)

```
PSD_TX(f)          = P_carrier + mask(f)              [dBm + dBc/Hz = dBm/Hz]   (또는 dBm/Hz로 직접)
PSD_after_chain(f) = PSD_TX(f) − L_TXchain(f)         [dB 감쇠]
C_EM(f)            = G_tx,realized(f) + G_rx,realized(f) − FSPL(f)   (f = 피간섭원 주파수)
                   = S21(f)                            (port-to-port S21이 있으면; G/FSPL 중복 없음)
PSD_port(f)        = PSD_after_chain(f) + C_EM(f)
margin(f)          = PSD_allowable − PSD_port(f)       required_psd_suppression = PSD_port − PSD_allowable
```

- mask가 없을 때는 C_EM만 계산하고, 허용 PSD를 만족하는 **TX 안테나 포트 불요방사 한계** `PSD_allowable − C_EM(f)`를 파생 요구값으로 보고한다(결과가 아니라 입력 요구).
- 감쇠(dB)와 반송파 상대값(dBc, dBc/Hz)은 별도 타입이다. 감쇠는 음수를 거부한다.

### 11.3 기준면 (`EmissionSpec.chainTerms`)

| reference_plane | 추가 적용 TX 체인 손실 | TX 안테나 이득 | 비고 |
|---|---|---|---|
| PA_OUTPUT, FILTER_INPUT | filter + post-filter | 포함(RealizedGain) | 손실 미상 → `TX_CHAIN_LOSS_MISSING` (0 dB로 두지 않음) |
| FILTER_OUTPUT | post-filter만 | 포함 | |
| ANTENNA_PORT | 없음 | 포함 | 상류 손실 재적용 금지 |
| RADIATED_EIRP_PSD | 없음 | **불포함**: C = G_rx − FSPL | S21과 결합 시 오류(S21에 TX 안테나 포함) |

- CST RealizedGain에 mismatch가 들어 있으므로 S11 손실을 따로 빼지 않는다.

### 11.4 수신기 기준 (`data/rfi_psd/receiver_baseline.csv`)

| 수신기 | tuning/평가 대역 | NF | 잡음 PSD | 허용 간섭 PSD | 적분 BW (2차) | desired signal |
|---|---|---|---|---|---|---|
| GPS L1 / L2 / L5 | 1563–1588 / 1217.37–1237.83 / 1164–1189 MHz (CST monitor 범위) | 2 dB | −172 dBm/Hz | **−178 dBm/Hz** | 20.46 MHz (**ASSUMPTION**: 신호 main-lobe 폭, 수신기 BW 미확정) | −130 dBm (별도 항목, 간섭 기준 아님) |
| S-TC | 2025–2110 MHz (tuning 전체) | 3 dB | −171 dBm/Hz | **−177 dBm/Hz** | 5529.6 Hz (4096 bps × 1.35, RRC α 0.35, ENGINEERING_BASELINE) | 미상 |
| ISL RX | 10.55–10.65 GHz | 3 dB | −171 | −177 | 20 MHz (PROVISIONAL) | 미상 |
| SAR RX | 9.3875–9.9125 GHz | 5 dB | −169 | −175 | 525 MHz | 미상(패턴 없음) |

- kT0 = −174 dBm/Hz(290 K 관례, 정확값 −173.98)로 둔다.
- tuning 대역은 PSD mask 판정 영역이고, 잡음 대역폭으로 쓰지 않는다. 적분 BW는 2차 평가에만 쓴다.
- GPS 평가 대역은 CST 응답이 계산된 monitor 범위로 제한했다(외삽 없음).
- **S-TC 충돌:** `rf_systems.csv`는 128 kbps / 200 kHz를 갖고 있다(전력 기준 screening의 허용 −123.96 dBm). PSD 기준은 대역폭과 무관하다. 2차 적분 BW는 소유자 지시 4096 bps 기준 5.53 kHz로 두고 충돌을 그대로 표시했다.

### 11.5 기존 "필요 제거도" 재분류

- `required_rejection = received_level − allowable_power`는 최종 요구사항으로 쓰지 않는다.
- 이름을 `screening_suppression_to_inband_limit_db`(진단값)로 바꿨다: `pair_results.csv`(A/B), `aggregate_by_victim.csv`, `sensitivity.csv`, `sar_assessment.csv`, `oob_blocking_results.csv`.
- 의미: "TX 반송파 대역 blocker 총전력을 피간섭원 대역 내 열잡음 기준 수준까지 낮추기 위한 등가 억압량". 실제 OOB rejection 요구가 아니다.
- 실제 대역 내 억압 요구는 B 경로의 `required_psd_suppression_db = PSD_port − PSD_allowable`이다.
- `received_A/B_dbm` 열은 `oob_blocker_port_A/B_dbm`으로 바꿨다(값 동일).

### 11.6 불요방사 유형

| 유형 | 단위 | 평가 |
|---|---|---|
| broadband noise / spectral mask | dBc/Hz, dBm/Hz | B: PSD mask 비교 |
| discrete spur | dBc, dBm (+ RBW) | 포트 전력 dBm. PSD mask에 넣지 않음 → C에서 채널 안이면 적분 간섭으로 |
| harmonic | dBc, dBm | 포트 전력 dBm |
| 수신기 적분 간섭 | dBm | C |

### 11.7 입력 테이블 (신규 schema)

| 파일 | 열 |
|---|---|
| `data/rfi_psd/tx_emission_masks.csv` | §12.2 schema — **현재 비어 있음**(source 값 생성 안 함) |
| `data/rfi_psd/tx_chain_losses.csv` | tx_system, victim_band, frequency_hz, post_filter_db, provenance — 현재 비어 있음(TX 필터는 §12.3 filter scenario) |
| `data/rfi_psd/receiver_baseline.csv` | receiver, victim_band, tuning_lo/hi_mhz, tuning_prov, channel_fc_mhz, integration_bw_hz, integration_bw_prov, rx_filter_model, nf_db, nf_prov, i_n_max_db, desired_signal_reference_dbm, desired_prov, note |

### 11.8 Ka의 두 경로

- Ka blocker: KAA aperture 근거리 → 피간섭원 안테나 @ Ka → 포트 전력(§10). S/L/SAR는 Ka 응답이 없어 INPUT_MISSING.
- Ka victim-band 방사: TX 불요방사 @ S/L/X → TX 체인 → (KAA의 S/L/X 대역 응답 또는 radiated EIRP PSD) → 피간섭원 @ f_victim → PSD 비교.
  - KAA feed/도파관/필터의 저주파 전달 특성이 지배적이므로 Ka 반사판 패턴을 S/L에 쓰지 않는다(외삽 금지).
  - 현재 G_rx − FSPL(`coupling_rx_only_db`)만 계산했다. Radiated EIRP PSD 규격이 들어오면 바로 비교할 수 있다(파생 한계: `min_max_tx_eirp_psd_dbm_hz`).

### 11.9 테스트 (`tests/test_rfi_psd.m`, 77 checks)

dBc/Hz→dBm/Hz, 60 dB 필터, −120→−180 dBm/Hz reference(전 −58 FAIL / 후 +2 PASS), GPS −178·S-TC −177 기준, tuning 대역 전체 sweep, 적분 BW와 tuning 분리, blocker/PSD 경로 분리, 기준면 중복 방지(ANTENNA_PORT·FILTER_OUTPUT·PA_OUTPUT·EIRP·S21), CST victim-band 응답 사용, 공격자 대역 패턴 재사용 거부, spur/broadband 단위 구분, 빈 mask 테이블.

## 12. 메인 축 재정렬 — victim-band PSD primary, blocker secondary

### 12.1 경로와 우선순위

| 순위 | 경로 | 결과 |
|---|---|---|
| **PRIMARY** | `VICTIM_BAND_EMISSION_PSD`: TX compliant source emission → filter scenario → victim-band coupling → 포트 PSD → 허용 PSD → margin / required additional suppression | `psd_pair_summary.csv`, `victim_band_psd_results.csv`, `rfi_analysis_readiness.csv` |
| SECONDARY | `SECONDARY_OOB_BLOCKER_ANALYSIS`: 기본파 blocker 포트 전력 | `oob_blocking_results.csv` (전부 `PORT_EXPOSURE_EVALUATED_BLOCKING_UNKNOWN`) |
| 2차 수신기 | I_rx = ∫PSD\|H\|²df, I/N (C/N0, J/S는 수신기 모델 필요) | `receiver_integrated_results.csv` |
| Appendix | Ka 근거리 aperture blocker | `ka_*.csv`, §10 |

- 메인 경로는 **피간섭원 대역 응답만** 쓴다. 공격자 반송파의 피간섭원 응답(blocker 대역)이 mesh 한도로 없어도 막히지 않는다(예: ISL → GPS).
- source emission이 없으면 결합과 최대 허용 TX PSD까지만 계산한다. PASS/FAIL은 내지 않는다(`EMISSION_SPEC_MISSING`).

### 12.2 TX source emission schema (`data/rfi_psd/tx_emission_masks.csv`)

| 열 | 내용 |
|---|---|
| tx_system, victim_band | 송신기 template (예: S_TM_TX, ISL_X_TX, KA_DLS_TX), 피간섭원 대역 key (S_TC, L1, L2, L5, ISL, SAR) |
| frequency_hz / frequency_lo_hz, frequency_hi_hz | 점 또는 flat 범위 |
| emission_type, level, unit, reference_bandwidth_hz | BROADBAND_PSD: dBm/Hz, dBc/Hz, 또는 RBW당 dBm/dBc(→ level − 10log10 RBW). DISCRETE_SPUR: dBm/dBc + RBW. HARMONIC: dBm/dBc |
| reference_plane | PA_OUTPUT, FILTER_INPUT, FILTER_OUTPUT, ANTENNA_PORT (conducted), RADIATED_EIRP_PSD (절대 단위만) |
| carrier_frequency_hz, filter_state | dBc 기준 반송파, PRE/POST_FILTER/UNKNOWN |
| standard_or_source, provenance | 규격·문서·조항 / 측정 id |
| assumption_class | REGULATORY_LIMIT, SUPPLIER_SPEC, MEASURED, ENGINEERING_ASSUMPTION (reference 전용 REFERENCE_CROSSCHECK) |

- User/reference scenario는 `data/rfi_psd/reference_scenarios.csv`에 둔다. 열은 같고, scenario_id·rx_receiver·coupling_override_db가 추가된다. 같은 엔진으로 계산하며 mission 결과와 섞지 않는다.
- 이번 단계에서는 어떤 규격(ITU/CCSDS/SFCG/vendor), RBW, broadband/spur 구분을 쓸지 정하지 않았다. 표는 비어 있다.

### 12.3 Filter scenario (`data/rfi_psd/filter_scenarios.csv`, `rfscreen.psd.FilterScenario`)

- `FLAT`(FILTER_0/40/60/70/80DB, `SCREENING_FILTER_SCENARIO`)과 `TABLE`(주파수별, dB 선형 보간, 외삽 없음)을 지원한다.
- 모든 PSD 결과 행에 `filter_scenario_id`, `filter_attenuation_db`, `filter_provenance`를 남긴다.
- 의미: PA_OUTPUT/FILTER_INPUT source에서는 TX 출력 필터, 그 외 기준면에서는 source에 포함된 것 외의 추가 외부 필터다.
- post-filter 손실(`tx_chain_losses.csv`)이 미상이면 0 dB를 적용한다(보수적). `POST_FILTER_LOSS_UNKNOWN_0DB_CONSERVATIVE`로 표시한다.

### 12.4 Radiated EIRP vs conducted source

| source | 결합 | 필요한 응답 | 없을 때 |
|---|---|---|---|
| RADIATED_EIRP_PSD | `PSD_victim = EIRP_PSD − L_filter − FSPL + G_RX` (TX 이득 중복 적용 없음) | 피간섭원 안테나 @ f_victim | `COUPLING_INPUT_MISSING` |
| conducted (PA_OUTPUT … ANTENNA_PORT) | `G_TX(f_v) + G_RX(f_v) − FSPL(f_v)` | TX와 피간섭원 안테나 @ f_victim | Ka: `KAA_VICTIM_BAND_RADIATION_RESPONSE_MISSING`, 그 외 `COUPLING_INPUT_MISSING` |

- Ka 26 GHz 반사판 패턴은 S/L/X로 외삽하지 않는다.

### 12.5 결과 schema

- `psd_pair_summary.csv` (pair × filter scenario): coupling_conducted/radiated min·max, max_allowable_tx_psd_conducted_dbm_hz (+ dBc/Hz), max_allowable_tx_eirp_psd_dbm_hz, source_emission_status, source_emission_psd_dbm_hz, source_emission_reference_plane, source_spec_provenance, filter_scenario_id, filter_attenuation_db, filter_provenance, victim_port_psd_dbm_hz, allowable_psd_dbm_hz, psd_margin_db, required_additional_suppression_db, result_status, readiness_status.
- `rfi_analysis_readiness.csv`: tx_system, rx_system, victim_band, victim_coupling_available, tx_emission_spec_available, tx_filter_data_available, radiated_eirp_psd_supported, blocker_path_available, readiness_status (`READY_FOR_PSD_ANALYSIS` / `EMISSION_SPEC_MISSING` / `COUPLING_INPUT_MISSING` / `KAA_RADIATED_PSD_OR_LOWBAND_RESPONSE_REQUIRED` / `NOT_APPLICABLE_SAME_PORT`), missing_inputs.
- `oob_blocking_results.csv`: `analysis_class = SECONDARY_OOB_BLOCKER_ANALYSIS`. 진단 열은 `screening_suppression_to_inband_limit_db_DIAGNOSTIC_ONLY`다.
- `run_provenance.csv`: 스크립트별 run_time, analysis_base_commit, working_tree.

### 12.6 회귀 고정값 (`tests/test_rfi_psd.m`, 출력 파일과 독립적으로 CST 응답·형상에서 재계산)

| 값 | 기대 | 결과 |
|---|---|---|
| S-TM@ZENITH → GPSA_1 blocker (2.25 GHz) | ≈ −21.3 dBm | −21.32 ± 0.05 |
| S-TM → 반대편 S-TC blocker | ≈ −32.3 dBm | −32.29 ± 0.05 |
| S-TM@ZENITH → GPS L1 C_EM | ≈ −81 dB | −81.38 ~ −80.98 |
| S-TM → 반대편 S-TC C_EM | −69 ~ −70 dB | −70.23 ~ −69.09 |
| S-TM → GPS L1 최대 허용 TX PSD | ≈ −97 dBm/Hz | −97.02 |
| S-TM → 반대편 S-TC 최대 허용 TX PSD | ≈ −108 dBm/Hz | −107.91 |

## 13. 송신기 불요방사 규격 적용 (Claude 독립 분석, freeze point 8469e89)

- **source(규격, 1차):** RR Appendix 3 (Rev.WRC-12) Table I 우주국을 쓴다.
  - 감쇠 A = min(43 + 10 log P[W], 60) dBc, 4 kHz 기준 대역폭(AP3 §8, note 10), 안테나 전송선 기준.
  - 광대역 등가 PSD = P − A − 10 log10(4000) [dBm/Hz]이다. S-TM·ISL −49.02, Ka −47.57 dBm/Hz.
- **감도:** ECSS-E-ST-50-05C Table 5-6 −60 dBc/4 kHz.
- **이산 스퍼:** RR AP3 단일 성분(4 kHz)과 CCSDS 401 rec. 2.4.16(단일 스퍼 총전력 −60 dBc). PSD로 변환하지 않고 채널 적분 허용 전력과 비교한다.
- **영역:** AP3 Annex 1 Table 1로 경계를 정했다. 모든 피간섭원 대역이 spurious 영역이다(`results/oob_spurious/domain_and_harmonic_check.csv`).
- **결합:** 피간섭원 주파수의 CST RealizedGain을 쓴다. TX 안테나의 해당 대역 응답이 없으면(KAA S/L/X, S 안테나 L2/L5 정규화 불안정) G_TX 대신 Harrington 최대 지향성 D = (ka)² + 2ka를 쓴다(물리 상한, 완전 정합·최악 지향).
  - a: KAA 119 mm, S 53 mm
  - 26 GHz 패턴은 재사용하지 않는다.
- **Ka 조건부 감도:** WR-42(f_c 14.05 GHz) 구간 길이 2λc의 evanescent 감쇠 109.15·√(1 − (f/f_c)²) dB. 근거는 SM.329-13 recommends 2.5이며, KAA 실제 구간 길이는 미확인이다.
- **필터:** `data/rfi_psd/filter_scenarios.csv`(0/40/60/70/80 dB)를 추가 외부 필터로 적용한다. 최소 추가 억제량 = max_f(포트 PSD − 허용 PSD).
- **코드:** `output/claude/run_oob_spurious_analysis.m`(공유 엔진 `src/+rfscreen/+psd` 사용, 변경 없음), 검증 `output/claude/validate_oob_spurious.m`. 입력은 `output/claude/inputs/tx_emission_sources_claude.csv`.
