# RFI 간섭 해석 결과보고서 — 불요방사 전력밀도 기반 피간섭원 평가 (Claude 독립 분석)

**결론.** Primary RFI 범위는 **S-TC TX와 Ka DLS TX**이며, ISL과 SAR는 victim으로만 다룬다(owner 결정, Task 2).
- **S-TC TX(legacy id: S_TM_TX):** ITU 불요방사 source 기준으로 GPS L2/L5가 70.45/70.87 dB(80 dB scenario)를 요구해 가장 크다. SAR RX는 63.36 dB(70 dB scenario)다. 고조파는 SAR 대역과 겹치지 않는다.
- **Ka DLS TX:** 최대 EIRP 49.451 dBW에 WR-42 below-cutoff 50 mm(owner 가정)를 적용했다. GPS와 S-TM RX는 추가 억제가 필요 없다. ISL RX 6.58 dB, SAR RX 8.08 dB가 남고 둘 다 40 dB scenario에서 통과한다.
- **판정 기준:** victim 포트 PSD [dBm/Hz]이며 허용치는 GPS −178, S-TM/ISL −177, SAR −175 dBm/Hz다(공학 가정).
- **owner 입력:** WR-42, 유효 길이 50 mm, SAR peak 52 dBi, ±80° 밖 −50 dB는 공학 가정·추정이다. 측정이나 full-wave 검증값이 아니다.

- **S-TC 송신기(2.25 GHz, 5 W)는 외부 필터가 필요하다.** CST 결합으로 평가한 경로 중 최악은 **SAR RX로, 요구 추가 억제량(required additional suppression)이 64.4 dB**다. 그 다음은 반대편 S-TM RX(58.9 dB)다.
  - S-TC의 정수배 고조파(integer harmonic)는 SAR 대역과 겹치지 않는다. 그러나 이것은 **고조파 경로가 없다는 뜻일 뿐, 광대역 불요방사 간섭이 없다는 뜻은 아니다.** 64.4 dB는 고조파가 아닌 일반 불요방사(generic spurious)에서 나온다.
  - GPS L2/L5는 89.0 dB까지 요구된다. 다만 S 안테나의 L2/L5 CST 응답을 쓸 수 없어서 송신 안테나 이득에 물리적 최대 지향성(Harrington limit)을 넣은 상한값이다.
- **Ka DLS 송신기(70 W)는 owner 설계 가정에서 L/S 대역 피간섭원에 대해 외부 필터가 필요 없다(margin +20.9 ~ +50.2 dB).** SAR RX와 ISL RX에는 각각 **9.1 dB와 6.6 dB**의 추가 억제가 필요하다. Ka의 최악 피간섭원은 SAR RX다.
  - 이 결과는 WR-42 도파관 50 mm의 차단주파수 이하 감쇠(below-cutoff waveguide attenuation; L/S 126–127 dB, SAR 90.6 dB, ISL 83.4 dB)를 적용한 값이다.
  - 이 감쇠는 **불요방사 한도가 도파관 상류(송신기 출력)에서 정의될 때만** 적용할 수 있다. 한도가 안테나 출력이나 EIRP로 정의되어 있다면 같은 감쇠를 다시 빼는 것은 이중 적용(double counting)이고, 그 경우 요구 억제량은 82–107 dB가 된다(§3.3).

| Attacker | Victim | Band | Source PSD/EIRP | Victim PSD | Limit | Required suppression | First PASS | Design target | Confidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S-TC TX (legacy id: S_TM_TX) | GPS RX | L1 | −49.02 | −130.00 | −178 | 48.00 | 60 dB | 60 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | GPS RX | L2 | −59.02 (−10 dB rescaling) | −107.55 | −178 | 70.45 | 80 dB | 90 dB | ENGINEERING_BOUND — L1-referenced 10 dB port-mismatch rescaling |
| S-TC TX (legacy id: S_TM_TX) | GPS RX | L5 | −59.02 (−10 dB rescaling) | −107.13 | −178 | 70.87 | 80 dB | 90 dB | ENGINEERING_BOUND — L1-referenced 10 dB port-mismatch rescaling |
| S-TC TX (legacy id: S_TM_TX) | S-TM RX (legacy id: S_TC_RX) | S (2025–2110 MHz) | −49.02 | −118.11 | −177 | 58.89 | 60 dB | 70 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | ISL RX | X (10.55–10.65 GHz) | −49.02 | −137.74 | −177 | 39.26 | 40 dB | 50 dB | 시뮬레이션 |
| S-TC TX (legacy id: S_TM_TX) | SAR RX (harmonic) | SAR X | — | — | — | 해당 없음 | — | — | NO_HARMONIC_OVERLAP |
| S-TC TX (legacy id: S_TM_TX) | SAR RX (generic spurious) | SAR X (9387.5–9912.5 MHz) | −49.02 | −111.64 | −175 | 63.36 | 70 dB | 80 dB | ENGINEERING_ESTIMATE (SAR 52 dBi, ±80° 밖 −50 dB) |
| Ka DLS TX | GPS RX | L1 / L2 / L5 | −16.57 (EIRP PSD), cutoff −127 dB | −223.29 / −199.62 / −198.93 | −178 | 0 / 0 / 0 | 0 dB | 불필요 | ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED |
| Ka DLS TX | S-TM RX | S (2025–2110 MHz) | −16.57, cutoff −126 dB | −198.49 | −177 | 0 | 0 dB | 불필요 | ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED |
| Ka DLS TX | ISL RX | X (10.55–10.65 GHz) | −16.57, cutoff −83.4 dB | −170.42 | −177 | 6.58 | 40 dB | 20 dB | ENGINEERING_BOUND; NOT_FULL_WAVE_VALIDATED |
| Ka DLS TX | SAR RX | SAR X | −16.57, cutoff −90.6 dB | −166.92 | −175 | 8.08 | 40 dB | 20 dB | ENGINEERING_BOUND + SAR ENGINEERING_ESTIMATE |

