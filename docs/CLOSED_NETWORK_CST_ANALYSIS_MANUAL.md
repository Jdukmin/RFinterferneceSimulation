# 폐쇄망 CST 실행 매뉴얼

현재 **18개 프로젝트 저장·메쉬 확인 완료 / 24개 계획**이다. KAA reflector 4개와 SAR 2개는 확정 CST/CAD 원본이 없어 준비 미완료다. 이 문서를 전체 준비 완료 증빙으로 사용하지 않는다. 모든 저장 프로젝트는 solver를 실행하지 않았다.

## A. 목적과 10개 경로

1. KAA → SBA_TM (STM)
2. KAA → L1 (L1)
3. KAA → SAR (SAR)
4. KAA → ISL_RX (ISL)
5. ISL_TX → SAR (SAR)
6. ISL_TX → SBA_TM (STM)
7. ISL_TX → L1 (L1)
8. SBA_TC → ISL_RX (ISL)
9. SBA_TC → SAR (SAR)
10. SBA_TC → L1 (L1)

KAA는 attacker only다. 정상 Ka 반송파 blocker는 이번 범위에서 제외한다. Victim operating frequency에서 attacker와 receiver 패턴을 결합한다.

## B. 프로젝트 inventory

| Project filename | Antenna | Configuration | Victim band | Frequencies (GHz) | Port | Polarization | Geometry source | Spacecraft | Solver status |
|---|---|---|---|---|---|---|---|---|---|
| RFC_KAA_FEED_ONLY_STM.cst | KAA | FEED_ONLY | STM | 2.2 / 2.25 / 2.3 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/KA_FEED_C_OEWG.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_WITH_REFLECTOR_STM.cst | KAA | FEED_WITH_REFLECTOR | STM | 2.2 / 2.25 / 2.3 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/KA_FEED_C_OEWG.cst | NONE | INPUT_MISSING |
| RFC_KAA_FEED_ONLY_L1.cst | KAA | FEED_ONLY | L1 | 1.563 / 1.57542 / 1.588 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/KA_FEED_C_OEWG.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_WITH_REFLECTOR_L1.cst | KAA | FEED_WITH_REFLECTOR | L1 | 1.563 / 1.57542 / 1.588 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/KA_FEED_C_OEWG.cst | NONE | INPUT_MISSING |
| RFC_KAA_FEED_ONLY_SAR.cst | KAA | FEED_ONLY | SAR | 8.9 / 9.65 / 10.4 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/KA_FEED_C_OEWG.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_WITH_REFLECTOR_SAR.cst | KAA | FEED_WITH_REFLECTOR | SAR | 8.9 / 9.65 / 10.4 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/KA_FEED_C_OEWG.cst | NONE | INPUT_MISSING |
| RFC_KAA_FEED_ONLY_ISL.cst | KAA | FEED_ONLY | ISL | 10.55 / 10.6 / 10.65 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/KA_FEED_C_OEWG.cst | NONE | READY_NOT_SOLVED |
| RFC_KAA_WITH_REFLECTOR_ISL.cst | KAA | FEED_WITH_REFLECTOR | ISL | 10.55 / 10.6 / 10.65 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/KA_FEED_C_OEWG.cst | NONE | INPUT_MISSING |
| RFC_SBA_TM_ORIGINAL.cst | SBA | ORIGINAL | STM | 2.2 / 2.25 / 2.3 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/SBAND_MATCHING_WIRE15.cst | NONE | READY_NOT_SOLVED |
| RFC_INSTALLED_SBA_TM_NADIR.cst | SBA | INSTALLED | STM | 2.2 / 2.25 / 2.3 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/SBAND_MATCHING_WIRE15.cst | FULL_SSOT_8_PANELS | READY_NOT_SOLVED |
| RFC_INSTALLED_SBA_TM_ZENITH.cst | SBA | INSTALLED | STM | 2.2 / 2.25 / 2.3 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/SBAND_MATCHING_WIRE15.cst | FULL_SSOT_8_PANELS | READY_NOT_SOLVED |
| RFC_GPS_L1_ORIGINAL.cst | GPS | ORIGINAL | L1 | 1.563 / 1.57542 / 1.588 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/LBAND_GNSS_FINAL_COMPROMISE.cst | NONE | READY_NOT_SOLVED |
| RFC_INSTALLED_GPS_L1_GPSA1.cst | GPS | INSTALLED | L1 | 1.563 / 1.57542 / 1.588 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/LBAND_GNSS_FINAL_COMPROMISE.cst | FULL_SSOT_8_PANELS | READY_NOT_SOLVED |
| RFC_INSTALLED_GPS_L1_GPSA2.cst | GPS | INSTALLED | L1 | 1.563 / 1.57542 / 1.588 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/LBAND_GNSS_FINAL_COMPROMISE.cst | FULL_SSOT_8_PANELS | READY_NOT_SOLVED |
| RFC_ISL_ORIGINAL.cst | ISL | ORIGINAL | ISL | 10.55 / 10.6 / 10.65 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/ISL_C4_CUP_R14P7.cst | NONE | READY_NOT_SOLVED |
| RFC_INSTALLED_ISL_RX.cst | ISL | INSTALLED | ISL | 10.55 / 10.6 / 10.65 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/ISL_C4_CUP_R14P7.cst | FULL_SSOT_8_PANELS | READY_NOT_SOLVED |
| RFC_SAR_ORIGINAL.cst | SAR | ORIGINAL | SAR | 8.9 / 9.65 / 10.4 | 미확보 | 원본 phase 유지; CP sense 확인 | 미확보 | NONE | INPUT_MISSING |
| RFC_INSTALLED_SAR.cst | SAR | INSTALLED | SAR | 8.9 / 9.65 / 10.4 | 미확보 | 원본 phase 유지; CP sense 확인 | 미확보 | FULL_SSOT_8_PANELS | INPUT_MISSING |
| RFC_ISL_TX_ORIGINAL_SAR.cst | ISL | ATTACKER_ORIGINAL | SAR | 8.9 / 9.65 / 10.4 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/ISL_C4_CUP_R14P7.cst | NONE | READY_NOT_SOLVED |
| RFC_ISL_TX_ORIGINAL_STM.cst | ISL | ATTACKER_ORIGINAL | STM | 2.2 / 2.25 / 2.3 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/ISL_C4_CUP_R14P7.cst | NONE | READY_NOT_SOLVED |
| RFC_ISL_TX_ORIGINAL_L1.cst | ISL | ATTACKER_ORIGINAL | L1 | 1.563 / 1.57542 / 1.588 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/ISL_C4_CUP_R14P7.cst | NONE | READY_NOT_SOLVED |
| RFC_SBA_TC_ORIGINAL_ISL.cst | SBA | ATTACKER_ORIGINAL | ISL | 10.55 / 10.6 / 10.65 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/SBAND_MATCHING_WIRE15.cst | NONE | READY_NOT_SOLVED |
| RFC_SBA_TC_ORIGINAL_SAR.cst | SBA | ATTACKER_ORIGINAL | SAR | 8.9 / 9.65 / 10.4 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/SBAND_MATCHING_WIRE15.cst | NONE | READY_NOT_SOLVED |
| RFC_SBA_TC_ORIGINAL_L1.cst | SBA | ATTACKER_ORIGINAL | L1 | 1.563 / 1.57542 / 1.588 | 4 native discrete ports | 원본 phase 유지; CP sense 확인 | cst/projects/SBAND_MATCHING_WIRE15.cst | NONE | READY_NOT_SOLVED |

