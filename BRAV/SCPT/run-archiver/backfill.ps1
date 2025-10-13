# BRAV/SCPT/run-archiver/backfill.ps1
# BossCat Run Archiver — Parallel backfill & prune
# Authority: BossCat OEM • ECRR-compliant • Two-agent paired execution

param(
  [string]$Repo = "MoneyCat-inc/otel-ops-pack",
  [int]$Shards = 8,
  [int]$Shard = 0,
  [int]$MaxParallel = 12,
  [switch]$DeleteAfterArchive = $false,
  [switch]$DryRun = $true
)

$ErrorActionPreference = "Stop"

# Kill-switch check (Rule #2)
if (Test-Path ".agent/LOCK") {
  Write-Error "Kill-switch active (.agent/LOCK exists). Aborting per ECRR doctrine."
  exit 1
}

# Load trim set (precomputed)
if (-not (Test-Path ".agent/tmp/TRIMSET.txt")) {
  Write-Error "TRIMSET.txt not found. Run preflight first."
  exit 1
}

$trimSet = Get-Content ".agent/tmp/TRIMSET.txt" | Where-Object {
  # Deterministic shard assignment
  ($_ -as [int]) % $Shards -eq $Shard
}

Write-Host "Shard $Shard of ${Shards}: Processing $($trimSet.Count) runs (MaxParallel: $MaxParallel, DryRun: $DryRun)"

# Bounded retry function (Rule #4)
function Invoke-WithRetry([scriptblock]$op, [int]$max=3) {
  for ($i=1; $i -le $max; $i++) {
    try { return & $op }
    catch {
      if ($i -eq $max) { throw }
      $backoff = [int][Math]::Pow(2,$i)
      Write-Warning "Retry $i/$max after ${backoff}s: $_"
      Start-Sleep -Seconds $backoff
    }
  }
}

