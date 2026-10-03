<#
.SYNOPSIS
  Generic CST Studio Suite (Learning Edition) COM/OLE bridge.

.DESCRIPTION
  PowerShell -> COM "CSTStudio.Application" -> CST VBA / AddToHistory.
  No CST Python runtime (cst.interface) is used.

  Every COM call used here was verified either by an earlier successful run
  in this repository (see cst/README_CST_COM.md) or by an installed CST macro
  under "C:\Program Files\CST Studio Suite 2026\Library\Macros". Commands not
  so verified are refused rather than guessed (see templates/README.md).

  Actions (single):  Status, Dialogs, Open, NewProject, History, SetParameter,
                     GetParameter, Rebuild, Solve, Save, SaveAs, ExportSParameters
  Action Job:        runs a JSON step list in one process so the project handle
                     is preserved between steps (recommended for candidates).

  Safety:
  - Projects listed in frozen_projects.txt are never modified unless
    -AllowFrozen is given explicitly.
  - SaveAs never overwrites an existing .cst file.
  - Modal dialogs are listed (title + text) and never closed automatically.
  - Every action is appended as one JSON line to tools/logs/invoke-cst.jsonl.

.EXAMPLE
  powershell -File cst/tools/invoke-cst.ps1 -Action Status
  powershell -File cst/tools/invoke-cst.ps1 -Action Job -JobFile cst/tools/commands/ISL_A.job.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Status', 'Dialogs', 'Open', 'NewProject', 'History', 'SetParameter', 'Solve',
                 'Save', 'SaveAs', 'ExportSParameters', 'Rebuild', 'GetParameter', 'Job')]
    [string]$Action,
    [string]$Project,
    [string]$CommandFile,
    [hashtable]$Vars = @{},
    [string]$Name,
    [string]$Value,
    [string]$OutFile,
    [string]$JobFile,
    [int]$Ports = 0,
    [switch]$AllowFrozen,
    [switch]$AttachOnly
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ToolRoot = $PSScriptRoot
$CstRoot = Split-Path $ToolRoot -Parent
$LogDir = Join-Path $ToolRoot 'logs'
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$LogFile = Join-Path $LogDir 'invoke-cst.jsonl'
$script:Proj = $null

function Write-BridgeLog([string]$step, [string]$status, [hashtable]$detail = @{}) {
    $entry = [ordered]@{ utc = (Get-Date).ToUniversalTime().ToString('o'); step = $step; status = $status }
    foreach ($k in $detail.Keys) { $entry[$k] = $detail[$k] }
    $line = ($entry | ConvertTo-Json -Compress -Depth 6)
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    Write-Host "[$status] $step $(if ($detail.Count) { ($detail | ConvertTo-Json -Compress -Depth 4) })"
}

# ---- Modal dialog inspection (read-only; never sends close/click) -----------
if (-not ('CstWin' -as [type])) {
    Add-Type @'
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
public static class CstWin {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr p, EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  static string Cls(IntPtr h){var s=new StringBuilder(256);GetClassName(h,s,256);return s.ToString();}
  static string Txt(IntPtr h){var s=new StringBuilder(2048);GetWindowText(h,s,2048);return s.ToString();}
  public static List<string> Dialogs(int[] pids){
    var found=new List<string>(); var set=new HashSet<uint>(); foreach(var p in pids) set.Add((uint)p);
    EnumWindows((h,l)=>{ uint pid; GetWindowThreadProcessId(h,out pid);
      if(!set.Contains(pid)||!IsWindowVisible(h)||Cls(h)!="#32770") return true;
      var parts=new List<string>(); parts.Add("TITLE="+Txt(h));
      EnumChildWindows(h,(c,l2)=>{ var t=Txt(c); if(t.Length>0) parts.Add(Cls(c)+"="+t); return true;},IntPtr.Zero);
      found.Add(string.Join(" | ",parts)); return true;},IntPtr.Zero);
    return found; } }
'@
}

function Get-CstDialogs {
    $pids = @(Get-Process | Where-Object { $_.ProcessName -match '^CST DESIGN ENVIRONMENT' } | ForEach-Object { $_.Id })
    if (-not $pids.Count) { return @() }
    return @([CstWin]::Dialogs([int[]]$pids))
}

