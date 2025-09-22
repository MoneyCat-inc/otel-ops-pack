# GPU Sidecar Deployment Guide 🚀

## Overview

This guide provides step-by-step instructions for deploying the complete GPU sidecar infrastructure to production. The system includes three GPU-accelerated sidecars (compression, aggregation, ML inference) with comprehensive monitoring, alerting, and automated validation.

## Prerequisites

- Windows 11 with PowerShell 7+
- NVIDIA GPU with CUDA support
- WSL2 with GPU support enabled
- Docker Desktop with NVIDIA runtime
- SigNoz running on localhost:8080
- Administrator privileges for Task Scheduler setup

## Quick Start

### 1. Verify Prerequisites
```powershell
# Check GPU availability
nvidia-smi

# Check WSL2 GPU support
wsl --list --verbose

# Check Docker GPU runtime
docker info | Select-String "nvidia"

# Check SigNoz
Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing
```

### 2. Deploy GPU Sidecars
```powershell
# Start all GPU sidecars
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action start

# Verify deployment
pwsh -File scripts/test-gpu-sidecars.ps1
```

### 3. Set Up Monitoring
```powershell
# Run as Administrator
pwsh -File scripts/setup-automated-monitoring.ps1

# Set up dashboard and alerts
pwsh -File scripts/final-deployment-checklist.ps1
```

## Detailed Deployment Steps

### Phase 1: Infrastructure Setup

#### 1.1 Start GPU Sidecars
```powershell
# Start all services
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action start

# Check status
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action status

# View logs
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action logs
```

#### 1.2 Verify Services
```powershell
# Run integration tests
pwsh -File scripts/test-gpu-sidecars.ps1

# Run production validation
pwsh -File scripts/validate-production-gpu.ps1 -Iterations 10

# Run complete verification
pwsh -File verify-integration.ps1
```

### Phase 2: Monitoring Setup

#### 2.1 Import SigNoz Dashboard
1. Open SigNoz UI: http://localhost:8080
2. Go to Settings → Dashboards
3. Click "Import Dashboard"
4. Upload: `artifacts/signoz-gpu-sidecar-dashboard.json`
5. Configure data sources and save

#### 2.2 Configure Alerts
1. Open SigNoz UI: http://localhost:8080
2. Go to Settings → Alerts
3. Create new alerts using conditions from `alerts/gpu-sidecar-alerts.json`:
   - **GPU Sidecar Health Down** (critical): `gpu_sidecar_health_status == 0`
   - **High GPU Fallback Rate** (warning): `rate(gpu_sidecar_fallback_total[5m]) > 0.1`
   - **GPU Buffer Queue Depth High** (warning): `gpu_buffer_queue_depth > 1000`
   - **Low GPU Processing Efficiency** (warning): `rate(gpu_processing_efficiency[5m]) < 0.5`
   - **GPU Memory Usage High** (critical): `gpu_memory_used_bytes / gpu_memory_total_bytes > 0.9`
4. Set appropriate thresholds and notification channels
5. Test alerts to ensure they work correctly

### Phase 3: Automation Setup

#### 3.1 Set Up Task Scheduler (Run as Administrator)
```powershell
# Create automated monitoring tasks
pwsh -File scripts/setup-automated-monitoring.ps1
```

This creates the following scheduled tasks:
- **GPU Sidecar Production Monitoring**: Daily at 2:00 AM
- **GPU Sidecar Watchdog**: At startup (continuous monitoring)
- **GPU Sidecar Health Check**: Every 15 minutes
- **GPU Sidecar Log Rotation**: Daily at 1:00 AM

#### 3.2 Verify Automation
```powershell
# Check Task Scheduler
taskschd.msc

# Look for tasks starting with "GPU Sidecar"
# Verify they are enabled and configured correctly
```

### Phase 4: Production Validation

#### 4.1 Run Production Tests
```powershell
# Comprehensive production validation
pwsh -File scripts/validate-production-gpu.ps1 -Iterations 20 -DelayMs 500

# Generate production report
pwsh -File scripts/production-monitoring.ps1 -Environment production
```

#### 4.2 Monitor Performance
```powershell
# Start continuous monitoring
pwsh -File scripts/gpu-watchdog.ps1

# Check logs
Get-Content logs/gpu-watchdog.log -Tail 20
```

## Service Management

### Daily Operations
```powershell
# Quick health check
pwsh -File scripts/test-gpu-sidecars.ps1

# Service management
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action status
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action restart
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action logs

# Production validation
pwsh -File scripts/validate-production-gpu.ps1 -Iterations 10
```

