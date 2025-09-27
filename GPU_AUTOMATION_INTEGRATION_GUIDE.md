# 🎮 GPU Automation Integration Guide

## Overview

This guide shows you how to seamlessly integrate GPU sidecars into your existing OpenTelemetry automated workflow system. The GPU infrastructure provides high-throughput telemetry processing while maintaining the hot path for real-time observability.

## 🚀 Quick Start (5 minutes)

### 1. Quick Setup
```powershell
# One-command GPU integration
.\scripts\gpu-automation-quickstart.ps1 -QuickSetup
```

### 2. Check Status
```powershell
# Verify GPU sidecars are running
.\scripts\gpu-workflow-orchestrator.ps1 -Action status
```

### 3. View Results
- **SigNoz UI**: http://localhost:8080
- **GPU Metrics**: Check `gpu.*` metrics in SigNoz
- **GPU Dashboard**: Import `artifacts/signoz-gpu-sidecar-dashboard.json`

## 🔧 Full Integration (15 minutes)

### 1. Complete Integration
```powershell
# Full production-ready integration
.\scripts\gpu-automation-quickstart.ps1 -FullIntegration
```

This will:
- ✅ Integrate GPU sidecars with existing workflow
- ✅ Deploy GPU infrastructure
- ✅ Set up automated monitoring
- ✅ Configure scheduled tasks
- ✅ Set up alerting system
- ✅ Import GPU dashboard
- ✅ Validate integration

### 2. Verify Integration
```powershell
# Validate all components
.\scripts\gpu-automation-quickstart.ps1 -ValidateOnly
```

## 📊 GPU Automation Components

### 1. **GPU Workflow Orchestrator** (`scripts/gpu-workflow-orchestrator.ps1`)
**Purpose**: Central orchestration of GPU sidecar lifecycle and monitoring

**Actions**:
- `start` - Start GPU sidecars and workflow
- `stop` - Stop GPU sidecars and cleanup
- `restart` - Restart GPU workflow
- `status` - Check GPU workflow status
- `health` - Health check all components
- `monitor` - Start monitoring loop
- `test` - Run integration tests
- `metrics` - Start metrics collection
- `deploy` - Deploy complete GPU stack

**Usage Examples**:
```powershell
# Start GPU workflow with monitoring
.\scripts\gpu-workflow-orchestrator.ps1 -Action start -IncludeGPU -IncludeMonitoring

# Run health check
.\scripts\gpu-workflow-orchestrator.ps1 -Action health

# Start monitoring for 30 minutes
.\scripts\gpu-workflow-orchestrator.ps1 -Action monitor -DurationMinutes 30

# Run integration test
.\scripts\gpu-workflow-orchestrator.ps1 -Action test
```

### 2. **GPU Automated Monitoring** (`scripts/gpu-automated-monitoring.ps1`)
**Purpose**: Automated monitoring with scheduled tasks and alerting

**Features**:
- Scheduled task management
- Health monitoring with thresholds
- Metrics collection automation
- Alerting system integration
- Dashboard deployment

**Usage Examples**:
```powershell
# Set up complete automated monitoring
.\scripts\gpu-automated-monitoring.ps1 -EnableScheduledTasks -EnableHealthChecks -EnableMetricsCollection -EnableAlerting -EnableDashboard

# Set up with custom intervals
.\scripts\gpu-automated-monitoring.ps1 -ScheduleInterval 10 -MetricsInterval 30 -HealthThreshold 90
```

### 3. **GPU Integration Automation** (`scripts/gpu-integration-automation.ps1`)
**Purpose**: Seamless integration with existing workflow infrastructure

**Actions**:
- `integrate` - Integrate with existing workflow
- `validate` - Validate integration
- `deploy` - Deploy GPU infrastructure
- `monitor` - Start integration monitoring
- `report` - Generate integration report
- `cleanup` - Clean up integration

**Usage Examples**:
```powershell
# Integrate with existing workflow
.\scripts\gpu-integration-automation.ps1 -Action integrate -IncludeExistingWorkflow

# Deploy with all features
.\scripts\gpu-integration-automation.ps1 -Action deploy -IncludeHealthChecks -IncludeMetrics -IncludeAlerts -IncludeDashboard

# Generate comprehensive report
.\scripts\gpu-integration-automation.ps1 -Action report
```

### 4. **GPU Sidecar Management** (`scripts/manage-gpu-sidecars.ps1`)
**Purpose**: Direct management of GPU sidecar containers

**Actions**:
- `start` - Start GPU sidecars
- `stop` - Stop GPU sidecars
- `restart` - Restart GPU sidecars
- `status` - Check sidecar status
- `logs` - View sidecar logs
- `test` - Test sidecar health

