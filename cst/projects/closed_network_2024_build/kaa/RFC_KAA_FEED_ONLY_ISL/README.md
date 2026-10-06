# RFC_KAA_FEED_ONLY_ISL — CST 2024 재구축

이 macro는 기존 numeric geometry를 새 프로젝트에 생성합니다. CST 2024에서 아직 실행하지 않았으며 solver를 자동 실행하지 않습니다. 설치 identity: 없음; native +Z. 위성체: NONE.

1. CST Studio Suite **2024**를 실행하고 Help → About에서 버전을 확인합니다.
2. 새 빈 Microwave Studio 3D project를 만듭니다. 기존 `.cst`를 열지 않습니다.
3. Macro → New Macro의 editor에 `build_2024.vba` 전체를 붙여 넣고 실행합니다. 필요하면 파일을 로컬 `.mcr`로 복사해 editor로 엽니다. History item에 `Sub Main` 전체를 직접 넣지 않습니다.
4. Message window와 History list 오류를 확인합니다. 오류가 있으면 중단하고 command/line/error를 기록합니다.
5. `validation_reference.json`과 object/component count, bounding box, 주요 치수와 설치 방향을 비교합니다. 설치형은 PANEL_1~PANEL_8 전부를 확인합니다.
6. Port 4개, endpoint/reference plane, 50 Ω와 CP phase를 확인합니다. SBA 두 설치형은 1–4 NADIR / 5–8 ZENITH를 각각 활성화하며 나머지는 amplitude 0입니다.
7. Farfield monitor 3개(10.55, 10.6, 10.65 GHz), frequency range, open boundary를 확인합니다.
8. Mesh와 자원을 점검합니다. 권장 검토: `TD_FD_WITH_RESOURCE_REVIEW`. 초기 TD 설정은 실행 권고가 아닙니다. Installed ISL은 약 2.269e9-cell TD 계획 때문에 IE/MLFMM 또는 Hybrid를 먼저 검토합니다. hull을 자르지 않습니다.
9. CST 2024에서 native **`RFC_KAA_FEED_ONLY_ISL_CST2024.cst`**로 Save As합니다. 저장 위치는 repository의 `cst/projects/closed_network_2024_native/kaa`입니다. master manual의 native validation 기록을 남깁니다.
10. 폐쇄망 사용자가 solver/port/mesh/resource를 승인한 뒤 직접 solver를 실행합니다. 수렴 및 normalization을 검증하고 RAW farfield를 export합니다.

재구축 세부 절차와 RAW→MATLAB 연결: [master manual](../../../../../docs/CST2024_CLOSED_NETWORK_REBUILD_MANUAL.md). intrinsic PEC를 사용하며 새 dielectric이나 제조사 CAD를 만들지 않습니다. Reflector의 F/illumination/secondary 값은 기존 engineering surrogate의 가정입니다.
