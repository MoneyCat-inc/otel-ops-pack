#Requires -Version 7.0

<#
.SYNOPSIS
    Test script for the Bosscat Parallel Agent Framework
    Verifies all components work correctly
#>

[CmdletBinding()]
param(
    [switch]$QuickTest,
    [switch]$FullTest,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "🧪 Testing Bosscat Parallel Agent Framework" -ForegroundColor Green

# Test 1: Basic Demo
if ($QuickTest -or $FullTest) {
    Write-Host "`n📋 Test 1: Basic Demo" -ForegroundColor Cyan
    try {
        if ($DryRun) {
            Write-Host "  Running demo in dry-run mode..." -ForegroundColor Yellow
            & .\scripts\bosscat-parallel-agent-demo.ps1 -DemoType "basic" -TaskCount 5 -MaxConcurrent 2 -DryRun
        } else {
            Write-Host "  Running basic demo..." -ForegroundColor Yellow
            & .\scripts\bosscat-parallel-agent-demo.ps1 -DemoType "basic" -TaskCount 5 -MaxConcurrent 2
        }
        Write-Host "  ✅ Basic demo test passed" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Basic demo test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 2: Task Decomposition
if ($FullTest) {
    Write-Host "`n🔍 Test 2: Task Decomposition" -ForegroundColor Cyan
    try {
        $taskDef = @'
{
    "name": "test-batch-processing",
    "type": "batch-processing",
    "input": {
        "itemCount": 100,
        "processingType": "validation",
        "parallelSettings": [2, 4, 8]
    }
}
'@
        
        Write-Host "  Testing task decomposition..." -ForegroundColor Yellow
        & .\scripts\atomic-task-manager.ps1 -TaskDefinition $taskDef -DecompositionStrategy "parallel" -OutputPath "artifacts/test-decomposition"
        Write-Host "  ✅ Task decomposition test passed" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Task decomposition test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 3: Workspace Isolation
if ($FullTest) {
    Write-Host "`n🏠 Test 3: Workspace Isolation" -ForegroundColor Cyan
    try {
        Write-Host "  Testing workspace isolation..." -ForegroundColor Yellow
        $workspace = & .\scripts\workspace-isolation-manager.ps1 -AgentId "test-agent-001" -WorkspaceType "temporary" -IsolationLevel "filesystem"
        
        if ($workspace -and $workspace.WorkspacePath) {
            Write-Host "  ✅ Workspace isolation test passed" -ForegroundColor Green
            Write-Host "    Workspace: $($workspace.WorkspacePath)" -ForegroundColor Gray
        } else {
            Write-Host "  ❌ Workspace isolation test failed: No workspace returned" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Workspace isolation test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: ECRR Framework
if ($FullTest) {
    Write-Host "`n📋 Test 4: ECRR Framework" -ForegroundColor Cyan
    try {
        Write-Host "  Testing ECRR framework..." -ForegroundColor Yellow
        $ecrr = & .\scripts\parallel-agent-ecrr-framework.ps1 -SessionId "test-session-001" -AgentId "test-agent-001" -OperationType "test-operation"
        
        if ($ecrr -and $ecrr.Session) {
            Write-Host "  ✅ ECRR framework test passed" -ForegroundColor Green
            Write-Host "    Session ID: $($ecrr.Session.SessionId)" -ForegroundColor Gray
        } else {
            Write-Host "  ❌ ECRR framework test failed: No ECRR session returned" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ ECRR framework test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 5: Telemetry Integration (if SigNoz is running)
if ($FullTest) {
    Write-Host "`n📊 Test 5: Telemetry Integration" -ForegroundColor Cyan
    try {
        # Check if SigNoz is running
        $signozHealth = $null
        try {
            $signozHealth = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
        } catch {
            Write-Host "  ⏸️ SigNoz not running, skipping telemetry test" -ForegroundColor Yellow
        }
        
        if ($signozHealth) {
            Write-Host "  Testing telemetry integration..." -ForegroundColor Yellow
            $telemetry = & .\scripts\agent-telemetry-integration.ps1 -AgentId "test-agent-001" -TelemetryType "all" -SamplingRate 0.1
            
            if ($telemetry -and $telemetry.Collector) {
                Write-Host "  ✅ Telemetry integration test passed" -ForegroundColor Green
                Write-Host "    Telemetry collector initialized" -ForegroundColor Gray
            } else {
                Write-Host "  ❌ Telemetry integration test failed: No telemetry collector returned" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "  ❌ Telemetry integration test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 6: Parallel Orchestration
if ($FullTest) {
    Write-Host "`n🚀 Test 6: Parallel Orchestration" -ForegroundColor Cyan
    try {
        $taskSpec = @'
{
    "name": "test-parallel-orchestration",
    "type": "batch-processing",
    "input": {
        "reportCount": 50,
        "parallelSettings": [2, 4]
    },
    "output": {
        "artifacts": ["test-results.json"],
        "telemetry": false
    }
}
'@
        
        Write-Host "  Testing parallel orchestration..." -ForegroundColor Yellow
        & .\scripts\parallel-agent-orchestrator.ps1 -TaskSpec $taskSpec -MaxConcurrentAgents 4 -DryRun
        Write-Host "  ✅ Parallel orchestration test passed" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Parallel orchestration test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Framework Testing Complete!" -ForegroundColor Green
Write-Host "Check the output above for test results." -ForegroundColor Cyan

if ($QuickTest) {
    Write-Host "`n💡 Run with -FullTest to test all components" -ForegroundColor Yellow
}
