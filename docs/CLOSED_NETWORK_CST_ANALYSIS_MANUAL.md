# 폐쇄망 CST 실행 매뉴얼

**분석용 CST 22/22개를 저장하고 단독 재열기 검증을 완료했다.** 별도 공통 geometry source 1개는 분석 case 수에 포함하지 않는다. Solver는 실행하지 않았다. SAR는 신규 CST 없이 기존 engineering receive-pattern baseline을 사용한다. 10개 RFI 경로의 입력 계획은 모두 연결되어 있으며 실제 수치 분석은 폐쇄망 CST RAW 결과를 가져온 뒤 수행한다.

## A. 목적과 범위

Victim operating frequency에서 attacker radiation과 victim receive pattern을 결합한다. 정상 Ka 반송파 blocker는 이번 범위가 아니다.

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

## B. Project inventory

[Inventory CSV](closed_network_cst_project_inventory.csv)는 분석 프로젝트 22개를 각각 한 행으로 관리한다. [전체 파일 목록](closed_network_generated_projects.md)에 저장 경로를 기록했다. CSV에는 antenna/configuration/band, edge/center frequency, geometry source, installation identity, 4-port 검증, monitor 검증, 저장 solver와 선택 정책, 출력 directory가 있다. 모든 분석 프로젝트 상태는 `READY_NOT_SOLVED`다. 이는 저장·설정 검증 상태이며 정식 라이선스·메모리·수렴 검증을 의미하지 않는다.

| 구성 | 개수 | Geometry / port / polarization | Spacecraft geometry |
|---|---:|---|---|
| KAA feed-only, 4 bands | 4 | KA_FEED_C_OEWG 원본; native 4-port CP phase 유지 | 없음 |
| KAA feed+reflector, 4 bands | 4 | 동일 feed + 공통 KARMA engineering surrogate; native 4-port CP phase 유지 | 없음; spacecraft-installed로 부르지 않음 |
| SBA TM Original + Installed NADIR/ZENITH | 3 | SBAND_MATCHING_WIRE15; 원본 4-port phase 유지 | Installed 두 건에 전체 SSOT bus hull |
| GPS L1 Original + Installed GPSA1/GPSA2 | 3 | LBAND_GNSS_FINAL_COMPROMISE; 원본 4-port phase 유지 | Installed 두 건에 전체 SSOT bus hull |
| ISL Original + Installed RX | 2 | ISL_C4_CUP_R14P7; 원본 4-port phase 유지 | Installed에 전체 SSOT bus hull |
| ISL TX off-band SAR/STM/L1 | 3 | ISL 원본 geometry와 4-port phase 유지 | 없음 |
| SBA TC off-band ISL/SAR/L1 | 3 | SBA 원본 geometry와 4-port phase 유지 | 없음 |

| Victim band | Range (GHz) | Far-field monitors (GHz) |
|---|---|---|
| S-TM | 2.200–2.300 | 2.200 / 2.250 / 2.300 |
| GPS L1 | 1.563–1.588 | 1.563 / 1.57542 / 1.588 |
| SAR | 8.900–10.400 | 8.900 / 9.650 / 10.400 |
| ISL | 10.550–10.650 | 10.550 / 10.600 / 10.650 |

SAR operating-band 평가는 기존 9.3875–9.9125 GHz를 사용하며 그 범위를 포함하는 세 monitor로 attacker response를 얻는다. `RFC_SAR_ORIGINAL.cst`와 `RFC_INSTALLED_SAR.cst`는 요구 목록에서 제거했다. SAR baseline은 Owner peak 52 dBi, rear +2 dBi, NF4/I-N−6 기준 −176 dBm/Hz다.

## C. KAA 공통 surrogate와 provenance

공통 source는 `cst/projects/closed_network/kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.cst`다. 네 `RFC_KAA_WITH_REFLECTOR_*`는 이 source를 복제하고 range/monitor만 변경했다. 원본 KA_FEED_C_OEWG geometry/material/ports/local frame과 0/−90/−180/−270° phase는 유지했다. `.geometry.json`의 surface hash 및 네 `.preflight.json`의 source/geometry hash로 동일성을 확인한다.

