# RFI 간섭 해석 결과보고서 — 송신기 불요방사 규격 적용 (Claude 독립 분석)

**결론.** 국제 규제 한도(ITU 전파규칙 부록 3)에 **딱 맞게 준수하는 송신기**가 내는 불요방사를 피간섭원 수신 대역에서 평가했다.
- **추가 외부 필터가 없으면 42개 TX→피간섭원 조합 모두가 수신기 PSD 기준을 넘는다**(1차 규격 기준). 이 중 16개는 CST 결합, 26개는 물리 상한 결합으로 계산했다.
- 가장 큰 요구는 다음과 같다(피간섭원 포트, 허용 PSD 대비).

  | 송신기 | 지배 피간섭원 | 최소 추가 억제량 | 범주 | 근거 |
  |---|---|---|---|---|
  | S-TM | 반대편 S-TC | **58.9 dB** | 60 dB 필터부터 충족(여유 1.1 dB) | CST 결합 |
  | ISL | S-TC | **33.7 dB** | 40 dB부터 충족 | CST 결합 |
  | Ka | S-TC | 물리 상한 기준 **89.8 dB** | 80 dB로도 부족 | 상한 결합 |

- Ka의 결과는 KAA가 S/L/X 대역에서 낼 수 있는 최대 지향성(물리 상한)을 가정한 값이다. KAA의 WR-42 도파관 급전이 차단 주파수 아래 대역을 실제로 막아 준다면 L/S 대역은 필터 없이도 기준을 충족한다(조건부).

판정 범위:
- 1차 판정은 **TX 불요방사 억제 요구**(송신 측 필터)이며, 수신기의 blocker rejection과는 별개다.
- 수신기 블로킹·위성 구조 산란은 포함하지 않았다.
- 기준은 freeze point의 engineering baseline이다(GPS −178 dBm/Hz, S-TC·ISL −177 dBm/Hz).

## 1. Executive Summary

- **적용 규격(1차):** ITU 전파규칙 부록 3(RR AP3, Rev. WRC-12) Table I "우주국(space stations)" 한도다.
  - 감쇠 = 43 + 10 log P 또는 60 dBc 중 **덜 엄격한 값**, 4 kHz 기준 대역폭, 안테나 전송선 공급전력 기준(conducted).
  - 모든 피간섭원 대역은 각 송신기 중심에서 AP3 Annex 1 경계보다 멀다. 따라서 **spurious 영역**이고, OOB 마스크(SFCG 21-2, SM.1541)는 적용되지 않는다.
- **source PSD(산출):** 4 kHz당 한도를 잡음형 방사로 가정한 광대역 등가값이다.
  - S-TM(5 W): −13.0 dBm/4 kHz → **−49.0 dBm/Hz**
  - ISL(1 W): −13.0 dBm/4 kHz → **−49.0 dBm/Hz**
  - Ka(70 W): −11.55 dBm/4 kHz → **−47.6 dBm/Hz**
  - 이산 스퍼는 dBm/Hz로 바꾸지 않고 별도로 검토했다(§9).
- **결과(필터 0 dB):**
  - **S-TM:** margin −23.5 ~ −58.9 dB. 최악은 반대편 S-TC, 다음은 GPSA_1 L1(−48.0 dB).
  - **ISL:** margin −6.8 ~ −33.7 dB. 최악은 S-TC.
  - **Ka:** 상한 결합 기준 −59.6 ~ −89.8 dB.
- **최소 추가 억제량과 screening 필터 범주:**
  - S-TM ≥ 60 dB
  - ISL ≥ 40 dB
  - Ka는 상한 기준으로 > 80 dB여서 별도 설계 검토가 필요하다. 1순위 확인 항목은 KAA 도파관 급전 구간의 차단 특성이다.
- **미확정으로 결론이 바뀔 수 있는 입력:**
  1. 실제 송신기 불요방사 사양(공급사 규격)
  2. KAA의 S/L/X 대역 방사 응답 또는 도파관 구간 길이
  3. S 안테나의 L2/L5 응답(현재 정규화 불안정으로 상한만 계산)
  4. 실제 필터 감쇠 table
