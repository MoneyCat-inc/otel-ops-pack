# TypeScript/JavaScript Reference Scanner
# Phase 2.1: Scan for import/require statements
param([string]$OutputFile = "artifacts/reference-scan/typescript-refs.csv")

Write-Host "📘 Scanning TypeScript/JavaScript files..." -ForegroundColor Cyan

# Use git grep for speed and reliability
$results = @()
$results += "Source,Target,Type,Pattern`n"

# Pattern 1: import from
git grep -n "import.*from\s*['\`"]" -- "*.ts" "*.tsx" "*.js" "*.jsx" "*.mjs" 2>$null | ForEach-Object {
    if ($_ -match '^([^:]+):(\d+):.*from\s*[' + "'" + '"`]([^' + "'" + '"`]+)[' + "'" + '"`]') {
        $file = $matches[1]
        $line = $matches[2]
        $target = $matches[3]
        if ($target -match '^\.' -or $target -match '^@/') {
            $results += "$file,$target,import-from,$line`n"
        }
    }
}

# Pattern 2: require()
git grep -n "require\s*\(['\`"]" -- "*.ts" "*.tsx" "*.js" "*.jsx" "*.mjs" 2>$null | ForEach-Object {
    if ($_ -match '^([^:]+):(\d+):.*require\s*\([' + "'" + '"`]([^' + "'" + '"`]+)[' + "'" + '"`]\)') {
        $file = $matches[1]
        $line = $matches[2]
        $target = $matches[3]
        if ($target -match '^\.' -or $target -match '^@/') {
            $results += "$file,$target,require,$line`n"
        }
    }
}

$results | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
$count = ($results.Count - 1)
Write-Host "  ✓ Found $count TypeScript/JavaScript references" -ForegroundColor Green
Write-Host "  📄 Saved to: $OutputFile" -ForegroundColor Gray

