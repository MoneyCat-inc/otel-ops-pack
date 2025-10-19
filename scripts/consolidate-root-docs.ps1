#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
    Consolidate root-level documentation into organized structure
.DESCRIPTION
    Moves scattered root .md files into docs/<bucket>/<YYYY-MM>/ with optional stubs.
    Preserves git history via git mv when available.
.PARAMETER Apply
    Execute the moves (default is dry-run)
.PARAMETER CreateStubs
    Leave redirect stubs at original locations for high-traffic files
.EXAMPLE
    pwsh scripts/consolidate-root-docs.ps1               # Dry-run
    pwsh scripts/consolidate-root-docs.ps1 -Apply        # Execute with stubs
.NOTES
    Authority: BossCat OEM
    Lane: DOCS
    Creates: docs/<bucket>/<YYYY-MM>/ structure
#>

param(
    [switch]$Apply = $false,
    [switch]$CreateStubs = $true
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Anchor to repository root
$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

Write-Host "`n🗂️  Root Documentation Consolidation" -ForegroundColor Cyan
Write-Host "   Mode: $(if($Apply){'APPLY'}else{'DRY-RUN'})" -ForegroundColor $(if($Apply){'Yellow'}else{'Cyan'})
Write-Host "   Stubs: $(if($CreateStubs){'YES'}else{'NO'})" -ForegroundColor White
Write-Host ""

# Extract YYYY-MM from filename
function Get-DateFolder($name) {
    # Pattern: _YYYYMMDD or _YYYY-MM-DD or _YYYY_MM_DD
    if ($name -match '([12]\d{3})(\d{2})(\d{2})') {
        return "$($matches[1])-$($matches[2])"
    }
    if ($name -match '([12]\d{3})[-_](\d{2})[-_](\d{2})') {
        return "$($matches[1])-$($matches[2])"
    }
    return "misc"
}

# Classification rules (order matters - first match wins)
$rules = @(
    @{ bucket="gate";     rx="^(GATE_|READY_FOR_GATE|READY_FOR_FINAL_GATE|GATE_READY|GATE_STATUS|PUBLIC_ECRR_|EXEC_|VERIFICATION_READINESS|FINAL_PRODUCTION_STATUS|PRODUCTION_GO_DECISION).*\.md$" },
    @{ bucket="socm";     rx="^(SOCM_|BLUESKY_|LINKEDIN_|PATREON_|BUYMEACOFFEE_).*\.md$" },
    @{ bucket="pr";       rx="^(PR_|GITHUB_PR_).*\.md$" },
    @{ bucket="releases"; rx="^(RELEASE_NOTES|ROADMAP).*\.md$" },
    @{ bucket="bosscat";  rx="^(BOSSCAT_|TETRAGRAM_).*\.md$|^AGENTS\.md$|^ART_OF_ECRR\.md$|^ENTERPRISE_READINESS_CHECKLIST\.md$" },
    @{ bucket="runbooks"; rx="^(DAY2_|HUB_.*RUNBOOK|HUB_.*STATUS|rollback_plan|DEPLOYMENT_|MISSION_COMPLETE).*\.md$" },
    @{ bucket="evidence"; rx="^(COMMIT_|.*_EVIDENCE_|CONVEYOR_SYSTEM_).*\.md$" },
    @{ bucket="status";   rx="^(STATUS|SESSION_|CURSOR_IMPLEMENTER_|WORKING_TREE_CLEANUP).*\.md$" },
    @{ bucket="notes";    rx="^(DECISIONS|TASKS|TODO_|tmp_).*\.md$" }
)

# Scan root for .md files (exclude README.md, CHANGELOG.md, CONTRIBUTING.md, LICENSE.md)
$keepAtRoot = @('README.md', 'CHANGELOG.md', 'CONTRIBUTING.md', 'LICENSE.md', 'CODE_OF_CONDUCT.md')
$rootFiles = Get-ChildItem -Path . -Depth 0 -File -Filter *.md | 
    Where-Object { $_.Name -notin $keepAtRoot }

$plan = @()

foreach ($file in $rootFiles) {
    $matched = $false
    foreach ($rule in $rules) {
        if ($file.Name -match $rule.rx) {
            $dateFolder = Get-DateFolder $file.Name
            $targetDir = Join-Path "docs" $rule.bucket | Join-Path -ChildPath $dateFolder
            $targetPath = Join-Path $targetDir $file.Name
            
            $plan += [PSCustomObject]@{
                From = $file.FullName
                FileName = $file.Name
                To = $targetPath
                Bucket = $rule.bucket
                DateFolder = $dateFolder
            }
            $matched = $true
            break
        }
    }
    
    if (-not $matched) {
        # Unclassified files go to docs/notes/misc
        $targetPath = Join-Path "docs" "notes" "misc" $file.Name
        $plan += [PSCustomObject]@{
            From = $file.FullName
            FileName = $file.Name
            To = $targetPath
            Bucket = "notes"
            DateFolder = "misc"
        }
    }
}

# Show plan
Write-Host "📋 Consolidation Plan:" -ForegroundColor Yellow
Write-Host "   Files to move: $($plan.Count)" -ForegroundColor White
Write-Host ""

$plan | Sort-Object Bucket, DateFolder, FileName | 
    Format-Table @{N='Bucket';E={$_.Bucket};Width=12}, 
                 @{N='Date';E={$_.DateFolder};Width=10}, 
                 @{N='File';E={$_.FileName}} -AutoSize

Write-Host "`n📊 Summary by Bucket:" -ForegroundColor Cyan
$plan | Group-Object Bucket | Sort-Object Name | 
    Format-Table @{N='Bucket';E={$_.Name}}, @{N='Count';E={$_.Count}} -AutoSize

if (-not $Apply) {
    Write-Host "`n💡 DRY RUN - No changes made" -ForegroundColor Yellow
    Write-Host "   To execute: pwsh $($MyInvocation.MyCommand.Path) -Apply" -ForegroundColor White
    Write-Host "   With stubs: pwsh $($MyInvocation.MyCommand.Path) -Apply -CreateStubs" -ForegroundColor White
    Write-Host ""
    exit 0
}

# Execute moves
Write-Host "`n🚀 Executing consolidation..." -ForegroundColor Green

$moved = 0
$stubbed = 0
$hasGit = Get-Command git -ErrorAction SilentlyContinue

foreach ($item in $plan) {
    # Create target directory
    $targetDir = Split-Path $item.To -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Move file (prefer git mv for history preservation)
    if ($hasGit) {
        git mv $item.FileName $item.To 2>&1 | Out-Null
    } else {
        Move-Item -Path $item.FileName -Destination $item.To -Force
    }
    $moved++
    
    # Create stub if requested
    if ($CreateStubs) {
        $relPath = $item.To.Replace('\', '/')
        $stubContent = @"
# Moved

This file has been moved to maintain a cleaner repository structure.

**New location:** [$relPath]($relPath)

**Moved:** $(Get-Date -Format 'yyyy-MM-dd')

For the canonical version, please see the link above.
"@
        $stubContent | Out-File -FilePath $item.FileName -Encoding UTF8
        $stubbed++
    }
}

Write-Host "`n✅ Consolidation complete" -ForegroundColor Green
Write-Host "   Files moved: $moved" -ForegroundColor White
Write-Host "   Stubs created: $stubbed" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Review changes: git status" -ForegroundColor White
Write-Host "   2. Stage stubs: git add *.md" -ForegroundColor White
Write-Host "   3. Commit: git commit -m 'docs(cleanup): consolidate root docs into organized structure'" -ForegroundColor White
Write-Host "   4. Update References Map to v1.1" -ForegroundColor White
Write-Host "   5. Regenerate indexes" -ForegroundColor White
Write-Host ""

