# CST 2024 폐쇄망 native project 재구축

22개 case를 **새 CST 2024 프로젝트에서 classic VBA/History로 재구축**한다. CST 2026 binary를 CST 2024에서 직접 열지 않는다. Geometry/material/port/phase/설치 방향을 보존하며 solver는 사용자가 mesh·자원·수렴 계획을 확인한 뒤 직접 실행한다. 개발 PC에는 CST 2026만 확인되었다. CST 2026에서의 History 재생 비교는 CST 2024 실행 인증이 아니다.

## 준비된 파일과 실행 순서

패키지 루트는 `cst/projects/closed_network_2024_build/`다. 각 case directory에는 `build_2024.vba`, `build_manifest.json`, `source_geometry.json`, `validation_reference.json`, `README.md`가 있다. 전체 경로·최종 저장 이름은 [22개 inventory](CST2024_REBUILD_22_PROJECTS.csv)에 기록되어 있다. 다음 순서대로 **한 프로젝트씩** 생성하고 저장한다. 22개 solver를 한꺼번에 시작하지 않는다.

| 순서 | Case ID | 구성 |
|---:|---|---|
| 1 | RFC_KAA_FEED_ONLY_STM | KAA feed, S-TM 대역 |
| 2 | RFC_KAA_WITH_REFLECTOR_STM | KAA feed+reflector, S-TM |
| 3 | RFC_KAA_FEED_ONLY_L1 | KAA feed, L1 |
| 4 | RFC_KAA_WITH_REFLECTOR_L1 | KAA feed+reflector, L1 |
| 5 | RFC_KAA_FEED_ONLY_SAR | KAA feed, SAR |
| 6 | RFC_KAA_WITH_REFLECTOR_SAR | KAA feed+reflector, SAR |
| 7 | RFC_KAA_FEED_ONLY_ISL | KAA feed, ISL |
| 8 | RFC_KAA_WITH_REFLECTOR_ISL | KAA feed+reflector, ISL |
| 9 | RFC_SBA_TM_ORIGINAL | SBA 단독 reference |
| 10 | RFC_INSTALLED_SBA_TM_NADIR | SBA NADIR 설치형 |
| 11 | RFC_INSTALLED_SBA_TM_ZENITH | SBA ZENITH 설치형 |
| 12 | RFC_SBA_TC_ORIGINAL_ISL | SBA 간섭원 설치형, ISL |
| 13 | RFC_SBA_TC_ORIGINAL_SAR | SBA 간섭원 설치형, SAR |
| 14 | RFC_SBA_TC_ORIGINAL_L1 | SBA 간섭원 설치형, L1 |
| 15 | RFC_GPS_L1_ORIGINAL | GPS 단독 reference |
| 16 | RFC_INSTALLED_GPS_L1_GPSA1 | GPSA1 설치형 |
| 17 | RFC_INSTALLED_GPS_L1_GPSA2 | GPSA2 설치형 |
| 18 | RFC_ISL_ORIGINAL | ISL 단독 reference |
| 19 | RFC_INSTALLED_ISL_RX | ISL 수신 설치형 |
| 20 | RFC_ISL_TX_ORIGINAL_SAR | ISL 간섭원 설치형, SAR |
| 21 | RFC_ISL_TX_ORIGINAL_STM | ISL 간섭원 설치형, S-TM |
| 22 | RFC_ISL_TX_ORIGINAL_L1 | ISL 간섭원 설치형, L1 |

`ORIGINAL`이라는 legacy filename이 붙은 SBA/ISL 간섭원은 **실제 설치형**이다. 최신 Owner scope를 따른다. KAA에는 spacecraft hull을 넣지 않고 feed-only/reflector를 비교한다. GPS는 primary victim installed pattern만 사용한다. 단독 SBA/GPS/ISL 세 개는 참고용이다. SAR CST를 설계하지 않으며 기존 engineering receive baseline을 사용한다. 10개 RFI family와 설치/configuration 37개 조합은 `analysis/closed_network/rfi_plan.json`을 따른다.

## 새 프로젝트에 macro 실행

1. CST Studio Suite **2024** 실행 → Help/About에서 실제 version/build를 기록한다.
2. New Project → Microwave Studio 3D의 빈 프로젝트를 만든다. CST 2026 `.cst`를 열거나 import하지 않는다.
3. Macro → New Macro에서 editor를 열고 해당 `build_2024.vba` 전체를 붙여 넣는다. UI가 확장자를 제한하면 같은 내용을 로컬 `.mcr`로 복사해 editor로 연다. `Sub Main` 및 helper subroutine 전체가 필요하다.
4. Macro editor에서 Run한다. 이 control macro가 `AddToHistory`를 호출한다. **전체 macro를 하나의 History item에 붙이지 않는다.**
5. Message window와 History list에서 오류를 확인한다. 오류가 있으면 solver를 시작하지 말고 case/version/command/line/message를 기록한다. 실행 중간에 실패한 프로젝트에 다시 실행하지 않는다. 새 빈 프로젝트에서 오류 수정본을 실행한다.

