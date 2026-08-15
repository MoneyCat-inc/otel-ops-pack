#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Repo hygiene validation script for OTel Ops Pack
.DESCRIPTION
    Validates PowerShell scripts, YAML configs, OTel collector configs,
    Docker compose files, and overall repo structure per docs/REPO_HYGIENE.md
.PARAMETER SkipDocker
    Skip Docker-related checks when daemon is unavailable
.PARAMETER SkipOtelCol
    Skip OTel collector validation (useful on Linux without Windows collector)
.PARAMETER ArtifactsPath
    Path to artifacts directory (default: artifacts)
.EXAMPLE
    .\tools\hygiene.ps1
.EXAMPLE
    .\tools\hygiene.ps1 -SkipDocker -SkipOtelCol
#>

[CmdletBinding()]
param(
    [switch]$SkipDocker,
    [switch]$SkipOtelCol,
    [string]$ArtifactsPath = "artifacts"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ensure artifacts directory exists
if (-not (Test-Path $ArtifactsPath)) {
    New-Item -ItemType Directory -Path $ArtifactsPath -Force | Out-Null
}

$logFile = Join-Path $ArtifactsPath "hygiene.log"
Start-Transcript -Path $logFile -Append | Out-Null

Write-Host "🔧 OTel Ops Pack - Repo Hygiene Validation" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$failures = @()
$warnings = @()

# Helper function to add failures
function Add-Failure {
    param([string]$Message)
    $script:failures += $Message
    Write-Host "❌ FAIL: $Message" -ForegroundColor Red
}

# Helper function to add warnings
function Add-Warning {
    param([string]$Message)
    $script:warnings += $Message
    Write-Host "⚠️  WARN: $Message" -ForegroundColor Yellow
}

# Helper function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

Write-Host "`n1️⃣ Checking PowerShell Script Quality..." -ForegroundColor Green

# Check if PSScriptAnalyzer is available
if (Test-Command "Invoke-ScriptAnalyzer") {
    Write-Host "Running PSScriptAnalyzer on scripts/ directory..."
    try {
        $scriptIssues = Invoke-ScriptAnalyzer -Path "scripts" -Recurse -Severity @('Error', 'Warning')
        if ($scriptIssues) {
            foreach ($issue in $scriptIssues) {
                Add-Warning "PSScriptAnalyzer: $($issue.RuleName) in $($issue.ScriptName):$($issue.Line) - $($issue.Message)"
            }
        } else {
            Write-Host "✅ PSScriptAnalyzer: No issues found" -ForegroundColor Green
        }
    } catch {
        Add-Failure "PSScriptAnalyzer failed: $($_.Exception.Message)"
    }
} else {
    Add-Warning "PSScriptAnalyzer not available - install with: Install-Module PSScriptAnalyzer -Scope CurrentUser"
}

# Check PowerShell script structure
Write-Host "Checking PowerShell script structure..."
$psScripts = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse
foreach ($script in $psScripts) {
    $content = Get-Content $script.FullName -Raw
    
    # Check for Set-StrictMode
    if ($content -notmatch "Set-StrictMode") {
        Add-Warning "Missing Set-StrictMode in $($script.Name)"
    }
    
    # Check for ErrorActionPreference
    if ($content -notmatch "ErrorActionPreference") {
        Add-Warning "Missing ErrorActionPreference in $($script.Name)"
    }
}

Write-Host "`n2️⃣ Checking YAML Configuration..." -ForegroundColor Green

# Check if yamllint is available
if (Test-Command "yamllint") {
    Write-Host "Running yamllint on YAML files..."
    try {
        $yamlFiles = @(
            "compose/*.yml",
            "compose/*.yaml", 
            ".github/workflows/*.yml",
            ".github/workflows/*.yaml",
            "configs/otel/*.yaml",
            "configs/otel/*.yml"
        )
        
        foreach ($pattern in $yamlFiles) {
            $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                Write-Host "Linting $($file.Name)..."
                $result = & yamllint $file.FullName 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Add-Warning "yamllint issues in $($file.Name): $result"
                }
            }
        }
    } catch {
        Add-Warning "yamllint failed: $($_.Exception.Message)"
    }
} else {
    Add-Warning "yamllint not available - install with: pip install yamllint"
}

Write-Host "`n3️⃣ Checking Docker Configuration..." -ForegroundColor Green

