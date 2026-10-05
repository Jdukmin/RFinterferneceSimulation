# 폐쇄망 MATLAB RFI 실행 매뉴얼

10개 pair와 Original/Installed 및 KAA Feed-only/Reflector 비교를 위한 실제 실행 파일을 `analysis/closed_network/`에 추가했다. **현재 CST 결과가 없고 6개 필수 project 원본도 미확보이므로 수치 분석을 실행하지 않았다.** Missing 결과를 기존 패턴으로 채우지 않는다.

## STEP 1 — RAW CST 결과 복사

`docs/closed_network_cst_project_inventory.csv`의 expected_output_directory를 사용한다. `data/closed_network_patterns/<dataset_id>/` 안에 각 frequency의 `f2.200000_XZ.csv` 형태 RAW export, provenance.json, S-matrix와 solver/convergence evidence를 넣는다. Installed SBA는 NADIR/ZENITH, GPS는 GPSA1/GPSA2별 독립 directory다. Free-space/installed 원본을 합치지 않는다.

## STEP 2 — Validation

```powershell
python analysis/closed_network/register_closed_network_patterns.py
```

`SOLVED_ACCEPTED`, RealizedGain/dBi, convergence acceptance, 세 frequency의 accepted-power normalization을 확인한다. 각 cut은 theta 0…359°, 360개 unique angle, finite realized_gain_dbi여야 한다. NaN/Inf/duplicate/missing angle을 조용히 건너뛰지 않는다. XZ는 phi0/180, YZ는 phi90/270이고 +Z_CST가 boresight다. 원본 angle convention/port phase와 출처 metadata를 확인한다.

Accepted-power Gain과 RealizedGain을 바꿔 쓰지 않는다. RealizedGain에는 mismatch가 이미 포함되어 별도 port mismatch나 S11 감쇠를 다시 적용하지 않는다. Complex fields와 CP±는 RAW에 남긴다. Registration은 단위를 추측하거나 gain floor를 만들지 않는다.

## STEP 3 — 별도 dataset 등록

Registration은 RAW를 수정하지 않고 각 directory의 `registered/` 아래 2-column theta,gain import view를 만든다. `data/closed_network_patterns/registry.json`에 dataset_id, configuration_id=`CN_<dataset_id>`, pattern_class, installation_id, frequencies, frame와 RAW hash를 기록한다. 기존 frozen data/Sband_TMTC, Lband_GPS, Xband_ISL, Kaband_KAA_CST를 덮어쓰지 않는다.

`cn_load_pattern.m`은 실제 repository classes를 사용한다.

- `rfscreen.patterndata.SourceCoordinateConvention`
- `rfscreen.patterndata.CsvPatternImporter(...).importCut()`
- `rfscreen.kaa.CstLocalFrameAdapter.localToAntenna()`
- `rfscreen.kaa.KaVictimResponse.cutGain(...)`
- `rfscreen.antenna.PatternGrid`
- Original/Feed-only/Feed-with-reflector → `rfscreen.antenna.FreeSpacePattern`
- Installed → `rfscreen.antenna.InstalledPattern(...,'CST',opts)`

Two-cut assembled grid의 provenance는 APPROX_FROM_CUTS다. True full 3D라고 표시하지 않는다. Generic CutPatternAssembler와 CST local roll map은 다르므로 이 loader는 기존 CstLocalFrameAdapter를 적용한다. Source cut +Z와 repository antenna +X를 한 번만 변환한다.

## STEP 4 — Binding / config 선택

기존 `MissionCaseBuilder.buildCase`는 `data/spacecraft/simplified_spacecraft_v1/pattern_bindings.csv`, `antenna_functions.csv`, `installed_patterns.csv`를 읽는다. 기존 mission 함수 selector는 CASE_SBA_TC/CASE_SBA_TM, CASE_GPS, FIXED_<pattern_key>이며, 설치 패턴은 function_id/config_id로 registerInstalledPatterns에서 선택된다. 그 baseline은 6개 legacy mission case이며 SAR는 NONE/DEFERRED다. 이를 10개 RFI pair의 새 CST 데이터와 동일하다고 가정하지 않는다.

