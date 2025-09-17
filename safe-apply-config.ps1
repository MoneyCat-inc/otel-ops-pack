# safe-apply-config.ps1
# Safe config apply with automatic rollback on canary failure
# ASCII only, PowerShell 5.1 compatible

param(
  [string]$Candidate = "C:\otel\config.candidate.yaml",
  [switch]$NoCanary
)

$ErrorActionPreference = "Stop"
$Service = "otelcol-contrib"
$Exe = "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe"
$Target = "C:\otel\config.yaml"
$LogDir = "C:\otel\logs"
$Log = Join-Path $LogDir "safe-apply.last.txt"
$Canary = "C:\otel\canary-check-min.ps1"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
function WL($m){ $ts=(Get-Date).ToString("s"); $line="[$ts] $m"; $line | Tee-Object -FilePath $Log -Append }

# Admin check
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
  IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Write-Error "Run elevated (Administrator)."; exit 1 }

if (-not (Test-Path $Candidate)) { Write-Error "Candidate not found: $Candidate"; exit 2 }

# Validate config (newer collectors support 'validate')
try {
  $p = Start-Process -FilePath $Exe -ArgumentList @("validate","--config",$Candidate) -Wait -PassThru
  if ($p.ExitCode -ne 0) { throw "validate exit code $($p.ExitCode)" }
  WL "Validation OK for $Candidate"
} catch {
  WL "Validation FAILED: $($_.Exception.Message)"
  exit 3
}

# Backup current target
$stamp = (Get-Date).ToString("yyyyMMddHHmmss")
$bak = "C:\otel\config.bak.$stamp.yaml"
if (Test-Path $Target) { Copy-Item -Force $Target $bak; WL "Backup created: $bak" }

# Apply candidate
Copy-Item -Force $Candidate $Target
WL "Installed $Candidate -> $Target"

# Restart service
Restart-Service $Service -ErrorAction Stop
Start-Sleep 5
WL "Service restarted."

if (-not $NoCanary) {
  if (-not (Test-Path $Canary)) { WL "Canary script not found: $Canary"; exit 4 }
  $pwsh = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
  $p = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$Canary) -Wait -PassThru
  if ($p.ExitCode -ne 0) {
    WL "Canary FAILED (exit $($p.ExitCode)). Rolling back to $bak"
    if (Test-Path $bak) {
      Copy-Item -Force $bak $Target
      Restart-Service $Service -ErrorAction Stop
      Start-Sleep 5
      $p2 = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$Canary) -Wait -PassThru
      WL "Rollback canary exit: $($p2.ExitCode)"
    }
    exit 10
  } else {
    WL "Canary PASS after apply."
  }
}

WL "Safe apply COMPLETE."
exit 0
