# 폐쇄망 MATLAB RFI 실행 매뉴얼

Installed CST 형상에서는 spacecraft body 좌표가 고정되고 안테나와 port가 회전·이동된다. ISL은 Owner 지정 +X 끝면(PANEL_7)이며 closed-network geometry manifest의 `nominal_R_BL`이 이 결정을 반영한다. 기존 shared installation CSV를 덮어쓰지 않는다. Original 및 KAA 프로젝트는 계속 native +Z다.

`export_closed_network_patterns.py`는 Installed far-field를 `d_body=R_BL*d_local` 방향에서 샘플링하여 local XZ/YZ gain CSV를 만든다. 등록기는 `solver_frame=SPACECRAFT_BODY_FIXED`, `gain_cut_resampled_in_antenna_local_frame=true` 및 preflight와 같은 rotation matrix를 확인한다. 잘못된 global XZ/YZ cut을 local cut처럼 등록하지 않는다. `cn_load_pattern`은 이 local gain cut을 기존 antenna +X boresight 규약으로 변환하고, RFI driver는 `nominal_R_BL`을 한 번만 적용한다. 안테나 방향 회전을 중복 적용하지 않는다.

**22개 CST 분석 프로젝트와 기존 SAR engineering baseline으로 10개 pair를 실행하는 절차를 준비했다.** Original/Installed와 KAA Feed/Reflector 조합은 67개다. SAR에는 Installed CST가 없으므로 하나의 동일 engineering receive baseline을 사용한다. 실제 CST export는 아직 없으며 실제 위성 RFI 수치를 계산하지 않았다.

## STEP 1 — RAW 복사

[CST inventory CSV](closed_network_cst_project_inventory.csv)의 expected_output_directory에 RAW를 넣는다. Dataset 이름은 `.cst` 이름에서 `RFC_`를 제외한 값이다. SBA installed NADIR/ZENITH, GPS installed GPSA1/GPSA2를 분리한다. 원본 frozen pattern과 정상 Ka-band 데이터를 덮어쓰지 않는다.

각 frequency에 `f2.200000_XZ.csv` 형태의 6자리 GHz filename을 사용한다. RAW realized gain, accepted-power gain, complex fields, CP±, S-matrix, convergence/mesh 로그, source frame/reference plane과 solver selection evidence를 함께 보존한다. Gain clipping/floor를 적용하지 않는다.

## STEP 2 — 패턴 검증과 등록

```powershell
python analysis/closed_network/register_closed_network_patterns.py
```

Register는 SOLVED_ACCEPTED, RealizedGain/dBi, convergence와 accepted-power normalization, project ID/frame, monitor 3개의 정확한 frequency를 확인한다. 각 XZ/YZ cut은 theta 0…359°, unique 360행, finite realized gain이어야 한다. NaN/Inf/duplicate/missing angle을 기존 데이터로 채우지 않는다. XZ는 phi0/180, YZ는 phi90/270이며 native +Z_CST가 boresight다.

RAW는 보존하고 `registered/`에 theta,gain 두 column의 별도 import view를 만든다. `data/closed_network_patterns/registry.json`에 dataset/config ID, pattern class, frequency, coordinate frame, RAW hash를 등록한다. configuration_id는 `CN_<dataset_id>`다.

RealizedGain에는 port mismatch가 포함된다. 이전 Owner −10 dB mismatch, 31 dBi reference 또는 WR42 attenuation을 다시 추가하지 않는다. Accepted-power Gain을 RealizedGain으로 이름만 바꾸지 않는다. CP±의 RHCP/LHCP 대응도 검증 없이 지정하지 않는다. IE/Hybrid result tree/quantity/reference plane이 native exporter 가정과 다르면 먼저 adapter를 검증한다.

## STEP 3 — SAR engineering receive baseline

Register는 CST 등록과 별도로 **SAR_ENGINEERING_RECEIVE_BASELINE**을 등록한다. 이 entry는 SOLVED_ACCEPTED나 InstalledPattern으로 위장하지 않고 `EngineeringReceiveBaseline`으로 표시한다.

실제 저장소 입력은 다음과 같다.

- `output/codex/emission_inputs/latest_owner_policy.json`: Owner peak=52 dBi, rear=−50 dB relative/+2 dBi absolute, NF4, I/N−6, allowable=−176 dBm/Hz.
- `output/codex/sar_owner_pattern_anchors.csv`, `sar_reference_envelope.csv`: Owner-extracted Azimuth/Elevation reconstruction, exact HPBW/null/sidelobe anchors. 원본 K8 MAT/1601 points를 반출·복원하지 않는다.
- `output/codex/sar_receiver_owner_baseline.csv`: receiver baseline provenance.