- **감도(ECSS-E-ST-50-05C, −60 dBc/4 kHz):** 송신기가 ECSS로 조달되면 S-TM은 10 dB, ISL은 17 dB 완화된다.
  - S-TM → S-TC는 여전히 48.9 dB가 필요해 60 dB 필터 범주가 유지된다.
  - ISL → GPS L1만 필터 없이 기준을 충족한다.
- **Secondary blocker:** 기존 값(S-TM@ZENITH → GPSA_1 −21.3 dBm, S-TM → 반대편 S-TC −32.3 dBm)은 유지했고, 블로킹 판정은 보류다. 필터 요구는 여기서 도출하지 않았다.

## 2. 적용한 OOB/spurious 규격

**결과.** 세 송신기 모두 피간섭원 대역이 spurious 영역이다. 1차 규격은 RR AP3이다. ECSS는 감도 분석에, CCSDS 2.4.16은 이산 스퍼 검토에 썼다.

**A. 적용 규격**

| TX | 규격 | 영역 (AP3 Annex 1 경계) | 한도 | 기준 대역폭 | 기준면 |
|---|---|---|---|---|---|
| S-TM 2.25 GHz, 5 W | RR AP3 Table I 우주국 | spurious (경계 ±6.75 MHz = 2.5 B_N, B_N 2.7 MHz; 피간섭원 최소 이격 140 MHz) | 43 + 10 log 5 = 49.99 dBc → −13.0 dBm | 4 kHz | 안테나 전송선(conducted) |
| ISL 10.6 GHz, 1 W | RR AP3 Table I 우주국 | spurious (경계 ±50 MHz; 최소 이격 8.3 GHz) | 43.0 dBc → −13.0 dBm | 4 kHz | 안테나 전송선 |
| Ka 25.5–27 GHz, 70 W | RR AP3 Table I 우주국 | spurious (경계 ±2.75 GHz = 1.5 B_N + 500 MHz; 최소 이격 15.6 GHz) | 61.45 dBc > 60 dBc → **60 dBc** → −11.55 dBm | 4 kHz | 안테나 전송선 (방사 경로는 §4 상한) |
| (감도) 전 TX | ECSS-E-ST-50-05C Table 5-6 | spurious (±2.5 × 점유대역폭 밖) | −60 dBc | 4 kHz | 송신기 출력 |
| (이산 스퍼) 전 TX | CCSDS 401 rec. 2.4.16 | 단일 스펙트럼선 | 단일 스퍼 총전력 ≤ −60 dBc | 없음(선 전체 전력) | 송신기 출력 |

**규격 후보 비교**(근거 유형: 규격 = spec):

| 규격 | 적용 대상 | 피간섭원 대역에서의 적용성 | 보수성(RFI 관점) | 채택 |
|---|---|---|---|---|
| RR AP3 (Rev. WRC-12) / ITU-R SM.329-13 Category A | 모든 우주국 (국제 규제, 우주업무는 설계 한도) | 직접 적용 (spurious) | 허용 방사가 가장 큼 = 가장 보수적 | **1차** |
| ECSS-E-ST-50-05C Rev.2 (2011) Table 5-6 | ECSS 조달 위성 | 적용 (spurious) | S·ISL은 AP3보다 10·17 dB 낮은 방사 | 감도 |
| CCSDS 401.0-B-32 rec. 2.4.16 | CCSDS 준수 원격측정 송신기 | 이산 스펙트럼선 | 이산선에만 해당, PSD 아님 | 이산 스퍼 검토 |
| SFCG Rec. 21-2 (CCSDS 413.0-G-3 경유) | Category A SRS/EESS 하향링크 2.2/8/26 GHz | **OOB 영역 마스크**(±약 5 Rs, 하한 peak PSD 대비 −60 dB) | 피간섭원 대역에 미도달 | 미채택 |
| ITU-R SM.1541 / SM.1539 | OOB 영역 / 경계 | 피간섭원 대역은 spurious | — | 미채택 |
| SM.329 Category B/C/D | 지상 장비 국가 등급 | 우주국 항목 없음 | — | 미채택 |
| 공급사 datasheet | 특정 제품 | 제품 미선정 | — | 미채택(입력되면 AP3 대체) |

- 고조파: 송신 주파수의 2–20배 중 피간섭원 대역에 들어가는 차수는 없다(`domain_and_harmonic_check.csv`). AP3 한도는 고조파를 포함한 모든 spurious 성분에 같이 적용된다.
- AP3 §12(같은 위성의 다른 트랜스폰더 대역 면제)는 피간섭원이 수신기이므로 해당하지 않는다.