이번 준비는 shared loader의 의미를 바꾸거나 기존 baseline CSV를 수정하지 않는다. 실제 closed-network 실행은 **`analysis/closed_network/rfi_plan.json`**의 tx_dataset/rx_dataset 및 tx_configuration/rx_configuration을 사용한다. 각 dataset은 registry.json의 configuration_id를 가진 별도 dataset이다. `run_closed_network_rfi.m`이 새 registry를 containers.Map에 등록하고 이 explicit binding으로 FreeSpacePattern/InstalledPattern을 선택한다. REQUIRE_INSTALLED에 해당하는 방식으로 missing installed는 대체하지 않는다.

SBA TC actual 역할과 기존 legacy S_TM_TX 역할을 혼동하지 않는다. 새 plan은 actual 명칭 SBA_TC/SBA_TM을 사용하고 원본 SSOT installation ID SBA_NADIR/SBA_ZENITH를 유지한다. S-TM victim 분석 주파수는 Owner의 **2.200–2.300 GHz**를 사용한다. SAR pattern monitors 8.9/9.65/10.4 GHz 중 actual victim operating band 9.3875–9.9125 GHz를 평가한다. KAA gimbal은 nominal SSOT reference orientation이며 commanded tracking case가 아니다.

## STEP 5 — 정확히 10개 pair 실행

```matlab
cd('RFInterferenceSimulation');
addpath('src');
addpath('analysis/closed_network');
input_status = run_closed_network_rfi(true); % 결과 계산 없이 dataset availability 확인
results = run_closed_network_rfi(false);    % CST 결과 수입·검증 완료 후 실행
```

Pair list는 `rfi_pairs.csv`, physical installation/config matrix 74행은 `rfi_plan.json`이다.

1. KAA → SBA_TM
2. KAA → L1
3. KAA → SAR
4. KAA → ISL_RX
5. ISL_TX → SAR
6. ISL_TX → SBA_TM
7. ISL_TX → L1
8. SBA_TC → ISL_RX
9. SBA_TC → SAR
10. SBA_TC → L1

SBA 양 설치와 GPS 양 설치, KAA 양 gimbal installation을 모두 순회한다. Same-installation path는 이 10개 목록에 없다. Frame/distance는 생성한 full_spacecraft_geometry.json의 실제 SSOT 설치 좌표에서 구한다.

## STEP 6 — 비교 matrix

KAA: FEED_ONLY + Original, FEED_WITH_REFLECTOR + Original, FEED_ONLY + Installed, FEED_WITH_REFLECTOR + Installed 네 조합이다. 비-KAA: Original와 Installed 두 조합이며 attacker original/off-band 데이터는 유지한다.

`rfscreen.config.PatternInterpolationPolicy`는 frequency linear / out-of-range error를 사용한다. +Z native→+X antenna 변환 후 gain lookup을 수행한다. `PsdMath.fspl`, `victimPortPsd`, `margin`, `requiredSuppression`으로 port PSD와 max(0, required)를 계산한다. Receiver BW 적분이나 blocker 계산은 이번 primary에 합치지 않는다.

Source는 ITU antenna-port broadband-equivalent baseline: KAA70 W −47.5696 dBm/Hz, ISL1 W/SBA5 W −49.0206 dBm/Hz다. 실제 계산된 **RealizedGain TX**를 쓰므로 과거 31 dBi reference, Owner −10 dB mismatch, WR42 engineering 감쇠를 추가하지 않는다. 별도 외부 RF-chain 감쇠가 필요하면 실제 기준면·확정값을 확보한 뒤 별도 sensitivity로 추가해야 한다. Native KAA feed geometry는 원본 circular OEWG이며 WR42로 바꾸지 않았다.

