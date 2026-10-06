# Closed-network 현재 해석 범위

**기존 CST 22개 안에서 SBA/ISL 송신원을 설치형으로 반영했다. KAA는 단독 Feed/Reflector 모델, GPS는 Installed 수신 패턴, SAR는 기존 engineering 수신 패턴을 사용한다. Solver는 실행하지 않았다.** 이 폴더의 `owner_scope.json`, `project_inventory.csv`, `dataset_bindings.json`이 현재 closed-network 실행 범위를 기록한다. 상위 docs의 이전 단독 송신원/Original 수신원 비교 계획은 현재 primary 실행 계획에 적용하지 않는다.

## 안테나별 적용

| 대상 | CST 구성 | 방향 및 분석 사용 |
|---|---|---|
| KAA | 기존 Feed-only / Feed+Reflector 8개 유지 | 단독 +Z, 위성체 설치 해석 없음 |
| SBA 송신원 | 기존 off-band ISL/SAR/L1 파일 3개에 전체 bus hull과 두 SBA instance | NADIR=PANEL_6 법선, ZENITH=PANEL_4 법선 |
| ISL 송신원 | 기존 off-band SAR/STM/L1 파일 3개에 전체 bus hull | PANEL_7 법선인 body +X |
| SBA / ISL 수신원 | 기존 Installed 파일 사용 | 각 면 법선에 정렬 |
| GPS 수신원 | GPSA1/GPSA2 Installed 파일만 분석에 사용 | PANEL_3 법선에 정렬 |
| SAR 수신원 | 기존 Owner engineering pattern 사용 | CST 생성·해석 없음; peak 52 dBi / rear +2 dBi / 허용 PSD −176 dBm/Hz |

SBA 송신원 파일은 이름에 `ORIGINAL`이 남아 있지만 현재 내용은 **Installed 송신원**이다. 22개 파일명과 경로를 유지하기 위한 legacy filename이며 pattern binding은 `INSTALLED_SBA_TC_*`다. ISL도 같은 이유로 파일명은 유지하고 `INSTALLED_ISL_TX_*`로 연결한다. 수신원 Original 파일 3개는 참고용으로 보존하며 primary plan에서 제외했다. 실제 primary 계산은 10개 RFI pair, 37개 설치 identity / reflector 조합이다.

전체 위성체는 기존 SSOT의 8개 bus outer panel을 body 좌표에 고정한 모델이다. Crop하지 않았으며 물리적으로 완전한 satellite CAD라고 주장하지 않는다. 설치 좌표는 유지했다. 실제 mount/bracket 형상이나 새로운 안테나 dimension을 만들지 않았다. KAA gimbal 설치 해석과 SAR 설치 해석도 추가하지 않았다.

## SBA의 두 위치와 port 그룹

22개 제한 안에서 NADIR와 ZENITH를 누락하지 않도록 SBA 송신원 3개에는 동일 원본 안테나의 rigid instance 두 개를 넣었다.

| Instance | Ports | Native CP phases | Body boresight |
|---|---|---|---|
| SBA_NADIR | 1–4 | 0 / 90 / 180 / 270° | (0, +0.8660254, +0.5) |
| SBA_ZENITH | 5–8 | 0 / 90 / 180 / 270° | (0, 0, −1) |
| ISL | 1–4 | 0 / −90 / −180 / −270° | (+1, 0, 0) |

SBA는 두 그룹을 동시에 송신시키지 않는다. 해당 instance의 4개 port만 coherent combination으로 활성화하고 다른 그룹의 incident amplitude는 0으로 둔다. 비활성 port의 matched 50-ohm termination은 기존 S-parameter port에 따른 engineering 조건이며 실제 RF chain을 측정한 값이 아니다. Port 번호/endpoint 순서/임피던스와 source phase를 보존했다. Solver에서 SBA의 **8개 port 전체 S-matrix와 개별 port far-field**가 생성되도록 excitation 선택을 확인한다.

## 폐쇄망 실행과 export