단위: PSD·Limit은 dBm/Hz, Required는 dB다. 각 행은 victim별 대표 worst다.

**억제 조건:**
- **Required suppression:** 0 dB 추가 필터 기준 총 요구량 max(0, PSD − limit)이다.
- **First PASS:** 0/40/60/70/80 dB screening 중 처음 margin ≥ 0인 값이다.
- **Design target:** 요구량 + 10 dB reserve를 10 dB 단위로 올린 계획값이다. 요구량이 0이면 "불필요"다. 필터 규격이 아니다.
- **Ka 도파관:** below-cutoff 감쇠는 필터와 별개 항(`WAVEGUIDE_BELOW_CUTOFF_BOUND`)이다. WR-42 50 mm에서 victim 대역 내 최소 감쇠를 적용했다.
- **Ka ISL·SAR의 길이 민감도:** 경로를 닫는 길이는 53.9 / 54.5 mm라 4~5 mm만 더 길면 추가 억제가 필요 없다. WR-34 50 mm였다면 모든 Ka 경로가 통과한다.

- **범위 matrix:**
  - S-TC TX → GPS / S-TM / ISL / SAR(victim-only)
  - Ka DLS TX → GPS / S-TM / ISL / SAR(cutoff route)
  - ISL TX와 SAR TX attacker는 **제외**한다.
  - KAA 저주파 최대 이득 상한은 legacy sensitivity로 내렸다.
- **SAR victim 패턴:** owner가 `K8_SAR_Pattern.mat`에서 추출한 값으로 재구성했다(HPBW az 0.242294° / el 1.112221°, upper envelope, 1601점 원본 미반출). peak 52 dBi(HPBW 기반 추정)와 ±80° 밖·후방 −50 dB(+2 dBi) ceiling은 owner 입력이다.
- **상세 보고서:**
  - S-TC TX: [S-TC_TX_억제요구_결과보고서.md](S-TC_TX_억제요구_결과보고서.md)
  - 범위·SAR·Ka cutoff: [RFI_Task2_범위단순화_결과보고서.md](RFI_Task2_범위단순화_결과보고서.md)
  - legacy KAA 상한: [KAA_저주파_방사응답_결과보고서.md](KAA_저주파_방사응답_결과보고서.md)
- **최종 판정에 필요한 입력:**
  1. Ka 도파관 형식·유효 길이 실측(현재 owner 가정 WR-42 / 50 mm)
  2. SAR 실제 peak gain과 후방 패턴(현재 owner 추정 52 dBi / −50 dB)
  3. S 안테나 L2/L5 S11
  4. 실제 TX BPF table과 동일 포트 isolation
  5. 수신기 블로킹·P1dB 데이터
- **Secondary:** 기본파 blocker 노출은 7절에 유지했고, 1차 요구사항이 아니다.
- **추가 CST 시뮬레이션은 하지 않았다.** 아래 3절 이하는 이전 판의 결합 계산 틀이다. 그중 ISL TX attacker 행은 이제 범위 밖이며 추적성을 위해서만 남겼다.

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

## 1. Executive Summary

## 3. Victim-band PSD 결과 (이전 판 결합 계산 — ISL TX attacker 행은 범위 밖, 추적용)

  | 간섭원 → 최악 피간섭원 | Victim PSD [dBm/Hz] | 허용 PSD [dBm/Hz] | Margin [dB] | 요구 추가 억제량 [dB] | 결합 근거 |
  |---|---|---|---|---|---|
  | S-TC → SAR RX | −111.6 | −176 | −64.4 | **64.4** | CST(S 안테나) + owner SAR 패턴 |
  | S-TC → 반대편 S-TM RX | −118.1 | −177 | −58.9 | 58.9 | CST |
  | S-TC → GPS L2/L5 | −89.0 | −178 | −89.0 | 89.0 | 송신 이득 상한(Harrington) |
  | Ka DLS → SAR RX | −166.9 | −176 | −9.1 | **9.1** | 31 dBi + WR-42 50 mm + owner SAR 패턴 |
  | Ka DLS → ISL RX | −170.4 | −177 | −6.6 | 6.6 | 31 dBi + WR-42 50 mm + CST |
  | Ka DLS → GPS / S-TM | −198.5 이하 | −177 / −178 | +20.9 이상 | 0 | 31 dBi + WR-42 50 mm + CST |

