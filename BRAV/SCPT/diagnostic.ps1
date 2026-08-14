#!/usr/bin/env pwsh
#requires -Version 7
<#
.SYNOPSIS
    BossCat Diagnostic Shell (PowerShell Edition)
    
.DESCRIPTION
    Collects environment information for IONA gating compliance.
    Outputs JSON-formatted diagnostic data.
    
.PARAMETER OutputFile
    Path to output file (default: stdout)
    
.PARAMETER Pretty
    Pretty-print JSON output
    
.EXAMPLE
    .\scripts\diagnostic.ps1
    
.EXAMPLE
    .\scripts\diagnostic.ps1 -OutputFile artifacts\diagnostics.json -Pretty
    
.NOTES
    Part of: BossCat Gating Framework
    Version: 1.0.0
#>

param(
    [string]$OutputFile = "",
    [switch]$Pretty
)

$ErrorActionPreference = "Continue"

Write-Host "🔍 BossCat Diagnostic Shell - Collecting environment information..." -ForegroundColor Cyan
Write-Host ""

# Initialize diagnostic data structure
$diagnosticData = @{
    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    diagnostic_version = "1.0.0"
}

# ═══════════════════════════════════════════════════════════════════════
# System Information
# ═══════════════════════════════════════════════════════════════════════

Write-Host "  → Collecting system information..." -ForegroundColor Gray

$diagnosticData.os_type = if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) { "windows" } 
                          elseif ($IsLinux) { "linux" } 
                          elseif ($IsMacOS) { "macos" } 
                          else { "unknown" }

if ($diagnosticData.os_type -eq "windows") {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $diagnosticData.os_name = $osInfo.Caption
    $diagnosticData.os_version = $osInfo.Version
    $diagnosticData.kernel = "NT $($osInfo.Version)"
} else {
    $diagnosticData.os_name = (uname -s 2>$null) ?? "Unknown"
    $diagnosticData.os_version = (uname -r 2>$null) ?? "Unknown"
    $diagnosticData.kernel = (uname -r 2>$null) ?? "Unknown"
}

$diagnosticData.architecture = if ($diagnosticData.os_type -eq "windows") {
    $env:PROCESSOR_ARCHITECTURE
} else {
    uname -m 2>$null
}

$diagnosticData.hostname = $env:COMPUTERNAME ?? $env:HOSTNAME ?? (hostname)

# CPU Information
if ($diagnosticData.os_type -eq "windows") {
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $diagnosticData.cpu_model = $cpuInfo.Name
    $diagnosticData.cpu_cores = $cpuInfo.NumberOfLogicalProcessors
} else {
    $diagnosticData.cpu_model = (lscpu 2>$null | Select-String "Model name" | ForEach-Object { $_ -replace "Model name:\s+", "" }) ?? "Unknown"
    $diagnosticData.cpu_cores = (nproc 2>$null) ?? "Unknown"
}

# Memory Information
if ($diagnosticData.os_type -eq "windows") {
    $memInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $diagnosticData.memory_total_mb = [math]::Round($memInfo.TotalVisibleMemorySize / 1024)
    $diagnosticData.memory_available_mb = [math]::Round($memInfo.FreePhysicalMemory / 1024)
} else {
    $memTotal = (free -m 2>$null | Select-String "^Mem:" | ForEach-Object { ($_ -split '\s+')[1] })
    $memAvail = (free -m 2>$null | Select-String "^Mem:" | ForEach-Object { ($_ -split '\s+')[6] })
    $diagnosticData.memory_total_mb = $memTotal ?? "Unknown"
    $diagnosticData.memory_available_mb = $memAvail ?? "Unknown"
}

# Disk Usage
if ($diagnosticData.os_type -eq "windows") {
    $disk = Get-PSDrive -Name C -ErrorAction SilentlyContinue
    if ($disk) {
        $diagnosticData.disk_total = "$([math]::Round($disk.Used / 1GB + $disk.Free / 1GB, 2)) GB"
        $diagnosticData.disk_available = "$([math]::Round($disk.Free / 1GB, 2)) GB"
        $usedPercent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 1)
        $diagnosticData.disk_usage_percent = "$usedPercent%"
    }
} else {
    $dfOutput = df -h . 2>$null | Select-Object -Skip 1 -First 1
    if ($dfOutput) {
        $parts = $dfOutput -split '\s+'
        $diagnosticData.disk_total = $parts[1]
        $diagnosticData.disk_available = $parts[3]
        $diagnosticData.disk_usage_percent = $parts[4]
    }
}

# ═══════════════════════════════════════════════════════════════════════
# Tool Versions
# ═══════════════════════════════════════════════════════════════════════

Write-Host "  → Checking installed tools..." -ForegroundColor Gray

$diagnosticData.tools = @{}

# Helper to get command version
function Get-ToolVersion {
    param([string]$Command, [scriptblock]$VersionScript)
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            & $VersionScript
        }
    } catch {
        $null
    }
}

$diagnosticData.tools.git = Get-ToolVersion "git" { 
    (git --version) -replace 'git version ', ''
}

$diagnosticData.tools.docker = Get-ToolVersion "docker" { 
    (docker --version) -match '\d+\.\d+\.\d+' | Out-Null; $matches[0]
}

$diagnosticData.tools.docker_compose = Get-ToolVersion "docker-compose" { 
    (docker-compose --version) -match '\d+\.\d+\.\d+' | Out-Null; $matches[0]
}