# Parallel processing with semaphore (concurrency control)
$sem = [System.Threading.SemaphoreSlim]::new($MaxParallel, $MaxParallel)
$tasks = foreach ($runId in $trimSet) {
  $null = $sem.Wait()
  [System.Threading.Tasks.Task]::Run([Action]{
    try {
      $year = (Get-Date).ToString("yyyy")
      $month = (Get-Date).ToString("MM")
      $base = "CHAR/EVID/artifacts/ecrr/arch/$year/$month/run-$runId"
      New-Item -ItemType Directory -Path $base -Force -ea 0 | Out-Null

      # 1) Run metadata
      $run = Invoke-WithRetry {
        gh api "repos/$using:Repo/actions/runs/$runId" | ConvertFrom-Json
      }
      
      # 2) Jobs
      $jobs = Invoke-WithRetry {
        gh api "repos/$using:Repo/actions/runs/$runId/jobs?per_page=100" | ConvertFrom-Json
      }

      # 3) Manifest
      $manifest = @{
        run_id = $run.id
        html_url = $run.html_url
        name = $run.name
        event = $run.event
        status = $run.status
        conclusion = $run.conclusion
        created_at = $run.created_at
        updated_at = $run.updated_at
        head_branch = $run.head_branch
        head_sha = $run.head_sha
        attempt = $run.run_attempt
        job_count = $jobs.total_count
        artifact_count = 0
        logs_zip = $null
        artifacts = @()
      }

      # 4) Download logs (follow 302 redirect)
      $logZip = Join-Path $base "logs.zip"
      try {
        $location = (gh api -i "repos/$using:Repo/actions/runs/$runId/logs" 2>$null | 
          Select-String -Pattern '^location:' | 
          ForEach-Object { $_.ToString().Split(' ',2)[1].Trim() })
        
        if ($location) {
          Invoke-WebRequest -Uri $location -OutFile $logZip -ea Stop
          $manifest.logs_zip = @{
            path = "logs.zip"
            sha256 = (Get-FileHash $logZip -Algorithm SHA256).Hash
            bytes = (Get-Item $logZip).Length
          }
        }
      } catch {
        Write-Warning "Could not download logs for run $runId"
      }

      # 5) Download artifacts (follow 302 redirect)
      try {
        $arts = Invoke-WithRetry {
          gh api "repos/$using:Repo/actions/runs/$runId/artifacts?per_page=100" | ConvertFrom-Json
        }
        $manifest.artifact_count = $arts.total_count

        foreach ($a in $arts.artifacts) {
          $zipPath = Join-Path $base "artifact-$($a.id).zip"
          try {
            $loc = (gh api -i "repos/$using:Repo/actions/artifacts/$($a.id)/zip" 2>$null | 
              Select-String -Pattern '^location:' | 
              ForEach-Object { $_.ToString().Split(' ',2)[1].Trim() })
            
            if ($loc) {
              Invoke-WebRequest -Uri $loc -OutFile $zipPath -ea Stop
              $manifest.artifacts += @{
                id = $a.id
                name = $a.name
                size_in_bytes = $a.size_in_bytes
                path = (Split-Path $zipPath -Leaf)
                sha256 = (Get-FileHash $zipPath -Algorithm SHA256).Hash
              }
            }
          } catch {
            Write-Warning "Could not download artifact $($a.id) for run $runId"
          }
        }
      } catch {
        Write-Warning "Could not list artifacts for run $runId"
      }

      # 6) Generate badge
      $color = if ($run.conclusion -eq "success") {"#4c1"} else {"#e05d44"}
      $badge = @"
<svg xmlns='http://www.w3.org/2000/svg' width='160' height='20'>
  <rect width='160' height='20' fill='#555'/>
  <rect x='70' width='90' height='20' fill='$color'/>
  <text x='35' y='14' fill='#fff' font-family='Verdana' font-size='11' text-anchor='middle'>run</text>
  <text x='115' y='14' fill='#fff' font-family='Verdana' font-size='11' text-anchor='middle'>$($run.conclusion)</text>
</svg>
"@
      $badge | Set-Content (Join-Path $base "badge.svg") -ea 0

      # 7) Generate TL;DR
      $tldr = @"
**TL;DR** Run #$($run.run_number) — **$($run.name)** — *$($run.conclusion)*  
Branch: ``$($run.head_branch)`` • Event: ``$($run.event)`` • Jobs: $($manifest.job_count) • Artifacts: $($manifest.artifact_count)  
Created: $($run.created_at) • SHA: ``$($run.head_sha)``
"@
      $tldr | Set-Content (Join-Path $base "TLDR.md") -ea 0

      # 8) Save manifest
      $manifest | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $base "manifest.json") -ea 0

      # 9) Evidence append (JSONL)
      $evidence = @{
        t = (Get-Date).ToString("o")
        who = "A"
        type = "archive"
        lane = "DOCS"
        run_id = $runId
        shard = $using:Shard
        logs = if ($manifest.logs_zip) { $true } else { $false }
        artifacts = $manifest.artifact_count
      } | ConvertTo-Json -Compress
      
      Add-Content "CHAR/EVID/artifacts/ecrr/arch/EVIDENCE.jsonl" $evidence

      # 10) Delete if not dry run
      if (-not $using:DryRun -and $using:DeleteAfterArchive) {
        Invoke-WithRetry {
          gh run delete $runId --yes 2>&1 | Out-Null
        }
        
        $deleteEvidence = @{
          t = (Get-Date).ToString("o")
          who = "A"
          type = "delete"
          lane = "DOCS"
          run_id = $runId
        } | ConvertTo-Json -Compress
        
        Add-Content "CHAR/EVID/artifacts/ecrr/arch/EVIDENCE.jsonl" $deleteEvidence
        
        # Rate limit (1/sec per GitHub best practice)
        Start-Sleep -Seconds 1
      }

      Write-Host "Shard $using:Shard: Processed run $runId"
    }
    catch {
      Write-Warning "Shard $using:Shard: Failed run $runId - $_"
    }
    finally {
      $sem.Release() | Out-Null
    }
  })
}

# Wait for all tasks
if ($tasks.Count -gt 0) {
  Write-Host "Waiting for $($tasks.Count) tasks to complete..."
  [System.Threading.Tasks.Task]::WaitAll($tasks)
}

Write-Host "Shard $Shard complete: Processed $($trimSet.Count) runs"