- **최종 worst-case 피간섭원:**
  - CST·owner 입력으로 평가한 경로에서는 **SAR RX**가 두 간섭원 모두의 최악이다(S-TC 64.4 dB, Ka 9.1 dB).
  - 수치상 가장 큰 요구량은 S-TC → GPS L5 89.0 dB다. 이 값은 S 안테나의 L2/L5 이득을 물리 상한으로 둔 값이므로, S 안테나 L2/L5 응답이 확보되면 낮아질 수 있다.
- **SAR 수신 이득:** 네 간섭원 위치(S NADIR/ZENITH, KAA_1/2) 모두 SAR 보어사이트 기준 85.8–123.9°로 ±80° 밖이다. 따라서 owner 후방 상한 **G_SAR = +2 dBi**(52 dBi − 50 dB)를 적용했다.
- **필터 요구(송신 측):** S-TC는 **≥ 70 dB 필터 감쇠**가 필요하다(SAR 64.4 dB 기준; GPS L2/L5 상한 경로는 별도 확인 필요). Ka는 owner 설계 가정에서 **≥ 10 dB**면 SAR·ISL을 포함해 모든 피간섭원이 기준을 충족한다. 단 기준면 확인이 전제다(§3.3).
- **결론을 바꿀 수 있는 미확정 입력:**
  1. Ka 송신기 불요방사 사양이 정의되는 기준면(송신기 출력 vs 안테나 출력)과 WR-42 50 mm 구간의 우회 경로 유무
  2. S 안테나의 L2/L5 대역 응답
  3. 실제 송신기 불요방사 사양과 필터 데이터

## 2. 주요 RFI 결과 — 통합 결과표

**결과.** 모든 대역을 같은 PSD 체계로 정리했다. S-TC는 GPS L2/L5, SAR, S-TM, GPS L1, ISL 순으로 큰 억제가 필요하다. Ka는 SAR와 ISL만 추가 억제가 필요하다.

계산식(산출):
```
Victim PSD [dBm/Hz]   = Source PSD − WG attenuation + Coupling
Coupling [dB]         = G_TX(f_v) + G_RX(f_v) − FSPL(f_v, d)          (피간섭원 주파수 f_v에서 평가)
Margin [dB]           = Allowable PSD − Victim PSD                     (양수 = 여유, 음수 = 초과)
Required suppression  = max(0, −Margin)                                 (송신 측 추가 필터 감쇠)
```
- S-TC의 G_TX는 피간섭원 주파수에서의 S 안테나 CST RealizedGain(시뮬레이션 데이터)이다. Ka의 G_TX는 owner 기준 이득 31 dBi다.
- G_RX는 피간섭원 안테나의 자기 대역 CST RealizedGain이다. SAR는 owner 재구성 패턴(+2 dBi)을 쓴다.
- WG attenuation은 Ka에만 있으며, 송신기 출력과 방사 개구 사이의 WR-42 50 mm 구간 감쇠다.

**표 A. 불요방사 PSD 결과 (1차 RR AP3, 필터 0 dB, 대역 내 최악 주파수)**

| Interferer | Victim | Source PSD [dBm/Hz] | WG attenuation [dB] | Coupling [dB] | Victim PSD [dBm/Hz] | Allowable PSD [dBm/Hz] | Margin [dB] | Required suppression [dB] |
|---|---|---|---|---|---|---|---|---|
| S-TC TX @ ZENITH | GPS L5 RX @ GPSA_1 | −49.02 | — | −39.96 ¹ | −88.98 | −178 | −89.02 | **89.0** ¹ |
| S-TC TX @ ZENITH | GPS L2 RX @ GPSA_1 | −49.02 | — | −40.24 ¹ | −89.26 | −178 | −88.74 | 88.7 ¹ |
| S-TC TX @ NADIR | GPS L5 / L2 RX (양 GPSA) | −49.02 | — | −56.20 ~ −53.30 ¹ | −105.22 ~ −102.32 | −178 | −75.68 ~ −72.78 | 75.7 ¹ |
| S-TC TX @ NADIR | **SAR RX** | −49.02 | — | −62.62 | −111.64 | **−176** | −64.36 | **64.4** |
| S-TC TX @ ZENITH | **SAR RX** | −49.02 | — | −63.16 | −112.18 | **−176** | −63.82 | 63.8 |
| S-TC TX (양 방향) | 반대편 S-TM RX | −49.02 | — | −69.09 | −118.11 | −177 | −58.89 | 58.9 |
| S-TC TX @ ZENITH | GPS L1 RX @ GPSA_1 / GPSA_2 | −49.02 | — | −80.98 / −86.09 | −130.00 / −135.11 | −178 | −48.00 / −42.89 | 48.0 |
| S-TC TX @ NADIR / ZENITH | ISL RX | −49.02 | — | −88.81 / −88.72 | −137.83 / −137.74 | −177 | −39.17 / −39.26 | 39.3 |
| S-TC TX @ NADIR | GPS L1 RX @ GPSA_1 / GPSA_2 | −49.02 | — | −105.43 / −103.59 | −154.45 / −152.61 | −178 | −23.55 / −25.39 | 25.4 |
| Ka DLS TX @ KAA_1 / KAA_2 | **SAR RX** | −47.57 ² | 90.64 | −28.71 / −28.96 | −166.92 / −167.17 | **−176** | −9.08 / −8.83 | **9.1** ³ |
| Ka DLS TX @ KAA_2 / KAA_1 | ISL RX | −47.57 ² | 83.43 | −39.42 / −40.45 | −170.42 / −171.45 | −177 | −6.58 / −5.55 | 6.6 ³ |
| Ka DLS TX @ KAA_2 / KAA_1 | S-TM RX (최악 SBA_NADIR) | −47.57 ² | 126.44 | −24.47 / −28.29 | −198.49 / −202.31 | −177 | +21.49 / +25.31 | 0 ³ |
| Ka DLS TX @ KAA_1 | GPS L5 / L2 RX @ GPSA_2 | −47.57 ² | 127.45 / 127.41 | −23.92 / −24.64 | −198.93 / −199.62 | −178 | +20.93 / +21.62 | 0 ³ |
| Ka DLS TX @ KAA_1 | GPS L1 RX @ GPSA_2 | −47.57 ² | 127.10 | −48.62 | −223.29 | −178 | +45.29 | 0 ³ |

