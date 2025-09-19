function Test-ResonaiStack {
  param(
    [string]$ResonaiUrl = "http://localhost:3003",
    [string]$SigNozUrl  = "http://localhost:8080",
    [string]$OtlpHttp   = "http://localhost:14318"
  )

  Write-Host "== OTel Collector presence ==" -ForegroundColor Cyan
  $otel = (Get-Command otelcol-contrib -ErrorAction SilentlyContinue)
  if (!$otel) { 
    Write-Warning "otelcol-contrib not on PATH" 
    $service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
    if ($service) {
      Write-Host "✅ OTel Collector service running: $($service.Status)" -ForegroundColor Green
    }
  } else { 
    Write-Host "✅ otelcol-contrib found: $($otel.Source)" -ForegroundColor Green
  }

  Write-Host "`n== Ports check ==" -ForegroundColor Cyan
  $ports = @(14317,14318,3003,8080)
  foreach ($p in $ports) {
    $ok = Test-NetConnection -ComputerName "localhost" -Port $p -WarningAction SilentlyContinue
    $status = if($ok.TcpTestSucceeded){"LISTENING/OK"}else{"closed"}
    $color = if($ok.TcpTestSucceeded){"Green"}else{"Red"}
    Write-Host "Port $p`: $status" -ForegroundColor $color
  }

  Write-Host "`n== HTTP health checks ==" -ForegroundColor Cyan
  foreach ($u in @("$ResonaiUrl","$SigNozUrl")) {
    try {
      $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 5
      Write-Host "$u -> $($r.StatusCode)" -ForegroundColor Green
    } catch { 
      Write-Host "$u -> FAIL: $($_.Exception.Message)" -ForegroundColor Red
    }
  }

  Write-Host "`n== OTLP canary (HTTP /v1/logs) ==" -ForegroundColor Cyan
  $nowNs = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()*1000000)
  $body = @{
    resourceLogs = @(@{
      resource  = @{ attributes = @(@{ key="service.name"; value=@{ stringValue="resonai-local" }}) }
      scopeLogs = @(@{
        logRecords = @(@{
          timeUnixNano = $nowNs
          body = @{ stringValue = "canary from $(hostname) $(Get-Date -Format o)" }
          severityText = "INFO"
        })
      })
    })
  } | ConvertTo-Json -Depth 7

  try {
    $resp = Invoke-RestMethod -Method Post -Uri "$OtlpHttp/v1/logs" -ContentType "application/json" -Body $body
    Write-Host "POST $OtlpHttp/v1/logs -> OK" -ForegroundColor Green
  } catch { 
    Write-Host "POST $OtlpHttp/v1/logs -> FAIL: $($_.Exception.Message)" -ForegroundColor Red
  }

  Write-Host "`n== Next steps ==" -ForegroundColor Cyan
  @(
    "• In SigNoz, search logs for service.name = resonai-local",
    "• In Resonai, trigger a quick /try mic session and watch the pitch HUD",
    "• If 14317/14318 are closed, ensure the collector is running with the expected config"
  ) | ForEach-Object { Write-Host $_ -ForegroundColor White }
}

# Run it:
Test-ResonaiStack