**Usage Examples**:
```powershell
# Start all GPU sidecars
.\scripts\manage-gpu-sidecars.ps1 -Action start

# Check status
.\scripts\manage-gpu-sidecars.ps1 -Action status

# View logs
.\scripts\manage-gpu-sidecars.ps1 -Action logs
```

## 🔄 Integration with Existing Workflow

### Scheduled Tasks Integration

The GPU automation integrates with your existing scheduled task infrastructure:

**New Scheduled Tasks**:
- `OTel-GPUHealthCheck` - GPU health check every 5 minutes
- `OTel-GPUMetricsCollection` - GPU metrics collection every 15 minutes
- `OTel-GPUIntegrationTest` - GPU integration test every hour
- `OTel-GPUStatusReport` - Daily GPU status report at 9 AM

**Enhanced Existing Tasks**:
- All existing OTel monitoring tasks now include GPU checks
- Health checks include GPU sidecar status
- Canary tests include GPU integration validation

### Monitoring Integration

**Enhanced Monitoring Scripts**:
- `scripts/enhanced-monitoring-with-gpu.ps1` - GPU-enhanced monitoring
- `scripts/enhanced-scheduled-task.ps1` - GPU-enhanced scheduled tasks

**Integration Points**:
```powershell
# Run existing monitoring with GPU integration
.\scripts\enhanced-monitoring-with-gpu.ps1 -IncludeGPU -IncludeGPUMetrics -IncludeGPUAlerts

# Run existing scheduled tasks with GPU integration
.\scripts\enhanced-scheduled-task.ps1 -IncludeGPU -TaskType monitoring
```

### Alerting Integration

**GPU Alert Configuration** (`alerts/gpu-alerts.json`):
- GPU Sidecar Health alerts
- GPU Temperature High alerts
- GPU Memory Usage High alerts

**Integration with Existing Alerts**:
- GPU alerts integrate with existing SigNoz alerting
- Webhook notifications for GPU issues
- Escalation based on existing alert policies

### Dashboard Integration

**GPU Dashboard** (`artifacts/signoz-gpu-sidecar-dashboard.json`):
- GPU utilization metrics
- Sidecar performance metrics
- Buffer processing metrics
- Integration health metrics

**Integration Steps**:
1. Import GPU dashboard to SigNoz
2. Configure GPU-specific queries
3. Set up GPU alert thresholds
4. Monitor GPU metrics alongside existing metrics

## 📈 Monitoring and Metrics

### GPU Metrics Available

**Hardware Metrics**:
- `gpu.utilization.percent` - GPU utilization percentage
- `gpu.memory.used.bytes` - GPU memory used
- `gpu.memory.total.bytes` - GPU total memory
- `gpu.memory.utilization.percent` - GPU memory utilization
- `gpu.temperature.celsius` - GPU temperature
- `gpu.power.draw.watts` - GPU power consumption
- `gpu.clock.graphics.mhz` - GPU graphics clock
- `gpu.clock.memory.mhz` - GPU memory clock
- `gpu.fan.speed.percent` - GPU fan speed

**Sidecar Metrics**:
- `gpu.compression.processing_time_ms` - Compression processing time
- `gpu.aggregation.processing_time_ms` - Aggregation processing time
- `gpu.inference.processing_time_ms` - Inference processing time
- `gpu.sidecar.health` - Sidecar health status
- `gpu.buffer.file_count` - Buffer file count
- `gpu.integration.health` - Integration health status

### SigNoz Queries

**GPU Utilization Query**:
```sql
SELECT gpu.utilization.percent FROM metrics WHERE gpu.utilization.percent IS NOT NULL ORDER BY timestamp DESC
```

**GPU Memory Usage Query**:
```sql
SELECT gpu.memory.utilization.percent FROM metrics WHERE gpu.memory.utilization.percent IS NOT NULL ORDER BY timestamp DESC
```

**GPU Sidecar Health Query**:
```sql
SELECT gpu.sidecar.health FROM metrics WHERE gpu.sidecar.health IS NOT NULL ORDER BY timestamp DESC
```

## 🚨 Alerting Configuration

### GPU Alert Rules

**Critical Alerts**:
- GPU sidecar service down
- GPU temperature > 85°C
- GPU memory usage > 95%

**Warning Alerts**:
- GPU utilization > 90%
- GPU memory usage > 80%
- Integration health degraded

### Alert Configuration

```json
{
  "alerts": [
    {
      "name": "GPU Sidecar Health",
      "description": "GPU sidecar service health check",
      "query": "gpu.sidecar.health == 0",
      "threshold": 1,
      "duration": "5m",
      "severity": "critical"
    },
    {
      "name": "GPU Temperature High",
      "description": "GPU temperature exceeds safe threshold",
      "query": "gpu.temperature.celsius > 85",
      "threshold": 1,
      "duration": "2m",
      "severity": "warning"
    }
  ]
}
```

