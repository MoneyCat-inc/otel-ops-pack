# Validation Evidence Collection Script
# Captures screenshots, logs, and status for all validation tasks

Write-Host "📸 COLLECTING VALIDATION EVIDENCE" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Create evidence directory
$evidenceDir = "validation-evidence-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
Write-Host "📁 Created evidence directory: $evidenceDir" -ForegroundColor Green

# 1. Background CI Monitor Status
Write-Host "`n1. 📊 BACKGROUND CI MONITOR EVIDENCE" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow

$monitorProcess = Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*monitor-ci-background*"
}

if ($monitorProcess) {
    Write-Host "✅ Background Monitor: RUNNING (PID: $($monitorProcess.Id))" -ForegroundColor Green
    "Background Monitor Status: RUNNING (PID: $($monitorProcess.Id))" | Out-File "$evidenceDir\background-monitor-status.txt"
} else {
    Write-Host "⚠️  Background Monitor: COMPLETED OR STOPPED" -ForegroundColor Yellow
    "Background Monitor Status: COMPLETED OR STOPPED" | Out-File "$evidenceDir\background-monitor-status.txt"
}

# Check for collector logs if monitor completed
if (Test-Path "otel_art\collector.log") {
    Write-Host "✅ Collector logs found in otel_art\collector.log" -ForegroundColor Green
    
    # Extract ci-cat span evidence
    $spanEvidence = Select-String -Path "otel_art\collector.log" -Pattern "service\.name.*ci-cat|ci-smoke|Trace ID|Span ID" | ForEach-Object { $_.Line }
    if ($spanEvidence) {
        Write-Host "✅ Found ci-cat span evidence:" -ForegroundColor Green
        $spanEvidence | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        $spanEvidence | Out-File "$evidenceDir\ci-cat-span-evidence.txt"
    }
    
    # Check for deprecation warnings
    $deprecationWarnings = Select-String -Path "otel_art\collector.log" -Pattern "logging exporter.*deprecated" | ForEach-Object { $_.Line }
    if ($deprecationWarnings) {
        Write-Host "❌ Found deprecation warnings:" -ForegroundColor Red
        $deprecationWarnings | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        $deprecationWarnings | Out-File "$evidenceDir\deprecation-warnings.txt"
    } else {
        Write-Host "✅ No deprecation warnings found" -ForegroundColor Green
        "No deprecation warnings found" | Out-File "$evidenceDir\deprecation-warnings.txt"
    }
    
    # Copy collector log
    Copy-Item "otel_art\collector.log" "$evidenceDir\collector.log"
    Write-Host "📋 Collector log copied to evidence directory" -ForegroundColor Green
}

# 2. Concurrency Test Evidence
Write-Host "`n2. 🔄 CONCURRENCY TEST EVIDENCE" -ForegroundColor Yellow
Write-Host "-------------------------------" -ForegroundColor Yellow

try {
    $runs = gh run list --limit 10 --json databaseId,status,conclusion,displayTitle,createdAt,headSha | ConvertFrom-Json
    
    if ($runs) {
        Write-Host "Recent CI runs:" -ForegroundColor Cyan
        $runs | ForEach-Object {
            $status = if ($_.status -eq "completed") { $_.conclusion.ToUpper() } else { $_.status.ToUpper() }
            $color = switch ($status) {
                "SUCCESS" { "Green" }
                "FAILURE" { "Red" }
                "CANCELLED" { "Yellow" }
                "RUNNING" { "Cyan" }
                default { "White" }
            }
            Write-Host "  $status - $($_.displayTitle)" -ForegroundColor $color
            Write-Host "    SHA: $($_.headSha.Substring(0,8)) | Created: $($_.createdAt)" -ForegroundColor Gray
        }
        
        # Save runs data
        $runs | ConvertTo-Json -Depth 3 | Out-File "$evidenceDir\ci-runs.json"
        
        # Look for cancelled runs
        $cancelledRuns = $runs | Where-Object { $_.conclusion -eq "cancelled" }
        if ($cancelledRuns) {
            Write-Host "`n✅ CONCURRENCY WORKING!" -ForegroundColor Green
            Write-Host "Found cancelled runs:" -ForegroundColor Green
            $cancelledRuns | ForEach-Object {
                Write-Host "  🚫 $($_.databaseId) - $($_.displayTitle)" -ForegroundColor Green
            }
            $cancelledRuns | ConvertTo-Json -Depth 3 | Out-File "$evidenceDir\cancelled-runs.json"
        } else {
            Write-Host "`n⏳ No cancelled runs found yet" -ForegroundColor Yellow
            "No cancelled runs found yet" | Out-File "$evidenceDir\cancelled-runs.json"
        }
        
        # Check for running jobs
        $runningRuns = $runs | Where-Object { $_.status -eq "in_progress" }
        if ($runningRuns) {
            Write-Host "`n🔄 Active runs:" -ForegroundColor Cyan
            $runningRuns | ForEach-Object {
                Write-Host "  ▶️  $($_.databaseId) - $($_.displayTitle)" -ForegroundColor Cyan
            }
        }
    }
} catch {
    Write-Host "❌ Error checking CI runs: $($_.Exception.Message)" -ForegroundColor Red
    "Error checking CI runs: $($_.Exception.Message)" | Out-File "$evidenceDir\ci-runs-error.txt"
}

