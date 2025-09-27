# requires Pester: Install-Module Pester -Scope CurrentUser
Describe "codex-local premium UX" {

  BeforeAll {
    # Ensure we're in the right directory
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    Set-Location $script:repoRoot
    
    # Create test artifacts directory
    if (-not (Test-Path ".agent")) {
      New-Item -ItemType Directory ".agent" | Out-Null
    }
  }

  AfterAll {
    # Cleanup test artifacts
    if (Test-Path ".agent/_status.json") {
      Remove-Item ".agent/_status.json"
    }
    if (Test-Path ".agent/LOCK") {
      Remove-Item ".agent/LOCK"
    }
  }

  It "produces valid status JSON matching schema fields" {
    pnpm agent:status-premium -Json | Out-File .agent/_status.json
    $obj = Get-Content .agent/_status.json -Raw | ConvertFrom-Json
    $obj | Should -Not -BeNullOrEmpty
    $obj.timestamp | Should -Not -BeNullOrEmpty
    $obj.lock | Should -BeOfType [bool]
    $obj.status | Should -BeIn @("unknown", "active", "locked", "corrupted")
    $obj.sections | Should -Not -BeNullOrEmpty
    $obj.queue | Should -Not -BeNullOrEmpty
  }

  It "honors kill-switch" {
    "test lock" | Set-Content .agent/LOCK
    $j = pnpm agent:status-premium -Json | ConvertFrom-Json
    Remove-Item .agent/LOCK -ErrorAction SilentlyContinue
    $j.lock | Should -Be $true
    $j.status | Should -Be "locked"
  }

  It "rate-limits file writes (≤1/sec)" {
    $before = Get-Date
    1..5 | ForEach-Object { 
      pnpm agent:status-premium -Quiet | Out-Null 
    }
    $after = Get-Date
    $elapsed = ($after - $before).TotalSeconds
    $elapsed | Should -BeGreaterOrEqual 4   # 5 calls ~≥4s with ≤1 write/sec throttle
  }

  It "produces valid guardrails JSON output" {
    $result = pnpm agent:guardrails-premium -Json | ConvertFrom-Json
    $result | Should -Not -BeNullOrEmpty
    $result.violations | Should -BeOfType [int]
    $result.filesProcessed | Should -BeOfType [int]
    $result.filesModified | Should -BeOfType [int]
    $result.linesChanged | Should -BeOfType [int]
    $result.exitCode | Should -BeOfType [int]
    $result.items | Should -BeOfType [array]
    $result.needsFollowup | Should -BeOfType [array]
  }

  It "respects quiet mode output format" {
    $quietOutput = pnpm agent:status-premium -Quiet
    $quietOutput | Should -Match "^ACTIVE - \d+ violations$|^LOCKED - \d+ violations$"
  }

  It "respects guardrails quiet mode output format" {
    $quietOutput = pnpm agent:guardrails-premium -Quiet
    $quietOutput | Should -Match "^PASS - \d+ violations found$|^FAIL - \d+ violations found$"
  }

  It "produces consistent EMA data structure" {
    # Run status twice to ensure EMA data is populated
    pnpm agent:status-premium -Quiet | Out-Null
    Start-Sleep -Seconds 1
    $status = pnpm agent:status-premium -Json | ConvertFrom-Json
    
    if ($status.ema) {
      $status.ema | Should -BeOfType [hashtable]
      # EMA values should be numbers if present
      foreach ($key in $status.ema.Keys) {
        $status.ema[$key] | Should -BeOfType [double]
      }
    }
  }

  It "handles missing lock file gracefully" {
    # Ensure no lock file exists
    if (Test-Path ".agent/LOCK") {
      Remove-Item ".agent/LOCK"
    }
    
    $status = pnpm agent:status-premium -Json | ConvertFrom-Json
    $status.lock | Should -Be $false
    $status.status | Should -BeIn @("unknown", "active", "corrupted")
  }

  It "produces valid JSON schema compliance" {
    $status = pnpm agent:status-premium -Json | ConvertFrom-Json
    $guardrails = pnpm agent:guardrails-premium -Json | ConvertFrom-Json
    
    # Status JSON should have required fields
    $status.PSObject.Properties.Name | Should -Contain "timestamp"
    $status.PSObject.Properties.Name | Should -Contain "lock"
    $status.PSObject.Properties.Name | Should -Contain "status"
    $status.PSObject.Properties.Name | Should -Contain "sections"
    $status.PSObject.Properties.Name | Should -Contain "queue"
    
    # Guardrails JSON should have required fields
    $guardrails.PSObject.Properties.Name | Should -Contain "violations"
    $guardrails.PSObject.Properties.Name | Should -Contain "filesProcessed"
    $guardrails.PSObject.Properties.Name | Should -Contain "exitCode"
    $guardrails.PSObject.Properties.Name | Should -Contain "items"
  }
}