# ---- Connection / project handling -----------------------------------------
function Connect-Cst {
    try {
        $app = [System.Runtime.InteropServices.Marshal]::GetActiveObject('CSTStudio.Application')
        Write-BridgeLog 'connect' 'OK' @{ mode = 'GetActiveObject' }
        return $app
    } catch {
        if ($AttachOnly) { throw "attach-only: no running CST instance ($($_.Exception.Message))" }
    }
    $app = New-Object -ComObject 'CSTStudio.Application'
    Write-BridgeLog 'connect' 'OK' @{ mode = 'New-Object (Dispatch)' }
    return $app
}

function Get-FrozenList {
    $file = Join-Path $ToolRoot 'frozen_projects.txt'
    if (-not (Test-Path $file)) { return @() }
    return @(Get-Content $file | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { $_.Trim() })
}

function Get-ProjectPath($p) {
    try { return [string]$p.GetProjectPath('Project') } catch { return '' }
}

function Assert-Mutable($p) {
    if ($AllowFrozen) { return }
    $leaf = Split-Path (Get-ProjectPath $p) -Leaf
    if ((Get-FrozenList) -contains $leaf) {
        throw "Refusing to modify frozen project '$leaf' (frozen_projects.txt). Use -AllowFrozen only with explicit owner approval."
    }
}

function Require-Project {
    if ($null -eq $script:Proj) {
        $app = Connect-Cst
        $script:Proj = $app.Active3D()
        if ($null -eq $script:Proj) { throw 'No active 3D project.' }
    }
    return $script:Proj
}

# ---- History command files ---------------------------------------------------
# File format: VBA History code. A line "'@@ <history entry name>" starts a new
# AddToHistory block. Lines beginning with "'" before the first block are
# provenance comments. {{key}} placeholders are replaced from -Vars / job vars.
function Read-HistoryBlocks([string]$path, [hashtable]$vars) {
    if (-not (Test-Path $path)) { throw "Command file not found: $path" }
    $text = Get-Content -Raw -Encoding UTF8 $path
    foreach ($k in $vars.Keys) { $text = $text.Replace('{{' + $k + '}}', [string]$vars[$k]) }
    $left = [regex]::Matches($text, '\{\{[A-Za-z0-9_]+\}\}')
    if ($left.Count) { throw "Unresolved placeholders in ${path}: $(($left | ForEach-Object Value | Select-Object -Unique) -join ', ')" }
    $blocks = @(); $cur = $null
    foreach ($line in ($text -split "`r?`n")) {
        if ($line -match "^'@@\s+(.+)$") {
            if ($cur) { $blocks += , $cur }
            $cur = [ordered]@{ name = $Matches[1].Trim(); code = New-Object System.Text.StringBuilder }
        } elseif ($cur) { [void]$cur.code.AppendLine($line) }
    }
    if ($cur) { $blocks += , $cur }
    if (-not $blocks.Count) { throw "No '@@ blocks in $path" }
    return ,$blocks
}

function Invoke-History([string]$path, [hashtable]$vars) {
    $p = Require-Project; Assert-Mutable $p
    $blocks = Read-HistoryBlocks $path $vars
    $i = 0
    foreach ($b in $blocks) {
        $i++
        $code = $b.code.ToString().TrimEnd()
        try {
            $r = $p.AddToHistory($b.name, $code)
            if ($r -eq $false) { throw 'AddToHistory returned False' }
        } catch {
            Write-BridgeLog 'history' 'FAILED' @{ file = $path; block = $i; name = $b.name; error = $_.Exception.Message; dialogs = @(Get-CstDialogs) }
            throw
        }
    }
    Write-BridgeLog 'history' 'OK' @{ file = $path; blocks = $blocks.Count; sha256 = (Get-FileHash $path -Algorithm SHA256).Hash }
}

# ---- Solver / results --------------------------------------------------------
function Get-LastSolverRun([string]$projectPath) {
    $log = Join-Path $projectPath 'Result\Model.log'
    if (-not (Test-Path $log)) { return @{ log = $log; exists = $false } }
    $text = Get-Content -Raw $log
    $idx = $text.LastIndexOf('Solver started at')
    $run = if ($idx -ge 0) { $text.Substring($idx) } else { $text }
    $cells = [regex]::Matches($run, 'Number of mesh cells:\s+(\d+)') | ForEach-Object { [int]$_.Groups[1].Value }
    $warn = [regex]::Matches($run, '\*\*\* Warning \*\*\*\s+[\d\- :]+\s+([^\r\n]+)') | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -Unique
    $err = [regex]::Matches($run, '\*\*\* Error \*\*\*\s+[\d\- :]+\s+([^\r\n]+)') | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -Unique
    $finished = ([regex]::Matches($run, 'solver finished successfully')).Count
    return @{ log = $log; exists = $true; mesh_cells = @($cells); warnings = @($warn); errors = @($err); successful_excitations = $finished }
}

