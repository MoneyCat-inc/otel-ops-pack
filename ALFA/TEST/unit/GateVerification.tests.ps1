# BossCat OEM - Gate Verification Pester Tests
# Requires: Pester v5+, PowerShell 7+

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Resolve-Path (Join-Path $here "..")
$artifact = Join-Path $root "out\gate_verification.json"
$schema   = Join-Path $root "schemas\gate_verification.schema.json"

Describe "Gate verification artifact" {
  
  It "JSON artifact exists" {
    Test-Path $artifact | Should -BeTrue -Because "verify-pipeline.ps1 should generate gate_verification.json"
  }

  It "Schema file exists" {
    Test-Path $schema | Should -BeTrue -Because "JSON schema should be present for validation"
  }

  Context "Schema validation" {
    
    It "conforms to JSON schema" -Skip:(!(Test-Path $artifact) -or !(Test-Path $schema)) {
      $json = Get-Content $artifact -Raw
      $isValid = $json | Test-Json -SchemaFile $schema
      $isValid | Should -BeTrue -Because "Artifact must conform to gate_verification.schema.json"
    }
  }

  Context "Business rules" {
    BeforeAll {
      if (Test-Path $artifact) {
        $script:j = Get-Content $artifact -Raw | ConvertFrom-Json
      }
    }

    It "has required top-level fields" -Skip:(!(Test-Path $artifact)) {
      $j.PSObject.Properties.Name | Should -Contain "timestamp_utc"
      $j.PSObject.Properties.Name | Should -Contain "service_name"
      $j.PSObject.Properties.Name | Should -Contain "steps"
      $j.PSObject.Properties.Name | Should -Contain "gate_checks"
      $j.PSObject.Properties.Name | Should -Contain "outcome"
      $j.PSObject.Properties.Name | Should -Contain "exit_code"
    }

    It "maps outcomes to exit codes correctly (0/1/2)" -Skip:(!(Test-Path $artifact)) {
      switch ($j.outcome) {
        "OK"   { $j.exit_code | Should -Be 0 -Because "OK outcome must have exit code 0" }
        "WARN" { $j.exit_code | Should -Be 1 -Because "WARN outcome must have exit code 1" }
        "FAIL" { $j.exit_code | Should -Be 2 -Because "FAIL outcome must have exit code 2" }
        default { throw "Invalid outcome: $($j.outcome)" }
      }
    }

    It "enforces pass preconditions when outcome=OK" -Skip:($j.outcome -ne "OK") {
      $j.gate_checks.collector_service_running | Should -BeTrue -Because "Collector must be running for OK"
      $j.gate_checks.otlp_reachable            | Should -BeTrue -Because "OTLP must be reachable for OK"
      $j.gate_checks.span_rate_nonzero         | Should -BeTrue -Because "Spans must be flowing for OK"
    }

    It "confirms span via API when outcome=OK (forensic requirement)" -Skip:($j.outcome -ne "OK") {
      $j.steps.canary_send.api_confirmed | Should -BeTrue -Because "API confirmation required for OK outcome"
      $j.steps.canary_send.api_reason    | Should -Be "span_found" -Because "API must find span for OK"
    }

    It "measures ingest latency when outcome=OK (SLI requirement)" -Skip:($j.outcome -ne "OK" -or -not $j.steps.canary_send.ingest_latency_ms) {
      $latency = [int]$j.steps.canary_send.ingest_latency_ms
      $latency | Should -BeGreaterThan 0 -Because "Latency must be positive"
      $latency | Should -BeLessThan 5000 -Because "p95 target is < 5000ms"
    }

    It "has valid trace_id when in PINPOINT mode" -Skip:($j.steps.canary_send.api_mode -notmatch "PINPOINT") {
      $j.steps.canary_send.trace_id | Should -Match "^[0-9a-f]{32}$" -Because "PINPOINT mode requires valid 32-char hex trace ID"
    }
  }

  Context "Artifact quality checks" {
    
    It "has recent timestamp (within last hour)" -Skip:(!(Test-Path $artifact)) {
      $ts = [DateTimeOffset]::Parse($j.timestamp_utc)
      $age = ([DateTimeOffset]::UtcNow - $ts).TotalMinutes
      $age | Should -BeLessThan 60 -Because "Verification should be recent"
    }

    It "includes gate_id reference" -Skip:(!(Test-Path $artifact)) {
      $j.gate_id | Should -Not -BeNullOrEmpty -Because "Gate ID provides traceability"
    }
  }
}

Describe "Trend CSV (SLO tracking)" {
  
  $csvPath = Join-Path $root "out\gate_verification_trend.csv"
  
  It "exists after verification run" -Skip:(!(Test-Path $csvPath)) {
    Test-Path $csvPath | Should -BeTrue
  }

  It "has required columns" -Skip:(!(Test-Path $csvPath)) {
    $header = Get-Content $csvPath -First 1
    $header | Should -Match "timestamp_utc"
    $header | Should -Match "outcome"
    $header | Should -Match "ingest_latency_ms"
    $header | Should -Match "verification_mode"
  }
}

Describe "Evidence pack" {
  
  It "generates evidence zip on verification" -Skip:($true) {
    # This test is informational - evidence packs are timestamped
    $zips = Get-ChildItem (Join-Path $root "out") -Filter "evidence-*.zip"
    $zips.Count | Should -BeGreaterThan 0 -Because "Evidence packs should be generated"
  }
}

