# OTel Observability Kit - Local Development Bootstrap
# Ensures Node.js 20.x, pnpm 9+, Python 3.11+, VS Build Tools, and project deps
# Run in elevated PowerShell on Windows 11

param(
    [switch]$SkipNativeModules,
    [switch]$ForceReinstall,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Color output for better UX
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-ColorOutput "==> [$Step] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" "Red"
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-ColorOutput "🚀 OTel Observability Kit - Local Development Bootstrap" "Magenta"
Write-ColorOutput "=====================================================" "Magenta"

if (-not (Test-Administrator)) {
    Write-Warning "This script works best when run as Administrator for tool installation."
    Write-ColorOutput "Consider running PowerShell as Administrator for optimal results." "Yellow"
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

# Step 1: Node.js & pnpm validation
Write-Step "1/8" "Validating Node.js 20.x and pnpm 9+"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "Node.js not found. Please install Node.js 20.x from https://nodejs.org/"
    Write-ColorOutput "Or use: winget install OpenJS.NodeJS" "Yellow"
    exit 1
}

$nodeVer = (node -v).TrimStart("v")
Write-ColorOutput "Found Node.js version: $nodeVer" "White"

if ([version]$nodeVer -lt [version]"20.0.0") {
    Write-Error "Node.js $nodeVer is too old. Please install Node.js 20.x or later."
    exit 1
}

Write-Success "Node.js version OK"

# Enable corepack and ensure pnpm
Write-ColorOutput "Enabling corepack for pnpm management..." "White"
try {
    corepack enable
    corepack prepare pnpm@latest --activate
    $pnpmVer = pnpm -v
    Write-Success "pnpm version: $pnpmVer"
} catch {
    Write-Error "Failed to setup pnpm via corepack: $_"
    exit 1
}

# Step 2: Python 3.11+ for native modules
Write-Step "2/8" "Ensuring Python 3.11+ for native module builds"

$pythonOk = $false
if (Get-Command py -ErrorAction SilentlyContinue) {
    try {
        $pyVer = & py -3 --version 2>&1
        Write-ColorOutput "Found Python: $pyVer" "White"
        if ($pyVer -match "Python (\d+\.\d+)") {
            $version = [version]$matches[1]
            if ($version -ge [version]"3.11.0") {
                $pythonOk = $true
                Write-Success "Python version OK"
            }
        }
    } catch {
        Write-Warning "Python check failed: $_"
    }
}

if (-not $pythonOk) {
    Write-ColorOutput "Installing Python 3.11+ via winget..." "Yellow"
    try {
        winget install -e --id Python.Python.3.11 -h | Out-Null
        Write-Success "Python installation completed"
        $pythonOk = $true
    } catch {
        Write-Error "Failed to install Python: $_"
        Write-ColorOutput "Please install Python 3.11+ manually from https://python.org/" "Yellow"
    }
}

if ($pythonOk) {
    npm config set python "py -3"
    Write-Success "npm configured to use Python 3"
}

# Step 3: Visual Studio Build Tools for native modules
Write-Step "3/8" "Ensuring Visual Studio 2022 Build Tools (C++ toolset)"

if (-not $SkipNativeModules) {
    try {
        # Check if build tools are already available
        $buildToolsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (Test-Path $buildToolsPath) {
            $installed = & $buildToolsPath -products "*" -requires "Microsoft.VisualStudio.Component.VC.Tools.x86.x64" -property installationPath
            if ($installed) {
                Write-Success "Visual Studio Build Tools already installed"
            } else {
                throw "Build tools not found"
            }
        } else {
            throw "VS Installer not found"
        }
    } catch {
        Write-ColorOutput "Installing Visual Studio 2022 Build Tools..." "Yellow"
        try {
            winget install -e --id Microsoft.VisualStudio.2022.BuildTools `
                --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64" -h
            Write-Success "Visual Studio Build Tools installation completed"
        } catch {
            Write-Warning "Failed to install VS Build Tools automatically: $_"
            Write-ColorOutput "You may need to install manually from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022" "Yellow"
            Write-ColorOutput "Make sure to include 'C++ build tools' workload." "Yellow"
        }
    }
} else {
    Write-Warning "Skipping native module build tools (--SkipNativeModules flag)"
}

# Step 4: Clean workspace
Write-Step "4/8" "Cleaning workspace and caches"

if ($ForceReinstall -or (Test-Path "node_modules")) {
    Write-ColorOutput "Removing existing node_modules..." "Yellow"
    Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
}

Write-ColorOutput "Pruning pnpm store..." "White"
try {
    pnpm store prune | Out-Null
    Write-Success "pnpm store cleaned"
} catch {
    Write-Warning "pnpm store prune failed: $_"
}

# Step 5: Install dependencies
Write-Step "5/8" "Installing project dependencies"

Write-ColorOutput "Installing dependencies with pnpm..." "White"
try {
    if ($ForceReinstall) {
        pnpm install
    } else {
        pnpm install --frozen-lockfile
    }
    Write-Success "Dependencies installed successfully"
} catch {
    Write-Error "Dependency installation failed: $_"
    Write-ColorOutput "This might be due to native module build issues." "Yellow"
    Write-ColorOutput "Consider using --SkipNativeModules flag or check Python/Build Tools setup." "Yellow"
    exit 1
}

# Step 6: Rebuild native modules (if not skipped)
if (-not $SkipNativeModules) {
    Write-Step "6/8" "Rebuilding native modules"
    
    Write-ColorOutput "Rebuilding native modules..." "White"
    try {
        pnpm rebuild
        Write-Success "Native modules rebuilt successfully"
    } catch {
        Write-Warning "Native module rebuild failed: $_"
        Write-ColorOutput "Some native modules may not work correctly." "Yellow"
        Write-ColorOutput "You can continue with --SkipNativeModules or fix the build environment." "Yellow"
    }
} else {
    Write-ColorOutput "Skipping native module rebuild (--SkipNativeModules flag)" "Yellow"
}

# Step 7: Install Playwright browsers
Write-Step "7/8" "Installing Playwright browsers"

Write-ColorOutput "Installing Playwright browsers with dependencies..." "White"
try {
    pnpm exec playwright install --with-deps
    Write-Success "Playwright browsers installed successfully"
} catch {
    Write-Warning "Playwright browser installation failed: $_"
    Write-ColorOutput "You may need to install browsers manually later for testing." "Yellow"
}

# Step 8: Verification tests
Write-Step "8/8" "Running verification tests"

# Test better-sqlite3
Write-ColorOutput "Testing better-sqlite3 module..." "White"
try {
    $result = node -e "require('better-sqlite3'); console.log('better-sqlite3 OK')" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "better-sqlite3 loads successfully"
    } else {
        Write-Warning "better-sqlite3 test failed: $result"
        Write-ColorOutput "Native modules may have issues. Consider --SkipNativeModules flag." "Yellow"
    }
} catch {
    Write-Warning "better-sqlite3 test failed: $_"
}

# Test basic package.json scripts
Write-ColorOutput "Running basic script verification..." "White"

$scriptsToTest = @("lint", "build", "test")
foreach ($script in $scriptsToTest) {
    if ((Get-Content package.json | ConvertFrom-Json).scripts.$script) {
        try {
            Write-ColorOutput "  Testing pnpm run $script..." "White"
            pnpm run $script --if-present 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "  $script script passed"
            } else {
                Write-Warning "  $script script had issues (exit code: $LASTEXITCODE)"
            }
        } catch {
            Write-Warning "  $script script failed: $_"
        }
    }
}

# Final status
Write-ColorOutput "" "White"
Write-ColorOutput "🎉 Bootstrap completed!" "Green"
Write-ColorOutput "===================" "Green"

Write-ColorOutput "Next steps:" "White"
Write-ColorOutput "1. Remove the .agent/LOCK file to resume agent processing" "White"
Write-ColorOutput "2. Run 'pnpm dev' to start the development server" "White"
Write-ColorOutput "3. Check SigNoz UI at http://localhost:8080" "White"

if ($SkipNativeModules) {
    Write-ColorOutput "" "White"
    Write-ColorOutput "⚠️  Note: You used --SkipNativeModules flag" "Yellow"
    Write-ColorOutput "   Some features may not work. To enable:" "Yellow"
    Write-ColorOutput "   1. Fix Python/Build Tools setup" "Yellow"
    Write-ColorOutput "   2. Run: pwsh scripts/setup-local.ps1 -ForceReinstall" "Yellow"
}

Write-ColorOutput "" "White"
Write-ColorOutput "For troubleshooting native modules:" "White"
Write-ColorOutput "- Ensure Python 3.11+ is in PATH: 'py -3 --version'" "White"
Write-ColorOutput "- Ensure VS Build Tools are installed with C++ workload" "White"
Write-ColorOutput "- Try: npm config set python 'py -3'" "White"
Write-ColorOutput "- Use --SkipNativeModules flag to continue without native modules" "White"
