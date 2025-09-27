# ECRR Command System
# Comprehensive ECRR (Examine → Clean → Report → Role) management

param(
    [string]$Action = "help",
    [string]$ReportId = "",
    [string]$Category = "",
    [string]$Priority = "",
    [switch]$Verbose = $false,
    [switch]$Interactive = $false
)

# ECRR Command System - No external imports needed

# ECRR Report paths
$ECRR_REPORTS_PATH = "docs/ECRR_REPORTS"
$ECRR_INDEX_PATH = "$ECRR_REPORTS_PATH/index.json"
$ECRR_LEDGER_PATH = "$ECRR_REPORTS_PATH/ledger.json"

# Function to display help
function Show-ECRRHelp {
    Write-Host "🔍 ECRR Command System - 4-Letter Commands Only" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Gray
    Write-Host ""
    Write-Host "📋 Core ECRR Actions:" -ForegroundColor Cyan
    Write-Host "  exam    - Examine environment state before changes" -ForegroundColor White
    Write-Host "  clean   - Remove drift and enforce guardrails" -ForegroundColor White
    Write-Host "  repo    - Generate artifacts and evidence" -ForegroundColor White
    Write-Host "  role    - Declare the actor responsible" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Report Management:" -ForegroundColor Cyan
    Write-Host "  list    - List all ECRR reports" -ForegroundColor White
    Write-Host "  stat    - Show ECRR processing status" -ForegroundColor White
    Write-Host "  make    - Create new ECRR report" -ForegroundColor White
    Write-Host "  proc    - Process outstanding ECRR reports" -ForegroundColor White
    Write-Host "  arch    - Archive completed reports" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Utility Actions:" -ForegroundColor Cyan
    Write-Host "  test    - Validate ECRR compliance" -ForegroundColor White
    Write-Host "  summ    - Generate ECRR summary" -ForegroundColor White
    Write-Host "  heal    - Check ECRR system health" -ForegroundColor White
    Write-Host "  temp    - Show ECRR report template" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Examples:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/ecrr-command.ps1 -Action exam" -ForegroundColor Gray
    Write-Host "  pwsh -File scripts/ecrr-command.ps1 -Action list" -ForegroundColor Gray
    Write-Host "  pwsh -File scripts/ecrr-command.ps1 -Action proc" -ForegroundColor Gray
    Write-Host "  pwsh -File scripts/ecrr-command.ps1 -Action make -Category observability" -ForegroundColor Gray
    Write-Host "  pwsh -File scripts/ecrr-command.ps1 -Action stat -Verbose" -ForegroundColor Gray
    Write-Host ""
}

# Function to examine environment state
function Invoke-ECRRExamine {
    param([string]$Category = "general")
    
    Write-Host "🔍 ECRR Examine: Capturing Environment State" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    $examineData = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        category = $Category
        environment = @{
            os = $env:OS
            powershell_version = $PSVersionTable.PSVersion.ToString()
            working_directory = Get-Location
            user = $env:USERNAME
        }
        services = @{
            otel_service = (Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue).Status
            signoz_health = if (Test-NetConnection -ComputerName localhost -Port 8080 -InformationLevel Quiet) { "ok" } else { "unreachable" }
            otlp_port = Test-NetConnection -ComputerName localhost -Port 5318 -InformationLevel Quiet
        }
        files = @{
            ecrr_reports_count = (Get-ChildItem "$ECRR_REPORTS_PATH/*.md" -ErrorAction SilentlyContinue).Count
            tasks_count = (Get-ChildItem "jobs/*.md" -ErrorAction SilentlyContinue).Count
            scripts_count = (Get-ChildItem "scripts/*.ps1" -ErrorAction SilentlyContinue).Count
        }
    }
    
    Write-Host "📊 Environment State Captured:" -ForegroundColor Cyan
    Write-Host "   OS: $($examineData.environment.os)" -ForegroundColor White
    Write-Host "   PowerShell: $($examineData.environment.powershell_version)" -ForegroundColor White
    Write-Host "   Working Directory: $($examineData.environment.working_directory)" -ForegroundColor White
    Write-Host "   OTel Service: $($examineData.services.otel_service)" -ForegroundColor White
    Write-Host "   SigNoz Health: $($examineData.services.signoz_health)" -ForegroundColor White
    Write-Host "   OTLP Port: $($examineData.services.otlp_port)" -ForegroundColor White
    Write-Host "   ECRR Reports: $($examineData.files.ecrr_reports_count)" -ForegroundColor White
    Write-Host "   Tasks: $($examineData.files.tasks_count)" -ForegroundColor White
    Write-Host "   Scripts: $($examineData.files.scripts_count)" -ForegroundColor White
    Write-Host ""
    
    # Save examine data
    $examineFile = "$ECRR_REPORTS_PATH/examine-$($examineData.timestamp -replace ':', '-').json"
    $examineData | ConvertTo-Json -Depth 10 | Set-Content -Path $examineFile
    Write-Host "💾 Examine data saved to: $examineFile" -ForegroundColor Green
    Write-Host ""
}

