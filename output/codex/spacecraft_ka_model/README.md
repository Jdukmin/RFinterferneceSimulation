# 위성체 + Ka 반사판 geometry-only 이관 자료

최종 CST 프로젝트: `cst/projects/SPACECRAFT_KA_MODEL_ONLY_V2.cst`.
SSOT 위성체 8개 PEC 면과 KAA1/KAA2 등가 반사판 2개를 실제 CST에서 생성하고 shape count 10을 확인했다. mesh/solver는 실행하지 않았다. 초기 V1 프로젝트는 이전 작업본이며 V2를 사용한다.

- `closed_network_model_bundle.zip`: V2 프로젝트와 관련 작업 폴더, SSOT CSV, geometry VBA/STL/manifest, 지침서, 생성 스크립트. ZIP 구조는 repo 상대 경로다. 모델링만 포함하며 기타 안테나 프로젝트·RF 분석 코드 전체는 별도 반입해야 한다.
- `model_manifest.json`: 각 body face와 반사판 위치/회전/치수·가정·기타 안테나 reference·원본 hash.
- `geometry_history.vba`: mm/GHz 새 CST 프로젝트에 적용할 재현 가능한 형상 history. AnalyticalFace 반사판이며 EM mesh가 아니다.
- `spacecraft_ka_reference_mm.stl`: mm 단위의 휴대용 표면 CAD. STL에는 단위/재료/포트 정보가 없으므로 import 시 지정한다.
- `geometry_preview.png`: 입력 geometry의 파생 미리보기이며 CST 화면 캡처나 해석 결과가 아니다.
- `geometry_validation.json`, `transfer_hashes.csv`: 법선·회전·치수·CST shape count 및 이관 파일 무결성.
- `validate_package_model.py`: geometry 검사·미리보기·이관 package 재생성.

정식 해석 지침: `docs/guides/closed_network_cst_simulation.md`.

Ka는 직경 220 mm의 equivalent paraboloid이다. 실제 Cassegrain의 feed/secondary/strut/hinge CAD는 포함하지 않는다. S/L/ISL/SAR는 manifest의 기존 배치 reference이며 방사체·포트가 이 조립 모델에 자동으로 병합되지 않는다. 이 상태를 installed pattern 또는 full-wave coupling 결과로 사용하지 않는다.
