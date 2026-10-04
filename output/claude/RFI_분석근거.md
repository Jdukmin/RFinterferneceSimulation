# RFI 간섭 해석 — 분석근거 (패턴·케이스·수식·검증)

작성 2026-10-04. 실행 환경 **GNU Octave 9.2.0** (MATLAB 미사용). 저장소 `main` @ `7f0db47`.
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
| KA_DLS_TX@KAA_1 / @KAA_2 (25.5–27.0 GHz) | **동결** `KAA_KA_25P5/26P25/27P0` (`data/Kaband_KAA_CST/`) — Ka 전체 반사판의 CST RealizedGain은 없음. feed-only 결과로 대체하지 않음 | A와 동일 |

### 3.2 피간섭원(RX) 측 응답 — 간섭원 주파수에서

A·B 공통으로 **CST 자유공간 RealizedGain**을 쓴다. 피간섭원의 자기 운용 대역 이득으로 대체하지 않았다.

| 피간섭원 \ 간섭원 주파수 | S_TM (2.25) | ISL (10.6) | Ka (25.5–27) |
|---|---|---|---|
| S_TC_RX@SBA_NADIR/ZENITH (S 안테나) | `RFC_S_LOW_FREE` `S/S_TM` | `RFC_S_HIGH_FREE` `S/ISL` | **없음** (`RFC_S_KA_FREE` MESH_LIMIT 255,600) → INPUT_MISSING |
| GPS_Lx_RX@GPSA_1/2 (L 안테나, L1/L2/L5 케이스 공통) | `RFC_L_LOW_FREE` `L/S_TM` | **없음** (`RFC_L_HIGH_FREE` MESH_LIMIT 212,940) | **없음** (`RFC_L_KA_FREE` MESH_LIMIT 1,467,648) |
| ISL_X_RX (ISL 안테나) | `RFC_ISL_LOW_FREE` `ISL/S_TM` | 같은 안테나(자기 포트) → NOT_EVALUATED | `RFC_ISL_KA_FREE` `ISL/KA` |

정규화 신뢰도:
- 위에서 사용한 모든 컷은 `normalization_reliable = true`이다.
- `S/L2`, `S/L5` RealizedGain은 정규화 불안정(false)이다. 이번 pair에는 필요가 없어 사용하지 않았다(S는 L 대역에서 송신·수신하지 않음).

### 3.3 대조·민감도에만 쓴 패턴

| 용도 | 패턴 |
|---|---|
| 기존 엔진 대조(변형 E) | 양 끝 동결 패턴. S_TC → `SBAx_TC`, GPS → `GPS_L1` / `GPS_L2`(CST 1227.6 MHz) / `GPS_L5`, ISL → `ISL_10P6`, 단일 주파수 재사용(엔진 방식) |
| S 잠정 설치 ΔG | `RFC_S_LOW_SBA_NADIR_R1P75`, `RFC_S_LOW_SBA_ZENITH_R1P75` − `RFC_S_LOW_FREE_M4R10`. 원시 열 `realized_gain_dbi`(legacy `gain` 열은 사용 안 함), 2.2/2.25/2.3 GHz. 기본 결과에 섞지 않음 |
| 누락 응답 경계값 | 피간섭원 이득 가정 −10 / 0 / +5 dBi (ASSUMPTION) |
| KAA 조향 최악 | 동결 Ka 패턴의 주빔(26.25 GHz 보어사이트 32.63 dBi). 반구 조향 가정 내에서만 |
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
수신 레벨  P_rx = P_tx + 10·log10( mean_k 10^(S21(f_k)/10) )                  [dBm, 피간섭원 안테나 포트]
대역 내 간섭 P_I = P_tx + 10·log10(B_overlap/B_tx) + 10·log10(mean over overlap 10^(S21/10))   (중첩 없으면 −∞)
허용 레벨  P_allow = kTB + NF + (I/N)_max          (B = 수신 필터 대역, I/N = −6 dB, rf_systems)
필요 제거도 = P_rx − P_allow                           (대역 밖 기본파를 수신단이 걸러야 할 양)
집계      P_agg = 10·log10( Σ_i 10^(P_rx,i/10) )          (활성 TX만, 선형 합)
```

- **P_tx:** 송신 안테나 입력단 기준 전력이다. RealizedGain(입사 전력 기준)과 맞는 기준이다.
- **mismatch:** RealizedGain에 이미 들어 있으므로 다시 빼지 않았다. accepted Gain은 사용하지 않았다.
- **동결 패턴(B, Ka):** 이득 기준(datasheet 포락선 또는 accepted-power 모델)을 그대로 두었다. mismatch를 따로 더하거나 빼지 않았다.
- **편파 손실:** RealizedGain이 total 이득이라 적용하지 않았다.
- **차폐·회절:** LOS가 BLOCKED여도 손실을 넣지 않았다. 따라서 BLOCKED pair의 값은 자유공간 상한이다.
- **주파수 보간:** 한 대역의 계산된 저/중/고 monitor 사이에서만 dB 선형 보간한다. 미계산 구간은 메우지 않는다(`code/rfi_eval_set.m`).
- **원거리장 판정:** `R_ff = max(2·D_max²/λ, 5λ)`(λ는 송신 대역 상단 기준, D는 `max_dimension_m`)이다.
  - 만족하면 `FAR_FIELD_OK`이다.
  - 만족하지 못하면 `NEAR_FIELD_FRIIS_ESTIMATE`이고, 해당 값은 추정치다. 모든 Ka pair가 여기에 해당한다(R_ff ≈ 8.7 m > 거리).

## 6. 상태 코드

| 상태 | 의미 |
|---|---|
| `EVALUATED_OOB_LEVEL` | 대역 밖 pair. 수신 레벨과 필요 제거도를 계산했다. 블로킹·스퓨리어스는 판정하지 않았다(P1dB/IIP3/emission mask 없음) |
| `EVALUATED_OOB_LEVEL_ESTIMATE` | 위와 같고, 근거리장이라 Friis 추정치다 |
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
| 동결 원본 불변 | `git status` 상 `data/`, `src/`, `tests/` 변경 없음. 동결 테스트 포함 전체 1425/1425 통과 | `results/test_suite_log.txt` |

## 9. 재현

저장소 루트에서 다음을 실행한다(환경: `results/environment.txt`, 로그: `results/run_log.txt`).

```
octave-cli --no-gui --norc --eval "run('output/claude/run_rfi_analysis.m')"
octave-cli --no-gui --norc --eval "run('output/claude/make_figures.m')"
```