`cn_sar_gain(repo,direction_A)`가 이 기존 Owner 입력을 읽는다. Antenna +X boresight로부터 polar angle이 80°를 넘으면 +2 dBi rear ceiling을 적용한다. 범위 안에서는 exact owner anchors와 기존 main-beam/adjacent-upper-envelope 규칙을 사용하고, 미확정 transverse roll 때문에 azimuth/elevation 중 높은 envelope를 사용한다. 이는 engineering angular approximation이며 실제 full-3D SAR simulation이 아니다. Cross-pol floor는 삭제하거나 자체 peak로 정규화하지 않는다. CST registration 및 본 Co-pol 계산은 cross-pol attenuation을 추가로 주장하지 않는다.

현재 SSOT 좌표에서 SAR를 향한 KAA_1/KAA_2/ISL/SBA_NADIR/SBA_ZENITH의 SAR off-axis angle은 약 89.02/95.14/116.77/85.78/123.85°다. 모든 SAR 경로에서 Owner rear +2 dBi가 적용된다. 이 각도는 설치 geometry 계산이며 RFI 결과가 아니다.

SAR pattern의 주파수 변화는 제공되지 않았다. 9.65 GHz nominal reference의 engineering baseline을 SAR tuning band 전체에서 동일하게 적용하는 가정을 기록한다. 이는 세 개 CST monitor에서 각각 얻은 SAR 패턴이 아니다.

SAR의 Original/Installed Δ는 산출하지 않는다. KAA→SAR의 Feed-only/Reflector Δ는 같은 SAR baseline을 유지한 TX pattern 효과만 비교한다. ISL TX→SAR 및 SBA TC→SAR도 같은 baseline으로 계산한다.

## STEP 4 — 실제 MATLAB loader/binding

기존 shared `MissionCaseBuilder.buildCase`는 SSOT의 pattern_bindings.csv/antenna_functions.csv/installed_patterns.csv를 읽는 legacy mission loader다. 이 준비 작업은 그 shared code/CSV와 frozen datasets를 변경하지 않는다. 기존 SAR deferred 상태를 새 실행 경로로 복사하지 않는다.

새 경로는 **`analysis/closed_network/rfi_plan.json`**의 tx_dataset/rx_dataset, tx_configuration/rx_configuration, 설치 identity와 band를 읽고 새 registry를 직접 연결한다.

`cn_load_pattern.m`은 `SourceCoordinateConvention`, `CsvPatternImporter.importCut`, `CstLocalFrameAdapter.localToAntenna`, `PatternGrid`와 `FreeSpacePattern`/`InstalledPattern(...,'CST',opts)`를 사용한다. CST native local +Z를 repository antenna +X로 한 번만 변환한다. Native frame의 two-cut interpolation과 동일한 수식을 vectorize했다. Generic cut assembler의 다른 roll map을 사용하지 않는다.

Original/Feed-only/Reflector는 FreeSpacePattern, 실제 installed CST는 InstalledPattern이다. 두 cut에서 만든 spherical grid는 `APPROX_FROM_CUTS`이며 true full 3D로 표시하지 않는다. SAR entry는 이 CST loader를 통과하지 않고 `cn_sar_gain`으로 연결한다. Missing installed를 original로 대체하지 않는다.

## STEP 5 — 10개 pair 실행

```matlab
cd('RFInterferenceSimulation');
addpath('src');
addpath('analysis/closed_network');
input_status = run_closed_network_rfi(true); % availability만 점검, 결과 CSV 생성 없음
results = run_closed_network_rfi(false);    % 검증된 CST export 수입 후 실행
```

`rfi_pairs.csv`는 정확히 다음 10개 family다. `rfi_plan.json`은 실제 installation/configuration 67개 조합을 담는다.

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

SBA 두 위치, GPS 두 위치, KAA 두 gimbal reference 위치를 모두 유지한다. KAA nominal reference orientation은 commanded tracking configuration이 아니다. SAR victim-band generic unwanted emission을 평가하며 integer harmonic 여부로 전체 SAR 분석을 skip하지 않는다. 이번 10-case scope가 이전 ISL TX exclusion/harmonic-only scope보다 우선한다.

## STEP 6 — 비교와 PSD 계산

