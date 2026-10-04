# RFI 설계 보고서 — Task 2: 범위 단순화, SAR/ISL victim-only, Ka 도파관 cutoff route

## 1. Executive Summary

**Primary 범위는 S-TC TX와 Ka DLS TX 두 attacker로 줄었다.** ISL과 SAR는 victim으로만 다룬다.

**S-TC TX(legacy id: S_TM_TX):**
- 일반 spurious 기준으로 GPS L2/L5(70.45/70.87 dB, 80 dB scenario)와 SAR RX(63.36 dB, 70 dB scenario)가 가장 큰 추가 억제를 요구한다.
- 고조파는 SAR 대역과 겹치지 않는다(`NO_HARMONIC_OVERLAP`).

**Ka DLS TX:**
- 경로는 최대 EIRP 49.451 dBW → WR-42 below-cutoff 50 mm(owner 가정)다.
- GPS와 S-TM RX는 추가 억제가 필요 없다(margin +20.9 dB 이상).
- ISL RX는 6.58 dB, SAR RX는 8.08 dB가 남는다(40 dB scenario 통과).
- ISL과 SAR는 cutoff에 가까워 도파관 감쇠가 작기 때문이다.

**입력과 확정 조건:**
- 이번 판의 Ka 도파관과 SAR 절대 이득은 owner 입력이다: WR-42, 유효 길이 50 mm, SAR peak 52 dBi, ±80° 밖 −50 dB.
- 모두 공학 가정·추정이며 측정이나 full-wave 검증값이 아니다.
- 추가 CST 시뮬레이션은 하지 않았다.

| Attacker | Victim | Band | Source PSD/EIRP | Coupling | Victim PSD | Limit | Required suppression | First PASS | Design target | Confidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S-TC TX (legacy id: S_TM_TX) | GPS RX | L1 | −49.02 | −80.98 | −130.00 | −178.00 | 48.00 | 60 dB | 60 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | GPS RX | L2 | −59.02 (−10 dB rescaling) | −48.53 | −107.55 | −178.00 | 70.45 | 80 dB | 90 dB | ENGINEERING_BOUND (port mismatch) |
| S-TC TX (legacy id: S_TM_TX) | GPS RX | L5 | −59.02 (−10 dB rescaling) | −48.11 | −107.13 | −178.00 | 70.87 | 80 dB | 90 dB | ENGINEERING_BOUND (port mismatch) |
| S-TC TX (legacy id: S_TM_TX) | S-TM RX | S (2025–2110 MHz) | −49.02 | −69.09 | −118.11 | −177.00 | 58.89 | 60 dB | 70 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | ISL RX | X (10.55–10.65 GHz) | −49.02 | −88.72 | −137.74 | −177.00 | 39.26 | 40 dB | 50 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | SAR RX (harmonic) | SAR X | — | — | — | — | 해당 없음 | — | — | NO_HARMONIC_OVERLAP |
| S-TC TX (legacy id: S_TM_TX) | SAR RX (generic spurious) | SAR X (9387.5–9912.5 MHz) | −49.02 | −62.62 | −111.64 | −175.00 | 63.36 | 70 dB | 80 dB | ENGINEERING_ESTIMATE (SAR 52 dBi, ±80° 밖 −50 dB) |
| Ka DLS TX | GPS RX | L1 | −16.57 (EIRP) − 127.1 (cutoff) | −79.62 | −223.29 | −178.00 | 0 (margin +45.29) | 0 dB | 불필요 | ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED |
| Ka DLS TX | GPS RX | L2 | −16.57 − 127.4 | −55.64 | −199.62 | −178.00 | 0 (margin +21.62) | 0 dB | 불필요 | ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED |
| Ka DLS TX | GPS RX | L5 | −16.57 − 127.4 | −54.92 | −198.93 | −178.00 | 0 (margin +20.93) | 0 dB | 불필요 | ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED |
| Ka DLS TX | S-TM RX | S (2025–2110 MHz) | −16.57 − 126.4 | −55.43 | −198.49 | −177.00 | 0 (margin +21.49) | 0 dB | 불필요 | ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED |
| Ka DLS TX | ISL RX | X (10.55–10.65 GHz) | −16.57 − 83.4 | −70.42 | −170.42 | −177.00 | 6.58 | 40 dB | 20 dB | ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED |
| Ka DLS TX | SAR RX | SAR X | −16.57 − 90.6 | −59.24 | −166.92 | −175.00 | 8.08 | 40 dB | 20 dB | ENGINEERING_BOUND + SAR ENGINEERING_ESTIMATE |