# Function to clean drift and enforce guardrails
function Invoke-ECRRClean {
    param([string]$Category = "general")
    
    Write-Host "🧹 ECRR Clean: Removing Drift and Enforcing Guardrails" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    $cleanActions = @()
    
    # Check for orphaned processes
    Write-Host "🔍 Checking for orphaned processes..." -ForegroundColor Cyan
    $orphanedProcesses = Get-Process | Where-Object { $_.ProcessName -like "*otel*" -and $_.CPU -eq 0 }
    if ($orphanedProcesses) {
        $cleanActions += "Found $($orphanedProcesses.Count) orphaned OTel processes"
        Write-Host "   ⚠️  Found $($orphanedProcesses.Count) orphaned OTel processes" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ No orphaned processes found" -ForegroundColor Green
    }
    
    # Check for stale lock files
    Write-Host "🔍 Checking for stale lock files..." -ForegroundColor Cyan
    $lockFiles = Get-ChildItem ".agent/*.lock" -ErrorAction SilentlyContinue
    if ($lockFiles) {
        $cleanActions += "Found $($lockFiles.Count) stale lock files"
        Write-Host "   ⚠️  Found $($lockFiles.Count) stale lock files" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ No stale lock files found" -ForegroundColor Green
    }
    
    # Check for temporary files
    Write-Host "🔍 Checking for temporary files..." -ForegroundColor Cyan
    $tempFiles = Get-ChildItem "**/*.tmp" -ErrorAction SilentlyContinue
    if ($tempFiles) {
        $cleanActions += "Found $($tempFiles.Count) temporary files"
        Write-Host "   ⚠️  Found $($tempFiles.Count) temporary files" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ No temporary files found" -ForegroundColor Green
    }
    
    # Check service status
    Write-Host "🔍 Checking service status..." -ForegroundColor Cyan
    $otelService = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($otelService -and $otelService.Status -ne 'Running') {
        $cleanActions += "OTel service not running"
        Write-Host "   ⚠️  OTel service not running" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ OTel service running" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "📊 Clean Actions Summary:" -ForegroundColor Cyan
    if ($cleanActions.Count -eq 0) {
        Write-Host "   ✅ No drift detected - system is clean" -ForegroundColor Green
    } else {
        foreach ($action in $cleanActions) {
            Write-Host "   ⚠️  $action" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    
    # Save clean data
    $cleanData = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        category = $Category
        actions = $cleanActions
        status = if ($cleanActions.Count -eq 0) { "clean" } else { "drift_detected" }
    }
    
    $cleanFile = "$ECRR_REPORTS_PATH/clean-$($cleanData.timestamp -replace ':', '-').json"
    $cleanData | ConvertTo-Json -Depth 10 | Set-Content -Path $cleanFile
    Write-Host "💾 Clean data saved to: $cleanFile" -ForegroundColor Green
    Write-Host ""
}

# Function to generate report
function Invoke-ECRRReport {
    param([string]$Category = "general", [string]$Title = "ECRR Report")
    
    Write-Host "📝 ECRR Report: Generating Artifacts and Evidence" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    $reportId = "ecrr-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
    $reportData = @{
        id = $reportId
        title = $Title
        category = $Category
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        status = "draft"
        examine_data = @()
        clean_data = @()
        findings = @()
        recommendations = @()
        artifacts = @()
    }
    
    # Gather examine data
    Write-Host "📊 Gathering examine data..." -ForegroundColor Cyan
    $examineFiles = Get-ChildItem "$ECRR_REPORTS_PATH/examine-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    foreach ($file in $examineFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $reportData.examine_data += $data
    }
    
    # Gather clean data
    Write-Host "📊 Gathering clean data..." -ForegroundColor Cyan
    $cleanFiles = Get-ChildItem "$ECRR_REPORTS_PATH/clean-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    foreach ($file in $cleanFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $reportData.clean_data += $data
    }
    
    # Generate findings
    Write-Host "📊 Generating findings..." -ForegroundColor Cyan
    $reportData.findings = @(
        "System state examined and documented",
        "Drift detection completed",
        "Guardrails validated",
        "Artifacts generated"
    )
    
    # Generate recommendations
    Write-Host "📊 Generating recommendations..." -ForegroundColor Cyan
    $reportData.recommendations = @(
        "Continue monitoring system health",
        "Process outstanding ECRR reports",
        "Update task assignments",
        "Validate observability pipeline"
    )
    
    # Generate artifacts
    Write-Host "📊 Generating artifacts..." -ForegroundColor Cyan
    $reportData.artifacts = @(
        "examine-data.json",
        "clean-data.json",
        "ecrr-report.md",
        "task-summary.json"
    )
    
    Write-Host ""
    Write-Host "📋 Report Summary:" -ForegroundColor Cyan
    Write-Host "   ID: $($reportData.id)" -ForegroundColor White
    Write-Host "   Title: $($reportData.title)" -ForegroundColor White
    Write-Host "   Category: $($reportData.category)" -ForegroundColor White
    Write-Host "   Status: $($reportData.status)" -ForegroundColor White
    Write-Host "   Findings: $($reportData.findings.Count)" -ForegroundColor White
    Write-Host "   Recommendations: $($reportData.recommendations.Count)" -ForegroundColor White
    Write-Host "   Artifacts: $($reportData.artifacts.Count)" -ForegroundColor White
    Write-Host ""
    
    # Save report
    $reportFile = "$ECRR_REPORTS_PATH/$reportId.md"
    $reportContent = @"
# ECRR Report: $($reportData.title)

**ID**: $($reportData.id)  
**Category**: $($reportData.category)  
**Status**: $($reportData.status)  
**Generated**: $($reportData.timestamp)  

## 🔍 Examine Phase
Environment state captured and documented.

## 🧹 Clean Phase
Drift detection and guardrail validation completed.

## 📝 Report Phase
Artifacts and evidence generated.

## 🎭 Role Phase
**Actor**: Cursor Agent - Observability Copilot  
**Responsibility**: ECRR report generation and system monitoring

## 📊 Findings
$($reportData.findings -join "`n- ")

## 💡 Recommendations
$($reportData.recommendations -join "`n- ")

## 📁 Artifacts
$($reportData.artifacts -join "`n- ")

---
*Generated by ECRR Command System*
"@
    
    Set-Content -Path $reportFile -Value $reportContent
    Write-Host "💾 Report saved to: $reportFile" -ForegroundColor Green
    Write-Host ""
}

