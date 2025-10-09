# Markdown Reference Scanner
# Phase 2.6: Scan for internal file links
param([string]$OutputFile = "artifacts/reference-scan/markdown-refs.csv")

Write-Host "📝 Scanning Markdown files..." -ForegroundColor Cyan

$results = @()
$results += "Source,Target,Type,Pattern`n"

# Pattern: [text](path)
git grep -n '\[.*\](\..*\|[^http][^:]*\.(md|ps1|ts|js|py|yml|yaml|json))' -- "*.md" 2>$null | ForEach-Object {
    if ($_ -match '^([^:]+):(\d+):.*\[([^\]]+)\]\(([^\)]+)\)') {
        $file = $matches[1]
        $line = $matches[2]
        $linkText = $matches[3]
        $target = $matches[4]
        if ($target -notmatch '^http' -and $target -match '\.(md|ps1|ts|js|py|yml|yaml|json|sh)') {
            $results += "$file,$target,markdown-link,$line`n"
        }
    }
}

$results | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
$count = ($results.Count - 1)
Write-Host "  ✓ Found $count Markdown references" -ForegroundColor Green
Write-Host "  📄 Saved to: $OutputFile" -ForegroundColor Gray

