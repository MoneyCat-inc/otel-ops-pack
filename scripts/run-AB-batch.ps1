# A/B Batch Timeout Sweep Runner
# Sweeps batch.timeout over candidate values and records latency metrics

param(
    [int[]]$BatchTimeoutsMs = @(100,150,200,250,300),
    [int]$SendBatchSize = 512,
    [int]$SendBatchMaxSize = 1024,
    [int]$PerRunSeconds = 20,
    [int]$Repeats = 3,
    [string]$OutputPath = $(Join-Path (Resolve-Path "..").Path ("artifacts/ab-batch-summary-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path "artifacts")) { New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null }

$results = @()

foreach ($ms in $BatchTimeoutsMs) {
    Write-Host ("== Testing batch.timeout = {0}ms ==" -f $ms) -ForegroundColor Cyan
    $runs = @()
    $applyOkCount = 0
    for ($r=1; $r -le $Repeats; $r++) {
        Write-Host ("  - Run {0}/{1}" -f $r,$Repeats) -ForegroundColor Gray
        # Apply config overrides safely (uses canary + rollback on failure)
        $apply = pwsh -NoProfile -File "safe-apply-config.ps1" -Candidate "C:\otel\config.yaml" -BatchTimeoutMs $ms -SendBatchSize $SendBatchSize -SendBatchMaxSize $SendBatchMaxSize
        if ($LASTEXITCODE -ne 0) {
            Write-Host ("    Apply failed for {0}ms (exit {1})" -f $ms,$LASTEXITCODE) -ForegroundColor Red
            $runs += @{ latency_ms=$null; exporter_failed_rate_per_sec=$null; apply_ok=$false }
            continue
        }
        $applyOkCount++

        # Run monitor briefly to capture latency gauge (exports JSON when requested)
        $report = Join-Path (Resolve-Path ".").Path ("artifacts/monitor-sample-{0}ms-{1}-r{2}.json" -f $ms,(Get-Date -Format 'HHmmss'),$r)
        $null = pwsh -NoProfile -File "scripts/monitor-optimized-pipeline.ps1" -DurationMinutes ([math]::Ceiling($PerRunSeconds/60)) -RefreshSeconds 5 -ExportReport -ReportPath $report

        # Parse latency section
        $lat = $null; $rate = $null
        try {
            $json = Get-Content -Raw -LiteralPath $report | ConvertFrom-Json -ErrorAction Stop
            $latEntries = $json.MonitoringData.Latency
            if ($latEntries) {
                $last = $latEntries[-1]
                $lat = $last.CanaryLatencyMs
                $rate = $last.ExporterFailedRatePerSec
            }
        } catch { }
        $runs += @{ latency_ms=$lat; exporter_failed_rate_per_sec=$rate; apply_ok=$true }
    }

    # Compute stats (ignore nulls)
    function Get-Percentile([double[]]$arr, [double]$p) {
        if (-not $arr -or $arr.Count -eq 0) { return $null }
        $sorted = $arr | Sort-Object
        $n = $sorted.Count
        $rank = ($p/100.0) * ($n - 1)
        $low = [math]::Floor($rank); $high = [math]::Ceiling($rank)
        if ($low -eq $high) { return [double]$sorted[$low] }
        $w = $rank - $low
        return [double]$sorted[$low] * (1 - $w) + [double]$sorted[$high] * $w
    }

    $latVals = @($runs | Where-Object { $_.latency_ms -ne $null } | ForEach-Object { [double]$_.latency_ms })
    $mean = if ($latVals.Count -gt 0) { [math]::Round(($latVals | Measure-Object -Average).Average,2) } else { $null }
    $p50 = if ($latVals.Count -gt 0) { [math]::Round((Get-Percentile $latVals 50),2) } else { $null }
    $p90 = if ($latVals.Count -gt 0) { [math]::Round((Get-Percentile $latVals 90),2) } else { $null }
    $p95 = if ($latVals.Count -gt 0) { [math]::Round((Get-Percentile $latVals 95),2) } else { $null }

    $results += @{
        batch_timeout_ms = $ms
        apply_ok_runs = $applyOkCount
        runs = $runs
        stats = @{ count=$runs.Count; seen_count=$latVals.Count; mean_ms=$mean; p50_ms=$p50; p90_ms=$p90; p95_ms=$p95 }
    }
}

# Emit summary
$summary = @{ 
    timestamp = (Get-Date).ToString("o");
    send_batch_size = $SendBatchSize;
    send_batch_max_size = $SendBatchMaxSize;
    per_run_seconds = $PerRunSeconds;
    repeats = $Repeats;
    results = $results
}

$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host ("Summary written: {0}" -f $OutputPath) -ForegroundColor Green


