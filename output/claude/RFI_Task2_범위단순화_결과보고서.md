# RFI 설계 보고서 — Task 2: 범위 단순화, SAR/ISL victim-only, Ka 도파관 cutoff route

## 1. Executive Summary

**Primary 범위는 S-TC TX와 Ka DLS TX 두 attacker로 줄었다.** ISL과 SAR는 victim으로만 다룬다.
- **S-TC TX:** 추가 억제 요구는 GPS L2/L5 70.45/70.87 dB(80 dB scenario)가 최대이고, 이어서 S-TM RX 58.89 dB, GPS L1 48.00 dB, ISL RX 39.26 dB다.
- **Ka DLS TX:** 최대 EIRP 49.451 dBW에 ITU −60 dBc/4 kHz를 적용하면, 도파관 cutoff를 인정하지 않은 상태에서 76.8~106.5 dB가 필요하다.
- **Ka 도파관 판단:** 데이터시트 기준인 WR-42의 below-cutoff 구간이 약 30~54 mm면 모든 Ka 경로가 닫힌다. 그러나 **유효 길이가 저장소에 확정되어 있지 않아 primary에서는 0 mm를 인정**했다. 따라서 Ka 수치는 최종 필터 요구가 아니라 "확인해야 할 도파관 길이"로 읽어야 한다.
- **SAR:** S-TC 고조파는 SAR 대역과 겹치지 않는다(`NO_HARMONIC_OVERLAP`). 일반 spurious route는 SAR 절대 peak gain이 미확정이라 G_peak를 포함한 식으로 제시한다.
- 추가 CST 시뮬레이션은 하지 않았다. SAR 패턴은 owner 제공 값으로 재구성했다.

| Attacker | Victim | Band | Source PSD/EIRP | Coupling | Victim PSD | Limit | Required suppression | First PASS | Design target | Confidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S-TC TX (legacy id: S_TM_TX) | GPS RX | L1 | −49.02 | −80.98 | −130.00 | −178.00 | 48.00 | 60 dB | 60 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | GPS RX | L2 | −59.02 (−10 dB rescaling) | −48.53 | −107.55 | −178.00 | 70.45 | 80 dB | 90 dB | ENGINEERING_BOUND (port mismatch) |
| S-TC TX (legacy id: S_TM_TX) | GPS RX | L5 | −59.02 (−10 dB rescaling) | −48.11 | −107.13 | −178.00 | 70.87 | 80 dB | 90 dB | ENGINEERING_BOUND (port mismatch) |
| S-TC TX (legacy id: S_TM_TX) | S-TM RX | S (2025–2110 MHz) | −49.02 | −69.09 | −118.11 | −177.00 | 58.89 | 60 dB | 70 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | ISL RX | X (10.55–10.65 GHz) | −49.02 | −88.72 | −137.74 | −177.00 | 39.26 | 40 dB | 50 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | SAR RX (harmonic) | SAR X | — | — | — | — | 해당 없음 | — | — | NO_HARMONIC_OVERLAP |
| S-TC TX (legacy id: S_TM_TX) | SAR RX (generic spurious) | SAR X (9387.5–9912.5 MHz) | −49.02 | −99.29 + G_peak | −148.31 + G_peak | −175.00 | 26.69 + G_peak | G_peak 의존 | G_peak 의존 | SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN |
| Ka DLS TX | GPS RX | L1 | −16.57 (EIRP) | −79.62 | −96.19 | −178.00 | 81.81 | 없음 (80 dB 초과) | 도파관 길이 확인 | ENGINEERING_BOUND; cutoff 0 mm 인정 |
| Ka DLS TX | GPS RX | L2 | −16.57 (EIRP) | −55.64 | −72.21 | −178.00 | 105.79 | 없음 (80 dB 초과) | 도파관 길이 확인 | ENGINEERING_BOUND; cutoff 0 mm 인정 |
| Ka DLS TX | GPS RX | L5 | −16.57 (EIRP) | −54.92 | −71.49 | −178.00 | 106.51 | 없음 (80 dB 초과) | 도파관 길이 확인 | ENGINEERING_BOUND; cutoff 0 mm 인정 |
| Ka DLS TX | S-TM RX | S (2025–2110 MHz) | −16.57 (EIRP) | −55.43 | −72.00 | −177.00 | 105.00 | 없음 (80 dB 초과) | 도파관 길이 확인 | ENGINEERING_BOUND; cutoff 0 mm 인정 |
| Ka DLS TX | ISL RX | X (10.55–10.65 GHz) | −16.57 (EIRP) | −70.42 | −86.99 | −177.00 | 90.01 | 없음 (80 dB 초과) | 도파관 길이 확인 | ENGINEERING_BOUND; cutoff 0 mm 인정 |
| Ka DLS TX | SAR RX | SAR X | −16.57 (EIRP) | −95.91 + G_peak | −112.48 + G_peak | −175.00 | 62.52 + G_peak | G_peak 의존 | G_peak 의존 | SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN |

