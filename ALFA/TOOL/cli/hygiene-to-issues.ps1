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

if ($yamls) {
    New-GHIssue -Title 'yamllint failures in workflows/configs' -Labels @('yaml','hygiene') -Body ("```
{0}
```" -f (($yamls | ForEach-Object { $_.Line }) -join "`n"))
}

if ($otel) {
    New-GHIssue -Title 'otelcol dry-run errors in configs/otel' -Labels @('otel','hygiene') -Body ("```
{0}
```" -f (($otel | ForEach-Object { $_.Line }) -join "`n"))
}

if ($ps) {
    New-GHIssue -Title 'PSScriptAnalyzer warnings in scripts/*.ps1' -Labels @('powershell','hygiene') -Body ("```
{0}
```" -f (($ps | ForEach-Object { $_.Line }) -join "`n"))
}

Write-Host "Filed issues (if any buckets had matches)." -ForegroundColor Cyan
