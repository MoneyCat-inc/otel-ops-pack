# Python Reference Scanner  
# Phase 2.3: Scan for import statements
param([string]$OutputFile = "artifacts/reference-scan/python-refs.csv")

Write-Host "🐍 Scanning Python files..." -ForegroundColor Cyan

$results = @()
$results += "Source,Target,Type,Pattern`n"

# Pattern 1: from X import Y
git grep -n "^from\s\+\w" -- "*.py" 2>$null | ForEach-Object {
    if ($_ -match '^([^:]+):(\d+):from\s+([\w\.]+)\s+import') {
        $file = $matches[1]
        $line = $matches[2]
        $target = $matches[3]
        # Skip standard library
        if ($target -notmatch '^(os|sys|json|re|datetime|pathlib|typing|logging|argparse|collections)') {
            $results += "$file,$target,from-import,$line`n"
        }
    }
}

# Pattern 2: import X
git grep -n "^import\s\+\w" -- "*.py" 2>$null | ForEach-Object {
    if ($_ -match '^([^:]+):(\d+):import\s+([\w\.]+)') {
        $file = $matches[1]
        $line = $matches[2]
        $target = $matches[3]
        # Skip standard library
        if ($target -notmatch '^(os|sys|json|re|datetime|pathlib|typing|logging|argparse|collections)') {
            $results += "$file,$target,import,$line`n"
        }
    }
}

$results | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
$count = ($results.Count - 1)
Write-Host "  ✓ Found $count Python references" -ForegroundColor Green
Write-Host "  📄 Saved to: $OutputFile" -ForegroundColor Gray

