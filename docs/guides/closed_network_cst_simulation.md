# 폐쇄망 CST 정식 라이선스 모델 이관·해석 지침

작성: 2026-10-04. 현재 사용자 결정은 Learning Edition에서 추가 mesh/해석 중단, 모델링만 수행이다. 이 문서의 해석 절차는 추후 폐쇄망 정식 환경에서 수행한다. 정식 라이선스가 모든 solver와 모든 계산 자원을 자동 제공하는 것은 아니므로 실제 보유 solver·HPC 권한·RAM을 확인한다.

## 1. 이번에 만든 조립 모델

`cst/projects/SPACECRAFT_KA_MODEL_ONLY_V2.cst`는 CST 2026에서 실제 생성·저장한 최종 모델이다. **위성체 PEC 외곽 면 8개 + Ka 등가 포물면 반사판 2개 = 10개 면 형상**이다. EM mesh 생성, 포트 설정, solver 실행은 하지 않았다. 저장된 solver/frequency 설정은 새 프로젝트 초기값일 뿐 해석 설정 승인이나 결과가 아니다. 최초 `SPACECRAFT_KA_MODEL_ONLY.cst`는 이전 작업본이고 이관 기준은 V2다.

| 항목 | 정의와 상태 |
|---|---|
| 위성체 | SSOT `hull_cross_section.csv`의 6개 YZ 꼭짓점을 X=0…6000 mm로 연장한 6측면+2단면 |
| 재료 | 두께 없는 ideal PEC sheet shell. 실제 패널 두께·MLI·복합재·접합 저항을 재현하지 않음 |
| KAA1 기준 | (5965, −1100, 850) mm; Panel 1 outward normal +Z |
| KAA2 기준 | (5965, 1285, 530) mm; Panel 5 outward normal (0, +√3/2, −0.5) |
| 반사판 | 직경 220 mm, 등가 초점거리 151.111258 mm, z=r²/(4F), rim depth 약 20.018 mm |
| 배치 가정 | 저장된 설치 reference를 포물면 vertex로 사용. 실제 장착 datum/hinge가 확인되면 별도 모델 버전에서 교정 |
| 지향 | 현재 저장된 panel outward normal 기준 reference orientation. 실제 Ka 지향각 sweep 미적용 |
| 기타 안테나 | 원래 설치 reference를 manifest에 보존. 이번 모델에는 S/L/ISL/SAR 방사체·급전 포트를 추가하지 않음 |

반사판은 CST `AnalyticalFace`의 연속 해석적 곡면으로 생성했다. 이는 기존 aperture 적분에 사용한 **equivalent paraboloid**의 기하 표현이다. 실제 Cassegrain의 primary F/D, hyperboloid secondary, septum/horn, strut, gimbal을 재현한 제품 CAD가 아니다. Fe=151.11 mm를 실제 제품 높이/급전 위치로 간주하지 않는다. 기존 Ds=44 mm는 aperture 적분의 blockage 값이므로 이를 임의 위치의 실물 부반사판으로 추가하지 않았다.

새 모델은 기존 frozen pattern을 수정하지 않는다. 현재 RFI 보고서는 그대로 자유공간 우선이며, 새 모델만 생성했다는 이유로 installed pattern이나 S21이 확보되었다고 표시하지 않는다.

## 2. 이관할 파일

