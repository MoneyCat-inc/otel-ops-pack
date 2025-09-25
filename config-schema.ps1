# C:\otel\config-schema.ps1
# OTel Configuration Schema Validator
# ASCII only, PowerShell 5.1 compatible

param(
  [string]$ConfigPath = "C:\otel\config.yaml",
  [switch]$CheckSecurity,
  [switch]$CheckPerformance,
  [switch]$CheckPipelines,
  [switch]$CheckMemory,
  [switch]$Verbose,
  [int]$BatchTimeoutMsMin = 100,
  [int]$BatchTimeoutMsMax = 300
)

$ErrorActionPreference = "Stop"
$LogDir = "C:\otel\logs"
$Log = Join-Path $LogDir "config-schema.last.txt"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
function WL($m){ $ts=(Get-Date).ToString("s"); $line="[$ts] $m"; $line | Tee-Object -FilePath $Log -Append }

# Initialize validation results
$ValidationResults = @{
  Passed = 0
  Failed = 0
  Warnings = 0
  Errors = @()
  WarningMessages = @()
}

function Add-Error($message) {
  $ValidationResults.Failed++
  $ValidationResults.Errors += $message
  Write-Host "ERROR: $message" -ForegroundColor Red
  WL "ERROR: $message"
}

function Add-Warning($message) {
  $ValidationResults.Warnings++
  $ValidationResults.WarningMessages += $message
  Write-Host "WARNING: $message" -ForegroundColor Yellow
  WL "WARNING: $message"
}

function Add-Pass($message) {
  $ValidationResults.Passed++
  if ($Verbose) {
    Write-Host "PASS: $message" -ForegroundColor Green
    WL "PASS: $message"
  }
}

# Check if config file exists
if (-not (Test-Path $ConfigPath)) {
  Add-Error "Configuration file not found: $ConfigPath"
  exit 1
}

Add-Pass "Configuration file exists: $ConfigPath"

# Load and parse YAML
try {
  $configContent = Get-Content $ConfigPath -Raw
  Add-Pass "Configuration file loaded successfully"
} catch {
  Add-Error "Failed to load configuration file: $($_.Exception.Message)"
  exit 1
}

# Basic YAML structure validation
$requiredSections = @("extensions", "receivers", "processors", "exporters", "service")
foreach ($section in $requiredSections) {
  if ($configContent -match "(?m)^\s*$section\s*:") {
    Add-Pass "Required section '$section' found"
  } else {
    Add-Error "Required section '$section' not found"
  }
}

# Validate extensions
if ($configContent -match "extensions:") {
  if ($configContent -match "health_check:") {
    Add-Pass "Health check extension configured"
  } else {
    Add-Warning "Health check extension not configured"
  }
  
  if ($configContent -match "file_storage:") {
    Add-Pass "File storage extension configured"
  } else {
    Add-Warning "File storage extension not configured"
  }
}

# Validate receivers
if ($configContent -match "receivers:") {
  if ($configContent -match "otlp:") {
    Add-Pass "OTLP receiver configured"
    
    # Check OTLP endpoints
    if ($configContent -match "endpoint:\s*127\.0\.0\.1:") {
      Add-Pass "OTLP endpoints use loopback addresses"
    } else {
      Add-Error "OTLP endpoints should use loopback addresses (127.0.0.1)"
    }
  } else {
    Add-Error "OTLP receiver not configured"
  }
}

# Validate processors
if ($configContent -match "processors:") {
  if ($configContent -match "memory_limiter:") {
    Add-Pass "Memory limiter processor configured"
  } else {
    Add-Warning "Memory limiter processor not configured"
  }
  
  if ($configContent -match "batch:") {
    Add-Pass "Batch processor configured"
  } else {
    Add-Warning "Batch processor not configured"
  }
  
  if ($configContent -match "resource/defaults:") {
    Add-Pass "Resource defaults processor configured"
  } else {
    Add-Warning "Resource defaults processor not configured"
  }
}

# Validate exporters
if ($configContent -match "exporters:") {
  if ($configContent -match "otlp:") {
    Add-Pass "OTLP exporter configured"
  } else {
    Add-Error "OTLP exporter not configured"
  }
  
  if ($configContent -match "kafka:") {
    Add-Pass "Kafka exporter configured"
  } else {
    Add-Warning "Kafka exporter not configured"
  }
}