function Invoke-Solve {
    $p = Require-Project; Assert-Mutable $p
    $t0 = Get-Date
    try { $r = $p.Solver().Start() } catch {
        Write-BridgeLog 'solve' 'FAILED' @{ error = $_.Exception.Message; dialogs = @(Get-CstDialogs) }; throw
    }
    $info = Get-LastSolverRun (Get-ProjectPath $p)
    $info.seconds = [int]((Get-Date) - $t0).TotalSeconds
    $info.start_returned = "$r"
    $ok = ($r -ne $false) -and $info.exists -and ($info.errors.Count -eq 0) -and ($info.successful_excitations -gt 0)
    Write-BridgeLog 'solve' $(if ($ok) { 'OK' } else { 'FAILED' }) $info
    if (-not $ok) { throw "Solver did not complete cleanly; inspect $($info.log)" }
    return $info
}

function Export-SParameters([string]$out, [int]$n) {
    $p = Require-Project
    if ($n -le 0) { $n = [int]$p.Port().StartPortNumberIteration() }
    $tree = $p.ResultTree()
    $rows = @{}; $freq = $null; $cols = @()
    for ($i = 1; $i -le $n; $i++) { for ($j = 1; $j -le $n; $j++) {
        $item = "1D Results\S-Parameters\S$i,$j"
        $ids = @($tree.GetResultIDsFromTreeItem($item))
        if (-not $ids.Count) { throw "No calculated result: $item" }
        $res = $tree.GetResultFromTreeItem($item, $ids[-1])
        $x = @($res.GetArray('x')); $re = @($res.GetArray('yre')); $im = @($res.GetArray('yim'))
        if ($null -eq $freq) { $freq = $x }
        $cols += "S${i}${j}_re", "S${i}${j}_im"; $rows["$i,$j"] = @($re, $im)
    } }
    $dir = Split-Path $out -Parent; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory $dir | Out-Null }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine((@('frequency') + $cols) -join ',')
    for ($k = 0; $k -lt $freq.Count; $k++) {
        $vals = @([string]$freq[$k])
        for ($i = 1; $i -le $n; $i++) { for ($j = 1; $j -le $n; $j++) { $vals += [string]$rows["$i,$j"][0][$k], [string]$rows["$i,$j"][1][$k] } }
        [void]$sb.AppendLine($vals -join ',')
    }
    [IO.File]::WriteAllText($out, $sb.ToString())
    Write-BridgeLog 'export_sparameters' 'OK' @{ out = $out; ports = $n; points = $freq.Count }
}

