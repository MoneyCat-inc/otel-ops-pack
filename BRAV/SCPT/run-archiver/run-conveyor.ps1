# BRAV/SCPT/run-archiver/run-conveyor.ps1
# BossCat Run Conveyor — Wrapper for Node.js conveyor
# Handles npm install and environment setup

param(
  [string]$Repo = "MoneyCat-inc/otel-ops-pack",
  [int]$MaxKeep = 100,
  [int]$ChunkSize = 2000,
  [int]$ChunkOffset = 0,
  [int]$ArchConcurrency = 16,
  [double]$ArchQps = 1.2,
  [double]$DeleteQps = 0.8,
  [switch]$DryRun = $true,
  [switch]$SkipRateLimitWait = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat Run Conveyor — Setup & Execute"

# Navigate to archiver directory
Push-Location BRAV/SCPT/run-archiver

try {
  # Install dependencies if needed
  if (-not (Test-Path "node_modules")) {
    Write-Host "`nInstalling dependencies..."
    npm install
  }

  # Set environment
  $env:REPO = $Repo
  $env:MAX_KEEP = $MaxKeep
  $env:CHUNK_SIZE = $ChunkSize
  $env:CHUNK_OFFSET = $ChunkOffset
  $env:ARCH_CONCURRENCY = $ArchConcurrency
  $env:ARCH_QPS = $ArchQps
  $env:DELETE_QPS = $DeleteQps
  $env:DRY_RUN = if ($DryRun) { "true" } else { "false" }
  $env:SKIP_RATE_LIMIT_WAIT = if ($SkipRateLimitWait) { "true" } else { "false" }
  
  # Use GITHUB_TOKEN if available, or prompt for GH_TOKENS
  if (-not $env:GH_TOKENS -and -not $env:GITHUB_TOKEN) {
    Write-Warning "GH_TOKENS not set. Using gh CLI default token..."
    $env:GITHUB_TOKEN = (gh auth token)
  }

  Write-Host "`nEnvironment:"
  Write-Host "  REPO: $env:REPO"
  Write-Host "  MAX_KEEP: $env:MAX_KEEP"
  Write-Host "  CHUNK: size=$env:CHUNK_SIZE offset=$env:CHUNK_OFFSET"
  Write-Host "  ARCH_CONCURRENCY: $env:ARCH_CONCURRENCY"
  Write-Host "  ARCH_QPS: $env:ARCH_QPS"
  Write-Host "  DELETE_QPS: $env:DELETE_QPS"
  Write-Host "  DRY_RUN: $env:DRY_RUN"
  Write-Host "  TOKENS: $($env:GH_TOKENS ? ($env:GH_TOKENS.Split(',').Count) : 1)"

  # Execute conveyor
  Write-Host "`n🚀 Starting conveyor..."
  node conveyor.mjs

  Write-Host "`n✅ Conveyor complete!"

} finally {
  Pop-Location
}

