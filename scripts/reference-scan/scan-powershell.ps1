# PowerShell Reference Scanner
# Phase 2.2: Scan for script calls and imports
param([string]$OutputFile = "artifacts/reference-scan/powershell-refs.csv")

Write-Host "📜 Scanning PowerShell files..." -ForegroundColor Cyan

$results = @()
$results += "Source,Target,Type,Pattern`n"

# Pattern 1: pwsh -File or powershell -File
git grep -n "pwsh.*-File\|powershell.*-File" -- "*.ps1" "*.psm1" 2>$null | ForEach-Object {
    if ($_ -match '^([^:]+):(\d+):.*(?:pwsh|powershell).*-File\s+([^\s]+\.ps1)') {
        $file = $matches[1]
        $line = $matches[2]
        $target = $matches[3] -replace '"','' -replace "'",''
        $results += "$file,$target,script-exec,$line`n"
    }
}

# Pattern 2: Dot sourcing (. script.ps1)
git grep -n '\.\s\+[^\s]*\.ps1' -- "*.ps1" "*.psm1" 2>$null | ForEach-Object {
    if ($_ -match '^([^:]+):(\d+):.*\.\s+([^\s]+\.ps1)') {
        $file = $matches[1]
        $line = $matches[2]
        $target = $matches[3] -replace '"','' -replace "'",''
        $results += "$file,$target,dot-source,$line`n"
    }
}

# Pattern 3: Import-Module
git grep -n "Import-Module" -- "*.ps1" "*.psm1" 2>$null | ForEach-Object {
    if ($_ -match '^([^:]+):(\d+):.*Import-Module\s+([^\s]+\.ps(?:m)?1)') {
        $file = $matches[1]
        $line = $matches[2]
        $target = $matches[3] -replace '"','' -replace "'",''
        $results += "$file,$target,import-module,$line`n"
    }
}

$results | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
$count = ($results.Count - 1)
Write-Host "  ✓ Found $count PowerShell references" -ForegroundColor Green
Write-Host "  📄 Saved to: $OutputFile" -ForegroundColor Gray