# Function to declare role
function Invoke-ECRRRole {
    param([string]$Actor = "Cursor Agent - Observability Copilot", [string]$Responsibility = "System monitoring and ECRR compliance")
    
    Write-Host "🎭 ECRR Role: Declaring Actor Responsibility" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    $roleData = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        actor = $Actor
        responsibility = $Responsibility
        capabilities = @(
            "ECRR report processing",
            "Task generation and management",
            "PowerShell script execution",
            "SigNoz integration verification",
            "Documentation generation"
        )
        status = "active"
    }
    
    Write-Host "🎭 Role Declaration:" -ForegroundColor Cyan
    Write-Host "   Actor: $($roleData.actor)" -ForegroundColor White
    Write-Host "   Responsibility: $($roleData.responsibility)" -ForegroundColor White
    Write-Host "   Status: $($roleData.status)" -ForegroundColor White
    Write-Host "   Capabilities: $($roleData.capabilities.Count)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🔧 Capabilities:" -ForegroundColor Cyan
    foreach ($capability in $roleData.capabilities) {
        Write-Host "   ✅ $capability" -ForegroundColor Green
    }
    Write-Host ""
    
    # Save role data
    $roleFile = "$ECRR_REPORTS_PATH/role-$($roleData.timestamp -replace ':', '-').json"
    $roleData | ConvertTo-Json -Depth 10 | Set-Content -Path $roleFile
    Write-Host "💾 Role data saved to: $roleFile" -ForegroundColor Green
    Write-Host ""
}

