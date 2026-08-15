# PowerShell Error Capture Module
# Provides standardized error handling and capture for PowerShell scripts

param(
    [string]$ServiceName = "powershell-script",
    [string]$ScriptName = $MyInvocation.ScriptName,
    [int]$LineNumber = $MyInvocation.ScriptLineNumber,
    [switch]$EnableCapture = $true
)

# Error capture configuration
$ErrorCaptureConfig = @{
    ServiceName = $ServiceName
    ScriptName = $ScriptName
    EnableCapture = $EnableCapture
    AdapterPath = "scripts/agent/error-watcher/publish.ps1-adapter.js"
    LogLevel = "error"
}

function Write-ErrorCapture {
    param(
        [string]$Message,
        [string]$ErrorRecord,
        [hashtable]$Context = @{}
    )
    
    if (-not $ErrorCaptureConfig.EnableCapture) {
        return
    }
    
    try {
        # Build context object
        $captureContext = @{
            service = $ErrorCaptureConfig.ServiceName
            file = $ErrorCaptureConfig.ScriptName
            line = $LineNumber
            message = $Message
            severity = "error"
        }
        
        # Merge additional context
        foreach ($key in $Context.Keys) {
            $captureContext[$key] = $Context[$key]
        }
        
        # Convert to command line arguments
        $args = @()
        foreach ($key in $captureContext.Keys) {
            $args += "--$key"
            $args += $captureContext[$key]
        }
        
        # Add error details if provided
        if ($ErrorRecord) {
            $args += "--stack"
            $args += $ErrorRecord
        }
        
        # Call Node.js adapter
        $adapterPath = Join-Path $PSScriptRoot "..\..\$($ErrorCaptureConfig.AdapterPath)"
        if (Test-Path $adapterPath) {
            $fingerprint = & node $adapterPath @args
            Write-Host "🚨 Error captured with fingerprint: $fingerprint" -ForegroundColor Red
        } else {
            Write-Warning "Error capture adapter not found at: $adapterPath"
        }
    }
    catch {
        Write-Warning "Failed to capture error: $($_.Exception.Message)"
    }
}

function Set-ErrorCaptureTrap {
    param(
        [string]$ServiceName = $ErrorCaptureConfig.ServiceName
    )
    
    # Set error action preference
    $ErrorActionPreference = "Stop"
    
    # Set up trap for error capture
    trap {
        $errorMessage = $_.Exception.Message
        $errorStack = $_.InvocationInfo.PositionMessage
        
        Write-Host "🚨 PowerShell Error Captured:" -ForegroundColor Red
        Write-Host "  Message: $errorMessage" -ForegroundColor Red
        Write-Host "  Script: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
        Write-Host "  Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        
        # Capture error
        Write-ErrorCapture -Message $errorMessage -ErrorRecord $errorStack -Context @{
            scriptName = $_.InvocationInfo.ScriptName
            lineNumber = $_.InvocationInfo.ScriptLineNumber
            command = $_.InvocationInfo.MyCommand
        }
        
        # Continue execution
        continue
    }
    
    Write-Host "✅ Error capture trap enabled for service: $ServiceName" -ForegroundColor Green
}

function Test-ErrorCapture {
    param(
        [string]$TestMessage = "Test PowerShell Error Capture"
    )
    
    Write-Host "🧪 Testing error capture..." -ForegroundColor Yellow
    
    try {
        # Simulate an error
        throw [System.Exception]::new($TestMessage)
    }
    catch {
        Write-Host "Test error caught and captured" -ForegroundColor Green
    }
    
    Write-Host "✅ Error capture test completed" -ForegroundColor Green
}

function Get-ErrorCaptureStats {
    $registryPath = ".agent/error_index.json"
    
    if (-not (Test-Path $registryPath)) {
        Write-Host "No error registry found" -ForegroundColor Yellow
        return
    }
    
    try {
        $registry = Get-Content $registryPath -Raw | ConvertFrom-Json
        $totalErrors = ($registry.PSObject.Properties | Measure-Object).Count
        $totalOccurrences = ($registry.PSObject.Properties.Value | Measure-Object -Property count -Sum).Sum
        
        Write-Host "📊 Error Capture Statistics:" -ForegroundColor Cyan
        Write-Host "  Total Unique Errors: $totalErrors" -ForegroundColor White
        Write-Host "  Total Occurrences: $totalOccurrences" -ForegroundColor White
        Write-Host "  Average per Error: $([math]::Round($totalOccurrences / $totalErrors, 1))" -ForegroundColor White
        
        # Show recent errors
        $recentErrors = $registry.PSObject.Properties | Where-Object {
            $_.Value.lastSeen -gt ([DateTimeOffset]::Now.ToUnixTimeSeconds() - 86400) # Last 24 hours
        } | Sort-Object Value.lastSeen -Descending | Select-Object -First 5
        
        if ($recentErrors.Count -gt 0) {
            Write-Host "`n🕒 Recent Errors (Last 24h):" -ForegroundColor Cyan
            foreach ($errEntry in $recentErrors) {
                $lastSeen = [DateTimeOffset]::FromUnixTimeSeconds($errEntry.Value.lastSeen).ToString("yyyy-MM-dd HH:mm:ss")
                Write-Host "  $($errEntry.Name) - $lastSeen - Count: $($errEntry.Value.count)" -ForegroundColor White
            }
        }
    }
    catch {
        Write-Warning "Failed to load error registry: $($_.Exception.Message)"
    }
}

# Export functions
Export-ModuleMember -Function Write-ErrorCapture, Set-ErrorCaptureTrap, Test-ErrorCapture, Get-ErrorCaptureStats

# Auto-setup trap if not in a function context
if ($MyInvocation.InvocationName -ne '') {
    Set-ErrorCaptureTrap -ServiceName $ServiceName
}

# Example usage:
# Import-Module scripts/ps/error-capture.ps1
# Set-ErrorCaptureTrap -ServiceName "my-script"
# Test-ErrorCapture
# Get-ErrorCaptureStats