공개 확정값은 220 mm antenna diameter, 25.5–27 GHz, system gain 31 dBi, RHCP/LHCP/dual RF system이다. [Kongsberg 제품 페이지](https://www.kongsberg.com/what-we-do/space/space-mechanisms/apm/karma-7-fg/)와 [2022/09 datasheet, pp.1–2](https://www.kongsberg.com/globalassets/kongsberg/1.-what-we-do/3.-space/2.-space-mechanisms/apm/karma-7-fg-product-data-sheet.pdf), [공개 사진](https://www.kongsberg.com/globalassets/kongsberg/1.-what-we-do/3.-space/2.-space-mechanisms/apm/karma-7-fg_865x865.jpg?width=750)을 출처로 둔다. 사진의 기구 전체 envelope는 RF reflector optical prescription이 아니다. 31 dBi는 system reference이며 CST 패턴을 이 값에 맞춰 rescale하지 않는다.

Fe=151.111258 mm, θf=40°, secondary/obstruction diameter=44 mm는 기존 `cst/results/KA_REFLECTOR_KA_FEED_C_OEWG/reflector_validation.json`과 `ka_reflector_po.py`/`ka_reflector_eval.py`의 equivalent aperture 모델에서 가져온 **engineering seed**다. Vendor specification으로 표시하지 않는다. 기존 seed의 PASS는 NON_CST_PYTHON aperture 모델에만 해당하며 새 CAD의 full-wave validation이 아니다.

이번 surrogate는 다음 추가 가정을 명시했다.

- PEC zero-thickness paraboloid: diameter 220 mm, focal proxy Fe, vertex z=−80 mm.
- Native feed mouth z=20 mm를 phase-centre proxy로 사용한다. Feed는 이동·회전하지 않았다.
- Forward feed를 main reflector로 향하게 하는 convex hyperbolic secondary: diameter 44 mm, vertex z=60 mm, 두 focus는 feed proxy와 main paraboloid focus다. 실제 KARMA secondary 형상·축 위치를 주장하지 않는다.
- 64 azimuth sectors, main 8 radial rings, secondary 4 radial rings로 1,408개 sheet triangle을 만들었다. Main rim chord sag는 약 0.133 mm다. 폐쇄망 mesh/convergence에서 이 faceting의 영향을 확인한다.
- Gimbal/strut/radome/cable/material loss는 발명하지 않았다. Tuning·optimization·solver는 수행하지 않았다.

`OWNER_AUTHORIZED_ENGINEERING_SURROGATE; NOT_VENDOR_CAD; NOT_FULL_WAVE_VALIDATED`를 provenance로 유지한다. CST 결과는 이 surrogate의 결과이며 제품 인증값으로 해석하지 않는다.

## D. Full SSOT bus hull audit

`FULL_SSOT_BUS_HULL_8_PANELS`는 현재 SSOT의 전체 simplified bus hull을 뜻한다. **물리적으로 완전한 satellite CAD가 아니다.** [외부 구조물 audit JSON](closed_network_external_structure_audit.json)을 함께 읽는다.

`SimplifiedSpacecraftBuilder`가 구조물 instance로 생성하는 것은 panels.csv의 SIDE 6개와 END_CAP 2개다. 8개 모두 포함했으며 정의된 구조물의 삭제/crop은 없다. Antenna installation/steering table은 좌표 metadata다. Generic `StructureType.SOLAR_ARRAY/PAYLOAD/...` enum이 존재한다는 사실은 실제 geometry instance가 있다는 뜻이 아니다. Standalone antenna library geometry도 released spacecraft assembly CAD와 구분한다. Passive antenna bodies, solar arrays, payload bodies, brackets, cables, gimbal hardware는 현재 SSOT assembly에 정의되지 않았다. 실제 위성에 없다는 뜻이 아니다.

Active installed antenna/ports의 native local frame을 보존하고 전체 bus hull을 rigid transform으로 옮겼다. `p_B=R_BL*p_L+installation_position_B`의 roundtrip으로 실제 SSOT 설치 위치/방향을 확인했다. Native component label `FULL_SPACECRAFT`는 역사적 container 이름이며 CAD fidelity 표현이 아니다.

## E. 폐쇄망 실행 순서

1. KAA feed-only STM → reflector STM → feed-only L1 → reflector L1 → feed-only SAR → reflector SAR → feed-only ISL → reflector ISL.
2. Victim Original SBA TM / GPS L1 / ISL.
3. Installed SBA TM NADIR와 ZENITH; GPS L1 GPSA1와 GPSA2; ISL RX. 각 identity를 별도로 실행한다.
4. ISL TX off-band SAR/STM/L1, SBA TC off-band ISL/SAR/L1.
5. SAR CST 실행 단계는 없다. 기존 receive baseline을 MATLAB에서 연결한다.

Project open → native geometry/material/port와 phase 확인 → range/monitor 확인 → 아래 solver 선택 → mesh quality/cells/RAM 확인 → solver run → convergence/passivity/normalization 확인 → independent far-field export → filename/directory 확인 순서로 진행한다. 오늘은 solver run 이후 단계가 수행되지 않았다.

## F. Solver 선택과 자원 검토

저장된 native default는 HF Time Domain이다. **이 default를 모든 case의 강제 선택으로 사용하지 않는다.** 특히 ISL Installed의 기존 hex plan은 2,269,049,730 cells이므로 그대로 Start를 누르지 않는다. 128 bytes/cell의 단순 계획식만으로도 약 270.5 GiB이며 실제 CST RAM 보증값이 아니다.

[공식 CST solver 설명](https://www.3ds.com/products/simulia/cst-studio-suite/electromagnetic-simulation-solvers)은 IE의 MoM/MLFMM 및 TD/FD/IE/Asymptotic Hybrid 연계를 설명한다. [공식 system modeling 설명](https://www.3ds.com/products/simulia/cst-studio-suite/electromagnetic-systems-modeling)은 feed far-field source와 reflector IE/Asymptotic 연계를 설명한다. 폐쇄망 정식 라이선스에서 다음 순서로 결정한다.

1. 설치 모델, 특히 ISL은 **Integral Equation/MLFMM** surface mesh를 먼저 검토한다. Discrete ports 4개, dielectric/material, closed/thin PEC sheet 지원, 모든 port excitation과 impedance/reference plane 보존 여부를 확인한다. Triangle 수·unknown 수·memory estimate를 기록한다.
2. IE가 local feed/material/port를 직접 지원하지 않으면 **Hybrid**를 검토한다. Native antenna subsystem은 TD/FD full-wave로, 큰 bus scattering은 IE/MLFMM으로 연결한다. Ports/phase를 유지하고 Huygens/current/far-field transfer quantity와 power normalization/reference plane을 기록한다. 형상 삭제로 대체하지 않는다.
3. **Asymptotic/PO/SBR**은 electrically large bus scattering의 보조 또는 Hybrid component로만 검토한다. L-band의 220 mm reflector와 below-cutoff feed 등 electrically small/resonant 부분을 Asymptotic만으로 계산하지 않는다. Near-field/source validity도 확인한다.
4. TD/FD가 적절한 compact original/feed 모델은 그 solver를 유지할 수 있다. Installed 모델은 해당 hardware에서 가능한 자원 추정과 mesh convergence를 확인한 뒤 선택한다. 형상/port/material을 변경하지 않는다.
5. Solver 변경 후 monitor 3개와 모든 port excitation, CP combination, raw gain quantity를 다시 확인한다. 선택 solver, licensed CST version, mesh type/size, RAM, convergence evidence를 `solver_selection.json` 및 export provenance에 남긴다. 설정 화면을 확인하는 동안 Start를 누르지 않는다.

오늘 임시 사본에서 `ChangeSolverType "HF Integral Equation"` macro token을 시험했으나 현재 설치에서 invalid solver type 오류로 거절되었다. 사본의 변경을 저장하지 않았고 본 프로젝트 hash는 유지했다. 이 실패는 정식 CST의 IE 기능 부재를 증명하지 않으며 잘못된 token인지 edition 제약인지를 확정하지 않는다. 이 token을 폐쇄망 명령으로 사용하지 말고 해당 버전 GUI에서 solver를 선택한다. 정식 라이선스의 IE/Hybrid mesh 및 convergence는 아직 검증하지 않았다.

## G. RAW export와 실패 처리

SBA phase는 0/90/180/270°, GPS/ISL/KAA는 0/−90/−180/−270°를 유지한다. 모든 port 결과를 계산한 뒤 coherent combination을 수행한다. 확인된 CP sense만 RHCP/LHCP로 이름 붙인다.

Windows Python 3.10+, numpy, pywin32와 CST COM 등록을 사용할 수 있는 경우:

```powershell
python cst/export_closed_network_patterns.py cst/projects/closed_network/kaa/RFC_KAA_WITH_REFLECTOR_STM.cst --convergence-accepted
```

이 명령은 Solver.Start를 호출하지 않는다. CombineResults.Run은 완료된 결과의 후처리다. `--convergence-accepted`는 mesh/solver 수렴을 실제 확인한 후에만 지정한다. Exporter는 native all-port S-matrix/combined far-field tree를 전제로 한다. IE/Hybrid에서 result tree가 달라지면 GUI RAW export 또는 해당 tree adapter를 먼저 검증한다. 기존 TD 결과로 대체하지 않는다.

각 frequency마다 `f<GHz 소수점 6자리>_XZ.csv`, `_YZ.csv`를 보존한다. 예: f2.200000_XZ.csv, f1.575420_YZ.csv. RAW realized gain linear/dBi, accepted-power gain, complex Eθ/Eφ, CP±와 raw_s_matrix.npz를 남긴다. CP± handedness는 CST convention 확인 후 지정한다. Full 3D ASCII도 가능한 경우 별도 보존하며 quantity/frame/unit을 기록한다. 폴더별 README에 모든 expected filename이 있다.

Gain floor/clipping은 금지한다. 실제 linear zero는 −Inf로 남기며 finite 값으로 바꾸지 않는다. Export는 solver log, convergence/mesh evidence, normalization, source/reference plane, selected solver와 함께 inventory의 expected_output_directory로 복사한다.

Mesh/solver/port/convergence/passivity/normalization 실패는 FAILED 또는 INPUT_MISSING으로 기록한다. 0 dB·과거 패턴으로 대체하지 않는다. Accepted-power normalization이 불안정하면 RAW는 유지하지만 primary registration을 거절한다.

## H. 검증 증거

[단독 재열기 검증](closed_network_reopen_validation.json), [준비 완전성 검사](closed_network_completeness.json), 각 `.preflight.json`이 프로젝트 hash, mesh count, native ports/material/geometry 및 전체 bus hull 좌표 증거를 남긴다. 실제 solver 결과와 실제 RF/RFI 수치는 아직 없다.

## Appendix ? per-project inventory

| Project filename | Antenna | Configuration | Victim band | Frequencies GHz | Ports | Polarization | Geometry source | Spacecraft | Solver status |
|---|---|---|---|---|---|---|---|---|---|
| RFC_KAA_FEED_ONLY_STM.cst | KAA | FEED_ONLY | STM | 2.2 / 2.25 / 2.3 | 4 native ports | Native CP phase; verify sense | cst/projects/KA_FEED_C_OEWG.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_WITH_REFLECTOR_STM.cst | KAA | FEED_WITH_REFLECTOR | STM | 2.2 / 2.25 / 2.3 | 4 native ports | Native CP phase; verify sense | cst/projects/closed_network/kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_FEED_ONLY_L1.cst | KAA | FEED_ONLY | L1 | 1.563 / 1.57542 / 1.588 | 4 native ports | Native CP phase; verify sense | cst/projects/KA_FEED_C_OEWG.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_WITH_REFLECTOR_L1.cst | KAA | FEED_WITH_REFLECTOR | L1 | 1.563 / 1.57542 / 1.588 | 4 native ports | Native CP phase; verify sense | cst/projects/closed_network/kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_FEED_ONLY_SAR.cst | KAA | FEED_ONLY | SAR | 8.9 / 9.65 / 10.4 | 4 native ports | Native CP phase; verify sense | cst/projects/KA_FEED_C_OEWG.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_WITH_REFLECTOR_SAR.cst | KAA | FEED_WITH_REFLECTOR | SAR | 8.9 / 9.65 / 10.4 | 4 native ports | Native CP phase; verify sense | cst/projects/closed_network/kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_FEED_ONLY_ISL.cst | KAA | FEED_ONLY | ISL | 10.55 / 10.6 / 10.65 | 4 native ports | Native CP phase; verify sense | cst/projects/KA_FEED_C_OEWG.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_WITH_REFLECTOR_ISL.cst | KAA | FEED_WITH_REFLECTOR | ISL | 10.55 / 10.6 / 10.65 | 4 native ports | Native CP phase; verify sense | cst/projects/closed_network/kaa/KARMA7_FG_REFLECTOR_SURROGATE_BASE.cst | NONE | READY_NOT_SOLVED |
| RFC_SBA_TM_ORIGINAL.cst | SBA | ORIGINAL | STM | 2.2 / 2.25 / 2.3 | 4 native ports | Native CP phase; verify sense | cst/projects/SBAND_MATCHING_WIRE15.cst | NONE | READY_NOT_SOLVED |
| RFC_INSTALLED_SBA_TM_NADIR.cst | SBA | INSTALLED | STM | 2.2 / 2.25 / 2.3 | 4 native ports | Native CP phase; verify sense | cst/projects/SBAND_MATCHING_WIRE15.cst | FULL_SSOT_BUS_HULL_8_PANELS | READY_NOT_SOLVED |
| RFC_INSTALLED_SBA_TM_ZENITH.cst | SBA | INSTALLED | STM | 2.2 / 2.25 / 2.3 | 4 native ports | Native CP phase; verify sense | cst/projects/SBAND_MATCHING_WIRE15.cst | FULL_SSOT_BUS_HULL_8_PANELS | READY_NOT_SOLVED |
| RFC_GPS_L1_ORIGINAL.cst | GPS | ORIGINAL | L1 | 1.563 / 1.57542 / 1.588 | 4 native ports | Native CP phase; verify sense | cst/projects/LBAND_GNSS_FINAL_COMPROMISE.cst | NONE | READY_NOT_SOLVED |
| RFC_INSTALLED_GPS_L1_GPSA1.cst | GPS | INSTALLED | L1 | 1.563 / 1.57542 / 1.588 | 4 native ports | Native CP phase; verify sense | cst/projects/LBAND_GNSS_FINAL_COMPROMISE.cst | FULL_SSOT_BUS_HULL_8_PANELS | READY_NOT_SOLVED |
| RFC_INSTALLED_GPS_L1_GPSA2.cst | GPS | INSTALLED | L1 | 1.563 / 1.57542 / 1.588 | 4 native ports | Native CP phase; verify sense | cst/projects/LBAND_GNSS_FINAL_COMPROMISE.cst | FULL_SSOT_BUS_HULL_8_PANELS | READY_NOT_SOLVED |
| RFC_ISL_ORIGINAL.cst | ISL | ORIGINAL | ISL | 10.55 / 10.6 / 10.65 | 4 native ports | Native CP phase; verify sense | cst/projects/ISL_C4_CUP_R14P7.cst | NONE | READY_NOT_SOLVED |
| RFC_INSTALLED_ISL_RX.cst | ISL | INSTALLED | ISL | 10.55 / 10.6 / 10.65 | 4 native ports | Native CP phase; verify sense | cst/projects/ISL_C4_CUP_R14P7.cst | FULL_SSOT_BUS_HULL_8_PANELS | READY_NOT_SOLVED |
| RFC_ISL_TX_ORIGINAL_SAR.cst | ISL | ATTACKER_ORIGINAL | SAR | 8.9 / 9.65 / 10.4 | 4 native ports | Native CP phase; verify sense | cst/projects/ISL_C4_CUP_R14P7.cst | NONE | READY_NOT_SOLVED |
| RFC_ISL_TX_ORIGINAL_STM.cst | ISL | ATTACKER_ORIGINAL | STM | 2.2 / 2.25 / 2.3 | 4 native ports | Native CP phase; verify sense | cst/projects/ISL_C4_CUP_R14P7.cst | NONE | READY_NOT_SOLVED |
| RFC_ISL_TX_ORIGINAL_L1.cst | ISL | ATTACKER_ORIGINAL | L1 | 1.563 / 1.57542 / 1.588 | 4 native ports | Native CP phase; verify sense | cst/projects/ISL_C4_CUP_R14P7.cst | NONE | READY_NOT_SOLVED |
| RFC_SBA_TC_ORIGINAL_ISL.cst | SBA | ATTACKER_ORIGINAL | ISL | 10.55 / 10.6 / 10.65 | 4 native ports | Native CP phase; verify sense | cst/projects/SBAND_MATCHING_WIRE15.cst | NONE | READY_NOT_SOLVED |
| RFC_SBA_TC_ORIGINAL_SAR.cst | SBA | ATTACKER_ORIGINAL | SAR | 8.9 / 9.65 / 10.4 | 4 native ports | Native CP phase; verify sense | cst/projects/SBAND_MATCHING_WIRE15.cst | NONE | READY_NOT_SOLVED |
| RFC_SBA_TC_ORIGINAL_L1.cst | SBA | ATTACKER_ORIGINAL | L1 | 1.563 / 1.57542 / 1.588 | 4 native ports | Native CP phase; verify sense | cst/projects/SBAND_MATCHING_WIRE15.cst | NONE | READY_NOT_SOLVED |