## 3. 규격별 source PSD 산출

**결과.** 규격 한도(4 kHz당 전력)를 광대역 등가 PSD로 바꾸면 S-TM·ISL −49.0 dBm/Hz, Ka −47.6 dBm/Hz다. 이산 스퍼는 별도로 유지한다.

변환(산출):
```
감쇠 A [dB]          = min(43 + 10 log P[W], 60)          (AP3: "whichever is less stringent")
4 kHz당 한도 [dBm]   = P[dBm] − A
광대역 등가 PSD      = 4 kHz당 한도 − 10 log10(4000) = 4 kHz당 한도 − 36.02 dB   [dBm/Hz]
```

**B. Source emission (피간섭원 대역 전체에서 평탄)**

| TX | 피간섭원 대역 | 최악 준수 source PSD [dBm/Hz] | 이산 스퍼 한도 [dBm] | 근거 |
|---|---|---|---|---|
| S-TM (36.99 dBm) | L1, L2, L5, S-TC, ISL | **−49.0** (ECSS 감도 −59.0) | −13.0 (AP3/4 kHz), −23.0 (CCSDS) | RR AP3 Table I + §8; SM.329-13 Annex 4 Table 8 |
| ISL (30.0 dBm) | L1, L2, L5, S-TC | **−49.0** (ECSS −66.0) | −13.0 (AP3), −30.0 (CCSDS) | 같음 |
| Ka (48.45 dBm) | L1, L2, L5, S-TC, ISL | **−47.6** (ECSS 동일) | −11.55 (AP3), −11.55 (CCSDS) | 같음 (P > 50 W: 10 log P − 30 dBm) |

해석:
- 광대역 등가 PSD는 "4 kHz마다 한도까지 채운 잡음형 방사"를 뜻한다. 규격을 지키면서 가능한 최악이다.
- 같은 한도를 하나의 이산 스퍼로 쓰면 −13 dBm 단일 톤이 된다. 이 톤은 수신 채널에 들어올 때만 의미가 있으므로 PSD mask가 아니라 2차 수신기 적분에서 다룬다(§9).
- 기준면은 안테나 전송선 공급전력이다. 송신기와 안테나 사이 급전선 손실은 0 dB로 두었다(보수적).
- 계산에 넣은 입력: `output/claude/inputs/tx_emission_sources_claude.csv`. 공유 `data/rfi_psd/tx_emission_masks.csv`는 freeze 상태 그대로(비어 있음) 두었다.

## 4. Victim-band PSD 결과

**결과.** 필터 0 dB에서 CST로 평가된 S-TM·ISL 조합은 모두 기준을 넘는다. Ka와 S-TM → GPS L2/L5는 송신 안테나 응답이 없어 물리 상한으로 계산했고, 상한 기준으로도 크게 넘는다.

결합 계산(산출, CST 시뮬레이션 데이터 기반):
- `피간섭원 포트 PSD = source PSD − 필터 감쇠 + C`, `margin = 허용 PSD − 피간섭원 포트 PSD`(양수 여유, 음수 초과)
- C는 피간섭원 주파수에서 구한다.
  - **CST:** C = G_TX(f_v) + G_RX(f_v) − FSPL(f_v)
  - **상한:** TX 안테나의 해당 대역 응답이 없으면 G_TX 대신 그 안테나를 감싸는 구의 Harrington 최대 지향성 D = (ka)² + 2ka를 쓴다(완전 정합, 최악 지향).
    - KAA: a = 119 mm(직경 220 mm, 높이 ≤ 92.2 mm) → L1 13.7 dBi, S-TC 15.8 dBi, ISL 28.8 dBi
    - S 안테나: a = 53 mm → L2/L5 약 6.5 dBi
  - 26 GHz KAA 패턴은 사용하지 않았다.

**C. RFI 결과 (1차 RR AP3, 필터 0 dB, 대역 내 최악 주파수)**

