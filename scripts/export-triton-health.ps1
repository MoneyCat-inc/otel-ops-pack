param(
  [string]$SigNozOtlpEndpoint = 'http://localhost:14318/v1/logs',
  [string]$SidecarHealthUrl = 'http://localhost:8003/health/deep'
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function New-DirectoryIfMissing { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null } }

$outDir = 'artifacts/gpu_diag'
New-DirectoryIfMissing $outDir
$stamp = (Get-Date -Format 'yyyyMMdd_HHmmss')

try {
  $deep = Invoke-RestMethod -Method GET -Uri $SidecarHealthUrl -TimeoutSec 5
  $deep | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $outDir "health_deep_$stamp.json") -Encoding utf8

  $tritonAvailable = [int]([bool]$deep.triton_available)
  $modelCount = @($deep.details.available_models).Count

  $otlp = @{resourceLogs=@(@{resource=@{attributes=@(@{key='service.name';value=@{stringValue='gpu-inference-sidecar'}},@{key='component';value=@{stringValue='triton-health-exporter'}})};scopeLogs=@(@{scope=@{name='triton-health';version='1.0.0'};logRecords=@(@{timeUnixNano = [string][int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()*1000000);severityText='INFO';body=@{stringValue=(ConvertTo-Json @{triton_available=$tritonAvailable;model_count=$modelCount})};attributes=@(@{key='triton_available';value=@{intValue=$tritonAvailable}},@{key='model_count';value=@{intValue=$modelCount}})})})})}
  $json = $otlp | ConvertTo-Json -Depth 12
  $json | Set-Content -Path (Join-Path $outDir "otlp_payload_$stamp.json") -Encoding utf8
  Invoke-RestMethod -Method Post -Uri $SigNozOtlpEndpoint -ContentType 'application/json' -Body $json -TimeoutSec 10 | Out-Null
  Write-Host "Exported Triton health to SigNoz via OTLP." -ForegroundColor Green
} catch {
  ($_ | Out-String) | Set-Content -Path (Join-Path $outDir "export_error_$stamp.txt") -Encoding utf8
  Write-Host "Failed to export Triton health." -ForegroundColor Red
}

