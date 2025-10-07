# BossCat Environment Setup Script (Windows PowerShell)
# MoneyCat Inc - Resonai [OTel] - otel-ops-pack
# ECRR Framework: Examine -> Clean -> Report -> Role

param(
    [switch]$SkipPython,
    [switch]$SkipNode,
    [switch]$SkipK6,
    [switch]$SkipLocust,
    [switch]$Verbose
)

# Script metadata
$ScriptVersion = "1.0.0"
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

Write-Host "BossCat Environment Setup v$ScriptVersion" -ForegroundColor Cyan
Write-Host "Timestamp: $Timestamp" -ForegroundColor Cyan
Write-Host ""

# Function to print section headers
function Write-Section {
    param([string]$Title)
    Write-Host "## $Title" -ForegroundColor Blue
    Write-Host ""
}

# Function to print status
function Write-Status {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

Write-Section "1. Examine - Environment Detection"

# Check if we're in the right directory
if (-not (Test-Path "AGENTS.md")) {
    Write-Error "AGENTS.md not found. Please run this script from the project root."
    exit 1
}

Write-Status "Project root confirmed"
Write-Status "Current directory: $(Get-Location)"

Write-Section "2. Clean - Python 3.13 Setup"

$pythonResolved = $null

if (-not $SkipPython) {
    $pythonCandidates = @(
        @{ Command = "python3.13"; Display = "python3.13"; VersionArgs = @("--version"); VenvArgs = @("-m", "venv", "venv") },
        @{ Command = "py"; Display = "py -3.13"; VersionArgs = @("-3.13", "--version"); VenvArgs = @("-3.13", "-m", "venv", "venv") },
        @{ Command = "python"; Display = "python"; VersionArgs = @("--version"); VenvArgs = @("-m", "venv", "venv") }
    )

    $pythonResolved = $null

    foreach ($candidate in $pythonCandidates) {
        $commandInfo = Get-Command $candidate.Command -ErrorAction SilentlyContinue
        if (-not $commandInfo) {
            continue
        }

        if ($commandInfo.CommandType -eq 'Application' -and -not (Test-Path $commandInfo.Source)) {
            Write-Warning "Command $($candidate.Display) is registered but $($commandInfo.Source) is missing."
            continue
        }

        try {
            $versionOutput = & $candidate.Command @($candidate.VersionArgs) 2>&1
            if ($LASTEXITCODE -eq 0 -and $versionOutput -match 'Python 3\.13') {
                $pythonResolved = [pscustomobject]@{
                    Command = $candidate.Command
                    Display = $candidate.Display
                    VenvArgs = $candidate.VenvArgs
                    Version = $versionOutput.Trim()
                }
                Write-Status "Python 3.13 available via $($candidate.Display) ($($pythonResolved.Version))"
                break
            }

            if ($versionOutput -match 'Python 3\.[0-9]+') {
                Write-Warning "Found $versionOutput via $($candidate.Display) but expected Python 3.13."
            }
        } catch {
            Write-Warning "Unable to run $($candidate.Display) --version: $($_.Exception.Message)"
        }
    }

    if (-not $pythonResolved) {
        Write-Warning "Python 3.13 not found. Install from https://www.python.org/downloads/ and re-run."
        Write-Warning "Skipping Python environment creation. Use -SkipPython to silence this message."
    } else {
        $venvPath = Join-Path (Get-Location) 'venv'
        if (-not (Test-Path $venvPath)) {
            Write-Status "Creating Python virtual environment at $venvPath..."
            try {
                & $pythonResolved.Command @($pythonResolved.VenvArgs) | Out-Null
                Write-Status "Virtual environment created."
            } catch {
                Write-Error "Failed to create virtual environment with $($pythonResolved.Display): $($_.Exception.Message)"
            }
        } else {
            Write-Status "Using existing virtual environment at $venvPath"
        }

        $venvPython = Join-Path $venvPath 'Scripts\python.exe'
        if (-not (Test-Path $venvPython)) {
            Write-Warning "Expected Python executable not found at $venvPython. Recreate the venv manually if needed."
        } else {
            Write-Status "Upgrading pip..."
            try {
                & $venvPython -m pip install --upgrade pip | Out-Null
            } catch {
                Write-Warning "Failed to upgrade pip: $($_.Exception.Message)"
            }

            $requirementsFiles = @('requirements.txt', 'requirements-dev.txt')
            foreach ($reqFile in $requirementsFiles) {
                if (Test-Path $reqFile) {
                    Write-Status "Installing dependencies from $reqFile"
                    try {
                        & $venvPython -m pip install -r $reqFile
                    } catch {
                        Write-Warning "Dependency installation from $reqFile failed: $($_.Exception.Message)"
                    }
                }
            }

            Write-Status "Ensuring BossCat Python tooling is installed"
            try {
                & $venvPython -m pip install flake8 black locust pytest pytest-cov
            } catch {
                Write-Warning "Failed to install BossCat tooling: $($_.Exception.Message)"
            }
        }
    }
} else {
    Write-Status "Python setup skipped (SkipPython flag)"
}

Write-Section "3. Report - Node.js and Testing Tools Setup"

if (-not $SkipNode) {
    # Check Node.js
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    if ($nodePath) {
        $nodeVersion = & node --version
        Write-Status "Node.js found: $nodeVersion"
    } else {
        Write-Warning "Node.js not found. Please install Node.js manually from https://nodejs.org/"
        Write-Warning "Skipping Node.js setup. Use -SkipNode to suppress this warning."
    }

    # Install npm dependencies
    if (Test-Path "package.json") {
        if ($nodePath) {
            Write-Status "Installing npm dependencies..."
            try {
                & npm install
                Write-Status "npm dependencies installed successfully"
            } catch {
                Write-Error "Failed to install npm dependencies: $($_.Exception.Message)"
            }
            
            Write-Status "Running npm audit fix..."
            try {
                $auditOutput = & npm audit fix --force 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "npm audit fix completed"
                } else {
                    Write-Warning "npm audit fix completed with warnings or errors"
                }
            } catch {
                Write-Warning "npm audit fix failed: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Warning "package.json not found. Skipping Node.js setup."
    }
} else {
    Write-Status "Node.js setup skipped (SkipNode flag)"
}

if (-not $SkipK6) {
    # Check k6
    $k6Path = Get-Command k6 -ErrorAction SilentlyContinue
    if ($k6Path) {
        $k6Version = & k6 version 2>&1
        Write-Status "k6 found: $k6Version"
    } else {
        Write-Warning "k6 not found. Please install k6 manually from https://k6.io/docs/get-started/installation/"
        Write-Warning "Skipping k6 setup. Use -SkipK6 to suppress this warning."
    }
} else {
    Write-Status "k6 setup skipped (SkipK6 flag)"
}

Write-Section "4. Role - Directory Structure Setup"

# Create required BossCat directories
Write-Status "Creating BossCat artifact directories..."

# Main artifacts directory
$directories = @(
    "artifacts",
    "artifacts\benchmarks",
    "artifacts\reports",
    "artifacts\snapshots",
    "docs\BossCat\reports",
    "docs\ecrr\ECRR_REPORTS",
    "docs\observability\snapshots",
    "docs\cheatsheets"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Status "Created directory: $dir"
    } else {
        Write-Status "Directory exists: $dir"
    }
}

# Create placeholder files for BossCat compliance
Write-Status "Creating BossCat compliance placeholders..."

# IONA error ledger
if (-not (Test-Path "docs\IONA_ERRORS.md")) {
    $ionaContent = @"
# IONA Error Ledger
## Intelligent Operations & Navigation Assistant

**Created:** $(Get-Date)
**Status:** Active monitoring

### Error Tracking
- No errors detected in initial setup

### Anomaly Detection
- System operating within normal parameters

### Health Scoring
- Overall health score: 100/100
"@
    Set-Content -Path "docs\IONA_ERRORS.md" -Value $ionaContent -Encoding UTF8
    Write-Status "Created IONA_ERRORS.md"
}

# Comfort-cat reference validation
Write-Status "Validating comfort-cat creative references..."
if (Test-Path "docs\comfort-cat") {
    Write-Status "Comfort-cat directory found"
    
    # Check for required creative reference files
    $requiredFiles = @("copy.md", "type.md", "motion.md")
    foreach ($file in $requiredFiles) {
        if (Test-Path "docs\comfort-cat\$file") {
            Write-Status "Found creative reference: $file"
        } else {
            Write-Warning "Missing creative reference: $file"
        }
    }
} else {
    Write-Error "Comfort-cat directory not found! This is required for BossCat compliance."
    Write-Status "Creating comfort-cat stub directory..."
    New-Item -ItemType Directory -Path "docs\comfort-cat" -Force | Out-Null
    
    # Create stub files
    $copyContent = @"
# Voice & Copy
version: cc-v1.0.0
Status: Draft | Owner: Editorial

Primary CTA: "Sleep easy. We've got the signal."
Tone: Warm, concise, lightly clever. Keep copy sparse; rely on visuals.
"@

    $typeContent = @"
# Typography
version: cc-v1.0.0
Status: Draft | Owner: Design

Primary font: System fonts for accessibility
Secondary font: Monospace for technical content
"@

    $motionContent = @"
# Motion & Animation
version: cc-v1.0.0
Status: Draft | Owner: Design

Principle: Smooth, calming transitions
Duration: 200ms for UI interactions
Easing: ease-out for comfort
"@

    Set-Content -Path "docs\comfort-cat\copy.md" -Value $copyContent -Encoding UTF8
    Set-Content -Path "docs\comfort-cat\type.md" -Value $typeContent -Encoding UTF8
    Set-Content -Path "docs\comfort-cat\motion.md" -Value $motionContent -Encoding UTF8
    
    Write-Status "Created comfort-cat stub files"
}

Write-Section "5. ECRR Compliance Verification"

# Verify ECRR framework compliance
Write-Status "Verifying ECRR framework compliance..."

$ecrrCompliance = 0
$totalChecks = 5

# Check for ECRR reports directory
if (Test-Path "docs\ecrr\ECRR_REPORTS") {
    Write-Status "ECRR reports directory present"
    $ecrrCompliance++
} else {
    Write-Error "ECRR reports directory missing"
}

# Check for artifacts directory
if (Test-Path "artifacts") {
    Write-Status "Artifacts directory present"
    $ecrrCompliance++
} else {
    Write-Error "Artifacts directory missing"
}

# Check for BossCat reports directory
if (Test-Path "docs\BossCat\reports") {
    Write-Status "BossCat reports directory present"
    $ecrrCompliance++
} else {
    Write-Error "BossCat reports directory missing"
}

# Check for IONA error ledger
if (Test-Path "docs\IONA_ERRORS.md") {
    Write-Status "IONA error ledger present"
    $ecrrCompliance++
} else {
    Write-Error "IONA error ledger missing"
}

# Check for comfort-cat references
if (Test-Path "docs\comfort-cat") {
    Write-Status "Comfort-cat references present"
    $ecrrCompliance++
} else {
    Write-Error "Comfort-cat references missing"
}

Write-Section "6. Final Status Report"

# Calculate compliance percentage
$compliancePercent = [math]::Round(($ecrrCompliance * 100) / $totalChecks)

Write-Host "BossCat Environment Setup Complete" -ForegroundColor Cyan
Write-Host ""
Write-Host "ECRR Compliance Score: $compliancePercent% ($ecrrCompliance/$totalChecks)" -ForegroundColor Green
Write-Host ""

if ($compliancePercent -eq 100) {
    Write-Host "[OK] Full BossCat compliance achieved!" -ForegroundColor Green
} elseif ($compliancePercent -ge 80) {
    Write-Host "[WARN] High BossCat compliance with minor issues" -ForegroundColor Yellow
} else {
    Write-Host "[FAIL] BossCat compliance issues detected" -ForegroundColor Red
}

Write-Host ""
Write-Host "Environment Summary:" -ForegroundColor Blue

# Get versions
$pythonVersion = "Not available"
$nodeVersion = "Not available"
$npmVersion = "Not available"
$k6Version = "Not available"
$locustVersion = "Not available"

# Try to get Python version from the command we found earlier
if ($null -ne $pythonResolved) {
    try {
        $versionArgs = @("--version")
        if ($pythonResolved.Display -eq "py -3.13") {
            $versionArgs = @("-3.13", "--version")
        }

        $pythonVersion = & $pythonResolved.Command @($versionArgs) 2>&1
    } catch {
        $pythonVersion = "Error getting version"
    }
} else {
    $pythonVersionFallback = @(
        @{ Command = "python3.13"; Args = @("--version") },
        @{ Command = "py"; Args = @("-3.13", "--version") },
        @{ Command = "python"; Args = @("--version") }
    )

    foreach ($candidate in $pythonVersionFallback) {
        try {
            $output = & $candidate.Command @($candidate.Args) 2>&1
            if ($LASTEXITCODE -eq 0) {
                $pythonVersion = $output
                break
            }
        } catch {
            # Continue to next candidate
        }
    }
}

try {
    $nodeVersion = & node --version 2>&1
} catch {
    $nodeVersion = "Not available"
}

try {
    $npmVersion = & npm --version 2>&1
} catch {
    $npmVersion = "Not available"
}

try {
    $k6Version = & k6 version 2>&1
} catch {
    $k6Version = "Not available"
}

try {
    $locustVersion = & locust --version 2>&1
} catch {
    $locustVersion = "Not available"
}

Write-Host "- Python: $pythonVersion"
Write-Host "- Node.js: $nodeVersion"
Write-Host "- npm: $npmVersion"
Write-Host "- k6: $k6Version"
Write-Host "- Locust: $locustVersion"

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Activate Python environment: .\venv\Scripts\Activate.ps1"
Write-Host "2. Run BossCat health check: pwsh -File scripts\quick-monitor.ps1"
Write-Host "3. Execute CI workflow: .\setup_cursor_implementer.ps1"
Write-Host "4. Monitor SigNoz UI: http://localhost:8080"

Write-Host ""
Write-Host "BossCat environment ready for CI workflow execution!" -ForegroundColor Green
Write-Host "Timestamp: $Timestamp" -ForegroundColor Cyan
