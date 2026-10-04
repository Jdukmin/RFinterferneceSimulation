# RFI 설계 보고서 — S-TC TX 추가 억제 요구 (GPS L2/L5 port-mismatch rescaling 포함)

## 1. Executive Summary

**S-TC TX(legacy id: S_TM_TX) → GPS L2/L5는 각각 최소 70.45 / 70.87 dB의 추가 억제가 필요하고, 첫 통과 screening은 80 dB다.** GPS L1은 48.00 dB(60 dB), S-TM RX는 58.89 dB(60 dB), ISL RX는 39.26 dB(40 dB)다. 따라서 S-TC TX의 확보 경로 중 최대 요구는 GPS L2/L5이며, 80 dB 필터 scenario에서야 모든 GPS 경로를 통과한다.

L2/L5는 이제 UNKNOWN이 아니다. CST RealizedGain의 accepted-power 정규화를 신뢰할 수 없어서 L1 기준 port mismatch 10 dB를 적용한 **engineering-bound 정량값**이다(`PORT_MISMATCH_RESCALED_LBAND`). L1/S-TM/ISL은 CST 시뮬레이션 데이터 경로를 그대로 쓴다. SAR RX와 동일 포트 경로는 미판정이다.

| Attacker | Victim | Band | ITU source PSD | Port mismatch rescaling | Effective TX L-band source | Coupling | Victim PSD | Limit | Required suppression | First PASS | Design target | Confidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S-TC TX (legacy id: S_TM_TX) @ SBA_ZENITH | GPS RX @ GPSA_1 | L1 | −49.02 | 0 (CST RealizedGain에 포함) | −49.02 | −80.98 | −130.00 | −178.00 | 48.00 | 60 dB | 60 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) @ SBA_ZENITH | GPS RX @ GPSA_1 | L2 | −49.02 | −10 | −59.02 | −48.53 | −107.55 | −178.00 | 70.45 | 80 dB | 90 dB | ENGINEERING_BOUND — L1-referenced 10 dB port-mismatch rescaling |
| S-TC TX (legacy id: S_TM_TX) @ SBA_ZENITH | GPS RX @ GPSA_1 | L5 | −49.02 | −10 | −59.02 | −48.11 | −107.13 | −178.00 | 70.87 | 80 dB | 90 dB | ENGINEERING_BOUND — L1-referenced 10 dB port-mismatch rescaling |
| S-TC TX (legacy id: S_TM_TX) @ SBA_NADIR/ZENITH | S-TM RX (legacy id: S_TC_RX), 반대편 SBA | S (2025–2110 MHz) | −49.02 | 0 | −49.02 | −69.09 | −118.11 | −177.00 | 58.89 | 60 dB | 70 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) @ SBA_ZENITH | ISL RX | X (10.55–10.65 GHz) | −49.02 | 0 | −49.02 | −88.72 | −137.74 | −177.00 | 39.26 | 40 dB | 50 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | SAR RX | SAR X | −49.02 | 0 | −49.02 | 미판정 | 미판정 | −175.00 | 미판정 | 미판정 | 미판정 | SAR 응답 없음 |

단위: source·victim PSD·limit은 dBm/Hz, rescaling·coupling·required·scenario는 dB다. Source는 안테나 포트의 ITU **conducted** PSD다. L2/L5의 coupling에는 rescaling을 넣지 않았고(이득 envelope + G_RX − FSPL), rescaling은 effective source에 한 번만 반영했다. 각 행은 해당 victim의 두 설치(SBA_NADIR/ZENITH) × GPSA_1/2 중 대표 worst다. 표 전체가 0 dB 추가 필터 기준 **총** 요구량이다.

**억제 조건:**
- **Required suppression:** 0 dB 추가 필터에서 `max(0, PSD_victim − PSD_allowable)`를 victim 대역 전체에서 본 최댓값이다. 필터를 넣은 뒤 남은 요구량과는 다르다.
- **First PASS:** 0/40/60/70/80 dB screening scenario 중에서 대역 전체 margin ≥ 0이 되는 가장 작은 값이다. 실제 필터 설계값이 아니다.
- **Design target:** 최소 요구량에 10 dB engineering reserve를 더하고 10 dB 단위로 올린 계획값이다. 규격이나 필터 보증값이 아니다.
- **적용하지 않은 감쇠:** 수신기 criterion은 GPS −178, S-TM/ISL −177, SAR −175 dBm/Hz다(kT₀ + NF + I/N, 공학 가정). 도파관·케이블·실제 BPF 감쇠는 0 dB로 두었다.

**owner baseline과의 차이:** owner는 rescaling 이후 source를 약 **−58 dBm/Hz**로 지정했다. 실제 산술값은 −49.02 − 10 = **−59.02 dBm/Hz**로 1.02 dB 낮다(덜 보수적). −58 dBm/Hz를 쓰면 L2/L5 요구량은 각각 71.47 / 71.89 dB로 1.02 dB 오르지만 first PASS 80 dB와 design target 90 dB는 바뀌지 않는다.

## 2. S-TC TX → GPS L-band 최우선 결과

