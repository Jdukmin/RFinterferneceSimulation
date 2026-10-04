# Octave RFI 결과와 재현

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
