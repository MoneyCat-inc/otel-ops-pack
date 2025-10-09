# scripts/agent/service-install.ps1 - Install codex-local as Windows Service

param(
    [string]$ServiceName = "codex-local",
    [string]$RepoRoot = (Resolve-Path "..\.."),
    [string]$NssmPath = "$PSScriptRoot\nssm.exe",
    [switch]$Force,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Write-ServiceResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

Write-Host "🔧 codex-local Windows Service Installation" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-ServiceResult -Message "Administrator privileges required for service installation" -Success $false
    exit 1
}

# Check if NSSM is available
if (-not (Test-Path $NssmPath)) {
    Write-ServiceResult -Message "NSSM not found at $NssmPath" -Success $false
    Write-Host "Please download NSSM from: https://nssm.cc/download" -ForegroundColor Yellow
    Write-Host "Extract nssm.exe to: $PSScriptRoot" -ForegroundColor Yellow
    exit 1
}

# Check if service already exists
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existingService -and -not $Force) {
    Write-ServiceResult -Message "Service '$ServiceName' already exists. Use -Force to reinstall." -Success $false
    exit 1
}

if ($existingService -and $Force) {
    Write-Host "`n🔄 Removing existing service..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    & $NssmPath remove $ServiceName confirm
    Write-ServiceResult -Message "Existing service removed"
}

# Validate repository structure
$packageJson = Join-Path $RepoRoot "package.json"
if (-not (Test-Path $packageJson)) {
    Write-ServiceResult -Message "package.json not found in $RepoRoot" -Success $false
    exit 1
}

# Ensure .agent directory exists
$agentDir = Join-Path $RepoRoot ".agent"
if (-not (Test-Path $agentDir)) {
    New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
    Write-ServiceResult -Message "Created .agent directory"
}

# Install service
Write-Host "`n📦 Installing Windows Service..." -ForegroundColor Yellow

try {
    # Install service with pnpm command
    $pnpmPath = Get-Command pnpm -ErrorAction Stop | Select-Object -ExpandProperty Source
    $installArgs = @(
        "install", $ServiceName,
        $pnpmPath, "run", "agent:start"
    )
    
    & $NssmPath $installArgs
    Write-ServiceResult -Message "Service installed with pnpm command"
    
    # Configure service settings
    Write-Host "`n⚙️ Configuring service settings..." -ForegroundColor Yellow
    
    # Set application directory
    & $NssmPath set $ServiceName AppDirectory $RepoRoot
    Write-ServiceResult -Message "Application directory set to: $RepoRoot"
    
    # Set log files
    $logDir = Join-Path $agentDir "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $stdoutLog = Join-Path $logDir "service.out.log"
    $stderrLog = Join-Path $logDir "service.err.log"
    
    & $NssmPath set $ServiceName AppStdout $stdoutLog
    & $NssmPath set $ServiceName AppStderr $stderrLog
    Write-ServiceResult -Message "Log files configured: $stdoutLog, $stderrLog"
    
    # Set service properties
    & $NssmPath set $ServiceName DisplayName "codex-local Agent"
    & $NssmPath set $ServiceName Description "Autonomous observability subsystem for Windows environments"
    & $NssmPath set $ServiceName Start SERVICE_AUTO_START
    
    # Set stop method
    & $NssmPath set $ServiceName AppStopMethodConsole 5000
    Write-ServiceResult -Message "Service properties configured"
    
    # Set environment variables
    & $NssmPath set $ServiceName AppEnvironmentExtra "NODE_ENV=production" "CI=false"
    Write-ServiceResult -Message "Environment variables set"
    
    # Start service
    Write-Host "`n🚀 Starting service..." -ForegroundColor Yellow
    & $NssmPath start $ServiceName
    
    # Wait for service to start
    Start-Sleep -Seconds 3
    
    # Verify service status
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-ServiceResult -Message "Service started successfully"
    } else {
        Write-ServiceResult -Message "Service failed to start" -Success $false
        Write-Host "Check logs: $stdoutLog, $stderrLog" -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-ServiceResult -Message "Service installation failed: $($_.Exception.Message)" -Success $false
    exit 1
}

# Generate service info
$serviceInfo = @{
    serviceName = $ServiceName
    status = "Running"
    installedAt = (Get-Date).ToString("o")
    repoRoot = $RepoRoot
    logFiles = @{
        stdout = $stdoutLog
        stderr = $stderrLog
    }
    nssmPath = $NssmPath
} | ConvertTo-Json -Depth 3

$serviceInfoPath = Join-Path $agentDir "service-info.json"
$serviceInfo | Set-Content $serviceInfoPath -Encoding UTF8
Write-ServiceResult -Message "Service info saved to: $serviceInfoPath"

Write-Host "`n🎉 Service Installation Complete" -ForegroundColor Green
Write-Host "Service Name: $ServiceName" -ForegroundColor Gray
Write-Host "Status: $($service.Status)" -ForegroundColor Gray
Write-Host "Logs: $stdoutLog" -ForegroundColor Gray
Write-Host "`nManagement Commands:" -ForegroundColor Cyan
Write-Host "  Start:   sc start $ServiceName" -ForegroundColor Gray
Write-Host "  Stop:    sc stop $ServiceName" -ForegroundColor Gray
Write-Host "  Status:  sc query $ServiceName" -ForegroundColor Gray
Write-Host "  Logs:    Get-Content `"$stdoutLog`"" -ForegroundColor Gray