단위: Source·Victim PSD·Limit은 dBm/Hz, Coupling·Required는 dB다. 각 행은 해당 victim의 설치·KAA 조합 중 대표 worst다.
- **S-TC source:** 안테나 포트의 ITU conducted PSD다. Coupling은 G_TX + G_RX − FSPL이다.
- **Ka source:** 최대 EIRP 기준 불요방사 EIRP PSD다. Coupling은 G_RX − FSPL이며 TX 이득을 다시 더하지 않았다.
- G_peak는 SAR 절대 peak gain [dBi]이고 미확정이다.

**억제 조건:**
- **Required suppression:** 0 dB 추가 필터 기준 총 요구량 max(0, PSD − limit)이고, victim 대역 전체 최댓값이다.
- **First PASS:** 0/40/60/70/80 dB screening 중 처음 margin ≥ 0이 되는 값이다.
- **Design target:** 요구량에 10 dB reserve를 더해 10 dB 단위로 올린 계획값이며 규격이 아니다.
- **Ka cutoff:** 도파관 below-cutoff 감쇠는 필터 scenario와 별개 항(`WAVEGUIDE_BELOW_CUTOFF_BOUND`)이다. Ka 행에서는 0 dB로 두었고(유효 길이 미확정) 4절에서 길이별로 제시한다.

## 2. 분석 범위 (역할 matrix)

| Attacker | GPS | S-TM RX | ISL RX | SAR RX |
| --- | --- | --- | --- | --- |
| S-TC TX (legacy id: S_TM_TX) | 분석 (Task 1) | 분석 | 분석 | victim-only 분석 (고조파 판정 + 일반 spurious) |
| Ka DLS TX | cutoff route | cutoff route | cutoff route | cutoff route (G_peak 미확정) |
| ISL TX | 제외 | 제외 | 제외 | 제외 |
| SAR TX | 제외 | 제외 | 제외 | 제외 |

- 이전 판의 ISL TX attacker 결과와 KAA 저주파 최대 이득 상한(`GAIN_BOUND_ONLY`) 결과는 primary에서 뺐다. 추적성을 위해 legacy/sensitivity로만 남긴다.
- 역할명은 실제 역할로 쓴다. S-TC TX = legacy `S_TM_TX`, S-TM RX = legacy `S_TC_RX`(대역 키 `S_TC`). 범위 SSOT: `data/rfi_psd/rfi_scope_matrix.csv`.

## 3. SAR victim 패턴과 S-TC → SAR

### 3.1 재구성 패턴 요약

owner가 폐쇄망 `K8_SAR_Pattern.mat`에서 추출한 값만 저장했다(`OWNER_EXTRACTED_FROM_K8_SAR_PATTERN_MAT`, `ENGINEERING_RECONSTRUCTION`, `NOT_FULL_1601_POINT_EXPORT`). 1601점 원본은 반출하지 않았다.

| Cut | HPBW [deg] | First null | Max sidelobe | 표본 이후 외곽 hold |
| --- | --- | --- | --- | --- |
| Azimuth | 0.242294 | ±0.3°, −39.083 dB | −13.565 dB @ ±0.4° | −40.708 dB |
| Elevation | 1.112221 (owner 값, 3-dB 점 ±0.556111°) | ±1.3°, −31.241 dB | −13.270 dB @ ±1.8° | −34.674 dB |