1. 실제 프로젝트: `cst/projects/SPACECRAFT_KA_MODEL_ONLY_V2.cst`와 같은 이름의 프로젝트 작업 폴더. 관련 CST 프로젝트 내부 데이터를 함께 복사하고 정식 환경에서 열기·저장 후 무결성을 확인한다.
2. 휴대용 geometry: `output/codex/spacecraft_ka_model/geometry_history.vba`, `model_manifest.json`, `spacecraft_ka_reference_mm.stl`.
3. 원본 geometry 정의: `data/spacecraft/simplified_spacecraft_v1/` 전체, 특히 hull·panels·installations·steering CSV.
4. 재현 코드: `cst/build_spacecraft_ka_model.py`, `cst/cst_com.py`, `cst/cst_com_common.py`, 그 의존 모듈. 실행할 경우 Python·numpy·pywin32와 CST COM 등록이 필요하다.
5. 기존 방사체 프로젝트: S 고정 surrogate, `LBAND_GNSS_FINAL_COMPROMISE`, `ISL_FIXED_10G6`, `KA_FEED_C_OEWG`의 프로젝트/원시 결과/geometry 입력. `cst/run_rfc_frequency_cases.py`의 build 정의를 따라 동일 파라미터를 사용한다.
6. 기존 pattern 및 provenance: `data/PATTERN_FREEZE.md`, `pattern_freeze_manifest.csv`, 분석 연결 CSV, `data/antenna_port_response_cst/`, `cst/results/rfc_frequency_cases/`, `output/codex/` 분석 보고서와 입력 hash.

`.cst`와 대형 작업 폴더는 `.gitignore`의 로컬 산출물이다. **Git clone만으로 모델이 이관되지 않는다.** 별도 반입 패키지와 SHA-256 목록을 준비한다. 원본 frozen 데이터·코드는 Git으로 관리한다. STL은 mm로 가져오며 STL 자체에는 단위·재료·포트·곡면 정확도가 없다. STL triangle은 CAD tessellation이지 EM mesh가 아니다. 곡면 정확도가 필요한 Ka 해석에는 `.cst` 또는 해석적 VBA 재생성을 우선한다.

새 프로젝트의 history에 units mm/GHz를 먼저 설정한 뒤 geometry_history.vba를 적용할 수 있다. 이 VBA에는 mesh/solve/port가 없다. PowerShell에서 repo 루트로 이동한 후 `python cst/build_spacecraft_ka_model.py --build-cst`로 재현한다. 이미 동일 생성 프로젝트가 있으면 덮어쓰기를 거부한다. 재생성은 별도 반입 작업 디렉터리/새 프로젝트에서 수행하며, 열려 있는 프로젝트를 덮어쓰지 않는다.

## 3. 정식 환경에서 먼저 확인할 것

- CST 2026 또는 지원되는 상위 버전에서 프로젝트를 복사본으로 연다. 버전 변환 후 실제 face 수 10, X 범위 0…6000 mm, KAA 좌표/normal/직경/깊이를 manifest와 대조한다.
- `mesh_generated=false`, `solver_started=false`, port 0이라는 현재 상태를 확인한다. geometry-only 모델 그대로 Solve를 눌러 방사 패턴을 기대하면 안 된다.
- 실제 장착 datum, Ka 광학·급전·지지대 CAD, 패널 재료/두께, 케이블·필터·접지·브래킷 자료를 확보한다. 입력이 없으면 근사 상태를 그대로 표시한다. 기존 설치 좌표를 면 위로 임의 투영하거나 ISL의 X=6375 mm 돌출을 제거하지 않는다.
- 기타 방사체는 기존 고정 antenna project에서 불러온다. CST source antenna local +Z boresight와 body normal을 일치시키고, 참고 Python 모델의 local +X=body +X, local +Y=Z×X를 사용한다. RF 분석 내부의 +X boresight 프레임과 혼동하지 않는다. 프로젝트 merge/import 시 solid뿐 아니라 port 끝점·극성·기준면도 같은 변환을 해야 한다.
- KAA1/2 모두 현재 기준 방향으로 배치되어 있다. 운용 지향각은 steering constraints와 실제 운용 scenario로 정하고 별도 configurations에 기록한다. hinge 위치 미확보 상태의 회전을 실제 기구 운동으로 검증했다고 하지 않는다.

## 4. 현재 미완료 항목과 변경 방법

