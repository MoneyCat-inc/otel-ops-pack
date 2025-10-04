# 🐾 BossCat GPU Pattern-Sifter EPIC - GitHub Issue Automation
# Creates all 6 lane issues (T1-T6) with proper labels and assignments

param(
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$Repository = "resonai/otel",
    [switch]$DryRun = $false
)

# BossCat Lane Definitions
$lanes = @(
    @{
        Number = "T1"
        Title = "feat(cuda): rolling-stats kernel MVP with JSON evidence"
        Labels = @("bosscat-lane", "enhancement", "cuda", "priority-0")
        Body = @"
## 🎯 **Why**
Need GPU kernel for rolling mean/stddev to act as base sifter for the Resonai [OTel] observability pipeline.

## 📋 **What**
- Add `cuda/rolling_stats.cu` with kernel implementation
- Add `rolling_run.py` harness with CPU parity check
- Emit deterministic JSON evidence

## ✅ **Acceptance Criteria**
- [ ] CPU vs GPU parity < `1e-5`
- [ ] Evidence JSON includes timings + parity fields
- [ ] Falls back to CPU if no CUDA available
- [ ] CI passes with green status

## 📊 **Evidence**
Expected JSON output:
```json
{
  "ok": true,
  "ts": "2024-12-19T10:30:00Z",
  "algo": "rolling",
  "params": {"window": 256, "stride": 64},
  "timings": {
    "h2dMs": 12.7,
    "kernelMs": 35.4,
    "d2hMs": 7.8,
    "gpuMs": 55.9,
    "cpuMs": 412.3
  },
  "parity": {"maxAbsDiff": 2.1e-06},
  "env": {
    "providers": ["cuda", "cpu"],
    "cudaVersion": "12.1"
  },
  "run": {
    "providerFinal": "cuda",
    "fellBackToCpu": false
  }
}
```

## 🚪 **Handoff**
```markdown
CI is green and all checks are satisfied.  
**@cat ready-for-gate** 🚪✅
```

**Epic Reference:** [GPU Pattern-Sifter EPIC](docs/ecrr/ECRR_REPORTS/GPU_PATTERN_SIFTER_EPIC.md)
"@
    },
    @{
        Number = "T2"
        Title = "test(ecrr): add JSON schema + CI evidence validator"
        Labels = @("bosscat-lane", "testing", "ecrr", "priority-0")
        Body = @"
## 🎯 **Why**
Ensure all evidence is valid, enforceable, and fails PRs if malformed to maintain BossCat governance standards.

## 📋 **What**
- Add `docs/ecrr/schema.json`
- Implement `validate_evidence.ts`
- Wire into CI workflow

## ✅ **Acceptance Criteria**
- [ ] Schema includes all required fields: `ok`, `ts`, `algo`, `params`, `timings`, `parity`, `env.providers`, `run.providerFinal`, `fellBackToCpu`, `hashes`
- [ ] CI fails on invalid evidence
- [ ] Valid JSON passes CI validation
- [ ] Schema covers all T1-T6 evidence formats

## 📊 **Evidence**
- Valid JSON passes CI
- Invalid JSON blocks merge
- Schema validation logs included in CI output

## 🚪 **Handoff**
```markdown
CI is green and all checks are satisfied.  
**@cat ready-for-gate** 🚪✅
```

**Epic Reference:** [GPU Pattern-Sifter EPIC](docs/ecrr/ECRR_REPORTS/GPU_PATTERN_SIFTER_EPIC.md)
"@
    },
    @{
        Number = "T3"
        Title = "docs(dx): add Windows + WSL quickrun kits"
        Labels = @("bosscat-lane", "documentation", "windows", "priority-1")
        Body = @"
## 🎯 **Why**
Developers must run smoke tests in <2 min with consistent artifacts across Windows and WSL environments.

## 📋 **What**
- Add `docs/windows-cheats.md`
- Add `docs/wsl-notes.md` with detection flag
- Include sample JSON evidence walkthrough

## ✅ **Acceptance Criteria**
- [ ] Windows teammate runs CPU smoke → JSON evidence <2 min
- [ ] WSL runs emit `wsl_detected: true` in evidence
- [ ] Clear walkthrough with sample JSON evidence
- [ ] Both environments produce consistent artifacts

## 📊 **Evidence**
- Docs walkthrough with sample JSON evidence
- PR artifacts: `wsl-notes.md`
- Validation from Windows teammate

## 🚪 **Handoff**
```markdown
CI is green and all checks are satisfied.  
**@cat ready-for-gate** 🚪✅
```

**Epic Reference:** [GPU Pattern-Sifter EPIC](docs/ecrr/ECRR_REPORTS/GPU_PATTERN_SIFTER_EPIC.md)
"@
    },
    @{
        Number = "T4"
        Title = "feat(cuda): PFAC multi-pattern scan kernel"
        Labels = @("bosscat-lane", "enhancement", "cuda", "priority-1")
        Body = @"
## 🎯 **Why**
Enable GPU-accelerated Aho–Corasick scanning for large pattern sets to dramatically improve pattern matching performance.

## 📋 **What**
- Implement `cuda/pfac_scan.cu` with GPU trie traversal
- Add CPU validator for correctness
- Record `patternsSha256` in evidence

## ✅ **Acceptance Criteria**
- [ ] GPU matches CPU output exactly
- [ ] `patternsSha256` logged in JSON evidence
- [ ] Handles large pattern sets (>1000 patterns)
- [ ] Falls back to CPU if GPU unavailable

## 📊 **Evidence**
```json
{
  "ok": true,
  "algo": "pfac",
  "matches": 1247,
  "patternsSha256": "def456...",
  "timings": {
    "gpuMs": 23.1,
    "cpuMs": 1156.8
  },
  "run": {
    "providerFinal": "cuda",
    "fellBackToCpu": false
  }
}
```

## 🚪 **Handoff**
```markdown
CI is green and all checks are satisfied.  
**@cat ready-for-gate** 🚪✅
```

**Epic Reference:** [GPU Pattern-Sifter EPIC](docs/ecrr/ECRR_REPORTS/GPU_PATTERN_SIFTER_EPIC.md)
"@
    },
    @{
        Number = "T5"
        Title = "chore(bench): nightly GPU vs CPU benchmarks + dashboards"
        Labels = @("bosscat-lane", "performance", "benchmark", "priority-2")
        Body = @"
## 🎯 **Why**
Track performance gains and regressions over time with automated benchmarking and dashboard generation.

## 📋 **What**
- Add `scripts/gpu_bench.ts`
- Save JSON under `docs/ecrr/ECRR_REPORTS/`
- Generate `docs/bench/index.md` static dashboard

## ✅ **Acceptance Criteria**
- [ ] GPU run shows `accMs < cpuMs`
- [ ] CPU-only runs still green with `"note": "no-accel"`
- [ ] JSON bench results committed nightly
- [ ] Dashboard updated with trend analysis

## 📊 **Evidence**
- JSON bench results committed to repo
- Dashboard updated nightly via automation
- Performance trend visualization

## 🚪 **Handoff**
```markdown
CI is green and all checks are satisfied.  
**@cat ready-for-gate** 🚪✅
```

**Epic Reference:** [GPU Pattern-Sifter EPIC](docs/ecrr/ECRR_REPORTS/GPU_PATTERN_SIFTER_EPIC.md)
"@
    },
    @{
        Number = "T6"
        Title = "feat(monitoring): add GPU health/fallback signals to harness"
        Labels = @("bosscat-lane", "monitoring", "signoz", "priority-2")
        Body = @"
## 🎯 **Why**
Ensure visibility into GPU fallback, parity, and regression signals within the SigNoz observability stack.

## 📋 **What**
- Update harness logging for GPU signals
- Add `docs/gpu-signals.md` documentation
- Integrate with existing SigNoz monitoring

## ✅ **Acceptance Criteria**
- [ ] Evidence logs include `gpu_fallback: true` on trigger
- [ ] Regression/parity mismatches logged to SigNoz
- [ ] GPU health metrics visible in dashboards
- [ ] Fallback events trigger appropriate alerts

## 📊 **Evidence**
- Artifacts show logs + JSON with fallback fields
- SigNoz dashboard integration verified
- Alert rules tested and documented

## 🚪 **Handoff**
```markdown
CI is green and all checks are satisfied.  
**@cat ready-for-gate** 🚪✅
```

**Epic Reference:** [GPU Pattern-Sifter EPIC](docs/ecrr/ECRR_REPORTS/GPU_PATTERN_SIFTER_EPIC.md)
"@
    }
)