# 3. Queue Test Evidence
Write-Host "`n3. 📋 QUEUE TEST EVIDENCE" -ForegroundColor Yellow
Write-Host "------------------------" -ForegroundColor Yellow

try {
    $prs = gh pr list --json number,title,state,author,headRefName,url,createdAt | ConvertFrom-Json
    
    if ($prs) {
        Write-Host "Open PRs:" -ForegroundColor Cyan
        $prs | ForEach-Object {
            $stateColor = switch ($_.state) {
                "OPEN" { "Green" }
                "MERGED" { "Blue" }
                "CLOSED" { "Red" }
                default { "Gray" }
            }
            Write-Host "  PR #$($_.number) | $($_.state) | $($_.title)" -ForegroundColor $stateColor
            Write-Host "    Author: $($_.author.login) | Branch: $($_.headRefName)" -ForegroundColor Gray
            Write-Host "    URL: $($_.url)" -ForegroundColor Gray
        }
        
        # Save PRs data
        $prs | ConvertTo-Json -Depth 3 | Out-File "$evidenceDir\open-prs.json"
        
        # Check for test PR
        $testPR = $prs | Where-Object { $_.headRefName -eq "test-queue-behavior" }
        if ($testPR) {
            Write-Host "`n✅ TEST PR FOUND!" -ForegroundColor Green
            Write-Host "  PR #$($testPR.number): $($testPR.title)" -ForegroundColor Green
            Write-Host "  State: $($testPR.state)" -ForegroundColor Green
            Write-Host "  URL: $($testPR.url)" -ForegroundColor Green
            
            # Save test PR data
            $testPR | ConvertTo-Json -Depth 3 | Out-File "$evidenceDir\test-pr.json"
            
            # Get detailed PR info
            try {
                $prDetails = gh pr view $testPR.number --json statusCheckRollup,reviews,state,comments | ConvertFrom-Json
                $prDetails | ConvertTo-Json -Depth 3 | Out-File "$evidenceDir\test-pr-details.json"
                
                Write-Host "`n  PR Details saved to evidence directory" -ForegroundColor Green
                
                # Check for Mergify comments
                $mergifyComments = $prDetails.comments | Where-Object { $_.author.login -eq "mergify[bot]" }
                if ($mergifyComments) {
                    Write-Host "`n✅ Mergify comments found:" -ForegroundColor Green
                    $mergifyComments | ForEach-Object {
                        Write-Host "  🤖 $($_.body)" -ForegroundColor Green
                    }
                    $mergifyComments | ConvertTo-Json -Depth 3 | Out-File "$evidenceDir\mergify-comments.json"
                } else {
                    Write-Host "`n⏳ No Mergify comments yet" -ForegroundColor Yellow
                    "No Mergify comments yet" | Out-File "$evidenceDir\mergify-comments.json"
                }
                
            } catch {
                Write-Host "❌ Error getting PR details: $($_.Exception.Message)" -ForegroundColor Red
                "Error getting PR details: $($_.Exception.Message)" | Out-File "$evidenceDir\test-pr-details-error.txt"
            }
        } else {
            Write-Host "`n⚠️  Test PR not found" -ForegroundColor Yellow
            "Test PR not found" | Out-File "$evidenceDir\test-pr.json"
        }
    } else {
        Write-Host "No open PRs found" -ForegroundColor Yellow
        "No open PRs found" | Out-File "$evidenceDir\open-prs.json"
    }
} catch {
    Write-Host "❌ Error checking PRs: $($_.Exception.Message)" -ForegroundColor Red
    "Error checking PRs: $($_.Exception.Message)" | Out-File "$evidenceDir\prs-error.txt"
}