¹ S 안테나의 L2/L5 CST RealizedGain은 정규화가 불안정해 쓰지 않았다. 대신 S 안테나를 감싸는 구(a = 53 mm)의 Harrington 최대 지향성(6.4–6.6 dBi)을 송신 이득으로 넣었다. 따라서 이 행은 **안테나 이득 상한에 따른 보수값**이다.
² Ka source PSD는 송신기 출력(WR-42 입력) 기준의 conducted 값이다. 31 dBi 기준 이득은 Coupling 열에 들어 있다.
³ Owner 설계 가정(한도가 WR-42 상류에서 정의, 유효 길이 50 mm)이다. 한도가 안테나 출력에서 정의된다면 WR-42 감쇠를 적용할 수 없다(§3.3, 각주 표 C).

해석:
- **SAR RX가 S-TC의 새 지배 경로다.** S-TC → SAR의 경로 결합(−62.6 dB)은 S-TM 경로(−69.1 dB)보다 6.5 dB 크다. SAR 기준(−176 dBm/Hz)은 S-TM 기준보다 1 dB 완화되어 있지만, 결합 차이가 더 크다. 따라서 64.4 dB > 58.9 dB다.
- 고조파 비중첩은 S-TC → SAR 결론에 영향을 주지 않는다. 계산에 쓴 것은 SAR 대역 전체에 걸친 광대역 불요방사 PSD다.
- **Ka의 L/S 피간섭원은 도파관 감쇠(126–127 dB)가 지배한다.** 31 dBi를 L/S에 적용해도 margin이 +20 dB 이상이다. 차단주파수 14.05 GHz에 가까운 SAR(9.39–9.91 GHz)·ISL(10.55–10.65 GHz)만 감쇠가 83–91 dB로 줄어 초과가 남는다.
- 전체 주파수별 결과: `results/oob_spurious/victim_psd_results.csv`. 쌍별 요약(최악 주파수 기준): `primary_psd_results.csv`.

## 3. 대역별 상세 — S-TC → SAR, Ka WR-42, 기준면

### 3.1 S-TC → SAR: 고조파와 일반 불요방사를 분리

**A. 정수배 고조파 (integer harmonic overlap): 없음**

| 차수 | 고조파 대역 (점유대역 2.7 MHz 기준) | SAR 대역 9.3875–9.9125 GHz와의 관계 |
|---|---|---|
| 4차 | 8.9946–9.0054 GHz | 382 MHz 아래, 겹침 없음 |
| 5차 | 11.2433–11.2568 GHz | 1.33 GHz 위, 겹침 없음 |
| 1–6차 전체 | — | **NO_HARMONIC_OVERLAP** |

- S 하향링크 할당 전체(2200–2290 MHz)로 넓혀도 4차는 8.80–9.16 GHz이며 SAR 하한보다 227.5 MHz 아래다. 따라서 겹치지 않는다(`stc_sar_harmonic_check.csv`).
- **이 결론은 고조파 경로가 없다는 뜻이며, S-TC → SAR 분석을 끝내는 근거가 아니다.**

**B. 일반 불요방사 (generic spurious emission): 64.4 dB 억제 필요**

