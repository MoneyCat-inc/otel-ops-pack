# Monitor ECRR compliance over time: append validation metrics with timestamp
param(
    [string]$ReportsDir = "docs/ECRR_REPORTS",
    [string]$HistoryFile = "artifacts/ecrr-compliance-history.jsonl"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path (Split-Path $HistoryFile))) { New-Item -ItemType Directory -Path (Split-Path $HistoryFile) -Force | Out-Null }

# Reuse validation logic by invoking the validator
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("ecrr-ci-validation-" + [guid]::NewGuid().ToString() + ".json")
$cmd = "scripts/validate-ecrr-compliance.ps1 -ReportsDir `"$ReportsDir`" -OutJson `"$temp`""

$proc = Start-Process pwsh -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File", "scripts/validate-ecrr-compliance.ps1", "-ReportsDir", $ReportsDir, "-OutJson", $temp -NoNewWindow -PassThru -Wait

if (-not (Test-Path $temp)) { Write-Error "Validation output not found: $temp"; exit 2 }

$data = Get-Content -Path $temp -Raw | ConvertFrom-Json
$entry = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss K")
    total = $data.total
    fourSectionPct = $data.fourSection.pct
    gatePct = $data.ecrrGate.pct
    passed = $data.passed
}

($entry | ConvertTo-Json -Depth 4 -Compress) | Add-Content -Path $HistoryFile -Encoding UTF8

Write-Host ("Appended compliance entry: four={0}%, gates={1}%" -f $entry.fourSectionPct,$entry.gatePct) -ForegroundColor Green
