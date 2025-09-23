$ErrorActionPreference = 'Stop'

# Creates .tmp/sanity-violations.txt with files that have UTF-8 BOM or smart quotes
# Usage: pwsh -File scripts/sanity-scan.ps1

function Get-GitFilesNullSeparated {
    $output = & git ls-files -z 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'git ls-files failed. Ensure you are in a git repository.'
    }
    return $output -split "`0"
}

New-Item -ItemType Directory -Force -Path .tmp | Out-Null

$badFiles = New-Object System.Collections.Generic.List[string]

$files = Get-GitFilesNullSeparated | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
foreach ($p in $files) {
    if (-not (Test-Path -LiteralPath $p)) { continue }
    try {
        $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $p))
    } catch { continue }

    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    try {
        $text = Get-Content -LiteralPath $p -Raw -ErrorAction Stop
    } catch { $text = '' }

    if ($hasBom -or ($text -match "[\u2018\u2019\u201C\u201D]")) {
        [void]$badFiles.Add($p)
    }
}

$badSorted = $badFiles | Sort-Object -Unique
$outPath = '.tmp/sanity-violations.txt'
$badSorted | Set-Content -LiteralPath $outPath -Encoding utf8

Write-Host ("Flagged files: " + ($badSorted | Measure-Object).Count)
if ($badSorted.Count -gt 0) {
    $badSorted | Select-Object -First 50 | ForEach-Object { Write-Host $_ }
    exit 2
} else {
    Write-Host 'OK'
}