| 경로 (worst 설치) | TX route | TX gain toward victim (dBi) | Victim PSD (dBm/Hz) | Margin at 0 dB (dB) | Required (dB) | First PASS | 근거 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S-TC TX @ ZENITH → GPS L1 @ GPSA_1 | CST RealizedGain | −11.31 (realized) | −130.00 | −48.00 | 48.00 | 60 dB | 시뮬레이션 |
| S-TC TX @ ZENITH → GPS L2 @ GPSA_1 | PORT_MISMATCH_RESCALED_LBAND | −1.71 (accepted-power envelope) → −11.71 (rescaled) | −107.55 | −70.45 | 70.45 | 80 dB | ENGINEERING_BOUND |
| S-TC TX @ ZENITH → GPS L5 @ GPSA_1 | PORT_MISMATCH_RESCALED_LBAND | −1.71 → −11.71 | −107.13 | −70.87 | 70.87 | 80 dB | ENGINEERING_BOUND |

- **일관성 확인:** L2/L5 유효 TX 이득(−11.71 dBi)은 같은 방향 L1 CST RealizedGain(−11.31 dBi)과 0.4 dB 차이다. 10 dB rescaling이 L1에서 확인된 mismatch 수준과 일관된다.
- **L2/L5 victim PSD가 L1보다 22~23 dB 높은 이유:** TX 쪽 차이(−0.4 dB)는 작다. 주된 원인은 victim GPS 안테나의 S-TC TX 방향 수신 이득이다. 이 이득이 L1 −27.94 dBi에서 L2 −7.50, L5 −7.29 dBi로 약 20 dB 높다(GPS 수신 RealizedGain, CST 시뮬레이션 데이터, 정상 사용). 나머지 약 2 dB는 낮은 주파수의 FSPL 감소다.
- **SBA_NADIR 설치:** L2/L5 요구량은 47.28~50.71 dB(60 dB)로 작다. 설치 위치가 결과를 20 dB 이상 바꾼다.

## 3. Source·기준면·required suppression 정의

- **ITU source(규격):** ITU RR Appendix 3 / ITU-R SM.329-13 우주국 spurious 한계를 쓴다. `A = min(43 + 10log₁₀P[W], 60)`, `Source = P[dBm] − A − 10log₁₀(4000)`. S-TC TX 5 W(36.99 dBm)이면 A = 49.99 dB이고 source는 **−49.0206 dBm/Hz**(안테나 포트, 4 kHz 기준 −13.0 dBm/4 kHz)다. 4 kHz와 조항은 저장소 기존 ITU 관례이며 이번에 원문과 대조하지 않았다. 대역 내 평탄한 broadband 등가값이며 discrete spur를 PSD로 바꾸지 않았다.
- **계산식:** `PSD_victim(F) = Source + R_mismatch + G_TX(f_v) + G_RX(f_v) − FSPL(f_v) − F`. `margin(F) = PSD_allowable − PSD_victim(F)`. `required_additional_suppression_db = max(0, −margin(0))`.
- **이득 기준:** L1/S/ISL은 G_TX가 CST RealizedGain이며 mismatch가 이미 포함되어 R_mismatch = 0이다. L2/L5는 G_TX가 accepted-power Gain(mismatch 제외)이고 R_mismatch = −10 dB다. mismatch를 두 번 적용하지 않는다.

## 4. L2/L5 port-mismatch rescaling과 confidence

- **문제(시뮬레이션 데이터):** S 안테나의 L2/L5 RealizedGain은 accepted-power fraction이 L2 0.0090~0.0161, L5 −0.0045~0.00003이다. 정규화를 신뢰할 수 없다(L1은 0.0957~0.1097). 기존 값(L2 중심 −11.48 dBi, 최대 −11.30 dBi / L5 중심 −12.46 dBi, 최대 −12.20 dBi)은 **삭제하지 않고** `CST_VALUE_PRESENT_BUT_NORMALIZATION_UNRELIABLE`로 유지했다. primary에는 쓰지 않았다.
- **대체 경로(가정):** TX 방사 모델은 정규화가 신뢰 가능한 S 안테나 accepted-power Gain cut의 방향별 최댓값 envelope다. L1 1.563/1.57542/1.588 GHz와 L2 1.2276 GHz를 썼고, peak는 5.98 dBi다. L5에는 Gain cut이 없어 같은 L1/L2 envelope를 쓴다. 여기에 rescaling −10 dB를 더한다.
- **rescaling 근거:** −10 dB는 **OWNER_ENGINEERING_BOUND**다. L1 accepted-power fraction 10log₁₀(0.0957) = −10.19 dB(최악)를 참조한 owner 결정이며, CST 측정값이나 ITU 규격값이 아니다. 실제 L2/L5 port 정합이 L1보다 나쁘면(감쇠가 크면) 실제 요구량은 더 작고, 좋으면 더 크다.
- **confidence:** `ENGINEERING_BOUND — L1-referenced 10 dB port-mismatch rescaling`. 확정에는 L2/L5 S11 또는 port-matched 재해석(정규화 신뢰 가능한 RealizedGain)이 필요하다.

