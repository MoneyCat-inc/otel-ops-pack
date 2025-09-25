param(
    [string]$SourcePath = 'docs/comfort cat',
    [string]$DestPath = 'docs/comfort-cat',
    [string]$ReportPath = 'artifacts/comfort-cat-merge-report.txt'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Source folder not found: $SourcePath"
}

New-Item -ItemType Directory -Force -Path $DestPath | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Path -Parent $ReportPath) | Out-Null

$sourceRoot = (Resolve-Path -LiteralPath $SourcePath).Path
$log = New-Object System.Collections.Generic.List[string]

Get-ChildItem -LiteralPath $SourcePath -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\\','/')
    $target = Join-Path -Path $DestPath -ChildPath $relative
    $targetDir = Split-Path -Path -Parent $target
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

    if (Test-Path -LiteralPath $target) {
        $same = $false
        try {
            $same = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash -eq (Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash
        } catch {}

        if ($same) {
            $log.Add("SKIP-SAME: $relative")
        } else {
            $conflict = $target + '.conflict'
            Copy-Item -LiteralPath $_.FullName -Destination $conflict -Force
            $log.Add("CONFLICT: $relative -> $conflict")
        }
    } else {
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        $log.Add("COPIED: $relative -> $target")
    }
}

$log | Set-Content -Encoding utf8 -LiteralPath $ReportPath

$summary = [pscustomobject]@{
    Source = $SourcePath
    Destination = $DestPath
    Report = (Resolve-Path -LiteralPath $ReportPath).Path
    Copied = ($log | Where-Object { $_ -like 'COPIED:*' }).Count
    Conflicts = ($log | Where-Object { $_ -like 'CONFLICT:*' }).Count
    Same = ($log | Where-Object { $_ -like 'SKIP-SAME:*' }).Count
}

$summary | ConvertTo-Json -Depth 3 | Write-Output



