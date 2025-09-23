$ErrorActionPreference = 'Stop'

# Cleans files listed by .tmp/sanity-violations.txt:
#  - Replace smart quotes with ASCII equivalents
#  - Rewrite as UTF-8 without BOM
# Usage: pwsh -File scripts/sanity-clean.ps1

function Write-Utf8NoBom([string]$path, [string]$content) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $path), $content, $utf8NoBom)
}

if (-not (Test-Path -LiteralPath '.tmp/sanity-violations.txt')) {
    Write-Host '.tmp/sanity-violations.txt not found. Run scripts/sanity-scan.ps1 first.' -ForegroundColor Yellow
    exit 1
}

$list = Get-Content -LiteralPath '.tmp/sanity-violations.txt'
foreach ($f in $list) {
    if (-not (Test-Path -LiteralPath $f)) { continue }
    try {
        $raw = Get-Content -LiteralPath $f -Raw -ErrorAction Stop
        $clean = $raw.Replace([string][char]0x2018, "'")
        $clean = $clean.Replace([string][char]0x2019, "'")
        $clean = $clean.Replace([string][char]0x201C, '"')
        $clean = $clean.Replace([string][char]0x201D, '"')
        Write-Utf8NoBom -path $f -content $clean
    } catch {
        Write-Host ("Skip: $f -> $_") -ForegroundColor Yellow
    }
}

Write-Host 'Clean complete.'


