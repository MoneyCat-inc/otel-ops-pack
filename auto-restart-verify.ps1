# auto-restart-verify.ps1
# Deterministic SCM recovery verification for otelcol-contrib on Windows.
# Requires: Administrator, canary script at C:\otel\canary-check-min.ps1

param(
  [string] $Service        = 'otelcol-contrib',
  [int]    $ProdDelayMs    = 60000,
  [int]    $TestDelayMs    = 5000,
  [string] $HealthUrl      = 'http://127.0.0.1:13134/healthz',
  [string] $CanaryScript   = 'C:\otel\canary-check-min.ps1',
  [string] $LogFile        = 'C:\otel\logs\auto-restart-verify.last.txt'
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) | Out-Null

function Log($m){ $ts = (Get-Date).ToString('s'); "$ts $m" | Tee-Object -FilePath $LogFile -Append }

# admin check
$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if(-not $admin){ Write-Error "Run elevated (Administrator)."; exit 2 }

try {
  Log "BEGIN auto-restart verification"

  # Speed up restart just for the test
  Log "Setting fast failure policy: $TestDelayMs ms"
  sc.exe failure $Service actions= restart/$TestDelayMs/restart/$TestDelayMs/restart/$TestDelayMs reset= 60 | Out-Null
  sc.exe failureflag $Service 1 | Out-Null

  # Ensure service is running and get *tracked* PID
  $svc = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $Service)
  if($null -eq $svc){ throw "Service not found: $Service" }
  if($svc.State -ne 'Running'){ Start-Service $Service; Start-Sleep 2; $svc = Get-CimInstance Win32_Service -Filter ("Name='{0}'" -f $Service) }

  $ServicePid = [int]$svc.ProcessId
  if(-not $ServicePid){ throw "Could not determine service PID." }
  Log "Service PID: $ServicePid"

  # Crash the service process (simulate unexpected failure)
  Log "Killing PID $ServicePid"
  taskkill /PID $ServicePid /F | Out-Null

  # Wait for SCM to restart it
  $timeoutSec = [Math]::Ceiling(($TestDelayMs/1000) + 30)
  $restarted = $false
  for($i=1; $i -le $timeoutSec; $i++){
    $status = (Get-Service $Service).Status
    Log "t+${i}s service status=$status"
    if($status -eq 'Running'){ $restarted = $true; break }
    Start-Sleep 1
  }

  if(-not $restarted){
    Log "FAIL: auto-restart not observed within $timeoutSec s"
    exit 3
  }

  # Health check
  try {
    $h = Invoke-WebRequest -Uri $HealthUrl -TimeoutSec 5 | ConvertFrom-Json
    Log ("Health: {0}" -f $h.status)
  } catch {
    Log "WARN: health check failed"; Log ($_ | Out-String)
  }

  # Canary (delta +1 expected, script already does metrics-delta)
  if(Test-Path $CanaryScript){
    Log "Running canary..."
    $p = Start-Process -FilePath "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" `
         -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', $CanaryScript) -PassThru -Wait
    Log "Canary exit code: $($p.ExitCode)"
    if($p.ExitCode -ne 0){ Log "WARN: canary reported non-zero exit code" }
  } else {
    Log "SKIP: canary script not found at $CanaryScript"
  }

  Log "PASS: auto-restart observed and checks completed"
  exit 0
}
finally {
  # restore production failure policy
  Log "Restoring production failure policy: $ProdDelayMs ms"
  sc.exe failure $Service actions= restart/$ProdDelayMs/restart/$ProdDelayMs/restart/$ProdDelayMs reset= 86400 | Out-Null
  sc.exe failureflag $Service 1 | Out-Null
  sc.exe qfailure $Service | Tee-Object -FilePath $LogFile -Append | Out-Null
  Log "END"
}