- **주빔:** 0 ~ 3 dB 지점은 −3(θ/θ₃)² dB로 두어 HPBW 지점에서 정확히 −3 dB가 되게 했다. 3 dB 지점 ~ first null 구간은 −3 dB로 유지했다. null로 내려가지 않게 한 보수 처리다.
- **부엽 구간:** null 이후는 max sidelobe와 owner 표본을 마디로 삼았다. 인접 마디 사이에서는 **높은 값**을 썼다(upper envelope). 모든 owner 표본 지점에서 envelope − 표본 ≥ 0 dB를 확인했다.
- **60° 이후·후방(가정):** owner 데이터는 ±80°까지만 있다. 60° 이후와 후방은 ≥10° 표본의 최댓값으로 유지했다. 방향 이득은 두 cut 중 큰 값(회전 envelope)을 써서 az/el 축 배정과 무관하다.
- **Cross-pol:** Cx는 Co peak 대비 −120 dB(XPD 120 dB)라 `CROSS_POL_NEGLIGIBLE_FOR_CURRENT_SCREENING`으로 기록하고 Co-pol을 primary로 썼다. Cx를 자기 peak로 재정규화하지 않았다.
- **절대 이득:** 248.7072는 복소 field 크기라 dBi가 아니다. 저장소에 확정된 SAR peak gain이 없다. 기존 X-band SAR 사양은 8 GHz 예시 surrogate라 해당하지 않는다. 따라서 `SAR_ABSOLUTE_PEAK_GAIN_UNKNOWN`이고, 0 dBi를 쓰지 않았다.

### 3.2 고조파 판정 (harmonic)

S-TC TX 점유대역 2248.65–2251.35 MHz의 정수 고조파 1~10차를 SAR 대역 9387.5–9912.5 MHz와 비교했다. 4차는 8994.6–9005.4 MHz, 5차는 11243.2–11256.8 MHz로 **겹침이 없다(`NO_HARMONIC_OVERLAP`)**. S-band 할당 2200–2290 MHz 전체로 넓혀도 겹치지 않는다(4차 8800–9160 MHz, 5차 11000–11450 MHz). 고조파 기준의 S-TC → SAR 요구는 없다.

### 3.3 일반 spurious route (harmonic과 별개)

경로는 ITU spurious source(−49.02 dBm/Hz) → S 안테나 SAR 대역 RealizedGain(CST) → FSPL → SAR 방향 이득(정규화 패턴 + G_peak)이다.

| TX 설치 | 거리 [m] | SAR 기준 off-axis | 정규화 이득 [dB] | G_peak 제외 victim PSD [dBm/Hz] | Required [dB] |
| --- | --- | --- | --- | --- | --- |
| SBA_NADIR | 3.127 | 85.8° (owner 범위 밖, 외곽 hold) | −34.67 | −148.31 | 26.69 + G_peak |
| SBA_ZENITH | 3.662 | 123.9° (후방, 외곽 hold) | −34.67 | −148.85 | 26.15 + G_peak |

- **G_peak에 따른 통과 조건:** 추가 필터 F에서 통과하려면 G_peak ≤ F − 26.69 dBi여야 한다. 0/40/60/70/80 dB에서 각각 −26.69/13.31/33.31/43.31/53.31 dBi 이하다.
- **판정 보류:** G_peak가 확정되면 최종 판정한다. 두 방향 모두 owner 패턴 범위(±80°)를 벗어나 외곽 hold 가정에 의존한다.

## 4. Ka DLS TX: 최대 EIRP + 도파관 below-cutoff route

### 4.1 Source와 도파관 입력

- **EIRP:** 70 W = 18.451 dBW에 high-gain 기준 31 dBi를 더해 **최대 EIRP 49.451 dBW**(79.451 dBm)다. 불요방사는 기존과 같은 ITU RR AP3 / SM.329 −60 dBc/4 kHz를 이 EIRP에 적용해 **비감쇠 EIRP PSD −16.57 dBm/Hz**다. 31 dBi를 victim 주파수에도 그대로 쓰므로 보수적 screening 값이다.
- **도파관 형식:** 저장소 근거는 벤더 데이터시트(`cst/specs/kaband_dls.yaml`, confidence A)의 "rf_interface: WR-42 (WR-34 optional)"이다. 비행 선택은 확정되지 않았다. WR-42는 데이터시트 기준이면서 cutoff가 낮아 감쇠가 작은 **보수적 선택**이라 primary로 썼고, WR-34는 민감도로 제시한다. CST feed surrogate(원형 r = 4.4 mm)는 하드웨어가 아니라 쓰지 않았다.
- **유효 below-cutoff 길이:** 저장소에 확정값이 없다(**INPUT_MISSING**). 그래서 primary는 0 mm를 인정했다. 5/10/20 mm는 예시 민감도다. 데이터시트 전체 높이 < 92.2 mm는 도파관 길이가 아니다.
- **근거 유형:** `WAVEGUIDE_BELOW_CUTOFF_BOUND`; `ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED`. 이상적 균일 도파관만 가정했고 flange·천이·불연속 누설과 도파관 이후 발생원은 포함하지 않았다. 필터 감쇠로 부르지 않는다.

