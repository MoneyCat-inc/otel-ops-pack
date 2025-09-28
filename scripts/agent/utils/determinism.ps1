# scripts/agent/utils/determinism.ps1 - Deterministic environment validation

param(
    [string]$ExpectedNodeVersion = "22.18.0",
    [string]$ExpectedPnpmVersion = "10.15.1"
)

$ErrorActionPreference = "Stop"

function Test-NodeVersion {
    param(
        [string]$ExpectedVersion = "22.18.0",
        [string]$VersionFile = ".node-version"
    )
    
    try {
        # Check if version file exists
        if (Test-Path $VersionFile) {
            $fileVersion = Get-Content $VersionFile -Raw
            if ($fileVersion -and $fileVersion.Trim() -ne $ExpectedVersion) {
                Write-Warning "Node version file specifies $($fileVersion.Trim()) but expected $ExpectedVersion"
            }
        }
        
        # Get current Node version
        $nodeVersion = node --version 2>$null
        if (-not $nodeVersion) {
            return @{
                valid = $false
                reason = "Node.js not found"
                current = $null
                expected = $ExpectedVersion
            }
        }
        
        # Remove 'v' prefix if present
        $nodeVersion = $nodeVersion -replace '^v', ''
        
        # Check major.minor version match
        $currentMajorMinor = ($nodeVersion -split '\.')[0..1] -join '.'
        $expectedMajorMinor = ($ExpectedVersion -split '\.')[0..1] -join '.'
        
        if ($currentMajorMinor -eq $expectedMajorMinor) {
            return @{
                valid = $true
                reason = "Version compatible"
                current = $nodeVersion
                expected = $ExpectedVersion
            }
        }
        
        return @{
            valid = $false
            reason = "Version mismatch: major.minor version differs"
            current = $nodeVersion
            expected = $ExpectedVersion
        }
    } catch {
        return @{
            valid = $false
            reason = "Error checking Node version: $($_.Exception.Message)"
            current = $null
            expected = $ExpectedVersion
        }
    }
}

function Test-PnpmVersion {
    param(
        [string]$ExpectedVersion = "9.0.0"
    )
    
    try {
        $pnpmVersion = pnpm --version 2>$null
        if (-not $pnpmVersion) {
            return @{
                valid = $false
                reason = "pnpm not found"
                current = $null
                expected = $ExpectedVersion
            }
        }
        
        # Check major version match
        $currentMajor = ($pnpmVersion -split '\.')[0]
        $expectedMajor = ($ExpectedVersion -split '\.')[0]
        
        if ($currentMajor -eq $expectedMajor) {
            return @{
                valid = $true
                reason = "Version compatible"
                current = $pnpmVersion
                expected = $ExpectedVersion
            }
        }
        
        return @{
            valid = $false
            reason = "Version mismatch: major version differs"
            current = $pnpmVersion
            expected = $ExpectedVersion
        }
    } catch {
        return @{
            valid = $false
            reason = "Error checking pnpm version: $($_.Exception.Message)"
            current = $null
            expected = $ExpectedVersion
        }
    }
}

function Test-PowerShellVersion {
    param(
        [int]$MinMajorVersion = 7
    )
    
    try {
        $psVersion = $PSVersionTable.PSVersion
        $majorVersion = $psVersion.Major
        
        if ($majorVersion -ge $MinMajorVersion) {
            return @{
                valid = $true
                reason = "Version compatible"
                current = $psVersion.ToString()
                expected = "PowerShell $MinMajorVersion+"
            }
        }
        
        return @{
            valid = $false
            reason = "Version too old"
            current = $psVersion.ToString()
            expected = "PowerShell $MinMajorVersion+"
        }
    } catch {
        return @{
            valid = $false
            reason = "Error checking PowerShell version: $($_.Exception.Message)"
            current = $null
            expected = "PowerShell $MinMajorVersion+"
        }
    }
}

function Test-EnvironmentDeterminism {
    param(
        [string]$ExpectedNodeVersion = "22.18.0",
        [string]$ExpectedPnpmVersion = "9.0.0"
    )
    
    $results = @{
        node = Test-NodeVersion -ExpectedVersion $ExpectedNodeVersion
        pnpm = Test-PnpmVersion -ExpectedVersion $ExpectedPnpmVersion
        powershell = Test-PowerShellVersion
        overall = $true
        issues = @()
    }
    
    # Check overall validity
    if (-not $results.node.valid) {
        $results.overall = $false
        $results.issues += "Node.js: $($results.node.reason)"
    }
    
    if (-not $results.pnpm.valid) {
        $results.overall = $false
        $results.issues += "pnpm: $($results.pnpm.reason)"
    }
    
    if (-not $results.powershell.valid) {
        $results.overall = $false
        $results.issues += "PowerShell: $($results.powershell.reason)"
    }
    
    return $results
}

function Write-EnvironmentReport {
    param(
        [object]$EnvironmentResults
    )
    
    Write-Host "🔧 Environment Determinism Report" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    # Node.js
    $nodeColor = if ($EnvironmentResults.node.valid) { "Green" } else { "Red" }
    Write-Host "Node.js: $($EnvironmentResults.node.current)" -ForegroundColor $nodeColor
    Write-Host "  Expected: $($EnvironmentResults.node.expected)" -ForegroundColor Gray
    Write-Host "  Status: $($EnvironmentResults.node.reason)" -ForegroundColor Gray
    
    # pnpm
    $pnpmColor = if ($EnvironmentResults.pnpm.valid) { "Green" } else { "Red" }
    Write-Host "pnpm: $($EnvironmentResults.pnpm.current)" -ForegroundColor $pnpmColor
    Write-Host "  Expected: $($EnvironmentResults.pnpm.expected)" -ForegroundColor Gray
    Write-Host "  Status: $($EnvironmentResults.pnpm.reason)" -ForegroundColor Gray
    
    # PowerShell
    $psColor = if ($EnvironmentResults.powershell.valid) { "Green" } else { "Red" }
    Write-Host "PowerShell: $($EnvironmentResults.powershell.current)" -ForegroundColor $psColor
    Write-Host "  Expected: $($EnvironmentResults.powershell.expected)" -ForegroundColor Gray
    Write-Host "  Status: $($EnvironmentResults.powershell.reason)" -ForegroundColor Gray
    
    # Overall status
    $overallColor = if ($EnvironmentResults.overall) { "Green" } else { "Red" }
    Write-Host "`nOverall: " -NoNewline
    Write-Host $(if ($EnvironmentResults.overall) { "PASS" } else { "FAIL" }) -ForegroundColor $overallColor
    
    if ($EnvironmentResults.issues.Count -gt 0) {
        Write-Host "`nIssues:" -ForegroundColor Yellow
        foreach ($issue in $EnvironmentResults.issues) {
            Write-Host "  • $issue" -ForegroundColor Yellow
        }
    }
    
    return $EnvironmentResults.overall
}

# Main execution if run directly
if ($MyInvocation.InvocationName -ne '.') {
    $results = Test-EnvironmentDeterminism -ExpectedNodeVersion $ExpectedNodeVersion -ExpectedPnpmVersion $ExpectedPnpmVersion
    $success = Write-EnvironmentReport -EnvironmentResults $results
    exit $(if ($success) { 0 } else { 1 })
}