KAA→SBA/GPS/ISL은 Feed-only+Original, Reflector+Original, Feed-only+Installed, Reflector+Installed 네 조합이다. 비 KAA→SBA/GPS/ISL은 Victim Original/Installed 두 조합이다. SAR는 하나의 engineering baseline이며 victim installed comparison은 N/A다.

각 경로의 실제 설치 좌표/R_BL을 `full_spacecraft_geometry.json`에서 읽는다. `PatternInterpolationPolicy`는 frequency linear interpolation/out-of-range error다. Victim tuning band를 161개 frequency로 점검하고 가장 큰 victim PSD를 출력한다. Monitor 3개로는 좁은 resonance/spur가 보장되지 않는다. 필요하면 폐쇄망에서 frequency 수렴을 확인하고 데이터를 추가한다.

`PsdMath.fspl`, `victimPortPsd`, `margin`, `requiredSuppression`을 사용한다.

`coupling = G_TX + G_RX − FSPL`

`victim PSD = conducted source PSD − explicit TX chain attenuation + coupling`

`margin = allowable PSD − victim PSD`

`required additional suppression = max(0, victim PSD − allowable PSD)`

현재 source 입력은 기존 Codex의 ITU 4 kHz broadband-equivalent baseline: KAA70 W −47.5696 dBm/Hz, ISL1 W/SBA5 W −49.0206 dBm/Hz다. Baseline reference plane은 coherent antenna-port input이며 기본 external chain attenuation은 0 dB다. 실제 TX RealizedGain을 쓰므로 31 dBi나 이전 WR42/Owner mismatch를 중복 적용하지 않는다. GPS/S-TM/ISL/SAR allowable은 −178/−177/−177/−176 dBm/Hz다.

이번 준비 단계에서 신규 송신서비스 규격 조사·necessary bandwidth/domain 판정은 하지 않았다. 특히 ISL→SAR의 OOB/spurious 적용성은 실제 bandwidth/규격으로 다시 확인해야 한다. 이 검토 전 source는 비교용 baseline이며 regulatory-compliant filter requirement로 확정하지 않는다. 확정 mask를 적용할 때 rfi_plan의 source PSD와 provenance를 함께 갱신한다. Discrete spur limit을 broadband PSD로 임의 변환하지 않는다.

## STEP 7 — 산출물

`output/closed_network/rfi_ten_pairs.csv`에는 attacker/victim gain, FSPL/coupling, victim PSD, allowable PSD, margin, required suppression, worst frequency, source provenance/model fidelity와 chain status를 남긴다.

`original_installed_comparison.csv`에는 30개 비교가 있다. SAR는 포함하지 않는다. `feed_reflector_comparison.csv`에는 동일 victim configuration을 유지한 22개 KAA 비교가 있다. Band-worst PSD끼리의 차이이며 worst frequency가 같은 것으로 가정하지 않는다.

Original/Installed는 antenna installation effect, Feed/Reflector는 reflector effect다. Filter/preselector/NF/P1dB/IIP3/blocker tolerance의 RF-chain effect는 별도로 유지한다. 미확정 chain 입력은 RX_CHAIN_INPUT_MISSING으로 표시하고 임의 값을 넣지 않는다. 요구 추가 억제도는 TX unwanted-emission requirement이며 RX blocker rejection으로 부르지 않는다.

## 한계와 검증

Installed 모델은 전체 **SSOT bus hull** 8개 패널이며 complete satellite CAD가 아니다. [구조물 audit](closed_network_external_structure_audit.json)을 확인한다. Bus 전체의 far-field pattern과 FSPL은 수 m 위성 내부 경로의 정확한 near-field S21을 보장하지 않는다. 정확한 port coupling에는 별도 full-wave multiport/near-field 결과가 필요하다. 본 절차는 이 한계를 model fidelity로 유지한다.

`test_closed_network_adapter`, `test_closed_network_driver`, `test_ten_pair_execution`은 임시 합성 입력으로 좌표/PSD 산술과 전체 10개 family 실행 및 비교 CSV 구조를 검사한다. 합성 결과를 실제 위성 결과로 등록하지 않는다. `test_registration.py`는 RAW 보존과 NaN/주파수/normalization 오류 거절을 검사한다. 실제 10개 family의 입력 계획은 모두 있으며 실제 수치 실행은 CST export 수입 후 가능하다. 현재 등록된 실제 입력은 SAR engineering baseline 하나이고 CST dataset은 아직 0개다.
