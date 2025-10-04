# 🐾 BossCat Nightly Benchmark Automation
# Runs GPU benchmark suite and commits results
# GPU Pattern-Sifter EPIC - Lane T5

param(
    [switch]$DryRun = $false,
    [string]$CommitMessage = "chore(bench): nightly GPU benchmark results"
)

function Write-BossCatLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "🐾 [$timestamp] $Message" -ForegroundColor Cyan
}

function Run-BenchmarkSuite {
    Write-BossCatLog "Starting BossCat GPU Benchmark Suite..."
    
    try {
        # Run the benchmark suite
        $result = npx tsx scripts/gpu_bench.ts
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Benchmark suite completed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Benchmark suite failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error running benchmark suite: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Commit-BenchmarkResults {
    param([string]$Message)
    
    Write-BossCatLog "Committing benchmark results..."
    
    try {
        # Add benchmark results
        git add docs/ecrr/ECRR_REPORTS/gpu_bench_*.json
        git add docs/bench/index.md
        
        # Check if there are changes to commit
        $status = git status --porcelain
        if ($status) {
            git commit -m $Message
            Write-Host "✅ Benchmark results committed" -ForegroundColor Green
            return $true
        } else {
            Write-Host "ℹ️  No changes to commit" -ForegroundColor Yellow
            return $true
        }
    }
    catch {
        Write-Host "❌ Error committing results: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-BossCatLog "Starting BossCat Nightly Benchmark Automation..."

if ($DryRun) {
    Write-BossCatLog "🔍 DRY RUN MODE - Would run benchmark suite and commit results"
    Write-Host "Commands that would be executed:" -ForegroundColor Yellow
    Write-Host "  1. npx tsx scripts/gpu_bench.ts" -ForegroundColor White
    Write-Host "  2. git add docs/ecrr/ECRR_REPORTS/gpu_bench_*.json" -ForegroundColor White
    Write-Host "  3. git add docs/bench/index.md" -ForegroundColor White
    Write-Host "  4. git commit -m '$CommitMessage'" -ForegroundColor White
    exit 0
}

# Run benchmark suite
$benchmarkSuccess = Run-BenchmarkSuite
if (-not $benchmarkSuccess) {
    Write-Host "❌ Benchmark suite failed, aborting commit" -ForegroundColor Red
    exit 1
}

# Commit results
$commitSuccess = Commit-BenchmarkResults -Message $CommitMessage
if (-not $commitSuccess) {
    Write-Host "❌ Failed to commit benchmark results" -ForegroundColor Red
    exit 1
}

Write-BossCatLog "🎉 Nightly benchmark automation complete!"
Write-Host "✅ Benchmark suite executed" -ForegroundColor Green
Write-Host "✅ Results committed to repository" -ForegroundColor Green
Write-Host "✅ Dashboard updated" -ForegroundColor Green

Write-Host "`n📊 Next steps:" -ForegroundColor Cyan
Write-Host "1. Review dashboard: docs/bench/index.md" -ForegroundColor White
Write-Host "2. Check raw results: docs/ecrr/ECRR_REPORTS/gpu_bench_*.json" -ForegroundColor White
Write-Host "3. Monitor performance trends" -ForegroundColor White

Write-Host "`n🐾 BossCat Nightly Automation - Complete" -ForegroundColor Cyan
