<!-- actual-role-labels-applied -->

# RFI 간섭 해석 결과 보고서

기존 Codex 산출물 기준: 2026-10-04. 이번 개정은 구성·표현만 정리했으며 계산값과 분석 범위를 유지했다. 작성 규칙은 [공통 guide](../../docs/REPORTING_GUIDE.md)를 따른다.

## 1. Executive Summary

**전체 RFI 적합성은 최종 판정 보류다.** 6개 조합 × 3개 활성 시나리오의 252개 경로 행 중 132개는 기본파 전력 계산을 완료했고, 120개는 송신 주파수에서의 수신 안테나 응답 미확보로 계산하지 못했다. 개수는 시나리오별 반복 행을 포함한다.

대표 최대 필터 전 입력은 **S-TC TX zenith → GPSA_1의 −21.317 dBm**이다. 이는 송신 기본파가 수신 포트에 도달하는 적분 전력이며 GPS 대역 불요방사 PSD가 아니다. 수신 대역 내 허용치와의 차이는 **83.549 dB**, 대표 S-TC TX → 반대편 S-TM RX의 차이는 **91.677 dB**다. 이 차이는 실제 필터 요구 규격을 확정한 값이 아니라 진단용 screening 값이다.

계산된 경로는 기본파와 이상 수신 필터 대역이 겹치지 않아 모델상 필터 후 기본파 간섭이 **0 W**다. 실제 emission·스퍼·고조파와 수신기 blocking 성능은 미평가이므로 전체 PASS나 실제 무한 margin으로 해석할 수 없다.

## 2. 주요 RFI 결과 / 요구 억제도 / margin

기존 `CASE_SBA1_L1`의 전체 TX 동시 활성 결과에서 최대 입력과 최대 진단용 차이를 각각 제시한다. 원본은 [rfi_pairs.csv](rfi_pairs.csv)다.

| 대표 경로 | 필터 전 적분 전력 (dBm) | 허용치와의 차이 (dB) | 적용 한계 |
|---|---:|---:|---|
| S-TC TX zenith → GPS L1 / GPSA_1 | −21.317 | 83.549 | 원거리 조건 충족 |
| S-TC TX → 반대편 S-TM RX (양방향 동일) | −32.288 | 91.677 | 구조물 교차 효과는 전력에 미반영 |
| Ka / KAA_1 → ISL RX | −44.945 | 59.020 | 원거리 조건 미충족, 자유공간 가정 |

확보 경로의 대표값이며 미계산 경로가 더 안전하다는 뜻은 아니다. Ka는 frozen reflector reference gain을 사용했고 mismatch가 미확인이다. Claude의 근거리 결과를 적용하지 않았다. 실제 RFI margin은 미판정이며 이상 모델의 0 W를 유한한 장비 여유값으로 바꾸지 않는다.

## 3. Victim-band PSD 결과

**실제 불요방사의 victim-band PSD는 이번 Codex 산출물에서 평가하지 않았다.** 기존 실행은 직사각형 기본파 PSD와 이상 bandpass 모델이다. 기본파 비중첩은 수신 tuning 대역의 emission mask 평가를 대신하지 않는다.

실제 victim-port PSD와 PSD margin을 얻으려면 기준면이 명시된 emission mask/스퍼·고조파 및 victim 주파수의 TX/RX 결합 응답이 필요하다. 현재 작업 디렉터리에 추가된 입력을 과거 실행에 사용했다고 간주하지 않는다.

## 4. Receiver criterion

기존 계산은 290 K, 수신 대역폭 B, NF, 최대 I/N 입력으로 수신 대역 내 허용 전력을 정했다. 사용 입력은 [input_snapshot/rf_systems.csv](input_snapshot/rf_systems.csv), 수식은 Appendix A에 있다. 이 기준은 실제 blocker 허용 전력이 아니다.

[receiver_aggregates.csv](receiver_aggregates.csv)는 선형 전력 합산이다. 누락 경로가 있으면 **확보 경로만의 부분 합산**이며 누락 값을 0 W로 채워 전체 통과로 판정하지 않았다. GNSS 최종 C/N0·J/S 및 실제 blocking·compression·상호변조 기준은 미평가다.

## 5. Filter / suppression requirement

**실제 필터 요구 억제도는 미확정이다.** 2절은 `max(0, 필터 전 적분 전력 − 수신 대역 내 허용치)`라는 진단용 차이다. 서로 다른 평가 대역을 비교하므로 검증된 RX 대역 외 rejection 요구 규격이나 필터 성능으로 사용하지 않는다.

TX 불요방사 억제 요구에는 victim-band emission과 PSD 기준이 필요하다. RX blocker rejection 요구에는 blocker 주파수의 필터 응답과 blocking/P1dB 등 한계가 필요하다. 이번 결과만으로 둘을 확정할 수 없다.

## 6. 입력 누락 및 분석 한계

**120개 경로는 S·L 안테나의 Ka 대역 응답과 L 안테나의 ISL 대역 응답 부족으로 계산 보류다.** 자기 운용 대역 패턴이나 임의 이득으로 대체하지 않았다.