if (-not $SkipDocker) {
    # Check if Docker is available
    if (Test-Command "docker") {
        Write-Host "Checking Docker availability..."
        try {
            $dockerInfo = & docker info 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Docker daemon is running" -ForegroundColor Green
                
                # Validate compose files
                $composeFiles = Get-ChildItem -Path "compose" -Filter "*.yml" -ErrorAction SilentlyContinue
                foreach ($file in $composeFiles) {
                    Write-Host "Validating $($file.Name)..."
                    $result = & docker compose -f $file.FullName config 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Add-Failure "Docker compose validation failed for $($file.Name): $result"
                    } else {
                        Write-Host "✅ $($file.Name) is valid" -ForegroundColor Green
                    }
                }
            } else {
                Add-Warning "Docker daemon not running: $dockerInfo"
                $SkipDocker = $true
            }
        } catch {
            Add-Warning "Docker check failed: $($_.Exception.Message)"
            $SkipDocker = $true
        }
    } else {
        Add-Warning "Docker not available"
        $SkipDocker = $true
    }
} else {
    Write-Host "Skipping Docker checks (SkipDocker flag)" -ForegroundColor Yellow
}

Write-Host "`n4️⃣ Checking OTel Collector Configuration..." -ForegroundColor Green

if (-not $SkipOtelCol) {
    # Check if otelcol is available
    if (Test-Command "otelcol") {
        Write-Host "Validating OTel collector configurations..."
        $otelConfigs = Get-ChildItem -Path "configs/otel" -Filter "*.yaml" -ErrorAction SilentlyContinue
        foreach ($config in $otelConfigs) {
            Write-Host "Validating $($config.Name)..."
            try {
                $result = & otelcol --config $config.FullName --dry-run 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Add-Failure "OTel config validation failed for $($config.Name): $result"
                } else {
                    Write-Host "✅ $($config.Name) is valid" -ForegroundColor Green
                }
            } catch {
                Add-Failure "OTel config validation error for $($config.Name): $($_.Exception.Message)"
            }
        }
    } else {
        Add-Warning "otelcol not available - install OpenTelemetry Collector"
    }
} else {
    Write-Host "Skipping OTel collector checks (SkipOtelCol flag)" -ForegroundColor Yellow
}

Write-Host "`n5️⃣ Checking Repository Structure..." -ForegroundColor Green

# Check for required files
$requiredFiles = @(
    "README.md",
    "LICENSE",
    "SECURITY.md",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    ".editorconfig",
    ".gitattributes",
    ".gitignore",
    ".env.example",
    "docs/REPO_HYGIENE.md"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Add-Failure "Missing required file: $file"
    }
}

# Check for required directories
$requiredDirs = @(
    "docs",
    "scripts",
    "configs/otel",
    "compose",
    "artifacts",
    ".github/workflows",
    ".github/ISSUE_TEMPLATE"
)

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "✅ $dir/ exists" -ForegroundColor Green
    } else {
        Add-Failure "Missing required directory: $dir/"
    }
}

Write-Host "`n6️⃣ Checking for Secrets..." -ForegroundColor Green

# Basic secret patterns (simplified to avoid regex issues)
$secretPatterns = @(
    'password\s*=\s*["''][^"'']+["'']',
    'secret\s*=\s*["''][^"'']+["'']',
    'token\s*=\s*["''][^"'']+["'']',
    'key\s*=\s*["''][^"'']+["'']',
    'api[_-]?key\s*=\s*["''][^"'']+["'']'
)

$filesToCheck = Get-ChildItem -Recurse -File | Where-Object { 
    $_.Extension -in @('.ps1', '.yml', '.yaml', '.json', '.env', '.config') -and
    $_.Name -notlike '*.example' -and
    $_.Name -notlike '*.template'
}

foreach ($file in $filesToCheck) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        foreach ($pattern in $secretPatterns) {
            if ($content -match $pattern) {
                Add-Warning "Potential secret pattern found in $($file.FullName): $($matches[0])"
            }
        }
    }
}

Write-Host "`n7️⃣ Generating Structure Snapshot..." -ForegroundColor Green

$treeFile = Join-Path $ArtifactsPath "tree.txt"
Get-ChildItem -Recurse -File | Select-Object FullName | Out-File $treeFile
Write-Host "✅ Structure snapshot saved to $treeFile" -ForegroundColor Green

# Summary
Write-Host "`n📊 Hygiene Validation Summary" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

if ($failures.Count -eq 0) {
    Write-Host "✅ All critical checks passed!" -ForegroundColor Green
} else {
    Write-Host "❌ $($failures.Count) critical issues found:" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host "  • $failure" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  $($warnings.Count) warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  • $warning" -ForegroundColor Yellow
    }
}

Write-Host "`n📝 Full log saved to: $logFile" -ForegroundColor Cyan

Stop-Transcript | Out-Null

# Exit with error code if there were failures
if ($failures.Count -gt 0) {
    exit 1
} else {
    exit 0
}