| 미완료 | Learning Edition에서의 근거 | 정식 환경에서 할 일 |
|---|---|---|
| L 설치 패턴 GPSA1/2 | R1.25 국부 구조도 133,920 cells, 축소 GPSA1도 103,680으로 미실행 | 원래 L geometry/ports 유지, 실제 장착 구조 포함. 제한 때문에 줄인 구조를 복원하고 mesh convergence부터 수행 |
| S 최종 installed pattern | 작은 patch에서만 99,330 / 98,670 cells 해석; extent/mesh convergence 미확인 | R3/R4/R5 또는 더 큰 실제 geometry로 범위 수렴 확인. 잠정 결과를 제품/전체위성 결과로 승격하지 않음 |
| S at Ka | 255,600 cells에서도 초과 | 별도 25.5–27 GHz 고정 S 프로젝트, fine geometry mesh와 전체 컷/3D·정규화 검증 |
| L at SAR/ISL | HIGH 212,940 cells | L geometry 유지, 8.9–10.65 GHz 범위 분리하여 passive response 해석 |
| L at Ka | 1,467,648 cells | Ka만 따로 해석. 높은 파장 해상도와 1 mm급 L patch/probe 구조의 국부 refinement 둘 다 필요 |
| Ka 전체 reflector full-wave | 기존은 CST feed + Python aperture 적분; 전체 reflector CST 해석 아님 | 실제 optical/feed CAD 확보 후 단독 reflector부터 full-wave 또는 지원되는 hybrid/IE/PO 경로 검증 |
| 전체 위성 설치·근거리 결합 | 6 m 위성체의 고주파 전기적 크기가 큼 | 포트 포함 multi-antenna full-wave/검증된 hybrid 모델로 S21 추출. 계산 규모와 solver 지원성을 별도 산정 |
| SAR 절대 RFI | 패턴/실제 송신·수신 전단 데이터 미결합 | 실제 SAR geometry/ports와 8.9–10.4 GHz band, emission/mask/전력/운용 조건을 확보해 새 분석 binding으로 등록 |

정식 환경에서는 Learning Edition의 100,000-cell guard를 그대로 사용하는 `run_rfc_frequency_cases.py` / `run_limited_installed.py`를 무조건 실행하지 않는다. **별도 복사본/설정에 환경별 cell budget를 두고, 정식 라이선스와 실제 RAM/HPC 자원 한도에 맞는 preflight를 유지**한다. `if mesh_cells >= 100000` 분기만 지워 무제한 실행하는 방법은 권장하지 않는다. coarse StepsPerWave=4, ratio=10의 기존 예산 설정을 최종 mesh로 쓰지 않는다. export/정규화/오류 검사 코드는 재사용한다.

## 5. 해석 순서와 주파수

### 5.1 단독 안테나 검증

먼저 고정 S/L/ISL/Ka feed를 단독으로 해석하여 기존 CST 결과와 비교한다. S/L/ISL의 quadrature 포트 진폭·위상·50 Ω 기준을 원래 프로젝트에서 읽는다. 임의 tuning을 하지 않는다. RealizedGain, accepted Gain, intended CP 및 complex Eθ/Eφ를 각각 저장한다. solver 로그, mesh 통계, accepted fraction, S-matrix passivity를 검증한다.

### 5.2 Ka reflector 검증

현 등가 반사판 모델은 passive scatterer다. 적절한 실제 feed/포트 또는 지원되는 field source가 없으면 방사 패턴을 직접 계산할 수 없다. 기존 OEWG horn을 등가 초점에 단순 배치하고 실제 Cassegrain이라고 부르지 않는다. 공급자 CAD가 없는 경우 별도 명시적 equivalent optical excitation 모델로 구성하고 feed phase-centre·위상·power reference를 검증한다.

