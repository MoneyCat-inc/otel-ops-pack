while ($true) {
  $sev = docker exec signoz-clickhouse clickhouse-client --query "SELECT severity_text, count() FROM signoz_logs.logs_v2 WHERE timestamp >= toUnixTimestamp64Nano(now64(9)-toIntervalMinute(10)) GROUP BY severity_text ORDER BY count() DESC" 2>$null
  $win = docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_logs.logs_v2 WHERE arrayElement(mapValues(attributes_string), indexOf(mapKeys(attributes_string),'dataset'))='windows'" 2>$null
  $sevText = ($sev | Out-String).Trim()
  Write-Host ("[{0}] last10m severities:`n{1}`nwindows count: {2}" -f (Get-Date -Format o), $sevText, $win)
  if ($sevText -match "^ERROR\s+([0-9]+)" -and [int]$Matches[1] -gt 0) { Write-Warning "ERRORs detected in last 10m — check filelog/canary"; break }
  Start-Sleep -Seconds 300
}
