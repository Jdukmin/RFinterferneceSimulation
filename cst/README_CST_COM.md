# CST 2026 Learning Edition — Windows COM automation

이 모델은 **SURROGATE_TRAINING_MODEL**이다. Beyond Gravity / former RUAG
SBA1/SBA4의 실제 설계 복원이나 성능 인증 모델이 아니다.

## 확인된 실행 환경

- Windows, Python **3.12.10**, `pywin32 312`.
- 설치 위치: `C:\Program Files\CST Studio Suite 2026`.
- GUI 표시: **CST Studio Suite 2026 [Learning Edition]**.
- 설치 `Image_Version` 및 저장된 ModelHistory: **2026.4**, build **20260414**.
- 이 설치에는 사용 가능한 CST bundled Python runtime / `cst.interface`가 없다.
  기존 내부 Python 메뉴는 없는 `AMD64\python\python` 실행 파일을 호출한다.
  새 스크립트는 외부 Python과 `win32com.client`만 사용한다.
- 기존 `cst_sband_helix_surrogate.py`는 이전 내부-Python 시도이며, 실행은 아래
  `cst_sband_helix_com.py`를 사용한다. 기존 파일과 SampleProject는 보존했다.

## 설치와 실행

저장소 최상위 PowerShell에서:

```powershell
python -m pip install pywin32
```

CST를 먼저 열고 빈 **Microwave Studio 3D project**를 활성화한다.
첫 연결은 `GetActiveObject("CSTStudio.Application")`, 실패 시
`Dispatch("CSTStudio.Application")`이다. `--attach-only`는 Dispatch를 금지한다.
Dispatch가 애플리케이션을 실행해도 기본 모드에서 프로젝트를 자동으로 만들지는
않는다. 열린 3D 프로젝트가 없으면 명확한 오류로 중단한다.
`Active3D`, `AddToHistory` 및 다른 late-bound COM 호출에는 `_FlagAsMethod`를 쓴다.

먼저 별도 빈 프로젝트에서 smoke test:

```powershell
python cst/cst_com_smoketest.py --attach-only
```

`COMSmokeTest:com_test_brick`, 10 × 10 × 10 mm PEC를 만든다.
성공 시 PEC와 1000 mm³ 부피를 읽어 확인한다. 같은 이름이 있으면 변경 전에
중단한다. 실패 시 단계, HRESULT(해당 오류가 COM 오류인 경우), 메시지를 출력하고
exit code 1을 반환한다. CST History 오류가 GUI 대화상자를 표시하면 닫은 후
COM 호출이 반환되어 오류가 출력된다.

smoke brick이 없는 빈 프로젝트를 선택하거나, 별도 프로젝트 생성 옵션 사용:

```powershell
python cst/cst_sband_helix_com.py --attach-only --new-project
```

이미 열린 빈 프로젝트를 사용하려면:

```powershell
python cst/cst_sband_helix_com.py --attach-only
```

옵션:

```powershell
python cst/cst_sband_helix_com.py --f0 2.25 --fmin 2.20 --fmax 2.30 --turns 3 --segments-per-turn 24 --ground-size-mm 110 --wire-radius-mm 1.25 --feed-gap-mm 2 --attach-only --new-project
```

주파수는 GHz, 길이는 mm다. 입력은 유한한 양수여야 하며 f0가 band 안에 있어야
한다. turn당 최소 8개, 전체 최대 240개 segment를 허용한다. 생성기는 기존
solid나 port가 있는 프로젝트에서 변경 전에 중단한다. 반복 실행은 새 프로젝트에서
수행한다. 중간 실패 시 완료된 history가 남으므로 새 프로젝트에서 다시 실행한다.
프로젝트는 자동 저장하지 않으며 CST GUI의 Save로 저장한다.

## 생성 모델

| 항목 | 기본 설정 |
|---|---|
| 중심 주파수 / band | 2.25 GHz / 2.20–2.30 GHz |
| 자유공간 파장 | 133.241092 mm |
| helix 반경 / pitch | 21.205978 mm / 30.645451 mm |
| 회전 / 근사 | 3 turns, 24 segments/turn, 72 chord segments |
| 도선 반경 | 1.25 mm |
| ground | 110 × 110 × 2 mm, PEC, Z=-2…0 |
| 급전 gap | ground top Z=0 → PEC 급전부 bottom Z=2 mm |
| port | Discrete Edge Port #1, S-Parameter, 50 Ω |
| radiation boundaries | 6면 open (add space), symmetry none |
| monitor | farfield (f=2.25), Frequency, Farfield |
| solver | HF Time Domain, Hexahedral FIT, TD-S, -30 dB |

실린더를 Y축 및 Z축으로 회전하고 이동해 polygonal helix를 만든 뒤 `Solid.Add`로
한 PEC solid로 합친다. 도선 두께 때문에 중심선을 Z=3.25 mm에서 시작하고,
Z=2 mm에서 시작하는 짧은 수직 급전부를 첫 segment에 연결한다. 따라서 2 mm는
금속 **표면** gap이며 도선 중심선과 ground의 거리와 구분된다. 진행 축은 +Z다.
단순한 축방향 모드 설계 시작점이며 실제 방사 패턴이나 정합은 solver 결과로
검증해야 한다.

```text
Components
  SURROGATE_TRAINING_MODEL
    ground
    helix
Ports
  port1
Field Monitors
  farfield (f=2.25)
```