| TX → 피간섭원 | source PSD [dBm/Hz] | 결합 [dB] | 피간섭원 PSD [dBm/Hz] | 기준 [dBm/Hz] | margin [dB] |
|---|---|---|---|---|---|
| S-TM → 반대편 S-TC (양 방향 동일) | −49.0 | −69.1 (CST) | −118.1 | −177 | **−58.9** |
| S-TM@ZENITH → GPSA_1 / GPSA_2 (L1) | −49.0 | −81.0 / −86.1 (CST) | −130.0 / −135.1 | −178 | −48.0 / −42.9 |
| S-TM@NADIR → GPSA_1 / GPSA_2 (L1) | −49.0 | −105.4 / −103.6 (CST) | −154.5 / −152.6 | −178 | −23.5 / −25.4 |
| S-TM@NADIR / ZENITH → ISL | −49.0 | −88.8 / −88.7 (CST) | −137.8 / −137.7 | −177 | −39.2 / −39.3 |
| S-TM → GPS L2 / L5 | −49.0 | −56.2 ~ −40.0 (상한) | −105.2 ~ −89.0 | −178 | −72.8 ~ −89.0 (상한) |
| ISL → GPSA_1 / GPSA_2 (L1) | −49.0 | −122.2 / −119.7 (CST) | −171.2 / −168.7 | −178 | −6.8 / −9.3 |
| ISL → GPSA_1 / GPSA_2 (L2·L5) | −49.0 | −103.3 ~ −100.7 (CST) | −152.3 ~ −149.7 | −178 | −25.7 ~ −28.3 |
| ISL → S-TC@NADIR / ZENITH | −49.0 | −97.7 / −94.3 (CST) | −146.7 / −143.3 | −177 | −30.3 / −33.7 |
| Ka → GPS L1 | −47.6 | −70.9 ~ −66.0 (상한) | −118.4 ~ −113.6 | −178 | −59.6 ~ −64.4 (상한) |
| Ka → GPS L2 / L5 | −47.6 | −50.9 ~ −43.3 (상한) | −98.4 ~ −90.9 | −178 | −79.6 ~ −87.1 (상한) |
| Ka → S-TC | −47.6 | −44.2 ~ −39.6 (상한) | −91.8 ~ −87.2 | −177 | −85.2 ~ −89.8 (상한) |
| Ka → ISL | −47.6 | −42.6 / −41.6 (상한) | −90.2 / −89.2 | −177 | −86.8 / −87.8 (상한) |

해석:
- **S-TM → 반대편 S-TC가 지배 경로다.** 같은 형식 S 안테나 사이 S-TC 대역 결합(−69 dB)이 크고, S-TC 기준이 엄격하다.
- ISL의 L1 경로는 결합이 −120 dB 수준으로 작아 초과가 10 dB 이내다.
- **Ka 상한의 의미와 한계:**
  - 상한은 "KAA가 저주파에서 크기 한계만큼 이득을 낼 수 있다"는 가정이다.
  - 실제로 KAA는 WR-42 도파관(차단 14.05 GHz)으로 급전된다(datasheet). L/S 대역은 차단 주파수의 0.7배 아래라 전파되지 않는다.
  - ITU-R SM.329-13 recommends 2.5도 "길이가 차단 파장의 2배 이상인 도파관 구간을 가진 일체형 안테나는 차단 주파수의 0.7배 아래 spurious 측정을 요구하지 않는다"고 명시한다.
  - 이 조건(WR-42 길이 ≥ 2λc = 42.7 mm)이 확인되면 추가 감쇠는 L/S 약 108 dB, ISL 약 72 dB다(산출, 조건부).
  - 그 경우 Ka → L/S margin은 +18 ~ +49 dB(필터 불필요), Ka → ISL은 −15.6 / −16.6 dB(40 dB 필터로 충족)가 된다.
  - 이 조건은 **미확정**이며, 1차 결과는 상한값이다.
- 상세: `results/oob_spurious/pair_margin_summary.csv`(pair × variant), `victim_psd_results.csv`(주파수별).

## 5. TX별 최소 추가 필터 억제량

**결과.** 송신 측 불요방사 억제 요구(RX blocker rejection 아님)는 S-TM ≥ 60 dB, ISL ≥ 40 dB다. Ka는 상한 기준 > 80 dB이며 도파관 조건 확인이 먼저다.

**E. TX별 설계 요약 (1차, 최악 피간섭원 기준)**

