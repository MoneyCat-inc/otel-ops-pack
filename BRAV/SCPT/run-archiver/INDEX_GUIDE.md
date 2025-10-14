# 📊 Archive Index Guide — Query & Analysis

**Authority**: cursor{implementer} — BossCat OEM  
**Purpose**: Lightweight JSONL index for archived workflow runs

---

## 🗂️ **INDEX STRUCTURE**

### **Location**
```
docs/BossCat/run-reports/INDEX.jsonl
```

### **Record Format**

Each line is a JSON object with:

```json
{
  "id": "18485761625",
  "workflow": "JFrog SAST Scan",
  "conclusion": "cancelled",
  "duration": 62,
  "date": "2025-10-14",
  "actor": "fubumaki",
  "path": "2025/10/run-18485761625.md"
}
```

### **Field Reference**

| Field | Type | Description | Example Values |
|-------|------|-------------|----------------|
| `id` | string | Unique run ID | `"18485761625"` |
| `workflow` | string | Workflow name | `"JFrog SAST Scan"`, `"ICF Smoke"` |
| `conclusion` | string | Run outcome | `"success"`, `"failure"`, `"cancelled"`, `"skipped"` |
| `duration` | number | Run duration in seconds | `62`, `145`, `3600` |
| `date` | string | Run date (ISO) | `"2025-10-14"` |
| `actor` | string | Triggering actor | `"fubumaki"`, `"github-actions"` |
| `path` | string | Relative path to report | `"2025/10/run-18485761625.md"` |

---

## 🔧 **MANAGING THE INDEX**

### **Automatic Indexing (During Archive)**

Index is built **on-the-fly** during archival:
- No parsing overhead (uses repo metadata)
- Append-only (safe for concurrent runs)
- One record per archived run

**No action needed** - index updates automatically!

---

### **Manual Backfill (After Cleanup)**

Regenerate index from all existing archived reports:

```powershell
# Rebuild INDEX.jsonl from scratch
pwsh BRAV/SCPT/run-archiver/generate-index.ps1

# Output: Scanned X reports, wrote INDEX.jsonl
```

**When to use:**
- After cleanup completes
- If index becomes corrupted
- To add missing historical records

---

## 📊 **ANALYSIS QUERIES**

### **1. Workflow Health Dashboard**

**Most Failed Workflows:**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Where-Object {$_.conclusion -eq 'failure'} | 
  Group-Object workflow | 
  Sort-Object Count -Descending | 
  Select-Object @{N='Workflow';E={$_.Name}}, @{N='Failures';E={$_.Count}} -First 10
```

**Success Rate by Workflow:**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Group-Object workflow | 
  ForEach-Object {
    $total = $_.Count
    $success = ($_.Group | Where-Object {$_.conclusion -eq 'success'}).Count
    [PSCustomObject]@{
      Workflow = $_.Name
      Total = $total
      Success = $success
      SuccessRate = [math]::Round($success / $total * 100, 2)
    }
  } | Sort-Object SuccessRate
```

---

### **2. Duration Analysis**

**Average Duration by Workflow:**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Group-Object workflow | 
  ForEach-Object {
    $avg = ($_.Group.duration | Measure-Object -Average).Average
    $max = ($_.Group.duration | Measure-Object -Maximum).Maximum
    [PSCustomObject]@{
      Workflow = $_.Name
      AvgSeconds = [math]::Round($avg, 1)
      MaxSeconds = $max
      Runs = $_.Count
    }
  } | Sort-Object AvgSeconds -Descending
```

**Slowest Runs (Top 20):**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Sort-Object duration -Descending | 
  Select-Object -First 20 | 
  Format-Table @{N='Run ID';E={$_.id}}, workflow, @{N='Duration (min)';E={[math]::Round($_.duration/60,1)}}, conclusion
```

---

### **3. Time-Based Trends**

**Daily Failure Rate:**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Group-Object date | 
  ForEach-Object {
    $failures = ($_.Group | Where-Object {$_.conclusion -eq 'failure'}).Count
    [PSCustomObject]@{
      Date = $_.Name
      Total = $_.Count
      Failures = $failures
      FailureRate = [math]::Round($failures / $_.Count * 100, 2)
    }
  } | Sort-Object Date -Descending | Format-Table
```

**Runs per Day (Activity Heatmap):**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Group-Object date | 
  Sort-Object Name | 
  Select-Object @{N='Date';E={$_.Name}}, @{N='Runs';E={$_.Count}}
```

---

### **4. Actor Analysis**

**Most Active Contributors:**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Group-Object actor | 
  Sort-Object Count -Descending | 
  Select-Object @{N='Actor';E={$_.Name}}, @{N='Runs';E={$_.Count}} -First 10
```

**Failure Rate by Actor:**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Group-Object actor | 
  ForEach-Object {
    $failures = ($_.Group | Where-Object {$_.conclusion -eq 'failure'}).Count
    [PSCustomObject]@{
      Actor = $_.Name
      Total = $_.Count
      Failures = $failures
      FailureRate = [math]::Round($failures / $_.Count * 100, 2)
    }
  } | Sort-Object FailureRate -Descending
```

---

### **5. Specific Workflow Deep-Dive**

**ICF Smoke Run History:**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Where-Object {$_.workflow -like "*ICF Smoke*"} | 
  Sort-Object date -Descending | 
  Select-Object id, conclusion, duration, date | 
  Format-Table
