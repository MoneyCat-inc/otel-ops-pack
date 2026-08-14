# Concurrency and Queue Validation Script
# Monitors CI runs for cancellation and Mergify queue behavior

Write-Host "🔍 Concurrency and Queue Validation" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check for recent CI runs to see concurrency behavior
Write-Host "`n1. Checking recent CI runs for concurrency behavior..." -ForegroundColor Yellow

try {
    $runs = gh run list --limit 5 --json databaseId,status,conclusion,displayTitle,createdAt | ConvertFrom-Json
    if ($runs) {
        Write-Host "Recent runs:" -ForegroundColor Cyan
        $runs | ForEach-Object {
            $status = switch ($_.status) {
                "completed" { $_.conclusion }
                "in_progress" { "RUNNING" }
                "queued" { "QUEUED" }
                "cancelled" { "CANCELLED" }
                default { $_.status.ToUpper() }
            }
            Write-Host "  $($_.databaseId) | $status | $($_.displayTitle)" -ForegroundColor White
        }
        
        # Look for cancelled runs (concurrency working)
        $cancelledRuns = $runs | Where-Object { $_.conclusion -eq "cancelled" }
        if ($cancelledRuns) {
            Write-Host "`n✅ Found cancelled runs - concurrency is working!" -ForegroundColor Green
            $cancelledRuns | ForEach-Object {
                Write-Host "  Cancelled: $($_.databaseId) - $($_.displayTitle)" -ForegroundColor Green
            }
        } else {
            Write-Host "`n⚠️  No cancelled runs found yet - concurrency may not be triggered" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "❌ Error checking CI runs: $($_.Exception.Message)" -ForegroundColor Red
}

# Check for open PRs to see queue behavior
Write-Host "`n2. Checking for open PRs and queue behavior..." -ForegroundColor Yellow

try {
    $prs = gh pr list --json number,title,state,author,headRefName | ConvertFrom-Json
    if ($prs) {
        Write-Host "Open PRs:" -ForegroundColor Cyan
        $prs | ForEach-Object {
            Write-Host "  PR #$($_.number) | $($_.state.ToUpper()) | $($_.title)" -ForegroundColor White
            Write-Host "    Author: $($_.author.login) | Branch: $($_.headRefName)" -ForegroundColor Gray
        }
        
        # Check if our test PR is there
        $testPR = $prs | Where-Object { $_.headRefName -eq "test-queue-behavior" }
        if ($testPR) {
            Write-Host "`n✅ Test PR found: #$($testPR.number)" -ForegroundColor Green
            Write-Host "Title: $($testPR.title)" -ForegroundColor Green
            
            # Check PR status and checks
            try {
                $prDetails = gh pr view $testPR.number --json statusCheckRollup,reviews | ConvertFrom-Json
                
                if ($prDetails.statusCheckRollup) {
                    Write-Host "`nPR Status Checks:" -ForegroundColor Cyan
                    $prDetails.statusCheckRollup | ForEach-Object {
                        $status = switch ($_.state) {
                            "SUCCESS" { "✅" }
                            "FAILURE" { "❌" }
                            "PENDING" { "⏳" }
                            "ERROR" { "⚠️" }
                            default { "❓" }
                        }
                        Write-Host "  $status $($_.name) - $($_.state)" -ForegroundColor White
                    }
                }
                
                if ($prDetails.reviews) {
                    $approvedReviews = $prDetails.reviews | Where-Object { $_.state -eq "APPROVED" }
                    if ($approvedReviews) {
                        Write-Host "`n✅ Found approved reviews:" -ForegroundColor Green
                        $approvedReviews | ForEach-Object {
                            Write-Host "  Approved by: $($_.author.login)" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "`n⚠️  No approved reviews yet" -ForegroundColor Yellow
                    }
                }
                
            } catch {
                Write-Host "❌ Error getting PR details: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "`n⚠️  Test PR not found - may still be processing" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No open PRs found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error checking PRs: $($_.Exception.Message)" -ForegroundColor Red
}

# Check Mergify status
Write-Host "`n3. Checking Mergify configuration..." -ForegroundColor Yellow

if (Test-Path ".mergify.yml") {
    Write-Host "✅ Mergify config found" -ForegroundColor Green
    
    $mergifyConfig = Get-Content ".mergify.yml" -Raw
    if ($mergifyConfig -match "queue_rules") {
        Write-Host "✅ Queue rules configured" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No queue rules found" -ForegroundColor Yellow
    }
    
    if ($mergifyConfig -match "auto-merge") {
        Write-Host "✅ Auto-merge rules configured" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No auto-merge rules found" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ No Mergify config found" -ForegroundColor Red
}

Write-Host "`n🏁 Concurrency and Queue Validation Complete!" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
