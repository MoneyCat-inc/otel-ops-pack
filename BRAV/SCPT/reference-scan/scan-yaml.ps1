# YAML Reference Scanner
# Phase 2.4: Scan for file paths in YAML configs
param([string]$OutputFile = "artifacts/reference-scan/yaml-refs.csv")

Write-Host "📋 Scanning YAML files..." -ForegroundColor Cyan

$results = @()
$results += "Source,Target,Type,Pattern`n"

# Pattern: quoted paths starting with . or containing /
git grep -n '["' + "'" + ']\.\./\|["' + "'" + ']\./\|["' + "'" + '][^"' + "'" + ']*/' -- "*.yml" "*.yaml" 2>$null | ForEach-Object {
    if ($_ -match '^([^:]+):(\d+):.*[' + "'" + '"]([\.\/][^' + "'" + '"]+)[' + "'" + '"]') {
        $file = $matches[1]
        $line = $matches[2]
        $target = $matches[3]
        if ($target -match '\.(ps1|ts|js|py|sh|yml|yaml|json|md)') {
            $results += "$file,$target,config-path,$line`n"
        }
    }
}

$results | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
$count = ($results.Count - 1)
Write-Host "  ✓ Found $count YAML references" -ForegroundColor Green
Write-Host "  📄 Saved to: $OutputFile" -ForegroundColor Gray

