$ErrorActionPreference = 'Continue'
Set-StrictMode -Version Latest

# Ensure UTF-8 output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function New-DirectoryIfMissing {
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

$root = (Get-Location).Path
$outDir = Join-Path $root 'artifacts/gpu_diag'
New-DirectoryIfMissing -Path $outDir

# Write a simple header
"GPU Diagnostics - $(Get-Date -Format s)" | Set-Content -Path (Join-Path $outDir 'README.txt') -Encoding utf8

try {
    # Docker basics
    docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>&1 |
        Set-Content -Path (Join-Path $outDir 'containers.txt') -Encoding utf8
    docker version --format '{{json .}}' 2>&1 |
        Set-Content -Path (Join-Path $outDir 'docker-version.json') -Encoding utf8
    docker stats --no-stream --all 2>&1 |
        Set-Content -Path (Join-Path $outDir 'docker-stats.txt') -Encoding utf8
} catch {
    $_ | Out-String | Set-Content -Path (Join-Path $outDir 'docker-errors.txt') -Encoding utf8
}

# Identify candidate GPU containers by name/image heuristics
$allContainers = @()
try {
    $allContainers = docker ps -a --format '{{.ID}} {{.Names}} {{.Image}}' 2>$null
} catch {}

$gpuCandidates = @()
foreach ($line in $allContainers) {
    if ($line -match '(?i)(gpu|cuda|nvidia|triton|ollama|torch)') {
        $gpuCandidates += $line
    }
}
$gpuCandidates | Set-Content -Path (Join-Path $outDir 'gpu-containers.txt') -Encoding utf8

# Collect logs and inspect for GPU candidates
foreach ($entry in $gpuCandidates) {
    $id = ($entry -split '\s+')[0]
    if ([string]::IsNullOrWhiteSpace($id)) { continue }
    try { docker logs --tail 400 $id 2>&1 | Set-Content -Path (Join-Path $outDir ("logs_${id}.txt")) -Encoding utf8 } catch {}
    try { docker inspect $id 2>&1 | Set-Content -Path (Join-Path $outDir ("inspect_${id}.json")) -Encoding utf8 } catch {}
}

# WSL GPU capability check (Windows Docker Desktop GPU path)
try {
    wsl.exe -l -v 2>&1 | Set-Content -Path (Join-Path $outDir 'wsl-list.txt') -Encoding utf8
} catch {}
try {
    wsl.exe -e sh -c 'test -e /dev/dxg && echo HAS_DXG || echo NO_DXG' 2>&1 |
        Set-Content -Path (Join-Path $outDir 'wsl-gpu.txt') -Encoding utf8
} catch {}

# CUDA/NVIDIA toolkit accessibility test
try {
    docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi 2>&1 |
        Set-Content -Path (Join-Path $outDir 'nvidia-smi.txt') -Encoding utf8
} catch {}

# Compose files present
try {
    Get-ChildItem -Path $root -Filter 'docker-compose*.yml' -Name 2>$null |
        Set-Content -Path (Join-Path $outDir 'compose-files.txt') -Encoding utf8
} catch {}

# Quick signature scan for common failure reasons
$signatures = @(
    'CUDA error',
    'no CUDA-capable device is detected',
    'failed to initialize NVML',
    'driver/library version mismatch',
    'could not select device',
    'segmentation fault',
    'out of memory',
    'Killed process out of memory',
    'ENOENT',
    'permission denied',
    'nvidia-smi: command not found'
)

$report = @()
foreach ($logFile in Get-ChildItem -Path $outDir -Filter 'logs_*.txt' -ErrorAction SilentlyContinue) {
    $content = Get-Content -Path $logFile.FullName -ErrorAction SilentlyContinue -Raw
    foreach ($sig in $signatures) {
        if ($content -match [Regex]::Escape($sig)) {
            $report += "$(Split-Path $logFile -Leaf): FOUND -> $sig"
        }
    }
}

if (-not $report) { $report = @('No known failure signatures matched in GPU container logs.') }
$report | Set-Content -Path (Join-Path $outDir 'scan-summary.txt') -Encoding utf8

Write-Host "GPU diagnostics complete. See $outDir" -ForegroundColor Green