# Validate service pipelines
if ($configContent -match "service:") {
  if ($configContent -match "pipelines:") {
    Add-Pass "Service pipelines configured"
    
    # Check for logs pipeline
    if ($configContent -match "logs:") {
      Add-Pass "Logs pipeline configured"
    } else {
      Add-Warning "Logs pipeline not configured"
    }
    
    # Check for traces pipeline
    if ($configContent -match "traces:") {
      Add-Pass "Traces pipeline configured"
    } else {
      Add-Warning "Traces pipeline not configured"
    }
    
    # Check for metrics pipeline
    if ($configContent -match "metrics:") {
      Add-Pass "Metrics pipeline configured"
    } else {
      Add-Warning "Metrics pipeline not configured"
    }
  } else {
    Add-Error "Service pipelines not configured"
  }
} else {
  Add-Error "Service section not configured"
}

# Security validation
if ($CheckSecurity) {
  Write-Host "`nRunning security validation..." -ForegroundColor Cyan
  
  # Check for external network exposure
  if ($configContent -match "endpoint:\s*0\.0\.0\.0:") {
    Add-Error "Configuration exposes endpoints to external networks (0.0.0.0)"
  } else {
    Add-Pass "No external network exposure detected"
  }
  
  # Check for hardcoded secrets
  $secretPatterns = @("api_key:\s*['`"][^'`"]+['`"]", "password:\s*['`"][^'`"]+['`"]", "token:\s*['`"][^'`"]+['`"]")
  foreach ($pattern in $secretPatterns) {
    if ($configContent -match $pattern) {
      Add-Error "Hardcoded secret detected: $($Matches[0])"
    }
  }
  
  # Check for CORS widening
  if ($configContent -match "cors:") {
    Add-Warning "CORS configuration detected - ensure it's not widened beyond loopback"
  }
  
  # Check for TLS settings
  if ($configContent -match "tls:\s*insecure:\s*true") {
    Add-Warning "Insecure TLS detected - ensure it's only for local connections"
  }
}

# Performance validation
if ($CheckPerformance) {
  Write-Host "`nRunning performance validation..." -ForegroundColor Cyan
  
  # Check memory limiter settings
  if ($configContent -match "memory_limiter:") {
    if ($configContent -match "limit_mib:\s*(\d+)") {
      $limit = [int]$Matches[1]
      if ($limit -eq 0) {
        Add-Error "Memory limiter disabled (limit_mib: 0)"
      } elseif ($limit -lt 256) {
        Add-Warning "Memory limit is very low ($limit MiB)"
      } elseif ($limit -gt 2048) {
        Add-Warning "Memory limit is very high ($limit MiB)"
      } else {
        Add-Pass "Memory limit is reasonable ($limit MiB)"
      }
    }
  }
  
  # Check batch settings
  if ($configContent -match "batch:") {
    # Support timeouts expressed in ms or s
    $timeoutMs = $null
    if ($configContent -match "(?m)^\s*batch:\s*[\s\S]*?^\s*timeout:\s*(\d+)ms") {
      $timeoutMs = [int]$Matches[1]
    } elseif ($configContent -match "(?m)^\s*batch:\s*[\s\S]*?^\s*timeout:\s*(\d+)s") {
      $timeoutMs = ([int]$Matches[1]) * 1000
    }
    if ($null -ne $timeoutMs) {
      if ($timeoutMs -le 0) {
        Add-Warning "Batch timeout is 0ms (no batching)"
      } else {
        if ($timeoutMs -lt $BatchTimeoutMsMin -or $timeoutMs -gt $BatchTimeoutMsMax) {
          Add-Warning ("Batch timeout {0}ms outside target A/B window {1}-{2}ms" -f $timeoutMs,$BatchTimeoutMsMin,$BatchTimeoutMsMax)
        } else {
          Add-Pass ("Batch timeout {0}ms within target window {1}-{2}ms" -f $timeoutMs,$BatchTimeoutMsMin,$BatchTimeoutMsMax)
        }
      }
    }
    
    if ($configContent -match "send_batch_size:\s*(\d+)") {
      $batchSize = [int]$Matches[1]
      if ($batchSize -eq 1) {
        Add-Warning "Batch size is 1 (inefficient)"
      } elseif ($batchSize -gt 10000) {
        Add-Warning "Batch size is very large ($batchSize)"
      } else {
        Add-Pass "Batch size is reasonable ($batchSize)"
      }
    }
  }
  
  # Check queue settings
  if ($configContent -match "sending_queue:") {
    if ($configContent -match "queue_size:\s*(\d+)") {
      $queueSize = [int]$Matches[1]
      if ($queueSize -lt 1000) {
        Add-Warning "Queue size is small ($queueSize)"
      } else {
        Add-Pass "Queue size is adequate ($queueSize)"
      }
    }
  }
}