## 5. TX별 filter design summary

| TX | Worst victim | Required suppression | First passing scenario | Recommended design target |
| --- | --- | --- | --- | --- |
| S-TC TX (legacy id: S_TM_TX) / ENGINEERING_BOUND | GPS L5 RX @ GPSA_1 (TX @ SBA_ZENITH) | 70.87 dB | 80 dB | 90 dB |
| S-TC TX (legacy id: S_TM_TX) / 시뮬레이션 | S-TM RX @ 반대편 SBA / S (2025–2110 MHz) | 58.89 dB | 60 dB | 70 dB |

| S-TC TX victim | Minimum suppression | First PASS | Design target | Confidence |
| --- | --- | --- | --- | --- |
| GPS L1 RX | 48.00 dB | 60 dB | 60 dB | 시뮬레이션 |
| GPS L2 RX | 70.45 dB | 80 dB | 90 dB | ENGINEERING_BOUND |
| GPS L5 RX | 70.87 dB | 80 dB | 90 dB | ENGINEERING_BOUND |
| S-TM RX | 58.89 dB | 60 dB | 70 dB | 시뮬레이션 |
| ISL RX | 39.26 dB | 40 dB | 50 dB | 시뮬레이션 |
| SAR RX | 미판정 | 미판정 | 미판정 | SAR 응답 없음 |

S-TC TX 전체 요구는 확보 경로 기준 70.87 dB(80 dB scenario)다. 동일 포트(diplexer/T-R isolation)와 SAR 경로가 미확정이라 TX 전체의 최종 요구는 아직 보류다.

## 6. 0/40/60/70/80 dB scenario

worst 설치 기준 victim별 최소 margin [dB]이다. 양수는 통과, 음수는 초과다.

| Victim (worst 설치) | 0 dB | 40 dB | 60 dB | 70 dB | 80 dB |
| --- | --- | --- | --- | --- | --- |
| GPS L1 (ZENITH → GPSA_1) | −48.00 | −8.00 | +12.00 | +22.00 | +32.00 |
| GPS L2 (ZENITH → GPSA_1) | −70.45 | −30.45 | −10.45 | −0.45 | +9.55 |
| GPS L5 (ZENITH → GPSA_1) | −70.87 | −30.87 | −10.87 | −0.87 | +9.13 |
| S-TM RX (반대편 SBA) | −58.89 | −18.89 | +1.11 | +11.11 | +21.11 |
| ISL RX (ZENITH) | −39.26 | +0.74 | +20.74 | +30.74 | +40.74 |

- 추가 필터 F는 margin을 정확히 F dB 올린다.
- GPS L2/L5는 70 dB에서 0.45/0.87 dB 차이로 초과한다. owner baseline −58 dBm/Hz에서는 이 차이가 1.47/1.89 dB로 벌어진다. 따라서 70 dB class로 내릴 근거는 없다.
- S-TM RX의 60 dB 통과 여유는 1.11 dB, ISL RX의 40 dB 통과 여유는 0.74 dB로 얇다.

## 7. 입력 누락 및 분석 한계

- **필요 입력:**
  - L2/L5 S11 또는 정합 재해석(rescaling 확정)
  - SAR 안테나 응답
  - 동일 포트 diplexer/T-R isolation
  - 실제 TX BPF 감쇠 table
  - ITU RBW 원문 대조
- **한계:** 자유공간 직접 결합이며, 장착 구조 산란과 가림은 감쇠로 인정하지 않았다. 수신기 2차 기준(I/N 적분, 블로킹)은 이번 범위에서 평가하지 않았다(미평가).

## Appendix. 파일과 출처

| 파일 | 내용 |
| --- | --- |
| `data/rfi_psd/stc_itu_spurious_source.csv` | S-TC TX ITU source 6행 |
| `data/rfi_psd/tx_port_mismatch_rescaling.csv` | L2/L5 rescaling −10 dB, OWNER_ENGINEERING_BOUND |
| `output/claude/results/stc_filter_design.csv` | pair별 source·rescaling·coupling·PSD·margin·요구량·first PASS·design target (`pair` 키) |
| `output/claude/results/stc_pair_summary.csv`, `stc_psd_results.csv` | pair × filter scenario 요약 / 주파수별 전체 행 |
| `output/claude/results/stc_unreliable_cst_kept.csv` | 유지했지만 쓰지 않은 L2/L5 CST RealizedGain |
| `output/claude/run_stc_lband_rescaling.m`, `src/+rfscreen/+psd/PortMismatchRescaledResponse.m` | 실행 스크립트 / rescaled 응답 모델 |

재현: `octave-cli --no-gui --norc --eval "run('output/claude/run_stc_lband_rescaling.m')"`. 실행 시점 base commit은 `output/claude/results/run_provenance.csv`에 있다. 표 양식은 `output/codex/결과보고서.md`를 따랐지만, 수치는 Claude worker가 독립 계산했다. 역할명은 실제 역할(S-TC TX, S-TM RX)로 표기하고 legacy ID와 CSV 키(`S_TM_TX`, `S_TC_RX`, `S_TC`)는 그대로 두었다.
