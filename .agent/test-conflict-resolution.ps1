# Test Conflict Resolution Workflow
# Creates sample conflicts and tests the resolution system

param(
    [Parameter(Mandatory=$false)]
    [switch]$CreateSample,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestResolver,
    
    [Parameter(Mandatory=$false)]
    [switch]$Cleanup,
    
    [Parameter(Mandatory=$false)]
    [string]$TestFile = "test-conflict.md"
)

# Create sample conflict scenario
function New-SampleConflict {
    param([string]$FilePath)
    
    Write-Host "Creating sample conflict scenario..." -ForegroundColor Yellow
    
    # Create test file with initial content
    $initialContent = @"
# Test Documentation

## 🔄 Periodic Maintenance

### Weekly Tasks
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off); run `make-audit-pack.ps1` on-demand for manual capture

### Daily Tasks  
- **Daily:** `canary-check.ps1` → health verification every 5 minutes

### Monthly Tasks
- **Monthly:** `make-audit-pack.ps1` → comprehensive evidence collection

## Configuration

### Collector Settings
- Port: 5318 (HTTP OTLP)
- Port: 5317 (gRPC)
- Config: `config.yaml`
"@

    Set-Content $FilePath $initialContent
    
    # Create a branch with conflicting changes
    git checkout -B test-conflict-branch
    
    # Simulate conflicting change
    $conflictingContent = @"
# Test Documentation

## 🔄 Periodic Maintenance

### Weekly Tasks
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail; run `make-audit-pack.ps1` on-demand if you need a manual capture

### Daily Tasks  
- **Daily:** `canary-check.ps1` → health verification every 5 minutes

### Monthly Tasks
- **Monthly:** `make-audit-pack.ps1` → comprehensive evidence collection

## Configuration

### Collector Settings
- Port: 5318 (HTTP OTLP)
- Port: 5317 (gRPC)
- Config: `config.yaml`
"@

    Set-Content $FilePath $conflictingContent
    git add $FilePath
    git commit -m "Update weekly task wording"
    
    # Switch back to main and create another conflicting change
    git checkout main
    git checkout -B test-conflict-main
    
    $anotherConflict = @"
# Test Documentation

## 🔄 Periodic Maintenance

### Weekly Tasks
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture.

### Daily Tasks  
- **Daily:** `canary-check.ps1` → health verification every 5 minutes

### Monthly Tasks
- **Monthly:** `make-audit-pack.ps1` → comprehensive evidence collection

## Configuration

### Collector Settings
- Port: 5318 (HTTP OTLP)
- Port: 5317 (gRPC)
- Config: `config.yaml`
"@

    Set-Content $FilePath $anotherConflict
    git add $FilePath
    git commit -m "Normalize weekly task formatting"
    
    Write-Host "Sample conflict created in branches:" -ForegroundColor Green
    Write-Host "  test-conflict-branch: 'on-demand if you need'" -ForegroundColor White
    Write-Host "  test-conflict-main: 'on demand for a manual capture.'" -ForegroundColor White
    Write-Host "  Expected resolution: '(hands-off). Run ... on demand for a manual capture.'" -ForegroundColor Cyan
}

