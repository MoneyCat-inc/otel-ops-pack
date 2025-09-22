# Detect near-duplicate paths (spaces vs hyphens, case, Unicode lookalikes)
param(
    [string]$Root = '.',
    [switch]$IncludeFiles
)

$ErrorActionPreference = 'Stop'

function Normalize-Name([string]$name) {
    $ascii = $name.Normalize([Text.NormalizationForm]::FormC)
    $ascii = $ascii.ToLowerInvariant()
    $ascii = $ascii -replace '\s', '-'   # spaces → hyphen
    $ascii = $ascii -replace '_', '-'     # underscores → hyphen
    $ascii = $ascii -replace '[^a-z0-9\.-]', ''  # strip non-ascii-ish
    return $ascii
}

$items = if ($IncludeFiles) {
    Get-ChildItem -Recurse -Path $Root -Force -ErrorAction SilentlyContinue
} else {
    Get-ChildItem -Recurse -Path $Root -Directory -Force -ErrorAction SilentlyContinue
}

$map = @{}
foreach ($it in $items) {
    $norm = Normalize-Name -name $it.Name
    if (-not $map.ContainsKey($norm)) { $map[$norm] = New-Object System.Collections.Generic.List[object] }
    $map[$norm].Add($it.FullName)
}

$suspects = $map.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | Sort-Object { $_.Value.Count } -Descending

if (-not $suspects) {
    Write-Output 'No near-duplicate names detected.'
    exit 0
}

foreach ($s in $suspects) {
    Write-Output ("== " + $s.Key + " ==")
    $s.Value | ForEach-Object { Write-Output ("  - " + $_) }
}

Write-Output ("Total groups: " + ($suspects | Measure-Object | Select-Object -ExpandProperty Count))


