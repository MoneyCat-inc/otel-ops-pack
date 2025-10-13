# BRAV/SCPT/run-archiver/run-conveyor.ps1
# BossCat Run Conveyor — Wrapper for Node.js conveyor
# Handles npm install and environment setup

param(
  [string]$Repo = "MoneyCat-inc/otel-ops-pack",
  [int]$MaxKeep = 100,
  [int]$ArchConcurrency = 24,
  [decimal]$DeleteQPS = 1.0,
  [switch]$DryRun = $true
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
  $env:ARCH_CONCURRENCY = $ArchConcurrency
  $env:DELETE_QPS = $DeleteQPS
  $env:DRY_RUN = if ($DryRun) { "true" } else { "false" }
  
  # Use GITHUB_TOKEN if available, or prompt for GH_TOKENS
  if (-not $env:GH_TOKENS -and -not $env:GITHUB_TOKEN) {
    Write-Warning "GH_TOKENS not set. Using gh CLI default token..."
    $env:GITHUB_TOKEN = (gh auth token)
  }

  Write-Host "`nEnvironment:"
  Write-Host "  REPO: $env:REPO"
  Write-Host "  MAX_KEEP: $env:MAX_KEEP"
  Write-Host "  ARCH_CONCURRENCY: $env:ARCH_CONCURRENCY"
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