| TX | 최악 피간섭원 | 필요 추가 억제량 [dB] | 권장 screening 필터 범주 | 근거 |
|---|---|---|---|---|
| S-TM | 반대편 S-TC (2025–2110 MHz) | **58.9** | **≥ 60 dB** (여유 1.1 dB, 실설계는 70 dB 범주 권장) | CST |
| S-TM (GPS L2/L5) | GPSA_1 L5 | 89.0 (상한) | > 80 dB 상한 — S 안테나 L2/L5 응답 확보 후 재평가 | 상한 |
| ISL | S-TC@ZENITH | **33.7** | **≥ 40 dB** | CST |
| Ka | S-TC@NADIR (KAA_2) | 89.8 (상한) | **> 80 dB / 별도 설계 검토**. WR-42 ≥ 2λc 확인 시 ISL 경로만 ≥ 40 dB | 상한 |

- S-TM에 60 dB 필터를 쓰면 여유가 1.1 dB뿐이다. 결합의 CST 모델 불확도와 설치 영향을 고려하면 70 dB 범주가 안전하다(판단).
- ECSS 감도에서는 S-TM 48.9 dB(60 dB 범주 유지), ISL 16.7 dB(40 dB 범주 유지)다.

## 6. 0/40/60/70/80 dB scenario 결과

**결과.** S-TM은 60 dB, ISL은 40 dB에서 모든 CST 평가 조합이 기준을 충족한다. Ka 상한 조합 18개 중 80 dB 이하에서 충족하는 것은 GPS L1 4개(60 dB 1개, 70 dB 3개)와 KAA_2 → GPS L2 2개(80 dB)다. 나머지 12개는 80 dB로도 부족하다.

**D. 필터 요구 (1차)**

| TX → 피간섭원 | 0 dB margin [dB] | 필요 추가 억제량 [dB] | 처음 충족하는 scenario | 40 / 60 / 70 / 80 dB |
|---|---|---|---|---|
| S-TM → 반대편 S-TC | −58.9 | 58.9 | 60 dB | 초과 / 충족 / 충족 / 충족 |
| S-TM@ZENITH → GPSA_1 / GPSA_2 (L1) | −48.0 / −42.9 | 48.0 / 42.9 | 60 dB | 초과 / 충족 / 충족 / 충족 |
| S-TM@NADIR → GPS L1 | −23.5 / −25.4 | 25.4 | 40 dB | 충족 ×4 |
| S-TM → ISL | −39.3 | 39.3 | 40 dB (여유 0.7) | 충족 ×4 |
| S-TM@NADIR → GPS L2/L5 (상한) | −72.8 ~ −75.7 | 75.7 | 80 dB | 초과 / 초과 / 초과 / 충족 |
| S-TM@ZENITH → GPS L2/L5 (상한) | −84.1 ~ −89.0 | 89.0 | 없음 (80 dB 초과) | 초과 ×4 |
| ISL → GPS L1 | −6.8 / −9.3 | 9.3 | 40 dB | 충족 ×4 |
| ISL → GPS L2/L5 | −25.7 ~ −28.3 | 28.3 | 40 dB | 충족 ×4 |
| ISL → S-TC | −30.3 / −33.7 | 33.7 | 40 dB | 충족 ×4 |
| Ka → GPS L1 (상한) | −59.6 ~ −64.4 | 64.4 | 60 dB (KAA_2 → GPSA_1) ~ 70 dB | 초과 / 일부 충족 / 충족 / 충족 |
| Ka → GPS L2/L5 (상한) | −79.6 ~ −87.1 | 87.1 | 80 dB (KAA_2 → L2만) / 나머지 없음 | 대부분 초과 |
| Ka → S-TC, ISL (상한) | −85.2 ~ −89.8 | 89.8 | 없음 | 초과 ×4 |

- "처음 충족하는 scenario"는 정의된 screening 감쇠(0/40/60/70/80 dB) 중 최소값이다. 실제 필요량은 "필요 추가 억제량" 열이다.
- 전체 표: `results/oob_spurious/pair_margin_summary.csv`. 열 `minimum_required_additional_suppression_db`, `first_passing_scenario`, `FILTER_40DB` … `FILTER_80DB`.

## 7. Receiver criterion

**결과.** freeze point 기준을 그대로 썼다. 1차 판정은 수신 tuning 대역 전체의 PSD mask다.

