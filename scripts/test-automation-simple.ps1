# Quick test script to verify the streamlined automation setup
param(
    [switch]$Quick
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Testing streamlined automation setup..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$errors = @()
$success = @()

# 1. Check essential files exist
Write-Host "`nChecking essential files..." -ForegroundColor Yellow
$essentialFiles = @(
    ".github/workflows/ci.yml",
    ".pre-commit-config.yaml", 
    "requirements-dev.txt",
    "package.json",
    ".github/dependabot.yml",
    ".mergify.yml"
)

foreach ($file in $essentialFiles) {
    if (Test-Path $file) {
        $success += "[OK] $file exists"
    } else {
        $errors += "[ERROR] Missing: $file"
    }
}

# 2. Validate YAML files
Write-Host "`nValidating YAML files..." -ForegroundColor Yellow
try {
    $yamlFiles = @(".github/workflows/ci.yml", ".github/dependabot.yml", ".mergify.yml")
    $convertFromYaml = Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue
    if (-not $convertFromYaml) {
        try {
            Import-Module powershell-yaml -ErrorAction Stop | Out-Null
            $convertFromYaml = Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue
        } catch {
            $success += "[WARN] ConvertFrom-Yaml not available; skipping YAML validation (install powershell-yaml for local checks)"
        }
    }

    foreach ($file in $yamlFiles) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            if ($convertFromYaml) {
                try {
                    $null = ConvertFrom-Yaml -Yaml $content
                    $success += "[OK] $file is valid YAML"
                } catch {
                    $errors += "[ERROR] $file has invalid YAML syntax: $($_.Exception.Message)"
                }
            } else {
                $success += "[WARN] Skipped validation for $file (ConvertFrom-Yaml unavailable)"
            }
        }
    }
} catch {
    $errors += "[ERROR] YAML validation failed: $_"
}

# 3. Check package.json scripts
Write-Host "`nChecking package.json..." -ForegroundColor Yellow
try {
    if (Test-Path "package.json") {
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        $requiredScripts = @("lint", "typecheck", "test", "quality")
        foreach ($script in $requiredScripts) {
            if ($packageJson.scripts.$script) {
                $success += "[OK] npm script: $script"
            } else {
                $errors += "[ERROR] Missing npm script: $script"
            }
        }
        
        if ($packageJson.devDependencies) {
            $success += "[OK] package.json has devDependencies"
        } else {
            $errors += "[ERROR] package.json missing devDependencies"
        }
    }
} catch {
    $errors += "[ERROR] package.json check failed: $_"
}

# 4. Test PowerShell linting (if not in quick mode)
if (-not $Quick) {
    Write-Host "`nTesting PowerShell linting..." -ForegroundColor Yellow
    try {
        # Check if PSScriptAnalyzer is available
        if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
            $success += "[OK] PSScriptAnalyzer available"
        } else {
            $success += "[WARN] PSScriptAnalyzer not installed (will install in CI)"
        }
    } catch {
        $success += "[WARN] PowerShell check skipped"
    }
}

# 5. Check Python dependencies
Write-Host "`nChecking Python setup..." -ForegroundColor Yellow
try {
    $pythonDeps = @("flake8", "mypy", "pytest", "yamllint")
    foreach ($dep in $pythonDeps) {
        $result = python -c "import $dep" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $success += "[OK] Python: $dep available"
        } else {
            $success += "[WARN] Python: $dep not installed (will install in CI)"
        }
    }
} catch {
    $success += "[WARN] Python check skipped"
}

# Summary
Write-Host "`nTest Results:" -ForegroundColor Cyan
Write-Host "=============" -ForegroundColor Cyan

if ($success.Count -gt 0) {
    Write-Host "`nSuccesses ($($success.Count)):" -ForegroundColor Green
    foreach ($item in $success) {
        Write-Host "  $item" -ForegroundColor Green
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`nErrors ($($errors.Count)):" -ForegroundColor Red
    foreach ($item in $errors) {
        Write-Host "  $item" -ForegroundColor Red
    }
}

# Final Status
Write-Host "`nFinal Status:" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "PERFECT! Streamlined automation is ready!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Run: pip install -r requirements-dev.txt" -ForegroundColor White
    Write-Host "2. Run: npm install" -ForegroundColor White
    Write-Host "3. Run: pre-commit install" -ForegroundColor White
    Write-Host "4. Create a test PR to verify CI works" -ForegroundColor White
    Write-Host "`nThe cat can now nap while the bots do laps!" -ForegroundColor Magenta
    exit 0
} else {
    Write-Host "ISSUES FOUND! Please fix the errors above." -ForegroundColor Red
    exit 1
}