# ---- Step dispatcher -------------------------------------------------------
function Invoke-Step([string]$act, [hashtable]$a) {
    switch ($act) {
        'Status' {
            $app = Connect-Cst; $p = $app.Active3D()
            $info = @{ active3d = ($null -ne $p); dialogs = @(Get-CstDialogs) }
            if ($p) {
                $info.project = Get-ProjectPath $p
                $info.shapes = [int]$p.Solid().GetNumberOfShapes()
                $info.ports = [int]$p.Port().StartPortNumberIteration()
                $info.frozen = (Get-FrozenList) -contains (Split-Path $info.project -Leaf)
            }
            Write-BridgeLog 'status' 'OK' $info
        }
        'Dialogs' { Write-BridgeLog 'dialogs' 'OK' @{ dialogs = @(Get-CstDialogs) } }
        'Open' {
            $app = Connect-Cst
            $path = (Resolve-Path $a.path).Path
            $script:Proj = $app.OpenFile($path)
            if ($null -eq $script:Proj) { $script:Proj = $app.Active3D() }
            Write-BridgeLog 'open' 'OK' @{ project = $path; frozen = (Get-FrozenList) -contains ((Split-Path $path -Leaf) -replace '\.cst$', '') }
        }
        'NewProject' {
            $app = Connect-Cst
            $script:Proj = $app.NewMWS()
            if ([int]$script:Proj.Solid().GetNumberOfShapes()) { throw 'New project is not empty' }
            Write-BridgeLog 'new_project' 'OK' @{}
        }
        'History' { Invoke-History $a.file $a.vars }
        'SetParameter' {
            $p = Require-Project; Assert-Mutable $p
            # Verified: StoreParameter via COM in generate_sband_ttc.py (actual run).
            $p.StoreParameter($a.name, [string]$a.value) | Out-Null
            Write-BridgeLog 'set_parameter' 'OK' @{ name = $a.name; value = [string]$a.value }
        }
        'Rebuild' {
            # Verified 2026-10-03 on tools/smoke/BRIDGE_SMOKE: StoreParameter 12->20 then
            # Rebuild() changed a parameter-driven brick volume 1200 -> 2000 mm^3.
            $p = Require-Project; Assert-Mutable $p
            $p.Rebuild() | Out-Null
            Write-BridgeLog 'rebuild' 'OK' @{ dialogs = @(Get-CstDialogs) }
        }
        'GetParameter' {
            # RestoreDoubleParameter: installed 3D Linear Helical Spiral^-DS.mcs; readback verified.
            $p = Require-Project
            Write-BridgeLog 'get_parameter' 'OK' @{ name = $a.name; value = [double]$p.RestoreDoubleParameter($a.name) }
        }
        'Solve' { [void](Invoke-Solve) }
        'Save' {
            $p = Require-Project; Assert-Mutable $p
            $path = (Get-ProjectPath $p) + '.cst'
            $p.SaveAs($path, $true) | Out-Null
            Write-BridgeLog 'save' 'OK' @{ project = $path }
        }
        'SaveAs' {
            $p = Require-Project
            $path = [IO.Path]::GetFullPath($a.path)
            if (Test-Path $path) { throw "Refusing overwrite: $path" }
            if ((Get-FrozenList) -contains ([IO.Path]::GetFileNameWithoutExtension($path))) { throw "Target name is frozen: $path" }
            $dir = Split-Path $path -Parent; if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir | Out-Null }
            # Verified: SaveAs(path, True) in cst_com.save (actual runs).
            $p.SaveAs($path, $true) | Out-Null
            Write-BridgeLog 'save_as' 'OK' @{ project = $path }
        }
        'ExportSParameters' { Export-SParameters ([IO.Path]::GetFullPath($a.out)) ([int]$a.ports) }
        default { throw "Unknown step: $act" }
    }
}

function ConvertTo-Hashtable($obj) {
    $h = @{}
    if ($null -eq $obj) { return $h }
    foreach ($prop in $obj.PSObject.Properties) { $h[$prop.Name] = $prop.Value }
    return $h
}

try {
    if ($Action -eq 'Job') {
        $job = Get-Content -Raw -Encoding UTF8 $JobFile | ConvertFrom-Json
        $jobVars = ConvertTo-Hashtable $job.vars
        foreach ($k in $Vars.Keys) { $jobVars[$k] = $Vars[$k] }
        Write-BridgeLog 'job' 'START' @{ job = $JobFile; label = [string]$job.label; steps = @($job.steps).Count }
        $base = Split-Path (Resolve-Path $JobFile).Path -Parent
        foreach ($s in $job.steps) {
            $a = ConvertTo-Hashtable $s
            foreach ($key in @('file', 'path', 'out')) {
                if ($a.ContainsKey($key) -and -not [IO.Path]::IsPathRooted($a[$key])) { $a[$key] = Join-Path $base $a[$key] }
            }
            $merged = @{} + $jobVars
            $vp = $s.PSObject.Properties['vars']
            if ($vp) { $stepVars = ConvertTo-Hashtable $vp.Value; foreach ($k in $stepVars.Keys) { $merged[$k] = $stepVars[$k] } }
            $a.vars = $merged
            Invoke-Step $a.action $a
        }
        Write-BridgeLog 'job' 'DONE' @{ job = $JobFile }
    } else {
        $a = @{ path = $Project; file = $CommandFile; vars = $Vars; name = $Name; value = $Value; out = $OutFile; ports = $Ports }
        if ($Action -eq 'Open' -and -not $Project) { throw '-Project is required for Open' }
        if ($Action -eq 'SaveAs' -and -not $Project) { throw '-Project (destination) is required for SaveAs' }
        if ($Project -and $Action -notin @('Open', 'SaveAs')) { Invoke-Step 'Open' $a }
        Invoke-Step $Action $a
    }
    exit 0
} catch {
    Write-BridgeLog $Action 'ERROR' @{ error = $_.Exception.Message; dialogs = @(Get-CstDialogs) }
    exit 1
}