| 송신 대역 | 전체 경로 행 | 전력 계산 완료 | 응답 미확보 | 확보 경로 최대 입력 (dBm) |
|---|---:|---:|---:|---:|
| S-TC TX | 84 | 84 | 0 | −21.317 |
| ISL | 60 | 24 | 36 | −58.882 |
| Ka | 108 | 24 | 84 | −44.945 |

출처는 [band_summary.csv](band_summary.csv)다. 계산 완료는 기본파 전력 계산 완료이며 적합 판정 완료가 아니다.

자유공간 패턴을 우선했고 승인된 설치 패턴은 사용하지 않았다. 두 방향 컷으로 임의 방위를 근사했으므로 완전 3D·실측·mesh 수렴 결과가 아니다. 구조물 교차 경로는 차폐 dB를 적용하지 않은 추정이며 엄밀한 상한이 아니다. Ka 지향은 설치 기준값이며 가동 범위 worst case 탐색과 근거리 solver 해석은 이 결과에 포함되지 않는다. 실제 emission과 전단 한계 미확보로 최종 판정은 보류다.

## 7. Secondary blocker analysis

**전단 보호 검토의 대표 우선 경로는 S-TC TX zenith → GPSA_1이다.** 필터 전 입력은 blocker 노출 screening이며 실제 감도 저하를 계산한 값이 아니다. 판정에는 선택도·blocking·compression·상호변조 자료가 필요하다.

6개 조합에서 반복되는 최대 입력을 시나리오별로 축약했다. 전체 동시 활성은 screening 가정이며 잠정 모드는 확정 운용 일정이 아니다.

| 활성 시나리오 | 조합당 전체/계산/미계산 경로 행 | 최대 확보 입력 (dBm) |
|---|---|---:|
| 전체 TX 동시 활성 | 22 / 12 / 10 | −21.317 |
| nadir S-TC TX · KAA_1 잠정 모드 | 10 / 5 / 5 | −42.314 |
| zenith S-TC TX · KAA_2 잠정 모드 | 10 / 5 / 5 | −21.317 |

원본 18행과 활성 ID는 [case_summary.csv](case_summary.csv), [case_pattern_evidence.csv](case_pattern_evidence.csv)에 있다. 공통 최대값만으로 모든 pair나 GPS 대역별 기준이 같다고 해석하지 않는다.

SAR는 패턴 미결합으로 실제 송수신 절대 RFI가 미평가다. 8.9/9.65/10.4 GHz에서 S/ISL 응답과 방향 EIRP=0 dBm당 전달량을 평가한 민감도 90행만 [sar_response_sensitivity.csv](sar_response_sensitivity.csv)에 있다. L 응답은 미확보다. 실제 SAR 이득·전력·mask를 넣은 간섭값이 아니며 SAR 크기 미확정에 따른 자유공간 가정도 있다.

## 8. Appendix / detailed validation

아래 검증은 기존 실행의 기록이며 이번 문서 개정에서 재실행한 결과가 아니다.

원본 enum은 다음 의미로 읽는다. `INPUT_MISSING`은 해당 TX 주파수의 RX 패턴 미확보로 계산 보류, `INCOMPLETE_MISSING_RESPONSES`는 확보 경로만 부분 합산이다. `IDEAL_FILTER_NO_FUNDAMENTAL_OVERLAP`은 이상 필터에서 기본파 비중첩을 뜻한다. 여기에 `REFERENCE_GAIN_MISMATCH_UNKNOWN`이 붙으면 Ka 참조 이득 mismatch도 미확인이다. `FAR_FIELD_VALID`은 원거리 조건 충족, `FREE_SPACE_ASSUMED`는 조건 미충족 상태의 자유공간 가정이다. `CLEAR/BLOCKED`는 구조물 교차 유무이며 차폐 dB와 별개다.

상세 조회는 [분석근거.md](분석근거.md)를 따른다. [rfi_pairs.csv](rfi_pairs.csv)의 `case_id`, `mode_id`, `tx_id`, `rx_id`가 경로 조회 키다. [frequency_direction_evidence.csv](frequency_direction_evidence.csv)는 실제 주파수·방향 이득·출처, [band_availability.csv](band_availability.csv)는 응답 가용성, [legacy_engine_reference.csv](legacy_engine_reference.csv)는 기존 비교 결과를 보존한다. [input_hash_manifest.csv](input_hash_manifest.csv)와 [input_snapshot/](input_snapshot/)는 기존 실행의 provenance다. 실행·검증 기록은 [run_metadata.json](run_metadata.json), [validation.json](validation.json), [octave_tests.log](octave_tests.log), [octave_execution.log](octave_execution.log)에 있다.

### A. 모델과 패턴 선택