| 단계 | S-TC @ NADIR | S-TC @ ZENITH | 근거 유형 |
|---|---|---|---|
| S-TC 불요방사 PSD @ SAR 대역 | −49.02 dBm/Hz | −49.02 dBm/Hz | 규격(RR AP3) → 산출 |
| S 안테나 이득 @ 9.3875 GHz, SAR 방향 | −2.81 dBi | −1.99 dBi | CST 시뮬레이션 데이터 |
| 거리 / 자유공간 손실(FSPL) | 3.127 m / 61.80 dB | 3.662 m / 63.17 dB | 산출 |
| SAR 입사각(보어사이트 기준) | 85.8° (±80° 밖) | 123.9° (후방) | 산출(형상) |
| SAR 수신 이득 | **+2 dBi**(후방 상한) | **+2 dBi**(후방 상한) | owner 공학 입력 |
| 경로 결합(Coupling) | −62.62 dB | −63.16 dB | 산출 |
| Victim PSD (SAR 수신 포트) | −111.64 dBm/Hz | −112.18 dBm/Hz | 산출 |
| 허용 PSD (NF 4 dB, I/N −6 dB) | −176 dBm/Hz | −176 dBm/Hz | owner 입력 |
| Margin / 요구 추가 억제량 | −64.36 / **64.4 dB** | −63.82 / 63.8 dB | 산출 |

- 최악 주파수는 SAR 대역 하단(9.3875 GHz)이다. S 안테나 이득이 대역 하단에서 가장 크기 때문이다.
- S-TC @ ZENITH → SAR는 위성 구조물로 가시선이 막혀 있다. 하지만 자유공간 결합에서 차폐 감쇠를 빼지 않았다(보수 방향).
- ECSS-E-ST-50-05C(−60 dBc/4 kHz)로 조달된 송신기라면 요구량은 54.4 dB다.

### 3.2 Ka DLS: WR-42 50 mm 차단주파수 이하 감쇠

**결과.** WR-42(a = 10.668 mm, TE10 차단주파수 f_c = c/2a = 14.051 GHz) 50 mm 구간의 감쇠는 L/S 126.4–127.5 dB, SAR 90.6–95.2 dB, ISL 83.4–84.5 dB다. 각 대역의 상단 주파수가 최소 감쇠(최악)다.

```
α(f) = √((π/a)² − (2πf/c)²)   [Np/m]        (TE10, f < f_c)
A(f) = 8.685889638 · α(f) · 0.05   [dB]      (L = 50 mm, owner 입력)
```

| 피간섭원 대역 | 주파수 [GHz] | f_hi / f_c | 감쇠 A [dB] (최악 = 상단) |
|---|---|---|---|
| GPS L5 | 1.164–1.189 | 0.085 | 127.45–127.44 |
| GPS L2 | 1.2174–1.2378 | 0.088 | 127.41–127.40 |
| GPS L1 | 1.563–1.588 | 0.113 | 127.10–127.07 |
| S-TM | 2.025–2.110 | 0.150 | 126.56–126.44 |
| SAR | 9.3875–9.9125 | 0.705 | 95.16–**90.64** |
| ISL | 10.55–10.65 | 0.758 | 84.47–**83.43** |

- 50 mm는 ITU-R SM.329-13 recommends 2.5의 조건(도파관 길이 ≥ 2λ_c = 42.7 mm)을 만족한다. 이 조항은 이런 일체형 안테나에 대해 0.7 f_c 아래 불요방사 측정을 요구하지 않는다.
- 감쇠는 기본 모드(TE10)만 계산했다. 고차 모드는 차단주파수가 더 높아 더 크게 감쇠하므로, TE10 값이 가장 작은(보수적) 감쇠다.
- 31 dBi 기준 이득은 L/S 대역에서 보수적이다. KAA 크기(직경 220 mm)의 물리적 최대 지향성은 L/S 13.7–15.8 dBi, SAR·ISL 약 28 dBi다. 이 상한을 쓰면 Ka → SAR 6.3 dB, Ka → ISL 4.4 dB로 줄어든다(`ka_reference_plane_comparison.csv`, 참고값).

### 3.3 기준면 검토 — AP3 한도와 WR-42 감쇠의 연결

**결론.** RR AP3의 불요방사 한도는 기본적으로 **안테나 전송선에 공급되는 전력**(송신기 출력, conducted)에 정의된다. KAA의 WR-42 구간이 그 기준면보다 하류에 있는 안테나 일부라면 감쇠를 적용할 수 있다. 반대로 한도나 공급사 사양이 안테나 출력에서 정의되었다면 감쇠를 다시 적용할 수 없다.

| 경우 | 불요방사 정의 위치 | WR-42 감쇠 적용 | Ka 요구 억제량 (최악) |
|---|---|---|---|
| **1. 도파관 상류** (owner 설계 가정, 표 A) | 송신기(SSPA) 출력 플랜지 = 안테나 전송선 입력. AP3 기본 정의와 같다 | **적용 가능.** 불요방사가 WR-42 below-cutoff 구간을 지나야 방사된다 | SAR 9.1 dB, ISL 6.6 dB, L/S 0 dB |
| **2. 안테나 출력/EIRP** | 안테나 급전 출력 또는 방사 EIRP(AP3 e.i.r.p. 방법, 공급사 안테나 단 측정) | **적용 불가.** 측정값에 이미 WR-42 감쇠가 포함되어 있어 다시 빼면 이중 적용이 된다 | SAR 100.2 dB, ISL 90.0 dB, S-TM 105.0 dB, GPS L1/L2/L5 81.8 / 105.8 / 106.5 dB |

