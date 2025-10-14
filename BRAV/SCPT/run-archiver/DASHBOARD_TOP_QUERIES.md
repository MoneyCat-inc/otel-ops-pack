# Dashboard Top Queries (Quick Reference)

Purpose: Copy/paste-ready queries and one-liners to power an at-a-glance GitHub Actions health dashboard from `docs/BossCat/run-reports/INDEX.jsonl` and archived run reports.

Assumptions
- Index file: `docs/BossCat/run-reports/INDEX.jsonl` (one JSON object per line)
- PowerShell 7+ available (`pwsh`), Node 18+/20+ optional
- Fields used (see INDEX_GUIDE.md for full schema): `id, workflow, status, conclusion, actor, started_at, updated_at, duration_ms`

Conventions
- Time window examples use the last 30 days; adjust as needed
- Output is kept compact; add `| ConvertTo-Csv -NoTypeInformation` to export

1) Top 10 Failed Workflows (30 days)
```powershell
$since=(Get-Date).AddDays(-30)
Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { $_.conclusion -eq 'failure' -and ([datetime]$_.updated_at) -ge $since } |
  Group-Object workflow | % { [pscustomobject]@{ workflow=$_.Name; failures=$_.Count } } |
  Sort-Object failures -Descending | Select-Object -First 10
```

2) Success Rate by Workflow (30 days)
```powershell
$since=(Get-Date).AddDays(-30)
$rows = Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { ([datetime]$_.updated_at) -ge $since }
$byFlow = $rows | Group-Object workflow
$byFlow | % {
  $w=$_.Name; $items=$_.Group
  $total=$items.Count
  $success=($items | ? { $_.conclusion -eq 'success' }).Count
  [pscustomobject]@{ workflow=$w; total=$total; success=$success; success_rate=[math]::Round(($success*100.0/$total),1) }
} | Sort-Object success_rate -Descending
```

3) Average Duration Trend (Daily, last 14 days)
```powershell
$since=(Get-Date).AddDays(-14)
Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { ([datetime]$_.started_at) -ge $since -and $_.duration_ms } |
  % { [pscustomobject]@{ day=((Get-Date $_.started_at).ToString('yyyy-MM-dd')); duration_ms = [int]$_.duration_ms } } |
  Group-Object day | % {
    $avg=[math]::Round((($_.Group.duration_ms | Measure-Object -Average).Average),0)
    [pscustomobject]@{ day=$_.Name; avg_ms=$avg }
  } | Sort-Object day
```

4) Daily Failure Rate (30 days)
```powershell
$since=(Get-Date).AddDays(-30)
$rows = Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { ([datetime]$_.updated_at) -ge $since }
$rows | % { [pscustomobject]@{ day=((Get-Date $_.updated_at).ToString('yyyy-MM-dd')); conclusion=$_.conclusion } } |
  Group-Object day | % {
    $day=$_.Name; $items=$_.Group; $t=$items.Count
    $fail=($items | ? { $_.conclusion -eq 'failure' }).Count
    [pscustomobject]@{ day=$day; total=$t; failures=$fail; failure_rate=[math]::Round(($fail*100.0/$t),1) }
  } | Sort-Object day
```

5) Slowest 25 Runs (last 7 days)
```powershell
$since=(Get-Date).AddDays(-7)
Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { $_.duration_ms -and ([datetime]$_.started_at) -ge $since } |
  Sort-Object @{Expression={[int]$_.duration_ms};Descending=$true} |
  Select-Object -First 25 id,workflow,conclusion,@{n='duration_s';e={[math]::Round([int]$_.duration_ms/1000,1)}},updated_at
```

6) Most Active Workflows (run volume, 30 days)
```powershell
$since=(Get-Date).AddDays(-30)
Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { ([datetime]$_.updated_at) -ge $since } |
  Group-Object workflow | % { [pscustomobject]@{ workflow=$_.Name; runs=$_.Count } } |
  Sort-Object runs -Descending | Select-Object -First 15
```

7) Recent Failures (last 7 days)
```powershell
$since=(Get-Date).AddDays(-7)
Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { $_.conclusion -eq 'failure' -and ([datetime]$_.updated_at) -ge $since } |
  Sort-Object updated_at -Descending | Select-Object -First 25 id,workflow,actor,updated_at
```

8) Weekday vs Weekend Failure Rate (last 30 days)
```powershell
$since=(Get-Date).AddDays(-30)
Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { ([datetime]$_.updated_at) -ge $since } |
  % {
    $dt=[datetime]$_.updated_at
    $isWeekend = ($dt.DayOfWeek -in @([DayOfWeek]::Saturday,[DayOfWeek]::Sunday))
    [pscustomobject]@{ bucket=(if($isWeekend){'weekend'}else{'weekday'}); conclusion=$_.conclusion }
  } | Group-Object bucket | % {
    $b=$_.Name; $items=$_.Group; $t=$items.Count; $f=($items | ? { $_.conclusion -eq 'failure' }).Count
    [pscustomobject]@{ bucket=$b; total=$t; failures=$f; failure_rate=[math]::Round(($f*100.0/$t),1) }
  } | Sort-Object bucket
```

9) Workflow Reliability Score (simple composite, 30 days)
```powershell
$since=(Get-Date).AddDays(-30)
$rows = Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { ([datetime]$_.updated_at) -ge $since }
$rows | Group-Object workflow | % {
  $w=$_.Name; $items=$_.Group
  $t=$items.Count
  $succ=($items | ? { $_.conclusion -eq 'success' }).Count
  $fail=$t-$succ
  $avgMs=[math]::Round((($items | ? { $_.duration_ms } | % { [int]$_.duration_ms } | Measure-Object -Average).Average),0)
  # Score: 70% weight on success rate, 30% on inverted duration (lower is better)
  $succRate = if($t){$succ*1.0/$t}else{0}
  $normDur = if($avgMs -gt 0){ [math]::Min(1.0, 300000.0/[double]$avgMs) } else { 1.0 } # Cap at 5m baseline
  $score = [math]::Round((0.7*$succRate + 0.3*$normDur)*100,1)
  [pscustomobject]@{ workflow=$w; total=$t; success=$succ; failures=$fail; avg_ms=$avgMs; reliability_score=$score }
} | Sort-Object reliability_score -Descending
```

10) Export Slice to CSV (last 30 days)
```powershell
$since=(Get-Date).AddDays(-30)
Get-Content docs/BossCat/run-reports/INDEX.jsonl | % { $_ | ConvertFrom-Json } |
  ? { ([datetime]$_.updated_at) -ge $since } |
  Select-Object id,workflow,status,conclusion,actor,started_at,updated_at,@{n='duration_s';e={[math]::Round([int]$_.duration_ms/1000,1)}} |
  ConvertTo-Csv -NoTypeInformation | Set-Content artifacts/index_slice_30d.csv
Write-Host 'Wrote artifacts/index_slice_30d.csv'
```

Notes
- For Node users, see INDEX_GUIDE.md for an equivalent `node -e` snippet to parse JSONL quickly.
- Adjust windows, groupings, and thresholds to match your dashboard KPIs.