```

**Nightly Dashboard Reliability:**
```powershell
$runs = Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Where-Object {$_.workflow -like "*Nightly*"}

$total = $runs.Count
$success = ($runs | Where-Object {$_.conclusion -eq 'success'}).Count

Write-Host "`nNightly Dashboard Reliability:"
Write-Host "Total runs: $total"
Write-Host "Successful: $success"
Write-Host "Reliability: $([math]::Round($success / $total * 100, 2))%"
```

---

### **6. Export to CSV (For Excel/Tableau)**

```powershell
# Export full index to CSV
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Export-Csv -Path "artifacts/index-export.csv" -NoTypeInformation

# Export failures only
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Where-Object {$_.conclusion -eq 'failure'} | 
  Export-Csv -Path "artifacts/failures.csv" -NoTypeInformation
```

---

## 🎯 **COMMON USE CASES**

### **Pre-Release Checks**

**Count failures in last 24 hours:**
```powershell
$yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Where-Object {$_.date -ge $yesterday -and $_.conclusion -eq 'failure'} | 
  Measure-Object | 
  Select-Object Count
```

---

### **Workflow Cleanup Candidates**

**Workflows with >90% failure rate:**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Group-Object workflow | 
  ForEach-Object {
    $failures = ($_.Group | Where-Object {$_.conclusion -eq 'failure'}).Count
    $rate = $failures / $_.Count * 100
    if ($rate -gt 90) {
      [PSCustomObject]@{
        Workflow = $_.Name
        Total = $_.Count
        FailureRate = [math]::Round($rate, 1)
      }
    }
  }
```

---

### **Performance Regression Detection**

**Compare average duration this week vs last week:**
```powershell
$thisWeek = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
$lastWeek = (Get-Date).AddDays(-14).ToString("yyyy-MM-dd")

$runs = Get-Content docs/BossCat/run-reports/INDEX.jsonl | ConvertFrom-Json

$thisWeekAvg = ($runs | Where-Object {$_.date -ge $thisWeek}).duration | Measure-Object -Average
$lastWeekAvg = ($runs | Where-Object {$_.date -ge $lastWeek -and $_.date -lt $thisWeek}).duration | Measure-Object -Average

Write-Host "This week avg: $([math]::Round($thisWeekAvg.Average, 1))s"
Write-Host "Last week avg: $([math]::Round($lastWeekAvg.Average, 1))s"
Write-Host "Change: $([math]::Round(($thisWeekAvg.Average - $lastWeekAvg.Average) / $lastWeekAvg.Average * 100, 1))%"
```

---

## 🚀 **INTEGRATION WITH DASHBOARDS**

### **PowerBI / Tableau**
Export to CSV and import into visualization tools.

### **Grafana / Prometheus**
Convert JSONL to time-series metrics:
```powershell
# Export for Grafana (timestamp + metrics)
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  ForEach-Object {
    $timestamp = [DateTimeOffset]::Parse($_.date).ToUnixTimeSeconds()
    "workflow_duration{workflow=`"$($_.workflow)`",conclusion=`"$($_.conclusion)`"} $($_.duration) $timestamp"
  } | Out-File "artifacts/metrics.prom"
```

### **Custom Dashboard (PowerShell + HTML)**
```powershell
# Generate HTML dashboard
$html = @"
<!DOCTYPE html>
<html>
<head><title>Workflow Analytics</title></head>
<body>
<h1>Workflow Health Dashboard</h1>
<pre>
$(Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Group-Object conclusion | 
  Select-Object Name, Count | 
  Format-Table | Out-String)
</pre>
</body>
</html>
"@

$html | Out-File "artifacts/dashboard.html"
Start-Process "artifacts/dashboard.html"
```

---

## 📋 **QUICK REFERENCE CARD**

```powershell
# Backfill index from existing reports
pwsh BRAV/SCPT/run-archiver/generate-index.ps1

# Top 10 failed workflows
Get-Content docs/BossCat/run-reports/INDEX.jsonl | ConvertFrom-Json | 
  Where-Object {$_.conclusion -eq 'failure'} | Group-Object workflow | 
  Sort-Object Count -Descending | Select-Object -First 10

# Average duration by workflow
Get-Content docs/BossCat/run-reports/INDEX.jsonl | ConvertFrom-Json | 
  Group-Object workflow | ForEach-Object { 
    [PSCustomObject]@{Workflow=$_.Name; AvgSec=[math]::Round(($_.Group.duration|Measure-Object -Average).Average,1)} 
  }

# Daily failure rate (last 30 days)
Get-Content docs/BossCat/run-reports/INDEX.jsonl | ConvertFrom-Json | 
  Where-Object {$_.date -ge (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")} | 
  Group-Object date | ForEach-Object { 
    [PSCustomObject]@{Date=$_.Name; Failures=($_.Group|Where-Object {$_.conclusion -eq 'failure'}).Count} 
  } | Sort-Object Date

# Export to CSV
Get-Content docs/BossCat/run-reports/INDEX.jsonl | ConvertFrom-Json | 
  Export-Csv "artifacts/runs.csv" -NoTypeInformation
```

---

**Authority**: cursor{implementer}  
**Status**: ✅ **INDEX SYSTEM DEPLOYED**

🎉 **JSONL INDEX · ON-THE-FLY + BACKFILL · QUERY-READY · ANALYSIS-OPTIMIZED** 🎉