해석:
- AP3는 e.i.r.p. 방법을 "안테나가 spurious 영역에서 큰 감쇠를 주도록 설계된 경우"에 쓰도록 한다. 따라서 공급사가 EIRP로 불요방사를 제시한다면 그 값에는 도파관 감쇠가 이미 들어 있다고 봐야 한다. 이 경우 −16.57 dBm/Hz(31 dBi 포함 EIRP 한도)는 규제 상한이다. 여기에 WR-42 감쇠를 추가로 빼면 victim PSD를 83–127 dB 과소평가한다.
- 경우 1이 성립하려면 다음 세 가지를 확인해야 한다.
  1. Ka 송신기 불요방사 사양의 측정 기준면이 WR-42 입력(송신기 출력) 쪽이다.
  2. 50 mm 유효 구간 뒤에 동축 변환·스트립선로 등 차단주파수가 없는 구간이 없다.
  3. 플랜지 틈새, 바이어스·제어 선로, SSPA 함체 직접 방사처럼 도파관을 우회하는 누설 경로가 따로 관리된다.
- 표 A와 §1의 Ka 결과는 owner 설계 가정(경우 1)을 보여 준다. 경우 2의 수치는 비교용(provenance)이다. 기준면이 확인되기 전까지 Ka 결론은 "경우 1이면 ≥ 10 dB 필터로 충분, 경우 2이면 ≥ 107 dB 억제 필요"의 범위로 읽어야 한다.

## 4. Receiver criterion

**결과.** 1차 판정은 각 수신기 tuning 대역 전체의 PSD 기준(허용 간섭 PSD = kT₀ + NF + I/N)이다. SAR는 owner 입력으로 갱신했다.

| 수신기 | 판정 대역 | NF [dB] | I/N [dB] | 허용 간섭 PSD [dBm/Hz] | 근거 유형 |
|---|---|---|---|---|---|
| GPS L1 / L2 / L5 | 1563–1588 / 1217.37–1237.83 / 1164–1189 MHz | 2 | −6 | −178 | 가정(engineering baseline) |
| S-TM | 2025–2110 MHz | 3 | −6 | −177 | 가정 |
| ISL | 10.55–10.65 GHz | 3 | −6 | −177 | 가정·잠정 |
| **SAR** | 9.3875–9.9125 GHz | **4** | −6 | **−176** | **owner 공학 입력**(이전 NF 5 dB 대리값 −175 대체) |

- kT₀ = −174 dBm/Hz(290 K 관례)다. SAR: −174 + 4 − 6 = −176 dBm/Hz.
- 공유 `data/rfi_psd/receiver_baseline.csv`의 SAR 행(NF 5 dB)은 바꾸지 않았다. owner 값은 Claude 입력 파일에서 적용했다.

**SAR 수신 패턴(owner 재구성, ENGINEERING_RECONSTRUCTION):**
- 최대 이득 52 dBi, 방위 HPBW 0.242294°, 고각 HPBW 1.112221°
- 첫 null: 방위 ±0.3°(−39.083 dB), 고각 ±1.3°(−31.241 dB)
- 최대 부엽: 방위 −13.565 dB @ ±0.4°, 고각 −13.270 dB @ ±1.8°
- ±80° 밖과 후방: −50 dB(최대 이득 대비), 절대 상한 +2 dBi
- ±80° 안에서는 주엽 −12(θ/HPBW)²을 최대 부엽 준위로 바닥 처리한 보수 포락선을 쓴다. 두 주단면 중 덜 감쇠된 값을 적용한다. 현재 형상에서는 모든 입사각이 ±80° 밖이라 이 영역이 결과에 쓰이지 않았다.
- 교차편파 −120 dB floor는 이번 RFI 분석에서 무시했다(공편파 포락선 사용). 근거는 provenance에 남겼다.

## 5. Filter / suppression requirement

**결과.** 송신 측 불요방사 억제 요구(RX blocker rejection 아님)는 S-TC ≥ 70 dB, Ka ≥ 10 dB(owner 설계 가정)다.

| 송신기 | 지배 피간섭원 | 요구 추가 억제량 [dB] | 필터 감쇠 시나리오(0/40/60/70/80 dB) 중 첫 충족 | 근거 |
|---|---|---|---|---|
| S-TC | SAR RX | **64.4** | 70 dB | CST + owner SAR 패턴 |
| S-TC | 반대편 S-TM RX | 58.9 | 60 dB(여유 1.1 dB) | CST |
| S-TC | GPS L2/L5 | 89.0 | 80 dB로 부족 | 송신 이득 상한¹ |
| Ka DLS | SAR RX | **9.1** | 40 dB | 31 dBi + WR-42 50 mm(경우 1) |
| Ka DLS | ISL RX | 6.6 | 40 dB | 31 dBi + WR-42 50 mm(경우 1) |
| (참고) ISL TX | S-TM RX | 33.7 | 40 dB | CST(이전 결과, owner 범위에서 간섭원 아님) |