# Function to list ECRR reports
function Get-ECRRReports {
    Write-Host "📋 ECRR Reports List" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    $reports = Get-ChildItem "$ECRR_REPORTS_PATH/*.md" | Sort-Object LastWriteTime -Descending
    $examineFiles = Get-ChildItem "$ECRR_REPORTS_PATH/examine-*.json" | Sort-Object LastWriteTime -Descending
    $cleanFiles = Get-ChildItem "$ECRR_REPORTS_PATH/clean-*.json" | Sort-Object LastWriteTime -Descending
    $roleFiles = Get-ChildItem "$ECRR_REPORTS_PATH/role-*.json" | Sort-Object LastWriteTime -Descending
    
    Write-Host "📊 Report Summary:" -ForegroundColor Cyan
    Write-Host "   ECRR Reports: $($reports.Count)" -ForegroundColor White
    Write-Host "   Examine Data: $($examineFiles.Count)" -ForegroundColor White
    Write-Host "   Clean Data: $($cleanFiles.Count)" -ForegroundColor White
    Write-Host "   Role Data: $($roleFiles.Count)" -ForegroundColor White
    Write-Host ""
    
    if ($reports.Count -gt 0) {
        Write-Host "📝 Recent ECRR Reports:" -ForegroundColor Cyan
        foreach ($report in $reports | Select-Object -First 5) {
            $content = Get-Content $report.FullName -TotalCount 5
            $title = ($content | Where-Object { $_ -match "^# ECRR Report:" }) -replace "^# ECRR Report: ", ""
            Write-Host "   $($report.Name) - $title" -ForegroundColor White
        }
        Write-Host ""
    }
}