### 4.2 Victim band별 cutoff 감쇠

TE10 cutoff는 f_c = c/2a, 감쇠상수는 α = 8.686·(2πf_c/c)·√(1−(f/f_c)²) [dB/m]다. victim 채널 중심 기준 값이다.

| Victim | f [GHz] | WR-42: a / f_c / f/f_c | WR-42 α [dB/mm] | WR-42 감쇠 5/10/20 mm [dB] | WR-34 α [dB/mm] (f_c 17.357 GHz) |
| --- | --- | --- | --- | --- | --- |
| GPS L1 | 1.5754 | 10.668 mm / 14.051 GHz / 0.112 | 2.542 | 12.7 / 25.4 / 50.8 | 3.147 |
| GPS L2 | 1.2276 | 〃 / 0.087 | 2.548 | 12.7 / 25.5 / 51.0 | 3.152 |
| GPS L5 | 1.1765 | 〃 / 0.084 | 2.549 | 12.7 / 25.5 / 51.0 | 3.153 |
| S-TM RX | 2.050 | 〃 / 0.146 | 2.531 | 12.7 / 25.3 / 50.6 | 3.138 |
| ISL RX | 10.600 | 〃 / 0.754 | 1.679 | 8.4 / 16.8 / 33.6 | 2.502 |
| SAR RX | 9.650 | 〃 / 0.687 | 1.859 | 9.3 / 18.6 / 37.2 | 2.626 |

모든 victim이 cutoff 아래다. 저주파(L/S)는 mm당 약 2.5 dB로 거의 일정하다. ISL/SAR는 cutoff에 가까워 감쇠가 작다(ISL 1.68 dB/mm).

### 4.3 Victim PSD와 요구 억제량 (WR-42)

| Victim | Victim PSD, cutoff 0 mm [dBm/Hz] | Required, 0 mm [dB] | Required, 20 mm 민감도 [dB] | 경로를 닫는 below-cutoff 길이 [mm] (WR-34) |
| --- | --- | --- | --- | --- |
| GPS L1 | −101.17 ~ −96.19 | 76.83 ~ 81.81 | 26.0 ~ 31.0 | 30.2 ~ 32.2 (24.4 ~ 26.0) |
| GPS L2 | −79.29 ~ −72.21 | 98.71 ~ 105.79 | 47.7 ~ 54.8 | 38.7 ~ 41.5 (31.3 ~ 33.6) |
| GPS L5 | −76.94 ~ −71.49 | 101.06 ~ 106.51 | 50.1 ~ 55.5 | 39.6 ~ 41.8 (32.1 ~ 33.8) |
| S-TM RX | −76.63 ~ −72.00 | 100.37 ~ 105.00 | 49.8 ~ 54.4 | 39.7 ~ 41.5 (32.0 ~ 33.5) |
| ISL RX | −88.02 ~ −86.99 | 88.98 ~ 90.01 | 55.6 ~ 56.6 | 53.3 ~ 53.9 (35.7 ~ 36.1) |
| SAR RX | −112.73 ~ −112.48 (+ G_peak) | 62.52 + G_peak (최대) | — | G_peak 확정 후 |

- **범위:** 각 칸은 KAA_1/2 × 해당 victim 설치의 최소~최대다.
- **도파관 길이가 결정 변수다.** 확정 길이가 표의 "닫는 길이" 이상이면 해당 경로의 추가 억제는 불필요하다. 짧으면 부족분을 필터가 맡는다. WR-42 기준으로 ISL이 가장 긴 54 mm를 요구한다. ISL은 cutoff에 가까워 감쇠상수가 작기 때문이다.
- **근거리 주의:** X-band에서 KAA–ISL 거리(1.8~2.3 m)는 반사판 원거리 거리(약 3.4 m)보다 짧아 자유공간 식이 엄밀하지 않다.
- **가림 미반영:** GPS 경로는 hull 가림 상태이지만 가림 감쇠는 인정하지 않았다.

### 4.4 이전 KAA `GAIN_BOUND_ONLY` 결과와 차이