- 요구 추가 억제량은 피간섭원 대역 전체에서 max(victim PSD − 허용 PSD)다. 필터 감쇠 시나리오(0/40/60/70/80 dB)는 판단을 돕는 단계값이며, 설계값은 요구 추가 억제량 열이다.
- S-TC 필터는 SAR 대역(9.39–9.91 GHz)에서 ≥ 64.4 dB, S-TM 대역(2.025–2.11 GHz)에서 ≥ 58.9 dB를 동시에 만족해야 한다. 2.25 GHz 필터의 고주파 재통과 대역(spurious passband)이 9–10 GHz에 생기지 않는지 확인해야 한다.
- ECSS 조달 송신기라면 S-TC 요구량은 SAR 54.4 dB, S-TM 48.9 dB다(60 dB 범주).
- 상세: `results/oob_spurious/tx_filter_requirement.csv`, `pair_margin_summary.csv`(열 `minimum_required_additional_suppression_db`, `first_passing_scenario`).

## 6. 입력 누락 및 분석 한계

1. **Ka 불요방사 기준면(미확정):** 결과를 가장 크게 바꾸는 입력이다(§3.3). 경우 1과 경우 2의 요구량 차이는 82–107 dB다.
2. **SAR 패턴(owner 재구성):** 원본 1601점 MAT 파일은 읽지 않았다. owner가 추출한 주요 값(최대 이득, HPBW, null, 부엽, 후방 포락선)만 썼다.
   - 최대 이득 52 dBi는 HPBW에서 추정한 값이다(OWNER_ENGINEERING_ESTIMATE_FROM_HPBW).
   - 방위면을 비행축(+X_B)으로 가정했다. 모든 입사각이 ±80° 밖이라 이 가정은 결과에 영향을 주지 않는다.
   - SAR 패턴은 대역 내 주파수 독립으로 가정했다.
3. **S 안테나 L2/L5 응답(미확정):** S-TC → GPS L2/L5는 송신 이득 상한값이다.
4. **모델 가정:** 자유공간 결합(구조 산란·차폐 없음, 두 컷 근사), 급전 손실 0 dB, 편파 손실 없음, 잡음형 광대역 불요방사. 모두 보수 방향이다.
5. **실제 송신기 사양·필터 데이터(미확정):** AP3는 법적 상한이다. 공급사 사양이 들어오면 같은 체인에서 source PSD를 바꾼다.

## 7. Secondary blocker analysis

**결과.** 기본파(fundamental)에 의한 수신기 노출은 별도로 계산했다. 수신기 블로킹 데이터가 없어 판정은 보류다.

- **S-TC 2.25 GHz 기본파 → SAR RX 포트:** −15.0 dBm(NADIR), −21.5 dBm(ZENITH)이다.
  - S 안테나 이득 −4.6 / −9.7 dBi, FSPL 49.4 / 50.8 dB를 썼다.
  - SAR 안테나의 2.25 GHz 응답이 없어서 +2 dBi 후방 상한을 대역 밖에도 적용했다. 이 부분은 가정이다.
  - SAR 프리셀렉터와 블로킹 한도가 없어 판정을 보류한다(`sar_secondary_fundamental_exposure.csv`).
- **이산 스퍼(discrete spur, 채널 안에 떨어질 때만):** AP3 단일 성분 −13 dBm 톤이 SAR 포트에서 −75.6 dBm이다. SAR 525 MHz 적분 허용 −88.8 dBm보다 13.2 dB 높다(`discrete_spur_check.csv`).
- **기존 blocker 값 유지:** S-TC@ZENITH → GPSA_1 −21.3 dBm, S-TC → 반대편 S-TM −32.3 dBm @ 2.25 GHz(`results/oob_blocking_results.csv`).
- Ka 기본파(25.5–27 GHz)의 SAR 포트 노출은 owner SAR 패턴이 SAR 대역만 다루므로 이번에도 계산하지 않았다.

## Appendix A. 용어 정리 (이전 표현 → 이번 보고서)

| 이전 내부 표현 | 이번 보고서 용어 | 위치 |
|---|---|---|
| gain bound / Harrington bound / BOUNDED | 안테나 이득 상한(Harrington maximum directivity) | 표 A 각주 ¹ |
| SENS_KAA_WR42_2LC, conditional bound, zero cutoff credit | 도파관 차단주파수 이하 감쇠(below-cutoff waveguide attenuation), 기준면 경우 1/2 | §3.2, §3.3 |
| bound route / route name / coupling route | 경로 결합(path coupling) 근거 | CSV `coupling_basis`, `coupling_route` |
| screening filter class | 필터 감쇠 시나리오, 요구 추가 억제량(required additional suppression) | §5 |
| source PSD (규격 기반) | 불요방사 전력밀도(spurious emission PSD) / 불요방사 EIRP 전력밀도(spurious EIRP spectral density) | §1 |
| port PSD | 피간섭원 입력 전력밀도(victim input PSD) | 표 A |
| allowable PSD | 허용 간섭 전력밀도(allowable interference PSD) | §4 |