1. 이 폴더의 inventory에서 해당 victim band, port 수, monitor 3개와 설치 identity를 확인한다.
2. 모든 Installed 모델은 full bus hull을 유지한다. 거대한 TD mesh를 그대로 실행하지 말고 정식 라이선스에서 IE/MLFMM/Hybrid의 port·material 지원과 자원을 검토한다. Solver 변경 시 개별 port excitation, S-matrix와 far-field가 유지되는지 확인한다.
3. Mesh 및 convergence를 확인하고 폐쇄망에서 solver를 실행한다. 현재는 실제 solver 결과가 없다.
4. 이번 port-group 구성을 지원하는 아래 exporter를 사용한다. 이전 4-port 전용 exporter로 SBA 8-port 결과를 처리하지 않는다.

```powershell
python cst/closed_network/export_patterns.py cst/projects/closed_network/sba/RFC_SBA_TC_ORIGINAL_SAR.cst --convergence-accepted
```

기본값은 NADIR와 ZENITH를 각각 후처리하여 별도 dataset에 export한다. 하나만 필요하면 `--installation-id SBA_NADIR` 또는 `SBA_ZENITH`를 지정한다. Exporter의 CombineResults.Run은 계산된 결과의 후처리이며 solver 시작 명령이 아니다. 수렴 확인 전에는 `--convergence-accepted`를 쓰지 않는다. IE/Hybrid result tree가 native TD와 다르면 해당 tree와 gain normalization을 먼저 검증한다.

RAW는 `dataset_bindings.json`의 directory에 저장한다. 각 monitor마다 `f9.650000_XZ.csv`, `f9.650000_YZ.csv`처럼 6자리 GHz filename을 사용한다. Installed 프로젝트에서는 local cut 방향을 body 방향으로 변환하여 CST 결과를 샘플링하고, gain CSV는 antenna-local +Z 규약으로 저장한다. Complex Eθ/Eφ는 solver-global spherical basis이며 global angles도 기록한다. RAW clipping/floor는 금지한다. 설치 회전을 MATLAB에서 중복 적용하지 않는다.

```powershell
python analysis/closed_network/register_closed_network_patterns.py
```

등록기는 dataset별 project hash, 설치 identity, active port 그룹, normalization과 local resampling을 검증한다. 모든 설치형 TX/RX는 InstalledPattern, KAA는 FreeSpacePattern, SAR는 EngineeringReceiveBaseline이다. 원래 frozen dataset을 덮어쓰지 않는다.

```matlab
addpath('analysis/closed_network');
rows = run_closed_network_rfi(true);   % 실제 export 입력의 존재 확인
rows = run_closed_network_rfi(false);  % 실제 export 등록 후 10개 pair / 37개 조합
```

현재 plan은 GPS/SBA/ISL 수신원에 Installed 패턴만 사용하므로 Original 대비 비교 CSV에는 primary 비교 행이 없다. KAA Feed/Reflector 비교는 같은 installed victim과 같은 설치 identity에서 12개다. Antenna-port PSD / allowable PSD / margin / required suppression은 실제 CST export를 등록한 뒤 계산한다. SAR는 기존 peak 52 dBi, rear +2 dBi, NF4 baseline을 유지한다. 입력/solver/normalization 실패를 0 dB나 다른 패턴으로 대체하지 않는다. Receiver chain 입력은 여전히 별도로 필요하다.

## 검증 및 재현

`python cst/closed_network/prepare_attacker_installations.py`는 SBA/ISL 송신원만 준비하며 KAA는 변경하지 않는다. `--metadata-only`는 binding/inventory만 갱신한다. `python cst/closed_network/validate_scope.py`는 22개 파일, 설치 방향, 모든 primary pair 연결과 standalone CST 재열기를 검증한다. 변경되지 않은 파일은 이전 재열기 결과와 정확한 binary hash를 대조한다. 검증 결과는 이 폴더의 `validation.json`과 `test_results.log`에 기록한다. Synthetic 입력 테스트는 실제 위성 RFI 결과가 아니다.