[전체 경로·출력 위치 CSV](closed_network_cst_project_inventory.csv)와 [preflight 검증](closed_network_preparation_validation.json)을 함께 사용한다. INPUT_MISSING 행은 .cst가 존재하지 않는다. README/계획 파일을 CST project로 세지 않는다.

## C. 실행 순서

1. KAA STM feed-only → reflector; L1 feed-only → reflector; SAR feed-only → reflector; ISL feed-only → reflector. Reflector 원본 확보·검증 후 해당 네 행을 생성해야 한다.
2. Victim Original SBA TM / GPS L1 / ISL을 실행한다. 기존 frozen reference와 섞지 않는 비교 원본이다.
3. SBA TM installed NADIR와 ZENITH를 각각 실행한다.
4. GPS L1 installed GPSA1와 GPSA2를 각각 실행한다.
5. ISL RX installed를 실행한다.
6. SAR authoritative Original과 Installed를 실행한다. 현재 full K8 원본 미확보이므로 실행할 수 없다. SAR leaf를 전체 수신 안테나로 대체하지 않는다.
7. 추가 attacker off-band ISL_TX @ SAR/STM/L1, SBA_TC @ ISL/SAR/L1을 실행한다. 기존 geometry를 그대로 사용하며 raw pattern을 얻는다.

