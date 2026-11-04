#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ensure .env carries a random SIGNOZ_JWT_SECRET for the SigNoz compose stack.
.DESCRIPTION
    The compose files refuse to start without SIGNOZ_JWT_SECRET (${SIGNOZ_JWT_SECRET:?...}).
    The repository ships no default: the old one sat in the public compose files, and in a
    tracked .env from 2025-10-05 to 2026-07-24, so anyone could sign SigNoz sessions with it.

    When the variable is missing, empty, or still a `your-...-here` placeholder in the .env next
    to the compose file, this writes a fresh 256-bit value (64 hex characters from the OS
    CSPRNG). An existing value is left alone, and the value is never printed. If
    SIGNOZ_JWT_SECRET is set in the process environment, compose uses it ahead of .env and
    nothing is written.

    On a host that already runs SigNoz, a new value signs every session out once the signoz
    container is recreated (docker compose up -d). That is a rotation and the machine
    operator's call, which is why only the start scripts call this, never the logon task.
.PARAMETER EnvFile
    Path of the .env file. Default: .env in the repository root, next to docker-compose.yml.
.EXAMPLE
    pwsh -File BRAV/SCPT/security/ensure-signoz-signing-key.ps1
#>
[CmdletBinding()]
param(
    [string]$EnvFile = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) '.env')
)

$ErrorActionPreference = 'Stop'

if ($env:SIGNOZ_JWT_SECRET) {
    Write-Host 'SIGNOZ_JWT_SECRET is set in the environment; compose uses it ahead of .env. Nothing written.'
    return
}

# Resolve against PowerShell's location, not the process directory, before any .NET file call.
$EnvFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($EnvFile)

$lines = @()
if (Test-Path -LiteralPath $EnvFile) {
    $lines = @(Get-Content -LiteralPath $EnvFile)
}

$index = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*SIGNOZ_JWT_SECRET\s*=\s*(.*)$') {
        $value = $Matches[1].Trim().Trim([char]34, [char]39)
        if ($value -and $value -notmatch '^your-.*-here$') {
            Write-Host "SIGNOZ_JWT_SECRET is already set in $EnvFile; left unchanged."
            return
        }
        $index = $i
    }
}

$bytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
$entry = 'SIGNOZ_JWT_SECRET=' + (-join ($bytes | ForEach-Object { $_.ToString('x2') }))

if ($index -ge 0) { $lines[$index] = $entry } else { $lines += $entry }

# Plain UTF-8 (no BOM, which Windows PowerShell's -Encoding UTF8 would add) with LF endings.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($EnvFile, (($lines -join "`n") + "`n"), $utf8NoBom)
if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
    & chmod 600 -- $EnvFile
}
Write-Host "Generated SIGNOZ_JWT_SECRET into $EnvFile (64 hex characters; value not shown)."
Write-Host 'If SigNoz was already running, recreate it with: docker compose up -d (existing sessions are signed out).'
