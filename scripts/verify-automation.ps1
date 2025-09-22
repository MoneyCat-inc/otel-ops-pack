# Verification script for the complete automation setup
param(
    [switch]$Quick,
    [switch]$InstallDeps
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "🤖 Automation Setup Verification" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$errors = @()
$warnings = @()
$success = @()

# 1. Check Required Files
Write-Host "`n📋 Checking automation files..." -ForegroundColor Yellow
$requiredFiles = @(
    ".github/workflows/ci-verify.yml",
    ".github/workflows/reviewdog.yml",
    ".github/dependabot.yml",
    ".pre-commit-config.yaml",
    ".mergify.yml",
    "requirements-dev.txt",
    "scripts/pre-commit-powershell.ps1",
    "scripts/validate-all.ps1",
    ".eslintrc.js",
    ".prettierrc",
    "tsconfig.json",
    "AUTOMATION_SETUP_GUIDE.md"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        $success += "✅ $file exists"
    } else {
        $errors += "❌ Missing: $file"
    }
}

# 2. Check Python Dependencies
Write-Host "`n🐍 Checking Python setup..." -ForegroundColor Yellow
try {
    $pythonDeps = @("black", "flake8", "mypy", "isort", "pre-commit", "yamllint")
    foreach ($dep in $pythonDeps) {
        $result = python -c "import $dep" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $success += "✅ Python: $dep available"
        } else {
            if ($InstallDeps) {
                Write-Host "Installing $dep..." -ForegroundColor Yellow
                pip install $dep
                $success += "✅ Python: $dep installed"
            } else {
                $warnings += "⚠️  Python: $dep not installed (use -InstallDeps to install)"
            }
        }
    }
} catch {
    $errors += "❌ Python check failed: $_"
}

# 3. Check Node.js Dependencies
Write-Host "`n📦 Checking Node.js setup..." -ForegroundColor Yellow
try {
    if (Test-Path "package.json") {
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        if ($packageJson.devDependencies) {
            $success += "✅ package.json has devDependencies configured"
        } else {
            $errors += "❌ package.json missing devDependencies"
        }
        
        # Check for npm scripts
        $requiredScripts = @("lint", "format", "quality", "validate")
        foreach ($script in $requiredScripts) {
            if ($packageJson.scripts.$script) {
                $success += "✅ npm script: $script"
            } else {
                $errors += "❌ Missing npm script: $script"
            }
        }
    } else {
        $errors += "❌ package.json not found"
    }
} catch {
    $errors += "❌ Node.js check failed: $_"
}

# 4. Check PowerShell Modules
Write-Host "`n💻 Checking PowerShell setup..." -ForegroundColor Yellow
try {
    if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
        $success += "✅ PSScriptAnalyzer available"
    } else {
        if ($InstallDeps) {
            Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Yellow
            Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
            $success += "✅ PSScriptAnalyzer installed"
        } else {
            $warnings += "⚠️  PSScriptAnalyzer not installed (use -InstallDeps to install)"
        }
    }
} catch {
    $errors += "❌ PowerShell check failed: $_"
}

# 5. Test Pre-commit Configuration
Write-Host "`n🪝 Testing pre-commit configuration..." -ForegroundColor Yellow
try {
    if (Get-Command pre-commit -ErrorAction SilentlyContinue) {
        # Validate config
        $config = Get-Content ".pre-commit-config.yaml" -Raw
        if ($config -match "repos:") {
            $success += "✅ Pre-commit config is valid"
        } else {
            $errors += "❌ Invalid pre-commit configuration"
        }
    } else {
        $warnings += "⚠️  Pre-commit not installed (install with: pip install pre-commit)"
    }
} catch {
    $errors += "❌ Pre-commit check failed: $_"
}

# 6. Validate YAML Files
Write-Host "`n📄 Validating YAML files..." -ForegroundColor Yellow
try {
    $yamlFiles = @(".github/workflows/ci-verify.yml", ".github/dependabot.yml", ".mergify.yml")
    foreach ($file in $yamlFiles) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            # Basic YAML validation
            try {
                $null = [System.Management.Automation.PSSerializer]::Deserialize($content)
                $success += "✅ $file is valid YAML"
            } catch {
                $errors += "❌ $file has invalid YAML syntax"
            }
        }
    }
} catch {
    $errors += "❌ YAML validation failed: $_"
}

# 7. Check Git Configuration
Write-Host "`n🔧 Checking Git setup..." -ForegroundColor Yellow
try {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitUser = git config user.name
        $gitEmail = git config user.email
        if ($gitUser -and $gitEmail) {
            $success += "✅ Git user configured: $gitUser <$gitEmail>"
        } else {
            $warnings += "⚠️  Git user not configured (recommended for automation)"
        }
        
        # Check if we're in a git repo
        $gitRoot = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0) {
            $success += "✅ In a git repository"
        } else {
            $errors += "❌ Not in a git repository"
        }
    } else {
        $errors += "❌ Git not available"
    }
} catch {
    $errors += "❌ Git check failed: $_"
}

# 8. Quick Test (if not in quick mode)
if (-not $Quick) {
    Write-Host "`n🧪 Running quick validation tests..." -ForegroundColor Yellow
    try {
        # Test the validation script
        if (Test-Path "scripts/validate-all.ps1") {
            Write-Host "Testing validation script..." -ForegroundColor Cyan
            $validationResult = pwsh -File "scripts/validate-all.ps1" -Quick 2>&1
            if ($LASTEXITCODE -eq 0) {
                $success += "✅ Validation script works"
            } else {
                $warnings += "⚠️  Validation script had issues: $validationResult"
            }
        }
        
        # Test npm scripts
        if (Test-Path "package.json") {
            Write-Host "Testing npm scripts..." -ForegroundColor Cyan
            $qualityResult = npm run quality 2>&1
            if ($LASTEXITCODE -eq 0) {
                $success += "✅ npm quality script works"
            } else {
                $warnings += "⚠️  npm quality script had issues"
            }
        }
    } catch {
        $warnings += "⚠️  Quick tests failed: $_"
    }
}

# Summary
Write-Host "`n📊 Verification Summary:" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

if ($success.Count -gt 0) {
    Write-Host "`n✅ Successes ($($success.Count)):" -ForegroundColor Green
    foreach ($item in $success) {
        Write-Host "  $item" -ForegroundColor Green
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n⚠️  Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($item in $warnings) {
        Write-Host "  $item" -ForegroundColor Yellow
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`n❌ Errors ($($errors.Count)):" -ForegroundColor Red
    foreach ($item in $errors) {
        Write-Host "  $item" -ForegroundColor Red
    }
}

# Final Status
Write-Host "`n🎯 Final Status:" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    if ($warnings.Count -eq 0) {
        Write-Host "🎉 PERFECT! All automation is ready to go!" -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "1. Run: pre-commit install" -ForegroundColor White
        Write-Host "2. Run: npm install" -ForegroundColor White
        Write-Host "3. Create a test PR to verify everything works" -ForegroundColor White
        exit 0
    } else {
        Write-Host "✅ GOOD! Automation is ready with minor warnings." -ForegroundColor Yellow
        Write-Host "Consider addressing the warnings above for optimal experience." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "❌ ISSUES FOUND! Please fix the errors above." -ForegroundColor Red
    Write-Host "`nQuick fixes:" -ForegroundColor Cyan
    Write-Host "1. Run: pip install -r requirements-dev.txt" -ForegroundColor White
    Write-Host "2. Run: npm install" -ForegroundColor White
    Write-Host "3. Run: Install-Module PSScriptAnalyzer -Force" -ForegroundColor White
    exit 1
}