### Monitoring Commands
```powershell
# Start watchdog
pwsh -File scripts/gpu-watchdog.ps1

# Generate monitoring report
pwsh -File scripts/production-monitoring.ps1

# Check queue depth
Get-ChildItem gpu-buffers -Recurse | Measure-Object | Select-Object Count
```

## Troubleshooting

### Common Issues

#### Sidecar Not Responding
```powershell
# Check container status
docker ps

# Check logs
docker logs gpu-compression-sidecar
docker logs gpu-aggregation-sidecar
docker logs gpu-inference-sidecar

# Restart services
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action restart
```

#### High Queue Depth
```powershell
# Check buffer directories
Get-ChildItem gpu-buffers -Recurse

# Monitor processing efficiency
# Check SigNoz dashboard for metrics
```

#### GPU Memory Issues
```powershell
# Check GPU usage
nvidia-smi

# Monitor memory metrics in SigNoz
# Restart sidecars to free memory
```

#### Fallback Rate High
```powershell
# Check GPU availability
nvidia-smi

# Verify sidecar health
pwsh -File scripts/test-gpu-sidecars.ps1

# Review error logs
```

### Emergency Procedures

#### Complete Restart
```powershell
# Stop all services
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action stop

# Wait 30 seconds
Start-Sleep -Seconds 30

# Start all services
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action start

# Verify health
pwsh -File scripts/test-gpu-sidecars.ps1
```

#### Rollback to CPU-Only
1. Update collector config to disable GPU routing
2. Restart collector service
3. Monitor for issues

## Performance Tuning

### Compression Sidecar
- Adjust compression level in config
- Monitor compression ratios
- Tune batch sizes

### Aggregation Sidecar
- Optimize cuDF operations
- Adjust group-by fields
- Monitor processing times

### Inference Sidecar
- Tune anomaly thresholds
- Update ML models
- Monitor accuracy metrics

## Maintenance

### Weekly Tasks
- Review performance metrics in SigNoz
- Check alert history
- Update documentation
- Review production monitoring reports

### Monthly Tasks
- Update ML models
- Review and tune thresholds
- Performance optimization
- Capacity planning

### Quarterly Tasks
- Full system review
- Technology updates
- Security updates
- Disaster recovery testing

## Monitoring Dashboard

### Key Metrics to Watch
- **Compression Throughput**: Records per second
- **Aggregation Latency**: P50, P90, P99 processing times
- **Inference Performance**: Anomaly detection rate
- **GPU Memory Usage**: Used vs. total memory
- **Queue Depth**: Buffer file counts
- **Fallback Rate**: CPU fallback percentage
- **Processing Efficiency**: GPU vs. CPU processing ratio

### Alert Thresholds
- **Health Status**: 0 = unhealthy, 1 = healthy
- **Fallback Rate**: >10% triggers warning
- **Queue Depth**: >1000 items triggers warning
- **Processing Efficiency**: <50% triggers warning
- **Memory Usage**: >90% triggers critical alert

## File Locations

### Scripts
- `scripts/manage-gpu-sidecars.ps1` - Service management
- `scripts/test-gpu-sidecars.ps1` - Health checks
- `scripts/validate-production-gpu.ps1` - Production validation
- `scripts/gpu-watchdog.ps1` - Continuous monitoring
- `scripts/production-monitoring.ps1` - Production reporting

### Configuration
- `artifacts/signoz-gpu-sidecar-dashboard.json` - SigNoz dashboard
- `alerts/gpu-sidecar-alerts.json` - Alert configurations
- `config.yaml` - Collector configuration

### Logs and Reports
- `logs/gpu-watchdog.log` - Watchdog logs
- `reports/gpu-sidecar/` - Production reports
- `gpu-buffers/` - GPU processing buffers

## Support

### Documentation
- `docs/GPU_SIDECAR_COMPLETE_IMPLEMENTATION.md` - Complete implementation guide
- `docs/GPU_SIDECAR_PRODUCTION_RUNBOOK.md` - Production operations guide
- `docs/TRITON_SERVER_SETUP.md` - Triton server setup guide

### Troubleshooting
- Check logs in `logs/` directory
- Review SigNoz dashboard for metrics
- Run health checks with test scripts
- Check Task Scheduler for automation status

---

**Status**: ✅ **PRODUCTION READY**

The GPU sidecar infrastructure is fully operational and ready for production deployment. All services are validated, monitoring is configured, and automation is in place.

**Next Steps**: Follow this guide to deploy to production and monitor the system using the provided tools and dashboards.