- 케이스는 SBA1/SBA4 × GPS L1/L2/L5. 설치 위치는 nadir/zenith, GPSA1/2, KAA1/2, ISL을 각각 유지했다. S는 TM TX와 TC RX, L은 RX만, Ka는 TX만, ISL은 TX/RX다.
- SCREENING_ALL_TX는 등록된 모든 TX/RX 동시 활성 가정이다. NOM_NADIR_KAA1 / NOM_ZENITH_KAA2는 기존 임시 운용 정의이며 확정 운용 일정이 아니다. 활성 ID와 패턴 매핑은 `case_pattern_evidence.csv`에 기록했다.
- 승인된 installed pattern이 없으므로 자유공간을 우선했다. 작은 구조물의 S 잠정 설치 결과를 최종 패턴으로 사용하지 않았으며 추가 CST를 실행하지 않았다.
- baseline frozen 패턴은 56개 파일의 hash를 검증했다. 기존 엔진 결과는 `legacy_engine_reference.csv`에 비교용으로 보존했다. baseline 재구성 격자는 10°로 명시했으며 주 결과는 원래 1° 컷에서 실제 결합 방향을 직접 평가했다.
- 주 결과에서 S/L/ISL은 해당 TX 대역의 CST total RealizedGain을 사용했다. SBA1/SBA4의 frozen 참조 패턴 구분은 유지하되, 물리 CST S 형상이 공통이므로 이 경로의 주 계산값이 variant에 따라 동일할 수 있다. 제품 간 실측 차이를 해석했다고 주장하지 않는다.
- Ka TX는 frozen reflector reference gain을 사용했다. 이 자료를 total RealizedGain으로 재분류하지 않았다. Ka 포함 경로는 mismatch 미확인 상태의 혼합 reference screening이다. feed-only 결과로 reflector를 대체하지 않았다.
- 모든 방향 이득은 두 컷의 주기적 theta 보간 및 기존 `CutPatternAssembler.reconstructGain`을 이용한다. 임의 방위는 두 컷의 근사이며 완전 3D/측정/mesh 수렴 결과가 아니다. 지향은 현재 설치 기준값이며 Ka gimbal 가동 범위 최악 탐색은 수행하지 않았다.

### 계산 근거

좌표는 기존 `AntennaToAntennaFOV.relativeGeometry`와 local-to-body 회전을 사용했다. 원본 +Z에서 내부 antenna +X로의 변환은 `canonicalToAntenna`로 한 번만 적용했다. TX→RX 방향과 RX→TX 방향을 각각 평가했다. 최대 이득을 방향 이득 대신 쓰지 않았다.

각 주파수에서 λ=c/f, FSPL=20 log10(4πd/λ), S21=Gtx+Grx−FSPL을 계산했다. TX 포트 기준 PSD에 10^(S21/10)을 곱해 선형 W로 적분했고, 필터 뒤에는 추가로 Hrx(f)를 한 번 곱했다. 64→128 구간 midpoint 적분의 최대 변화는 5.55649e-06 dB로 0.1 dB 이내다. 서로 다른 계산 대역 사이의 gap 보간은 하지 않았다. RealizedGain에는 mismatch를 다시 차감하지 않았다. 별도 polarization 손실은 입력 근거가 없어 적용하지 않았다.

허용치=10 log10(k·290·B·10^(NF/10))+30+I/N_max. 필요한 광대역 거부량=max(0, 필터 전 적분 수신전력−허용치)다. 이 값은 요구 거부량 screening이며 실제 필터의 성능이나 blocking/P1dB 허용치를 뜻하지 않는다.

원거리 유효성은 기존 `FarFieldCouplingModel`의 양 안테나 2D²/λ와 5λ 조건을 사용했다. 미충족이면 FREE_SPACE_ASSUMED로 표시했다. LOS와 구조물 교차도 기록했지만 구조물에 임의 차폐 dB를 부여하지 않았다. BLOCKED 경로의 자유공간 수치는 구조효과 미포함 추정이며 엄밀한 상한 또는 측정된 결합으로 표현하지 않는다.

### B. 검증과 재현

- Octave 관련 테스트: 57 assertions 통과, 0 실패 (`octave_tests.log`). 전체 테스트 suite 실행을 주장하지 않는다.
- 입력 frozen 56개 hash 불변, 역할/자기 설치 제외/전력 수식/대역별 적분 refinement 검증 PASS (`validation.json`).
- 원본 컷에서 기록된 방향·주파수 이득을 독립 재구성해 대조한 최대 오차는 1.83826e-10 dB였다. 필터 전 선형 합산도 별도 대조했다.
- `frequency_direction_evidence.csv`는 64구간 검증 grid의 8448행이다. 최종 적분값은 128구간이고 두 grid 차이는 pair CSV에 기록했다. 샘플 컷 출처와 전체 보간 방법은 동일하다.
- 재실행: Octave에서 repo를 현재 디렉터리로 두고 `addpath('output/codex'); run_rfi_octave; run_rfi_octave('sar');` 실행. 이어 Python으로 `output/codex/build_report.py` 실행. 런타임 파일 경로는 `README.md`에 기록했다.
- `input_snapshot/`은 사용한 spacecraft 설정과 manifest 복사본이다. 원본 패턴·코드·CST 상태 hash는 `input_hash_manifest.csv`에 기록했다. 변경이 있으면 같은 결과의 재현으로 보지 않는다.
