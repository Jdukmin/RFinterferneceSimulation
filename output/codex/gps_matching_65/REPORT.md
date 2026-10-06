# GPS L1·L2·L5 매칭 개선 결과

새 engineering surrogate는 기존 4포트 합성 급전 조건에서 L1·L2·L5의 전력 수용률 65% 요구를 모두 만족했다. 최종 CST 2026 계산의 평가대역별 최저 수용률은 L1 **66.40%**, L2 **81.80%**, L5 **73.66%**이다. 별도 CST 프로젝트로 생성했으며 기존 accepted 모델과 closed-network 22개 프로젝트는 보존했다.

| 대역 | 평가 범위 [MHz] | 기존 중심주파수 수용률 [%] | 개선 중심주파수 수용률 [%] | 개선 대역 최저 수용률 [%] |
|---|---|---:|---:|---:|
| GPS L1 | 1563–1588 | 1.34 | 67.90 | **66.40** |
| GPS L2 | 1217.37–1237.83 | 53.48 | 83.82 | **81.80** |
| GPS L5 | 1164–1189 | 52.85 | 74.50 | **73.66** |

중심주파수는 각각 1575.42, 1227.60, 1176.45 MHz이다. 실제 GPS L2를 사용했으며 기존 1207 MHz proxy로 대체하지 않았다. 평가 범위는 `data/rfi_psd/receiver_baseline.csv`의 engineering baseline이다. 대역 최저값은 CST의 저장 주파수 샘플과 정확한 대역 경계의 복소 S 보간으로 평가했다.

전력 수용률은 전체 입사 전력 중 네 포트로 되돌아가지 않고 안테나에 수용되는 비율이다. 방사효율이나 실물 수신기 성능을 의미하지 않는다. 중심주파수의 매칭 손실은 L1 1.68 dB, L2 0.77 dB, L5 1.28 dB로 감소했다. 특히 L1은 기존 18.72 dB의 매칭 손실이 크게 줄었다.

## 변경한 형상

공진 위치와 결합을 조정하기 위해 두 패치의 직경, 패치 간격과 급전 반경을 변경했다. 부품·형상을 새로 추가하지 않았으며 외경, cup/choke 형상, 재료, 프로브 굵기와 높이, 포트 임피던스, 합성 급전 위상은 유지했다.

| 항목 | 기존 [mm] | 개선 [mm] |
|---|---:|---:|
| 하부 구동 패치 직경 | 140 | 130 |
| 상부 결합 패치 직경 | 123 | 93 |
| 패치 간격 | 12 | 6 |
| 급전 반경 | 35 | 45 |

이 치수는 독립 CST 최적화로 얻은 engineering surrogate 입력이며 제조사 공개 CAD나 실측 치수로 주장하지 않는다. 안테나 좌표계는 기존 original 모델과 같은 local +Z이다.

## 판정 방법 및 검증

포트 기준 임피던스는 모두 **50 Ω**, 입사 진폭은 동일하며 위상은 기존 `[0, −90, −180, −270]°`를 유지했다. 임피던스 기준값 변경, 손실성 흡수체 추가, 패턴 정규화로 수용률을 높인 것이 아니다.

`aᵢ = exp(jφᵢ)`, `b = S a`

`ηaccepted = 1 − (bᴴb)/(aᴴa)`

`매칭 손실 = −10 log₁₀ηaccepted`

탐색에는 동일한 네 사분면 형상의 회전대칭을 이용했지만 최종 판정은 **4포트 모두 실제로 여기한 4×4 복소 S-matrix**로 수행했다. 최종 계산은 1001개 주파수 샘플, 62,208 mesh cells, Time Domain solver의 −40 dB 종료 기준을 사용했으며 solver error는 없었다. 평가대역의 최대 수동성 초과량은 −0.00336으로, 해당 샘플에서는 수동성 위반을 검출하지 않았다.

최종 검증 항목은 다음과 같다.

- 세 평가대역의 최저 수용률 65% 이상.
- 저장 S-matrix로 합성 반사계수 재현 및 전력 수지 확인.
- PEC solid 11개, 50 Ω 포트 4개, far-field monitor 9개 확인.
- 세 중심주파수의 RAW XZ/YZ CSV 6개, 각각 360개 각도 및 유한한 gain 값 확인.
- 기존 accepted 프로젝트·geometry JSON·공유 generator·spec의 hash 보존 확인.
- CST 2024 재생성 매크로에 solver 자동 실행 및 결과 생성 전 CombineResults 호출이 없음.

## 사용할 파일과 적용 한계

로컬 CST 프로젝트는 [GPS_TRIBAND_MATCH65.cst](validated_candidate/GPS_TRIBAND_MATCH65.cst)이다. 폐쇄망 CST 2024에서는 새 Microwave Studio 프로젝트에 [build_2024.vba](validated_candidate/build_2024.vba)를 실행한 뒤 geometry·port·monitor·mesh를 확인하고 native `.cst`로 저장한다. 실행 절차는 [README](validated_candidate/README.md)에 기록했다. CST 2024에서 실제 재생성·solver 실행을 검증한 것은 아니다.

최종 RAW 패턴은 `validated_candidate/f*_RAW_RealizedGain_XZ.csv` 및 `..._YZ.csv`에 별도로 보존했다. gain은 dBi이며 clipping이나 임의 floor를 적용하지 않았다. 복소 field는 기존 CST 추출기의 원시 정규화를 유지했다. 이 신규 패턴을 기존 RFI baseline이나 installed 패턴에 자동으로 덮어쓰지 않았다.

이번 결과는 원래 안테나의 매칭 개선에 대한 로컬 EM 계산 결과다. mesh 수렴, 실물 측정, 실제 급전망, 편파 성능의 요구규격 충족 및 위성체 설치 영향은 별도 검증이 필요하다. 동일 진폭·위상으로 여기한 네 안테나 포트의 수용률을 실제 단일 입력 급전망의 S11로 해석하지 않는다.

## Appendix — 정밀값과 provenance

- [대역별 비교 CSV](matching_summary.csv)
- [최종 계산·검증 JSON](validated_candidate/validation.json)
- [복소 S-matrix](validated_candidate/s_matrix.npz) 및 [전체 매칭 sweep](validated_candidate/matching_sweep.csv)
- [실제 solver log](validated_candidate/solver_Model.log)
- [숫자 형상·포트·classic history](validated_candidate/source_geometry.json)
- [기존 입력 hash](source_snapshot.json)
- 후보 탐색 근거: `candidate_screening.json`, `refined_patch_screening.json`, `refined_screening.json`, `best_candidate.json`.

기존 입력 snapshot의 저장소 기준은 `63dd5b42cb57298fd8126a11022ff987b0ddc140`이다. 수치와 판단은 Codex의 독립 산출물이며 다른 worker 보고서에서 복사하지 않았다.
