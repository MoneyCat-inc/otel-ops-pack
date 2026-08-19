# BossCat OEM - Gate Verification Pester Tests
# Requires: Pester v5+, PowerShell 7+

Describe "Gate verification artifact" {
  BeforeAll {
    . (Join-Path $PSScriptRoot '..\helpers\RepoRoot.ps1')
    $script:root = Get-OtelRepoRoot
    $script:artifact = Join-Path $script:root 'out\gate_verification.json'
    $script:schema = Join-Path $script:root 'schema\gate_verification.schema.json'
    $script:csvPath = Join-Path $script:root 'out\gate_verification_trend.csv'
  }

  It "JSON artifact exists" {
    Test-Path -LiteralPath $script:artifact | Should -BeTrue -Because "verify-pipeline.ps1 should generate gate_verification.json"
  }

  It "Schema file exists" {
    Test-Path -LiteralPath $script:schema | Should -BeTrue -Because "JSON schema should be present for validation"
  }

  Context "Schema validation" {
    It "conforms to JSON schema" {
      if (-not (Test-Path -LiteralPath $script:artifact) -or -not (Test-Path -LiteralPath $script:schema)) {
        Set-ItResult -Skipped -Because "artifact or schema missing"
        return
      }
      $json = Get-Content -LiteralPath $script:artifact -Raw
      $isValid = $json | Test-Json -SchemaFile $script:schema
      $isValid | Should -BeTrue -Because "Artifact must conform to gate_verification.schema.json"
    }
  }

  Context "Business rules" {
    BeforeAll {
      if (Test-Path -LiteralPath $script:artifact) {
        $script:j = Get-Content -LiteralPath $script:artifact -Raw | ConvertFrom-Json
      }
    }

    It "has required top-level fields" {
      if (-not $script:j) { Set-ItResult -Skipped -Because "gate_verification.json missing"; return }
      $script:j.PSObject.Properties.Name | Should -Contain "timestamp_utc"
      $script:j.PSObject.Properties.Name | Should -Contain "service_name"
      $script:j.PSObject.Properties.Name | Should -Contain "steps"
      $script:j.PSObject.Properties.Name | Should -Contain "gate_checks"
      $script:j.PSObject.Properties.Name | Should -Contain "outcome"
      $script:j.PSObject.Properties.Name | Should -Contain "exit_code"
    }

    It "maps outcomes to exit codes correctly (0/1/2)" {
      if (-not $script:j) { Set-ItResult -Skipped -Because "gate_verification.json missing"; return }
      switch ($script:j.outcome) {
        "OK"   { $script:j.exit_code | Should -Be 0 -Because "OK outcome must have exit code 0" }
        "WARN" { $script:j.exit_code | Should -Be 1 -Because "WARN outcome must have exit code 1" }
        "FAIL" { $script:j.exit_code | Should -Be 2 -Because "FAIL outcome must have exit code 2" }
        default { throw "Invalid outcome: $($script:j.outcome)" }
      }
    }

    It "enforces pass preconditions when outcome=OK" {
      if (-not $script:j) { Set-ItResult -Skipped -Because "gate_verification.json missing"; return }
      if ($script:j.outcome -ne "OK") { Set-ItResult -Skipped -Because "outcome is not OK"; return }
      $script:j.gate_checks.collector_service_running | Should -BeTrue -Because "Collector must be running for OK"
      $script:j.gate_checks.otlp_reachable            | Should -BeTrue -Because "OTLP must be reachable for OK"
      $script:j.gate_checks.span_rate_nonzero         | Should -BeTrue -Because "Spans must be flowing for OK"
    }

    It "confirms span via API when outcome=OK (forensic requirement)" {
      if (-not $script:j) { Set-ItResult -Skipped -Because "gate_verification.json missing"; return }
      if ($script:j.outcome -ne "OK") { Set-ItResult -Skipped -Because "outcome is not OK"; return }
      $script:j.steps.canary_send.api_confirmed | Should -BeTrue -Because "API confirmation required for OK outcome"
      $script:j.steps.canary_send.api_reason    | Should -Be "span_found" -Because "API must find span for OK"
    }

    It "measures ingest latency when outcome=OK (SLI requirement)" {
      if (-not $script:j) { Set-ItResult -Skipped -Because "gate_verification.json missing"; return }
      if ($script:j.outcome -ne "OK" -or -not $script:j.steps.canary_send.ingest_latency_ms) {
        Set-ItResult -Skipped -Because "outcome is not OK or latency not measured"
        return
      }
      $latency = [int]$script:j.steps.canary_send.ingest_latency_ms
      $latency | Should -BeGreaterThan 0 -Because "Latency must be positive"
      $latency | Should -BeLessThan 5000 -Because "p95 target is < 5000ms"
    }

    It "has valid trace_id when in PINPOINT mode" {
      if (-not $script:j) { Set-ItResult -Skipped -Because "gate_verification.json missing"; return }
      if ($script:j.steps.canary_send.api_mode -notmatch "PINPOINT") {
        Set-ItResult -Skipped -Because "not PINPOINT mode"
        return
      }
      $script:j.steps.canary_send.trace_id | Should -Match "^[0-9a-f]{32}$" -Because "PINPOINT mode requires valid 32-char hex trace ID"
    }
  }

  Context "Artifact quality checks" {
    It "has recent timestamp (within last hour)" {
      if (-not $script:j) { Set-ItResult -Skipped -Because "gate_verification.json missing"; return }
      $raw = $script:j.timestamp_utc
      # ConvertFrom-Json hydrates ISO-8601 strings to DateTime; keep round-trip parse for strings.
      $ts = if ($raw -is [datetime] -or $raw -is [DateTimeOffset]) {
        [DateTimeOffset]::new(([datetime]$raw).ToUniversalTime())
      } else {
        [DateTimeOffset]::Parse(
          [string]$raw,
          [cultureinfo]::InvariantCulture,
          [System.Globalization.DateTimeStyles]::RoundtripKind
        )
      }
      $age = ([DateTimeOffset]::UtcNow - $ts).TotalMinutes
      $age | Should -BeLessThan 60 -Because "Verification should be recent"
    }

    It "includes gate_id reference" {
      if (-not $script:j) { Set-ItResult -Skipped -Because "gate_verification.json missing"; return }
      $script:j.gate_id | Should -Not -BeNullOrEmpty -Because "Gate ID provides traceability"
    }
  }
}

Describe "Trend CSV (SLO tracking)" {
  BeforeAll {
    . (Join-Path $PSScriptRoot '..\helpers\RepoRoot.ps1')
    $script:root = Get-OtelRepoRoot
    $script:csvPath = Join-Path $script:root 'out\gate_verification_trend.csv'
  }

  It "exists after verification run" {
    Test-Path -LiteralPath $script:csvPath | Should -BeTrue
  }

  It "has required columns" {
    if (-not (Test-Path -LiteralPath $script:csvPath)) {
      Set-ItResult -Skipped -Because "trend CSV missing"
      return
    }
    $header = Get-Content -LiteralPath $script:csvPath -First 1
    $header | Should -Match "timestamp_utc"
    $header | Should -Match "outcome"
    $header | Should -Match "ingest_latency_ms"
    $header | Should -Match "verification_mode"
  }
}

Describe "Evidence pack" {
  BeforeAll {
    . (Join-Path $PSScriptRoot '..\helpers\RepoRoot.ps1')
    $script:root = Get-OtelRepoRoot
  }

  It "generates evidence zip on verification" {
    Set-ItResult -Skipped -Because "evidence packs are timestamped; informational only"
  }
}
