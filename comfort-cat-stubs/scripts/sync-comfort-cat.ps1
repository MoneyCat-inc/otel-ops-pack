#Requires -Version 7
param(
  [string]$RepoPath = (Join-Path $PSScriptRoot '..\docs\comfort-cat'),
  [string]$WinTarget = 'C:\otel\docs\comfort cat'
)
New-Item -ItemType Directory -Force -Path $WinTarget | Out-Null
Copy-Item -Path (Join-Path $RepoPath '*') -Destination $WinTarget -Recurse -Force
Write-Host "Synced $RepoPath -> $WinTarget"