**읽는 법:**
- **단위:** Source·Victim PSD·Limit은 dBm/Hz, Coupling·Required는 dB다. 각 행은 설치·KAA 조합 중 대표 worst다.
- **S-TC source:** 안테나 포트의 ITU conducted PSD다. Coupling은 G_TX + G_RX − FSPL이다.
- **Ka source:** 불요방사 EIRP PSD에서 도파관 below-cutoff 감쇠를 뺀 값이다(victim 대역 내 최소 감쇠). Coupling은 G_RX − FSPL이며 TX 이득을 다시 더하지 않았다. SAR coupling에는 SAR 이득 +2 dBi가 들어 있다.

**억제 조건:**
- **Required suppression:** 0 dB 추가 필터 기준 총 요구량 max(0, PSD − limit)이며 victim 대역 전체 최댓값이다.
- **First PASS:** 0/40/60/70/80 dB screening 중 처음 margin ≥ 0인 값이다.
- **Design target:** 요구량 + 10 dB reserve를 10 dB 단위로 올린 계획값이다. 요구량이 0이면 "불필요"다. 규격이 아니다.
- **Ka cutoff:** 도파관 감쇠(`WAVEGUIDE_BELOW_CUTOFF_BOUND`)는 필터 scenario와 별개 항이며, owner 가정 50 mm를 primary로 인정했다.

## 2. 분석 범위 (역할 matrix)

| Attacker | GPS | S-TM RX | ISL RX | SAR RX |
| --- | --- | --- | --- | --- |
| S-TC TX (legacy id: S_TM_TX) | 분석 (Task 1) | 분석 | 분석 | victim-only 분석 (고조파 판정 + 일반 spurious) |
| Ka DLS TX | cutoff route | cutoff route | cutoff route | cutoff route |
| ISL TX | 제외 | 제외 | 제외 | 제외 |
| SAR TX | 제외 | 제외 | 제외 | 제외 |

- 이전 판의 ISL TX attacker 결과와 KAA 저주파 최대 이득 상한(`GAIN_BOUND_ONLY`) 결과는 primary에서 뺐고, legacy/sensitivity로만 남긴다.
- 역할명 대응: S-TC TX = legacy `S_TM_TX`, S-TM RX = legacy `S_TC_RX`(대역 키 `S_TC`). 범위 SSOT: `data/rfi_psd/rfi_scope_matrix.csv`.

## 3. SAR victim 패턴과 S-TC → SAR

### 3.1 재구성 패턴과 owner 절대값

owner가 폐쇄망 `K8_SAR_Pattern.mat`에서 추출한 값만 저장했다(`OWNER_EXTRACTED_FROM_K8_SAR_PATTERN_MAT`, `ENGINEERING_RECONSTRUCTION`, `NOT_FULL_1601_POINT_EXPORT`).

| Cut | HPBW [deg] | First null | Max sidelobe | 60~80° hold | ±80° 밖 / 후방 |
| --- | --- | --- | --- | --- | --- |
| Azimuth | 0.242294 | ±0.3°, −39.083 dB | −13.565 dB @ ±0.4° | −40.708 dB | −50 dB (owner ceiling) |
| Elevation | 1.112221 (3-dB 점 ±0.556111°) | ±1.3°, −31.241 dB | −13.270 dB @ ±1.8° | −34.674 dB | −50 dB (owner ceiling) |