# 4. Reviewdog Test Evidence
Write-Host "`n4. 🔍 REVIEWDOG TEST EVIDENCE" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Yellow

if (Test-Path "test-reviewdog.js") {
    Write-Host "✅ Test file present: test-reviewdog.js" -ForegroundColor Green
    
    # Copy test file to evidence
    Copy-Item "test-reviewdog.js" "$evidenceDir\test-reviewdog.js"
    Write-Host "📋 Test file copied to evidence directory" -ForegroundColor Green
    
    # Check git status
    try {
        $gitStatus = git status --porcelain
        if ($gitStatus -match "test-reviewdog.js") {
            Write-Host "⚠️  File has uncommitted changes" -ForegroundColor Yellow
            "File has uncommitted changes: $gitStatus" | Out-File "$evidenceDir\test-file-git-status.txt"
        } else {
            Write-Host "✅ File committed and pushed" -ForegroundColor Green
            "File committed and pushed" | Out-File "$evidenceDir\test-file-git-status.txt"
        }
    } catch {
        Write-Host "⚠️  Could not check git status" -ForegroundColor Yellow
        "Could not check git status" | Out-File "$evidenceDir\test-file-git-status.txt"
    }
} else {
    Write-Host "❌ Test file not found" -ForegroundColor Red
    "Test file not found" | Out-File "$evidenceDir\test-file-status.txt"
}

# 5. Summary Report
Write-Host "`n5. 📊 EVIDENCE SUMMARY" -ForegroundColor Yellow
Write-Host "---------------------" -ForegroundColor Yellow

$summary = @"
VALIDATION EVIDENCE COLLECTION SUMMARY
=====================================
Timestamp: $(Get-Date)
Evidence Directory: $evidenceDir

BACKGROUND CI MONITOR:
- Status: $(if ($monitorProcess) { "RUNNING (PID: $($monitorProcess.Id))" } else { "COMPLETED OR STOPPED" })
- Collector Log: $(if (Test-Path "otel_art\collector.log") { "FOUND" } else { "NOT FOUND" })
- CI-Cat Span: $(if (Test-Path "$evidenceDir\ci-cat-span-evidence.txt") { "FOUND" } else { "NOT FOUND" })
- Deprecation Warnings: $(if (Test-Path "$evidenceDir\deprecation-warnings.txt") { "CHECKED" } else { "NOT CHECKED" })

CONCURRENCY TEST:
- Recent Runs: $(if (Test-Path "$evidenceDir\ci-runs.json") { "CAPTURED" } else { "NOT CAPTURED" })
- Cancelled Runs: $(if (Test-Path "$evidenceDir\cancelled-runs.json") { "FOUND" } else { "NOT FOUND" })

QUEUE TEST:
- Open PRs: $(if (Test-Path "$evidenceDir\open-prs.json") { "CAPTURED" } else { "NOT CAPTURED" })
- Test PR: $(if (Test-Path "$evidenceDir\test-pr.json") { "FOUND" } else { "NOT FOUND" })
- Mergify Comments: $(if (Test-Path "$evidenceDir\mergify-comments.json") { "FOUND" } else { "NOT FOUND" })

REVIEWDOG TEST:
- Test File: $(if (Test-Path "$evidenceDir\test-reviewdog.js") { "FOUND" } else { "NOT FOUND" })
- Git Status: $(if (Test-Path "$evidenceDir\test-file-git-status.txt") { "CHECKED" } else { "NOT CHECKED" })

NEXT STEPS:
1. Review collected evidence
2. Take screenshots of key findings
3. Document validation results
4. Clean up test branches/PRs
"@

$summary | Out-File "$evidenceDir\validation-summary.txt"
Write-Host $summary -ForegroundColor White

Write-Host "`n📁 Evidence collected in: $evidenceDir" -ForegroundColor Green
Write-Host "🔄 Run this script again to collect updated evidence" -ForegroundColor Yellow