우선 반사판만의 단독 해석을 25.5/26.25/27 GHz에서 수행한다. PEC뿐 아니라 실제 재료 손실·지지대·secondary shadow·feed spillover와 CP를 반영할 수 있는지 확인한다. 기존 데이터시트의 boresight/0.5°/0.75°/1° 범위 비교는 유지하되, 그 밖의 side/backlobe를 envelope로 가린 결과 대신 raw 계산 결과도 제출한다. Ka 주엽은 0.05° 또는 그에 준하는 세밀한 angular sampling으로 기록한다.

### 5.3 S/L 설치 패턴

원래 방사체/포트를 유지한 free-space와 installed 두 프로젝트를 동일 excitation·주파수·gain reference로 계산한다. S는 nadir/zenith 각각, L은 GPSA1/2 각각이다. S의 SBA1/SBA4 reference는 동일 surrogate의 두 제품 형상이라는 뜻이 아니므로 구분한다.

국부 모델을 사용할 경우 실제 SSOT plane·finite facet·rear cap을 유지하고 R3/R4/R5 이상의 extent convergence를 확인한다. DeltaG=Ginstalled−Gfree는 gain 종류를 일치시킨다. source envelope 보정값은 reference가 유효한 자기 운용 대역에서만 적용한다. 다른 대역에는 검증되지 않은 datasheet 이득을 만들어 넣지 않는다. 전체 3D farfield를 실제 solver로 export하며 두 컷을 축대칭으로 복제하지 않는다.

### 5.4 다중 안테나 결합 S21

full spacecraft shell에 필요한 방사체와 feed ports를 동일 body 좌표로 배치한다. 하나의 방사체를 가진 동일 설치의 TX/RX는 별도 분리 안테나 경로로 만들지 않는다. 각 포트 excitation, 비활성 포트 termination, reference impedance, de-embedding plane을 명시한다. 원시 복소 Sij를 모든 관련 주파수에서 추출한다.

S/L/ISL의 4-port CP 조합은 **포트 하나의 S21을 논리 RF 채널 결합이라고 사용하면 안 된다.** 원시 S matrix와 실제 TX quadrature vector, RX coherent combining/network를 같이 보존한다. 실제 수신 combiner가 있으면 전력파 정규화 하에 a_rxᴴ S_rx,tx a_tx를 사용하고 combiner 손실·reflection을 중복 적용하지 않는다. incoherent port-power 합은 coherent CP 수신과 다른 모델이다. 실제 장비 입력 기준으로 네트워크를 검증한 후 논리 TX→RX transfer를 등록한다.

full-wave S21에 antenna radiation/mismatch/공간 구조가 포함되어 있으면 그 위에 Gtx+Grx−FSPL이나 mismatch를 다시 더하지 않는다. 포트 평면에서 얻은 transfer를 `CstCouplingModel`의 요구 주파수·pair ID·reference convention에 맞춰 변환하고 원시 데이터와 변환식을 남긴다. plane wave illumination의 far-field pattern과 근거리 port-to-port S21을 혼동하지 않는다.

### 5.5 대역 분리

| 대역 | 저/중/고 GHz | 역할 |
|---|---|---|
| S-TC | 2.0 / 2.06 / 2.12 | S RX; 송신 spur 유입 평가 시 실제 mask 필요 |
| S-TM | 2.2 / 2.25 / 2.3 | S TX, 다른 RX의 해당 대역 응답 |
| L1 | 1.563 / 1.57542 / 1.588 | L RX |
| L2 | 1.21737 / 1.2276 / 1.23783 | L RX; 기존 assumed 20.46 MHz window |
| L5 | 1.164 / 1.17645 / 1.189 | L RX |
| SAR | 8.9 / 9.65 / 10.4 | SAR 미결합 항목 보완; 전체 band 검증 |
| ISL | 10.55 / 10.6 / 10.65 | ISL TX/RX |
| Ka | 25.5 / 26.25 / 27 | Ka TX, S/L/ISL RX 응답 |

