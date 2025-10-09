#Requires -Version 7.0
param(
  [int]$MaxContainers = 200
)

$ErrorActionPreference = "Stop"
$root = Join-Path $PSScriptRoot "../../.artifacts/memx/snapshots"
New-Item -ItemType Directory -Force -Path $root | Out-Null

$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH-mm-ss.fffZ")
$id = [guid]::NewGuid().ToString("N")
$file = Join-Path $root "$($ts)_$id.json"

# --- System ---
$os = Get-CimInstance Win32_OperatingSystem
$committed = (Get-Counter '\Memory\Committed Bytes').CounterSamples[0].CookedValue
$page = Get-CimInstance Win32_PageFileUsage | Select-Object -First 1

$system = [ordered]@{
  total_ram_bytes = [int64]($os.TotalVisibleMemorySize * 1KB)
  free_ram_bytes  = [int64]($os.FreePhysicalMemory * 1KB)
  committed_bytes = [int64]$committed
}
$pagefile = $null
if ($page) {
  $pagefile = [ordered]@{
    allocated_mb = [int]$page.AllocatedBaseSize
    current_mb   = [int]$page.CurrentUsage
    peak_mb      = [int]$page.PeakUsage
    name         = $page.Name
  }
}

# --- Processes of interest ---
$procNames = @('firefox','otelcol-contrib','com.docker.backend','com.docker.service')
$procs = @()
foreach ($name in $procNames) {
  $p = Get-Process -Name $name -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($p) {
    $procs += [ordered]@{
      name = $p.ProcessName
      pid  = $p.Id
      working_set_bytes = [int64]$p.WorkingSet64
      private_mem_bytes = [int64]$p.PrivateMemorySize64
      cpu_total_ms      = [int64]$p.TotalProcessorTime.TotalMilliseconds
    }
  }
}

# --- Docker containers (optional) ---
$containers = @()
try {
  $json = docker stats --no-stream --format "{{json .}}" 2>$null
  if ($LASTEXITCODE -eq 0 -and $json) {
    $lines = $json -split "`n"
    $count = 0
    foreach ($ln in $lines) {
      if ($count -ge $MaxContainers) { break }
      $obj = $ln | ConvertFrom-Json
      # Normalize memory usage like "123.45MiB / 2.00GiB"
      $memParts = $obj.MemUsage -split '/'
      function Parse-Mem { param($s)
        $t = $s.Trim()
        if ($t -match '([0-9\.,]+)\s*([KMG]i?)B') {
          $num = [double]($Matches[1].Replace(',','.'))
          $unit = $Matches[2].ToLower()
          switch -regex ($unit) {
            'k'   { return [int64]($num * 1KB) }
            'ki'  { return [int64]($num * 1KB) }
            'm'   { return [int64]($num * 1MB) }
            'mi'  { return [int64]($num * 1MB) }
            'g'   { return [int64]($num * 1GB) }
            'gi'  { return [int64]($num * 1GB) }
            default { return $null }
          }
        } else { return $null }
      }
      $used = Parse-Mem $memParts[0]
      $limit = Parse-Mem $memParts[1]
      $containers += [ordered]@{
        id = $obj.ID
        name = $obj.Name
        cpu_pct = $obj.CPUPerc.TrimEnd('%') -as [double]
        mem_used_bytes = $used
        mem_limit_bytes = $limit
        mem_pct = $obj.MemPerc.TrimEnd('%') -as [double]
        oom_killed = $false # docker stats doesn't show directly (v1: false)
      }
      $count++
    }
  }
} catch { }

# --- Envelope ---
$payload = [ordered]@{
  version = "memx-1"
  snapshot_id = $id
  ts = (Get-Date).ToUniversalTime().ToString("o")
  host = $env:COMPUTERNAME
  system = $system
  pagefile = $pagefile
  processes = $procs
  containers = $containers
}

$payload | ConvertTo-Json -Depth 6 | Out-File -FilePath $file -Encoding UTF8
Write-Host "MEMX snapshot written: $file"
