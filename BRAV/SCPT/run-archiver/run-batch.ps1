#Requires -Version 7.0

<#
.SYNOPSIS
    Execute multiple conveyor chunks with interactive wait controls

.DESCRIPTION
    Runs the conveyor in a loop for multiple chunks with:
    - Interactive countdown between chunks
    - Skip/Halt controls for operator
    - Progress tracking and status updates

.PARAMETER StartOffset
    Starting chunk offset (default: 0)

.PARAMETER ChunkCount
    Number of chunks to process (default: 6)

.PARAMETER ChunkSize
    Size of each chunk (default: 1000)

.PARAMETER ArchQps
    Archive requests per second (default: 12.0)

.PARAMETER DeleteQps
    Delete requests per second (default: 1.0)

.PARAMETER CooldownSeconds
    Seconds to wait between chunks (default: 180)

.PARAMETER DryRun
    If true, runs in dry-run mode (no deletions)

.EXAMPLE
    # Process 6 chunks starting at offset 0
    .\run-batch.ps1 -StartOffset 0 -ChunkCount 6

.EXAMPLE
    # Quick run with 30-second cooldown
    .\run-batch.ps1 -ChunkCount 3 -CooldownSeconds 30
#>

param(
    [int]$StartOffset = 0,
    [int]$ChunkCount = 6,
    [int]$ChunkSize = 1000,
    [double]$ArchQps = 2.0,
    [double]$DeleteQps = 1.0,
    [int]$CooldownSeconds = 60,
    [switch]$DryRun,
    [switch]$BackfillIndex
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$conveyorScript = Join-Path $scriptDir "run-conveyor.ps1"
$waitScript = Join-Path $scriptDir "Wait-WithControl.ps1"

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🐾 BossCat Conveyor — Batch Execution" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Chunks:          $ChunkCount (starting at offset $StartOffset)"
Write-Host "Chunk size:      $ChunkSize runs"
Write-Host "Rate limits:     Archive $ArchQps req/s • Delete $DeleteQps/s"
Write-Host "Cooldown:        $CooldownSeconds seconds between chunks"
Write-Host "Dry run:         $DryRun"
Write-Host "════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$completed = 0
$skipped = 0
$failed = 0

for ($i = 0; $i -lt $ChunkCount; $i++) {
    $offset = $StartOffset + ($i * $ChunkSize)
    $chunkNum = $i + 1
    
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  📦 CHUNK $chunkNum of $ChunkCount (offset $offset)" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    # Execute conveyor
    $params = @{
        ChunkOffset = $offset
        ChunkSize = $ChunkSize
        ArchQps = $ArchQps
        DeleteQps = $DeleteQps
        MetricsTag = "batch-chunk-$chunkNum"
        DryRun = $DryRun  # Always pass DryRun flag explicitly
    }
    
    try {
        & $conveyorScript @params
        
        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            $completed++
            Write-Host "`n✅ Chunk $chunkNum complete!`n" -ForegroundColor Green
        } else {
            $failed++
            Write-Host "`n⚠️  Chunk $chunkNum failed with exit code $LASTEXITCODE`n" -ForegroundColor Yellow
        }
    }
    catch {
        $failed++
        Write-Host "`n❌ Chunk $chunkNum error: $_`n" -ForegroundColor Red
    }
    
    # Wait before next chunk (unless this is the last one)
    if ($i -lt ($ChunkCount - 1)) {
        $waitResult = & $waitScript -Seconds $CooldownSeconds -Message "Cooldown before Chunk $($chunkNum + 1)"
        
        switch ($waitResult) {
            1 {
                # Skipped - continue immediately
                Write-Host "⏭️  Cooldown skipped - proceeding to next chunk`n" -ForegroundColor Cyan
                continue
            }
            2 {
                # Halted - stop execution
                Write-Host "🛑 Batch execution HALTED by operator`n" -ForegroundColor Red
                Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
                Write-Host "📊 BATCH SUMMARY (HALTED)" -ForegroundColor Yellow
                Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
                Write-Host "Completed: $completed chunks" -ForegroundColor Green
                Write-Host "Failed:    $failed chunks" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
                Write-Host "Halted at: Chunk $($chunkNum + 1) of $ChunkCount"
                Write-Host "════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
                exit 0
            }
        }
    }
}

# Final summary
Write-Host "`n════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 BATCH EXECUTION COMPLETE" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Completed: $completed / $ChunkCount chunks" -ForegroundColor Green
Write-Host "Failed:    $failed chunks" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Optional: Backfill index after cleanup completes
if ($BackfillIndex -and $failed -eq 0 -and -not $DryRun) {
    Write-Host "📊 BACKFILLING INDEX..." -ForegroundColor Cyan
    Write-Host "Regenerating INDEX.jsonl from all archived reports...`n" -ForegroundColor DarkGray
    
    $indexScript = Join-Path $scriptDir "generate-index.ps1"
    if (Test-Path $indexScript) {
        & $indexScript
        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            Write-Host "`n✅ Index backfill complete!" -ForegroundColor Green
            Write-Host "📍 Location: docs/BossCat/run-reports/INDEX.jsonl`n" -ForegroundColor DarkGray
        } else {
            Write-Host "`n⚠️  Index backfill failed with exit code $LASTEXITCODE`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`n⚠️  Index backfill script not found: $indexScript`n" -ForegroundColor Yellow
    }
}

# Exit with appropriate code
if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}

