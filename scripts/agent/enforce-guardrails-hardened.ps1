param(
  [switch]$ReportOnly = $true,
  [switch]$Fix
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

function Add-Task([string]$msg) {
  $line = "* $(Get-Date -Format o) – $msg"
  Add-Content -Path "TASKS.md" -Value $line
}

$files = Get-ChildItem -Recurse -File -Include *.html,*.htm,*.js,*.jsx,*.ts,*.tsx | `
         Where-Object { $_.FullName -notmatch "\\node_modules\\" }

$patterns = @(
  @{ id="inline-style-html"; desc="Inline style attributes"; rx='(?is)<[^>]+\sstyle\s*=\s*"[^"]*"' },
  @{ id="inline-style-jsx";  desc="JSX style prop";        rx='(?s)\bstyle\s*=\s*{{.*?}}' },
  @{ id="dangerouslySetInnerHTML"; desc="dangerouslySetInnerHTML usage"; rx='dangerouslySetInnerHTML\s*=' },
  @{ id="img-missing-alt"; desc="IMG missing alt"; rx='(?is)<img(?![^>]*\balt\s*=)[^>]*>' },
  @{ id="btn-no-name"; desc="BUTTON w/out accessible name/label"; rx='(?is)<button(?![^>]*(aria-label|aria-labelledby|title)=)[^>]*>\s*(?:</button>|<\s*/button\s*>)' },
  @{ id="input-unlabeled"; desc="INPUT missing label/aria"; rx='(?is)<input(?![^>]*(id=|name=|aria-label=|aria-labelledby=|title=|placeholder=))[^>]*>' }
)

$violations = @()

foreach ($f in $files) {
  $text = Get-Content $f.FullName -Raw
  foreach ($p in $patterns) {
    $matches = [regex]::Matches($text, $p.rx)
    foreach ($m in $matches) {
      # compute line number cheaply
      $lineNum = ($text.Substring(0, $m.Index) -split "`n").Count
      $violations += [pscustomobject]@{
        file = $f.FullName
        id   = $p.id
        desc = $p.desc
        line = $lineNum
        excerpt = $text.Substring($m.Index, [Math]::Min(120, $m.Length)).Replace("`r"," ").Replace("`n"," ")
      }
    }
  }

  if ($Fix) {
    $fixed = $false
    # Safe autofixes only
    # 1) img missing alt -> add alt=""
    $text2 = $text -replace '(?is)<img(?![^>]*\balt\s*=)([^>]*)>', '<img alt=""$1>'
    if ($text2 -ne $text) { $fixed = $true; $text = $text2; Add-Task "Added alt=`"`" to <img> in $($f.Name)" }

    # 2) empty/unnamed buttons -> add aria-label="TODO"
    $text2 = $text -replace '(?is)<button((?:(?!>).)*)>(\s*)</button>', '<button aria-label="TODO"$1>$2</button>'
    if ($text2 -ne $text) { $fixed = $true; $text = $text2; Add-Task "Added aria-label to empty <button> in $($f.Name)" }

    # 3) inputs without label/aria -> add aria-label="TODO"
    $text2 = $text -replace '(?is)<input(?![^>]*(aria-label|aria-labelledby|title|placeholder|name|id)=)([^>]*)>', '<input aria-label="TODO"$2>'
    if ($text2 -ne $text) { $fixed = $true; $text = $text2; Add-Task "Added aria-label to <input> in $($f.Name)" }

    if ($fixed -and -not $ReportOnly) {
      Set-Content -Path $f.FullName -Value $text -Encoding UTF8
    }
  }
}

# Write JSON report
$report = [pscustomobject]@{
  generatedAt = (Get-Date).ToString("o")
  counts = ($violations | Group-Object id | ForEach-Object { @{($_.Name) = $_.Count} } | `
           ForEach-Object { $_ }) -join "; "
  items = $violations
}
$reportJson = $report | ConvertTo-Json -Depth 6
Set-Content -Path ".agent/guardrails_report.json" -Value $reportJson -Encoding UTF8

Write-Host "Guardrails report written to .agent/guardrails_report.json"
Write-Host "Violations found:" ($violations.Count)

if ($violations.Count -gt 0) {
  Add-Task "Guardrail scan found $($violations.Count) violations. See .agent/guardrails_report.json"
}