## D. 각 프로젝트 실행과 export

프로젝트를 열고 solver를 실행하는 데 Python은 필요 없다. 아래 자동 export/검증 스크립트를 쓰려면 폐쇄망 Windows에 Python 3.10 이상, `numpy`, `pywin32`와 CST COM 등록이 필요하다. 인터넷 접속 없이 설치할 wheel 및 Python 설치본을 사전에 승인된 경로로 준비한다. CST 버전이 다르면 프로젝트를 사본으로 열어 호환성·포트·메쉬를 다시 확인한다.

1. 해당 .cst를 연다. 원본 파일을 여는 것이 아니라 closed_network 하위 사본을 연다.
2. geometry를 확인한다. Installed의 FULL_SPACECRAFT에는 PANEL_1…PANEL_8 전부 있어야 한다. Antenna native geometry·material·port·reference plane은 원본과 같아야 한다.
3. native 4-port excitation을 확인한다. S는 0/90/180/270°, GPS·ISL·KAA는 0/−90/−180/−270°를 coherent far-field combination에 사용한다. 포트별 solver를 실행한 뒤 기존 위상을 결합한다.
4. range와 edge/center 3개 monitor를 확인한다. 이전 operating-band monitor는 제거해 unrelated frequency를 계산하지 않는다.
5. Mesh Update와 mesh quality/셀 수/RAM을 확인한다. 전체 형상을 자르거나 Learning Edition 100k 제한에 맞추지 않는다.
6. 정식 라이선스에서 Time Domain solver를 시작한다. 오늘은 이 단계를 수행하지 않았다.
7. solver log에서 모든 port excitations 완료, 에너지 잔류량, mesh convergence, S-matrix passivity와 accepted power를 확인한다. Accuracy 설정만으로 convergence 완료라고 보지 않는다.
8. 결과 검증 후 아래 exporter로 RAW XZ/YZ, realized gain, accepted-power gain, complex Eθ/Eφ와 CP±를 출력한다.

```powershell
python cst/export_closed_network_patterns.py cst/projects/closed_network/kaa/RFC_KAA_FEED_ONLY_STM.cst --convergence-accepted
```

이 명령은 Solver.Start를 호출하지 않는다. CombineResults.Run은 이미 계산된 port 결과의 후처리다. `--convergence-accepted`는 사용자가 solver/mesh 검증을 실제 완료한 경우에만 지정한다.

9. RAW filename은 **f<GHz 소수점 6자리>_XZ.csv / _YZ.csv**다. 예: f2.200000_XZ.csv, f1.575420_YZ.csv. 기존 간략 소수점 이름과 혼동하지 않는다. 각 frequency를 독립 export한다. Full 3D는 CST Farfield 3D ASCII export로 추가 보존하며 metadata에 quantity·좌표계·단위를 기록한다. CP±의 RHCP/LHCP 대응은 CST의 관찰 방향 convention을 확인하고 지정한다.
10. inventory의 expected_output_directory로 복사한다. RAW CSV, raw_s_matrix.npz, provenance.json, solver/convergence log를 함께 보존한다. accepted normalization이 불안정하면 export는 보존하되 registration을 거절한다.

RAW output에는 gain floor/clipping을 적용하지 않는다. 실제 linear zero는 −Inf로 보존되고 import 단계에서 검토 대상으로 거절된다. 원본을 finite 값으로 대체하지 않는다.