## STEP 7 — 결과

`output/closed_network/rfi_ten_pairs.csv`: gtx, grx, FSPL, coupling, victim PSD, allowable PSD, margin, required suppression, worst frequency, provenance/chain status.

`original_installed_comparison.csv`: 같은 pair/physical installations/attacker configuration에 대해 Original/Installed와 ΔInstalled를 비교한다.

`feed_reflector_comparison.csv`: 같은 victim configuration/physical installations에 대해 Feed-only/Reflector와 ΔReflector를 비교한다. Δ는 두 band-worst PSD의 차이다. 필요하면 개별 frequency의 차이를 별도 분석하고 peak가 같은 주파수라고 가정하지 않는다.

기본 source filter는 0 dB다. GPS −178, S-TM/ISL −177, SAR NF4/I-N−6 기준 −176 dBm/Hz를 사용한다. 이 기준은 측정된 장비 acceptance가 아닌 engineering baseline이다.

## Antenna / reflector / RF-chain 효과 분리와 한계

Original→Installed는 antenna pattern effect, Feed-only→Reflector는 reflector effect다. Filter/preselector/NF/P1dB/IIP3/blocker tolerance는 RF-chain 효과다. 후자의 실제 input이 없어 결과에는 RX_CHAIN_INPUT_MISSING을 유지한다. Port PSD와 front-end 적합성을 동일하게 보지 않는다.

Full-spacecraft installed far-field는 전체 위성체의 원거리 응답이다. 위성 내부 수 m 경로는 전체 위성체 far-field 조건을 충족하지 않을 수 있으므로 이 pattern + FSPL 비교는 정확한 near-field S21을 보증하지 않는다. 정확한 intra-spacecraft coupling이 필요하면 별도 multiport full-spacecraft S21 또는 validated near-field solver 결과가 필요하다. 이 한계는 pattern comparison과 별도로 기록한다.

현재 실제 solver 결과가 없어 registry는 비어 있다. INPUT_MISSING/FAILED를 기존 CSV, 0 dB 또는 임의 SAR gain으로 대체하지 않는다. 6개 geometry 미확보를 해결하기 전에는 전체 project preparation complete라고 보고하지 않는다.

## Source 적용성 확인

위 source PSD는 기존 Codex 산출물의 ITU 4 kHz broadband-equivalent 값을 비교용 입력으로 유지한 것이다. 이번 준비 단계에서는 새로운 송신기 규격 조사나 도메인 판정을 수행하지 않았다. 특히 ISL TX → SAR/S-TM 및 SBA TC → L1의 OOB/spurious 경계는 실제 necessary bandwidth와 송신 서비스 규격으로 다시 확인해야 한다. 이 확인 전에는 값이 계산되어도 regulatory-compliant filter requirement로 확정하지 않는다. 결과 CSV에 source_provenance와 coupling_fidelity를 별도로 남긴다. 실제 source mask가 확정되면 rfi_plan.json의 source_psd_dbm_hz를 해당 기준면의 값으로 갱신하고 provenance를 함께 갱신한다.

## 준비 단계 테스트

`test_closed_network_adapter`는 임시 합성 cut으로 native 좌표 변환과 두 pattern class를 확인한다. `test_closed_network_driver`는 임시 repository의 네 비교 조합으로 PSD·margin·요구 억제도 산술과 비교 CSV를 검증한다. Original→Installed +5 dB, Feed→Reflector +3 dB는 합성 fixture에서 지정한 차이이며 실제 위성 결과가 아니다. Python `test_registration.py`의 네 테스트는 RAW 보존 및 NaN/주파수 불일치/불안정 normalization 거절을 확인한다. 테스트는 통과했으며 실제 10개 RFI 경로의 수치 분석은 CST 결과 수입 후 수행한다.
