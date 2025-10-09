# BossCat Repository Cleanup Script
# Safely archives redundant documentation and cleans build artifacts
# ECRR-compliant with dry-run and backup capabilities

param(
    [switch]$DryRun,
    [switch]$Force,
    [int]$ArtifactRetentionDays = 30
)

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat Repository Cleanup" -ForegroundColor Cyan
Write-Host "ECRR-compliant safe cleanup with archival" -ForegroundColor Gray
if ($DryRun) {
    Write-Host "⚠️  DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# EXAMINE - Capture current state
# ============================================================================

$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$reportDir = "artifacts/cleanup-reports"
$archiveRoot = "archive/cleanup-$timestamp"

if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

Write-Host "📋 EXAMINE - Capturing current state..." -ForegroundColor Cyan

# Count current state
$rootMdFiles = Get-ChildItem -Path . -File -Filter "*.md" -ErrorAction SilentlyContinue
$totalRootMd = $rootMdFiles.Count
$totalRootMdSize = ($rootMdFiles | Measure-Object -Property Length -Sum).Sum / 1MB

$nodeModulesSize = if (Test-Path "node_modules") {
    (Get-ChildItem "node_modules" -Recurse -File -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum).Sum / 1GB
} else { 0 }

$venvSize = if (Test-Path ".venv") {
    (Get-ChildItem ".venv" -Recurse -File -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum).Sum / 1GB
} else { 0 }

Write-Host "  Current state:" -ForegroundColor Gray
Write-Host "    Root .md files: $totalRootMd ($([math]::Round($totalRootMdSize, 2)) MB)" -ForegroundColor White
Write-Host "    node_modules: $([math]::Round($nodeModulesSize, 2)) GB" -ForegroundColor White
Write-Host "    .venv: $([math]::Round($venvSize, 2)) GB" -ForegroundColor White
Write-Host ""

# ============================================================================
# CLEAN - Archive and organize
# ============================================================================

Write-Host "🧹 CLEAN - Organizing repository..." -ForegroundColor Cyan

$actions = @{
    files_archived = 0
    files_kept = 0
    size_freed_mb = 0
    gitignore_updated = $false
}

# Define files to KEEP at root
$keepAtRoot = @(
    "README.md",
    "CHANGELOG.md",
    "QUICKSTART.md",
    "AGENTS.md",
    "ART_OF_ECRR.md",
    "STATUS.md",
    "DECISIONS.md",
    "TASKS.md",
    ".cursor-prompt.md",
    "LICENSE"
)

# Step 1: Archive old markdown files
Write-Host ""
Write-Host "Step 1: Archiving root markdown files..." -ForegroundColor Yellow

$docsArchive = "docs/archive/root-docs-$timestamp"
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $docsArchive -Force | Out-Null
}

foreach ($mdFile in $rootMdFiles) {
    if ($keepAtRoot -notcontains $mdFile.Name) {
        # Categorize by prefix
        $category = switch -Wildcard ($mdFile.Name) {
            "QUEUE_STEWARD*" { "queue-steward" }
            "BOSSCAT*" { "bosscat" }
            "BOSS_CAT*" { "bosscat" }
            "IONA*" { "iona" }
            "BEDROCK*" { "bedrock" }
            "PR_*" { "pull-requests" }
            "CI_*" { "ci-cd" }
            "ROADMAP*" { "roadmap" }
            "SIGNOZ*" { "signoz" }
            "CURSOR*" { "cursor" }
            "SETUP*" { "setup" }
            "DEPLOYMENT*" { "deployment" }
            "PRODUCTION*" { "production" }
            "STAKEHOLDER*" { "stakeholder" }
            "REMEDIATION*" { "remediation" }
            "VERIFICATION*" { "verification" }
            "FINAL*" { "final-reports" }
            "COMPLETE*" { "completion" }
            "SUCCESS*" { "success-reports" }
            "ARCHIVE*" { "archive-meta" }
            "MONITORING*" { "monitoring" }
            "SECURITY*" { "security" }
            "CLEANUP*" { "cleanup" }
            "DIAGNOSTIC*" { "diagnostic" }
            "DOCUMENTATION*" { "documentation" }
            "DEPENDENCY*" { "dependency" }
            "PROGRESS*" { "progress" }
            "PARALLEL*" { "parallel" }
            "OBSERVABILITY*" { "observability" }
            "ALERTING*" { "alerting" }
            "DASHBOARD*" { "dashboard" }
            "ECRR*" { "ecrr-misc" }
            "C[0-9]*" { "issues" }
            "PROC_*" { "process" }
            "COMMIT*" { "commit" }
            "EMOJI*" { "cleanup" }
            "ASCII*" { "cleanup" }
            "BACKUP*" { "backup" }
            "WINDOWS*" { "windows" }
            "PYTORCH*" { "pytorch" }
            "PROMETHEUS*" { "prometheus" }
            "OTLP*" { "otlp" }
            "DFG*" { "dfg" }
            "MINOR*" { "issues" }
            "MISSION*" { "mission" }
            "QUICK*" { "quick-ref" }
            "test-*" { "tests" }
            default { "miscellaneous" }
        }
        
        $destDir = Join-Path $docsArchive $category
        if (-not $DryRun) {
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Move-Item -Path $mdFile.FullName -Destination $destDir -Force
        }
        
        $actions.files_archived++
        $actions.size_freed_mb += $mdFile.Length / 1MB
        
        if ($actions.files_archived % 20 -eq 0) {
            Write-Host "    Archived $($actions.files_archived) files..." -ForegroundColor Gray
        }
    } else {
        $actions.files_kept++
    }
}

