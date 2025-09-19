# GPU Monitoring Script for RTX 2080 Super
# Monitors GPU utilization, memory usage, and temperature

param(
    [int]$Duration = 60,
    [int]$Interval = 5
)

$ErrorActionPreference = "Stop"

function Get-GPUStatus {
    try {
        $gpuInfo = nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu,temperature.gpu,power.draw --format=csv,noheader,nounits
        return $gpuInfo
    }
    catch {
        Write-Warning "Failed to get GPU status: $($_.Exception.Message)"
        return $null
    }
}

function Write-GPUReport {
    param([string]$Status)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $reportFile = "C:\otel\.agent\reports\gpu_monitor_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $report = @"
=== GPU Monitor Report ===
Timestamp: $timestamp
Duration: $Duration seconds
Interval: $Interval seconds

$Status
"@
    
    $report | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Host "GPU report saved to: $reportFile"
}

function Start-GPUMonitoring {
    Write-Host "=== GPU Monitoring Started ==="
    Write-Host "Monitoring RTX 2080 Super for $Duration seconds (every $Interval seconds)"
    Write-Host ""
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $samples = @()
    
    while ((Get-Date) -lt $endTime) {
        $gpuStatus = Get-GPUStatus
        if ($gpuStatus) {
            $samples += @{
                Timestamp = Get-Date
                Status = $gpuStatus
            }
            
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $gpuStatus"
        }
        
        Start-Sleep -Seconds $Interval
    }
    
    # Generate summary
    if ($samples.Count -gt 0) {
        $avgUtil = ($samples | ForEach-Object { ($_.Status -split ',')[2] } | Measure-Object -Average).Average
        $maxUtil = ($samples | ForEach-Object { ($_.Status -split ',')[2] } | Measure-Object -Maximum).Maximum
        $avgTemp = ($samples | ForEach-Object { ($_.Status -split ',')[4] } | Measure-Object -Average).Average
        $maxTemp = ($samples | ForEach-Object { ($_.Status -split ',')[4] } | Measure-Object -Maximum).Maximum
        
        $summary = @"
=== GPU Monitoring Summary ===
Samples collected: $($samples.Count)
Average GPU utilization: $([math]::Round($avgUtil, 1))%
Maximum GPU utilization: $([math]::Round($maxUtil, 1))%
Average temperature: $([math]::Round($avgTemp, 1))°C
Maximum temperature: $([math]::Round($maxTemp, 1))°C

Recent samples:
$($samples[-5..-1] | ForEach-Object { "[$($_.Timestamp.ToString('HH:mm:ss'))] $($_.Status)" } | Out-String)
"@
        
        Write-GPUReport -Status $summary
        Write-Host $summary
    }
    
    Write-Host "=== GPU Monitoring Complete ==="
}

# Main execution
try {
    Start-GPUMonitoring
}
catch {
    Write-Error "GPU monitoring failed: $($_.Exception.Message)"
    exit 1
}

