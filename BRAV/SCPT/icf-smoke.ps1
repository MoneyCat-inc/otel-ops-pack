Param(
  [string]$Url = $env:UI_URL,
  [int]$MaxRetries = 1,
  [int]$TimeoutSec = 10,
  [int]$RetryDelaySec = 5,
  [switch]$VerboseMode
)
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Get-GitMeta { try {$c=(git rev-parse --short HEAD 2>$null).Trim()}catch{$c=''}; try{$b=(git rev-parse --abbrev-ref HEAD 2>$null).Trim()}catch{$b=''}; [pscustomobject]@{Commit=$c;Branch=$b} }

$Url = if([string]::IsNullOrWhiteSpace($Url)){'https://example.com'} else {$Url}
$evDir = 'CHAR/EVID/artifacts/icf-smoke'
Ensure-Dir $evDir
$jsonl = Join-Path $evDir 'EVIDENCE.jsonl'

$attempt = 0
$ok = $false
$status = $null
$errorMsg = ''
$startAll = Get-Date
do {
  $attempt++
  $start = Get-Date
  try {
    $resp = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSec -MaximumRedirection 3 -UseBasicParsing
    $status = $resp.StatusCode
    if ($status -ge 200 -and $status -lt 500) { $ok = $true }
  } catch {
    $errorMsg = $_.Exception.Message
    $status = -1
    $ok = $false
  }
  $durMs = [int]((Get-Date) - $start).TotalMilliseconds
  $g = Get-GitMeta
  $record = [ordered]@{
    ts = (Get-Date).ToString('o')
    url = $Url
    attempt = $attempt
    status = $status
    ok = $ok
    duration_ms = $durMs
    commit = $g.Commit
    branch = $g.Branch
  }
  ($record | ConvertTo-Json -Compress) | Out-File -Append -FilePath $jsonl -Encoding utf8
  if (-not $ok -and $attempt -le $MaxRetries) { Start-Sleep -Seconds $RetryDelaySec }
} while(-not $ok -and $attempt -le $MaxRetries)

$totalMs = [int]((Get-Date) - $startAll).TotalMilliseconds
Write-Host "ICF smoke completed: ok=$ok status=$status attempts=$attempt totalMs=$totalMs"
if (-not $ok) { exit 1 } else { exit 0 }

