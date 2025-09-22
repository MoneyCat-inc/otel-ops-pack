# GPU Sidecar Production Runbook

## Daily Operations

### Health Checks
```powershell
# Quick health check
pwsh -File scripts/test-gpu-sidecars.ps1

# Complete integration test
pwsh -File verify-integration.ps1

# Production validation
pwsh -File scripts/validate-production-gpu.ps1 -Iterations 20
```

### Monitoring
```powershell
# Start watchdog
pwsh -File scripts/gpu-watchdog.ps1

# Generate production report
pwsh -File scripts/production-monitoring.ps1 -Environment production
```

### Service Management
```powershell
# Start all sidecars
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action start

# Stop all sidecars
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action stop

# Restart all sidecars
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action restart

# Check status
pwsh -File scripts/manage-gpu-sidecars.ps1 -Action status
```

## Troubleshooting

### Common Issues

#### Sidecar Not Responding
1. Check container status: `docker ps`
2. Check logs: `docker logs <container_name>`
3. Restart service: `pwsh -File scripts/manage-gpu-sidecars.ps1 -Action restart`

#### High Queue Depth
1. Check buffer directories: `Get-ChildItem gpu-buffers -Recurse`
2. Monitor processing efficiency
3. Scale up sidecar resources if needed

#### GPU Memory Issues
1. Check GPU usage: `nvidia-smi`
2. Monitor memory metrics in SigNoz
3. Restart sidecars to free memory

#### Fallback Rate High
1. Check GPU availability
2. Verify sidecar health
3. Review error logs

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
- Review performance metrics
- Check alert history
- Update documentation

### Monthly Tasks
- Update ML models
- Review and tune thresholds
- Performance optimization

### Quarterly Tasks
- Full system review
- Capacity planning
- Technology updates