**재구성 규칙:**
- 주빔은 HPBW 지점에서 정확히 −3 dB가 되게 했고, 3 dB 지점 ~ first null 구간은 −3 dB로 유지했다(null로 내려가지 않음).
- 부엽은 인접 마디 중 높은 값을 썼다(upper envelope). 모든 owner 표본에서 envelope ≥ 표본임을 확인했다.
- 60~80°(owner 범위 내 표본 이후)는 ≥10° 표본의 최댓값으로 유지했다.
- ±80° 밖과 후방은 owner ceiling **peak 대비 −50 dB**(conservative envelope)를 쓴다.
- 방향 이득은 두 cut의 큰 값이다.

**SAR 절대 이득과 cross-pol:**
- **절대 peak gain 52 dBi:** owner의 HPBW 기반 공학 추정이다. 교차 확인으로 41253/(0.242294 × 1.112221)를 계산하면 효율 100 %에서 51.9 dBi다.
- **후방 절대 ceiling:** 52 − 50 = **+2 dBi**로 owner 값과 일치함을 확인했다.
- 248.7072는 복소 field 크기이며 이 계산에 쓰지 않았다.
- Cx는 Co peak 대비 −120 dB라 `CROSS_POL_NEGLIGIBLE_FOR_CURRENT_SCREENING`으로 기록했다.

### 3.2 고조파 판정 (harmonic)

S-TC TX 점유대역 2248.65–2251.35 MHz의 정수 고조파 1~10차는 SAR 대역 9387.5–9912.5 MHz와 **겹치지 않는다(`NO_HARMONIC_OVERLAP`)**. 4차는 8994.6–9005.4 MHz, 5차는 11243.2–11256.8 MHz다. S-band 할당 2200–2290 MHz 전체로 넓혀도 겹치지 않는다(4차 8800–9160, 5차 11000–11450 MHz). 고조파 기준 요구는 없다.

### 3.3 일반 spurious route (harmonic과 별개)

경로는 ITU spurious source(−49.02 dBm/Hz) → S 안테나 SAR 대역 RealizedGain(CST) → FSPL → SAR 방향 이득이다.

| TX 설치 | 거리 [m] | SAR 기준 off-axis | SAR 이득 [dBi] | Victim PSD [dBm/Hz] | 0/40/60/70/80 dB margin [dB] | Required [dB] | First PASS |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SBA_NADIR (LOS CLEAR) | 3.127 | 85.8° | +2 (−50 dB ceiling) | −111.64 | −63.36 / −23.36 / −3.36 / +6.64 / +16.64 | 63.36 | 70 dB |
| SBA_ZENITH (LOS BLOCKED) | 3.662 | 123.9° | +2 (−50 dB ceiling) | −112.18 | −62.82 / −22.82 / −2.82 / +7.18 / +17.18 | 62.82 | 70 dB |

- S 안테나 두 위치 모두 SAR boresight 기준 80° 밖이다. 그래서 결과는 owner ceiling(+2 dBi)이 정한다. design target은 80 dB다.
- 이전 판의 외곽 hold(−34.67 dB)보다 15.3 dB 낮은 ceiling이다.
- 60 dB scenario에서 2.8~3.4 dB 차이로 초과한다.

## 4. Ka DLS TX: 최대 EIRP + 도파관 below-cutoff route

### 4.1 Source와 도파관 입력

| 항목 | 입력값 | 성격 |
| --- | --- | --- |
| Ka TX power / reference gain | 70 W = 18.451 dBW / 31 dBi | owner baseline |
| 최대 EIRP | 49.451 dBW (79.451 dBm) | derived |
| 불요방사 EIRP PSD (비감쇠) | −16.57 dBm/Hz (ITU −60 dBc/4 kHz 적용) | derived, 규격 상대레벨 |
| Waveguide | WR-42 | owner assumption (데이터시트 "WR-42 (WR-34 optional)") |
| Broad wall a | 10.668 mm | geometry |
| TE10 cutoff | 14.051 GHz | derived (c/2a) |
| Effective below-cutoff length | 50 mm | conservative engineering assumption (owner) |