## E. 실패 기록

Mesh failure / solver failure / port excitation failure / convergence failure / passivity issue / normalization issue를 project ID, CST version, solver log, mesh cells, frequency, port와 함께 기록한다. 실패 시 status=FAILED 또는 INPUT_MISSING으로 유지하고 0 dB·기존 free-space pattern으로 대체하지 않는다.

## F. Full spacecraft 좌표와 메쉬

8개 완전한 side/end-cap SSOT outer surfaces를 사용한다. 일부 panel crop은 없다. 기존 antenna local geometry/port를 전혀 이동시키지 않기 위해 **CST global solver frame을 원본 antenna local frame으로 유지**하고 전체 spacecraft를 동일한 rigid coordinate transform으로 옮겼다. 이것은 crop이나 설치 위치 변경이 아니다. 각 preflight.json에 실제 body 설치 위치, R_BL, 모든 body/local panel vertices를 남겼다. `p_B = R_BL p_L + installation_position_B`로 복원하면 원래 spacecraft 좌표와 일치한다. Body +X/+Y/+Z와 CST +Z boresight를 혼동하지 않는다.

KAA gimbal 위치와 SAR 위치를 포함한 모든 SSOT installation coordinate는 full_spacecraft_geometry.json에 들어 있다. SimplifiedSpacecraftBuilder가 실제 구조물로 정의한 것은 8개 outer panel이다. Gimbal bracket, 실제 reflector CAD, SAR array CAD와 cable/radome는 저장소에 없어 금속 형상으로 invent하지 않았다. Outer panels는 기존 CST facet 모델의 PEC sheet 처리이며 임의 두께를 넣지 않았다.

- RFC_INSTALLED_SBA_TM_NADIR.cst: 55,678,740 cells; 128 bytes/cell 단순 계획값 6.6 GiB.
- RFC_INSTALLED_SBA_TM_ZENITH.cst: 55,522,584 cells; 128 bytes/cell 단순 계획값 6.6 GiB.
- RFC_INSTALLED_GPS_L1_GPSA1.cst: 10,886,400 cells; 128 bytes/cell 단순 계획값 1.3 GiB.
- RFC_INSTALLED_GPS_L1_GPSA2.cst: 10,886,400 cells; 128 bytes/cell 단순 계획값 1.3 GiB.
- RFC_INSTALLED_ISL_RX.cst: 2,269,049,730 cells; 128 bytes/cell 단순 계획값 270.5 GiB.

128 bytes/cell은 실제 CST RAM 보증값이 아닌 대략적 계획 산식이다. ISL 약 22.69억 cells는 정식 라이선스에서도 큰 자원이 필요하다. 폐쇄망의 hardware/RAM에 맞는 mesh 계획과 convergence 검증이 필수이며 형상을 삭제해서 해결하지 않는다.

## G. 미확보 원본과 완료 조건

KAA validated reflector 기록은 D=220 mm, Fe=151.111258 mm, Ds=44 mm의 NON_CST_PYTHON aperture 모델이다. Actual reflector surfaces·feed relative placement·material·subreflector CAD를 확정하지 않는다. 이 값만으로 새 reflector CST를 구성하지 않았다. SAR 원본은 단일소자 SAR_LEAF_C_DUALFEED 예제만 있으며 K8 전체 antenna가 아니다. Owner가 authoritative geometry를 지정해야 누락 6개 project를 완성할 수 있다. 전체 completeness는 현재 INCOMPLETE_INPUT_MISSING이다.

## 검증 기록

18개 저장 프로젝트를 sidecar 없이 독립 폴더에서 다시 열어 원본 4-port endpoint, 재질/체적, 3개 monitor 및 installed 전체 8개 panel을 확인했다. `closed_network_reopen_validation.json`과 `closed_network_completeness.json`에 증거를 남겼다. Octave 9.2에서 합성 fixture로 native CST 좌표 변환과 FreeSpacePattern/InstalledPattern class 구분을 검증했으며 실제 RFI 계산은 실행하지 않았다.
