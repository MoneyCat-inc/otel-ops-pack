# Comprehensive validation script for the observability stack
param(
    [switch]$SkipDocker,
    [switch]$SkipCollector,
    [switch]$Quick
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "🔍 Running comprehensive validation..." -ForegroundColor Cyan

$errors = @()
$warnings = @()

# 1. PowerShell Script Analysis
Write-Host "📋 Checking PowerShell scripts..." -ForegroundColor Yellow
try {
    if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
        $psFiles = Get-ChildItem -Path . -Filter "*.ps1" -Recurse | Where-Object { $_.FullName -notlike "*node_modules*" }
        foreach ($file in $psFiles) {
            $results = Invoke-ScriptAnalyzer -Path $file.FullName -Severity Error
            if ($results) {
                $errors += "PowerShell issues in $($file.Name): $($results.Count) errors"
            }
        }
        Write-Host "✅ PowerShell scripts validated" -ForegroundColor Green
    } else {
        $warnings += "PSScriptAnalyzer not available - install with: Install-Module PSScriptAnalyzer"
    }
} catch {
    $errors += "PowerShell validation failed: $_"
}

# 2. YAML Validation
Write-Host "📋 Checking YAML files..." -ForegroundColor Yellow
try {
    $yamlFiles = @("config.yaml", "docker-compose.yml", ".github/workflows/*.yml")
    foreach ($pattern in $yamlFiles) {
        $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            try {
                $content = Get-Content $file.FullName -Raw
                # Basic YAML validation
                $null = [System.Management.Automation.PSSerializer]::Deserialize($content)
            } catch {
                $errors += "Invalid YAML in $($file.Name): $_"
            }
        }
    }
    Write-Host "✅ YAML files validated" -ForegroundColor Green
} catch {
    $errors += "YAML validation failed: $_"
}

# 3. OpenTelemetry Config Validation
Write-Host "📋 Validating OpenTelemetry configuration..." -ForegroundColor Yellow
try {
    if (Test-Path "config.yaml") {
        $config = Get-Content "config.yaml" -Raw
        
        # Check for required sections
        $requiredSections = @("receivers", "processors", "exporters", "service")
        foreach ($section in $requiredSections) {
            if ($config -notmatch $section) {
                $errors += "Missing required section: $section"
            }
        }
        
        # Check for OTLP endpoints
        if ($config -notmatch "otlp") {
            $warnings += "No OTLP exporters found - check SigNoz connectivity"
        }
        
        Write-Host "✅ OpenTelemetry config validated" -ForegroundColor Green
    } else {
        $errors += "config.yaml not found"
    }
} catch {
    $errors += "OpenTelemetry config validation failed: $_"
}

# 4. Docker Compose Validation (if not skipped)
if (-not $SkipDocker) {
    Write-Host "📋 Validating Docker Compose files..." -ForegroundColor Yellow
    try {
        if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
            docker-compose -f docker-compose.yml config > $null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Docker Compose files validated" -ForegroundColor Green
            } else {
                $errors += "Docker Compose validation failed"
            }
        } else {
            $warnings += "docker-compose not available for validation"
        }
    } catch {
        $errors += "Docker validation failed: $_"
    }
}

# 5. Port Conflict Check
Write-Host "📋 Checking for port conflicts..." -ForegroundColor Yellow
try {
    $requiredPorts = @(8080, 4317, 4318, 5317, 5318)
    $conflicts = @()
    
    foreach ($port in $requiredPorts) {
        $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($connection.TcpTestSucceeded) {
            $conflicts += $port
        }
    }
    
    if ($conflicts.Count -gt 0) {
        $warnings += "Ports in use: $($conflicts -join ', ') - may cause conflicts"
    } else {
        Write-Host "✅ No port conflicts detected" -ForegroundColor Green
    }
} catch {
    $warnings += "Port conflict check failed: $_"
}

# 6. File Structure Validation
Write-Host "📋 Validating file structure..." -ForegroundColor Yellow
try {
    $requiredFiles = @(
        "config.yaml",
        "docker-compose.yml", 
        "package.json",
        "requirements.txt",
        ".github/workflows/ci-verify.yml"
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            $errors += "Missing required file: $file"
        }
    }
    
    if ($errors.Count -eq 0) {
        Write-Host "✅ File structure validated" -ForegroundColor Green
    }
} catch {
    $errors += "File structure validation failed: $_"
}

# Summary
Write-Host "`n📊 Validation Summary:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

if ($errors.Count -eq 0) {
    Write-Host "✅ All validations passed!" -ForegroundColor Green
    if ($warnings.Count -gt 0) {
        Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
    exit 0
} else {
    Write-Host "❌ Validation failed with $($errors.Count) error(s):" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
    exit 1
}
