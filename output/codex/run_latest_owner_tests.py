"""Run unchanged full Octave suite using native Git cp to avoid xcopy prompts."""
from pathlib import Path
import json,os,re,subprocess
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent.parent
s=(OUT/'README.md').read_text(encoding='utf-8')
runtime=next(x for x in re.findall(r'`([^`]+)`',s) if x.endswith('octave-cli.exe'))
cp=Path('C:/Program Files/Git/usr/bin/cp.exe')
assert Path(runtime).is_file() and cp.is_file()
env=os.environ.copy();env['PATH']=str(cp.parent)+os.pathsep+env.get('PATH','')
command=[runtime,'--quiet','--eval',"addpath('tests'); ok=run_all_tests(); if ~ok, exit(1); end;"]
with (OUT/'latest_owner_full_tests.log').open('w',encoding='utf-8') as log:
    log.write('Unchanged full suite; Git cp.exe added to PATH to avoid Windows xcopy destination-type prompt. No shared files patched.\n');log.flush()
    result=subprocess.run(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
text=(OUT/'latest_owner_full_tests.log').read_text(encoding='utf-8')
m=re.search(r'Passed:\s*(\d+)\s+Failed:\s*(\d+)\s+Total:\s*(\d+)',text)
evidence=dict(exit_code=result.returncode,passed=int(m[1]) if m else None,failed=int(m[2]) if m else None,total=int(m[3]) if m else None,runtime_version='GNU Octave 9.2.0',
    runner='tests/run_all_tests.m unchanged',copy_compatibility='Git cp.exe on process PATH; standard Octave copyfile selects cp instead of Windows xcopy',shared_files_modified=False,additional_cst_run=False,
    initial_attempt='1480 passed; 3 file-copy runtime errors; latest_owner_full_tests_initial.log preserves evidence')
(OUT/'latest_owner_full_test_results.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
print(json.dumps(evidence,indent=2));raise SystemExit(result.returncode)