Macro는 mm/GHz/ns, intrinsic PEC와 진공 배경, accepted numeric geometry, rigid installation transform, discrete ports, open boundaries, low/center/high monitor, 초기 solver/mesh, CP combination 정의를 생성한다. `CombineResults`에는 위상값만 설정하며 결과 계산을 호출하지 않는다. 자동 Save/solver 실행도 하지 않는다. 프로젝트 이름은 manifest 및 `cn_rebuild_version` parameter 설명에 있으며 최종 native Save As로 지정한다.

## Geometry와 ports 검증

각 `validation_reference.json`의 object/component/material/port/monitor 수, bounding box, 치수, reference point, boresight, orientation matrix를 비교한다. Bounding box는 native CAD의 **loose bounding box 합집합**으로 보수적인 형상 범위다. 개발 PC 비교에서는 bbox 0.02 mm, port endpoint 1e−7 mm, solid volume 상대차 1e−5 이내를 확인한다. JSON의 `primitive_definitions` 및 `geometry_history`는 실제 숫자를 가진 생성 명령이며 macro와 동일하다. `project_history`는 설정을 포함한 전체 명령이다.

설치형은 spacecraft 좌표를 고정하고 안테나만 `p_B = R_BL p_L + position_B`로 옮긴다. **PANEL_1…PANEL_8 전체**가 있어야 한다. 명칭은 `FULL_SSOT_BUS_HULL_8_PANELS`이며 완전한 satellite CAD가 아니다. Crop·추가 bracket/radome/cable·source antenna tuning을 하지 않는다.

| 설치 identity | 부착면 | native +Z가 향하는 body 방향 |
|---|---|---|
| SBA_NADIR | PANEL_6 | (0, +0.8660254, +0.5) |
| SBA_ZENITH | PANEL_4 | (0, 0, −1) |
| GPSA_1 / GPSA_2 | PANEL_3 | (0, −0.8660254, −0.5) |
| ISL | PANEL_7 | (+1, 0, 0), Owner 결정 |

Port는 native feed endpoint와 50 Ω reference plane을 보존한다. SBA phase는 0/+90/+180/+270°, GPS/ISL/KAA는 0/−90/−180/−270°다. SBA 간섭원 프로젝트에는 NADIR port 1–4와 ZENITH port 5–8이 있다. 각각 별도의 field combination을 생성하며 나머지 네 port는 amplitude 0, matched 50 Ω로 둔다. 이를 실제 flight RF termination 측정값으로 표현하지 않는다. 초기 설정은 첫 group만 amplitude 1이다.

KAA feed는 accepted `KA_FEED_C_OEWG` 그대로다. Reflector 네 개에는 동일한 main/secondary PEC sheet surrogate를 추가한다. 공개 anchors는 D=220 mm, 25.5–27 GHz, system gain 약 31 dBi다. Fe≈151.111258 mm, 40°, secondary 약 44 mm, axial placement와 tessellation은 **ENGINEERING_SURROGATE_FROM_EXISTING_VALIDATED_EQUIVALENT_MODEL**이다. 31 dBi가 이 재구축 형상의 계산 결과라는 뜻은 아니다. Source에 확정된 support 치수가 없어 새로운 support를 invent하지 않는다.

## Monitor와 solver 선택

| Band | Farfield monitor frequencies (GHz) |
|---|---|
| S-TM | 2.200 / 2.250 / 2.300 |
| GPS L1 | 1.563 / 1.57542 / 1.588 |
| SAR | 8.900 / 9.650 / 10.400 |
| ISL | 10.550 / 10.600 / 10.650 |