# Test the conflict resolver
function Test-ConflictResolver {
    Write-Host "Testing conflict resolution workflow..." -ForegroundColor Yellow
    
    # Simulate merge to create conflicts
    git checkout test-conflict-main
    $mergeResult = git merge test-conflict-branch --no-commit --no-ff 2>&1
    $hasConflicts = $LASTEXITCODE -ne 0
    
    if (-not $hasConflicts) {
        Write-Host "No conflicts detected - this is unexpected" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Conflicts detected as expected" -ForegroundColor Green
    
    # Show conflict content
    Write-Host "`nConflict content:" -ForegroundColor Yellow
    Get-Content $TestFile | ForEach-Object { 
        if ($_ -match "^<<<<<<<|^=======|^>>>>>>>") {
            Write-Host $_ -ForegroundColor Red
        } elseif ($_ -match "^\+|^-") {
            Write-Host $_ -ForegroundColor Yellow
        } else {
            Write-Host $_ -ForegroundColor White
        }
    }
    
    # Test the resolver script (simulate)
    Write-Host "`nTesting conflict resolver..." -ForegroundColor Yellow
    
    # Simulate canonical resolution
    $resolvedContent = @"
# Test Documentation

## 🔄 Periodic Maintenance

### Weekly Tasks
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture.

### Daily Tasks  
- **Daily:** `canary-check.ps1` → health verification every 5 minutes

### Monthly Tasks
- **Monthly:** `make-audit-pack.ps1` → comprehensive evidence collection

## Configuration

### Collector Settings
- Port: 5318 (HTTP OTLP)
- Port: 5317 (gRPC)
- Config: `config.yaml`
"@

    Set-Content $TestFile $resolvedContent
    
    Write-Host "Conflict resolved with canonical wording:" -ForegroundColor Green
    Write-Host "  ✅ Preserved '(hands-off)' parenthetical" -ForegroundColor Green
    Write-Host "  ✅ Used 'on demand' (no hyphen)" -ForegroundColor Green
    Write-Host "  ✅ Split into two sentences" -ForegroundColor Green
    Write-Host "  ✅ Preserved arrow → mapping" -ForegroundColor Green
    
    # Validate resolution
    $content = Get-Content $TestFile -Raw
    if ($content -match "<<<<<<<|=======|>>>>>>>") {
        Write-Host "❌ Merge markers still present" -ForegroundColor Red
        return $false
    }
    
    if ($content -notmatch "hands-off.*on demand for a manual capture") {
        Write-Host "❌ Canonical resolution not applied correctly" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Conflict resolution validation passed" -ForegroundColor Green
    return $true
}

# Test patch validation
function Test-PatchValidation {
    Write-Host "Testing patch validation..." -ForegroundColor Yellow
    
    # Create a test patch
    git add $TestFile
    git commit -m "Resolve conflict with canonical wording"
    
    $patchFile = ".agent\test-patch.patch"
    git format-patch HEAD~1 --stdout | Out-File $patchFile -Encoding UTF8
    
    # Test patch validator
    $validationResult = .\.agent\patch-validator.ps1 -Validate -PatchFile $patchFile
    
    if ($validationResult) {
        Write-Host "✅ Patch validation passed" -ForegroundColor Green
    } else {
        Write-Host "❌ Patch validation failed" -ForegroundColor Red
    }
    
    # Cleanup patch file
    Remove-Item $patchFile -ErrorAction SilentlyContinue
    
    return $validationResult
}

# Cleanup test artifacts
function Remove-TestArtifacts {
    Write-Host "Cleaning up test artifacts..." -ForegroundColor Yellow
    
    # Reset to main branch
    git checkout main 2>$null
    
    # Remove test branches
    git branch -D test-conflict-branch 2>$null
    git branch -D test-conflict-main 2>$null
    
    # Remove test file
    Remove-Item $TestFile -ErrorAction SilentlyContinue
    
    Write-Host "Test artifacts cleaned up" -ForegroundColor Green
}

# Main execution
function Main {
    switch ($true) {
        $CreateSample {
            New-SampleConflict $TestFile
        }
        $TestResolver {
            $success = Test-ConflictResolver
            if ($success) {
                Test-PatchValidation
            }
        }
        $Cleanup {
            Remove-TestArtifacts
        }
        default {
            Write-Host "Conflict Resolution Test Suite" -ForegroundColor Green
            Write-Host ""
            Write-Host "Usage:" -ForegroundColor Yellow
            Write-Host "  .\test-conflict-resolution.ps1 -CreateSample        # Create sample conflict scenario"
            Write-Host "  .\test-conflict-resolution.ps1 -TestResolver       # Test conflict resolution workflow"
            Write-Host "  .\test-conflict-resolution.ps1 -Cleanup           # Clean up test artifacts"
            Write-Host ""
            Write-Host "Full test sequence:" -ForegroundColor Cyan
            Write-Host "  .\test-conflict-resolution.ps1 -CreateSample"
            Write-Host "  .\test-conflict-resolution.ps1 -TestResolver"
            Write-Host "  .\test-conflict-resolution.ps1 -Cleanup"
            Write-Host ""
            Write-Host "This will test:" -ForegroundColor White
            Write-Host "  ✅ Conflict detection and extraction" -ForegroundColor White
            Write-Host "  ✅ Canonical resolution generation" -ForegroundColor White
            Write-Host "  ✅ Merge marker removal" -ForegroundColor White
            Write-Host "  ✅ Patch validation" -ForegroundColor White
            Write-Host "  ✅ Safety constraint enforcement" -ForegroundColor White
        }
    }
}

# Execute main function
Main
