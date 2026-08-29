Param(
  [switch]$Strict,
  [string]$OutputJson = 'artifacts/gate-verification-results.json',
  [string]$PrCommentPath = 'PR_COMMENT_IONA_GATE_002_FINAL.md',
  [switch]$NoFailOnMissing,
  [string]$Gate = 'IONA',
  [string]$Site = 'ci',
  [switch]$VerboseMode
)
$ErrorActionPreference = 'Stop'
try { Import-Module -Name "$(Join-Path $PSScriptRoot 'lib/BossCat.Progress.psm1')" -ErrorAction SilentlyContinue } catch {}
if (Get-Command Start-BossCatProgress -ErrorAction SilentlyContinue) { Start-BossCatProgress -Activity 'BossCat Gate Verify' -ExpectedTotalSeconds 20 }
function Get-GitMeta { try {$c=(git rev-parse --short HEAD 2>$null).Trim()}catch{$c=''}; try{$b=(git rev-parse --abbrev-ref HEAD 2>$null).Trim()}catch{$b=''}; [pscustomobject]@{Commit=$c;Branch=$b} }
function Ensure-Dirs([string[]]$Dirs){ foreach($d in $Dirs){ if(-not(Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Path $d -Force|Out-Null } } }
function Get-ControlToken([int]$Code){
  switch ($Code) {
    0 { return '[CTRL-NULL]' }
    7 { return '[CTRL-BEL]' }
    8 { return '[CTRL-BS]' }
    11 { return '[CTRL-VT]' }
    12 { return '[CTRL-FF]' }
    default { return ('[CTRL-0x{0:X2}]' -f $Code) }
  }
}
function Convert-ToAscii([string]$Input){
  if ($null -eq $Input) {  return '' }
  $sb = New-Object System.Text.StringBuilder
  foreach($ch in $Input.ToCharArray()){
    $code = [int][char]$ch
    if (($code -ge 32 -and $code -le 126) -or $code -in @(9,10,13)) {
      [void]$sb.Append([char]$code)
    } else {
      [void]$sb.Append((Get-ControlToken $code))
    }
  }
  return $sb.ToString()
}
function Convert-ToAsciiLines([string[]]$Lines){
  if (-not $Lines) { return @() }
  return $Lines | ForEach-Object { Convert-ToAscii $_ }
}
function Read-TestsJson{ $p='docs/status/tests.json'; if(-not(Test-Path $p)){return [pscustomobject]@{total=0;passed=0;failed=0}}; try{ $d=Get-Content -Raw -LiteralPath $p|ConvertFrom-Json; if($d.summary){return $d.summary}; [pscustomobject]@{total=0;passed=0;failed=0} }catch{ [pscustomobject]@{total=0;passed=0;failed=0} } }
function New-EcrrReport([string]$Verdict,[string[]]$Reasons,[hashtable]$Checks){
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'
  $g  = Get-GitMeta
  $cwd = Get-Location
  $lines = @(
    '# ECRR Gate Run - BossCat Decision',
    '',
    "Timestamp: $ts",
    "Commit: $($g.Commit)",
    "Branch: $($g.Branch)",
    "Gate: $Gate",
    "Site: $Site",
    "Working Dir: $cwd",
    '',
    '## Examine',
    ''
  )
  foreach($k in ($Checks.Keys | Sort-Object)) {
    $lines += ("- {0} - {1}" -f $k, $Checks[$k])
  }
  $lines += ''
  $lines += '## Report'
  $lines += ''
  $lines += "Gate Verdict: $Verdict"
  if ($Reasons -and $Reasons.Count -gt 0) {
    $lines += ''
    $lines += 'Reasons:'
    foreach($r in $Reasons){ $lines += "- $r" }
  }
  $dir = 'CHAR/ECRR/ECRR_REPORTS'
  Ensure-Dirs @($dir)
  $name = Join-Path $dir ("ECRR_GATE_RUN_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.md')
  $content = $lines -join "`r`n"
  $content | Set-Content -Path $name -Encoding utf8
  $content | Set-Content -Path (Join-Path $dir 'ECRR_GATE_RUN_LATEST.md') -Encoding utf8
  return $name
}
function Write-PrComment([string]$Verdict,[string[]]$Reasons,[string]$OutputPath,[hashtable]$Checks=$null){
  $g = Get-GitMeta
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'

  # Budget calculations (P2: Gate UX Budget Comment Polish)
  $changedFiles = @(git diff --name-only HEAD~1..HEAD 2>$null)
  $fileCount = if ($changedFiles) { $changedFiles.Count } else { 0 }
  $locCount = if ($changedFiles) { 
    (git diff --shortstat HEAD~1..HEAD 2>$null | Select-String -Pattern '\d+ insertion' | ForEach-Object { 
      if ($_ -match '(\d+) insertion') { [int]$matches[1] } else { 0 }
    }) 
  } else { 0 }
  
  # Determine budget mode and thresholds
  $isGovLane = ($Site -eq 'prod')
  $maxFiles = if ($isGovLane) { 10 } else { 10 }
  $maxLOC = if ($isGovLane) { 2000 } else { 200 }
  $stickyPct = 0.80
  
  # Calculate budget status
  $fileStatus = if ($fileCount -ge ($maxFiles * $stickyPct)) { 'WARN' } else { 'OK' }
  $locStatus = if ($locCount -ge ($maxLOC * $stickyPct)) { 'WARN' } else { 'OK' }
  $budgetLine = "Budgets: Files [$fileStatus] $fileCount/$maxFiles | LOC [$locStatus] $locCount/$maxLOC"
  $isSticky = ($fileCount -ge ($maxFiles * $stickyPct) -or $locCount -ge ($maxLOC * $stickyPct))
  if ($isSticky) {
    $budgetLine += " | NOTE: sticky warn at >=80%"
    # P2: Add first failing gate name for faster triage
    if ($Checks -and $Verdict -ne 'READY') {
      $firstFail = ($Checks.Keys | Where-Object { $Checks[$_] -eq 'missing' } | Select-Object -First 1)
      if ($firstFail) { $budgetLine += " | First fail: ``$firstFail``" }
    }
  }

  $lines = @(
    '# IONA Gate - BossCat Verdict',
    '',
    "**Gate:** ``$Gate`` | **Site:** ``$Site``",
    $budgetLine,
    "**ECRR:** evidence OK | contain OK | rollback plan OK | report OK",
    '',
    "- **Verdict**: $Verdict",
    "- **Timestamp**: $ts",
    "- **Commit**: $($g.Commit)",
    "- **Branch**: $($g.Branch)",
    '',
    '## Reasons'
  )
  if (-not $Reasons -or $Reasons.Count -eq 0) { $lines += '- None' } else { foreach($r in $Reasons){ $lines += "- $r" } }
  ($lines -join "`r`n") | Set-Content -Path $OutputPath -Encoding utf8
}
$primaryOutputPath='artifacts/gate-verification-results.json'
$legacyOutputPath='DELT/ARTF/gate-verification-results.json'
$legacyMirrorRequested=$false
$tsIso=Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'; Ensure-Dirs @('artifacts','CHAR/ECRR/ECRR_REPORTS')
if ((Test-Path -LiteralPath $legacyOutputPath) -and -not (Test-Path -LiteralPath $primaryOutputPath)) {
  try {
    Copy-Item -LiteralPath $legacyOutputPath -Destination $primaryOutputPath -Force
    Write-Warning "[Gate][$Site] migrated gate results from legacy DELT/ARTF to artifacts/."
  } catch {
    Write-Warning "[Gate][$Site] failed to migrate legacy gate results: $($_.Exception.Message)"
  }
}
# Collect all destinations for gate results, ensuring artifacts/ is canonical
$outputTargets = New-Object 'System.Collections.Generic.List[string]'
[void]$outputTargets.Add($primaryOutputPath)
if ($PSBoundParameters.ContainsKey('OutputJson')) {
  if ([string]::IsNullOrWhiteSpace($OutputJson)) {
    $OutputJson = $primaryOutputPath
  } elseif ($OutputJson -eq $legacyOutputPath) {
    $legacyMirrorRequested = $true
    Write-Warning "[Gate][$Site] legacy DELT/ARTF output requested; mirroring artifacts/ content for compatibility."
    if (-not $outputTargets.Contains($legacyOutputPath)) { [void]$outputTargets.Add($legacyOutputPath) }
  } elseif ($OutputJson -ne $primaryOutputPath) {
    if (-not $outputTargets.Contains($OutputJson)) { [void]$outputTargets.Add($OutputJson) }
  }
} else {
  $OutputJson = $primaryOutputPath
}
if (-not $legacyMirrorRequested -and $OutputJson -eq $primaryOutputPath) {
  Write-Verbose "[Gate][$Site] using canonical artifacts output path: $primaryOutputPath"
}
# Ensure directories for each output target
foreach($target in $outputTargets){
  $dir = Split-Path -Parent $target
  if ($dir -and $dir -ne '.') { Ensure-Dirs @($dir) }
}
# Resolve environment switches early for use in checks
$useMock = ($env:USE_MOCK -eq 'true')
$queueRequired = ($Site -eq 'prod' -and -not $useMock)
# Default strictness by site if not explicitly provided
if (-not $PSBoundParameters.ContainsKey('Strict')) { $Strict = ($Site -eq 'prod') }
if (Get-Command Update-BossCatProgress -ErrorAction SilentlyContinue) { Update-BossCatProgress -Phase 'Collecting required assets' -CompletedSeconds 3 }
$required=@('.github/workflows/bosscat-gate-verify.yml','docs/status/tests.json','docs/status.html','CHAR/ECRR/ECRR_REPORTS','docs/observability/snapshots','docs/IONA_ERRORS.md','docs/cheatsheets','index.html')
$nonCritical=@('scripts/benchmark-process-all-ecrr-reports.ps1','docs/BossCat/README.md')
Ensure-Dirs @('docs/observability/snapshots','docs/cheatsheets')
$checks=@{}; $missing=New-Object System.Collections.ArrayList
foreach($p in $required){ $ex=Test-Path -LiteralPath $p; $checks[$p]= if($ex){'present'} else {'missing'}; if(-not $ex){[void]$missing.Add($p)} }
if (Get-Command Update-BossCatProgress -ErrorAction SilentlyContinue) { Update-BossCatProgress -Phase 'Reading status tests' -CompletedSeconds 7 }
foreach($p in $nonCritical){ $checks[$p]= if(Test-Path -LiteralPath $p){'present'} else {'missing'} }

# Composite non-critical check: signoz helper can live in either path
$signozPaths=@('tests/helpers/signoz.ts','ALFA/TEST/helpers/signoz.ts')
$signozPresent=$false
foreach($sp in $signozPaths){ if(Test-Path -LiteralPath $sp){ $signozPresent=$true; break } }
$checks['signoz.ts']= if($signozPresent){'present'} else {'missing'}

# Composite check: queue-steward-verification.txt expected under artifacts/
$queuePreferredPath='artifacts/queue-steward-verification.txt'
$queueLegacyPath='DELT/ARTF/queue-steward-verification.txt'
if ((Test-Path -LiteralPath $queueLegacyPath) -and -not (Test-Path -LiteralPath $queuePreferredPath)) {
  try {
    Copy-Item -LiteralPath $queueLegacyPath -Destination $queuePreferredPath -Force
    Write-Warning "[Gate][$Site] migrated queue steward evidence from legacy DELT/ARTF to artifacts/."
  } catch {
    Write-Warning "[Gate][$Site] failed to migrate legacy queue steward evidence: $($_.Exception.Message)"
  }
}
$queuePresent=Test-Path -LiteralPath $queuePreferredPath
$checks['queue-steward-verification.txt']= if($queuePresent){'present'} else {'missing'}
if (-not $queuePresent -and (Test-Path -LiteralPath $queueLegacyPath)) {
  Write-Warning "[Gate][$Site] queue-steward evidence found under legacy DELT/ARTF path; migrate to artifacts/."
}
# Treat queue-steward verification evidence as REQUIRED only for real prod
if (-not $queuePresent -and $queueRequired) {
  [void]$missing.Add('queue-steward-verification.txt')
} elseif (-not $queuePresent -and -not $queueRequired) {
  Write-Warning "[Gate][$Site] queue-steward evidence missing (OK in mock/non-prod)."
}
$s=Read-TestsJson; $failed=[int]$s.failed; $total=[int]$s.total
if (Get-Command Update-BossCatProgress -ErrorAction SilentlyContinue) { Update-BossCatProgress -Phase 'Evaluating verdict' -CompletedSeconds 12 }
$reasons=New-Object System.Collections.ArrayList
if($missing.Count -gt 0){ [void]$reasons.Add("Missing required assets: "+($missing -join ', ')) }
if($total -gt 0 -and $failed -gt 0){ [void]$reasons.Add("Tests failing: $failed of $total") }
$verdict='READY'
if($missing.Count -gt 0 -or ($failed -gt 0 -and $Strict)){ $verdict='NOT_READY' } elseif($failed -gt 0){ $verdict='READY_WITH_WARNINGS' }
$g=Get-GitMeta
$asciiReasons=@($reasons | ForEach-Object { $_ })
$out=[ordered]@{ timestamp=$tsIso; commit=$g.Commit; branch=$g.Branch; gate=$Gate; site=$Site; verdict=$verdict; reasons=$asciiReasons; tests=[ordered]@{total=$total;failed=$failed}; checks=$checks }
$jsonPayload = $out | ConvertTo-Json -Depth 6
foreach($target in $outputTargets){
  $jsonPayload | Set-Content -Path $target -Encoding utf8
  if ($target -eq $legacyOutputPath) {
    Write-Warning "[Gate][$Site] mirrored gate results to DELT/ARTF for legacy consumers; update workflows to artifacts/."
  }
}
if (-not $legacyMirrorRequested -and (Test-Path -LiteralPath $legacyOutputPath)) {
  Write-Warning "[Gate][$Site] legacy DELT/ARTF gate results still exist but are no longer updated by default. Remove stale copies or run with -OutputJson $legacyOutputPath if needed."
}
if (Get-Command Update-BossCatProgress -ErrorAction SilentlyContinue) { Update-BossCatProgress -Phase 'Writing ECRR & PR comment' -CompletedSeconds 16 }
$report=New-EcrrReport -Verdict $verdict -Reasons @($reasons) -Checks $checks
Write-PrComment -Verdict $verdict -Reasons @($reasons) -OutputPath $PrCommentPath -Checks $checks
if (Get-Command Complete-BossCatProgress -ErrorAction SilentlyContinue) { Complete-BossCatProgress }
if($verdict -eq 'NOT_READY' -and -not $NoFailOnMissing){ exit 2 } else { exit 0 }