6 m 모델을 1–27 GHz 단일 full-wave sweep으로 시작하지 않는다. 저대역·SAR/ISL·Ka 대역을 프로젝트/solver별로 분리하고 요구 RF occupied bandwidth와 대역별 monitor를 구분한다. 3개 monitor는 초기 샘플이며 공진/필터/결합 변동을 포착하는 적응 sweep과 주파수 수렴을 추가한다.

## 6. Mesh·solver 선택과 수렴

- 27 GHz에서 6 m 길이는 약 540 λ다. license 제한 해제만으로 hex full-wave가 실용적이라는 뜻은 아니다. bounding box, λ 기준 분할, 작은 feed gap/probe/박판의 국부 세분화, RAM 및 wall time을 별도 산정한다.
- S/L 국부 구조는 기존 TD hex를 기준으로 시작할 수 있다. Ka 단독 reflector는 보유 tetra FD/IE 등 지원 solver를 비교한다. 대형위성 고주파 scattering은 실제 보유 hybrid/IE/asymptotic solver를 검토한다. 제품/포트/near-field 지원과 excitation coupling을 확인하고 GUI 도움말·해당 버전 매뉴얼로 설정한다. PO ray 결과를 near-field 포트 결합 정답으로 취급하지 않는다.
- solver별 mesh convergence를 최소 2회 refinement로 확인한다. 기존 local 기준 예: R5−R4 주요 영역 gain 차이 <0.5 dB, mesh peak 변화 <0.3 dB, cut RMS <0.5 dB. S21은 relevant pair/band의 amplitude·phase 변화와 노이즈 floor를 함께 비교하고 acceptance tolerance를 별도 정한다.
- port/probe/metal thickness/gap resolution과 high-frequency λ resolution을 함께 만족시킨다. coarse whole-box 설정만 올리는 대신 작은 구조와 scattering 면의 local mesh를 분리한다. 박판 처리 옵션은 해당 solver 지원 범위에서 확인한다.
- PEC shell 면 연결, 법선, CAD tolerance, ka analytical periodic seam을 검사한다. PEC shell이 실제 금속 패널 접합과 같다는 가정은 입력 기록에 남긴다. 실제 패널 내부·케이블·MLI가 필요하면 별도 geometry/material 추가 후 수렴을 다시 한다.
- PML/open boundary와 낮은 monitor 기준 거리, steady-state decay, energy balance, S passivity, port reference, farfield power normalization을 검사한다. mesh count만 통과했다고 신뢰 가능한 패턴이 되지 않는다.

## 7. 결과 등록과 RFI 재검증

raw complex S, Gain/RealizedGain/CP, full 3D + 독립 XZ/YZ cuts, 포트·조합 가중치, 주파수 grid, material, mesh, solver 로그/버전, CAD/입력 SHA-256를 제출한다. source는 CST 정식 해석, geometry fidelity는 실제/근사 여부를 구분한다.

승인된 installed 결과만 별도 dataset과 `installed_patterns.csv`의 ACCEPTED 행으로 등록한다. 원래 frozen free-space는 수정하지 않는다. 새 S21은 별도 결합 dataset으로 등록한다. 현재 `output/codex/결과보고서.md`의 120개 미판정 경로를 우선 보완하고 동일 6개 케이스 × 3개 scenario를 다시 실행한다.

Ka RX와 L TX는 만들지 않는다. ISL RX는 유지한다. SAR 실제 source/susceptibility 입력이 없으면 절대 RFI는 여전히 미판정이다. 실제 out-of-band emission mask, RX rejection, P1dB/IIP3, GNSS C/N0/J/S, 동시 활성/Ka steering 정보는 EM 모델과 별도로 필요하다. 이상 필터에서 기본파 비중첩이라는 현재 결과를 전체 EMC 적합으로 바꾸지 않는다.

최종 보고서에는 어떤 geometry/패턴/S21을 어떤 scenario/pair에 적용했는지, free-space→installed/full-wave로 바뀐 margin, 남은 가정·미판정 항목, 원본 CSV 및 hash를 추적 가능하게 남긴다.
