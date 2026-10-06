# 22개 CST 2024 생성 순서

각 case의 `build_2024.vba`를 **새 빈 CST 2024 Microwave Studio project**에 실행하고 geometry/port/monitor/mesh를 확인한 뒤 `${case_id}_CST2024.cst`로 저장한다. Solver는 자동 실행하지 않는다. 개발 PC에서 실제 CST 2024 실행은 하지 않았다.

전체 22개 이름과 순서는 [master manual](../../../docs/CST2024_CLOSED_NETWORK_REBUILD_MANUAL.md)의 inventory 표를 따른다. Package 및 최종 filename 경로는 [master CSV](../../../docs/CST2024_REBUILD_22_PROJECTS.csv)에 있다.

1. KAA: STM → L1 → SAR → ISL 순서로 각 feed-only / with-reflector, 총 8개.
2. SBA: original reference → installed NADIR → installed ZENITH → installed attacker ISL/SAR/L1, 총 6개.
3. GPS: original reference → installed GPSA1 → installed GPSA2, 총 3개.
4. ISL: original reference → installed RX → installed attacker SAR/STM/L1, 총 5개.

SBA attacker 하나에는 두 installation/8 ports가 있다. SAR project는 만들지 않는다. 새 2024 파일은 `cst/projects/closed_network_2024_native/{kaa,sba,gps,isl}/`에 저장한다. 원본 source binary는 수정하지 않는다.

폐쇄망 첫 작업은 **CST 2024 실행 → New Microwave Studio project → `kaa/RFC_KAA_FEED_ONLY_STM/build_2024.vba` macro 실행**이다. 전체 native 저장 후에도 모든 solver를 동시에 시작하지 않는다.

Repository package completeness 확인:

```powershell
python cst/closed_network/check_2024_rebuild.py
```

이 checker는 실제 CST 2024 검증을 대신하지 않는다. Native geometry acceptance에는 `native_validation.template.json`을 사용한다. RAW export/registration/MATLAB은 master manual 절차를 따른다.
