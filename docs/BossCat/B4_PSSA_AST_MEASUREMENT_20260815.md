<!-- markdownlint-disable MD013 MD034 MD060 -->
# B4 Measurement — PSScriptAnalyzer / AST sweep

**Date:** 2026-08-15  
**Authority:** BossCat OEM · Second Pass Wave 2 B4  
**Actor:** Cursor{Implementer}  
**Grounded against:** `origin/main` @ `88f59e929` (post B3 BRAV declare-done)  
**Status:** MEASUREMENT ONLY — no script fixes in this commit

## Scope

| Tree | Role |
|------|------|
| `BRAV/SCPT/**/*.ps1` | Primary (B3 conversions just settled here) |
| `scripts/**/*.ps1` | Secondary operational scripts |

Done when (plan): **0 parse errors** live in scope; **PSSA count recorded**.

## Canonical commands

Run from repo root. **Do not pipe** if you need the script’s exit code (OEM instrument lesson).

### AST parse (authoritative for “0 parse errors”)

```powershell
$roots = @('BRAV/SCPT','scripts')
$files = foreach ($r in $roots) {
  Get-ChildItem -Path $r -Recurse -Filter '*.ps1' -File -ErrorAction SilentlyContinue
}
$byFile = @{}
foreach ($f in $files) {
  $errs = $null
  $null = [System.Management.Automation.Language.Parser]::ParseFile(
    $f.FullName, [ref]$null, [ref]$errs)
  if ($errs -and $errs.Count -gt 0) {
    $rel = ($f.FullName.Substring((Get-Location).Path.Length + 1)) -replace '\\','/'
    $byFile[$rel] = $errs.Count
  }
}
"ps1_files=$($files.Count)"
"files_with_parse_errors=$($byFile.Count)"
"parse_error_events=$(($byFile.Values | Measure-Object -Sum).Sum)"
$byFile.GetEnumerator() | Sort-Object Name | ForEach-Object {
  '{0,4} {1}' -f $_.Value, $_.Name
}
```

### PSScriptAnalyzer (debt inventory)

```powershell
Import-Module PSScriptAnalyzer
$roots = @('BRAV/SCPT','scripts')
$issues = foreach ($r in $roots) {
  Invoke-ScriptAnalyzer -Path $r -Recurse -Severity @('Error','Warning','Information')
}
"PSSA_VERSION=$((Get-Module PSScriptAnalyzer).Version)"
"pssa_total=$($issues.Count)"
$issues | Group-Object Severity | ForEach-Object { "$($_.Name)=$($_.Count)" }
$issues | Group-Object RuleName | Sort-Object Count -Descending |
  Select-Object -First 15 |
  ForEach-Object { '{0,5} {1}' -f $_.Count, $_.Name }
```

## Results @ `88f59e929`

| Probe | Result |
|-------|-------:|
| `.ps1` files in scope | **722** |
| Files with ≥1 AST parse error | **23** |
| AST parse error events | **161** |
| `scripts/**` parse-error files | **0** (all 23 under `BRAV/SCPT`) |
| PSScriptAnalyzer | **1.25.0** |
| PSSA total (Error+Warning+Information) | **25,682** |
| PSSA Information | 7,749 |
| PSSA Warning | 17,922 |
| PSSA Error | 11 |

Top PSSA rules (full severity scan):

| Count | Rule |
|------:|------|
| 16106 | PSAvoidUsingWriteHost |
| 7587 | PSAvoidTrailingWhitespace |
| 555 | PSUseBOMForUnicodeEncodedFile |
| 270 | PSUseDeclaredVarsMoreThanAssignments |
| 247 | PSReviewUnusedParameter |

## Files with AST parse errors (23)

```text
   4 BRAV/SCPT/agent/utils/atomic-writes.ps1
   1 BRAV/SCPT/agent/utils/schema-version.ps1
  36 BRAV/SCPT/agent/utils/secrets-hygiene.ps1
   1 BRAV/SCPT/agent/watchdog-enhanced.ps1
   1 BRAV/SCPT/automated-stack-manager.ps1
   4 BRAV/SCPT/deep-clean.ps1
   4 BRAV/SCPT/ecrr-export-checklist.ps1
   4 BRAV/SCPT/ecrr/collect-evidence.ps1
   1 BRAV/SCPT/generate-weekly-report.ps1
   2 BRAV/SCPT/manage-compliance-task.ps1
   2 BRAV/SCPT/monitor-stack-health.ps1
   6 BRAV/SCPT/optimized-monitoring-core.ps1
   1 BRAV/SCPT/pre-commit-powershell.ps1
   3 BRAV/SCPT/production-monitoring.ps1
   8 BRAV/SCPT/setup-comprehensive-alerts.ps1
  29 BRAV/SCPT/setup-dashboards.ps1
   1 BRAV/SCPT/setup-github-repo-security.ps1
  40 BRAV/SCPT/setup-saved-views.ps1
   5 BRAV/SCPT/setup-signoz-authentication-for-automation.ps1
   1 BRAV/SCPT/validate-configuration.ps1
   3 BRAV/SCPT/verify-dashboard-import.ps1
   2 BRAV/SCPT/verify-hurst-drift-alert.ps1
   2 BRAV/SCPT/verify-observability-stack.ps1
```

## Why AST first (OEM #530 lesson)

B3 closeout introduced a **parse regression** invisible to drift/`tsc`/literal grep:
`$otelPorts` used inside a PowerShell **class method** without `$script:` scope.
AST `ParseFile` is the gate that would have caught it. Fix batches must prove
**pass (0)** and **fail** (deliberate bad token or class-scope probe) before merge.

## Suggested fix order (not done here)

1. **Parse-zero batches** — repair the 23 files (≤10/batch); class-scope `$script:` is a recurring pattern (`automated-stack-manager.ps1` already shows “Variable is not assigned in the method”).
2. **PSSA Error severity** — chase the 11 Error findings once parse is clean (re-measure; parse failures can confuse analyzers).
3. **PSSA Warning hygiene** — optional later; WriteHost/trailing-whitespace dominate and are mostly noise for this lane.

## Next

Measurement PR only. Fix batches start after OEM affirms scope (BRAV/SCPT + scripts) and AST-first ordering.
