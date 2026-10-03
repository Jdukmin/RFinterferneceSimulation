# CST COM bridge (`invoke-cst.ps1`)

Automation chain: Claude Code / user → PowerShell → Windows COM/OLE
`CSTStudio.Application` → CST VBA via `AddToHistory()` → CST Studio Suite 2026.4
Learning Edition. CST Python (`cst.interface`) is not used. Result post-processing
that needs numerics (accepted-power CP gain, active reflection) stays in the
existing Python modules, which use the same COM path through `win32com`.

Location note: the requested `tools/cst/` layout lives under `cst/tools/` because
repository changes are restricted to `cst/`.

```
cst/tools/
  invoke-cst.ps1        generic bridge
  frozen_projects.txt   accepted/evidence projects the bridge refuses to modify
  templates/*.vba       verified History snippets with {{placeholders}}
  commands/<LABEL>/     rendered candidate history.vba + job.json + candidate.json
  logs/invoke-cst.jsonl one JSON line per step (status, errors, dialogs, mesh cells)
  smoke/BRIDGE_SMOKE.cst bridge smoke-test project
```

## Usage

```powershell
$B = "$PWD\cst\tools\invoke-cst.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $B -Action Status
powershell -NoProfile -ExecutionPolicy Bypass -File $B -Action Job -JobFile "$PWD\cst\tools\commands\ISL_B_CUPPATCH\job.json"
powershell -NoProfile -ExecutionPolicy Bypass -File $B -Action History -Project <x.cst> -CommandFile <file.vba> -Vars @{fmin='8';fmax='8.4'}
```

Actions: `Status`, `Dialogs`, `Open`, `NewProject`, `History`, `SetParameter`,
`GetParameter`, `Rebuild`, `Solve`, `Save`, `SaveAs`, `ExportSParameters`, `Job`.
A job (JSON step list) runs in one process so the project handle is kept.
Relative paths in a job are resolved against the job file. Step `vars` override job `vars`.

## History file format

```
' provenance comments
'@@ <history entry name>
<VBA History code>
'@@ <next entry>
...
```

Unresolved `{{key}}` placeholders abort before anything is sent to CST.

## Verification record (2026-10-03, CST 2026.4 Learning Edition)

| Capability | Evidence |
|---|---|
| GetActiveObject attach, `Active3D`, `GetProjectPath`, Solid/Port read-back | read-only smoke on the open L-band project; nothing modified |
| Frozen-project refusal | `History` on `LBAND_GNSS_FINAL_COMPROMISE` refused before any COM write |
| `NewMWS`, `AddToHistory`, units/solver/boundary/brick/`StoreParameterWithDescription` | `commands/bridge_smoke.job.json` → `smoke/BRIDGE_SMOKE.cst` |
| `StoreParameter` + `Rebuild()` | parameter-driven brick 1200 → 2000 mm³ after 12 → 20 change; `RestoreDoubleParameter` readback 20 |
| `Solver.Start`, Model.log parsing, `ExportSParameters` | ISL candidate jobs (see `logs/invoke-cst.jsonl`) |

History syntax sources are listed at the top of each template (prior actual runs or
installed `Library/Macros` files). If a needed feature has no verified syntax, do the
operation once in the CST GUI, copy the generated History entry into `templates/`
with a provenance line, and only then automate it. Do not guess commands.

## Dialogs

`Dialogs` (and every failure) lists visible `#32770` dialog windows owned by the CST
process with their text. The bridge never clicks or closes them; read the text and
decide manually. Learning Edition stores History scrambled, so the rendered
`history.vba` files are the readable record of what was sent.
