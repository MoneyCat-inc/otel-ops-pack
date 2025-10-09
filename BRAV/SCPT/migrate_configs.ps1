# Phase B.2: Migrate configs/assets/infra → DELT & BRAV
# BossCat OEM - Tetragram Migration Kit

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat Phase B.2: Configs/Assets/Infra Migration" -ForegroundColor Magenta
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host ""

# Find repo root
try {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $RepoRoot) { $RepoRoot = Get-Location }
} catch {
    $RepoRoot = Get-Location
}

Set-Location $RepoRoot

# Create target directories
New-Item -ItemType Directory -Path "DELT\CONF", "DELT\ASST", "DELT\FIXT", "DELT\TMPL" -Force | Out-Null
New-Item -ItemType Directory -Path "BRAV\INFR\legacy", "BRAV\DOCK\legacy" -Force | Out-Null
New-Item -ItemType Directory -Path "CHAR\EVID" -Force | Out-Null

$movedCount = 0

# Function to migrate with junction
function Migrate-Directory {
    param(
        [string]$Source,
        [string]$Destination,
        [bool]$CreateShim = $true
    )
    
    if (-not (Test-Path $Source)) {
        return
    }
    
    $item = Get-Item $Source -ErrorAction SilentlyContinue
    if ($item.LinkType -eq "Junction" -or $item.Attributes -match "ReparsePoint") {
        return
    }
    
    Write-Host "📦 Migrating: $Source → $Destination" -ForegroundColor Cyan
    
    # Move the directory
    Move-Item $Source $Destination -Force
    $script:movedCount++
    
    # Create junction shim if requested
    if ($CreateShim) {
        try {
            cmd /c mklink /J "$Source" "$Destination" | Out-Null
            Write-Host "  🔗 Created junction: $Source → $Destination" -ForegroundColor Gray
        } catch {
            Write-Host "  ⚠️  Could not create junction (may need admin rights)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "  ✅ Migrated successfully" -ForegroundColor Green
    Write-Host ""
}

# Migrate configurations
Migrate-Directory "config" "DELT\CONF\config"
Migrate-Directory "configs" "DELT\CONF\configs"

# Migrate Docker infrastructure
Migrate-Directory "docker" "BRAV\DOCK\legacy"

# Migrate Helm and deployment pipelines
Migrate-Directory "helm" "BRAV\INFR\helm"
Migrate-Directory "deployment-pipeline" "BRAV\INFR\deployment-pipeline"

# Migrate evidence/reports
Migrate-Directory "artifacts" "CHAR\EVID\artifacts"
Migrate-Directory "reports" "CHAR\EVID\reports"
Migrate-Directory "playwright-report" "CHAR\EVID\playwright-report"

# Migrate test assets and fixtures
Migrate-Directory "assets" "DELT\ASST\assets"
Migrate-Directory "baseline" "DELT\FIXT\baseline"
Migrate-Directory "test-payloads" "DELT\FIXT\test-payloads"

# Migrate templates
Migrate-Directory "templates" "DELT\TMPL\templates"

Write-Host "✅ Phase B.2 complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary: Migrated $movedCount directories" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review changes: git status" -ForegroundColor White
Write-Host "  2. Update workflow paths if needed" -ForegroundColor White
Write-Host "  3. Test CI/CD pipelines" -ForegroundColor White
Write-Host "  4. Commit: git add -A; git commit -m 'chore(repo): move configs/infra/assets to DELT/BRAV'" -ForegroundColor White
Write-Host "  5. After 2 green cycles, remove junctions: .\BRAV\SCPT\cleanup_shims.ps1" -ForegroundColor White
Write-Host ""

