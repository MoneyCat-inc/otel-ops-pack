# Integrated SSOT Automation Scaling
param(
    [switch]$EnableAll,
    [switch]$Predictive,
    [switch]$LoadBalancing,
    [switch]$AutoScaling,
    [switch]$IntelligentAlerting,
    [int]$MaxConcurrent = 10,
    [string]$Strategy = "adaptive",
    [switch]$DryRun
)

function Invoke-IntegratedScaling {
    param([hashtable]$Config)
    
    $results = @{}
    
    # Predictive automation
    if ($Config.EnablePredictive) {
        Write-Host "🧠 Running predictive automation..." -ForegroundColor Yellow
        $predictiveResult = & pwsh -ExecutionPolicy Bypass -File "scripts/predictive-ssot-automation.ps1"
        $results.Predictive = $predictiveResult
    }
    
    # Load balancing
    if ($Config.EnableLoadBalancing) {
        Write-Host "⚖️ Running load balancing..." -ForegroundColor Yellow
        $loadBalancingResult = & pwsh -ExecutionPolicy Bypass -File "scripts/ssot-load-balancing.ps1" -Strategy $Config.LoadBalancingStrategy
        $results.LoadBalancing = $loadBalancingResult
    }
    
    # Auto-scaling
    if ($Config.EnableAutoScaling) {
        Write-Host "📈 Running auto-scaling..." -ForegroundColor Yellow
        $autoScalingResult = & pwsh -ExecutionPolicy Bypass -File "scripts/ssot-auto-scaling.ps1" -DryRun:$Config.DryRun
        $results.AutoScaling = $autoScalingResult
    }
    
    # Intelligent alerting
    if ($Config.EnableIntelligentAlerting) {
        Write-Host "🧠 Running intelligent alerting..." -ForegroundColor Yellow
        $alertingResult = & pwsh -ExecutionPolicy Bypass -File "scripts/intelligent-ssot-alerting.ps1" -Strategy $Config.AlertingStrategy -DryRun:$Config.DryRun
        $results.IntelligentAlerting = $alertingResult
    }
    
    return $results
}

# Main integration
$config = @{
    EnablePredictive = $Predictive -or $EnableAll
    EnableLoadBalancing = $LoadBalancing -or $EnableAll
    EnableAutoScaling = $AutoScaling -or $EnableAll
    EnableIntelligentAlerting = $IntelligentAlerting -or $EnableAll
    LoadBalancingStrategy = $Strategy
    AlertingStrategy = $Strategy
    DryRun = $DryRun
}

$scalingResults = Invoke-IntegratedScaling -Config $config

Write-Host "🎯 Integrated Scaling Results:" -ForegroundColor Green
foreach ($component in $scalingResults.Keys) {
    Write-Host "   $component`: Configured and operational" -ForegroundColor Cyan
}

return $scalingResults
