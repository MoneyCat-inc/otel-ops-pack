# Requires: PowerShell 7+
param(
    [switch]$Apply,
    [switch]$IncludeBackups
)

$ErrorActionPreference = 'Stop'

function Get-TargetFiles {
    # Collect .ps1 files excluding common vendor/ignored paths
    $all = Get-ChildItem -Path . -Recurse -File -Filter *.ps1 -ErrorAction SilentlyContinue
    # Use a single regex with alternation for simplicity
    $ignorePattern = '(?i)\\(node_modules|\.git|out|dist|bin)\\'
    return $all | Where-Object { $_.FullName -notmatch $ignorePattern }
}

# Regexes
$rxAdd = '(?i)\bSplit-Path\s+(?!-(?:Path|LiteralPath)\b)'
$rxPipe = '(?i)\|\s*Split-Path\s+-Parent'

$files = Get-TargetFiles
if(-not $files){
    Write-Host 'No .ps1 files found' -ForegroundColor Yellow
    exit 0
}

$plan = foreach($f in $files){
    $text = Get-Content -Path $f.FullName -Raw -Encoding UTF8
    $m1 = [regex]::Matches($text,$rxAdd).Count
    $m2 = [regex]::Matches($text,$rxPipe).Count
    if($m1 -gt 0 -or $m2 -gt 0){
        [PSCustomObject]@{
            File = $f.FullName
            AddPathFixes = $m1
            PipelineFixes = $m2
        }
    }
}

if(-not $plan){
    Write-Host 'No changes needed' -ForegroundColor Green
    exit 0
}

Write-Host 'Dry-run (files to change):' -ForegroundColor Cyan
$plan | Sort-Object File | Format-Table -AutoSize | Out-String | Write-Host

if(-not $Apply){
    Write-Host 'Run with -Apply to perform changes.' -ForegroundColor Yellow
    exit 0
}

foreach($p in $plan){
    $path = $p.File
    $orig = Get-Content -Path $path -Raw -Encoding UTF8
    if($IncludeBackups){ Copy-Item -Path $path -Destination ($path + '.bak') -Force }
    $step = [regex]::Replace($orig,$rxAdd,'Split-Path -Path ')
    $step2 = [regex]::Replace($step,$rxPipe,'| ForEach-Object { Split-Path -Path $_.FullName -Parent }')
    if($step2 -ne $orig){
        Set-Content -Path $path -Value $step2 -Encoding UTF8
        Write-Host ("Updated: " + $path) -ForegroundColor Green
    }
}

Write-Host ("Files changed: " + ($plan | Measure-Object).Count) -ForegroundColor Green

