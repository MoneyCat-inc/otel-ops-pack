# Pre-commit hook for PowerShell Script Analyzer
param(
    [Parameter(ValueFromPipeline = $true)]
    [string[]]$Files
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Install PSScriptAnalyzer if not available
if (!(Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
}

$exitCode = 0

foreach ($file in $Files) {
    if (Test-Path $file) {
        Write-Host ("Analyzing {0}..." -f $file) -ForegroundColor Cyan

        $results = Invoke-ScriptAnalyzer -Path $file -Severity Error, Warning

        if ($results) {
            Write-Host ("Issues found in {0}:" -f $file) -ForegroundColor Red
            $results | ForEach-Object {
                Write-Host "  Line $($_.Line): $($_.Message)" -ForegroundColor Red
            }
            $exitCode = 1
        } else {
            Write-Host ("{0} passed analysis" -f $file) -ForegroundColor Green
        }
    }
}

exit $exitCode
