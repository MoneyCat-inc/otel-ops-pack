# Backfill and compress JSONL history: ensure each entry is single-line JSON
param(
    [string]$InputPath = "artifacts/ecrr-compliance-history.jsonl",
    [string]$BackupPath,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $InputPath)) {
    Write-Error "Input file not found: $InputPath"
    exit 1
}

if (-not $BackupPath) {
    $BackupPath = "$InputPath.bak"
}

function Get-BraceDelta {
    param([string]$line)
    # naive brace count; good enough for our JSON entries
    $opens = ([regex]::Matches($line, '\{')).Count
    $closes = ([regex]::Matches($line, '\}')).Count
    return ($opens - $closes)
}

$lines = Get-Content -Path $InputPath -ErrorAction Stop
$buffer = New-Object System.Collections.Generic.List[string]
$depth = 0
$objects = New-Object System.Collections.Generic.List[object]

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $buffer.Add($line)
    $depth += Get-BraceDelta -line $line
    if ($depth -le 0 -and $buffer.Count -gt 0) {
        $joined = [string]::Join("`n", $buffer)
        try {
            $obj = $joined | ConvertFrom-Json -ErrorAction Stop
            $objects.Add($obj)
        } catch {
            Write-Warning "Skipping malformed JSON block starting with: $($buffer[0])"
        }
        $buffer.Clear()
        $depth = 0
    }
}

if ($buffer.Count -gt 0) {
    $joined = [string]::Join("`n", $buffer)
    try {
        $obj = $joined | ConvertFrom-Json -ErrorAction Stop
        $objects.Add($obj)
    } catch {
        Write-Warning "Trailing malformed JSON block skipped."
    }
}

Write-Host ("Parsed {0} JSON entries" -f $objects.Count) -ForegroundColor Cyan

if ($DryRun) {
    $preview = $objects | Select-Object -Last 3 | ForEach-Object { $_ | ConvertTo-Json -Compress }
    $preview | ForEach-Object { Write-Output $_ }
    exit 0
}

# Backup and rewrite
Copy-Item -Path $InputPath -Destination $BackupPath -Force
$tmp = "$InputPath.tmp"
if (Test-Path $tmp) { Remove-Item $tmp -Force }

foreach ($obj in $objects) {
    ($obj | ConvertTo-Json -Compress) | Add-Content -Path $tmp -Encoding UTF8
}

Move-Item -Path $tmp -Destination $InputPath -Force

Write-Host "Backfill complete. Backup at: $BackupPath" -ForegroundColor Green
exit 0