$diagnosticData.tools.node = Get-ToolVersion "node" { 
    (node --version) -replace 'v', ''
}

$diagnosticData.tools.npm = Get-ToolVersion "npm" { 
    npm --version
}

$diagnosticData.tools.pnpm = Get-ToolVersion "pnpm" { 
    pnpm --version
}

$diagnosticData.tools.python3 = Get-ToolVersion "python" { 
    (python --version) -replace 'Python ', ''
}

$diagnosticData.tools.pip3 = Get-ToolVersion "pip" { 
    (pip --version) -match '\d+\.\d+\.\d+' | Out-Null; $matches[0]
}

$diagnosticData.tools.pwsh = Get-ToolVersion "pwsh" { 
    $PSVersionTable.PSVersion.ToString()
}

$diagnosticData.tools.playwright = Get-ToolVersion "npx" { 
    try {
        $output = npx playwright --version 2>$null
        $output -match '\d+\.\d+\.\d+' | Out-Null
        $matches[0]
    } catch {
        "not_installed"
    }
}

$diagnosticData.tools.gh = Get-ToolVersion "gh" { 
    (gh --version 2>$null | Select-Object -First 1) -replace 'gh version ', '' -replace ' .*', ''
}

$diagnosticData.tools.gitleaks = Get-ToolVersion "gitleaks" { 
    (gitleaks version 2>$null) -match '\d+\.\d+\.\d+' | Out-Null; $matches[0]
}

# Remove null entries
$diagnosticData.tools = $diagnosticData.tools.GetEnumerator() | 
    Where-Object { $_.Value } | 
    ForEach-Object -Begin { $h = @{} } -Process { $h[$_.Key] = $_.Value } -End { $h }

# ═══════════════════════════════════════════════════════════════════════
# Connectivity Checks
# ═══════════════════════════════════════════════════════════════════════

Write-Host "  → Testing connectivity..." -ForegroundColor Gray

$diagnosticData.connectivity = @{}

function Test-Connectivity {
    param([string]$Url, [int]$TimeoutSeconds = 5)
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        $response.StatusCode
    } catch {
        if ($_.Exception.Response) {
            $_.Exception.Response.StatusCode.value__
        } else {
            "000"
        }
    }
}

$diagnosticData.connectivity.github_api = Test-Connectivity "https://api.github.com/"
$diagnosticData.connectivity.npm_registry = Test-Connectivity "https://registry.npmjs.org/"
$diagnosticData.connectivity.pypi = Test-Connectivity "https://pypi.org/simple/"
$diagnosticData.connectivity.signoz_local = Test-Connectivity "http://localhost:8080/api/v1/health" -TimeoutSeconds 3
$diagnosticData.connectivity.otel_collector_http = Test-Connectivity "http://127.0.0.1:5321" -TimeoutSeconds 3

# ═══════════════════════════════════════════════════════════════════════
# Environment Variables (non-sensitive)
# ═══════════════════════════════════════════════════════════════════════

Write-Host "  → Collecting environment variables..." -ForegroundColor Gray

$diagnosticData.environment = @{}

$envVars = @(
    "OTEL_EXPORTER_OTLP_ENDPOINT",
    "OTEL_SERVICE_NAME",
    "OTEL_RESOURCE_ATTRIBUTES",
    "NODE_ENV",
    "CI"
)

foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if ($value) {
        $diagnosticData.environment[$var] = $value
    }
}

# ═══════════════════════════════════════════════════════════════════════
# Git Information
# ═══════════════════════════════════════════════════════════════════════

Write-Host "  → Collecting git information..." -ForegroundColor Gray

$diagnosticData.git = @{}

if (Get-Command git -ErrorAction SilentlyContinue) {
    try {
        $gitDir = git rev-parse --git-dir 2>$null
        if ($gitDir) {
            $diagnosticData.git.branch = git branch --show-current 2>$null
            $diagnosticData.git.commit = git rev-parse --short HEAD 2>$null
            $diagnosticData.git.remote = git remote get-url origin 2>$null
            $statusLines = (git status --porcelain 2>$null | Measure-Object).Count
            $diagnosticData.git.uncommitted_changes = $statusLines
        }
    } catch {
        # Not in a git repository
    }
}

# ═══════════════════════════════════════════════════════════════════════
# Output Results
# ═══════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "✅ Diagnostic collection complete!" -ForegroundColor Green

# Convert to JSON
$jsonOutput = if ($Pretty) {
    $diagnosticData | ConvertTo-Json -Depth 10
} else {
    $diagnosticData | ConvertTo-Json -Depth 10 -Compress
}

# Output to file or stdout
if ($OutputFile) {
    $jsonOutput | Set-Content -Path $OutputFile -Encoding UTF8
    Write-Host "📄 Diagnostic data saved to: $OutputFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  OS: $($diagnosticData.os_name) $($diagnosticData.os_version)" -ForegroundColor Gray
    Write-Host "  Architecture: $($diagnosticData.architecture)" -ForegroundColor Gray
    Write-Host "  CPU: $($diagnosticData.cpu_model) ($($diagnosticData.cpu_cores) cores)" -ForegroundColor Gray
    Write-Host "  Memory: $($diagnosticData.memory_total_mb) MB total, $($diagnosticData.memory_available_mb) MB available" -ForegroundColor Gray
    Write-Host "  Disk: $($diagnosticData.disk_available) available ($($diagnosticData.disk_usage_percent) used)" -ForegroundColor Gray
} else {
    Write-Output $jsonOutput
}

exit 0