function Write-BossCatLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "🐾 [$timestamp] $Message" -ForegroundColor Cyan
}

function Create-GitHubIssue {
    param(
        [hashtable]$Lane,
        [string]$Token,
        [string]$Repo
    )
    
    $headers = @{
        "Authorization" = "token $Token"
        "Accept" = "application/vnd.github.v3+json"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        title = $Lane.Title
        body = $Lane.Body
        labels = $Lane.Labels
    } | ConvertTo-Json -Depth 10
    
    $uri = "https://api.github.com/repos/$Repo/issues"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
        Write-BossCatLog "✅ Created issue #$($response.number): $($Lane.Title)"
        return $response.number
    }
    catch {
        Write-Error "❌ Failed to create issue for $($Lane.Number): $($_.Exception.Message)"
        return $null
    }
}

# Main execution
Write-BossCatLog "Starting BossCat GPU Pattern-Sifter EPIC issue creation..."

if ($DryRun) {
    Write-BossCatLog "🔍 DRY RUN MODE - Would create the following issues:"
    foreach ($lane in $lanes) {
        Write-Host "  $($lane.Number): $($lane.Title)" -ForegroundColor Yellow
        Write-Host "    Labels: $($lane.Labels -join ', ')" -ForegroundColor Gray
    }
    exit 0
}

if (-not $GitHubToken) {
    Write-Error "❌ GitHub token required. Set GITHUB_TOKEN environment variable or use -GitHubToken parameter"
    exit 1
}

$createdIssues = @()
foreach ($lane in $lanes) {
    Write-BossCatLog "Creating $($lane.Number): $($lane.Title)"
    $issueNumber = Create-GitHubIssue -Lane $lane -Token $GitHubToken -Repo $Repository
    if ($issueNumber) {
        $createdIssues += @{
            Number = $lane.Number
            IssueNumber = $issueNumber
            Title = $lane.Title
        }
    }
    Start-Sleep -Seconds 2  # Rate limiting
}

Write-BossCatLog "🎯 BossCat EPIC Issues Created:"
foreach ($issue in $createdIssues) {
    Write-Host "  $($issue.Number): #$($issue.IssueNumber) - $($issue.Title)" -ForegroundColor Green
}

Write-BossCatLog "🚀 Ready to begin lane execution with T1 and T2 in parallel!"
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Start T1 (Rolling Stats Kernel)" -ForegroundColor White
Write-Host "2. Start T2 (Evidence Schema)" -ForegroundColor White
Write-Host "3. Follow BossCat governance: ≤10 files, ≤200 LOC per PR" -ForegroundColor White