기존 `data/Sband_TMTC`의 CSV는 `theta,gain` (dBi) screening 데이터다.
TC/RX 2.000–2.120 GHz, TM/TX 2.200–2.300 GHz이며 datasheet envelope를
1°로 재표본화한 근사 패턴이다. complex Eθ/Eφ, phase, polarization 정보가
없으므로 CST source로 사용하지 않는다.

## 문법 근거 — 설치 파일 우선

아래 경로는 설치 루트 아래의 실제 Dassault Systèmes 배포 매크로다.
임의 인터넷 예제의 `Wire` 명령은 사용하지 않았다.

- `Library\Macros\Construct\Demo Examples\Dipole Antenna^+MWS.mcs`:
  Brick, Cylinder, Units.Geometry/Frequency/Time, Solver.FrequencyRange,
  CalculationType TD-S, Boundary `expanded open`, Monitor Farfield.
- `Library\Macros\Construct\Coils\3D Helical Circular Inductor^-DS.mcs`:
  Transform.Angle / RotateAdvanced / TranslateAdvanced와 Solid.Add.
- `Library\Macros\File\ADS Converter 1.bas`:
  DiscretePort.Point1/Point2, UsePickedPoints, LocalCoordinates,
  Type SParameter, Impedance, Voltage, Current, Create.
  뷰 명령은 이 파일의 Plot.ZoomToStructure를 사용한다.
- `Library\Macros\Construct\Discrete Ports\Convert Discrete Edge Port to Discrete Face Port^+MWS.mcs`:
  Solid.GetNumberOfShapes / GetNameOfShapeFromIndex / IsPointInsideShape,
  Port.StartPortNumberIteration / GetNextPortNumber / GetLineImpedance.
- `Library\Macros\Solver\Mesh\Add Sheets for Skindepth Meshing^-DS.mcs`:
  Solid.GetVolume.
- `Online Help\general\student\student_edition_-_limitations.htm`:
  100,000 hexahedral cells / 20,000 second-order tetrahedral cells;
  허용 solver와 CAD import/export 제한.
- 실행 중 COM IApplication type information에서 `Active3D`, `NewMWS`와
  `OpenFile` 등 실제 메서드명을 읽어 확인했다.

`ChangeSolverType "HF Time Domain"`과 모든 모델링 명령은 실제 Learning Edition에서
실행했고 GUI의 Time Domain Solver Parameters에서 Hexahedral FIT / -30 dB를
확인했다. Boundary의 VBA 값 `expanded open`은 GUI의 `open (add space)`에
대응한다. 표시 명령의 초기 오류는 수정했으며 최종 생성 로그는 오류 없는 재실행이다.

## 실제 검증 결과 — 2026-10-03 KST

- GetActiveObject attach와 Active3D / AddToHistory 성공.
- Dispatch 연결과 Active3D / Solid readback도 실제 성공: `dispatch_check.log`.
- smoke PEC brick 생성, GUI 형상 확인 성공.
- 생성기 전체 실행 성공: `helix_build.log`.
- ground와 helix 두 PEC solid 및 각 부피 readback 성공.
- 72개 chord midpoint 모두 PEC 내부, 3 turns의 +Z 진행 확인.
- 급전 (R,0,1) mm는 두 solid 모두 외부, (R,0,2.1) mm는 helix 내부:
  `geometry_verification.log`.
- Port #1, 50 Ω COM readback 및 GUI S-Parameter / Z=0→2 좌표 확인.
- GUI에서 2.20–2.30 GHz, 6면 open (add space), 2.25 GHz monitor 확인.
- 실제 Mesh View: **41,472 Hexahedral FIT cells**, 100,000 제한 이하.
  이 수는 기본 모델과 검증 당시 CST 기본 mesh 설정에 대한 결과다.
  옵션 또는 mesh refinement 변경 후에는 다시 확인해야 한다.
- 반복 실행이 변경 없이 중단됨: `duplicate_check.log`.
- `SURROGATE_TRAINING_MODEL.cst`를 GUI에서 저장했고 편집 가능한 상태로 유지.
- 모든 저장소 변경은 `cst/`에만 있다. 기존 simulation code/data는 변경하지 않았다.

검증 utility는 **기본 모델**을 대상으로 한다:

```powershell
python cst/verify_geometry_com.py
```

Learning Edition은 저장 history code를 `Scrambled` 형태로 기록한다. 따라서
검증된 VBA 원문은 Python 함수와 설치 매크로를 근거로 유지한다. 생성 모델의
runtime/mesh cache 디렉터리는 `.gitignore`에 제외하며 `.cst` 파일을 보존한다.

## 수동으로 남은 단계와 확장

첫 버전은 **solver를 자동 실행하지 않는다**. `--run`은 제공하지 않는다.
CST GUI에서 mesh / port를 확인한 후 Home → Setup Solver → Start로 실행한다.
S11, 효율, gain, axial ratio, far-field pattern 및 mesh convergence는 아직
해석하지 않았다. mesh 제한 통과는 RF 정확도 검증을 의미하지 않는다.

상용 CST 확장은 (1) 검증된 antenna far-field의 complex Eθ/Eφ와 phase,
polarization을 export, (2) Farfield Source의 좌표·편파·power normalization 지정,
(3) 위성 CAD와 재질을 가진 별도 satellite scattering 프로젝트 작성,
(4) Asymptotic Solver로 installed pattern / coupling 평가 순서로 진행할 수 있다.
이 단계들의 API는 상용 설치의 History/VBA에서 다시 확인하고 별도 모듈로 추가한다.
현재 screening CSV를 complex far-field로 변환해 사용하는 확장은 하지 않는다.
