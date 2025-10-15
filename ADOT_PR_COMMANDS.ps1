# ADOT PR Staging Commands (PowerShell-Compatible)
# Run these commands step-by-step to stage the ADOT PR

# Step 1: Ensure we're on the feature branch (or create if doesn't exist)
Write-Host "`n=== Step 1: Feature Branch ===" -ForegroundColor Cyan
$branchName = "feat/adot-config-with-ci-validation"
$currentBranch = git branch --show-current
if ($currentBranch -ne $branchName) {
    git checkout $branchName 2>$null
    if ($LASTEXITCODE -ne 0) {
        git checkout -b $branchName
        Write-Host "Created new branch: $branchName" -ForegroundColor Green
    } else {
        Write-Host "Switched to existing branch: $branchName" -ForegroundColor Green
    }
} else {
    Write-Host "Already on branch: $branchName" -ForegroundColor Green
}

# Step 2: Stage ADOT files
Write-Host "`n=== Step 2: Stage Files ===" -ForegroundColor Cyan
git add .aws/
git add docs/cheatsheets/adot-setup.md
git add .github/workflows/adot-config-gate.yml
git add ADOT_PR_READY_20251015.md
git add ADOT_PR_COMMANDS.ps1
Write-Host "Staged ADOT configuration files" -ForegroundColor Green

# Step 3: Show status
Write-Host "`n=== Step 3: Status Check ===" -ForegroundColor Cyan
git status --short

# Step 4: Commit with ECRR-compliant message
Write-Host "`n=== Step 4: Commit ===" -ForegroundColor Cyan
$commitMessage = @"
feat(otel): add AWS ADOT collector config with CI validation

ECRR: Examine → Clean → Report → Role

## Examine
- Current OTel config uses OTLP receivers (4317/4318)
- SigNoz ingests via standard OTLP protocol
- 200ms batch timeout for low-latency pipeline
- ADOT supports same OTLP spec (drop-in compatible)

## Clean
- Add .aws/adot-collector-config.yaml (ADOT configuration)
- Add .aws/adot-operator-cr.yaml (EKS Operator CustomResource)
- Add docs/cheatsheets/adot-setup.md (deployment guide)
- Update .github/workflows/adot-config-gate.yml (CI validation)

## Report
- CI gate validates YAML syntax + dry-run + K8s manifests
- Deployment guide covers EKS/ECS/EC2/Local
- Migration strategy documented (Windows OTel → ADOT)
- Comprehensive troubleshooting guide included

## Role
Authority: cursor{implementer} under BossCat OEM
Gate: ADOT config validation (ci site)
Compatibility: OTLP endpoints preserved (vendor-neutral)

Key Features:
- OTLP receivers (4317/4318) — matches current setup
- SigNoz exporter via OTLP (no vendor lock-in)
- AWS exporters optional (CloudWatch, X-Ray)
- 200ms batch timeout (low-latency preserved)
- CI validation (YAML lint + dry-run + K8s check)
- Multi-platform deployment (EKS/ECS/EC2/Local)

Deployment Paths:
- EKS: ADOT Operator CustomResource
- ECS: Task definition sidecar
- EC2: Systemd service
- Local: Docker Compose

Migration: Hybrid operation supported (both collectors run simultaneously)

BossCat Compliance: ECRR + CI gate + evidence-based + GitHub Actions standards

Gate Status: READY (per IONA gate verification)
Evidence: .github/workflows/adot-config-gate.yml
"@

git commit -m $commitMessage
if ($LASTEXITCODE -eq 0) {
    Write-Host "Committed successfully" -ForegroundColor Green
} else {
    Write-Host "Commit failed or no changes to commit" -ForegroundColor Yellow
}

# Step 5: Show commit
Write-Host "`n=== Step 5: Last Commit ===" -ForegroundColor Cyan
git log --oneline -1 --decorate

# Step 6: Push to remote (optional - uncomment to execute)
Write-Host "`n=== Step 6: Push to Remote ===" -ForegroundColor Cyan
Write-Host "To push, run: git push -u origin $branchName" -ForegroundColor Yellow
# Uncomment below to auto-push:
# git push -u origin $branchName

# Step 7: Create PR via GitHub CLI (optional - uncomment to execute)
Write-Host "`n=== Step 7: Create PR ===" -ForegroundColor Cyan
Write-Host "To create PR, run:" -ForegroundColor Yellow
Write-Host "  gh pr create --title 'feat(otel): add AWS ADOT collector config with CI validation' --body-file ADOT_PR_READY_20251015.md --label feat --label otel --label ci" -ForegroundColor White
# Uncomment below to auto-create PR:
# gh pr create --title "feat(otel): add AWS ADOT collector config with CI validation" --body-file ADOT_PR_READY_20251015.md --label "feat" --label "otel" --label "ci"

Write-Host "`n=== ADOT PR Staging Complete ===" -ForegroundColor Green
Write-Host "Branch: $branchName" -ForegroundColor Cyan
Write-Host "Next: Push to remote and create PR (commands above)" -ForegroundColor Yellow

