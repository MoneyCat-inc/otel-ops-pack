# Test SigNoz Query Syntax
# Helps verify correct query syntax before creating alerts

param(
    [string]$QueryType = "windows-canary",
    [switch]$TestAll = $false
)

# ECRR - Examine → Clean → Report → Role
Write-Host "🔍 Test SigNoz Query Syntax - ECRR Framework" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

Write-Host "`n📊 SigNoz Query Syntax Testing" -ForegroundColor Green

# Define test queries
$TestQueries = @{
    "windows-canary" = @{
        name = "Windows Canary Logs"
        description = "Test query for Windows canary log detection"
        queries = @(
            "log.file.path contains `"windows-canary-test.log`" AND body contains `"windows-canary`"",
            "log.source = `"filelog`" AND log.file.path contains `"windows-canary-test.log`" AND body contains `"windows-canary`"",
            "(log.source = `"windows_event_log`" AND body contains `"windows-canary`") OR (log.file.path contains `"windows-canary-test.log`" AND body contains `"windows-canary`")"
        )
    }
    "hurst-exponent" = @{
        name = "Hurst Exponent Drift"
        description = "Test query for Hurst exponent monitoring"
        queries = @(
            "message contains `"hurst_estimate`" AND log.file.path contains `"canary-pattern-results.json`"",
            "body contains `"hurst_estimate`" AND log.file.path contains `"canary-pattern-results.json`"",
            "attributes.hurst_estimate exists"
        )
    }
    "pattern-analysis" = @{
        name = "Pattern Analysis"
        description = "Test query for pattern drill analysis"
        queries = @(
            "message contains `"windows-canary`" AND attributes.pattern exists",
            "body contains `"windows-canary`" AND attributes.pattern in [`"steady`", `"poisson`", `"pareto`"]",
            "log.file.path contains `"canary-`" AND body contains `"windows-canary`""
        )
    }
    "enhanced-validation" = @{
        name = "Enhanced Statistical Validation"
        description = "Test query for enhanced validation results"
        queries = @(
            "message contains `"enhanced_statistical_validation`" AND log.file.path contains `"enhanced-statistical-validation.json`"",
            "body contains `"coefficient_of_variation`" AND log.file.path contains `"enhanced-statistical-validation.json`"",
            "attributes.confidence_interval exists"
        )
    }
}

function Test-Query {
    param(
        [string]$QueryName,
        [string]$Query,
        [string]$Description
    )
    
    Write-Host "`n🧪 Testing: $QueryName" -ForegroundColor Yellow
    Write-Host "  Query: $Query" -ForegroundColor Cyan
    Write-Host "  Description: $Description" -ForegroundColor Gray
    
    # Basic syntax validation
    $SyntaxValid = $true
    $SyntaxErrors = @()
    
    # Check for common syntax errors
    if ($Query -match "\|") {
        $SyntaxValid = $false
        $SyntaxErrors += "Contains '|' - SigNoz doesn't use pipe syntax"
    }
    
    if ($Query -match "stats\s+count\(\)") {
        $SyntaxValid = $false
        $SyntaxErrors += "Contains 'stats count()' - Use UI grouping instead"
    }
    
    if ($Query -match "by\s+bin\(") {
        $SyntaxValid = $false
        $SyntaxErrors += "Contains 'by bin()' - Use UI time grouping instead"
    }
    
    if ($Query -match "=\s*'[^']*'") {
        $SyntaxValid = $false
        $SyntaxErrors += "Uses single quotes - Use double quotes for strings"
    }
    
    if ($Query -match "=\s*'[^']*'") {
        $Query = $Query -replace "=\s*'([^']*)'", "contains `"`$1`""
        Write-Host "  🔧 Auto-fixed single quotes to double quotes with 'contains'" -ForegroundColor Green
    }
    
    # Display results
    if ($SyntaxValid) {
        Write-Host "  ✅ Syntax appears valid" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Syntax errors detected:" -ForegroundColor Red
        foreach ($syntaxError in $SyntaxErrors) {
            Write-Host "    - $syntaxError" -ForegroundColor Red
        }
    }
    
    Write-Host "  📋 Recommended for SigNoz UI:" -ForegroundColor Cyan
    Write-Host "    Query: $Query" -ForegroundColor White
    
    return @{
        query = $Query
        valid = $SyntaxValid
        errors = $SyntaxErrors
    }
}

# Test queries based on type
if ($TestAll) {
    Write-Host "`n🚀 Testing All Query Types" -ForegroundColor Green
    
    foreach ($Type in $TestQueries.Keys) {
        $QuerySet = $TestQueries[$Type]
        Write-Host "`n📊 $($QuerySet.name)" -ForegroundColor Magenta
        Write-Host "  $($QuerySet.description)" -ForegroundColor Gray
        
        foreach ($Query in $QuerySet.queries) {
            Test-Query -QueryName "Query $($QuerySet.queries.IndexOf($Query) + 1)" -Query $Query -Description $QuerySet.description
        }
    }
} else {
    if ($TestQueries.ContainsKey($QueryType)) {
        $QuerySet = $TestQueries[$QueryType]
        Write-Host "`n📊 Testing: $($QuerySet.name)" -ForegroundColor Magenta
        Write-Host "  $($QuerySet.description)" -ForegroundColor Gray
        
        foreach ($Query in $QuerySet.queries) {
            Test-Query -QueryName "Query $($QuerySet.queries.IndexOf($Query) + 1)" -Query $Query -Description $QuerySet.description
        }
    } else {
        Write-Host "❌ Unknown query type: $QueryType" -ForegroundColor Red
        Write-Host "Available types: $($TestQueries.Keys -join ', ')" -ForegroundColor Yellow
        exit 1
    }
}

# Generate summary
Write-Host "`n📋 Query Testing Summary" -ForegroundColor Green
Write-Host "Query Type: $QueryType" -ForegroundColor Cyan

if ($TestAll) {
    Write-Host "Total Query Sets: $($TestQueries.Count)" -ForegroundColor White
    $TotalQueries = ($TestQueries.Values | ForEach-Object { $_.queries.Count } | Measure-Object -Sum).Sum
    Write-Host "Total Queries Tested: $TotalQueries" -ForegroundColor White
} else {
    $QuerySet = $TestQueries[$QueryType]
    Write-Host "Queries Tested: $($QuerySet.queries.Count)" -ForegroundColor White
}

Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Copy the recommended queries above" -ForegroundColor White
Write-Host "2. Test them in SigNoz UI: Logs → Explore" -ForegroundColor White
Write-Host "3. Verify they return expected results" -ForegroundColor White
Write-Host "4. Use the working query for your alert" -ForegroundColor White

Write-Host "`n📖 Reference:" -ForegroundColor Cyan
Write-Host "  Syntax Fix Guide: docs/SIGNOZ_QUERY_SYNTAX_FIX.md" -ForegroundColor White
Write-Host "  Alert Import Guide: docs/SIGNOZ_ALERT_IMPORT_GUIDE.md" -ForegroundColor White

Write-Host "`n🎭 Role: Cursor-Local (Observability Copilot) - Query Syntax Testing Complete" -ForegroundColor Magenta