| 수신기 | 판정 대역 | 허용 간섭 PSD [dBm/Hz] | 근거 유형 |
|---|---|---|---|
| GPS L1 / L2 / L5 | 1563–1588 / 1217.37–1237.83 / 1164–1189 MHz | −178 | 가정(engineering baseline): NF 2 dB, I/N −6 dB |
| S-TC | 2025–2110 MHz | −177 | 가정: NF 3 dB, I/N −6 dB |
| ISL | 10.55–10.65 GHz | −177 | 가정·잠정 |

- 채널 적분(2차)은 이산 스퍼 검토(§9)에만 썼다.
- 적분 대역폭: S-TC 5.53 kHz(engineering baseline), GPS 20.46 MHz(가정), ISL 20 MHz(잠정).

## 8. 입력·모델 한계

**결과.** 결론을 바꿀 수 있는 미확정 입력은 다섯 가지다. 0이나 임의 이득으로 대체하지 않았다.

1. **실제 송신기 사양(미확정):** AP3는 법적 상한이다. 실제 S/X/Ka 송신기는 보통 이보다 낮다. 공급사 spurious 사양(RBW·기준면 포함)이 오면 같은 엔진에서 1차 source를 바꾼다.
2. **KAA 저주파 방사(미확정):** KAA의 S/L/X 응답이나 WR-42 구간 길이가 없다. Ka 결과는 물리 상한이고, 도파관 조건이 확인되면 결론이 "필터 불필요(L/S)"로 바뀔 수 있다.
3. **S 안테나 L2/L5 응답(미확정):** CST 정규화가 불안정해 쓰지 않았다. S-TM → GPS L2/L5는 상한값(최대 89 dB 요구)이다.
4. **필터(미확정):** screening 감쇠만 있다. 실제 필터 table을 넣으면 주파수별로 계산된다.
5. **모델 한계(가정):**
   - 결합은 자유공간 CST 시뮬레이션 데이터다(두 컷 근사, 구조 산란 없음).
   - 급전선 손실 0 dB, 편파 손실 없음(모두 보수 방향).
   - 광대역 등가 PSD는 잡음형 spurious 가정이다.
   - 수신기 기준은 engineering baseline이다.

## 9. Secondary: 이산 스퍼 및 blocker

**이산 스퍼(2차, 수신 채널 내에 떨어질 때만):**
- 규격 한도의 단일 톤을 최대 결합으로 피간섭원 포트에 놓고, 채널 적분 허용 전력과 비교했다(`discrete_spur_check.csv`).
- S-TM → 반대편 S-TC:
  - AP3 톤 −82.1 dBm vs 허용 −139.6 dBm(5.53 kHz) → **−57.5 dB**
  - CCSDS 2.4.16 톤 −92.1 dBm → −47.5 dB
- S-TM@ZENITH → GPSA_1: AP3 −10.9 dB, CCSDS −0.9 dB(20.46 MHz 가정 기준).
- 톤의 주파수는 규격에서 정해지지 않으므로 이 결과는 "채널에 들어오면"이라는 조건부 위험이다. 필터 요구는 광대역 PSD 결과(§5)로 정했다.

**기본파 대역 밖 blocker(`SECONDARY_OOB_BLOCKER_ANALYSIS`):**
- 기존 값을 유지했다: S-TM@ZENITH → GPSA_1 **−21.3 dBm** @ 2.25 GHz, S-TM → 반대편 S-TC **−32.3 dBm** @ 2.25 GHz.
- 수신기 프리셀렉터·블로킹·P1dB가 없어 최종 판정 보류다.
- 이번 필터 요구는 이 결과에서 도출하지 않았다. 상세: `results/oob_blocking_results.csv`.

## Appendix A. 규격 근거 (1차 출처 원문 확인)

