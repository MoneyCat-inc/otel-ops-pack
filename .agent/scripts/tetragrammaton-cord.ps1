# Tetragrammaton Agent Boilerplate - CORD (Coordinator) Script
# Purpose: Review, gatekeep, and merge PRs according to CORD guidelines

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$PRNumber = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TicketId = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$ReviewPR,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunGates,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckCI,
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateSSOT
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Set-Location $repoRoot

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "✅ $msg" -ForegroundColor Green }
function Warning($msg) { Write-Host "⚠️ $msg" -ForegroundColor Yellow }
function Error($msg) { Write-Host "❌ $msg" -ForegroundColor Red }

# Load agent configuration
$configPath = ".agent/config.json"
if (-not (Test-Path $configPath)) {
    Error "Agent configuration not found at $configPath"
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

# Check for lock file
if (Test-Path ".agent/LOCK") {
    Warning ".agent/LOCK present — CORD paused. Remove the file to resume."
    exit 2
}

function Show-CORD-Status {
    Step "CORD (Coordinator) Status"
    Write-Host ""
    Write-Host "🤖 Role: CORD (Coordinator)" -ForegroundColor Blue
    Write-Host "📋 Goal: $($config.tetragrammaton.roles.CORD.goal)" -ForegroundColor Blue
    Write-Host "📝 Owns: $($($config.tetragrammaton.roles.CORD.owns) -join ', ')" -ForegroundColor Blue
    Write-Host "🚫 Never Does: $($($config.tetragrammaton.roles.CORD.neverDoes) -join ', ')" -ForegroundColor Blue
    Write-Host ""
    
    Write-Host "🛡️ Gatekeeping Responsibilities:" -ForegroundColor Yellow
    Write-Host "  ✅ CI/CD pipeline verification"
    Write-Host "  ✅ CSP/COOP/COEP header validation"
    Write-Host "  ✅ Flaky test quarantine"
    Write-Host "  ✅ SSOT generation and alignment"
    Write-Host "  ✅ Merge approvals"
    Write-Host "  ✅ Accessibility compliance (WCAG AA)"
    Write-Host ""
}

function Check-CIStatus {
    Step "Checking CI/CD Pipeline Status"
    
    # Check if we're in a git repository
    if (-not (Test-Path ".git")) {
        Warning "Not in a git repository - CI checks skipped"
        return
    }
    
    # Check for CI configuration files
    $ciFiles = @(".github/workflows", ".gitlab-ci.yml", "azure-pipelines.yml", "Jenkinsfile")
    $foundCI = $false
    
    foreach ($ciFile in $ciFiles) {
        if (Test-Path $ciFile) {
            Success "CI configuration found: $ciFile"
            $foundCI = $true
        }
    }
    
    if (-not $foundCI) {
        Warning "No CI configuration files found"
        Write-Host "  Consider adding GitHub Actions, GitLab CI, or Azure Pipelines"
    }
    
    # Check for test scripts in package.json
    if (Test-Path "package.json") {
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        $testScripts = @("test", "test:unit", "test:e2e", "test:coverage", "lint", "type-check")
        
        Write-Host ""
        Write-Host "📋 Available Test Scripts:" -ForegroundColor Yellow
        foreach ($script in $testScripts) {
            if ($packageJson.scripts.$script) {
                Success "${script}: $($packageJson.scripts.$script)"
            } else {
                Warning "${script}: Not defined"
            }
        }
    }
    
    Write-Host ""
    Write-Host "🔍 CI Status Check Complete" -ForegroundColor Yellow
}

function Validate-SSOT {
    Step "Validating Single Source of Truth (SSOT)"
    
    Write-Host ""
    Write-Host "📋 Checking SSOT Files:" -ForegroundColor Yellow
    Write-Host ""
    
    # Check for required SSOT files
    $ssotFiles = @{
        "TASKS.md" = "Main task and activity log"
        "DECISIONS.md" = "Decision log and rationale"
        ".agent/config.json" = "Agent configuration"
        ".agent/status.json" = "Agent status tracking"
    }
    
    foreach ($file in $ssotFiles.Keys) {
        if (Test-Path $file) {
            $lastModified = (Get-Item $file).LastWriteTime
            $age = (Get-Date) - $lastModified
            $ageText = if ($age.Days -gt 0) { "$($age.Days)d ago" } 
                      elseif ($age.Hours -gt 0) { "$($age.Hours)h ago" }
                      else { "$($age.Minutes)m ago" }
            
            Success "$file - $($ssotFiles[$file]) (modified $ageText)"
        } else {
            Error "$file - $($ssotFiles[$file]) (MISSING)"
        }
    }
    
    # Check for documentation consistency
    Write-Host ""
    Write-Host "📚 Documentation Consistency:" -ForegroundColor Yellow
    
    if (Test-Path "README.md") {
        Success "README.md present"
    } else {
        Warning "README.md missing"
    }
    
    if (Test-Path "docs") {
        $docFiles = Get-ChildItem -Path "docs" -Recurse -Include "*.md" | Measure-Object
        Success "docs/ directory with $($docFiles.Count) markdown files"
    } else {
        Warning "docs/ directory missing"
    }
    
    Write-Host ""
    Write-Host "🛡️ SSOT Validation Complete" -ForegroundColor Yellow
}

function Run-Gates {
    Step "Running CORD Gate Checks"
    
    Write-Host ""
    Write-Host "🚪 Running Gate Checks:" -ForegroundColor Yellow
    Write-Host ""
    
    # Gate 1: CI Status
    Write-Host "Gate 1: CI/CD Pipeline" -ForegroundColor Cyan
    Check-CIStatus
    Write-Host ""
    
    # Gate 2: SSOT Validation
    Write-Host "Gate 2: Single Source of Truth" -ForegroundColor Cyan
    Validate-SSOT
    Write-Host ""
    
    # Gate 3: Guardrail Compliance
    Write-Host "Gate 3: Guardrail Compliance" -ForegroundColor Cyan
    
    # Check CSP headers
    if (Test-Path "next.config.js") {
        $nextConfig = Get-Content "next.config.js" -Raw
        if ($nextConfig -match "Content-Security-Policy|CSP") {
            Success "CSP configuration found in next.config.js"
        } else {
            Warning "CSP configuration not found in next.config.js"
        }
    } else {
        Warning "next.config.js not found - CSP configuration unknown"
    }
    
    # Check COOP/COEP headers
    if (Test-Path "app/layout.tsx") {
        $layout = Get-Content "app/layout.tsx" -Raw
        if ($layout -match "Cross-Origin-Opener-Policy|Cross-Origin-Embedder-Policy") {
            Success "COOP/COEP headers found in layout.tsx"
        } else {
            Warning "COOP/COEP headers not found in layout.tsx"
        }
    } else {
        Warning "app/layout.tsx not found - COOP/COEP configuration unknown"
    }
    
    # Gate 4: Accessibility Compliance
    Write-Host ""
    Write-Host "Gate 4: Accessibility Compliance" -ForegroundColor Cyan
    
    # Check for accessibility test files
    $accessibilityTests = Get-ChildItem -Path "tests", "src", "app" -Recurse -Include "*accessibility*", "*a11y*" -ErrorAction SilentlyContinue
    if ($accessibilityTests.Count -gt 0) {
        Success "Accessibility test files found: $($accessibilityTests.Count)"
    } else {
        Warning "No accessibility test files found"
    }
    
    # Check for ARIA usage
    $ariaFiles = Get-ChildItem -Path "src", "app", "components" -Recurse -Include "*.tsx", "*.jsx" -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'aria-' | 
        Select-Object -ExpandProperty Filename -Unique
    
    if ($ariaFiles.Count -gt 0) {
        Success "ARIA attributes found in $($ariaFiles.Count) files"
    } else {
        Warning "No ARIA attributes detected"
    }
    
    Write-Host ""
    Write-Host "🚪 Gate Checks Complete" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 Gate Summary:" -ForegroundColor Yellow
    Write-Host "  ✅ CI/CD Pipeline: Checked"
    Write-Host "  ✅ SSOT Validation: Checked"
    Write-Host "  ✅ Guardrail Compliance: Checked"
    Write-Host "  ✅ Accessibility Compliance: Checked"
    Write-Host ""
    Write-Host "🎯 Ready for merge if all gates pass" -ForegroundColor Green
}

function Review-PR {
    if (-not $PRNumber -and -not $TicketId) {
        Error "PR Number or Ticket ID is required. Use -PRNumber or -TicketId parameter."
        exit 1
    }
    
    Step "Reviewing PR/Ticket: $($PRNumber ?? $TicketId)"
    
    # Create CORD review ticket
    $cordTicketId = if ($TicketId) { $TicketId -replace "IMPL-", "CORD-" } else { "CORD-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }
    $cordTicketPath = ".agent/tickets/$cordTicketId-review.md"
    
    $cordContent = @"
# ${cordTicketId}: Review & merge PR/Ticket

**Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**PR Number:** $PRNumber
**Parent Ticket:** $TicketId
**Status:** Under Review

## Inputs
PR from IMPL ($TicketId)

## Gatekeeping Tasks
- [ ] Verify CI pipeline passes (unit + E2E + accessibility)
- [ ] Check CSP/COOP/COEP headers in app build
- [ ] Refresh SSOT blocks if needed (`DECISIONS.md`, telemetry JSON, etc.)
- [ ] Quarantine flaky tests if present, bounce back with concrete failures
- [ ] Verify accessibility compliance (WCAG AA)
- [ ] Merge if all criteria pass

## Rollback Criteria
- CI failures not resolved within 24h
- Accessibility violations detected
- Performance budgets exceeded
- CSP/COOP/COEP header issues

## Outputs
Merged PR, updated SSOT

## Definition of Done
Main branch stays green, compliant, and artifact-aligned

## Review Notes
- Follow Tetragrammaton CORD role guidelines
- Ensure all gates pass before merge
- Document any issues found
- Update SSOT as needed

## Progress Log
- $(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): Review started
"@
    
    Set-Content -Path $cordTicketPath -Value $cordContent -Encoding UTF8
    Success "Created CORD review ticket: $cordTicketPath"
    
    Write-Host ""
    Write-Host "🎫 CORD Review Ticket Created:" -ForegroundColor Yellow
    Write-Host "  ID: $cordTicketId"
    Write-Host "  PR: $PRNumber"
    Write-Host "  Parent: $TicketId"
    Write-Host "  Path: $cordTicketPath"
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Run gate checks: -RunGates"
    Write-Host "  2. Verify CI status: -CheckCI"
    Write-Host "  3. Validate SSOT: -ValidateSSOT"
    Write-Host "  4. Review PR for compliance"
    Write-Host "  5. Merge if all gates pass"
    Write-Host "  6. Update SSOT as needed"
}

# Check switch parameters first
if ($ReviewPR) {
    Review-PR
    return
}
if ($RunGates) {
    Run-Gates
    return
}
if ($CheckCI) {
    Check-CIStatus
    return
}
if ($ValidateSSOT) {
    Validate-SSOT
    return
}

# Main execution
switch ($Action.ToLower()) {
    "status" { Show-CORD-Status }
    "review" { Review-PR }
    "gates" { Run-Gates }
    "ci" { Check-CIStatus }
    "ssot" { Validate-SSOT }
    "help" { 
        Write-Host "Tetragrammaton CORD Commands:"
        Write-Host "  status - Show CORD status and capabilities"
        Write-Host "  review - Review a PR or ticket"
        Write-Host "  gates - Run all gate checks"
        Write-Host "  ci - Check CI/CD pipeline status"
        Write-Host "  ssot - Validate Single Source of Truth"
        Write-Host "  help - Show this help message"
        Write-Host ""
        Write-Host "Parameters:"
        Write-Host "  -ReviewPR -PRNumber `"123`" - Review specific PR"
        Write-Host "  -ReviewPR -TicketId `"IMPL-XXXX`" - Review implementation ticket"
        Write-Host "  -RunGates - Run all gate checks"
        Write-Host "  -CheckCI - Check CI/CD pipeline status"
        Write-Host "  -ValidateSSOT - Validate SSOT files"
    }
    default { 
        Error "Unknown action: $Action"
        Write-Host "Use 'help' for available commands"
    }
}