- CSV enum 대응: `coupling_basis` = `CST_SIMULATED_GAIN`, `CST_TX_GAIN_OWNER_SAR_RX_ENVELOPE`, `HARRINGTON_MAX_DIRECTIVITY_TX`, `OWNER_31DBI_GAIN_REFERENCE_WR42_50MM`.
- `variant` = `PRIMARY_RR_AP3`, `SENS_ECSS_50_05C`, `SENS_KA_SOURCE_AT_ANTENNA_OUTPUT`(경우 2), `SENS_KA_HARRINGTON_GAIN`(31 dBi 대신 물리 상한 이득).
- 역할명 대응: owner의 **S-TC TX**(2.25 GHz) = 저장소 `S_TM_TX`, owner의 **S-TM RX**(2025–2110 MHz) = 저장소 `S_TC_RX`. CSV의 system ID는 저장소 이름을 유지한다.

## Appendix B. SAR 피간섭원 제외 로직 제거와 상태 갱신

- **제거한 로직:** `output/claude/run_oob_spurious_analysis.m`의 고조파/영역 확인 루프에 있던 `if strcmp(b.receiver, 'SAR_X_RX'); continue; end`를 지웠다.
- **새로 추가한 평가:** 쌍 목록이 `pair_results.csv`(SAR_ANT가 분석 케이스에서 빠진 freeze-point 결과)에서만 왔기 때문에 SAR RX가 빠져 있었다. 이번에 S-TC ×2와 Ka ×2 → SAR RX 쌍을 명시적으로 추가했다.
- **SAR TX:** 간섭원으로 넣지 않았다(owner 정책).
- **추가 검색 결과(제외/skip 성격 로직):**
  - `run_rfi_analysis.m`: SAR 패턴 가용성 `NO_PATTERN_BOUND`, SAR 피간섭원 `PARTIAL_INTERFERER_SIDE_ONLY`가 있다. freeze-point 기록이며, SAR 결과는 이번 파일들이 대체한다.
  - `src/+rfscreen/+kaa/KaVictimResponse.m`: SAR의 Ka 대역 응답이 `NO_PATTERN_BOUND`로 되어 있다. Ka 기본파 경로이며, owner 패턴이 SAR 대역만 다루므로 유지했다. 공유 엔진은 수정하지 않았다.
  - `data/spacecraft/.../rf_systems.csv`, `analysis_cases.csv`: `DEFERRED_CLOSED_NETWORK`는 CST 패턴 결합 상태다. 저장소에 SAR 패턴 파일이 없으므로 유지했다.
- 상태 전환 전체: `results/oob_spurious/sar_status_update.csv`.

## Appendix C. 산출물·재현·provenance

- **결과**(`output/claude/results/oob_spurious/`):
  - 1차: `primary_psd_results.csv`(표 A 형식), `pair_margin_summary.csv`, `victim_psd_results.csv`(주파수별), `tx_filter_requirement.csv`
  - SAR: `stc_sar_harmonic_check.csv`, `sar_victim_geometry.csv`, `sar_secondary_fundamental_exposure.csv`, `sar_status_update.csv`
  - Ka: `ka_wr42_below_cutoff_attenuation.csv`, `ka_reference_plane_comparison.csv`
  - 공통: `source_emission_derivation.csv`, `domain_and_harmonic_check.csv`, `discrete_spur_check.csv`, `standards_survey.csv`
  - 기록: `validation_log.txt`, `test_suite_log.txt`, `run_log.txt`, `update_record_2026-10-05.txt`, `freeze_record.txt`(이전 분석)
- **입력:**
  - `output/claude/inputs/tx_emission_sources_claude.csv`: SAR 대역 행 추가
  - `output/claude/inputs/owner_engineering_inputs_claude.csv`: SAR 패턴·NF·허용 PSD와 Ka 70 W·31 dBi·WR-42·50 mm. 근거 유형은 `OWNER_EXTRACTED_FROM_K8_SAR_PATTERN_MAT`, `ENGINEERING_RECONSTRUCTION`, `OWNER_ENGINEERING_ESTIMATE_FROM_HPBW`, `OWNER_ENGINEERING_REAR_ENVELOPE`이다.
- **재현**(저장소 루트, GNU Octave):
  ```
  octave-cli --no-gui --norc --eval "run('output/claude/run_oob_spurious_analysis.m')"
  octave-cli --no-gui --norc --eval "run('output/claude/validate_oob_spurious.m')"
  ```
- **provenance:**
  - 실행 기준 commit은 `results/run_provenance.csv`에 있다.
  - 이번 실행 환경은 GNU Octave 8.4.0이다(이전 9.2.0). 수정 전 스크립트를 8.4.0에서 다시 돌려 모든 기존 CSV가 비트 단위로 같게 재현되는 것을 먼저 확인했다.
  - 다른 worker 산출물은 owner 역할명 대응(S-TC = `S_TM_TX`)을 확인하는 데만 읽었다. 수치·모델·패턴 표본은 쓰지 않았다(`update_record_2026-10-05.txt`).
- 규격 원문 근거(RR AP3 Table I·§8·Annex 1, SM.329-13 recommends 2.5·Table 8, ECSS-E-ST-50-05C Table 5-6, CCSDS 401 2.4.16)는 이전 판과 같다. 상세는 `standards_survey.csv`와 `RFI_분석근거.md` §13–§14에 있다.
