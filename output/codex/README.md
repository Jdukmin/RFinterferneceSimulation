# Octave RFI 결과와 재현

Task 1에서 S-TC TX → GPS L2/L5 primary는 `PORT_MISMATCH_RESCALED_LBAND` engineering route로 전환했다. [Owner 정책](emission_inputs/owner_port_mismatch_policy.json)의 −10 dB만 적용하며, ITU −49.0206 dBm/Hz에서 effective source는 −59.0206 dBm/Hz다. 기존 accepted-power gain envelope 9.03 dBi와 정상 GPS receive RealizedGain을 결합한다. L1에는 추가 mismatch 감쇠를 넣지 않는다.

[Task 1 요약](task1_lband_summary.csv), [설치/case별 24개 경로](task1_lband_pair_results.csv), [120개 filter scenario](task1_lband_filter_scenarios.csv), [원본 CST normalization 근거](task1_cst_normalization_evidence.csv), [검증](task1_validation.json)을 참조한다. `victim_band_scenarios.csv`의 이전 UNKNOWN과 `conditional_bound_required_suppression.csv`의 mismatch 미적용 결과는 과거 분석/sensitivity로 유지하며, 최신 primary 결과는 `all_pair_required_suppression.csv`다.

최신 설계 결과는 [결과보고서.md](결과보고서.md)와 [main_design_results.csv](main_design_results.csv)다. 실제 역할은 **S-TC TX**(`S_TM_TX`), **S-TM RX**(`S_TC_RX`)로 표시하고, legacy ID는 조회 키로 유지한다. 이전 `source_set=PRIMARY`는 ECSS/ITU 혼합 분석이며, 최신 설계 보완은 모든 TX에 ITU RR Appendix 3 / SM.329 source를 적용한 별도 결과다.

기존 독립 coupling 결과에서 추가 억제 요구만 재현하려면 `python output/codex/complete_suppression_design.py`를 실행한다. CST/Octave 재실행 없이 168개 primary pair, 76개 조건부 bound, 1,220개 filter scenario를 만든다. [all_pair_required_suppression.csv](all_pair_required_suppression.csv)에 primary의 미판정 사유를 남기고 [conditional_bound_required_suppression.csv](conditional_bound_required_suppression.csv)는 조건부 가정을 별도로 보존한다. 전체 분석의 마지막 `summarize_emission_analysis.py`도 이 보완 단계를 자동으로 호출한다.

## 현재 독립 규격 분석

현재 [결과보고서.md](결과보고서.md)는 freeze `8469e8903da83b6ebed014aae311f90855c31715`에서 독립 수행한 규격 기반 victim-band PSD 보고서다. [emission_inputs/tx_emission_masks.csv](emission_inputs/tx_emission_masks.csv)가 worker 독립 source 입력이며 공유 `data/`를 변경하지 않았다. 보고서 작성은 [공통 guide](../../docs/REPORTING_GUIDE.md)를 따른다.

재현 순서: freeze worktree에서 `python output/codex/prepare_emission_analysis.py`, Octave에서 `addpath('tests'); addpath('output/codex'); run_emission_analysis;`, 이후 `python output/codex/summarize_emission_analysis.py`. 준비 스크립트는 HEAD가 freeze와 정확히 같은지 검사한다. 완료 commit에서 재현할 때에는 freeze에서 별도 worktree를 만들고 이 worker의 driver·보고서 정리 script·source 준비 파일·규격 evidence CSV만 복사한다. 규격 PDF는 `standards/` 임시 작업 폴더에서 조사했으며 최종 근거는 [standard_source_evidence.csv](standard_source_evidence.csv)의 공식 URL/hash다. 정리 스크립트는 PDF가 없으면 기존 evidence CSV를 유지한다.

기존 `run_rfi_octave.m`·`build_report.py` 및 아래 절차는 **과거 기본파/blocker 분석**이다. 이번 victim-band 분석 재현이나 최신 결과보고서 생성에 사용하지 않는다. 기존 CSV·로그는 secondary 근거로 보존했다.

보고서 생성/수정 시 [공통 reporting guide](../../docs/REPORTING_GUIDE.md)를 반드시 따른다. 현재 결과보고서는 기존 산출물을 유지한 가독성 개정본이다. 기존 `build_report.py` 템플릿은 개정 전 구조이므로 재사용 전에 guide에 맞게 수정해야 한다. 이 스크립트는 검증·snapshot·manifest도 갱신하므로 문서 편집만을 위해 실행하지 않는다.

이 폴더가 요청된 분석 결과의 루트다. `결과보고서.md`와 `분석근거.md`를 먼저 읽는다. CSV는 UTF-8이며 NaN은 미확보, −Inf dBm은 정확한 0 W의 이상 모델 결과다.

## 실행 환경

GNU Octave 9.2.0, Windows x86_64-w64-mingw32.

이번에 사용한 실행 파일:

`C:\Users\ykyk1\AppData\Local\Temp\claude\C--Users-ykyk1-source-repos-RFInterferenceSimulation\7c30d0c5-d552-4d3f-9867-67d16bd1fce6\scratchpad\octave\octave-9.2.0-w64\mingw64\bin\octave-cli.exe`

같은 버전의 다른 Octave 경로에서도 실행할 수 있다. repo 루트를 현재 디렉터리로 두고 다음을 Octave에서 실행한다.

```matlab
addpath('output/codex');
run_rfi_octave;
run_rfi_octave('sar');
```

관련 검사:

```matlab
addpath('src'); addpath('tests');
h = testutil.Harness();
test_coordinate(h);
test_spectral_coupling(h);
test_noise(h);
test_rf_coexistence_integration(h);
test_pattern_freeze(h);
assert(h.report());
```

보고서·원본 컷 교차검증·입력 hash 목록·그림 생성:

```text
python output/codex/build_report.py
```

Python은 RF 분석 실행을 대체하지 않으며 Octave의 CSV를 검사·포장한다. 재실행 전에 `input_hash_manifest.csv`를 현재 원본과 대조한다. `input_snapshot/`은 사용한 spacecraft CSV 설정과 provenance/freeze 목록의 복사본이다. runtime 경로는 사용한 로컬 실행 파일의 기록이며, repo에 Octave 실행 파일을 포함하지 않는다.

## 해석 범위

18개 시나리오 / 252 pair: 132 계산, 120 입력 부족. 자기 설치 경로는 별도 제외 목록에 기록한다. SAR 응답 민감도 90행은 SAR 절대 간섭 판정이 아니다. 설치 패턴은 사용하지 않고 자유공간을 우선했다. CST 추가 실행과 안테나 형상 변경은 없다.

모든 기본파 대역은 이상적인 수신 bandpass와 비중첩이다. 전체 RFI 적합, 실제 out-of-band blocking, 스퍼·고조파·상호변조, 실제 Ka steering 최악조건은 판정하지 않았다. 근거리 가정/구조 차폐/미확보 패턴/Ka mismatch 한계를 결과보고서에서 확인한다.