- **근거 유형:** `WAVEGUIDE_BELOW_CUTOFF_BOUND`; `ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED`.
- **가정 범위:** 이상적 균일 도파관만 가정했다. flange·천이·불연속 누설과 도파관 이후 발생원은 포함하지 않았다.
- **이득 가정:** 31 dBi를 victim 주파수에도 그대로 적용한 보수적 screening이다.

### 4.2 Victim band별 cutoff 감쇠 (WR-42, 50 mm)

감쇠상수는 α = 8.686·(2πf_c/c)·√(1−(f/f_c)²) [dB/m]다. 채널 중심 기준 값이다.

| Victim | f [GHz] | f/f_c | α [dB/mm] | 50 mm 감쇠 [dB] | 감쇠 후 EIRP PSD [dBm/Hz] | WR-34 50 mm 감쇠 [dB] (민감도) |
| --- | --- | --- | --- | --- | --- | --- |
| GPS L1 | 1.5754 | 0.112 | 2.542 | 127.1 | −143.66 | 157.3 |
| GPS L2 | 1.2276 | 0.087 | 2.548 | 127.4 | −143.97 | 157.6 |
| GPS L5 | 1.1765 | 0.084 | 2.549 | 127.4 | −144.01 | 157.6 |
| S-TM RX | 2.050 | 0.146 | 2.531 | 126.5 | −143.10 | 156.9 |
| ISL RX | 10.600 | 0.754 | 1.679 | 84.0 | −100.52 | 125.1 |
| SAR RX | 9.650 | 0.687 | 1.859 | 93.0 | −109.53 | 131.3 |

### 4.3 Victim PSD와 요구 억제량 (WR-42, 50 mm)

| Victim | Victim PSD [dBm/Hz] | Margin at 0 dB [dB] | Required [dB] | First PASS | 경로를 닫는 길이 [mm] |
| --- | --- | --- | --- | --- | --- |
| GPS L1 | −228.24 ~ −223.29 | +45.29 ~ +50.24 | 0 | 0 dB | 30.2 ~ 32.2 |
| GPS L2 | −206.71 ~ −199.62 | +21.62 ~ +28.71 | 0 | 0 dB | 38.7 ~ 41.5 |
| GPS L5 | −204.39 ~ −198.93 | +20.93 ~ +26.39 | 0 | 0 dB | 39.6 ~ 41.8 |
| S-TM RX | −203.07 ~ −198.49 | +21.49 ~ +26.07 | 0 | 0 dB | 39.7 ~ 41.5 |
| ISL RX | −171.45 ~ −170.42 | −5.55 ~ −6.58 | 5.55 ~ 6.58 | 40 dB | 53.3 ~ 53.9 |
| SAR RX | −167.17 ~ −166.92 | −7.83 ~ −8.08 | 7.83 ~ 8.08 | 40 dB | 54.3 ~ 54.5 |

- **범위:** 각 칸은 KAA_1/2 × victim 설치의 최소~최대다. 감쇠는 대역 내 최소값(대역 상단)을 적용했다.
- **ISL·SAR:** 50 mm는 닫는 길이(53~55 mm)보다 짧아 6~8 dB가 남는다.
- **WR-34 민감도:** 같은 50 mm라면 모든 Ka 경로가 통과한다(ISL margin +34.7 dB, SAR +31.0 dB). 도파관 형식이 결과를 크게 바꾼다.
- **근거리 주의:** KAA–ISL 거리(1.8~2.3 m)와 KAA–SAR 거리(2.9~3.0 m)는 X-band 반사판 원거리 거리(3.1~3.4 m)보다 짧아 자유공간 식이 엄밀하지 않다.
- **가림 미반영:** GPS 경로의 hull 가림은 감쇠로 인정하지 않았다.

### 4.4 이전 KAA `GAIN_BOUND_ONLY` 결과와 차이

