<#
.SYNOPSIS
    Perform a full deep-clean on the OTel observability workspace.
.DESCRIPTION
    Stops WSL/Docker (best effort), runs the quick tidy, removes local dependency folders,
    refreshes pnpm installs, vacuums the git repo, and prints the 15 heaviest directories.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Get-Item -LiteralPath '.').FullName
Write-Host "== DEEP CLEAN: $repoRoot ==" -ForegroundColor Cyan

$quickTidy = Join-Path -Path $PSScriptRoot -ChildPath 'quick-tidy.ps1'
if (Test-Path $quickTidy) {
    Write-Host "== Running quick tidy first ==" -ForegroundColor Cyan
    try {
        & $quickTidy
    } catch {
        Write-Warning ("quick-tidy.ps1 encountered an error: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Warning "quick-tidy.ps1 not found; continuing without pre-clean"
}

Write-Host "== SHUTDOWN WSL/Docker (best effort) ==" -ForegroundColor Cyan
try {
    & wsl.exe --shutdown 2>$null
    Write-Host "  -> WSL stopped" -ForegroundColor DarkGray
} catch {
    Write-Host ("  -> WSL shutdown skipped ({0})" -f $_.Exception.Message) -ForegroundColor DarkGray
}

if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        Write-Host "  -> docker system prune -af --volumes" -ForegroundColor Yellow
        docker system prune -af --volumes | Out-Null
    } catch {
        Write-Warning ("Docker prune failed: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Host "  -> Docker not found; skipping prune" -ForegroundColor DarkGray
}

function Remove-PathSafely {
    param([Parameter(Mandatory)][string]$Path)

    $fullPath = Join-Path -Path $repoRoot -ChildPath $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        return
    }

    $relative = try { [System.IO.Path]::GetRelativePath($repoRoot, $fullPath) } catch { $Path }
    try {
        Write-Host ("  -> removing {0}" -f $relative) -ForegroundColor Yellow
        Remove-Item -LiteralPath $fullPath -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Warning ("    failed to remove {0}: {1}" -f $relative, $_.Exception.Message)
    }
}

$deepTargets = @(
    'node_modules',
    '.pnpm-store',
    'pnpm-store',
    '.venv',
    'env',
    'venv'
)

foreach ($target in $deepTargets) {
    Remove-PathSafely -Path $target
}

# Remove nested node_modules outside third_party (avoid disturbing vendored submodules)
Get-ChildItem -Path $repoRoot -Directory -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq 'node_modules' -and $_.FullName -notmatch '\\third_party\\' } |
    ForEach-Object {
        $relative = try { [System.IO.Path]::GetRelativePath($repoRoot, $_.FullName) } catch { $_.FullName }
        try {
            Write-Host ("  -> removing {0}" -f $relative) -ForegroundColor Yellow
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Warning ("    failed to remove {0}: {1}" -f $relative, $_.Exception.Message)
        }
    }

if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    Write-Host "== PNPM: prune and reinstall ==" -ForegroundColor Cyan
    try {
        pnpm store prune | Out-Null
    } catch {
        Write-Warning ("pnpm store prune failed: {0}" -f $_.Exception.Message)
    }

    try {
        pnpm install
    } catch {
        Write-Warning ("pnpm install failed: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Host "pnpm not found; skipping reinstall" -ForegroundColor DarkGray
}

Write-Host "== GIT VACUUM ==" -ForegroundColor Cyan
try {
    git gc --prune=now --aggressive | Out-Null
    Write-Host "  -> git gc complete" -ForegroundColor DarkGray
} catch {
    Write-Warning ("git gc failed: {0}" -f $_.Exception.Message)
}

Write-Host "== TOP 15 HEAVIEST DIRECTORIES ==" -ForegroundColor Cyan
$excludePattern = '\\.(git)(\\|$)'
Get-ChildItem -Path $repoRoot -Directory -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch $excludePattern } |
    ForEach-Object {
        $size = 0
        try {
            $size = (Get-ChildItem -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
        } catch {
            $size = 0
        }
        [pscustomobject]@{
            Path = try { [System.IO.Path]::GetRelativePath($repoRoot, $_.FullName) } catch { $_.FullName }
            GB   = if ($size) { [math]::Round($size / 1GB, 2) } else { 0 }
        }
    } |
    Sort-Object -Property GB -Descending |
    Select-Object -First 15 |
    Format-Table -AutoSize

Write-Host "== DONE ==" -ForegroundColor Green
