#Requires -Version 7.0
<#
.SYNOPSIS
  ALFA-2 Backfill time-sliced fetcher for ECRR ingestion

.DESCRIPTION
  Iterates GitHub workflow runs with manual pagination and date slicing,
  writing minimal meta/summary/events to the ECRR folder structure.

.PARAMETER Repository
  Owner/Repo slug (default: current repo inferred by gh)

.PARAMETER Days
  How many days back to fetch (default: 3)

.PARAMETER Root
  ECRR root directory (default: artifacts/ecrr)

.EXAMPLE
  pwsh -File scripts/ingest-backfill.ps1 -Repository MoneyCat-inc/otel-ops-pack -Days 3
#>

[CmdletBinding()]
param(
  [string]$Repository = '',
  [int]$Days = 3,
  [string]$Root = 'artifacts/ecrr'
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

function Ecrr-Path([string]$root, [string]$org, [string]$repo, [datetime]$createdAt, [string]$runId) {
  $yyyy = $createdAt.ToUniversalTime().Year.ToString()
  $mm = '{0:d2}' -f $createdAt.ToUniversalTime().Month
  $dd = '{0:d2}' -f $createdAt.ToUniversalTime().Day
  $dir = Join-Path -Path $root -ChildPath "org=$org/repo=$repo/dt=$yyyy/$mm/$dd/run=$runId"
  Ensure-Dir $dir
  return @{ dir = $dir; date = "$yyyy-$mm-$dd" }
}

function Redact([string]$text) {
  $out = $text
  $out = [regex]::Replace($out, '(token|password|secret)[=:]\s*[^\s"\'']+', '$1=[REDACTED]', 'IgnoreCase')
  $out = [regex]::Replace($out, '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}', '[redacted-email]')
  $out = [regex]::Replace($out, '\b[a-f0-9]{20,64}\b', '[redacted-hash]', 'IgnoreCase')
  $out = [regex]::Replace($out, '\b(\d{1,3}\.){3}\d{1,3}\b', '[redacted-ip]')
  return $out
}

Write-Host "[ingest-backfill] Repository: $Repository Days: $Days Root: $Root" -ForegroundColor Cyan

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "GitHub CLI 'gh' not found"
  exit 1
}

try { gh auth status 2>&1 | Out-Null } catch { Write-Error "gh not authenticated"; exit 1 }

$since = (Get-Date).AddDays(-1 * $Days)
$page = 1
$perPage = 100
$total = 0

while ($true) {
  Write-Host "[ingest-backfill] Page $page" -ForegroundColor Gray
  $path = "/repos/$Repository/actions/runs?per_page=$perPage&page=$page"
  $resp = gh api $path 2>&1
  if (-not $resp) { break }
  $json = $resp | ConvertFrom-Json
  $runs = $json.workflow_runs
  if (-not $runs -or $runs.Count -eq 0) { break }

  foreach ($r in $runs) {
    $created = Get-Date $r.created_at
    if ($created -lt $since) { continue }
    $org = $r.repository.owner.login
    $repo = $r.repository.name
    $paths = Ecrr-Path $Root $org $repo $created $r.id

    $meta = [ordered]@{
      org = $org; repo = $repo; run_id = $r.id; run_number = $r.run_number; name = $r.name
      event = $r.event; status = $r.status; conclusion = $r.conclusion
      head_branch = $r.head_branch; head_sha = $r.head_sha
      created_at = $r.created_at; updated_at = $r.updated_at
      storage = @{ root = $Root; date = $paths.date; dir = $paths.dir }
    } | ConvertTo-Json -Depth 5
    $meta | Set-Content -Path (Join-Path $paths.dir 'meta.json') -Encoding UTF8

    @(
      "Run: $repo #$($r.run_number) ($($r.name))",
      "Org/Repo: $org/$repo",
      "Event: $($r.event)",
      "Status: $($r.status) -> $($r.conclusion)",
      "Branch: $($r.head_branch)",
      "SHA: $($r.head_sha.Substring(0,7))",
      "Created: $($r.created_at)",
      "Updated: $($r.updated_at)"
    ) | Set-Content -Path (Join-Path $paths.dir 'summary.md') -Encoding UTF8

    $eventLine = @{ ts = (Get-Date).ToString('o'); kind = 'workflow_run.completed'; data = @{ org = $org; repo = $repo; id = $r.id; conclusion = $r.conclusion } } | ConvertTo-Json -Compress
    Add-Content -Path (Join-Path $paths.dir 'events.jsonl') -Value $eventLine

    Ensure-Dir (Join-Path $paths.dir 'logs')
    "$(Redact "backfilled $org/$repo run $($r.id) at $(Get-Date -Format o)")" | Set-Content -Path (Join-Path $paths.dir 'logs/ingest.txt') -Encoding UTF8

    $total++
  }

  if ($runs.Count -lt $perPage) { break }
  $page++
}

Write-Host "[ingest-backfill] Complete. Runs ingested: $total" -ForegroundColor Green
exit 0

