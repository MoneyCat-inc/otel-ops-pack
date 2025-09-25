# IONA Error Export Script
# Exports error ledger to JSON format for dashboard integration and analytics

param(
    [string]$OutputPath = "C:\otel\artifacts\iona-errors.json",
    [switch]$IncludeResolved,
    [switch]$IncludeOpenOnly,
    [string]$DateFilter = "",
    [string]$TypeFilter = "",
    [switch]$PrettyPrint
)

# Configuration
$ErrorLedgerPath = "C:\otel\iona\IONA_ERRORS.md"

# Check if ledger exists
if (-not (Test-Path $ErrorLedgerPath)) {
    Write-Host "❌ Error ledger not found at: $ErrorLedgerPath" -ForegroundColor Red
    Write-Host "Please ensure IONA_ERRORS.md exists in the IONA directory." -ForegroundColor Yellow
    exit 1
}

# Read ledger content
$LedgerContent = Get-Content $ErrorLedgerPath -Raw

# Parse entries using regex
$EntryPattern = "### Entry (\d{4}-\d{2}-\d{2}-\d{4})\s*\n\s*\*\*Type\*\*: (.+?)\n\s*\*\*Context\*\*: (.+?)\n\s*\*\*Impact\*\*: (.+?)\n\s*\*\*Resolution\*\*: (.+?)\n\s*\*\*Status\*\*: (.+?)\n\s*\*\*Evidence\*\*: (.+?)(?=\n\n|\Z)"
$Matches = [regex]::Matches($LedgerContent, $EntryPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

# Initialize export data
$ExportData = @{
    metadata = @{
        exportDate = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        totalEntries = $Matches.Count
        sourceFile = $ErrorLedgerPath
        filters = @{
            includeResolved = $IncludeResolved
            includeOpenOnly = $IncludeOpenOnly
            dateFilter = $DateFilter
            typeFilter = $TypeFilter
        }
    }
    entries = @()
    statistics = @{}
}

# Process each entry
$ProcessedEntries = 0
foreach ($Match in $Matches) {
    $EntryId = $Match.Groups[1].Value
    $Type = $Match.Groups[2].Value.Trim()
    $Context = $Match.Groups[3].Value.Trim()
    $Impact = $Match.Groups[4].Value.Trim()
    $Resolution = $Match.Groups[5].Value.Trim()
    $Status = $Match.Groups[6].Value.Trim()
    $Evidence = $Match.Groups[7].Value.Trim()
    
    # Parse entry date
    $EntryDate = $EntryId.Substring(0, 10)  # YYYY-MM-DD part
    
    # Apply filters
    if ($DateFilter -and $EntryDate -ne $DateFilter) { continue }
    if ($TypeFilter -and $Type -ne $TypeFilter) { continue }
    
    # Status filtering
    $IsResolved = $Status -match "✅ Fixed"
    $IsOpen = $Status -match "🚧 Pending verification|🔄 In Progress"
    
    if ($IncludeOpenOnly -and -not $IsOpen) { continue }
    if (-not $IncludeResolved -and $IsResolved) { continue }
    
    # Create entry object
    $Entry = @{
        id = $EntryId
        date = $EntryDate
        type = $Type
        context = $Context
        impact = $Impact
        resolution = $Resolution
        status = $Status
        evidence = $Evidence
        isResolved = $IsResolved
        isOpen = $IsOpen
    }
    
    $ExportData.entries += $Entry
    $ProcessedEntries++
}

# Calculate statistics
$TotalEntries = $ExportData.entries.Count
$ResolvedEntries = ($ExportData.entries | Where-Object { $_.isResolved }).Count
$OpenEntries = ($ExportData.entries | Where-Object { $_.isOpen }).Count

$ExportData.statistics = @{
    total = $TotalEntries
    resolved = $ResolvedEntries
    open = $OpenEntries
    resolutionRate = if ($TotalEntries -gt 0) { [math]::Round(($ResolvedEntries / $TotalEntries) * 100, 2) } else { 0 }
    byType = @{}
    byStatus = @{}
}

# Group by type
$TypeGroups = $ExportData.entries | Group-Object type
foreach ($Group in $TypeGroups) {
    $ExportData.statistics.byType[$Group.Name] = $Group.Count
}

# Group by status
$StatusGroups = $ExportData.entries | Group-Object status
foreach ($Group in $StatusGroups) {
    $ExportData.statistics.byStatus[$Group.Name] = $Group.Count
}

# Convert to JSON
$JsonOptions = if ($PrettyPrint) { 
    [System.Web.Script.Serialization.JavaScriptSerializer]::new() 
} else { 
    $null 
}

if ($PrettyPrint) {
    $JsonContent = $ExportData | ConvertTo-Json -Depth 10
} else {
    $JsonContent = $ExportData | ConvertTo-Json -Depth 10 -Compress
}

# Ensure output directory exists
$OutputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Write JSON file
try {
    $JsonContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✅ Error data exported successfully!" -ForegroundColor Green
    Write-Host "   Output: $OutputPath" -ForegroundColor Cyan
    Write-Host "   Entries processed: $ProcessedEntries" -ForegroundColor Cyan
    Write-Host "   Total entries: $TotalEntries" -ForegroundColor Cyan
    Write-Host "   Resolved: $ResolvedEntries" -ForegroundColor Cyan
    Write-Host "   Open: $OpenEntries" -ForegroundColor Cyan
    Write-Host "   Resolution rate: $($ExportData.statistics.resolutionRate)%" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Failed to write JSON file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Display summary
Write-Host "`n📊 Export Summary:" -ForegroundColor Yellow
Write-Host "   Resolution Rate: $($ExportData.statistics.resolutionRate)%" -ForegroundColor White
if ($ExportData.statistics.byType.Count -gt 0) {
    Write-Host "   By Type:" -ForegroundColor White
    foreach ($Type in $ExportData.statistics.byType.Keys) {
        Write-Host "     $Type`: $($ExportData.statistics.byType[$Type])" -ForegroundColor White
    }
}

Write-Host "`n🔗 JSON file ready for dashboard integration: $OutputPath" -ForegroundColor Green