| Victim | 이전 Tier 3 상한 route [dB] | 새 route, cutoff 0 mm [dB] | 새 route, WR-42 50 mm [dB] |
| --- | --- | --- | --- |
| GPS L1 | 59.0 ~ 63.9 | 76.8 ~ 81.8 | 0 |
| GPS L2 | 79.0 ~ 86.1 | 98.7 ~ 105.8 | 0 |
| GPS L5 | 81.1 ~ 86.6 | 101.1 ~ 106.5 | 0 |
| S-TM RX | 84.6 ~ 89.2 | 100.4 ~ 105.0 | 0 |
| ISL RX | 86.1 ~ 87.2 | 89.0 ~ 90.0 | 5.6 ~ 6.6 |
| SAR RX | 산출 불가 (SAR 응답 없음) | 98.5 ~ 98.7 (G_SAR +2 dBi) | 7.8 ~ 8.1 |

- **cutoff 0 mm에서 새 route가 높은 이유:** TX 이득이 31 dBi로 이전 상한(11~28 dBi)보다 크기 때문이다(+2.9~19.9 dB).
- **50 mm cutoff를 인정하면:** L/S 경로는 모두 닫히고 X-band만 6~8 dB가 남는다.
- **이전 결과의 지위:** legacy sensitivity로 유지한다([KAA_저주파_방사응답_결과보고서.md](KAA_저주파_방사응답_결과보고서.md)).

## 5. S-TC TX → ISL RX

S 안테나 ISL 대역 RealizedGain과 ISL 수신 RealizedGain(둘 다 CST 시뮬레이션 데이터)을 썼다(Task 1 계산).

| TX 설치 | Victim PSD [dBm/Hz] | Allowable [dBm/Hz] | Margin at 0 dB [dB] | Required [dB] | 0/40/60/70/80 dB margin [dB] | First PASS |
| --- | --- | --- | --- | --- | --- | --- |
| SBA_NADIR | −137.83 | −177.00 | −39.17 | 39.17 | −39.17 / +0.83 / +20.83 / +30.83 / +40.83 | 40 dB |
| SBA_ZENITH | −137.74 | −177.00 | −39.26 | 39.26 | −39.26 / +0.74 / +20.74 / +30.74 / +40.74 | 40 dB |

## 6. 입력 누락 및 분석 한계

- **owner 입력(가정·추정):** WR-42 형식, 유효 길이 50 mm, SAR peak 52 dBi, ±80° 밖 −50 dB. 실측이나 full-wave 검증이 들어오면 교체한다.
- **ISL·SAR 판정의 민감도:** Ka의 ISL·SAR 판정은 도파관 길이에 민감하다. 4~5 mm만 길어도 경로가 닫힌다(ISL 53.9 mm, SAR 54.5 mm).
- **그 밖의 필요 입력:** L2/L5 S11(Task 1 rescaling 확정), 동일 포트 isolation, 실제 BPF table.
- **한계:** 자유공간 직접 결합이며 산란·가림은 미모델이다. X-band Ka 근거리 조건은 4.3절 참조.

## Appendix. 파일과 출처

| 파일 | 내용 |
| --- | --- |
| `data/rfi_psd/rfi_scope_matrix.csv` | primary 범위 SSOT |
| `data/Xband_SAR_K8_owner/owner_cut_values.csv`, `owner_absolute_inputs.csv`, `sar_envelope_0p1deg.csv` | owner 추출 값 / owner 절대값(52 dBi, −50 dB, +2 dBi) / 0.1° envelope |
| `data/rfi_psd/ka_waveguide_cutoff.csv` | WR-42 50 mm owner 가정, WR-34 민감도 |
| `output/claude/results/task2_*.csv` | SAR 요약, 고조파, S-TC→SAR, Ka cutoff 표·pair |
| `output/claude/run_task2_scope_analysis.m`, `src/+rfscreen/+psd/{WaveguideCutoff,SarOwnerPattern}.m` | 실행 / 모델 |

재현: `run_stc_lband_rescaling.m` 다음에 `octave-cli --no-gui --norc --eval "run('output/claude/run_task2_scope_analysis.m')"`. 추가 CST 실행은 없다. 수치는 Claude worker의 독립 계산이며 양식만 `output/codex/결과보고서.md`를 따랐다.
