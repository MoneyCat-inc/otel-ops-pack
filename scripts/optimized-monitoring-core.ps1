# Optimized Monitoring Core - Condensed & Low-Latency
# Consolidated common functionality for maximum efficiency
# Usage: . .\scripts\optimized-monitoring-core.ps1

param(
    [hashtable]$Config = @{},
    [switch]$Silent = $false
)

# Core optimization settings
$script:OptimizedConfig = @{
    BatchTimeout = 200ms
    BatchSize = 1024
    MaxConcurrency = 8
    RetryCount = 3
    RetryInterval = 100ms
    CacheTimeout = 30s
    MemoryLimit = 1024MB
    PollInterval = 200ms
} + $Config

# Optimized logging function
function Write-OptimizedLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [System.ConsoleColor]$Color = "White"
    )
    if (-not $Silent) {
        $timestamp = Get-Date -Format "HH:mm:ss.fff"
        $prefix = switch ($Level) {
            "ERROR" { "❌" }
            "WARN" { "⚠️" }
            "SUCCESS" { "✅" }
            "INFO" { "ℹ️" }
            default { "📊" }
        }
        Write-Host "[$timestamp] $prefix $Message" -ForegroundColor $Color
    }
}

# Optimized health check with caching
$script:healthCache = @{}
function Test-ServiceHealth {
    param(
        [string]$Service,
        [string]$Endpoint,
        [int]$TimeoutMs = 1000
    )
    
    $cacheKey = "$Service-$Endpoint"
    $now = Get-Date
    
    # Check cache first
    if ($script:healthCache.ContainsKey($cacheKey)) {
        $cached = $script:healthCache[$cacheKey]
        if (($now - $cached.Timestamp).TotalSeconds -lt $script:OptimizedConfig.CacheTimeout.TotalSeconds) {
            return $cached.Result
        }
    }
    
    # Perform health check
    try {
        $response = Invoke-WebRequest -Uri $Endpoint -TimeoutSec ($TimeoutMs / 1000) -UseBasicParsing
        $result = $response.StatusCode -eq 200
    } catch {
        $result = $false
    }
    
    # Cache result
    $script:healthCache[$cacheKey] = @{
        Result = $result
        Timestamp = $now
    }
    
    return $result
}

# Optimized batch processing
function Invoke-OptimizedBatch {
    param(
        [array]$Items,
        [scriptblock]$ProcessBlock,
        [int]$MaxConcurrency = $script:OptimizedConfig.MaxConcurrency
    )
    
    $batches = @()
    for ($i = 0; $i -lt $Items.Count; $i += $script:OptimizedConfig.BatchSize) {
        $batch = $Items | Select-Object -Skip $i -First $script:OptimizedConfig.BatchSize
        $batches += ,$batch
    }
    
    $results = @()
    foreach ($batch in $batches) {
        $batchResults = $batch | ForEach-Object -Parallel {
            & $using:ProcessBlock $_
        } -ThrottleLimit $MaxConcurrency
        
        $results += $batchResults
    }
    
    return $results
}

# Optimized metrics collection
function Get-OptimizedMetrics {
    param(
        [string]$Service,
        [hashtable]$Metrics = @{}
    )
    
    $metrics = @{
        Timestamp = Get-Date
        Service = $Service
        Latency = @{}
        Throughput = @{}
        Errors = @{}
    }
    
    # Collect latency metrics
    $latencyStart = Get-Date
    $healthCheck = Test-ServiceHealth $Service "http://localhost:8080/api/v1/health"
    $latencyEnd = Get-Date
    $metrics.Latency.HealthCheck = ($latencyEnd - $latencyStart).TotalMilliseconds
    
    # Collect throughput metrics (simplified)
    $metrics.Throughput.BatchSize = $script:OptimizedConfig.BatchSize
    $metrics.Throughput.BatchTimeout = $script:OptimizedConfig.BatchTimeout
    
    # Collect error metrics
    $metrics.Errors.RetryCount = $script:OptimizedConfig.RetryCount
    $metrics.Errors.RetryInterval = $script:OptimizedConfig.RetryInterval
    
    return $metrics
}

# Optimized error handling with exponential backoff
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = $script:OptimizedConfig.RetryCount,
        [int]$BaseDelay = 100
    )
    
    $attempt = 0
    $lastError = $null
    
    while ($attempt -lt $MaxRetries) {
        try {
            return & $ScriptBlock
        } catch {
            $lastError = $_
            $attempt++
            
            if ($attempt -lt $MaxRetries) {
                $delay = $BaseDelay * [math]::Pow(2, $attempt - 1)
                Write-OptimizedLog "Retry $attempt/$MaxRetries in ${delay}ms" "WARN" "Yellow"
                Start-Sleep -Milliseconds $delay
            }
        }
    }
    
    throw $lastError
}

# Optimized configuration validation
function Test-OptimizedConfig {
    param([hashtable]$Config)
    
    $issues = @()
    
    # Validate batch settings
    if ($Config.BatchTimeout -gt 1000ms) {
        $issues += "Batch timeout too high: $($Config.BatchTimeout)"
    }
    
    if ($Config.BatchSize -lt 512) {
        $issues += "Batch size too small: $($Config.BatchSize)"
    }
    
    # Validate memory settings
    if ($Config.MemoryLimit -lt 512MB) {
        $issues += "Memory limit too low: $($Config.MemoryLimit)"
    }
    
    # Validate concurrency
    if ($Config.MaxConcurrency -gt 16) {
        $issues += "Max concurrency too high: $($Config.MaxConcurrency)"
    }
    
    return $issues
}

# Initialize optimized monitoring
function Initialize-OptimizedMonitoring {
    param([hashtable]$Config = @{})
    
    $script:OptimizedConfig = $script:OptimizedConfig + $Config
    
    # Validate configuration
    $issues = Test-OptimizedConfig $script:OptimizedConfig
    if ($issues.Count -gt 0) {
        Write-OptimizedLog "Configuration issues detected:" "WARN" "Yellow"
        foreach ($issue in $issues) {
            Write-OptimizedLog "  - $issue" "WARN" "Yellow"
        }
    }
    
    # Clear cache
    $script:healthCache.Clear()
    
    Write-OptimizedLog "Optimized monitoring initialized" "SUCCESS" "Green"
    Write-OptimizedLog "Batch: $($script:OptimizedConfig.BatchSize) items, $($script:OptimizedConfig.BatchTimeout) timeout" "INFO" "Cyan"
    Write-OptimizedLog "Concurrency: $($script:OptimizedConfig.MaxConcurrency) workers" "INFO" "Cyan"
    Write-OptimizedLog "Memory: $($script:OptimizedConfig.MemoryLimit)" "INFO" "Cyan"
}

# Export optimized functions
Export-ModuleMember -Function @(
    'Write-OptimizedLog',
    'Test-ServiceHealth',
    'Invoke-OptimizedBatch',
    'Get-OptimizedMetrics',
    'Invoke-WithRetry',
    'Test-OptimizedConfig',
    'Initialize-OptimizedMonitoring'
)
