# Finalized pattern inventory and Git policy

2026-10-04 기준. 확정은 현재 분석에 선택·고정된 baseline을 뜻하며 측정 검증이나 mesh 수렴을 뜻하지 않는다.

| 구분 | 위치 | 상태 / Git 관리 |
|---|---|---|
| S SBA1/SBA4 TC/TM 자유공간 | `data/Sband_TMTC/` | 8 CSV; frozen; 보존 |
| GNSS L1/L5 및 과거 L2 proxy 자유공간 | `data/Lband_GPS/` | 6 CSV; frozen; 실제 L2는 아래 별도 자료 사용 |
| GNSS 실제 L2 1227.6 MHz 자유공간 | `data/Lband_GPS_CST_L2/` | 2 CSV + provenance; frozen; 보존 |
| ISL 자유공간 | `data/Xband_ISL/` | 12 CSV + 12 regions JSON; frozen; active 10.6 GHz / 10.55–10.65 GHz |
| Ka KAA 자유공간 | `data/Kaband_KAA_CST/` | 6 CSV + 6 regions JSON + validation; frozen; 보존 |
| 과거 Ka 미결합 자료 | `data/Kaband_DLS/` | 2 CSV; frozen archive; 현재 active pattern 아님 |
| 대역별 고정 형상 포트 응답 | `data/antenna_port_response_cst/` | 340 공개 컷 + provenance; RFI 보조 데이터; baseline freeze와 별도; 보존 |
| 승인된 설치 패턴 | `data/spacecraft/simplified_spacecraft_v1/installed_patterns.csv` | ACCEPTED 행 0개; 현재 없음 |
| S 잠정 설치 계산 | `cst/results/rfc_frequency_cases/RFC_S_LOW_SBA_{NADIR,ZENITH}_R1P75/` | 각 30개 raw 컷; 범위·mesh 수렴 미확인; 기본 분석에 설치 최종본으로 연결하지 않음; 증거 보존 |
| GPSA1/GPSA2 설치 패턴 | 해당 case의 `status.json` | mesh 초과; 미확보; 사용자 요청으로 작업 중단 |
| SAR | 현재 분석 binding 없음 | 최종 pattern 없음; 예제·후보 산출물을 baseline으로 승격하지 않음 |

`data/pattern_freeze_manifest.csv`의 56개 파일은 LF-normalized SHA-256로 보호한다. 실제 활성/민감도/과거 연결은 `pattern_bindings.csv`와 `antenna_functions.csv`에서 확인한다. 전체 frozen 목록이 모두 현재 활성이라는 뜻은 아니다.

설치 패턴 미확보 시 자유공간을 우선 사용한다. S의 잠정 설치 결과는 별도 참고 비교에만 사용한다. 대역별 port response는 total RealizedGain / accepted Gain / intended CP를 구분하며, 기본 baseline의 datasheet envelope와 혼합하지 않는다.

## Git 관리

- 최종 CSV/JSON, freeze manifest, bindings, 분석용 port-response 데이터, 계산 status, 원시 컷, 정규화 증거, 보고서와 재현 코드는 관리 대상으로 유지한다.
- `.gitignore`는 이번에 생성한 `cst/projects/RFC_*.cst`, `cst/projects/RFC_*/`, `ISL_FIXED_10G6.cst`와 해당 작업 폴더를 제외한다. 대형 solver workspace는 로컬에 보존한다.
- `*.geometry.json`과 `cst/results/`는 제외하지 않는다. 기존 Temp/ModelCache/Meshfill 제외 규칙도 유지한다.
- ignore는 추적 중인 파일을 자동으로 제외하거나 freeze 파일을 변경 방지하지 않는다. 이번 작업은 index에서 기존 파일을 제거하지 않는다. 다른 워커가 준비한 staged 변경도 그대로 둔다.
- 패턴을 재발행하지 않고 현재 목록과 hash만 확인한다. SAR 후보나 미검증 installed 결과를 final로 표기하지 않는다.

기계 판독 목록은 같은 폴더의 `finalized_pattern_inventory.json`을 참조한다. 원본은 기존 freeze manifest와 각 case의 status.json이다.
