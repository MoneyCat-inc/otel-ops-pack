# chaos-drill.ps1
# Chaos drill for exporter outage testing and queue resilience verification
# ASCII only, PowerShell 5.1 compatible

param(
  [int]$OutageSeconds = 90
)

$ErrorActionPreference = "Stop"
$LogDir = "C:\otel\logs"
$Log = Join-Path $LogDir "chaos-drill.last.txt"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
function WL($m){ $ts=(Get-Date).ToString("s"); $line="[$ts] $m"; $line | Tee-Object -FilePath $Log -Append }
function Get-Metrics(){ try { (Invoke-WebRequest "http://127.0.0.1:8889/metrics" -TimeoutSec 5).Content -split "`n" } catch { @() } }

# Admin check
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
  IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Write-Error "Run elevated (Administrator)."; exit 1 }

WL "Starting chaos drill, outage=$OutageSeconds s"

$pre = Get-Metrics
$preFail = ($pre | ? {$_ -match 'exporter_send_failed_log_records'}).Count
WL "Pre-check: exporter_send_failed_log_records lines=$preFail"
$didDocker = $false
$ruleName = "OTel Chaos Drop SigNoz"

# Try Docker via WSL
try {
  $wslList = (wsl.exe -l) 2>$null
  if ($LASTEXITCODE -eq 0 -and $wslList) {
    $ps = wsl.exe -e sh -lc "docker ps --format '{{.Names}}'"
    $names = ($ps | Out-String).Trim().Split("`n") | % { $_.Trim() } | ? { $_ }
    if ($names -contains "signoz-otel-collector") {
      WL "Stopping docker container signoz-otel-collector..."
      wsl.exe -e sh -lc "docker stop signoz-otel-collector" | Out-Null
      $didDocker = $true
    } elseif ($names -contains "signoz") {
      WL "Stopping docker container signoz..."
      wsl.exe -e sh -lc "docker stop signoz" | Out-Null
      $didDocker = $true
    }
  }
} catch { }

# If docker path not available, fall back to firewall block
if (-not $didDocker) {
  WL "Applying firewall block to localhost:4317,4318..."
  netsh advfirewall firewall add rule name="$ruleName" dir=out action=block protocol=TCP remoteip=127.0.0.1 remoteport=4317,4318 | Out-Null
}

# Generate some traffic during outage
$pwsh = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
for($i=1;$i -le 3;$i++){
  Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File','C:\otel\canary-check-min.ps1') -Wait | Out-Null
  Start-Sleep 2
}

Start-Sleep $OutageSeconds

# Revert outage
if ($didDocker) {
  WL "Starting docker containers..."
  wsl.exe -e sh -lc "docker start signoz-otel-collector 2>/dev/null || true; docker start signoz 2>/dev/null || true" | Out-Null
} else {
  WL "Removing firewall block..."
  netsh advfirewall firewall delete rule name="$ruleName" | Out-Null
}

Start-Sleep 10
$post = Get-Metrics
$postFail = ($post | ? {$_ -match 'exporter_send_failed_log_records'}).Count
WL "Post-check: exporter_send_failed_log_records lines=$postFail (was $preFail)"

# Final canary
$p = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File','C:\otel\canary-check-min.ps1') -Wait -PassThru
WL "Final canary exit=$($p.ExitCode)"
if ($p.ExitCode -ne 0) { exit 2 } else { exit 0 }