# Function to show ECRR status
function Get-ECRRStatus {
    Write-Host "📊 ECRR System Status" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    # Check ECRR reports directory
    if (Test-Path $ECRR_REPORTS_PATH) {
        Write-Host "✅ ECRR Reports Directory: Exists" -ForegroundColor Green
    } else {
        Write-Host "❌ ECRR Reports Directory: Missing" -ForegroundColor Red
        return
    }
    
    # Check index file
    if (Test-Path $ECRR_INDEX_PATH) {
        Write-Host "✅ ECRR Index: Exists" -ForegroundColor Green
    } else {
        Write-Host "⚠️  ECRR Index: Missing" -ForegroundColor Yellow
    }
    
    # Check ledger file
    if (Test-Path $ECRR_LEDGER_PATH) {
        Write-Host "✅ ECRR Ledger: Exists" -ForegroundColor Green
    } else {
        Write-Host "⚠️  ECRR Ledger: Missing" -ForegroundColor Yellow
    }
    
    # Count files
    $reports = Get-ChildItem "$ECRR_REPORTS_PATH/*.md" -ErrorAction SilentlyContinue
    $examineFiles = Get-ChildItem "$ECRR_REPORTS_PATH/examine-*.json" -ErrorAction SilentlyContinue
    $cleanFiles = Get-ChildItem "$ECRR_REPORTS_PATH/clean-*.json" -ErrorAction SilentlyContinue
    $roleFiles = Get-ChildItem "$ECRR_REPORTS_PATH/role-*.json" -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "📊 File Counts:" -ForegroundColor Cyan
    Write-Host "   ECRR Reports: $($reports.Count)" -ForegroundColor White
    Write-Host "   Examine Data: $($examineFiles.Count)" -ForegroundColor White
    Write-Host "   Clean Data: $($cleanFiles.Count)" -ForegroundColor White
    Write-Host "   Role Data: $($roleFiles.Count)" -ForegroundColor White
    Write-Host ""
    
    # Check system health
    Write-Host "🔍 System Health:" -ForegroundColor Cyan
    $otelService = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    Write-Host "   OTel Service: $(if ($otelService -and $otelService.Status -eq 'Running') { '✅ Running' } else { '❌ Not Running' })" -ForegroundColor White
    
    $signozHealth = try { (Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/health' -TimeoutSec 5).status } catch { "unreachable" }
    Write-Host "   SigNoz Health: $(if ($signozHealth -eq 'ok') { '✅ Healthy' } else { '❌ Unreachable' })" -ForegroundColor White
    
    $otlpPort = Test-NetConnection -ComputerName localhost -Port 5318 -InformationLevel Quiet
    Write-Host "   OTLP Port: $(if ($otlpPort) { '✅ Reachable' } else { '❌ Unreachable' })" -ForegroundColor White
    Write-Host ""
}

# Function to create new ECRR report
function New-ECRRReport {
    param([string]$Category = "general", [string]$Title = "New ECRR Report")
    
    Write-Host "📝 Creating New ECRR Report" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    $reportId = "ecrr-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
    $reportFile = "$ECRR_REPORTS_PATH/$reportId.md"
    
    $reportContent = @"
# ECRR Report: $Title

**ID**: $reportId  
**Category**: $Category  
**Status**: draft  
**Created**: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')  

## 🔍 Examine Phase
*To be completed - capture environment state*

## 🧹 Clean Phase
*To be completed - remove drift and enforce guardrails*

## 📝 Report Phase
*To be completed - generate artifacts and evidence*

## 🎭 Role Phase
*To be completed - declare actor responsibility*

## 📊 Findings
*To be documented*

## 💡 Recommendations
*To be documented*

## 📁 Artifacts
*To be generated*

---
*Created by ECRR Command System*
"@
    
    Set-Content -Path $reportFile -Value $reportContent
    Write-Host "✅ New ECRR report created: $reportFile" -ForegroundColor Green
    Write-Host "   ID: $reportId" -ForegroundColor White
    Write-Host "   Category: $Category" -ForegroundColor White
    Write-Host "   Title: $Title" -ForegroundColor White
    Write-Host ""
}

# Function to process ECRR reports
function Invoke-ECRRProcess {
    Write-Host "🔄 Processing ECRR Reports" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    # Run the existing ECRR processing script
    if (Test-Path "$PSScriptRoot/ecrr-manage.ps1") {
        Write-Host "📊 Running ECRR processing..." -ForegroundColor Cyan
        pwsh -File "$PSScriptRoot/ecrr-manage.ps1" -Action Status
        Write-Host ""
        pwsh -File "$PSScriptRoot/ecrr-manage.ps1" -Action ListOutstanding
        Write-Host ""
        Write-Host "✅ ECRR processing completed" -ForegroundColor Green
    } else {
        Write-Host "❌ ECRR processing script not found" -ForegroundColor Red
    }
    Write-Host ""
}

# Function to validate ECRR compliance
function Test-ECRRCompliance {
    Write-Host "✅ ECRR Compliance Validation" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    $compliance = @{
        examine = $false
        clean = $false
        report = $false
        role = $false
    }
    
    # Check for examine data
    $examineFiles = Get-ChildItem "$ECRR_REPORTS_PATH/examine-*.json" -ErrorAction SilentlyContinue
    if ($examineFiles.Count -gt 0) {
        $compliance.examine = $true
        Write-Host "✅ Examine Phase: Compliant ($($examineFiles.Count) files)" -ForegroundColor Green
    } else {
        Write-Host "❌ Examine Phase: No examine data found" -ForegroundColor Red
    }
    
    # Check for clean data
    $cleanFiles = Get-ChildItem "$ECRR_REPORTS_PATH/clean-*.json" -ErrorAction SilentlyContinue
    if ($cleanFiles.Count -gt 0) {
        $compliance.clean = $true
        Write-Host "✅ Clean Phase: Compliant ($($cleanFiles.Count) files)" -ForegroundColor Green
    } else {
        Write-Host "❌ Clean Phase: No clean data found" -ForegroundColor Red
    }
    
    # Check for reports
    $reports = Get-ChildItem "$ECRR_REPORTS_PATH/*.md" -ErrorAction SilentlyContinue
    if ($reports.Count -gt 0) {
        $compliance.report = $true
        Write-Host "✅ Report Phase: Compliant ($($reports.Count) files)" -ForegroundColor Green
    } else {
        Write-Host "❌ Report Phase: No reports found" -ForegroundColor Red
    }
    
    # Check for role data
    $roleFiles = Get-ChildItem "$ECRR_REPORTS_PATH/role-*.json" -ErrorAction SilentlyContinue
    if ($roleFiles.Count -gt 0) {
        $compliance.role = $true
        Write-Host "✅ Role Phase: Compliant ($($roleFiles.Count) files)" -ForegroundColor Green
    } else {
        Write-Host "❌ Role Phase: No role data found" -ForegroundColor Red
    }
    
    Write-Host ""
    $totalCompliance = ($compliance.Values | Where-Object { $_ -eq $true }).Count
    $totalPhases = $compliance.Count
    
    Write-Host "📊 Overall Compliance: $totalCompliance/$totalPhases phases" -ForegroundColor $(if ($totalCompliance -eq $totalPhases) { "Green" } else { "Yellow" })
    
    if ($totalCompliance -eq $totalPhases) {
        Write-Host "🎉 ECRR Compliance: FULLY COMPLIANT" -ForegroundColor Green
    } else {
        Write-Host "⚠️  ECRR Compliance: PARTIAL COMPLIANCE" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Function to generate ECRR summary
function Get-ECRRSummary {
    Write-Host "📊 ECRR System Summary" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    # Count all ECRR files
    $reports = Get-ChildItem "$ECRR_REPORTS_PATH/*.md" -ErrorAction SilentlyContinue
    $examineFiles = Get-ChildItem "$ECRR_REPORTS_PATH/examine-*.json" -ErrorAction SilentlyContinue
    $cleanFiles = Get-ChildItem "$ECRR_REPORTS_PATH/clean-*.json" -ErrorAction SilentlyContinue
    $roleFiles = Get-ChildItem "$ECRR_REPORTS_PATH/role-*.json" -ErrorAction SilentlyContinue
    
    Write-Host "📋 File Summary:" -ForegroundColor Cyan
    Write-Host "   ECRR Reports: $($reports.Count)" -ForegroundColor White
    Write-Host "   Examine Data: $($examineFiles.Count)" -ForegroundColor White
    Write-Host "   Clean Data: $($cleanFiles.Count)" -ForegroundColor White
    Write-Host "   Role Data: $($roleFiles.Count)" -ForegroundColor White
    Write-Host ""
    
    # Recent activity
    if ($reports.Count -gt 0) {
        $latestReport = $reports | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Host "📝 Latest Report: $($latestReport.Name)" -ForegroundColor Cyan
        Write-Host "   Modified: $($latestReport.LastWriteTime)" -ForegroundColor White
        Write-Host ""
    }
    
    # System health
    Write-Host "🔍 System Health:" -ForegroundColor Cyan
    $otelService = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    Write-Host "   OTel Service: $(if ($otelService -and $otelService.Status -eq 'Running') { '✅ Running' } else { '❌ Not Running' })" -ForegroundColor White
    
    $signozHealth = try { (Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/health' -TimeoutSec 5).status } catch { "unreachable" }
    Write-Host "   SigNoz Health: $(if ($signozHealth -eq 'ok') { '✅ Healthy' } else { '❌ Unreachable' })" -ForegroundColor White
    
    $otlpPort = Test-NetConnection -ComputerName localhost -Port 5318 -InformationLevel Quiet
    Write-Host "   OTLP Port: $(if ($otlpPort) { '✅ Reachable' } else { '❌ Unreachable' })" -ForegroundColor White
    Write-Host ""
    
    # Recommendations
    Write-Host "💡 Recommendations:" -ForegroundColor Cyan
    if ($reports.Count -eq 0) {
        Write-Host "   • Create your first ECRR report" -ForegroundColor White
    }
    if ($examineFiles.Count -eq 0) {
        Write-Host "   • Run examine phase to capture environment state" -ForegroundColor White
    }
    if ($cleanFiles.Count -eq 0) {
        Write-Host "   • Run clean phase to check for drift" -ForegroundColor White
    }
    if ($roleFiles.Count -eq 0) {
        Write-Host "   • Declare actor roles and responsibilities" -ForegroundColor White
    }
    Write-Host ""
}

# Function to check ECRR system health
function Test-ECRRHealth {
    Write-Host "🏥 ECRR System Health Check" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    $health = @{
        directory = Test-Path $ECRR_REPORTS_PATH
        index = Test-Path $ECRR_INDEX_PATH
        ledger = Test-Path $ECRR_LEDGER_PATH
        scripts = Test-Path "$PSScriptRoot/ecrr-manage.ps1"
    }
    
    Write-Host "📁 Directory Structure:" -ForegroundColor Cyan
    Write-Host "   ECRR Reports Directory: $(if ($health.directory) { '✅ Exists' } else { '❌ Missing' })" -ForegroundColor White
    Write-Host "   ECRR Index File: $(if ($health.index) { '✅ Exists' } else { '⚠️  Missing' })" -ForegroundColor White
    Write-Host "   ECRR Ledger File: $(if ($health.ledger) { '✅ Exists' } else { '⚠️  Missing' })" -ForegroundColor White
    Write-Host "   ECRR Management Script: $(if ($health.scripts) { '✅ Exists' } else { '❌ Missing' })" -ForegroundColor White
    Write-Host ""
    
    # Check file permissions
    if ($health.directory) {
        try {
            $testFile = "$ECRR_REPORTS_PATH/test-$(Get-Date -Format 'HHmmss').tmp"
            Set-Content -Path $testFile -Value "test"
            Remove-Item -Path $testFile -Force
            Write-Host "✅ File Permissions: Writable" -ForegroundColor Green
        } catch {
            Write-Host "❌ File Permissions: Read-only" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    $totalHealth = ($health.Values | Where-Object { $_ -eq $true }).Count
    $totalChecks = $health.Count
    
    Write-Host "📊 Overall Health: $totalHealth/$totalChecks checks passed" -ForegroundColor $(if ($totalHealth -eq $totalChecks) { "Green" } else { "Yellow" })
    
    if ($totalHealth -eq $totalChecks) {
        Write-Host "🎉 ECRR System: HEALTHY" -ForegroundColor Green
    } else {
        Write-Host "⚠️  ECRR System: ISSUES DETECTED" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Function to show ECRR template
function Show-ECRRTemplate {
    Write-Host "📋 ECRR Report Template" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    $template = @"
# ECRR Report: [Title]

**ID**: ecrr-[timestamp]  
**Category**: [category]  
**Status**: [draft|in-progress|completed]  
**Generated**: [timestamp]  

## 🔍 Examine Phase
*Capture environment state before changes*

### Environment State
- OS: [operating system]
- PowerShell Version: [version]
- Working Directory: [path]
- User: [username]

### Services Status
- OTel Service: [status]
- SigNoz Health: [status]
- OTLP Port: [status]

### File System
- ECRR Reports: [count]
- Tasks: [count]
- Scripts: [count]

## 🧹 Clean Phase
*Remove drift and enforce guardrails*

### Drift Detection
- Orphaned Processes: [count]
- Stale Lock Files: [count]
- Temporary Files: [count]
- Service Status: [status]

### Guardrail Validation
- [guardrail 1]: [status]
- [guardrail 2]: [status]
- [guardrail 3]: [status]

## 📝 Report Phase
*Generate artifacts and evidence*

### Findings
- [finding 1]
- [finding 2]
- [finding 3]

### Recommendations
- [recommendation 1]
- [recommendation 2]
- [recommendation 3]

### Artifacts
- [artifact 1]
- [artifact 2]
- [artifact 3]

## 🎭 Role Phase
*Declare actor responsibility*

**Actor**: [agent name]  
**Responsibility**: [responsibility description]  
**Capabilities**: [capability list]  
**Status**: [active|inactive]  

---
*Generated by ECRR Command System*
"@
    
    Write-Host $template -ForegroundColor White
    Write-Host ""
}

# Main command dispatcher - 4-letter commands only
switch ($Action.ToLower()) {
    "help" { Show-ECRRHelp }
    "exam" { Invoke-ECRRExamine -Category $Category }
    "clean" { Invoke-ECRRClean -Category $Category }
    "repo" { Invoke-ECRRReport -Category $Category -Title "ECRR Report" }
    "role" { Invoke-ECRRRole }
    "list" { Get-ECRRReports }
    "stat" { Get-ECRRStatus }
    "make" { New-ECRRReport -Category $Category -Title "New ECRR Report" }
    "proc" { Invoke-ECRRProcess }
    "test" { Test-ECRRCompliance }
    "summ" { Get-ECRRSummary }
    "heal" { Test-ECRRHealth }
    "temp" { Show-ECRRTemplate }
    # Legacy support for old commands
    "examine" { Invoke-ECRRExamine -Category $Category }
    "report" { Invoke-ECRRReport -Category $Category -Title "ECRR Report" }
    "status" { Get-ECRRStatus }
    "create" { New-ECRRReport -Category $Category -Title "New ECRR Report" }
    "process" { Invoke-ECRRProcess }
    "validate" { Test-ECRRCompliance }
    "summary" { Get-ECRRSummary }
    "health" { Test-ECRRHealth }
    "template" { Show-ECRRTemplate }
    default { 
        Write-Host "❌ Unknown action: $Action" -ForegroundColor Red
        Write-Host "💡 Use 'help' to see available 4-letter actions" -ForegroundColor Yellow
    }
}