| 문서 | 판 | 조항 | 확인 내용 |
|---|---|---|---|
| ITU Radio Regulations Vol.2, Appendix 3 | Edition 2020, AP3 Rev. WRC-12 | §8 | "The reference bandwidth of all space service spurious domain emissions should be 4 kHz." |
| 〃 | 〃 | Table I, note 10, P·dBc 정의 | "Space services (space stations): 43 + 10 log (P), or 60 dBc, whichever is less stringent". P = 안테나 전송선 평균전력. dBc = 무변조 반송파 대비 |
| 〃 | 〃 | §2, §10, §11, Example 2 | 안테나 외 부분의 방사는 안테나에 한도 전력을 공급한 효과 이하. e.i.r.p. 방법은 안테나가 spurious 영역에서 큰 감쇠를 주도록 설계된 경우 사용. 고조파 포함. 20 W 예 → −43 dBW/4 kHz |
| 〃 | 〃 | Annex 1 Table 1 | 경계 2.5 B_N. wideband: 1–3 GHz B_N > 50 MHz, 10–15 GHz B_N > 250 MHz, > 26 GHz B_N > 500 MHz에서 1.5 B_N + (50/250/500) MHz |
| Rec. ITU-R SM.329-13 | 09/2024 | recommends 4.1, Table 2 notes (2)(3), Annex 4 Table 8, recommends 2.5, Annex 1 §1.1.2 | 4 kHz(space); 절대값 −13 dBm(P ≤ 50 W) / 10 log P − 30 dBm(P > 50 W); 도파관 ≥ 2λc 일체형 안테나는 0.7 f_c 아래 측정 불요; 설계대역 밖 안테나 특성 미지 |
| ECSS-E-ST-50-05C | Rev.2 2011-10-04 (Rev.1 2009-03-06 동일) | 5.5.1.1a, Table 5-6 | "−60 dBc, measured in a reference bandwidth of 4 kHz", 반송파 100–40 500 MHz |
| CCSDS 401.0-B-32 | Blue Book Oct 2021, rec. 2.4.16 B-2 (Oct 2004) | 2.4.16 | "the total power contained in any single spurious emission shall not exceed −60 dBc" |
| CCSDS 413.0-G-3 | Feb 2018 | §2.2, Annex B | SFCG 21-2R4 mask: Category A 2200–2290 / 8025–8400 / 8450–8500 MHz, 25.5–27 GHz(Rs ≥ 10 Ms/s, 2020 이후). mask floor −60 dB(peak PSD 대비) |

- 출처 URL: [RR 2020 Vol.2](https://eclass.uoa.gr/modules/document/file.php/LAW835/RR-2020-00013-Vol.II-EA5.pdf), [SM.329-13](https://www.itu.int/dms_pubrec/itu-r/rec/sm/R-REC-SM.329-13-202409-I!!PDF-E.pdf), [ECSS-E-ST-50-05C Rev.1](https://ecss.nl/wp-content/uploads/standards/ecss-e/ECSS-E-ST-50-05C_Rev.16March2009.pdf), [ECSS-E-ST-50-05C Rev.2](https://everyspec.com/ESA/download.php?spec=ECSS-E-ST-50-05C_REV-2.048184.pdf), [CCSDS 401.0-B-32](https://ccsds.org/Pubs/401x0b32.pdf), [CCSDS 413.0-G-3](https://ccsds.org/Pubs/413x0g3e1.pdf).
- 규격 비교 전체: `results/oob_spurious/standards_survey.csv`.

## Appendix B. 산출물·재현·provenance

- **결과**(`output/claude/results/oob_spurious/`):
  - `standards_survey.csv`, `source_emission_derivation.csv`, `domain_and_harmonic_check.csv`
  - `pair_margin_summary.csv`(1차·ECSS·WR-42 조건부 variant), `victim_psd_results.csv`
  - `tx_filter_requirement.csv`, `discrete_spur_check.csv`
  - `validation_log.txt`, `test_suite_log.txt`, `freeze_record.txt`, `run_log.txt`
- **입력:** `output/claude/inputs/tx_emission_sources_claude.csv`(worker 독립 사본). 공유 엔진(`src/+rfscreen/+psd`)과 공유 데이터는 변경하지 않았다.
- **재현**(저장소 루트):
  ```
  octave-cli --no-gui --norc --eval "run('output/claude/run_oob_spurious_analysis.m')"
  octave-cli --no-gui --norc --eval "run('output/claude/validate_oob_spurious.m')"
  ```
- **provenance:**
  - freeze point `8469e89`에서 만든 독립 branch에서 분석했다. 시작 시 작업트리는 clean이었다(`freeze_record.txt`).
  - 실행 기준 commit은 `results/run_provenance.csv`, 저장 commit은 `git log -- output/claude`로 확인한다.
  - 다른 worker의 결과는 읽지 않았다.
- 프레임워크 정리판(freeze point 시점)의 내용은 `RFI_분석근거.md` §11–§12와 기존 `results/*.csv`에 그대로 있다.