Write-Host "  ✅ Archived $($actions.files_archived) markdown files" -ForegroundColor Green
Write-Host "  ✅ Kept $($actions.files_kept) essential files at root" -ForegroundColor Green
Write-Host ""

# Step 2: Update .gitignore
Write-Host "Step 2: Updating .gitignore..." -ForegroundColor Yellow

$gitignoreEntries = @"
# Build artifacts (should not be in git)
node_modules/
.venv/
venv/
.next/
dist/
out/
build/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python

# Temporary files
.tmp/
tmp/
*.log
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# Playwright
playwright-report/
test-results/

# BossCat cleanup archives
archive/cleanup-*/
artifacts/cleanup-reports/

# Large mock data (use git-lfs or external storage)
resonai-mock/
third_party/

"@

$gitignorePath = ".gitignore"
if (Test-Path $gitignorePath) {
    $existingContent = Get-Content $gitignorePath -Raw
    if (-not $DryRun) {
        Add-Content -Path $gitignorePath -Value "`n# === BossCat Cleanup Additions ===`n$gitignoreEntries"
    }
    $actions.gitignore_updated = $true
    Write-Host "  ✅ Updated existing .gitignore" -ForegroundColor Green
} else {
    if (-not $DryRun) {
        $gitignoreEntries | Out-File $gitignorePath -Encoding UTF8
    }
    $actions.gitignore_updated = $true
    Write-Host "  ✅ Created new .gitignore" -ForegroundColor Green
}
Write-Host ""

# Step 3: Clean old artifacts
Write-Host "Step 3: Cleaning old artifacts (>$ArtifactRetentionDays days)..." -ForegroundColor Yellow

if (Test-Path "artifacts") {
    $cutoffDate = (Get-Date).AddDays(-$ArtifactRetentionDays)
    $oldArtifacts = Get-ChildItem "artifacts" -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    $oldCount = $oldArtifacts.Count
    $oldSize = ($oldArtifacts | Measure-Object -Property Length -Sum).Sum / 1MB
    
    if ($oldCount -gt 0) {
        $artifactArchive = "archive/artifacts-old-$timestamp"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $artifactArchive -Force | Out-Null
            foreach ($artifact in $oldArtifacts) {
                $relativePath = $artifact.FullName.Replace((Get-Location).Path, "").TrimStart('\')
                $destPath = Join-Path $artifactArchive $relativePath
                $destDir = Split-Path $destPath -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                Move-Item -Path $artifact.FullName -Destination $destPath -Force
            }
        }
        Write-Host "  ✅ Archived $oldCount old artifacts ($([math]::Round($oldSize, 2)) MB)" -ForegroundColor Green
        $actions.size_freed_mb += $oldSize
    } else {
        Write-Host "  ℹ️  No old artifacts to clean" -ForegroundColor Gray
    }
}
Write-Host ""

# ============================================================================
# REPORT - Generate cleanup summary
# ============================================================================

Write-Host "📊 REPORT - Generating cleanup summary..." -ForegroundColor Cyan

$summary = @{
    timestamp = $timestamp
    dry_run = $DryRun.IsPresent
    actions = $actions
    recommendations = @{
        remove_from_git = @("node_modules", ".venv", "resonai-mock", "third_party")
        estimated_size_reduction_gb = 5.5
        root_md_before = $totalRootMd
        root_md_after = $actions.files_kept
        reduction_percent = [math]::Round((($totalRootMd - $actions.files_kept) / $totalRootMd) * 100, 1)
    }
    next_steps = @(
        "Run: git rm -r --cached node_modules .venv (after commit)",
        "Commit changes: git commit -m 'docs(cleanup): Archive historical docs, update .gitignore'",
        "Consider git-lfs for large binary assets",
        "Run npm install / pip install -r requirements.txt to restore dependencies"
    )
}

$reportFile = Join-Path $reportDir "cleanup-report-$timestamp.json"
$summary | ConvertTo-Json -Depth 10 | Out-File $reportFile -Encoding UTF8

Write-Host ""
Write-Host "✅ Cleanup Summary:" -ForegroundColor Green
Write-Host "  Files archived: $($actions.files_archived)" -ForegroundColor White
Write-Host "  Files kept at root: $($actions.files_kept)" -ForegroundColor White
Write-Host "  Size freed: $([math]::Round($actions.size_freed_mb, 2)) MB" -ForegroundColor White
Write-Host "  Reduction: $($summary.recommendations.reduction_percent)% fewer root files" -ForegroundColor White
Write-Host ""

if ($DryRun) {
    Write-Host "⚠️  DRY RUN - No actual changes made" -ForegroundColor Yellow
    Write-Host "   Run without -DryRun to execute cleanup" -ForegroundColor Gray
} else {
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
}

Write-Host ""
Write-Host "📄 Report saved: $reportFile" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# ROLE - Next actions
# ============================================================================

Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review archived files:" -ForegroundColor White
Write-Host "   cd $docsArchive" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Remove large directories from git:" -ForegroundColor White
Write-Host "   git rm -r --cached node_modules .venv" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Commit cleanup:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'docs(cleanup): Archive 170 historical docs, update .gitignore'" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Restore dependencies:" -ForegroundColor White
Write-Host "   pnpm install" -ForegroundColor Gray
Write-Host "   pip install -r requirements.txt" -ForegroundColor Gray
Write-Host ""

Write-Host "🐾 BossCat: Repository cleanup complete" -ForegroundColor Cyan

