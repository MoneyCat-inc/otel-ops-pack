# IONA Error Logging Helper Script
# Automatically appends new entries to IONA_ERRORS.md ledger

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Usage Error", "System Error", "Guardrail Violation")]
    [string]$Type,
    
    [Parameter(Mandatory=$true)]
    [string]$Context,
    
    [Parameter(Mandatory=$true)]
    [string]$Impact,
    
    [Parameter(Mandatory=$true)]
    [string]$Resolution,
    
    [string]$Evidence = "N/A",
    
    [ValidateSet("🚧 Pending verification", "✅ Fixed", "🔄 In Progress", "❌ Failed")]
    [string]$Status = "🚧 Pending verification"
)

# Configuration
$ErrorLedgerPath = "C:\otel\iona\IONA_ERRORS.md"
$MaxEntriesPerPass = 10

# Generate unique ID based on timestamp
$Timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$EntryId = "$(Get-Date -Format 'yyyy-MM-dd')-$(Get-Date -Format 'HHmm')"

# Create new entry content
$NewEntry = @"

### Entry $EntryId

* **Type**: $Type
* **Context**: $Context
* **Impact**: $Impact
* **Resolution**: $Resolution
* **Status**: $Status
* **Evidence**: $Evidence

"@

# Check if ledger exists
if (-not (Test-Path $ErrorLedgerPath)) {
    Write-Host "❌ Error ledger not found at: $ErrorLedgerPath" -ForegroundColor Red
    Write-Host "Please ensure IONA_ERRORS.md exists in the IONA directory." -ForegroundColor Yellow
    exit 1
}

# Read current ledger content
$LedgerContent = Get-Content $ErrorLedgerPath -Raw

# Count current entries
$EntryCount = ([regex]::Matches($LedgerContent, "### Entry \d{4}-\d{2}-\d{2}-\d{4}")).Count

# Check entry limit
if ($EntryCount -ge $MaxEntriesPerPass) {
    Write-Host "⚠️  Warning: Entry limit reached ($MaxEntriesPerPass entries per pass)" -ForegroundColor Yellow
    Write-Host "Consider resolving some entries before adding new ones." -ForegroundColor Yellow
    $Confirm = Read-Host "Continue anyway? (y/N)"
    if ($Confirm -ne "y" -and $Confirm -ne "Y") {
        Write-Host "❌ Entry logging cancelled." -ForegroundColor Red
        exit 0
    }
}

# Find insertion point (before the statistics section)
$StatisticsPattern = "## 📊 Error Statistics"
$InsertionPoint = $LedgerContent.IndexOf($StatisticsPattern)

if ($InsertionPoint -eq -1) {
    # If no statistics section, append to end
    $NewContent = $LedgerContent + $NewEntry
} else {
    # Insert before statistics section
    $NewContent = $LedgerContent.Substring(0, $InsertionPoint) + $NewEntry + $LedgerContent.Substring($InsertionPoint)
}

# Update statistics
$NewEntryCount = $EntryCount + 1
$StatisticsSection = @"

## 📊 Error Statistics

**Total Entries**: $NewEntryCount  
**Open Issues**: $(($NewContent | Select-String "🚧 Pending verification|🔄 In Progress").Matches.Count)  
**Resolved Issues**: $(($NewContent | Select-String "✅ Fixed").Matches.Count)  
**Last Updated**: $(Get-Date -Format "yyyy-MM-dd")

"@

# Replace statistics section
$StatisticsPattern = "## 📊 Error Statistics.*?Last Updated.*?\n"
$NewContent = $NewContent -replace $StatisticsPattern, $StatisticsSection

# Write updated content
try {
    $NewContent | Out-File -FilePath $ErrorLedgerPath -Encoding UTF8
    Write-Host "✅ Error entry logged successfully!" -ForegroundColor Green
    Write-Host "   Entry ID: $EntryId" -ForegroundColor Cyan
    Write-Host "   Type: $Type" -ForegroundColor Cyan
    Write-Host "   Status: $Status" -ForegroundColor Cyan
    Write-Host "   Total entries: $NewEntryCount" -ForegroundColor Cyan
    
    # Emit metrics to SigNoz
    $MetricsScript = Join-Path $PSScriptRoot "emit-signoz-metrics.ps1"
    if (Test-Path $MetricsScript) {
        try {
            # Emit error count metric
            & $MetricsScript -MetricType "counter" -MetricName "iona.errors.total" -MetricValue $NewEntryCount -Labels @{
                "error.type" = $Type
                "error.status" = $Status
            } -Verbose:$false
            
            # Emit resolution rate metric
            $ResolvedCount = ($NewContent | Select-String "✅ Fixed").Matches.Count
            $ResolutionRate = if ($NewEntryCount -gt 0) { [math]::Round(($ResolvedCount / $NewEntryCount) * 100, 2) } else { 0 }
            
            & $MetricsScript -MetricType "gauge" -MetricName "iona.errors.resolution_rate" -MetricValue $ResolutionRate -Labels @{
                "metric.type" = "percentage"
            } -Verbose:$false
            
            Write-Host "📊 Metrics emitted to SigNoz" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Failed to emit metrics: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Emit trace spans to SigNoz
    $TracesScript = Join-Path $PSScriptRoot "emit-signoz-traces.ps1"
    if (Test-Path $TracesScript) {
        try {
            # Emit error creation trace
            $TraceResult = & $TracesScript -TraceName "iona.error.created" -ErrorId $EntryId -LifecycleStage "created" -Attributes @{
                "error.type" = $Type
                "error.context" = $Context
                "error.impact" = $Impact
                "error.resolution" = $Resolution
                "error.status" = $Status
                "error.evidence" = $Evidence
            } -Verbose:$false
            
            if ($TraceResult.Success) {
                Write-Host "🔍 Trace emitted to SigNoz (ID: $($TraceResult.TraceId))" -ForegroundColor Green
            }
        } catch {
            Write-Host "⚠️  Failed to emit trace: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Emit structured logs to SigNoz
    $LogsScript = Join-Path $PSScriptRoot "emit-signoz-logs.ps1"
    if (Test-Path $LogsScript) {
        try {
            # Emit error creation log
            $LogLevel = switch ($Type) {
                "Guardrail Violation" { "WARN" }
                "System Error" { "ERROR" }
                "Usage Error" { "INFO" }
                default { "INFO" }
            }
            
            $LogMessage = "IONA Error Created: $Type - $Context"
            
            $LogResult = & $LogsScript -LogLevel $LogLevel -LogMessage $LogMessage -ErrorId $EntryId -LogEvent "error.created" -Attributes @{
                "error.type" = $Type
                "error.context" = $Context
                "error.impact" = $Impact
                "error.resolution" = $Resolution
                "error.status" = $Status
                "error.evidence" = $Evidence
                "error.total_count" = $NewEntryCount
            } -Verbose:$false
            
            if ($LogResult) {
                Write-Host "📝 Log emitted to SigNoz" -ForegroundColor Green
            }
        } catch {
            Write-Host "⚠️  Failed to emit log: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "❌ Failed to write to error ledger: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Display the new entry
Write-Host "`n📝 New Entry Added:" -ForegroundColor Yellow
Write-Host $NewEntry -ForegroundColor White

Write-Host "`n🔗 Error ledger updated: $ErrorLedgerPath" -ForegroundColor Green