# Pipeline validation
if ($CheckPipelines) {
  Write-Host "`nRunning pipeline validation..." -ForegroundColor Cyan
  
  # Check for complete pipeline configuration
  if ($configContent -match "pipelines:") {
    # Extract pipeline sections
    $pipelineMatch = [regex]::Match($configContent, "pipelines:\s*\n(.*?)(?=\n\s*\w+:|$)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($pipelineMatch.Success) {
      $pipelineContent = $pipelineMatch.Groups[1].Value
      
      # Check each pipeline type
      $pipelineTypes = @("logs", "traces", "metrics")
      foreach ($type in $pipelineTypes) {
        if ($pipelineContent -match "$($type):") {
          Add-Pass "$type pipeline configured"
          
          # Check for receivers
          if ($pipelineContent -match "$($type):\s*\n.*?receivers:\s*\[(.*?)\]") {
            $receivers = $Matches[1] -split "," | ForEach-Object { $_.Trim() }
            if ($receivers.Count -gt 0) {
              Add-Pass "$type pipeline has receivers: $($receivers -join ', ')"
            } else {
              Add-Error "$type pipeline has no receivers"
            }
          }
          
          # Check for processors
          if ($pipelineContent -match "$($type):\s*\n.*?processors:\s*\[(.*?)\]") {
            $processors = $Matches[1] -split "," | ForEach-Object { $_.Trim() }
            if ($processors.Count -gt 0) {
              Add-Pass "$type pipeline has processors: $($processors -join ', ')"
            } else {
              Add-Warning "$type pipeline has no processors"
            }
          }
          
          # Check for exporters
          if ($pipelineContent -match "$($type):\s*\n.*?exporters:\s*\[(.*?)\]") {
            $exporters = $Matches[1] -split "," | ForEach-Object { $_.Trim() }
            if ($exporters.Count -gt 0) {
              Add-Pass "$type pipeline has exporters: $($exporters -join ', ')"
            } else {
              Add-Error "$type pipeline has no exporters"
            }
          }
        }
      }
    }
  }
}

# Memory validation
if ($CheckMemory) {
  Write-Host "`nRunning memory validation..." -ForegroundColor Cyan
  
  # Check for memory limiter
  if ($configContent -match "memory_limiter:") {
    Add-Pass "Memory limiter configured"
    
    # Check memory limit
    if ($configContent -match "limit_mib:\s*(\d+)") {
      $limit = [int]$Matches[1]
      if ($limit -gt 0) {
        Add-Pass "Memory limit set to $limit MiB"
      } else {
        Add-Error "Memory limit is disabled"
      }
    }
    
    # Check spike limit
    if ($configContent -match "spike_limit_mib:\s*(\d+)") {
      $spikeLimit = [int]$Matches[1]
      if ($spikeLimit -gt 0) {
        Add-Pass "Spike limit set to $spikeLimit MiB"
      } else {
        Add-Warning "Spike limit not configured"
      }
    }
  } else {
    Add-Warning "Memory limiter not configured"
  }
  
  # Check for batch processor
  if ($configContent -match "batch:") {
    Add-Pass "Batch processor configured (helps with memory management)"
  } else {
    Add-Warning "Batch processor not configured"
  }
}

# Summary
Write-Host "`nValidation Summary:" -ForegroundColor Cyan
Write-Host "  Passed: $($ValidationResults.Passed)" -ForegroundColor Green
Write-Host "  Warnings: $($ValidationResults.Warnings)" -ForegroundColor Yellow
Write-Host "  Errors: $($ValidationResults.Failed)" -ForegroundColor Red

if ($ValidationResults.Failed -gt 0) {
  Write-Host "`nValidation FAILED with $($ValidationResults.Failed) errors" -ForegroundColor Red
  exit 1
} elseif ($ValidationResults.Warnings -gt 0) {
  Write-Host "`nValidation PASSED with $($ValidationResults.Warnings) warnings" -ForegroundColor Yellow
  exit 0
} else {
  Write-Host "`nValidation PASSED with no issues" -ForegroundColor Green
  exit 0
}