Param(
  [switch]$Strict,
  [string]$OutputJson = 'DELT/ARTF/gate-verification-results.json',
  [string]$PrCommentPath = 'PR_COMMENT_IONA_GATE_002_FINAL.md',
  [switch]$NoFailOnMissing,
  [string]$Gate = 'IONA',
  [string]$Site = 'ci'
)
$ErrorActionPreference = 'Stop'
try { Import-Module -Name "$(Join-Path $PSScriptRoot 'lib/BossCat.Progress.psm1')" -ErrorAction SilentlyContinue } catch {}
if (Get-Command Start-BossCatProgress -ErrorAction SilentlyContinue) { Start-BossCatProgress -Activity 'IONA Gate Verify' -ExpectedTotalSeconds 20 }
function Get-GitMeta { try {$c=(git rev-parse --short HEAD 2>$null).Trim()}catch{$c=''}; try{$b=(git rev-parse --abbrev-ref HEAD 2>$null).Trim()}catch{$b=''}; [pscustomobject]@{Commit=$c;Branch=$b} }
function Ensure-Dirs([string[]]$Dirs){ foreach($d in $Dirs){ if(-not(Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Path $d -Force|Out-Null } } }
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
  $dir = 'docs/ecrr/ECRR_REPORTS'
  Ensure-Dirs @($dir)
  $name = Join-Path $dir ("ECRR_GATE_RUN_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.md')
  $content = $lines -join "`r`n"
  $content | Set-Content -Path $name -Encoding utf8
  $content | Set-Content -Path (Join-Path $dir 'ECRR_GATE_RUN_LATEST.md') -Encoding utf8
  return $name
}
function Write-PrComment([string]$Verdict,[string[]]$Reasons,[string]$OutputPath){
  $g = Get-GitMeta
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'
  $lines = @(
    '# IONA Gate - BossCat Verdict',
    '',
    "- Verdict: $Verdict",
    "- Timestamp: $ts",
    "- Commit: $($g.Commit)",
    "- Branch: $($g.Branch)",
    "- Gate: $Gate",
    "- Site: $Site",
    '',
    '## Reasons'
  )
  if (-not $Reasons -or $Reasons.Count -eq 0) { $lines += '- None' } else { foreach($r in $Reasons){ $lines += "- $r" } }
  ($lines -join "`r`n") | Set-Content -Path $OutputPath -Encoding utf8
}
$tsIso=Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'; Ensure-Dirs @('DELT/ARTF','docs/ecrr/ECRR_REPORTS')
if (Get-Command Update-BossCatProgress -ErrorAction SilentlyContinue) { Update-BossCatProgress -Phase 'Collecting required assets' -CompletedSeconds 3 }
$required=@('.github/workflows/bosscat-gate-verify.yml','docs/status/tests.json','docs/status.html','docs/ecrr/ECRR_REPORTS','docs/observability/snapshots','docs/IONA_ERRORS.md','docs/cheatsheets','index.html')
$nonCritical=@('scripts/benchmark-process-all-ecrr-reports.ps1','ALFA/TEST/helpers/signoz.ts','docs/BossCat/README.md')
Ensure-Dirs @('docs/observability/snapshots','docs/cheatsheets')
$checks=@{}; $missing=New-Object System.Collections.ArrayList
foreach($p in $required){ $ex=Test-Path -LiteralPath $p; $checks[$p]= if($ex){'present'} else {'missing'}; if(-not $ex){[void]$missing.Add($p)} }
if (Get-Command Update-BossCatProgress -ErrorAction SilentlyContinue) { Update-BossCatProgress -Phase 'Reading status tests' -CompletedSeconds 7 }
foreach($p in $nonCritical){ $checks[$p]= if(Test-Path -LiteralPath $p){'present'} else {'missing'} }

# Composite check: queue-steward-verification.txt may reside in DELT/ARTF or artifacts
$queuePaths=@('DELT/ARTF/queue-steward-verification.txt','artifacts/queue-steward-verification.txt')
$queuePresent=$false
foreach($qp in $queuePaths){ if(Test-Path -LiteralPath $qp){ $queuePresent=$true; break } }
$checks['queue-steward-verification.txt']= if($queuePresent){'present'} else {'missing'}
# Treat queue-steward verification evidence as REQUIRED
if (-not $queuePresent) {
  [void]$missing.Add('queue-steward-verification.txt')
}
$s=Read-TestsJson; $failed=[int]$s.failed; $total=[int]$s.total
if (Get-Command Update-BossCatProgress -ErrorAction SilentlyContinue) { Update-BossCatProgress -Phase 'Evaluating verdict' -CompletedSeconds 12 }
$reasons=New-Object System.Collections.ArrayList
if($missing.Count -gt 0){ [void]$reasons.Add("Missing required assets: "+($missing -join ', ')) }
if($total -gt 0 -and $failed -gt 0){ [void]$reasons.Add("Tests failing: $failed of $total") }
$verdict='READY'
if($missing.Count -gt 0 -or ($failed -gt 0 -and $Strict)){ $verdict='NOT_READY' } elseif($failed -gt 0){ $verdict='READY_WITH_WARNINGS' }
$g=Get-GitMeta
$out=[ordered]@{ timestamp=$tsIso; commit=$g.Commit; branch=$g.Branch; gate=$Gate; site=$Site; verdict=$verdict; reasons=@($reasons); tests=[ordered]@{total=$total;failed=$failed}; checks=$checks }
($out|ConvertTo-Json -Depth 6)|Set-Content -Path $OutputJson -Encoding utf8
if (Get-Command Update-BossCatProgress -ErrorAction SilentlyContinue) { Update-BossCatProgress -Phase 'Writing ECRR & PR comment' -CompletedSeconds 16 }
$report=New-EcrrReport -Verdict $verdict -Reasons @($reasons) -Checks $checks
Write-PrComment -Verdict $verdict -Reasons @($reasons) -OutputPath $PrCommentPath
if (Get-Command Complete-BossCatProgress -ErrorAction SilentlyContinue) { Complete-BossCatProgress }
if($verdict -eq 'NOT_READY' -and -not $NoFailOnMissing){ exit 2 } else { exit 0 }
