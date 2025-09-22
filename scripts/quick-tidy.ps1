<#
.SYNOPSIS
    Remove common local build and telemetry cache directories for the OTel ops toolkit
.DESCRIPTION
    Deletes transient directories (logs, queue, coverage, etc.) and Python cache folders.
    If pnpm is available, trims the global store and dedupes workspace dependencies.
    Safe to re-run; tracked files are untouched.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Get-Item -LiteralPath '.').FullName
Write-Host "== TIDY: cleaning repo ==" -ForegroundColor Cyan
Write-Host "Root: $repoRoot" -ForegroundColor DarkGray

function Get-RelativePathSafe {
    param([Parameter(Mandatory)][string]$FullPath)
    try {
        return [System.IO.Path]::GetRelativePath($repoRoot, $FullPath)
    } catch {
        return $FullPath
    }
}

function Test-IsThirdParty {
    param([Parameter(Mandatory)][string]$RelativePath)
    return $RelativePath -like 'third_party\\*' -or $RelativePath -like 'third_party/*'
}

$cleanupTargets = @(
    'logs',
    'queue',
    'backup',
    'state',
    '.pytest_cache',
    '.mypy_cache',
    '.ruff_cache',
    'coverage',
    'dist',
    'build',
    '.turbo',
    '.next',
    '.parcel-cache',
    '.cache',
    'tmp',
    'temp'
)

function Remove-TargetPath {
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $fullPath = Join-Path -Path $repoRoot -ChildPath $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        return
    }

    if ($fullPath -eq $repoRoot) {
        Write-Warning "Skipping repo root"
        return
    }

    $relative = Get-RelativePathSafe -FullPath $fullPath
    if (Test-IsThirdParty -RelativePath $relative) {
        Write-Host ("  -> skipping third_party scoped path {0}" -f $relative) -ForegroundColor DarkGray
        return
    }

    try {
        Write-Host ("  -> removing {0}" -f $relative) -ForegroundColor Yellow
        Remove-Item -LiteralPath $fullPath -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Warning ("    failed to remove {0}: {1}" -f $relative, $_.Exception.Message)
    }
}

foreach ($target in $cleanupTargets) {
    Remove-TargetPath -Path $target
}

# Remove scattered __pycache__ folders (excluding third_party)
Get-ChildItem -Path $repoRoot -Directory -Recurse -Force -Filter '__pycache__' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $relative = Get-RelativePathSafe -FullPath $_.FullName
        if (Test-IsThirdParty -RelativePath $relative) {
            return
        }
        try {
            Write-Host ("  -> removing {0}" -f $relative) -ForegroundColor Yellow
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Warning ("    failed to remove {0}: {1}" -f $relative, $_.Exception.Message)
        }
    }

# Remove TypeScript build info files if any (excluding third_party)
Get-ChildItem -Path $repoRoot -Filter '*.tsbuildinfo' -Recurse -Force -ErrorAction SilentlyContinue |
    ForEach-Object {
        $relative = Get-RelativePathSafe -FullPath $_.FullName
        if (Test-IsThirdParty -RelativePath $relative) {
            return
        }
        try {
            Write-Host ("  -> deleting file {0}" -f $relative) -ForegroundColor Yellow
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
        } catch {
            Write-Warning ("    failed to delete {0}: {1}" -f $relative, $_.Exception.Message)
        }
    }

if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    Write-Host "== PNPM: prune global store ==" -ForegroundColor Cyan
    try {
        pnpm store prune | Out-Null
    } catch {
        Write-Warning ("pnpm store prune failed: {0}" -f $_.Exception.Message)
    }

    Write-Host "== PNPM: dedupe workspace deps ==" -ForegroundColor Cyan
    try {
        pnpm dedupe | Out-Null
    } catch {
        Write-Warning ("pnpm dedupe failed: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Host "pnpm not found; skipping pnpm maintenance" -ForegroundColor DarkGray
}

Write-Host "== DONE ==" -ForegroundColor Green
