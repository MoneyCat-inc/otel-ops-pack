#requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [string]$Log = "artifacts/hygiene.log"
)

if (-not (Test-Path $Log)) {
    throw "No log found at $Log"
}

$content = Get-Content $Log

$yamls = $content | Select-String -Pattern 'yamllint|YAML parse failed'
$otel  = $content | Select-String -Pattern 'otelcol|receiver|exporter|processor|pipeline'
$ps    = $content | Select-String -Pattern 'PSScriptAnalyzer|RuleName'

function New-GHIssue {
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$Body,
        [string[]]$Labels = @()
    )

    $args = @('issue','create','--title',$Title)
    foreach ($label in $Labels) {
        $args += @('--label',$label)
    }

    $tmp = New-TemporaryFile
    try {
        Set-Content -Path $tmp -Value $Body -Encoding UTF8
        $args += @('--body-file',$tmp)
        & gh @args
    } finally {
        Remove-Item -Path $tmp -ErrorAction SilentlyContinue
    }
}

function Format-IssueBody {
    param([object[]]$Matches)
    $fence = '```'
    $lines = ($Matches | ForEach-Object { $_.Line }) -join "`n"
    return "$fence`n$lines`n$fence"
}

if ($yamls) {
    New-GHIssue -Title 'yamllint failures in workflows/configs' -Labels @('yaml','hygiene') -Body (Format-IssueBody $yamls)
}

if ($otel) {
    New-GHIssue -Title 'otelcol dry-run errors in configs/otel' -Labels @('otel','hygiene') -Body (Format-IssueBody $otel)
}

if ($ps) {
    New-GHIssue -Title 'PSScriptAnalyzer warnings in scripts/*.ps1' -Labels @('powershell','hygiene') -Body (Format-IssueBody $ps)
}

Write-Host "Filed issues (if any buckets had matches)." -ForegroundColor Cyan