| Victim | 이전 Tier 3 상한 route [dB] | 새 route, cutoff 0 mm [dB] | 차이 [dB] | 새 route, WR-42 20 mm [dB] |
| --- | --- | --- | --- | --- |
| GPS L1 | 59.0 ~ 63.9 | 76.8 ~ 81.8 | +17.9 | 26.0 ~ 31.0 |
| GPS L2 | 79.0 ~ 86.1 | 98.7 ~ 105.8 | +19.6 | 47.7 ~ 54.8 |
| GPS L5 | 81.1 ~ 86.6 | 101.1 ~ 106.5 | +19.9 | 50.1 ~ 55.5 |
| S-TM RX | 84.6 ~ 89.2 | 100.4 ~ 105.0 | +15.8 | 49.8 ~ 54.4 |
| ISL RX | 86.1 ~ 87.2 | 89.0 ~ 90.0 | +2.9 | 55.6 ~ 56.6 |

- **차이의 원인:** 새 route는 TX 이득으로 31 dBi를 쓰는데, 이전 상한은 안테나 크기 기반 11~28 dBi였다. 차이는 정확히 31 dBi − 이전 상한이다.
- **도파관 감쇠의 효과:** 새 route는 cutoff 감쇠를 별도 항으로 넣는다. 20 mm만 인정해도 이전 결과보다 약 30~35 dB 낮아진다.
- **이전 결과의 지위:** legacy sensitivity로 유지한다([KAA_저주파_방사응답_결과보고서.md](KAA_저주파_방사응답_결과보고서.md)).

## 5. S-TC TX → ISL RX

S 안테나 ISL 대역 RealizedGain과 ISL 수신 RealizedGain(둘 다 CST 시뮬레이션 데이터)을 썼다. Task 1 계산을 그대로 사용했다.

| TX 설치 | Victim PSD [dBm/Hz] | Allowable [dBm/Hz] | Margin at 0 dB [dB] | Required [dB] | 0/40/60/70/80 dB margin [dB] | First PASS |
| --- | --- | --- | --- | --- | --- | --- |
| SBA_NADIR | −137.83 | −177.00 | −39.17 | 39.17 | −39.17 / +0.83 / +20.83 / +30.83 / +40.83 | 40 dB |
| SBA_ZENITH | −137.74 | −177.00 | −39.26 | 39.26 | −39.26 / +0.74 / +20.74 / +30.74 / +40.74 | 40 dB |

40 dB 통과 여유는 0.7~0.8 dB로 얇다. design target은 50 dB다.

## 6. 입력 누락 및 분석 한계

- **필요 입력:**
  - Ka 도파관 형식(WR-42/WR-34) 확정과 **유효 below-cutoff 길이**
  - SAR 절대 peak gain [dBi]
  - SAR 후방·±80° 밖 패턴(현재 외곽 hold 가정)
  - L2/L5 S11(Task 1 rescaling 확정)
  - 동일 포트 isolation
  - 실제 BPF table
- **한계:**
  - cutoff 감쇠는 full-wave 검증이 아니다.
  - Ka 31 dBi를 victim 주파수에 그대로 적용한 것은 보수적 가정이다.
  - 자유공간 직접 결합이며 산란·가림은 미모델이다. X-band Ka 근거리 조건은 4.3절 참조.

## Appendix. 파일과 출처

| 파일 | 내용 |
| --- | --- |
| `data/rfi_psd/rfi_scope_matrix.csv` | primary 범위 SSOT |
| `data/Xband_SAR_K8_owner/owner_cut_values.csv`, `sar_envelope_0p1deg.csv` | owner 추출 값 / 0.1° envelope |
| `data/rfi_psd/ka_waveguide_cutoff.csv` | WR-42/WR-34 입력, 길이 INPUT_MISSING |
| `output/claude/results/task2_*.csv` | SAR 요약, 고조파, S-TC→SAR, Ka cutoff 표·pair |
| `output/claude/run_task2_scope_analysis.m`, `src/+rfscreen/+psd/{WaveguideCutoff,SarOwnerPattern}.m` | 실행 / 모델 |

재현: `run_stc_lband_rescaling.m` 다음에 `octave-cli --no-gui --norc --eval "run('output/claude/run_task2_scope_analysis.m')"`. 추가 CST 실행은 없다. 수치는 Claude worker의 독립 계산이며 양식만 `output/codex/결과보고서.md`를 따랐다.