초기 TD/hex 설정은 재구축 가능한 공통 출발점이다. **Installed case를 TD로 실행하라는 권고가 아니다.** Mesh의 실제 cell 수, RAM, discrete port 지원과 license를 확인하고 case별 solver를 결정한다. 안테나 단독은 TD 또는 FD를 검토한다. 큰 hull의 installed 성능은 surface-based Integral Equation/MLFMM 또는 작은 안테나와 큰 플랫폼을 연결하는 Hybrid를 우선 검토한다. [Dassault solver 설명](https://www.3ds.com/products/simulia/cst-studio-suite/electromagnetic-simulation-solvers)은 IE의 surface integral/MLFMM과 TD/FD/IE/Asymptotic 연결을 설명한다. 실제 CST 2024의 license, PEC surface, feed port와 excitation 지원 여부는 폐쇄망에서 확인해야 한다.

특히 `RFC_INSTALLED_ISL_RX`의 기존 TD 계획은 약 **2.269e9 cells**이며 그대로 실행을 권장하지 않는다. IE/MLFMM의 port/mesh 적합성을 확인하고, 필요하면 near antenna를 TD/FD, 전체 hull을 IE/Asymptotic으로 연결하는 Hybrid를 검토한다. Asymptotic 단독으로 feed port normalization을 대체하지 않는다. 변경 solver의 settings/mesh/reference plane을 기록하고 전체 hull은 유지한다. GUI에서 선택한 solver settings는 CST 2024가 생성한 History 문법으로 기록한다. 초기 hex 8 cells/wavelength, ratio 5는 수렴 보장이 아니며 license 제한을 맞추는 geometry 축소 수단도 아니다.

## CST 2024 native 저장과 승인 기록

검증 후 `${case_id}_CST2024.cst`로 저장한다. 위치는 `cst/projects/closed_network_2024_native/{kaa,sba,gps,isl}/`다. `source_project`는 비교 대상 CST 2026 파일의 식별자이며 rebuild 입력 binary가 아니다.

각 native 파일 옆에 `${case_id}_CST2024.native_validation.json`을 기록한다. `native_validation.template.json`을 복사해 실제 검증 후 채운다. status는 검증 전 `NOT_VALIDATED`를 유지하고 검증 후에만 `GEOMETRY_ACCEPTED_CST2024`로 바꾼다. 실제 About version, reviewer/time, object/port/monitor/panel 수와 모든 checks를 기록한다. `source_geometry_hash`, `build_vba_sha256`은 manifest 값이며 **native_project_sha256은 실제 CST 2024에서 저장한 파일의 hash**다. 파일명만으로 version을 인증하지 않는다.

```powershell
Get-FileHash cst/projects/closed_network_2024_native/kaa/RFC_KAA_FEED_ONLY_STM_CST2024.cst -Algorithm SHA256
python cst/closed_network/check_2024_rebuild.py
```

후자의 checker는 전달 패키지 completeness 검사이며 실제 native 2024 검증을 대신하지 않는다. Native 저장 후 사용자가 mesh/resource를 확인하고 직접 solver를 실행한다. Solver 결과를 저장하면 native file hash가 바뀔 수 있으므로 **최종 저장본의 hash를 승인 기록에 갱신**하고 geometry 승인 근거는 유지한다. Mesh/port/solver/convergence/passivity/normalization 실패는 별도 실패 기록으로 남기고 0 dB·기존 pattern으로 대체하지 않는다.

## RAW export → MATLAB

각 monitor의 XZ/YZ realized gain, accepted-power gain, complex E, 가능하면 CP 및 full 3D를 RAW로 보존한다. clipping/floor를 넣지 않는다. 설치형 cut은 body solver 방향을 안테나 local 방향으로 resample하며 complex E basis를 명시한다. RAW directory/dataset binding은 기존 `cst/projects/closed_network/dataset_bindings.json`을 유지한다.

폐쇄망 Python+pywin32가 있으면 **CST 2024에서 해석된 native project**에 기존 exporter를 사용할 수 있다. 이 방식은 CST Python API를 사용하지 않는다. GUI export를 사용하는 경우 동일 schema/provenance와 native acceptance 기록을 함께 준비한다. 변경된 solver의 result tree/quantity가 다르면 먼저 adapter를 검증한다.

```powershell
python cst/closed_network/export_patterns.py cst/projects/closed_network_2024_native/kaa/RFC_KAA_FEED_ONLY_STM_CST2024.cst --build-package cst/projects/closed_network_2024_build/kaa/RFC_KAA_FEED_ONLY_STM --native-validation cst/projects/closed_network_2024_native/kaa/RFC_KAA_FEED_ONLY_STM_CST2024.native_validation.json --convergence-accepted
python analysis/closed_network/register_closed_network_patterns.py
```

실제 solver 결과가 있고 수렴을 확인한 뒤에만 `--convergence-accepted`를 쓴다. Exporter는 solver를 시작하지 않는다. SBA 두 group은 `--installation-id SBA_NADIR` 및 `--installation-id SBA_ZENITH`로 각각 export한다. 등록기는 2024 native file hash/승인 기록/build hash를 확인하며 CST 2026 binary hash와 같다고 요구하지 않는다. [MATLAB 실행 매뉴얼](CLOSED_NETWORK_MATLAB_RFI_MANUAL.md)의 동일 RAW→registry→10 pair 흐름으로 이어진다.

## 검증 증거

`cst/projects/closed_network_2024_build/cst2026_replay_validation.json`은 CST **2026**에서 source와 classic History 재구축을 비교한 기록이다. `completeness_validation.json`은 22개 × 필수 5파일, geometry hash, installed 8 panels와 10 family binding 검사다. CST 2024 실행 및 solver 수렴은 아직 검증하지 않았다. 새로운 EM pattern이나 실제 RFI 결과도 생성하지 않았다.