## 🔧 Troubleshooting

### Common Issues

**1. GPU Sidecars Not Starting**:
```powershell
# Check GPU prerequisites
.\scripts\gpu-workflow-orchestrator.ps1 -Action status

# Check Docker NVIDIA runtime
docker info | Select-String "nvidia"

# Check GPU availability
nvidia-smi
```

**2. Integration Test Failures**:
```powershell
# Run detailed integration test
.\scripts\gpu-workflow-orchestrator.ps1 -Action test

# Check individual sidecar health
.\scripts\manage-gpu-sidecars.ps1 -Action test
```

**3. Monitoring Not Working**:
```powershell
# Check scheduled tasks
Get-ScheduledTask -TaskName "*OTel*"

# Check monitoring processes
Get-Process -Name "pwsh" | Where-Object { $_.CommandLine -match "gpu" }

# View monitoring logs
Get-Content artifacts\gpu-*.log -Tail 20
```

### Health Check Commands

```powershell
# Quick health check
.\scripts\gpu-workflow-orchestrator.ps1 -Action health

# Detailed status
.\scripts\gpu-workflow-orchestrator.ps1 -Action status

# Integration validation
.\scripts\gpu-integration-automation.ps1 -Action validate
```

### Log Locations

- **GPU Workflow Logs**: `artifacts/gpu-workflow-*.log`
- **GPU Monitoring Logs**: `artifacts/gpu-*-monitor-*.log`
- **GPU Alert Logs**: `artifacts/gpu-alerts-*.log`
- **ECRR Reports**: `artifacts/gpu-*-orchestrator-*.json`

## 📋 Best Practices

### 1. **Gradual Integration**
- Start with Quick Setup for testing
- Use Full Integration for production
- Validate each step before proceeding

### 2. **Monitoring Strategy**
- Set up health checks first
- Configure alerts with appropriate thresholds
- Monitor GPU metrics alongside existing metrics

### 3. **Resource Management**
- Monitor GPU memory usage
- Set up alerts for high utilization
- Plan for GPU memory cleanup

### 4. **Automation Maintenance**
- Regular validation of integration
- Update scheduled tasks as needed
- Monitor ECRR reports for issues

## 🎯 Next Steps

### 1. **Production Deployment**
```powershell
# Deploy to production
.\scripts\gpu-automation-quickstart.ps1 -FullIntegration

# Set up monitoring
.\scripts\gpu-automated-monitoring.ps1 -EnableScheduledTasks -EnableHealthChecks -EnableMetricsCollection -EnableAlerting
```

### 2. **Customization**
- Modify alert thresholds based on your needs
- Customize dashboard panels for your metrics
- Adjust monitoring intervals for your environment

### 3. **Scaling**
- Monitor GPU utilization patterns
- Scale GPU resources based on demand
- Optimize batch sizes for your workload

### 4. **Integration with CI/CD**
- Add GPU health checks to your CI pipeline
- Include GPU integration tests in your test suite
- Set up automated GPU monitoring in your deployment pipeline

## 📞 Support

### Getting Help

1. **Check Logs**: Review ECRR reports and monitoring logs
2. **Run Diagnostics**: Use validation and health check scripts
3. **Review Documentation**: Check this guide and script comments
4. **Test Integration**: Use dry-run mode to test changes

### Useful Commands

```powershell
# Quick diagnostic
.\scripts\gpu-automation-quickstart.ps1 -ValidateOnly

# Full system check
.\scripts\gpu-integration-automation.ps1 -Action validate

# Generate status report
.\scripts\gpu-integration-automation.ps1 -Action report
```

---

## 🎮 GPU Automation Complete!

Your GPU infrastructure is now fully integrated into your automated workflow system. The GPU sidecars provide high-throughput telemetry processing while maintaining the hot path for real-time observability in SigNoz.

**Key Benefits**:
- ✅ **Seamless Integration**: Works with existing automation
- ✅ **Automated Monitoring**: Scheduled tasks and health checks
- ✅ **Comprehensive Alerting**: GPU-specific alerts and notifications
- ✅ **Performance Optimization**: GPU-accelerated processing
- ✅ **Production Ready**: Full deployment and monitoring capabilities

**Monitor Your GPU Infrastructure**:
- **SigNoz UI**: http://localhost:8080
- **GPU Dashboard**: Import `artifacts/signoz-gpu-sidecar-dashboard.json`
- **Status Commands**: Use the orchestration scripts for real-time status
- **Reports**: Check ECRR reports for detailed analysis

Happy GPU-powered observability! 🚀
